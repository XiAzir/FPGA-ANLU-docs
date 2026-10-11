module ov5640_sdram_vga(
    input                                   clk                                     ,
    input                                   rst_n                                   ,
    output                                  clk_8192                                ,
	
	//camera interface
    output                                  camera_sclk                             ,
    inout                                   camera_sdat                             ,
    input                                   camera_vsync                            ,//synthesis keep
    input                                   camera_href                             ,//synthesis keep
    input                                   camera_pclk                             ,
    output                                  camera_xclk                             ,
    input               [   7: 0]           camera_data                             ,
    output                                  camera_rst_n                            ,
    output                                  camera_pwdn                             ,

    // output                                  tmds_clk_p                              ,
    // output                                  tmds_clk_n                              ,
    // output              [   2: 0]           tmds_data_p                             ,
    // output              [   2: 0]           tmds_data_n                             ,
		
	//tft output
    output              [  15: 0]           tft_rgb                                 ,
    output                                  tft_hs                                  ,
    output                                  tft_vs                                  ,
    output                                  tft_clk                                 ,
    output                                  tft_de                                  ,
    output                                  tft_bl                                   
	
);
    wire                               clk_vga                                    ;//根据不同分辨率而定
    wire                               clk_24m                                    ;
    
    assign                              camera_xclk                 = clk_24m              ;
    assign                              tft_bl                      = 1                    ;
    
    wire                               ras_n                                      ;
    wire                               cas_n                                      ;
    wire                               we_n                                       ;
    wire                               cke                                        ;
    wire           [  10: 0]           addr                                       ;
    wire           [   1: 0]           ba                                         ;
    wire           [  31: 0]           dq                                         ;
    wire                               cs_n                                       ;
    wire           [   3: 0]           dm                                         ;
    wire                               sdram_clk_w                                ;
    wire                               DataReq                                    ;
    wire           [  31: 0]           data_rgb                                   ;//read image data
    
    	//摄像头1,摄像头2图像输出
    wire                               fifo_aclr                                  ;
    wire                               fifo_wrreq                                 ;//synthesis keep
    wire           [  31: 0]           fifo_wrdata                                ;//synthesis keep
    reg                                Rd_Sdram                                   ;
    
    
    wire           [  15: 0]           rgb                                        ;

	
    wire                               video_hs                                   ;
    wire                               video_vs                                   ;
    wire                               video_de                                   ;
    wire                               video_clk                                  ;
    wire                               video_clk_5x                               ;
    
    pll_hdmi pll_hdmi_inst(
    .refclk                             (clk                                 ),
    .reset                              (~rst_n                              ),
    .clk0_out                           (                                    ),
    .clk1_out                           (clk_vga                             ),
    .clk2_out                           (clk_24m                             ),
    .clk3_out                           (video_clk_5x                        ), 
    .clk4_out                           (clk_8192                            ) 
    );



	
    localparam                    RGB    = 0                                 ;
    localparam                    JPEG   = 1                                 ;
	
    parameter                     IMAGE_WIDTH= 800                               ; //图片宽度
    parameter                     IMAGE_HEIGHT= 480                               ; //图片高度(≤720)
    parameter                     IMAGE_LENGTH= IMAGE_WIDTH * IMAGE_HEIGHT/2      ; // 32 bit sdram
    parameter                     IMAGE_FLIP= 0                                 ;   //0：不翻转，1：上下翻转
    parameter                     IMAGE_MIRROR= 0                                 ;   //0：不镜像，1：左右镜像

	//摄像头初始化配置
    wire                               Init_Done                                  ;
    camera_init
    #(
    .IMAGE_TYPE                         (RGB                                 ),
    .IMAGE_WIDTH                        (IMAGE_WIDTH                         ),
    .IMAGE_HEIGHT                       (IMAGE_HEIGHT                        ),
    .IMAGE_FLIP                         (IMAGE_FLIP                          ),
    .IMAGE_MIRROR                       (IMAGE_MIRROR                        ) 
    )
    camera_init(
    .Clk                                (clk                                 ),
    .Rst_n                              (rst_n                               ),
    .Init_Done                          (Init_Done                           ),
    .camera_rst_n                       (camera_rst_n                        ),
    .camera_pwdn                        (camera_pwdn                         ),
    .i2c_sclk                           (camera_sclk                         ),
    .i2c_sdat                           (camera_sdat                         ) 
    );
	

    DVP_Capture DVP_Capture(
    .Rst_n                              (Init_Done                           ),
    .PCLK                               (camera_pclk                         ),
    .Vsync                              (camera_vsync                        ),
    .Href                               (camera_href                         ),
    .Data                               (camera_data                         ),
    .ImageState                         (fifo_aclr                           ),
    .DataValid                          (fifo_wrreq                          ),
    .DataPixel                          (fifo_wrdata                         ),
    .Xaddr                              (                                    ),
    .Yaddr                              (                                    ) 
    );


    always @ (posedge clk_vga or negedge rst_n)
    if (!rst_n)
        Rd_Sdram <= 1'b0;
    else if (DataReq)
        Rd_Sdram <= ~Rd_Sdram;


    Sdram_Control_4Port u_Sdram_Control_4Port_0(
		//	HOST Side
    .REF_CLK                            (clk                                 ),
    .RESET_N                            (rst_n                               ),
    .CLK                                (clk_w                               ),

		//	FIFO Write Side 1
    .WR1_DATA                           (fifo_wrdata                         ),
    .WR1                                (fifo_wrreq                          ),
    .WR1_ADDR                           ('d0                                 ),
    .WR1_MAX_ADDR                       (IMAGE_LENGTH                        ),
    .WR1_LENGTH                         (9'h80                               ),
    .WR1_LOAD                           (!rst_n                              ),
    .WR1_CLK                            (camera_pclk                         ),
    .WR1_FULL                           (                                    ),
		//.WR1_USE(),

		//	FIFO Write Side 2
    .WR2_DATA                           (0                                   ),
    .WR2                                (1'b0                                ),
    .WR2_ADDR                           ('d0                                 ),
    .WR2_MAX_ADDR                       (0                                   ),
    .WR2_LENGTH                         (0                                   ),
    .WR2_LOAD                           (1'b0                                ),
    .WR2_CLK                            (1'b0                                ),
    .WR2_FULL                           (                                    ),
		//.WR2_USE(),

		//	FIFO Read Side 1
    .RD1_DATA                           (data_rgb                            ),
    .RD1                                (Rd_Sdram                            ),
    .RD1_ADDR                           ('d0                                 ),
    .RD1_MAX_ADDR                       (IMAGE_LENGTH                        ),//640*480/4-1  除以4是因为一个像素8bit，而SDRAM位宽32bit
    .RD1_LENGTH                         (9'h80                               ),
    .RD1_LOAD                           (!rst_n                              ),
    .RD1_CLK                            (clk_vga                             ),
    .RD1_EMPTY                          (                                    ),
		//.RD1_USE(),

		//	FIFO Read Side 2
    .RD2_DATA                           (                                    ),
    .RD2                                (1'b0                                ),
    .RD2_ADDR                           ('d0                                 ),
    .RD2_MAX_ADDR                       (0                                   ),
    .RD2_LENGTH                         (0                                   ),
    .RD2_LOAD                           (1'b0                                ),
    .RD2_CLK                            (1'b0                                ),
    .RD2_EMPTY                          (                                    ),
		//.RD2_USE(),

		//	SDRAM Side
    .SA                                 (addr                                ),
    .BA                                 (ba                                  ),
    .CS_N                               (cs_n                                ),
    .CKE                                (cke                                 ),
    .RAS_N                              (ras_n                               ),
    .CAS_N                              (cas_n                               ),
    .WE_N                               (we_n                                ),
    .DQ                                 (dq                                  ),
    .DQM                                (dm                                  ),
    .SDR_CLK                            (sdram_clk_w                         ),
		//.test_oe(test_oe)
    .test_oe                            (                                    ) 
    );

    sdram_ip u_sdram_ip_0(
    .clk                                (sdram_clk_w                         ),
    .ras_n                              (ras_n                               ),
    .cas_n                              (cas_n                               ),
    .we_n                               (we_n                                ),
    .addr                               (addr                                ),
    .ba                                 (ba                                  ),
    .dq                                 (dq                                  ),
    .cs_n                               (cs_n                                ),//(cs_n), 
    .dm0                                (1'b0                                ),
    .dm1                                (1'b0                                ),
    .dm2                                (1'b0                                ),
    .dm3                                (1'b0                                ),
    .cke                                (cke                                 ) 
    );
    
    assign                              rgb                         = Rd_Sdram ?data_rgb[15:0]:data_rgb[31:16];

    wire           [   4: 0]           disp_red                                   ;
    wire           [   5: 0]           disp_green                                 ;
    wire           [   4: 0]           disp_blue                                  ;
    disp_driver #(
    .AHEAD_CLK_CNT                      (3                                   ) 
    )disp_driver(
    .ClkDisp                            (clk_vga                             ),
    .Rst_n                              (rst_n                               ),
    .Data                               (rgb                                 ),
    .DataReq                            (DataReq                             ),
    .H_Addr                             (                                    ),
    .V_Addr                             (                                    ),
    .Disp_HS                            (video_hs                            ),
    .Disp_VS                            (video_vs                            ),
    .Disp_Red                           (disp_red                            ),
    .Disp_Green                         (disp_green                          ),
    .Disp_Blue                          (disp_blue                           ),
    .Disp_Sof                           (                                    ),
    .Disp_DE                            (video_de                            ),
    .Disp_PCLK                          (video_clk                           ) 
    );

	
	//tft display
    assign                              tft_rgb                     = {disp_red, disp_green, disp_blue};
    assign                              tft_hs                      = video_hs             ;
    assign                              tft_vs                      = video_vs             ;
    assign                              tft_clk                     = video_clk            ;
    assign                              tft_de                      = video_de             ;
    assign                              tft_pwm                     = rst_n                ;


    // dvi_encoder dvi_encoder(
    // .pixelclk                           (video_clk                           ),
    // .pixelclk5x                         (video_clk_5x                        ),
    // .rst_n                              (rst_n                               ),
    // .blue_din                           (disp_blue                           ),
    // .green_din                          (disp_green                          ),
    // .red_din                            (disp_red                            ),
    // .hsync                              (video_hs                            ),
    // .vsync                              (video_vs                            ),
    // .de                                 (video_de                            ),
    // .tmds_clk_p                         (tmds_clk_p                          ),
    // .tmds_clk_n                         (tmds_clk_n                          ),
    // .tmds_data_p                        (tmds_data_p                         ),
    // .tmds_data_n                        (tmds_data_n                         ) 
    // );

endmodule
