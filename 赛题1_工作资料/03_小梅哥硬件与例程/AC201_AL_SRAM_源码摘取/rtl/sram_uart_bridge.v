`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : sram_uart_bridge.v
// 模块名称 : sram_uart_bridge
// 功能说明 : 负责解析 UART 文本命令，并把命令转换为异步 SRAM 控制器的读写握手。
//            支持的命令格式如下：
//            1. 读命令 : RAAAAA[<CR>]
//            2. 写命令 : WAAAAA=DDDD[<CR>]
//            其中 AAAAA 为 5 位十六进制字地址，DDDD 为 4 位十六进制 16bit 数据。
//            为兼容部分串口工具的“发送按钮不自动追加回车”用法，固定长度命令在最后
//            1 个十六进制字符接收完成后即可直接执行；若额外发送 CR/LF，也会被兼容。
//            返回结果如下：
//            1. 写成功 : OK<CR><LF>
//            2. 读成功 : DDDD<CR><LF>
//            3. 解析错误或地址越界 : ER<CR><LF>
// 上层调用 : sram_uart_top
// 时钟说明 : clk_i，50 MHz 系统时钟
// 复位说明 : rst_n_i，低有效异步复位
// 修改记录 :
//   2026-04-22  初版，完成 UART 文本协议到 SRAM 命令的桥接
//------------------------------------------------------------------------------

module sram_uart_bridge #(
    parameter           ADDR_W = 18,                // 板上 SRAM 有效地址位宽，当前实装器件为 18bit
    parameter           DATA_W = 16                 // 板上 SRAM 数据位宽，当前实装器件为 16bit
) (
    input   wire                    clk_i,          // 系统时钟输入
    input   wire                    rst_n_i,        // 低有效异步复位输入
    input   wire    [7:0]           rx_data_i,      // UART 接收器给出的 1 字节数据
    input   wire                    rx_done_i,      // UART 接收器给出的接收完成脉冲
    output  reg     [7:0]           tx_data_o,      // 送往 UART 发送器的 1 字节数据
    output  reg                     tx_send_o,      // 送往 UART 发送器的发送启动脉冲
    input   wire                    tx_busy_i,      // 来自 UART 发送器的忙状态
    output  reg                     cmd_valid_o,    // 送往 SRAM 控制器的命令有效脉冲
    output  reg                     cmd_write_o,    // 送往 SRAM 控制器的读写方向，1 表示写
    output  reg     [ADDR_W-1:0]    cmd_addr_o,     // 送往 SRAM 控制器的目标字地址
    output  reg     [DATA_W-1:0]    cmd_wdata_o,    // 送往 SRAM 控制器的写数据
    output  reg     [1:0]           cmd_byte_en_o,  // 送往 SRAM 控制器的字节使能，当前固定全字访问
    input   wire                    cmd_ready_i,    // 来自 SRAM 控制器的 ready 信号
    input   wire                    rsp_valid_i,    // 来自 SRAM 控制器的完成脉冲
    input   wire    [DATA_W-1:0]    rsp_rdata_i     // 来自 SRAM 控制器的读回数据
);

    localparam  [2:0]   S_RX_COLLECT    = 3'd0;     // 空闲/收命令状态，逐字节解析 UART 命令
    localparam  [2:0]   S_CMD_SEND      = 3'd1;     // 对 SRAM 控制器发起 1 次命令请求
    localparam  [2:0]   S_CMD_HOLD      = 3'd2;     // 保持 cmd_valid_o 1 个完整时钟周期，确保下游采样到
    localparam  [2:0]   S_WAIT_RSP      = 3'd3;     // 等待 SRAM 控制器返回本次读写命令完成脉冲
    localparam  [2:0]   S_TX_SEND       = 3'd4;     // 给 UART 发送器加载 1 个应答字节
    localparam  [2:0]   S_TX_HOLD       = 3'd5;     // 保持 tx_send_o 1 个完整时钟周期，确保下游采样到
    localparam  [2:0]   S_TX_DRAIN      = 3'd6;     // 所有字节均已送入 UART 后，等待最后 1 字节真正发完

    localparam  [2:0]   P_IDLE          = 3'd0;     // 等待命令首字符 R/W
    localparam  [2:0]   P_R_ADDR        = 3'd1;     // 正在接收读命令的 5 位十六进制地址
    localparam  [2:0]   P_R_TERM        = 3'd2;     // 读命令地址接收完毕，等待回车结束符
    localparam  [2:0]   P_W_ADDR        = 3'd3;     // 正在接收写命令的 5 位十六进制地址
    localparam  [2:0]   P_W_EQ          = 3'd4;     // 写命令地址接收完毕，等待 '=' 分隔符
    localparam  [2:0]   P_W_DATA        = 3'd5;     // 正在接收写命令的 4 位十六进制数据
    localparam  [2:0]   P_W_TERM        = 3'd6;     // 写命令数据接收完毕，等待回车结束符
    localparam  [2:0]   P_SKIP_EOL      = 3'd7;     // 当前命令已判错，丢弃后续字节直到遇到行结束符

    reg     [2:0]               main_state_r;       // 主状态机当前状态寄存器
    reg     [2:0]               parse_state_r;      // UART 命令解析状态寄存器
    reg     [2:0]               hex_cnt_r;          // 当前解析到的十六进制字符序号
    reg     [19:0]              addr_parse_r;       // 解析 UART 文本时使用的 20bit 地址累加寄存器
    reg     [15:0]              data_parse_r;       // 解析 UART 文本时使用的 16bit 数据累加寄存器
    reg     [7:0]               resp_buf_r [0:5];  // UART 应答缓冲区，最长需要发送 6 个字符
    reg     [2:0]               resp_len_r;         // 当前 UART 应答总字节数
    reg     [2:0]               resp_idx_r;         // 当前准备发送的 UART 应答字节编号
    reg                         last_resp_byte_r;   // 标记刚刚装入 UART 发送器的是不是最后 1 个字节
    wire                        w_rx_is_hex;        // 当前接收字节是否属于合法十六进制字符
    wire    [3:0]               w_rx_hex_value;     // 当前接收字节对应的十六进制数值
    wire                        w_rx_is_crlf;       // 当前接收字节是否是 CR/LF 行结束符
    wire                        w_addr_in_range;    // 当前解析出的 20bit 地址是否落在真实 SRAM 容量范围内
    wire    [19:0]              w_addr_parse_next;  // 把当前接收十六进制字符并入后的下一拍地址值
    wire    [15:0]              w_data_parse_next;  // 把当前接收十六进制字符并入后的下一拍数据值
    wire                        w_addr_next_in_range; // 下一拍地址值是否仍处于真实 SRAM 范围内

    // 将 ASCII 十六进制字符映射为 4bit 数值，非法字符时该函数的输出值会被上层忽略。
    function [3:0] fn_hex_value;
        input [7:0] char_i;
        begin
            case (char_i)
                8'h30: fn_hex_value = 4'h0;         // '0' 映射为 0
                8'h31: fn_hex_value = 4'h1;         // '1' 映射为 1
                8'h32: fn_hex_value = 4'h2;         // '2' 映射为 2
                8'h33: fn_hex_value = 4'h3;         // '3' 映射为 3
                8'h34: fn_hex_value = 4'h4;         // '4' 映射为 4
                8'h35: fn_hex_value = 4'h5;         // '5' 映射为 5
                8'h36: fn_hex_value = 4'h6;         // '6' 映射为 6
                8'h37: fn_hex_value = 4'h7;         // '7' 映射为 7
                8'h38: fn_hex_value = 4'h8;         // '8' 映射为 8
                8'h39: fn_hex_value = 4'h9;         // '9' 映射为 9
                8'h41, 8'h61: fn_hex_value = 4'hA;  // 'A'/'a' 映射为 10
                8'h42, 8'h62: fn_hex_value = 4'hB;  // 'B'/'b' 映射为 11
                8'h43, 8'h63: fn_hex_value = 4'hC;  // 'C'/'c' 映射为 12
                8'h44, 8'h64: fn_hex_value = 4'hD;  // 'D'/'d' 映射为 13
                8'h45, 8'h65: fn_hex_value = 4'hE;  // 'E'/'e' 映射为 14
                8'h46, 8'h66: fn_hex_value = 4'hF;  // 'F'/'f' 映射为 15
                default: fn_hex_value = 4'h0;       // 非法字符统一返回 0，由合法性判断逻辑拦截
            endcase
        end
    endfunction

    // 判断当前 ASCII 字符是否属于合法十六进制输入。
    function fn_is_hex_char;
        input [7:0] char_i;
        begin
            case (char_i)
                8'h30, 8'h31, 8'h32, 8'h33,
                8'h34, 8'h35, 8'h36, 8'h37,
                8'h38, 8'h39, 8'h41, 8'h42,
                8'h43, 8'h44, 8'h45, 8'h46,
                8'h61, 8'h62, 8'h63, 8'h64,
                8'h65, 8'h66: fn_is_hex_char = 1'b1; // 0~9/A~F/a~f 都视为合法十六进制字符
                default: fn_is_hex_char = 1'b0;     // 其余字符一律视为非法
            endcase
        end
    endfunction

    // 把 4bit 十六进制数值映射回大写 ASCII 字符，用于读命令的文本应答。
    function [7:0] fn_hex_ascii;
        input [3:0] nibble_i;
        begin
            case (nibble_i)
                4'h0: fn_hex_ascii = 8'h30;         // 0 -> '0'
                4'h1: fn_hex_ascii = 8'h31;         // 1 -> '1'
                4'h2: fn_hex_ascii = 8'h32;         // 2 -> '2'
                4'h3: fn_hex_ascii = 8'h33;         // 3 -> '3'
                4'h4: fn_hex_ascii = 8'h34;         // 4 -> '4'
                4'h5: fn_hex_ascii = 8'h35;         // 5 -> '5'
                4'h6: fn_hex_ascii = 8'h36;         // 6 -> '6'
                4'h7: fn_hex_ascii = 8'h37;         // 7 -> '7'
                4'h8: fn_hex_ascii = 8'h38;         // 8 -> '8'
                4'h9: fn_hex_ascii = 8'h39;         // 9 -> '9'
                4'hA: fn_hex_ascii = 8'h41;         // A -> 'A'
                4'hB: fn_hex_ascii = 8'h42;         // B -> 'B'
                4'hC: fn_hex_ascii = 8'h43;         // C -> 'C'
                4'hD: fn_hex_ascii = 8'h44;         // D -> 'D'
                4'hE: fn_hex_ascii = 8'h45;         // E -> 'E'
                4'hF: fn_hex_ascii = 8'h46;         // F -> 'F'
                default: fn_hex_ascii = 8'h30;      // 理论不会走到此分支，默认返回 '0'
            endcase
        end
    endfunction

    // 用当前接收到的字节生成解析辅助信号，减少主状态机内部重复比较。
    assign w_rx_is_hex     = fn_is_hex_char(rx_data_i);      // 用于地址/数据字符的合法性判断
    assign w_rx_hex_value  = fn_hex_value(rx_data_i);        // 用于把合法十六进制字符累加进寄存器
    assign w_rx_is_crlf    = (rx_data_i == 8'h0D) ||
                             (rx_data_i == 8'h0A);           // 兼容 CR 和 LF 两种结尾方式
    assign w_addr_in_range = (addr_parse_r[19:ADDR_W] == {20-ADDR_W{1'b0}}); // 地址高于真实位宽的部分必须为 0
    assign w_addr_parse_next = {addr_parse_r[15:0], w_rx_hex_value}; // 地址解析过程中每接收 1 个十六进制字符就左移 4bit 再拼入
    assign w_data_parse_next = {data_parse_r[11:0], w_rx_hex_value}; // 数据解析过程中每接收 1 个十六进制字符就左移 4bit 再拼入
    assign w_addr_next_in_range = (w_addr_parse_next[19:ADDR_W] == {20-ADDR_W{1'b0}}); // 用于无结尾符模式下直接判定最终地址是否越界

    // 把解析器恢复到等待新命令的安全状态，避免上一次残留字段污染下一条命令。
    task task_reset_parser;
        begin
            parse_state_r <= P_IDLE;                // 回到等待命令首字符的解析状态
            hex_cnt_r     <= 3'd0;                  // 清零十六进制字符计数器
            addr_parse_r  <= 20'h00000;             // 清零地址累加寄存器
            data_parse_r  <= 16'h0000;              // 清零数据累加寄存器
        end
    endtask

    // 组织 ER<CR><LF> 应答，用于非法命令、缺字段或地址越界场景。
    task task_load_error_response;
        begin
            resp_buf_r[0] <= 8'h45;                 // 装入字符 'E'
            resp_buf_r[1] <= 8'h52;                 // 装入字符 'R'
            resp_buf_r[2] <= 8'h0D;                 // 装入回车 CR
            resp_buf_r[3] <= 8'h0A;                 // 装入换行 LF
            resp_len_r    <= 3'd4;                  // 错误应答总长度固定为 4 字节
            resp_idx_r    <= 3'd0;                  // 从应答缓冲区第 0 个字节开始发送
            last_resp_byte_r <= 1'b0;               // 启动新一轮应答发送前清除“最后 1 字节”标记
            main_state_r  <= S_TX_SEND;             // 切换到 UART 应答发送状态
            task_reset_parser();                    // 同时清空当前解析上下文，准备下一条命令
        end
    endtask

    // 组织 OK<CR><LF> 应答，用于 SRAM 写命令执行成功场景。
    task task_load_ok_response;
        begin
            resp_buf_r[0] <= 8'h4F;                 // 装入字符 'O'
            resp_buf_r[1] <= 8'h4B;                 // 装入字符 'K'
            resp_buf_r[2] <= 8'h0D;                 // 装入回车 CR
            resp_buf_r[3] <= 8'h0A;                 // 装入换行 LF
            resp_len_r    <= 3'd4;                  // 写成功应答总长度固定为 4 字节
            resp_idx_r    <= 3'd0;                  // 从应答缓冲区第 0 个字节开始发送
            last_resp_byte_r <= 1'b0;               // 启动新一轮应答发送前清除“最后 1 字节”标记
            main_state_r  <= S_TX_SEND;             // 切换到 UART 应答发送状态
            task_reset_parser();                    // 应答准备完成后清空解析上下文
        end
    endtask

    // 组织 DDDD<CR><LF> 应答，用于 SRAM 读命令执行成功场景。
    task task_load_read_response;
        input [15:0] read_data_i;
        begin
            resp_buf_r[0] <= fn_hex_ascii(read_data_i[15:12]); // 发送高 4bit 对应的 ASCII 字符
            resp_buf_r[1] <= fn_hex_ascii(read_data_i[11:8]);  // 发送次高 4bit 对应的 ASCII 字符
            resp_buf_r[2] <= fn_hex_ascii(read_data_i[7:4]);   // 发送次低 4bit 对应的 ASCII 字符
            resp_buf_r[3] <= fn_hex_ascii(read_data_i[3:0]);   // 发送最低 4bit 对应的 ASCII 字符
            resp_buf_r[4] <= 8'h0D;                 // 装入回车 CR，便于串口工具按行显示
            resp_buf_r[5] <= 8'h0A;                 // 装入换行 LF，便于串口工具按行显示
            resp_len_r    <= 3'd6;                  // 读成功应答总长度固定为 6 字节
            resp_idx_r    <= 3'd0;                  // 从应答缓冲区第 0 个字节开始发送
            last_resp_byte_r <= 1'b0;               // 启动新一轮应答发送前清除“最后 1 字节”标记
            main_state_r  <= S_TX_SEND;             // 切换到 UART 应答发送状态
            task_reset_parser();                    // 应答准备完成后清空解析上下文
        end
    endtask

    // 在解析完成后，把当前命令上下文转成 SRAM 控制器可接受的一次完整读写命令。
    task task_start_sram_cmd;
        input               write_i;
        input [ADDR_W-1:0]  addr_i;
        input [DATA_W-1:0]  data_i;
        begin
            cmd_write_o   <= write_i;               // 锁存本次命令的读写方向
            cmd_addr_o    <= addr_i;                // 锁存本次命令的目标字地址
            cmd_wdata_o   <= data_i;                // 锁存本次写命令的 16bit 数据，读命令时该字段可忽略
            cmd_byte_en_o <= 2'b11;                 // 当前协议固定做整字访问，始终同时使能高低字节
            main_state_r  <= S_CMD_SEND;            // 切换到 SRAM 命令发起状态
            task_reset_parser();                    // 当前命令已经转交给 SRAM 控制路径，清空解析上下文
        end
    endtask

    // ---- 主状态机：负责收命令、发 SRAM 访问和回传 UART 文本应答 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            main_state_r      <= S_RX_COLLECT;      // 复位后先进入 UART 命令收集状态
            parse_state_r     <= P_IDLE;            // 复位后等待新的命令首字符
            hex_cnt_r         <= 3'd0;              // 复位后清零十六进制字符计数器
            addr_parse_r      <= 20'h00000;         // 复位后清零地址解析寄存器
            data_parse_r      <= 16'h0000;          // 复位后清零数据解析寄存器
            resp_len_r        <= 3'd0;              // 复位后清空应答长度
            resp_idx_r        <= 3'd0;              // 复位后清空应答索引
            last_resp_byte_r  <= 1'b0;              // 复位后清除“最后 1 字节”标记
            tx_data_o         <= 8'h00;             // 复位后清空 UART 待发送数据寄存器
            tx_send_o         <= 1'b0;              // 复位后不向 UART 发送器发启动脉冲
            cmd_valid_o       <= 1'b0;              // 复位后不向 SRAM 控制器发命令
            cmd_write_o       <= 1'b0;              // 复位后默认命令方向为读，不产生副作用
            cmd_addr_o        <= {ADDR_W{1'b0}};    // 复位后清零 SRAM 命令地址
            cmd_wdata_o       <= {DATA_W{1'b0}};    // 复位后清零 SRAM 命令数据
            cmd_byte_en_o     <= 2'b11;             // 复位后默认全字节使能，便于后续直接复用
            resp_buf_r[0]     <= 8'h00;             // 复位后清空应答缓冲区第 0 字节
            resp_buf_r[1]     <= 8'h00;             // 复位后清空应答缓冲区第 1 字节
            resp_buf_r[2]     <= 8'h00;             // 复位后清空应答缓冲区第 2 字节
            resp_buf_r[3]     <= 8'h00;             // 复位后清空应答缓冲区第 3 字节
            resp_buf_r[4]     <= 8'h00;             // 复位后清空应答缓冲区第 4 字节
            resp_buf_r[5]     <= 8'h00;             // 复位后清空应答缓冲区第 5 字节
        end
        else begin
            tx_send_o   <= 1'b0;                    // 默认每拍拉低 UART 发送启动脉冲，只有发新字节时拉高 1 拍
            cmd_valid_o <= 1'b0;                    // 默认每拍拉低 SRAM 命令有效脉冲，只有发新命令时拉高 1 拍

            case (main_state_r)
                S_RX_COLLECT: begin
                    if (rx_done_i) begin
                        case (parse_state_r)
                            P_IDLE: begin
                                if (w_rx_is_crlf) begin
                                    parse_state_r <= P_IDLE; // 空行或 CRLF 空闲字节直接忽略
                                end
                                else if ((rx_data_i == 8'h52) || (rx_data_i == 8'h72)) begin
                                    parse_state_r <= P_R_ADDR; // 检测到 'R'/'r' 后进入读地址接收状态
                                    hex_cnt_r     <= 3'd0;     // 从第 0 个地址字符开始累计
                                    addr_parse_r  <= 20'h00000; // 启动新命令前先清空地址寄存器
                                    data_parse_r  <= 16'h0000; // 启动新命令前先清空数据寄存器
                                end
                                else if ((rx_data_i == 8'h57) || (rx_data_i == 8'h77)) begin
                                    parse_state_r <= P_W_ADDR; // 检测到 'W'/'w' 后进入写地址接收状态
                                    hex_cnt_r     <= 3'd0;     // 从第 0 个地址字符开始累计
                                    addr_parse_r  <= 20'h00000; // 启动新命令前先清空地址寄存器
                                    data_parse_r  <= 16'h0000; // 启动新命令前先清空数据寄存器
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 首字符非法时先丢弃整行剩余内容
                                end
                            end

                            P_R_ADDR: begin
                                if (w_rx_is_hex) begin
                                    if (hex_cnt_r == 3'd4) begin
                                        if (w_addr_next_in_range) begin
                                            task_start_sram_cmd(1'b0, w_addr_parse_next[ADDR_W-1:0], {DATA_W{1'b0}}); // 读命令收满 5 位地址后直接执行，兼容无回车发送
                                        end
                                        else begin
                                            task_load_error_response(); // 固定长度命令到齐后若地址越界则直接返回 ER
                                        end
                                    end
                                    else begin
                                        addr_parse_r <= w_addr_parse_next; // 地址尚未收满时把当前 nibble 累加进解析寄存器
                                        hex_cnt_r <= hex_cnt_r + 1'b1; // 地址尚未收满时继续统计下一个字符位置
                                    end
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 地址字段遇到非法字符时丢弃当前整条命令
                                end
                            end

                            P_R_TERM: begin
                                if (w_rx_is_crlf) begin
                                    if (w_addr_in_range) begin
                                        task_start_sram_cmd(1'b0, addr_parse_r[ADDR_W-1:0], {DATA_W{1'b0}}); // 地址合法时发起 1 次 SRAM 读命令
                                    end
                                    else begin
                                        task_load_error_response(); // 地址越界时直接返回 ER，不访问真实 SRAM
                                    end
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 读命令地址后若不是回车结束符，则命令格式错误
                                end
                            end

                            P_W_ADDR: begin
                                if (w_rx_is_hex) begin
                                    addr_parse_r <= {addr_parse_r[15:0], w_rx_hex_value}; // 逐字符把写地址左移 4bit 后拼入新 nibble

                                    if (hex_cnt_r == 3'd4) begin
                                        parse_state_r <= P_W_EQ;  // 收满 5 位地址后转去等待 '=' 分隔符
                                    end
                                    else begin
                                        hex_cnt_r <= hex_cnt_r + 1'b1; // 地址尚未收满时继续统计下一个字符位置
                                    end
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 地址字段遇到非法字符时丢弃当前整条命令
                                end
                            end

                            P_W_EQ: begin
                                if (rx_data_i == 8'h3D) begin
                                    parse_state_r <= P_W_DATA;  // 检测到 '=' 分隔符后进入写数据接收状态
                                    hex_cnt_r     <= 3'd0;      // 从第 0 个数据字符开始累计
                                    data_parse_r  <= 16'h0000;  // 每条写命令开始前清空数据寄存器
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 缺少 '=' 分隔符时判定为命令格式错误
                                end
                            end

                            P_W_DATA: begin
                                if (w_rx_is_hex) begin
                                    if (hex_cnt_r == 3'd3) begin
                                        if (w_addr_in_range) begin
                                            task_start_sram_cmd(1'b1, addr_parse_r[ADDR_W-1:0], w_data_parse_next[DATA_W-1:0]); // 写命令收满 4 位数据后直接执行，兼容无回车发送
                                        end
                                        else begin
                                            task_load_error_response(); // 固定长度写命令到齐后若地址越界则直接返回 ER
                                        end
                                    end
                                    else begin
                                        data_parse_r <= w_data_parse_next; // 数据尚未收满时把当前 nibble 累加进解析寄存器
                                        hex_cnt_r <= hex_cnt_r + 1'b1; // 数据尚未收满时继续统计下一个字符位置
                                    end
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 数据字段遇到非法字符时丢弃当前整条命令
                                end
                            end

                            P_W_TERM: begin
                                if (w_rx_is_crlf) begin
                                    if (w_addr_in_range) begin
                                        task_start_sram_cmd(1'b1, addr_parse_r[ADDR_W-1:0], data_parse_r[DATA_W-1:0]); // 地址合法时发起 1 次 SRAM 写命令
                                    end
                                    else begin
                                        task_load_error_response(); // 地址越界时直接返回 ER，不访问真实 SRAM
                                    end
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 写命令数据后若不是回车结束符，则命令格式错误
                                end
                            end

                            P_SKIP_EOL: begin
                                if (w_rx_is_crlf) begin
                                    task_load_error_response();   // 丢弃到本行结束后统一回发 1 条 ER 应答
                                end
                                else begin
                                    parse_state_r <= P_SKIP_EOL; // 行结束前继续忽略所有后续字符
                                end
                            end

                            default: begin
                                task_load_error_response();       // 解析器进入非法状态时直接回 ER 并自恢复
                            end
                        endcase
                    end
                end

                S_CMD_SEND: begin
                    if (cmd_ready_i) begin
                        cmd_valid_o  <= 1'b1;       // 下游空闲时拉高命令有效脉冲
                        main_state_r <= S_CMD_HOLD; // 保持 1 个完整时钟周期，确保 SRAM 控制器采样到命令
                    end
                    else begin
                        main_state_r <= S_CMD_SEND; // 下游尚未 ready 时继续等待，不丢命令
                    end
                end

                S_CMD_HOLD: begin
                    main_state_r <= S_WAIT_RSP;     // 命令已经送入下游，开始等待本次访问完成脉冲
                end

                S_WAIT_RSP: begin
                    if (rsp_valid_i) begin
                        if (cmd_write_o) begin
                            task_load_ok_response();           // 写命令完成后组织 OK 应答
                        end
                        else begin
                            task_load_read_response(rsp_rdata_i); // 读命令完成后把读回数据转成 4 位十六进制文本
                        end
                    end
                    else begin
                        main_state_r <= S_WAIT_RSP; // SRAM 尚未返回完成脉冲时持续等待
                    end
                end

                S_TX_SEND: begin
                    if (!tx_busy_i) begin
                        tx_data_o  <= resp_buf_r[resp_idx_r]; // UART 发送器空闲时装入当前应答字节
                        tx_send_o  <= 1'b1;         // 拉高 1 拍发送启动脉冲，请求 UART 发送器取数

                        if (resp_idx_r == (resp_len_r - 1'b1)) begin
                            last_resp_byte_r <= 1'b1; // 当前装入的是最后 1 个应答字节，后续转入 drain 阶段
                        end
                        else begin
                            last_resp_byte_r <= 1'b0; // 当前装入的还不是最后 1 个字节，后续继续发送下一个字节
                            resp_idx_r       <= resp_idx_r + 1'b1; // 推进到下一个待发送应答字节
                        end

                        main_state_r <= S_TX_HOLD;  // 保持 1 个完整时钟周期，确保 UART 发送器采样到启动脉冲
                    end
                    else begin
                        main_state_r <= S_TX_SEND;  // UART 发送器忙时等待其空闲后再加载下一个字节
                    end
                end

                S_TX_HOLD: begin
                    if (last_resp_byte_r) begin
                        main_state_r <= S_TX_DRAIN; // 最后 1 个字节已交给 UART 发送器，等待其物理发完
                    end
                    else begin
                        main_state_r <= S_TX_SEND;  // 还有剩余字节时返回继续发送后续字节
                    end
                end

                S_TX_DRAIN: begin
                    if (!tx_busy_i) begin
                        resp_len_r       <= 3'd0;   // 整条应答发送结束后清零应答长度
                        resp_idx_r       <= 3'd0;   // 整条应答发送结束后清零应答索引
                        last_resp_byte_r <= 1'b0;   // 清除“最后 1 字节”标记，为下一次应答做准备
                        main_state_r     <= S_RX_COLLECT; // UART 发空后回到命令收集状态
                    end
                    else begin
                        main_state_r <= S_TX_DRAIN; // UART 最后 1 字节尚未发完时持续等待
                    end
                end

                default: begin
                    main_state_r <= S_RX_COLLECT;   // 主状态机进入非法状态时回到命令收集状态
                    task_reset_parser();            // 恢复时同时清空解析上下文，避免残留字段影响下一条命令
                end
            endcase
        end
    end

endmodule

`default_nettype wire
