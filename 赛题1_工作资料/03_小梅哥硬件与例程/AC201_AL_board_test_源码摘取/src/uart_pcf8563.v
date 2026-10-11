module uart_pcf8563(
    sys_clk,
    sys_rst_n,
    uart_rx,
    uart_tx,
//	i2c_sclk,
//	i2c_sdat
	
    data_date,
    data_time,
	
    pcf8563_scl,
    pcf8563_i,
    pcf8563_o,
    pcf8563_oe
);
	// System clock reset
    input                               sys_clk                    ;//系统时钟输入，50M
    input                               sys_rst_n                  ;//复位信号输入，低有效

	// Uart interface              
    input                               uart_rx                    ;//串口输入信号
    output                              uart_tx                    ;//串口输出信号

	// I2c interface
//	output          i2c_sclk    ;
//	inout           i2c_sdat	;
	
    output             [  31: 0]        data_date                  ;
    output             [  31: 0]        data_time                  ;
	
    output                              pcf8563_scl                ;
    input                               pcf8563_i                  ;
    output                              pcf8563_o                  ;
    output                              pcf8563_oe                 ;
	
    wire                                Set_Time                   ;
    wire               [  23: 0]        Time_to_Set                ;
    wire                                Set_Date                   ;
    wire               [  31: 0]        Date_to_Set                ;
    wire                                Read                       ;
    wire               [  23: 0]        Time_Read                  ;
    wire               [  31: 0]        Date_Read                  ;
	
    wire                                Cmd_Done                   ;
	
	//PCF8563驱动
    RTC8563_Driver RTC8563_Driver(
    .Clk                                (sys_clk                   ),
    .Rst_n                              (sys_rst_n                 ),
    .Set_Time                           (Set_Time                  ),
    .Time_to_Set                        (Time_to_Set               ),
    .Set_Date                           (Set_Date                  ),
    .Date_to_Set                        (Date_to_Set               ),
    .Read                               (Read                      ),
    .Time_Read                          (Time_Read                 ),
    .Date_Read                          (Date_Read                 ),
    .Cmd_Done                           (Cmd_Done                  ),
//		.i2c_sclk     (i2c_sclk   ),
//		.i2c_sdat     (i2c_sdat   )
    .pcf8563_scl                        (pcf8563_scl               ),
    .pcf8563_i                          (pcf8563_i                 ),
    .pcf8563_o                          (pcf8563_o                 ),
    .pcf8563_oe                         (pcf8563_oe                ) 
    );
	
	//数码管显示驱动
    wire               [  47: 0]        disp_data                  ;//日期+时间显示
    wire               [  31: 0]        disp_data1                 ;//日期或者时间显示
	
    wire               [  31: 0]        Time_to_Disp               ;//需要送到数码管上显示的带格式的时间数据
    wire               [  31: 0]        Date_to_Disp               ;//需要送到数码管上显示的带格式的日期数据
	
    assign                              data_time                 = {disp_data[23:16], 4'hf, disp_data[15:8], 4'hf, disp_data[7:0]};//f对应显示-
    assign                              data_date                 = {8'h20, disp_data[47:40], disp_data[39:32], disp_data[31:24]};

	//8'h20, 24 +24
	// 19 01 01 12 00 00
    assign                              disp_data                 = {Date_Read[31:24],Date_Read[23:16],Date_Read[7:0],Time_Read[23:16],Time_Read[15:8],Time_Read[7:0]};
    
	//设定一个定时器，大概每20ms读取一次PCF8563的日期和时间寄存器
    reg                [  19: 0]        cnt                        ;
    assign                              Read                      = (cnt == 20'hfffff);
    always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt <= 0;
    else
        cnt <= cnt + 1'b1;
    
    wire               [   7: 0]        Data_rx                    ;
    wire                                done_rx                    ;
    uart_byte_rx uart_byte_rx(
    .clk                                (sys_clk                   ),
    .reset                              (!sys_rst_n                ),
    .baud_set                           (3'd0                      ),
    .uart_rx                            (uart_rx                   ),
    .data_byte                          (Data_rx                   ),
    .rx_done                            (done_rx                   ) 
    );
	
    time_adjust u_time_adjust(
    .sys_clk                            (sys_clk                   ),
    .sys_rst_n                          (sys_rst_n                 ),
    .uart_data                          (Data_rx                   ),
    .data_valid                         (done_rx                   ),
    .set_time                           (Set_Time                  ),
    .set_time_data                      (Time_to_Set               ),
    .set_date                           (Set_Date                  ),
    .set_date_data                      (Date_to_Set               ) 
    );
    
    wire                                done                       ;
    wire               [   7: 0]        Data                       ;
    wire                                tx_done                    ;
    time_send u_time_send(
    .sys_clk                            (sys_clk                   ),
    .sys_rst_n                          (sys_rst_n                 ),
    .time_data                          (disp_data                 ),
    .Go                                 (tx_done                   ),
    .uart_data                          (Data                      ),
    .data_valid                         (done                      ) 
    );

    uart_byte_tx u_uart_byte_tx(
    .clk                                (sys_clk                   ),
    .reset                              (!sys_rst_n                ),
    .data_byte                          (Data                      ),
    .send_en                            (done                      ),
    .baud_set                           (3'd0                      ),
    .uart_tx                            (uart_tx                   ),
    .tx_done                            (tx_done                   ),
    .uart_state                         (                          ) 
    );

endmodule
