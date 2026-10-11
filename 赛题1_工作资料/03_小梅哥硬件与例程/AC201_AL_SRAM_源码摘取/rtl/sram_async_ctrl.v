`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : sram_async_ctrl.v
// 模块名称 : sram_async_ctrl
// 功能说明 : 以 50 MHz 系统时钟驱动异步 SRAM，采用固定多拍时序完成单次读写。
//            该模块只负责板级 SRAM 访问时序，不负责测试序列、比较和错误锁存。
// 上层调用 : sram_bist_top
// 时钟说明 : clk_i，单时钟域
// 复位说明 : rst_n_i，低有效
// 修改记录 :
//   2026-04-22 初版，完成异步 SRAM 固定时序控制器。
//------------------------------------------------------------------------------

module sram_async_ctrl #(
    parameter           ADDR_W      = 18,           // SRAM 地址总线位宽
    parameter           DATA_W      = 16            // SRAM 数据总线位宽
) (
    input   wire                    clk_i,          // 系统时钟
    input   wire                    rst_n_i,        // 异步低有效复位

    input   wire                    cmd_valid_i,    // 上层命令有效脉冲
    input   wire                    cmd_write_i,    // 命令方向，1 表示写，0 表示读
    input   wire    [ADDR_W-1:0]    cmd_addr_i,     // 命令目标地址
    input   wire    [DATA_W-1:0]    cmd_wdata_i,    // 写命令需要送出的数据
    input   wire    [1:0]           cmd_byte_en_i,  // 字节使能，[1] 对应高字节，[0] 对应低字节
    output  wire                    cmd_ready_o,    // 控制器空闲，可接受新命令
    output  wire                    rsp_valid_o,    // 本次命令完成脉冲
    output  wire    [DATA_W-1:0]    rsp_rdata_o,    // 读命令返回的数据

    output  wire    [ADDR_W-1:0]    sram_addr_o,    // 送往 SRAM 的地址总线
    inout   wire    [DATA_W-1:0]    sram_dq_io,     // 与 SRAM 相连的双向数据总线
    output  wire                    sram_ce_n_o,    // SRAM 片选，低有效
    output  wire                    sram_oe_n_o,    // SRAM 输出使能，低有效
    output  wire                    sram_we_n_o,    // SRAM 写使能，低有效
    output  wire                    sram_lb_n_o,    // SRAM 低字节使能，低有效
    output  wire                    sram_ub_n_o     // SRAM 高字节使能，低有效
);

    localparam  [2:0]   S_IDLE          = 3'd0;     // 控制器空闲，等待上层发出新命令
    localparam  [2:0]   S_WRITE_SETUP   = 3'd1;     // 写周期准备拍，提前给出地址和写数据
    localparam  [2:0]   S_WRITE_PULSE   = 3'd2;     // 写周期有效拍，拉低 WE# 完成实际写入
    localparam  [2:0]   S_WRITE_HOLD    = 3'd3;     // 写周期保持拍，满足写后保持要求
    localparam  [2:0]   S_READ_SETUP    = 3'd4;     // 读周期准备拍，给出地址并拉低 CE#/OE#
    localparam  [2:0]   S_READ_WAIT     = 3'd5;     // 读周期等待拍，为异步 SRAM 留出访问时间
    localparam  [2:0]   S_READ_CAPTURE  = 3'd6;     // 读周期采样拍，在时钟沿锁存 SRAM 返回数据
    localparam  [2:0]   S_DONE          = 3'd7;     // 命令完成拍，对上层输出 rsp_valid_o

    reg     [2:0]           st_cur_r;               // 当前状态寄存器
    reg     [2:0]           st_nxt_r;               // 下一状态组合结果
    reg     [ADDR_W-1:0]    cmd_addr_r;             // 已锁存的命令地址
    reg     [DATA_W-1:0]    cmd_wdata_r;            // 已锁存的写数据
    reg     [1:0]           cmd_byte_en_r;          // 已锁存的字节使能
    reg     [DATA_W-1:0]    rsp_rdata_r;            // 读命令采样得到的数据寄存器

    wire                    w_write_state;          // 当前状态是否属于写访问流程
    wire                    w_read_state;           // 当前状态是否属于读访问流程
    wire                    w_access_state;         // 当前状态是否处于 SRAM 有效访问窗口
    wire    [DATA_W-1:0]    w_sram_dq_in;           // 从 SRAM 数据总线读回的实时电平

    // 读命令只在 READ_SETUP / READ_WAIT / READ_CAPTURE 三个状态打开 CE# 和 OE#。
    assign w_read_state = (st_cur_r == S_READ_SETUP)   || // 读周期准备拍需要使能 SRAM 输出
                          (st_cur_r == S_READ_WAIT)    || // 读周期等待拍继续保持输出打开
                          (st_cur_r == S_READ_CAPTURE);  // 读周期采样拍继续保持输出打开

    // 写命令只在 WRITE_SETUP / WRITE_PULSE / WRITE_HOLD 三个状态驱动地址和写数据。
    assign w_write_state = (st_cur_r == S_WRITE_SETUP) || // 写周期准备拍，先稳定地址和写数据
                           (st_cur_r == S_WRITE_PULSE) || // 写周期有效拍，WE# 拉低完成写入
                           (st_cur_r == S_WRITE_HOLD);   // 写周期保持拍，满足写后保持时间

    // 只要当前处于读状态或写状态，就保持 SRAM 片选有效。
    assign w_access_state = w_read_state || w_write_state; // 访问窗口内 CE# 需要保持为低

    // 控制器只有在 IDLE 状态才允许上层发起新命令。
    assign cmd_ready_o = (st_cur_r == S_IDLE);      // 空闲状态返回 ready，简化上层握手时序

    // DONE 状态持续一个时钟周期，用该状态直接作为完成脉冲。
    assign rsp_valid_o = (st_cur_r == S_DONE);      // 命令完成后对上层输出单拍有效脉冲

    // 读数据在 READ_CAPTURE 状态锁存到寄存器，DONE 状态再返回给上层。
    assign rsp_rdata_o = rsp_rdata_r;               // 返回最近一次读命令采样得到的数据

    // SRAM 地址总线在整个访问期间都输出锁存后的命令地址。
    assign sram_addr_o = cmd_addr_r;                // 地址在开始访问时锁存，后续保持稳定

    // SRAM 双向数据总线只在写周期内由 FPGA 驱动，其余时间释放为高阻。
    assign sram_dq_io = w_write_state ? cmd_wdata_r : {DATA_W{1'bz}}; // 写时驱动数据，读时释放总线

    // 读周期通过双向总线直接采样 SRAM 当前返回的数据。
    assign w_sram_dq_in = sram_dq_io;               // 读数据在 READ_CAPTURE 时钟沿锁存

    // 片选在读写访问窗口内始终拉低，空闲和 DONE 状态恢复为高电平。
    assign sram_ce_n_o = w_access_state ? 1'b0 : 1'b1; // 访问时片选有效，结束后关闭芯片

    // 读状态下拉低 OE#，写状态和空闲状态都保持 OE# 为高，避免总线冲突。
    assign sram_oe_n_o = w_read_state ? 1'b0 : 1'b1; // 只有读访问才允许 SRAM 驱动数据总线

    // 只有在 WRITE_PULSE 状态拉低 WE#，其余状态都保持写禁止。
    assign sram_we_n_o = (st_cur_r == S_WRITE_PULSE) ? 1'b0 : 1'b1; // 固定单拍写脉冲，易于板级分析

    // 只在访问窗口内根据锁存后的字节使能拉低 LB#，空闲时统一拉高。
    assign sram_lb_n_o = w_access_state ? ~cmd_byte_en_r[0] : 1'b1; // 低字节访问时才拉低 LB#

    // 只在访问窗口内根据锁存后的字节使能拉低 UB#，空闲时统一拉高。
    assign sram_ub_n_o = w_access_state ? ~cmd_byte_en_r[1] : 1'b1; // 高字节访问时才拉低 UB#

    // ---- st_cur_r: 控制器状态寄存器 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            st_cur_r <= S_IDLE;                     // 复位后回到空闲状态，禁止任何 SRAM 访问
        end
        else begin
            st_cur_r <= st_nxt_r;                  // 每拍根据组合次态更新控制器状态
        end
    end

    // ---- st_nxt_r: 控制器状态转移组合逻辑 ----
    always @(*) begin
        st_nxt_r = st_cur_r;                       // 默认保持当前状态，避免组合逻辑不完整

        case (st_cur_r)
            S_IDLE: begin
                if (cmd_valid_i && cmd_write_i) begin
                    st_nxt_r = S_WRITE_SETUP;      // 上层发出写命令后先进入写准备拍
                end
                else if (cmd_valid_i && !cmd_write_i) begin
                    st_nxt_r = S_READ_SETUP;       // 上层发出读命令后先进入读准备拍
                end
                else begin
                    st_nxt_r = S_IDLE;             // 没有新命令时保持空闲状态
                end
            end

            S_WRITE_SETUP: begin
                st_nxt_r = S_WRITE_PULSE;          // 地址和数据稳定一拍后进入写脉冲拍
            end

            S_WRITE_PULSE: begin
                st_nxt_r = S_WRITE_HOLD;           // 拉低 WE# 一拍后进入写保持拍
            end

            S_WRITE_HOLD: begin
                st_nxt_r = S_DONE;                 // 写后保持结束，进入完成拍
            end

            S_READ_SETUP: begin
                st_nxt_r = S_READ_WAIT;            // 给出地址后再等待一拍，留足异步访问时间
            end

            S_READ_WAIT: begin
                st_nxt_r = S_READ_CAPTURE;         // 等待一拍后在下一拍时钟沿采样 SRAM 数据
            end

            S_READ_CAPTURE: begin
                st_nxt_r = S_DONE;                 // 读数据锁存结束后进入完成拍
            end

            S_DONE: begin
                st_nxt_r = S_IDLE;                 // 完成脉冲输出一拍后回到空闲状态
            end

            default: begin
                st_nxt_r = S_IDLE;                 // 非法状态统一恢复到安全空闲状态
            end
        endcase
    end

    // ---- 命令锁存寄存器组: 在 IDLE 状态接受上层命令后锁存地址/数据/方向 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cmd_addr_r    <= {ADDR_W{1'b0}};       // 复位时清空地址寄存器，避免上电误访问
            cmd_wdata_r   <= {DATA_W{1'b0}};       // 复位时清空写数据寄存器
            cmd_byte_en_r <= 2'b00;                // 复位时关闭高低字节，避免控制脚误拉低
        end
        else if (cmd_valid_i && cmd_ready_o) begin
            cmd_addr_r    <= cmd_addr_i;           // 接收新命令时锁存访问地址
            cmd_wdata_r   <= cmd_wdata_i;          // 接收写命令时锁存需要驱动到 SRAM 的数据
            cmd_byte_en_r <= cmd_byte_en_i;        // 接收命令时锁存字节使能
        end
        else begin
            cmd_addr_r    <= cmd_addr_r;           // 访问进行期间保持地址稳定
            cmd_wdata_r   <= cmd_wdata_r;          // 访问进行期间保持写数据稳定
            cmd_byte_en_r <= cmd_byte_en_r;        // 访问进行期间保持字节使能稳定
        end
    end

    // ---- rsp_rdata_r: 在 READ_CAPTURE 状态锁存 SRAM 返回数据 ----
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rsp_rdata_r <= {DATA_W{1'b0}};         // 复位时清空返回数据寄存器
        end
        else if (st_cur_r == S_READ_CAPTURE) begin
            rsp_rdata_r <= w_sram_dq_in;           // 在采样拍锁存异步 SRAM 当前输出的数据
        end
        else begin
            rsp_rdata_r <= rsp_rdata_r;           // 非采样拍保持上一次读回的数据
        end
    end

endmodule

`default_nettype wire
