`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : sram_bist_top.v
// 模块名称 : sram_bist_top
// 功能说明 : 板级顶层，实例化异步 SRAM 控制器和 BIST 序列器。
//            上电后自动运行 SRAM 自检，并通过独立 LED 给出运行/通过/失败指示。
// 上层调用 : 独立顶层
// 时钟说明 : clk50_i，板载 50 MHz 振荡器
// 复位说明 : 采用内部上电等待计数器产生启动延时
// 修改记录 :
//   2026-04-22 初版，完成纯 FPGA 自检顶层封装。
//------------------------------------------------------------------------------

module sram_bist_top #(
    parameter           ADDR_W          = 18,       // 板上实装 SRAM 的有效地址宽度
    parameter           DATA_W          = 16,       // 板上 SRAM 的数据宽度
    parameter           POR_CNT_W       = 20,       // 上电等待计数器位宽，默认约 20 ms 启动延时
    parameter           RUN_BLINK_BIT   = 24,       // 运行中 LED 慢闪分频位
    parameter           FAIL_BLINK_BIT  = 22,       // 失败后 LED 快闪分频位
    parameter           LED_ACTIVE_LOW  = 1         // 板上独立 LED 为低有效时取 1
) (
    input   wire                    clk50_i,        // 板载 50 MHz 时钟输入
    output  wire                    led0_o,         // 独立 LED0，运行结果显示输出

    output  wire    [ADDR_W-1:0]    sram_addr_o,    // 外挂 SRAM 地址总线
    inout   wire    [DATA_W-1:0]    sram_dq_io,     // 外挂 SRAM 双向数据总线
    output  wire                    sram_ce_n_o,    // 外挂 SRAM 片选，低有效
    output  wire                    sram_oe_n_o,    // 外挂 SRAM 输出使能，低有效
    output  wire                    sram_we_n_o,    // 外挂 SRAM 写使能，低有效
    output  wire                    sram_lb_n_o,    // 外挂 SRAM 低字节使能，低有效
    output  wire                    sram_ub_n_o     // 外挂 SRAM 高字节使能，低有效
);

    reg     [POR_CNT_W-1:0]    por_cnt_r;           // 上电等待计数器，用于给 SRAM 电源和管脚稳定留裕量
    reg     [31:0]             blink_cnt_r;         // LED 心跳计数器，用于运行态和失败态闪烁显示

    wire                       w_por_done;          // 上电等待是否完成
    wire                       w_rst_n;             // 送往控制器和 BIST 的内部低有效复位
    wire                       w_cmd_valid;         // BIST 发给控制器的命令有效
    wire                       w_cmd_write;         // BIST 发给控制器的读写方向
    wire   [ADDR_W-1:0]        w_cmd_addr;          // BIST 发给控制器的访问地址
    wire   [DATA_W-1:0]        w_cmd_wdata;         // BIST 发给控制器的写数据
    wire   [1:0]               w_cmd_byte_en;       // BIST 发给控制器的字节使能
    wire                       w_cmd_ready;         // 控制器对 BIST 返回的 ready
    wire                       w_rsp_valid;         // 控制器对 BIST 返回的完成脉冲
    wire   [DATA_W-1:0]        w_rsp_rdata;         // 控制器对 BIST 返回的读数据
    wire                       w_bist_done;         // BIST 全流程结束指示
    wire                       w_bist_pass;         // BIST 通过指示
    wire                       w_bist_fail;         // BIST 失败指示
    wire   [7:0]               w_fail_stage;        // BIST 锁存的失败阶段编号
    wire   [ADDR_W-1:0]        w_fail_addr;         // BIST 锁存的失败地址
    wire   [DATA_W-1:0]        w_fail_exp_data;     // BIST 锁存的期望数据
    wire   [DATA_W-1:0]        w_fail_rd_data;      // BIST 锁存的实际读回数据
    wire                       w_led_on;            // 逻辑上的“点亮 LED”控制信号，高电平表示想点亮 LED

    // ---- 上电初值: 让 POR 计数器和 LED 分频计数器从确定值启动 ----
    initial begin
        por_cnt_r   = {POR_CNT_W{1'b0}};            // 利用 FPGA 配置后的寄存器初值能力，让 POR 计数从 0 开始
        blink_cnt_r = 32'd0;                        // 让 LED 分频计数器从 0 开始，保证仿真和上板表现一致
    end

    // 计数器全 1 时表示上电等待已经完成，内部复位可以释放。
    assign w_por_done = &por_cnt_r;                 // 使用全 1 饱和计数方式，避免额外比较器

    // 内部低有效复位在上电等待结束前一直保持为低。
    assign w_rst_n = w_por_done;                    // 等待 SRAM 供电和 IO 稳定后再启动 BIST

    // 板上独立 LED 为低有效时输出取反，否则直接输出逻辑点亮信号。
    assign led0_o = LED_ACTIVE_LOW ? ~w_led_on : w_led_on; // 兼容低有效和高有效两类 LED 接法

    // 通过状态常亮、失败状态快闪、运行状态慢闪。
    assign w_led_on = w_bist_pass                 ? 1'b1 :                 // 测试全部通过后保持常亮
                      w_bist_fail                 ? blink_cnt_r[FAIL_BLINK_BIT] : // 失败后使用更快的闪烁节奏提示异常
                      blink_cnt_r[RUN_BLINK_BIT];   // 运行中使用慢闪提示正在执行 BIST

    // ---- por_cnt_r: 上电等待计数器 ----
    always @(posedge clk50_i) begin
        if (!w_por_done) begin
            por_cnt_r <= por_cnt_r + 1'b1;         // 上电后持续计数，直到计数器饱和为全 1
        end
        else begin
            por_cnt_r <= por_cnt_r;                // 计数器饱和后保持不变，稳定释放内部复位
        end
    end

    // ---- blink_cnt_r: LED 闪烁分频计数器 ----
    always @(posedge clk50_i) begin
        if (!w_rst_n) begin
            blink_cnt_r <= 32'd0;                  // 复位期间清零闪烁计数器，保证 LED 从确定状态开始
        end
        else begin
            blink_cnt_r <= blink_cnt_r + 1'b1;     // BIST 运行后持续累加，用于产生不同节奏的闪烁信号
        end
    end

    // 该实例负责把 BIST 发出的单次读写命令转换为板级 SRAM 可接受的固定多拍时序。
    sram_async_ctrl #(
        .ADDR_W                 (ADDR_W            ), // 顶层地址宽度直接透传给控制器
        .DATA_W                 (DATA_W            )  // 顶层数据宽度直接透传给控制器
    ) u_sram_async_ctrl (
        .clk_i                  (clk50_i           ), // 控制器工作在板载 50 MHz 单时钟域
        .rst_n_i                (w_rst_n           ), // 上电等待完成后释放控制器内部复位
        .cmd_valid_i            (w_cmd_valid       ), // 接收 BIST 发出的命令有效脉冲
        .cmd_write_i            (w_cmd_write       ), // 接收 BIST 指定的读写方向
        .cmd_addr_i             (w_cmd_addr        ), // 接收 BIST 指定的访问地址
        .cmd_wdata_i            (w_cmd_wdata       ), // 接收 BIST 指定的写数据
        .cmd_byte_en_i          (w_cmd_byte_en     ), // 接收 BIST 指定的字节使能
        .cmd_ready_o            (w_cmd_ready       ), // 向 BIST 返回控制器 ready
        .rsp_valid_o            (w_rsp_valid       ), // 向 BIST 返回单次命令完成脉冲
        .rsp_rdata_o            (w_rsp_rdata       ), // 向 BIST 返回读命令采样数据
        .sram_addr_o            (sram_addr_o       ), // 直接驱动板级 SRAM 地址总线
        .sram_dq_io             (sram_dq_io        ), // 直接连接板级 SRAM 双向数据总线
        .sram_ce_n_o            (sram_ce_n_o       ), // 直接驱动板级 SRAM 片选信号
        .sram_oe_n_o            (sram_oe_n_o       ), // 直接驱动板级 SRAM 输出使能信号
        .sram_we_n_o            (sram_we_n_o       ), // 直接驱动板级 SRAM 写使能信号
        .sram_lb_n_o            (sram_lb_n_o       ), // 直接驱动板级 SRAM 低字节使能信号
        .sram_ub_n_o            (sram_ub_n_o       )  // 直接驱动板级 SRAM 高字节使能信号
    );

    // 该实例负责按照固定阶段和全地址遍历方式执行 SRAM BIST，并锁存首个失败上下文。
    sram_bist_engine #(
        .ADDR_W                 (ADDR_W            ), // 顶层地址宽度直接透传给 BIST 引擎
        .DATA_W                 (DATA_W            )  // 顶层数据宽度直接透传给 BIST 引擎
    ) u_bist (
        .clk_i                  (clk50_i           ), // BIST 与控制器共用板载 50 MHz 时钟
        .rst_n_i                (w_rst_n           ), // 上电等待完成后释放 BIST 内部复位
        .cmd_valid_o            (w_cmd_valid       ), // 向控制器输出命令有效脉冲
        .cmd_write_o            (w_cmd_write       ), // 向控制器输出读写方向
        .cmd_addr_o             (w_cmd_addr        ), // 向控制器输出访问地址
        .cmd_wdata_o            (w_cmd_wdata       ), // 向控制器输出写数据
        .cmd_byte_en_o          (w_cmd_byte_en     ), // 向控制器输出字节使能
        .cmd_ready_i            (w_cmd_ready       ), // 接收控制器 ready 状态
        .rsp_valid_i            (w_rsp_valid       ), // 接收控制器完成脉冲
        .rsp_rdata_i            (w_rsp_rdata       ), // 接收控制器返回读数据
        .done_o                 (w_bist_done       ), // 对顶层输出 BIST 完成状态
        .pass_o                 (w_bist_pass       ), // 对顶层输出 BIST 通过状态
        .fail_o                 (w_bist_fail       ), // 对顶层输出 BIST 失败状态
        .fail_stage_o           (w_fail_stage      ), // 失败阶段信息保留在顶层内部，便于后续片上调试
        .fail_addr_o            (w_fail_addr       ), // 失败地址信息保留在顶层内部，便于后续片上调试
        .exp_data_o             (w_fail_exp_data   ), // 期望数据保留在顶层内部，便于后续片上调试
        .rd_data_o              (w_fail_rd_data    )  // 实际读回数据保留在顶层内部，便于后续片上调试
    );

endmodule

`default_nettype wire
