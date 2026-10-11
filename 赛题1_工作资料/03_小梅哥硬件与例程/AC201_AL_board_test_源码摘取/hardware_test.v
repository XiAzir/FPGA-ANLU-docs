module hardware_test(
	//时钟
    input                                   clk                                     ,
	//复位
    input                                   rst_n                                   ,

      //uart interface
    input                                   uart_rx                                 ,
    output                                  uart_tx                                 ,
    
    //audio interface
    input                                   I2S_DI                                  ,
    input                                   I2S_RCLK                                ,
    input                                   I2S_BCLK                                ,
    output                                  I2S_DO                                  ,
    output                                  I2S_MCLK                                ,

	//按键
    input                                   key_0                                   ,//S0输入，低有效
    input                                   key_1                                   ,//S1输入，低有效
	//红外
    input                                   ir                                      ,
	//led
    output              [   3: 0]           led                                     ,
	//beep
    output                                  beep                                    ,
	//sw
    input               [   7: 0]           sw                                      ,

    output              [  35: 0]           gpio_40pin                              ,

      //pcf8563 interface
    output                                  i2c_sclk                                ,
    inout                                   i2c_sdat                                ,

		//eth receive interface
    input                                   eth_rxc                                 ,//以太网接收时钟
    input               [   3: 0]           eth_rxd                                 ,//以太网接收数据
    input                                   eth_rxdv                                ,//以太网接收数据有效标志
	//eth send interface
    output                                  eth_gtxc                                ,//以太网发送时钟
//	input 			eth_txc	   ; //以太网发送时钟
    output              [   3: 0]           eth_txd                                 ,//以太网发送数据
    output                                  eth_txen                                ,//以太网发送数据有效标志
	// mdio
    output                                  eth_rst_n                               ,//以太网复位，低有效
    inout                                   eth_mdc                                 ,
    inout                                   eth_mdio                                ,

	//camera interface
    output                                  camera_sclk                             ,
    inout                                   camera_sdat                             ,
    input                                   camera_vsync                            ,//synthesis keep
    input                                   camera_href                             ,//synthesis keep
    input                                   camera_pclk                             ,
    output                                  camera_xclk                             ,
    input               [   7: 0]           camera_data                             ,
//    output                                  camera_rst_n                            ,
//    output                                  camera_pwdn                             ,
		
	//tft output
    output              [  15: 0]           tft_rgb                                 ,
    output                                  tft_hs                                  ,
    output                                  tft_vs                                  ,
    output                                  tft_clk                                 ,
    output                                  tft_de                                  ,
    output                                  tft_bl                                  ,
    //hdmi output
    output wire                             O_tmds_ch0_p                            ,
    output wire                             O_tmds_ch1_p                            ,
    output wire                             O_tmds_ch2_p                            ,
    output wire                             O_tmds_clk_p                            ,

	//数码管
    output                                  seg7_sclk                               ,
    output                                  seg7_rclk                               ,
    output                                  seg7_dio                                 

);
    wire                               en_s0                                      ;
    wire                               en_s1                                      ;
    wire                               key_flag                                   ;

    key_handle KEY_HANDLE(
    .Clk                                (clk                                 ),
    .Rst_n                              (rst_n                               ),
    .Key_S1                             (key_0                               ),
    .Key_S0                             (key_1                               ),
    .En_S1                              (en_s0                               ),
    .En_S0                              (en_s1                               ),
    .Key_flag                           (key_flag                            ) 
    );

    wire                               mode                                       ;
    wire                               time_date                                  ;
    mode mode_inst(
    .clk                                (clk                                 ),
    .rst_n                              (rst_n                               ),
    .en_s0                              (en_s0                               ),
    .en_s1                              (en_s1                               ),
    .mode                               (mode                                ),
    .time_date                          (time_date                           ) 
    );


    wire                               flag_delay                                 ;
    wire                               flag_1s                                    ;
    delay_2s delay_2_inst(
    .clk                                (clk                                 ),
    .rst_n                              (rst_n                               ),
    .flag_1s                            (flag_1s                             ),
    .flag                               (flag_delay                          ) 
    );

    wire           [  31: 0]           disp_data                                  ;
    wire           [  31: 0]           data_time                                  ;
    wire           [  31: 0]           data_date                                  ;
    assign                              disp_data                   = !mode ? (time_date ? data_date : data_time) : 32'h88888888;


    HEX_top HEX_top_inst(
    .Clk                                (clk                                 ),
    .Rst_n                              (rst_n                               ),
    .switch                             (flag_delay                          ),
    .mode                               (mode                                ),
    .sw                                 (sw                                  ),
    .disp_data                          (disp_data                           ),
    .SEG7_SCLK                          (seg7_sclk                           ),
    .SEG7_RCLK                          (seg7_rclk                           ),
    .SEG7_DIO                           (seg7_dio                            ) 
    );

    wire           [  15: 0]           ir_data                                    ;//解码出的数据
    wire           [  15: 0]           ir_addr                                    ;//解码出的地址
    wire                               Flag_ir                                    ;//一次红外解码完成标志
    ir_decode ir_decode(
    .Clk50M                             (clk                                 ),
    .Rst_n                              (rst_n                               ),
    .iIR                                (ir                                  ),
    .Get_Flag                           (Flag_ir                             ),
    .irData                             (ir_data                             ),
    .irAddr                             (ir_addr                             ) 
    );

    wire                               flag                                       ;
    ibeep BEEP(
    .Clk                                (clk                                 ),
    .Rst_n                              (rst_n                               ),
    .En_beep                            (key_flag|Flag_ir|flag               ),
    .Beep                               (beep                                ) 
    );
	
    led led_inst(
    .clk                                (clk                                 ),
    .rst_n                              (rst_n                               ),
    .led                                (led                                 ) 
    );
    
    
       eth_udp_loopback_rgmii eth_udp_loopback_rgmii(
    .reset_n                            (rst_n                               ),
  //eth_rx
    .rgmii_rx_clk_i                     (eth_rxc                             ),
    .rgmii_rxd                          (eth_rxd                             ),
    .rgmii_rxdv                         (eth_rxdv                            ),
  //eth_tx
    .rgmii_tx_clk                       (eth_gtxc                            ),
    .rgmii_txd                          (eth_txd                             ),
    .rgmii_txen                         (eth_txen                            ),
  
    .eth_rstn                           (eth_rst_n                           ),
    .eth_mdc                            (eth_mdc                             ),
    .eth_mdio                           (eth_mdio                            ),
  //led
    .led                                (                                    ) 
);

    wire                               clk_8192                                   ;
ov5640_sdram_vga  ov5640_sdram_vga(
    .clk                                (clk                                 ),
    .rst_n                              (rst_n                               ),
    .clk_8192                           (clk_8192                            ),
	//camera interface
    .camera_sclk                        (camera_sclk                         ),
    .camera_sdat                        (camera_sdat                         ),
    .camera_vsync                       (camera_vsync                        ),//synthesis keep
    .camera_href                        (camera_href                         ),//synthesis keep
    .camera_pclk                        (camera_pclk                         ),
    .camera_xclk                        (camera_xclk                         ),
    .camera_data                        (camera_data                         ),
    .camera_rst_n                       (camera_rst_n                        ),
    .camera_pwdn                        (camera_pwdn                         ),
	//tft output
    .tft_rgb                            (tft_rgb                             ),
    .tft_hs                             (tft_hs                              ),
    .tft_vs                             (tft_vs                              ),
    .tft_clk                            (tft_clk                             ),
    .tft_de                             (tft_de                              ),
    .tft_bl                             (tft_bl                              ) 
	
);


    wire                               iis_done                                   ;
    wire                               iis_scl                                    ;
    wire                               iis_i                                      ;
    wire                               iis_o                                      ;
    wire                               iis_oe                                     ;
    wire                               pcf8563_scl                                ;
    wire                               pcf8563_i                                  ;
    wire                               pcf8563_o                                  ;
    wire                               pcf8563_oe                                 ;
    function_pin function_pin_inst(
    .iic_sda                            (i2c_sdat                            ),
    .iic_scl                            (i2c_sclk                            ),
    .mode                               (iis_done                            ),
    .iis_scl                            (iis_scl                             ),
    .iis_i                              (iis_i                               ),
    .iis_o                              (iis_o                               ),
    .iis_oe                             (iis_oe                              ),
    .pcf8563_scl                        (pcf8563_scl                         ),
    .pcf8563_i                          (pcf8563_i                           ),
    .pcf8563_o                          (pcf8563_o                           ),
    .pcf8563_oe                         (pcf8563_oe                          ) 
    );


    uart_pcf8563 uart_pcf8563_inst(
    .sys_clk                            (clk                                 ),
    .sys_rst_n                          (iis_done                            ),
    .uart_rx                            (uart_rx                             ),
    .uart_tx                            (uart_tx                             ),
    .data_date                          (data_date                           ),
    .data_time                          (data_time                           ),
    .pcf8563_scl                        (pcf8563_scl                         ),
    .pcf8563_i                          (pcf8563_i                           ),
    .pcf8563_o                          (pcf8563_o                           ),
    .pcf8563_oe                         (pcf8563_oe                          ) 
    );


    audio_loop_back audio_loop_back(
    .clk                                (clk                                 ),
    .clk_18_3                           (clk_8192                            ),
    .rst_n                              (rst_n                               ),
    .iis_scl                            (iis_scl                             ),
    .iis_i                              (iis_i                               ),
    .iis_o                              (iis_o                               ),
    .iis_oe                             (iis_oe                              ),
    .iis_done                           (iis_done                            ),
    .aud_adclrck                        (I2S_RCLK                            ),
    .aud_adcdat                         (I2S_DI                              ),
    .aud_daclrck                        (I2S_RCLK                            ),
    .aud_dacdat                         (I2S_DO                              ),
    .aud_bclk                           (I2S_BCLK                            ),
    .aud_xck                            (I2S_MCLK                            ) 
    );

    // wire                               S_pll_lock                                 ;
    // pll_hdmi1_4b U_pll(
    // .refclk                             (clk                                 ),
    // .reset                              (~rst_n                              ),

    // .extlock                            (S_pll_lock                          ),

    // .clk1_out                           (clk_75                              ),
    // .clk2_out                           (clk_375                             ) 
    // );

    design_top_wrapper  design_top_wrapper(
    .I_sys_clk                          (clk                                 ),

    .I_key_in                           (1'b0                                ),

    .I_i2s_BCLK                         (1'b0                                ),
    .I_i2s_LRCK                         (1'b0                                ),
    .I_i2s_DOUT                         (1'b0                                ),
    .O_tmds_ch0_p                       (O_tmds_ch0_p                        ),
    .O_tmds_ch1_p                       (O_tmds_ch1_p                        ),
    .O_tmds_ch2_p                       (O_tmds_ch2_p                        ),
    .O_tmds_clk_p                       (O_tmds_clk_p                        ) 
);


    localparam          integer              GPIO_TOGGLE_BIT                         = 23;
    localparam          [  35: 0]           GPIO40_HDMI_SAFE_MASK                    = 36'hFFFFFFFFF;

    reg                 [GPIO_TOGGLE_BIT:0] gpio_div                                 ;
    wire                                    gpio_level                               ;

    always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                gpio_div <= {(GPIO_TOGGLE_BIT + 1){1'b0}};
            else
                gpio_div <= gpio_div + 1'b1;
        end

    assign                              gpio_level                   = gpio_div[GPIO_TOGGLE_BIT];
    assign                              gpio_40pin                  = {36{gpio_level}} & GPIO40_HDMI_SAFE_MASK;

endmodule
