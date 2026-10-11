`timescale 1ns/1ps
`default_nettype none

//------------------------------------------------------------------------------
// 项目名称 : AC201_AL_SRAM
// 文件名称 : sram_uart_top.v
// 模块名称 : sram_uart_top
// 功能说明 : 通过 UART 文本命令直接读写板上的异步 SRAM，用于人工联调或上位机脚本验证。
//            本顶层不再自动遍历 BIST，而是保留现有异步 SRAM 控制器，通过串口桥接层按需访问。
// 上层调用 : 独立顶层
// 时钟说明 : clk50_i，板载 50 MHz 时钟
// 复位说明 : 采用内部上电等待计数器产生启动延时
// 修改记录 :
//   2026-04-22  初版，完成 UART->SRAM 读写验证顶层封装
// 使用方法 W00020=5678 表示写 SRAM[0x00020] <= 5678 ，应答 OK
// 使用方法 R00020   表示读 SRAM[0x00020]，读的值为5678
//------------------------------------------------------------------------------

module sram_uart_top #(
    parameter           ADDR_W              = 18,   // 板上实装 SRAM 的有效地址位宽
    parameter           DATA_W              = 16,   // 板上 SRAM 的数据位宽
    parameter           POR_CNT_W           = 20,   // 上电等待计数器位宽，默认约 20 ms 启动延时
    parameter integer   UART_CLKS_PER_BIT   = 434   // 50 MHz 下对应 115200 波特率
) (
    input   wire                    clk50_i,        // 板载 50 MHz 时钟输入
    input   wire                    uart_rx_i,      // 板载串口接收引脚
    output  wire                    uart_tx_o,      // 板载串口发送引脚
    output  wire    [ADDR_W-1:0]    sram_addr_o,    // 外挂 SRAM 地址总线
    inout   wire    [DATA_W-1:0]    sram_dq_io,     // 外挂 SRAM 双向数据总线
    output  wire                    sram_ce_n_o,    // 外挂 SRAM 片选，低有效
    output  wire                    sram_oe_n_o,    // 外挂 SRAM 输出使能，低有效
    output  wire                    sram_we_n_o,    // 外挂 SRAM 写使能，低有效
    output  wire                    sram_lb_n_o,    // 外挂 SRAM 低字节使能，低有效
    output  wire                    sram_ub_n_o     // 外挂 SRAM 高字节使能，低有效
);

    reg     [POR_CNT_W-1:0]    por_cnt_r;           // 上电等待计数器，用于给 SRAM 电源和 IO 留出稳定时间
    wire                       w_por_done;          // 上电等待是否完成
    wire                       w_rst_n;             // 送往 UART 和 SRAM 控制链路的内部低有效复位
    wire    [7:0]              w_rx_data;           // UART 接收器解出的 1 字节数据
    wire                       w_rx_done;           // UART 接收器给出的接收完成脉冲
    wire    [7:0]              w_tx_data;           // UART 桥接层送给 UART 发送器的 1 字节数据
    wire                       w_tx_send;           // UART 桥接层送给 UART 发送器的发送启动脉冲
    wire                       w_tx_busy;           // UART 发送器忙状态
    wire                       w_cmd_valid;         // UART 桥接层送给 SRAM 控制器的命令有效脉冲
    wire                       w_cmd_write;         // UART 桥接层送给 SRAM 控制器的读写方向
    wire    [ADDR_W-1:0]       w_cmd_addr;          // UART 桥接层送给 SRAM 控制器的目标地址
    wire    [DATA_W-1:0]       w_cmd_wdata;         // UART 桥接层送给 SRAM 控制器的写数据
    wire    [1:0]              w_cmd_byte_en;       // UART 桥接层送给 SRAM 控制器的字节使能
    wire                       w_cmd_ready;         // SRAM 控制器返回给 UART 桥接层的 ready
    wire                       w_rsp_valid;         // SRAM 控制器返回给 UART 桥接层的完成脉冲
    wire    [DATA_W-1:0]       w_rsp_rdata;         // SRAM 控制器返回给 UART 桥接层的读回数据

    // ---- 上电初值设置：确保 POR 计数器从确定值启动 ----
    initial begin
        por_cnt_r = {POR_CNT_W{1'b0}};              // 利用 FPGA 上电初始化能力让 POR 计数器从 0 起步
    end

    // 计数器全 1 时表示上电等待已经完成，内部复位可以释放。
    assign w_por_done = &por_cnt_r;                 // 采用全 1 饱和判断，避免额外比较器开销

    // UART 和 SRAM 控制链路都共用这一份上电释放后的内部复位。
    assign w_rst_n = w_por_done;                    // 等待板级供电和 IO 稳定后再启动串口和 SRAM 访问链路

    // ---- por_cnt_r: 上电等待计数器 ----
    always @(posedge clk50_i) begin
        if (!w_por_done) begin
            por_cnt_r <= por_cnt_r + 1'b1;          // 上电后持续累加，直到计数器饱和为全 1
        end
        else begin
            por_cnt_r <= por_cnt_r;                 // 计数器饱和后保持不变，稳定释放内部复位
        end
    end

    // 该实例负责把板载 UART RX 串行波形恢复成 8bit 字节流，供后续命令解析使用。
    uart_byte_rx #(
        .CLKS_PER_BIT           (UART_CLKS_PER_BIT  )  // 顶层统一参数化波特率分频，仿真和上板共用同一套接口
    ) u_uart_byte_rx (
        .clk_i                  (clk50_i            ), // 与整套 SRAM 访问链路共用 50 MHz 单时钟域
        .rst_n_i                (w_rst_n            ), // 上电等待结束后再启动 UART 接收，避免上电毛刺误触发
        .uart_rx_i              (uart_rx_i          ), // 直接连接板载串口 RX 引脚
        .data_byte_o            (w_rx_data          ), // 输出解析后的 UART 1 字节数据
        .rx_done_o              (w_rx_done          ), // 输出接收完成脉冲供桥接层取数
        .frame_err_o            (                   )  // 停止位错误当前不参与控制逻辑，保留空连接避免额外警告
    );

    // 该实例负责把桥接层准备好的 1 字节应答重新编码为 UART TX 串行波形发回上位机。
    uart_byte_tx #(
        .CLKS_PER_BIT           (UART_CLKS_PER_BIT  )  // 顶层统一参数化波特率分频，仿真和上板共用同一套接口
    ) u_uart_byte_tx (
        .clk_i                  (clk50_i            ), // 与整套 SRAM 访问链路共用 50 MHz 单时钟域
        .rst_n_i                (w_rst_n            ), // 上电等待结束后再启动 UART 发送器
        .data_byte_i            (w_tx_data          ), // 输入桥接层准备好的 1 字节应答数据
        .send_en_i              (w_tx_send          ), // 输入桥接层发起的发送启动脉冲
        .uart_tx_o              (uart_tx_o          ), // 输出板载串口 TX 波形
        .tx_busy_o              (w_tx_busy          ), // 返回发送忙状态，供桥接层串行装载多个应答字节
        .tx_done_o              (                   )  // 单字节发送完成当前不参与控制逻辑，保留空连接避免额外警告
    );

    // 该实例负责把 UART 文本命令转换成 SRAM 控制器命令，并把读写结果重新组织成文本应答。
    sram_uart_bridge #(
        .ADDR_W                 (ADDR_W             ), // 传入板上真实 SRAM 地址位宽，用于地址越界判断
        .DATA_W                 (DATA_W             )  // 传入板上真实 SRAM 数据位宽，用于格式化读回数据
    ) u_sram_uart_bridge (
        .clk_i                  (clk50_i            ), // 桥接层工作在与 UART/SRAM 相同的 50 MHz 单时钟域
        .rst_n_i                (w_rst_n            ), // 上电等待结束后再开始解析 UART 命令
        .rx_data_i              (w_rx_data          ), // 接收 UART 解出的 1 字节数据
        .rx_done_i              (w_rx_done          ), // 接收 UART 接收完成脉冲
        .tx_data_o              (w_tx_data          ), // 输出待发送的 UART 应答字节
        .tx_send_o              (w_tx_send          ), // 输出发送启动脉冲给 UART 发送器
        .tx_busy_i              (w_tx_busy          ), // 输入 UART 发送器忙状态，保证多字节应答顺序发送
        .cmd_valid_o            (w_cmd_valid        ), // 输出 SRAM 访问命令有效脉冲
        .cmd_write_o            (w_cmd_write        ), // 输出 SRAM 访问读写方向
        .cmd_addr_o             (w_cmd_addr         ), // 输出 SRAM 访问目标地址
        .cmd_wdata_o            (w_cmd_wdata        ), // 输出 SRAM 写入数据
        .cmd_byte_en_o          (w_cmd_byte_en      ), // 输出 SRAM 字节使能，当前固定整字访问
        .cmd_ready_i            (w_cmd_ready        ), // 输入 SRAM 控制器 ready 信号
        .rsp_valid_i            (w_rsp_valid        ), // 输入 SRAM 控制器完成脉冲
        .rsp_rdata_i            (w_rsp_rdata        )  // 输入 SRAM 控制器读回数据
    );

    // 该实例复用已经通过仿真的异步 SRAM 固定多拍时序控制器，只替换其上游命令来源。
    sram_async_ctrl #(
        .ADDR_W                 (ADDR_W             ), // 顶层地址位宽直接透传给 SRAM 控制器
        .DATA_W                 (DATA_W             )  // 顶层数据位宽直接透传给 SRAM 控制器
    ) u_sram_async_ctrl (
        .clk_i                  (clk50_i            ), // SRAM 控制器工作在板载 50 MHz 单时钟域
        .rst_n_i                (w_rst_n            ), // 上电等待完成后释放 SRAM 控制器内部复位
        .cmd_valid_i            (w_cmd_valid        ), // 接收 UART 桥接层发起的单次读写命令
        .cmd_write_i            (w_cmd_write        ), // 接收 UART 桥接层给出的读写方向
        .cmd_addr_i             (w_cmd_addr         ), // 接收 UART 桥接层给出的目标字地址
        .cmd_wdata_i            (w_cmd_wdata        ), // 接收 UART 桥接层给出的写数据
        .cmd_byte_en_i          (w_cmd_byte_en      ), // 接收 UART 桥接层给出的字节使能
        .cmd_ready_o            (w_cmd_ready        ), // 返回控制器 ready 给 UART 桥接层
        .rsp_valid_o            (w_rsp_valid        ), // 返回单次命令完成脉冲给 UART 桥接层
        .rsp_rdata_o            (w_rsp_rdata        ), // 返回读命令读回数据给 UART 桥接层
        .sram_addr_o            (sram_addr_o        ), // 直接驱动板级 SRAM 地址总线
        .sram_dq_io             (sram_dq_io         ), // 直接连接板级 SRAM 双向数据总线
        .sram_ce_n_o            (sram_ce_n_o        ), // 直接驱动板级 SRAM 片选信号
        .sram_oe_n_o            (sram_oe_n_o        ), // 直接驱动板级 SRAM 输出使能信号
        .sram_we_n_o            (sram_we_n_o        ), // 直接驱动板级 SRAM 写使能信号
        .sram_lb_n_o            (sram_lb_n_o        ), // 直接驱动板级 SRAM 低字节使能信号
        .sram_ub_n_o            (sram_ub_n_o        )  // 直接驱动板级 SRAM 高字节使能信号
    );

endmodule

`default_nettype wire
