`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : uart_byte_tx.v
// 模块名称 : uart_byte_tx
// 功能说明 : 单字节 UART 发送器，采用 1bit 起始位、8bit 数据位、1bit 停止位。
//            上层给出 send_en_i 单拍脉冲后，本模块会把 data_byte_i 发送到串口线上。
// 上层调用 : sram_uart_top
// 时钟说明 : clk_i，50 MHz 系统时钟
// 复位说明 : rst_n_i，低有效异步复位
// 修改记录 :
//   2026-04-22  重构版本，统一当前工程的命名、复位和参数接口
//------------------------------------------------------------------------------

module uart_byte_tx #(
    parameter integer CLKS_PER_BIT = 434            // 50 MHz 下对应 115200 波特率
) (
    input   wire            clk_i,                  // 系统时钟输入
    input   wire            rst_n_i,                // 低有效异步复位输入
    input   wire    [7:0]   data_byte_i,            // 待发送的 1 字节数据
    input   wire            send_en_i,              // 发送请求单拍脉冲
    output  reg             uart_tx_o,              // UART 串口发送引脚
    output  reg             tx_busy_o,              // 发送忙标志，高电平表示正在发送当前字节
    output  reg             tx_done_o               // 发送完成单拍脉冲
);

    localparam  [1:0]   S_IDLE  = 2'd0;             // 空闲状态，等待上层发起发送请求
    localparam  [1:0]   S_START = 2'd1;             // 起始位发送状态，输出固定低电平
    localparam  [1:0]   S_DATA  = 2'd2;             // 数据发送状态，按 LSB first 顺序输出 8bit 数据
    localparam  [1:0]   S_STOP  = 2'd3;             // 停止位发送状态，输出固定高电平

    reg     [1:0]       st_cur_r;                   // 当前发送状态寄存器
    reg     [15:0]      baud_cnt_r;                 // 比特周期计数器
    reg     [2:0]       bit_idx_r;                  // 当前正在发送的数据位编号
    reg     [7:0]       data_latch_r;               // 发送开始时锁存的字节数据

    // ---- UART 发送主状态机：完成起始位、数据位和停止位的顺序发送 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            st_cur_r     <= S_IDLE;                 // 复位后回到空闲状态
            baud_cnt_r   <= 16'd0;                  // 复位后清零比特计数器
            bit_idx_r    <= 3'd0;                   // 复位后清零位索引
            data_latch_r <= 8'h00;                  // 复位后清空发送缓存
            uart_tx_o    <= 1'b1;                   // UART 空闲线电平为高
            tx_busy_o    <= 1'b0;                   // 复位后不处于发送忙状态
            tx_done_o    <= 1'b0;                   // 复位后不输出发送完成脉冲
        end
        else begin
            tx_done_o <= 1'b0;                      // 默认每拍拉低，只有发送完成时拉高 1 拍

            case (st_cur_r)
                S_IDLE: begin
                    baud_cnt_r <= 16'd0;            // 空闲期间保持比特计数器清零
                    bit_idx_r  <= 3'd0;             // 空闲期间预置位索引，便于后续从 bit0 发送
                    uart_tx_o  <= 1'b1;             // 空闲状态持续驱动高电平
                    tx_busy_o  <= 1'b0;             // 空闲状态对上层声明可接收新字节

                    if (send_en_i) begin
                        data_latch_r <= data_byte_i; // 检测到发送请求后锁存待发送字节
                        st_cur_r     <= S_START;    // 进入起始位发送状态
                        uart_tx_o    <= 1'b0;       // 起始位固定输出低电平
                        tx_busy_o    <= 1'b1;       // 从起始位开始到停止位结束都保持忙状态
                    end
                    else begin
                        st_cur_r <= S_IDLE;         // 没有新发送请求时保持空闲状态
                    end
                end

                S_START: begin
                    tx_busy_o <= 1'b1;              // 起始位期间保持忙状态，禁止上层插入新字节

                    if (baud_cnt_r == (CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 起始位时长满足后清零计数器
                        bit_idx_r  <= 3'd0;         // 进入数据阶段前从 bit0 开始发送
                        uart_tx_o  <= data_latch_r[0]; // 先送出最低位，符合 UART LSB first 约定
                        st_cur_r   <= S_DATA;       // 起始位结束后进入数据发送状态
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 起始位未发送满一个比特周期时继续计数
                        st_cur_r   <= S_START;      // 起始位未完成前保持当前状态
                    end
                end

                S_DATA: begin
                    tx_busy_o <= 1'b1;              // 数据发送期间保持忙状态

                    if (baud_cnt_r == (CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 当前数据位发送满 1bit 后清零计数器

                        if (bit_idx_r == 3'd7) begin
                            uart_tx_o <= 1'b1;      // 数据最后一位发送完成后切换到停止位高电平
                            st_cur_r  <= S_STOP;    // 8bit 数据全部送完后进入停止位状态
                        end
                        else begin
                            bit_idx_r <= bit_idx_r + 1'b1; // 继续推进到下一位数据
                            uart_tx_o <= data_latch_r[bit_idx_r + 1'b1]; // 提前切换到下一位输出数据
                            st_cur_r  <= S_DATA;    // 数据尚未发送完时保持数据发送状态
                        end
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 当前数据位时长未到时继续计数
                        st_cur_r   <= S_DATA;       // 等待当前数据位发送满 1bit
                    end
                end

                S_STOP: begin
                    tx_busy_o <= 1'b1;              // 停止位期间仍处于发送忙状态
                    uart_tx_o <= 1'b1;              // 停止位固定输出高电平

                    if (baud_cnt_r == (CLKS_PER_BIT - 1)) begin
                        baud_cnt_r <= 16'd0;        // 停止位发送完成后清零计数器
                        tx_busy_o  <= 1'b0;         // 整个字节发送结束，释放忙状态
                        tx_done_o  <= 1'b1;         // 对上层输出 1 拍发送完成脉冲
                        st_cur_r   <= S_IDLE;       // 返回空闲状态等待下一个字节
                    end
                    else begin
                        baud_cnt_r <= baud_cnt_r + 1'b1; // 停止位未发送满 1bit 时继续计数
                        st_cur_r   <= S_STOP;       // 停止位未完成前保持当前状态
                    end
                end

                default: begin
                    st_cur_r     <= S_IDLE;         // 非法状态统一恢复为空闲状态
                    baud_cnt_r   <= 16'd0;          // 恢复时清零计数器，避免残留计数影响下一次发送
                    bit_idx_r    <= 3'd0;           // 恢复时清零位索引
                    data_latch_r <= data_latch_r;   // 保持上一次锁存数据，不影响后续新的 send_en
                    uart_tx_o    <= 1'b1;           // 恢复时重新驱动空闲高电平
                    tx_busy_o    <= 1'b0;           // 恢复时释放忙状态
                    tx_done_o    <= 1'b0;           // 非法状态恢复过程中不输出完成脉冲
                end
            endcase
        end
    end

endmodule

`default_nettype wire
