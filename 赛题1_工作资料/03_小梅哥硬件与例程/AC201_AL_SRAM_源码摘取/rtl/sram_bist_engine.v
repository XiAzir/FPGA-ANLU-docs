`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : sram_bist_engine.v
// 模块名称 : sram_bist_engine
// 功能说明 : 自动驱动 SRAM 控制器完成写入、读回和比较。
//            该模块负责测试阶段调度、错误锁存和 PASS/FAIL 状态输出。
// 上层调用 : sram_bist_top
// 时钟说明 : clk_i，单时钟域
// 复位说明 : rst_n_i，低有效
// 修改记录 :
//   2026-04-22 初版，完成纯 FPGA SRAM BIST 序列器。
//------------------------------------------------------------------------------

module sram_bist_engine #(
    parameter           ADDR_W      = 18,           // SRAM 地址总线位宽
    parameter           DATA_W      = 16            // SRAM 数据总线位宽
) (
    input   wire                    clk_i,          // 系统时钟
    input   wire                    rst_n_i,        // 异步低有效复位

    output  wire                    cmd_valid_o,    // 发往控制器的命令有效脉冲
    output  wire                    cmd_write_o,    // 发往控制器的读写方向，1 表示写
    output  wire    [ADDR_W-1:0]    cmd_addr_o,     // 发往控制器的访问地址
    output  wire    [DATA_W-1:0]    cmd_wdata_o,    // 发往控制器的写数据
    output  wire    [1:0]           cmd_byte_en_o,  // 发往控制器的字节使能
    input   wire                    cmd_ready_i,    // 控制器空闲，可接收新命令
    input   wire                    rsp_valid_i,    // 控制器当前命令已完成
    input   wire    [DATA_W-1:0]    rsp_rdata_i,    // 控制器返回的读数据

    output  wire                    done_o,         // BIST 全流程结束指示
    output  wire                    pass_o,         // BIST 全流程通过指示
    output  wire                    fail_o,         // BIST 检测到错误指示
    output  wire    [7:0]           fail_stage_o,   // 首次失败时锁存的测试阶段编号
    output  wire    [ADDR_W-1:0]    fail_addr_o,    // 首次失败时锁存的错误地址
    output  wire    [DATA_W-1:0]    exp_data_o,     // 首次失败时锁存的期望数据
    output  wire    [DATA_W-1:0]    rd_data_o       // 首次失败时锁存的实际读回数据
);

    localparam  [2:0]   S_ISSUE         = 3'd0;     // 向控制器发出当前阶段当前地址的测试命令
    localparam  [2:0]   S_WAIT          = 3'd1;     // 等待控制器完成单次读写命令
    localparam  [2:0]   S_CHECK         = 3'd2;     // 对读命令返回的数据做比对
    localparam  [2:0]   S_ADVANCE       = 3'd3;     // 推进地址或切换到下一测试阶段
    localparam  [2:0]   S_PASS          = 3'd4;     // 所有阶段都通过后停在 PASS 状态
    localparam  [2:0]   S_FAIL          = 3'd5;     // 首次读回失败后停在 FAIL 状态

    localparam  [7:0]   PH_W0000        = 8'h00;    // 全空间写 0x0000
    localparam  [7:0]   PH_R0000        = 8'h01;    // 全空间读回并比较 0x0000
    localparam  [7:0]   PH_WFFFF        = 8'h02;    // 全空间写 0xFFFF
    localparam  [7:0]   PH_RFFFF        = 8'h03;    // 全空间读回并比较 0xFFFF
    localparam  [7:0]   PH_WAAAA        = 8'h04;    // 全空间写 0xAAAA
    localparam  [7:0]   PH_RAAAA        = 8'h05;    // 全空间读回并比较 0xAAAA
    localparam  [7:0]   PH_W5555        = 8'h06;    // 全空间写 0x5555
    localparam  [7:0]   PH_R5555        = 8'h07;    // 全空间读回并比较 0x5555
    localparam  [7:0]   PH_WADDR        = 8'h08;    // 全空间写地址低 16 位
    localparam  [7:0]   PH_RADDR        = 8'h09;    // 全空间读回并比较地址低 16 位
    localparam  [7:0]   PH_WNADR        = 8'h0A;    // 全空间写地址低 16 位取反
    localparam  [7:0]   PH_RNADR        = 8'h0B;    // 全空间读回并比较地址低 16 位取反
    localparam  [7:0]   PH_W55AA        = 8'h0C;    // 全空间写 0x55AA，为字节测试建立基准值
    localparam  [7:0]   PH_R55AA        = 8'h0D;    // 全空间读回并比较 0x55AA
    localparam  [7:0]   PH_WLB          = 8'h0E;    // 仅写低字节，验证 LB# 和低 8 位数据线
    localparam  [7:0]   PH_RLB          = 8'h0F;    // 读回并比较低字节改写后的结果
    localparam  [7:0]   PH_WUB          = 8'h10;    // 仅写高字节，验证 UB# 和高 8 位数据线
    localparam  [7:0]   PH_RUB          = 8'h11;    // 读回并比较高字节改写后的结果

    reg     [2:0]           st_cur_r;               // 当前状态寄存器
    reg     [2:0]           st_nxt_r;               // 下一状态组合结果
    reg     [7:0]           phase_r;                // 当前测试阶段编号
    reg     [ADDR_W-1:0]    addr_r;                 // 当前正在访问的 SRAM 地址
    reg     [DATA_W-1:0]    rd_data_hold_r;         // 锁存控制器返回的读数据，供下一拍比较
    reg     [7:0]           fail_stage_r;           // 锁存首次失败时的阶段编号
    reg     [ADDR_W-1:0]    fail_addr_r;            // 锁存首次失败时的访问地址
    reg     [DATA_W-1:0]    exp_data_r;             // 锁存首次失败时的期望数据
    reg     [DATA_W-1:0]    rd_data_r;              // 锁存首次失败时的实际读回数据

    wire    [DATA_W-1:0]    w_expect_data;          // 当前阶段当前地址对应的期望读回数据
    wire    [DATA_W-1:0]    w_write_data;           // 当前阶段当前地址对应的写入数据
    wire    [1:0]           w_byte_en;              // 当前阶段当前地址对应的字节使能
    wire                    w_phase_is_read;        // 当前阶段是否属于读回比较阶段
    wire                    w_last_addr;            // 当前地址是否已经到达本阶段最后一个地址
    wire                    w_last_phase;           // 当前阶段是否已经是最后一个测试阶段
    wire                    w_data_match;           // 当前读回数据是否与期望值一致

    // 当前阶段如果是读阶段，则发给控制器的命令方向为读；否则为写。
    assign w_phase_is_read = phase_is_read_f(phase_r); // 将阶段编号映射为读/写属性，便于状态机判断

    // 当前阶段的写数据由阶段编号和地址共同决定。
    assign w_write_data = phase_write_data_f(phase_r, addr_r); // 地址码和取反地址码阶段依赖当前地址值

    // 当前阶段的期望读回数据由阶段编号和地址共同决定。
    assign w_expect_data = phase_expect_data_f(phase_r, addr_r); // 读阶段的比较基准统一由函数生成

    // 字节访问阶段会分别选择低字节或高字节，其余阶段默认整字访问。
    assign w_byte_en = phase_byte_en_f(phase_r);    // 统一用函数生成当前阶段的字节使能

    // 命令只在 ISSUE 状态且控制器 ready 时对外发出。
    assign cmd_valid_o = (st_cur_r == S_ISSUE);     // ISSUE 状态持续到握手成功，保证命令不丢失

    // 写阶段输出 1，读阶段输出 0，控制器据此选择不同访问时序。
    assign cmd_write_o = !w_phase_is_read;          // 读写方向完全由当前阶段决定

    // 每个阶段都会遍历当前地址寄存器指向的 SRAM 地址。
    assign cmd_addr_o = addr_r;                     // 当前正在测试的地址直接送给控制器

    // 写阶段需要的测试数据由阶段函数生成，读阶段该总线值会被控制器忽略。
    assign cmd_wdata_o = w_write_data;              // 即使读阶段也保持稳定值，简化顶层连线

    // 字节使能在整字测试和字节测试阶段分别由函数给出。
    assign cmd_byte_en_o = w_byte_en;               // 统一采用 [1]=高字节、[0]=低字节 编码

    // 当前地址达到全 1 时说明本阶段最后一个地址已经处理完成。
    assign w_last_addr = &addr_r;                   // 适配 18 位实板和缩小地址宽度的仿真场景

    // 最后一个阶段固定定义为 PH_RUB。
    assign w_last_phase = (phase_r == PH_RUB);      // 所有测试完成后停在 PASS 状态

    // 读比较阶段使用锁存后的读数据与函数生成的期望值直接比较。
    assign w_data_match = (rd_data_hold_r == w_expect_data); // 一旦不匹配就锁存失败信息并停机

    // DONE 只在 PASS 或 FAIL 两个终态为高，表示 BIST 已经停止。
    assign done_o = (st_cur_r == S_PASS) || (st_cur_r == S_FAIL); // 顶层据此决定 LED 进入最终显示模式

    // PASS 终态表示所有测试阶段都已通过。
    assign pass_o = (st_cur_r == S_PASS);           // PASS 状态下 LED 将常亮显示通过结果

    // FAIL 终态表示已经检测到首个错误并锁存了失败上下文。
    assign fail_o = (st_cur_r == S_FAIL);           // FAIL 状态下 LED 将以快闪方式提示错误

    // 直接输出首次失败时锁存的测试阶段，便于后续通过片上调试或层级观察定位问题。
    assign fail_stage_o = fail_stage_r;             // 首次失败后保持不变，直到重新复位

    // 直接输出首次失败时锁存的错误地址。
    assign fail_addr_o = fail_addr_r;               // 首次失败后保持不变，直到重新复位

    // 直接输出首次失败时锁存的期望数据。
    assign exp_data_o = exp_data_r;                 // 首次失败后保持不变，直到重新复位

    // 直接输出首次失败时锁存的实际读回数据。
    assign rd_data_o = rd_data_r;                   // 首次失败后保持不变，直到重新复位

    // ---- st_cur_r: BIST 主状态寄存器 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            st_cur_r <= S_ISSUE;                    // 复位释放后直接从首个阶段首个地址开始测试
        end
        else begin
            st_cur_r <= st_nxt_r;                   // 每拍根据组合次态推进 BIST 状态
        end
    end

    // ---- st_nxt_r: BIST 主状态组合逻辑 ----
    always @(*) begin
        st_nxt_r = st_cur_r;                        // 默认保持当前状态，避免组合逻辑不完整

        case (st_cur_r)
            S_ISSUE: begin
                if (cmd_ready_i) begin
                    st_nxt_r = S_WAIT;              // 与控制器握手成功后等待本次命令完成
                end
                else begin
                    st_nxt_r = S_ISSUE;             // 控制器未 ready 时继续保持命令有效
                end
            end

            S_WAIT: begin
                if (rsp_valid_i && w_phase_is_read) begin
                    st_nxt_r = S_CHECK;             // 读命令完成后进入比较阶段
                end
                else if (rsp_valid_i && !w_phase_is_read) begin
                    st_nxt_r = S_ADVANCE;           // 写命令完成后直接推进地址或切换阶段
                end
                else begin
                    st_nxt_r = S_WAIT;              // 控制器尚未返回完成脉冲时继续等待
                end
            end

            S_CHECK: begin
                if (w_data_match) begin
                    st_nxt_r = S_ADVANCE;           // 读回一致时推进地址或切换阶段
                end
                else begin
                    st_nxt_r = S_FAIL;              // 读回不一致时立即停在 FAIL 状态
                end
            end

            S_ADVANCE: begin
                if (w_last_phase && w_last_addr) begin
                    st_nxt_r = S_PASS;              // 最后一个阶段最后一个地址完成后进入 PASS
                end
                else begin
                    st_nxt_r = S_ISSUE;             // 其余情况回到 ISSUE 处理下一条测试命令
                end
            end

            S_PASS: begin
                st_nxt_r = S_PASS;                 // 进入 PASS 后保持终态，等待重新复位
            end

            S_FAIL: begin
                st_nxt_r = S_FAIL;                 // 进入 FAIL 后保持终态，等待重新复位
            end

            default: begin
                st_nxt_r = S_ISSUE;                // 非法状态统一恢复到首阶段发命令状态
            end
        endcase
    end

    // ---- phase_r / addr_r: 按阶段顺序遍历整个地址空间 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            phase_r <= PH_W0000;                    // 复位后从“全写 0”阶段开始
            addr_r  <= {ADDR_W{1'b0}};             // 复位后从 0 地址开始测试
        end
        else if (st_cur_r == S_ADVANCE) begin
            if (w_last_addr && !w_last_phase) begin
                phase_r <= phase_r + 1'b1;          // 当前阶段完成后切换到下一个测试阶段
                addr_r  <= {ADDR_W{1'b0}};         // 切换阶段时重新从 0 地址开始遍历
            end
            else if (!w_last_addr) begin
                phase_r <= phase_r;                 // 当前阶段尚未结束时保持阶段编号不变
                addr_r  <= addr_r + 1'b1;          // 地址自增，继续测试下一单元
            end
            else begin
                phase_r <= phase_r;                 // 最后一个阶段最后一个地址完成后保持当前阶段
                addr_r  <= addr_r;                 // PASS 终态前保持地址不再变化
            end
        end
        else begin
            phase_r <= phase_r;                     // 非推进状态保持当前阶段不变
            addr_r  <= addr_r;                     // 非推进状态保持当前地址不变
        end
    end

    // ---- rd_data_hold_r: 在 WAIT 状态收到 rsp_valid_i 时锁存控制器读回数据 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rd_data_hold_r <= {DATA_W{1'b0}};      // 复位时清空读数据暂存寄存器
        end
        else if (rsp_valid_i) begin
            rd_data_hold_r <= rsp_rdata_i;         // 命令完成脉冲到来时锁存返回数据
        end
        else begin
            rd_data_hold_r <= rd_data_hold_r;      // 非响应时刻保持上一次返回数据
        end
    end

    // ---- fail_*: 首次比较失败时锁存阶段、地址、期望值和实际值 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            fail_stage_r <= 8'h00;                 // 复位时清空失败阶段寄存器
            fail_addr_r  <= {ADDR_W{1'b0}};       // 复位时清空失败地址寄存器
            exp_data_r   <= {DATA_W{1'b0}};       // 复位时清空期望数据寄存器
            rd_data_r    <= {DATA_W{1'b0}};       // 复位时清空实际读回数据寄存器
        end
        else if ((st_cur_r == S_CHECK) && !w_data_match) begin
            fail_stage_r <= phase_r;               // 检测到首次失败时锁存当前阶段编号
            fail_addr_r  <= addr_r;                // 检测到首次失败时锁存当前访问地址
            exp_data_r   <= w_expect_data;         // 检测到首次失败时锁存期望数据
            rd_data_r    <= rd_data_hold_r;        // 检测到首次失败时锁存实际读回数据
        end
        else begin
            fail_stage_r <= fail_stage_r;          // 未发生新失败时保持已锁存的阶段编号
            fail_addr_r  <= fail_addr_r;           // 未发生新失败时保持已锁存的错误地址
            exp_data_r   <= exp_data_r;            // 未发生新失败时保持已锁存的期望数据
            rd_data_r    <= rd_data_r;             // 未发生新失败时保持已锁存的实际读回数据
        end
    end

    // 当前阶段是否为读阶段。
    function phase_is_read_f;
        input [7:0] phase_i;                       // 当前测试阶段编号
        begin
            case (phase_i)
                PH_R0000,
                PH_RFFFF,
                PH_RAAAA,
                PH_R5555,
                PH_RADDR,
                PH_RNADR,
                PH_R55AA,
                PH_RLB,
                PH_RUB: begin
                    phase_is_read_f = 1'b1;        // 所有以 R 开头的阶段都属于读回比较阶段
                end

                default: begin
                    phase_is_read_f = 1'b0;        // 其余阶段都属于写入准备阶段
                end
            endcase
        end
    endfunction

    // 当前阶段对应的字节使能。
    function [1:0] phase_byte_en_f;
        input [7:0] phase_i;                       // 当前测试阶段编号
        begin
            case (phase_i)
                PH_WLB: begin
                    phase_byte_en_f = 2'b01;       // 低字节测试阶段只访问低 8 位
                end

                PH_WUB: begin
                    phase_byte_en_f = 2'b10;       // 高字节测试阶段只访问高 8 位
                end

                default: begin
                    phase_byte_en_f = 2'b11;       // 读回比较阶段统一整字访问，便于检查未改字节是否保持
                end
            endcase
        end
    endfunction

    // 将任意地址宽度统一折算为 DATA_W 位数据，兼容实板 18 位地址和仿真 8 位地址两种场景。
    function [DATA_W-1:0] addr_to_data_f;
        input [ADDR_W-1:0] addr_i;                  // 当前正在测试的 SRAM 地址
        integer            bit_idx;                 // 地址到数据的逐 bit 搬运循环变量
        begin
            addr_to_data_f = {DATA_W{1'b0}};       // 先默认清零，再把地址低位逐 bit 拷贝进结果向量

            for (bit_idx = 0; bit_idx < DATA_W; bit_idx = bit_idx + 1) begin
                if (bit_idx < ADDR_W) begin
                    addr_to_data_f[bit_idx] = addr_i[bit_idx]; // 低于地址位宽的 bit 直接拷贝地址值
                end
                else begin
                    addr_to_data_f[bit_idx] = 1'b0; // 超出地址位宽的高 bit 统一补 0
                end
            end
        end
    endfunction

    // 当前阶段对应的写入数据。
    function [DATA_W-1:0] phase_write_data_f;
        input [7:0]           phase_i;             // 当前测试阶段编号
        input [ADDR_W-1:0]    addr_i;              // 当前正在测试的 SRAM 地址
        begin
            case (phase_i)
                PH_W0000: begin
                    phase_write_data_f = 16'h0000; // 全 0 测试用于验证基本写入和数据线低电平
                end

                PH_WFFFF: begin
                    phase_write_data_f = 16'hFFFF; // 全 1 测试用于验证基本写入和数据线高电平
                end

                PH_WAAAA: begin
                    phase_write_data_f = 16'hAAAA; // 棋盘格 1010... 用于交替翻转相邻数据位
                end

                PH_W5555: begin
                    phase_write_data_f = 16'h5555; // 棋盘格 0101... 与 0xAAAA 形成互补覆盖
                end

                PH_WADDR: begin
                    phase_write_data_f = addr_to_data_f(addr_i); // 地址码测试用于检测地址线镜像和重叠
                end

                PH_WNADR: begin
                    phase_write_data_f = ~addr_to_data_f(addr_i); // 地址码取反用于扩展地址相关故障覆盖
                end

                PH_W55AA: begin
                    phase_write_data_f = 16'h55AA; // 字节测试前先建立整字基准值 0x55AA
                end

                PH_WLB: begin
                    phase_write_data_f = 16'h00CC; // 仅写低字节，把低 8 位改成 0xCC
                end

                PH_WUB: begin
                    phase_write_data_f = 16'h7700; // 仅写高字节，把高 8 位改成 0x77
                end

                default: begin
                    phase_write_data_f = {DATA_W{1'b0}}; // 读阶段的写数据无效，统一输出 0
                end
            endcase
        end
    endfunction

    // 当前阶段对应的期望读回数据。
    function [DATA_W-1:0] phase_expect_data_f;
        input [7:0]           phase_i;             // 当前测试阶段编号
        input [ADDR_W-1:0]    addr_i;              // 当前正在测试的 SRAM 地址
        begin
            case (phase_i)
                PH_R0000: begin
                    phase_expect_data_f = 16'h0000; // 对应前一阶段写入的全 0 数据
                end

                PH_RFFFF: begin
                    phase_expect_data_f = 16'hFFFF; // 对应前一阶段写入的全 1 数据
                end

                PH_RAAAA: begin
                    phase_expect_data_f = 16'hAAAA; // 对应前一阶段写入的 0xAAAA 数据
                end

                PH_R5555: begin
                    phase_expect_data_f = 16'h5555; // 对应前一阶段写入的 0x5555 数据
                end

                PH_RADDR: begin
                    phase_expect_data_f = addr_to_data_f(addr_i); // 读回时应与地址低位折算结果一致
                end

                PH_RNADR: begin
                    phase_expect_data_f = ~addr_to_data_f(addr_i); // 读回时应与地址低位折算结果取反一致
                end

                PH_R55AA: begin
                    phase_expect_data_f = 16'h55AA; // 字节测试基准值读回比较
                end

                PH_RLB: begin
                    phase_expect_data_f = 16'h55CC; // 仅改写低字节后，高字节应保持 0x55
                end

                PH_RUB: begin
                    phase_expect_data_f = 16'h77CC; // 仅改写高字节后，低字节应继续保持 0xCC
                end

                default: begin
                    phase_expect_data_f = {DATA_W{1'b0}}; // 写阶段不使用期望值，统一输出 0
                end
            endcase
        end
    endfunction

endmodule

`default_nettype wire
