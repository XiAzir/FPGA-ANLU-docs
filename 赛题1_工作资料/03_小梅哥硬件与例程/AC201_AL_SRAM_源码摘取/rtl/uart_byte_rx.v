`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : uart_byte_rx.v
// 模块名称 : uart_byte_rx
// 功能说明 : 单字节 UART 接收器，采用 1bit 起始位、8bit 数据位、1bit 停止位。
//            该模块只负责把串口电平恢复为字节数据，并给出接收完成脉冲。
// 上层调用 : sram_uart_top
// 时钟说明 : clk_i，50 MHz 系统时钟
// 复位说明 : rst_n_i，低有效异步复位
// 修改记录 :
//   2026-04-22  重构版本，统一当前工程的命名、复位和参数接口
//------------------------------------------------------------------------------

module uart_byte_rx #(
    parameter integer CLKS_PER_BIT = 434            // 50 MHz 下对应 115200 波特率
) (
    input   wire            clk_i,                  // 系统时钟输入
    input   wire            rst_n_i,                // 低有效异步复位输入
    input   wire            uart_rx_i,              // UART 串口接收引脚
    output  reg     [7:0]   data_byte_o,            // 接收到的 1 字节数据
    output  reg             rx_done_o,              // 接收完成单拍脉冲
    output  reg             frame_err_o             // 停止位错误单拍脉冲
);

    localparam  [1:0]   S_IDLE  = 2'd0;             // 空闲状态，等待起始位下降沿
    localparam  [1:0]   S_START = 2'd1;             // 起始位确认状态，在半比特位置复核起始位
    localparam  [1:0]   S_DATA  = 2'd2;             // 数据接收状态，按位采样 8bit 数据
    localparam  [1:0]   S_STOP  = 2'd3;             // 停止位检查状态，确认帧格式正确
    localparam  integer HALF_CLKS_PER_BIT =
                (CLKS_PER_BIT > 1) ? (CLKS_PER_BIT / 2) : 1; // 起始位中点采样计数

    reg     [1:0]       st_cur_r;                   // 当前接收状态寄存器
    reg     [15:0]      baud_cnt_r;                 // 比特周期计数器
    reg     [2:0]       bit_idx_r;                  // 当前正在接收的数据位编号
    reg     [7:0]       shift_r;                    // 串并转换移位寄存器
    reg                 rx_sync1_r;                 // 接收输入第 1 级同步寄存器
    reg                 rx_sync2_r;                 // 接收输入第 2 级同步寄存器
    reg                 rx_sync3_r;                 // 接收输入延迟寄存器，用于下降沿检测
    wire                w_rx_fall;                  // 同步后的 UART 起始位下降沿脉冲

    // 通过三级同步链把异步串口输入带入时钟域，同时保留一个历史值用于下降沿检测。
    assign w_rx_fall = rx_sync3_r && !rx_sync2_r;   // 检测空闲高电平到起始位低电平的跳变

    // ---- 输入同步寄存器组：把 UART 异步输入稳定到 clk_i 时钟域 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rx_sync1_r <= 1'b1;                     // 复位后把 UART 总线视为空闲高电平
            rx_sync2_r <= 1'b1;                     // 复位后把 UART 总线视为空闲高电平
            rx_sync3_r <= 1'b1;                     // 复位后把 UART 总线视为空闲高电平
        end
        else begin
            rx_sync1_r <= uart_rx_i;                // 第 1 级同步，吸收异步输入毛刺风险
            rx_sync2_r <= rx_sync1_r;               // 第 2 级同步，提供稳定采样值
            rx_sync3_r <= rx_sync2_r;               // 延迟 1 拍，用于下降沿检测
        end
    end

    // ---- UART 接收主状态机：完成起始位确认、数据采样和停止位检查 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            st_cur_r    <= S_IDLE;                  // 复位后回到空闲状态
            baud_cnt_r  <= 16'd0;                   // 复位后清零比特计数器
            bit_idx_r   <= 3'd0;                    // 复位后清零位索引
            shift_r     <= 8'h00;                   // 复位后清空移位寄存器
            data_byte_o <= 8'h00;                   // 复位后清空输出数据寄存器
            rx_done_o   <= 1'b0;                    // 复位后拉低接收完成脉冲
            frame_err_o <= 1'b0;                    // 复位后拉低帧错误脉冲
        end
        else begin
            rx_done_o   <= 1'b0;                    // 默认每拍拉低，只有真正接收完成时拉高 1 拍
            frame_err_o <= 1'b0;                    // 默认每拍拉低，只有停止位错误时拉高 1 拍

            case (st_cur_r)
                S_IDLE: begin
                    baud_cnt_r <= 16'd0;            // 空闲期间持续清零比特计数器
                    bit_idx_r  <= 3'd0;             // 空闲期间预置位索引，便于后续从 bit0 开始接收

                    if (w_rx_fall) begin
                        st_cur_r <= S_START;        // 检测到起始位下降沿后进入起始位确认状态
                    end
                    else begin
                        st_cur_r <= S_IDLE;         // 未检测到新起始位时保持空闲状态
                    end
                end

                S_START: begin
                    if (baud_cnt_r == (HALF_CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 到达半比特位置后清零计数器，准备按整比特间隔采样

                        if (!rx_sync2_r) begin
                            st_cur_r <= S_DATA;     // 中点仍为低电平，确认起始位有效
                            bit_idx_r <= 3'd0;      // 下一阶段从最低位 bit0 开始接收
                        end
                        else begin
                            st_cur_r <= S_IDLE;     // 中点已恢复高电平，说明是毛刺，直接丢弃
                        end
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 继续等待到达起始位中点
                        st_cur_r   <= S_START;      // 起始位确认完成前保持当前状态
                    end
                end

                S_DATA: begin
                    if (baud_cnt_r == (CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 当前比特采样完成后清零计数器，准备下一位
                        shift_r[bit_idx_r] <= rx_sync2_r; // 按 LSB first 的 UART 约定写入当前采样位

                        if (bit_idx_r == 3'd7) begin
                            st_cur_r <= S_STOP;     // 收满 8 位数据后转去检查停止位
                        end
                        else begin
                            bit_idx_r <= bit_idx_r + 1'b1; // 继续接收下一位数据
                            st_cur_r  <= S_DATA;    // 数据尚未收满时保持数据接收状态
                        end
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 尚未到达采样点时继续累计比特计数
                        st_cur_r   <= S_DATA;       // 等待下一次采样时钟
                    end
                end

                S_STOP: begin
                    if (baud_cnt_r == (CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 停止位检查完成后清零计数器
                        st_cur_r   <= S_IDLE;       // 当前帧结束后返回空闲状态等待下一帧

                        if (rx_sync2_r) begin
                            data_byte_o <= shift_r; // 停止位正确时锁存本帧接收到的 8bit 数据
                            rx_done_o   <= 1'b1;    // 输出 1 拍接收完成脉冲供上层取数
                        end
                        else begin
                            frame_err_o <= 1'b1;    // 停止位不是高电平时报告帧错误
                        end
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 停止位窗口未结束时继续等待
                        st_cur_r   <= S_STOP;       // 停止位检查完成前保持当前状态
                    end
                end

                default: begin
                    st_cur_r    <= S_IDLE;          // 非法状态统一回到空闲状态
                    baud_cnt_r  <= 16'd0;           // 回退时清零计数器，避免残留计数影响下一帧
                    bit_idx_r   <= 3'd0;            // 回退时清零位索引
                    shift_r     <= 8'h00;           // 回退时清空移位寄存器
                    data_byte_o <= data_byte_o;     // 保持上一次成功接收的数据输出
                    rx_done_o   <= 1'b0;            // 非法状态恢复过程中不产生完成脉冲
                    frame_err_o <= 1'b0;            // 非法状态恢复过程中不产生错误脉冲
                end
            endcase
        end
    end

endmodule

`default_nettype wire
