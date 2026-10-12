
`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
//////////////////////////////////////////////////////////////////////////////////

/*
// 0x01 : red
// 0x02 : green
// 0x03 : blue
// 0x04 : white
// 0x05 : gray red
// 0x06 : gray green
// 0x07 : gray blue
// 0x08 : gray white
// 0x09 : mosaic
// 0x0A : diagonal gray scan
// 0x0B : grid scan
*/

//-------------------------------------------------------------------------------------------
module hdmi_top(   
		input   PXLCLK_I,
        input   PXLCLK_5X_I,
		input	RST_I,
		
		input   		DEN_TPG,
		input [3:0] 	TPG_mode,
		input			LOCKED_I,

		//HDMI
		output			HDMI_CLK_P,
		output			HDMI_D2_P,
		output			HDMI_D1_P,
		output			HDMI_D0_P,
		
		output			SERDES_CLK_TEST,
		output			SERDES_DATA1_TEST,
		output			SERDES_DATA2_TEST,
		
		output			ODDR_CLK_TEST,
		output			ODDR_DATA1_TEST,
		output			ODDR_DATA2_TEST

	);

wire  			VGA_DE;
wire  			VGA_HS;      
wire  			VGA_VS;
wire  [23:0]  	VGA_RGB;	
	
video_tpg_1080p u2_tpg(   
		.PCLK(PXLCLK_I),
        .Reset(RST_I),
		.DEN_TPG(DEN_TPG),
		.TPG_mode(TPG_mode),
		.PDEN(VGA_DE),
        .HSYNC(VGA_HS),     //VESA行同步信��
        .VSYNC(VGA_VS ),    //VESA场同步信��
        .PDATA(VGA_RGB)
	);	
	
	
hdmi_tx u3_hdmi_tx
	(
		.PXLCLK_I(PXLCLK_I),
		.PXLCLK_5X_I(PXLCLK_5X_I),

		.RST_N (RST_I),
		
		//VGA
		.VGA_HS (VGA_HS ),
		.VGA_VS (VGA_VS ),
		.VGA_DE (VGA_DE ),
		.VGA_RGB(VGA_RGB),

		//HDMI
		.HDMI_CLK_P(HDMI_CLK_P),
		.HDMI_D2_P (HDMI_D2_P ),
		.HDMI_D1_P (HDMI_D1_P ),
		.HDMI_D0_P (HDMI_D0_P )	
		
	);
	

endmodule
