//Company: Anlogic Infotech Co., Ltd
//Engineer:  ae
//Create Date:  25/04/2021
//Description: a HDMI video and audio receive project


`define IMAGE_LOOP

module hdmi_loop (

		input wire          SYS_CLK, 
		
//		input		[1:0]	KEY,
		
		//HDMI RX
		input wire       	HDMI_CLK_P, 
		input wire       	HDMI_D2_P,
		input wire       	HDMI_D1_P,
		input wire       	HDMI_D0_P,		
  
  		//HDMI TX
		output				HDMI_TX_CLK_P,
		output				HDMI_TX_D2_P,
		output				HDMI_TX_D1_P,
		output				HDMI_TX_D0_P,
		
		//EDID
		inout              	sda        ,
		input              	scl        ,
		output  			hpd_reset,
		//video(DVI) deocde
//  		output wire 		rx_vsync,
//  		output wire 		rx_hsync,
//  		output wire 		rx_de,
  		
		output	[1:0]		LED//[0]RX PLL LOCK,Blink if work well,[1]DECODE OK, light on if work well
		//audio play to iis
//		output wire 		iis_lrclk,
//		output wire			iis_sdata,
//		output wire 		iis_sclk,
//		output wire 		iis_mclk,

//		output wire 		fifo0_full,
//		output wire 		fifo1_full

//		output 			info_AVI_valid, 
//    	output  [2:0] 	RGB_YCbCr,
//    	output  [6:0] 	VIC_Value,
//    	output  [15:0] 	TopBar,
//    	output  [15:0] 	BottomBar,
//    	output  [15:0] 	LeftBar,
//    	output  [15:0] 	RightBar
);




wire		rx_pclk,rx_pclkx5,rx_pll_lock;
wire		vsync,hsync,de;
wire [23:0] pdata;

// assign HDMI_IIS_PA_EN = 1'b1;


hdmi_rx_top u1_rx (

  	.FPGA_SYS_25M_CLK(SYS_CLK), 
//	.KEY(KEY),
  	
  	.HDMI_CLK_P	(HDMI_CLK_P), 
  	.HDMI_D2_P	(HDMI_D2_P),
  	.HDMI_D1_P	(HDMI_D1_P),
  	.HDMI_D0_P	(HDMI_D0_P),
  
	.sda		(sda),
	.scl		(scl),
	.hpd_reset	(hpd_reset),
 
  	.rx_vsync	(vsync),  
  	.rx_hsync	(hsync),
  	.rx_de		(de),
  	.rx_pdata	(pdata),
  	.rx_pll_lock(rx_pll_lock),
  	.rx_pclk	(rx_pclk),
  	.rx_pclkx5	(rx_pclkx5),
  
  	.LED		(LED)


//	.iis_lrclk(iis_lrclk),
//	.iis_sdata(iis_sdata),
//	.iis_sclk(iis_sclk),
//	.iis_mclk(iis_mclk),
//	.fifo0_full(fifo0_full),
//	.fifo1_full(fifo1_full)

	// .info_AVI_valid_r(info_AVI_valid), 
    // .RGB_YCbCr_r(RGB_YCbCr),
    // .VIC_Value_r(VIC_Value),
    // .TopBar_r(TopBar),
    // .BottomBar_r(BottomBar),
    // .LeftBar_r(LeftBar),
    // .RightBar_r(RightBar)
);

assign rx_vsync=vsync;
assign rx_hsync=hsync;
assign rx_de=de;


`ifdef IMAGE_LOOP
  
	hdmi_tx  u2_tx
	(
		.PXLCLK_I 	(rx_pclk),
		.PXLCLK_5X_I(rx_pclkx5),
		.RST_N 		(),
		
		////VGA
		.VGA_HS 	(hsync),
		.VGA_VS 	(vsync),
		.VGA_DE 	(de),
		.VGA_RGB 	(pdata),

		//HDMI
		.HDMI_CLK_P	(HDMI_TX_CLK_P),
		.HDMI_D2_P	(HDMI_TX_D2_P),
		.HDMI_D1_P	(HDMI_TX_D1_P),
		.HDMI_D0_P	(HDMI_TX_D0_P)	
	);
    
`else

	hdmi_tx_display u2_tx(
		.FPGA_SYS_25M_CLK_P(SYS_CLK),
		
		//HDMI
		.HDMI_CLK_P	(HDMI_TX_CLK_P),
		.HDMI_D2_P	(HDMI_TX_D2_P),
		.HDMI_D1_P	(HDMI_TX_D1_P),
		.HDMI_D0_P	(HDMI_TX_D0_P),
		
		.LED	()
    );
			  
`endif
    
 
	
endmodule