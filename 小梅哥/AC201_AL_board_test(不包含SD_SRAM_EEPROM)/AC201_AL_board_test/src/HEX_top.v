/***************************************************
*	Module Name		:	HEX_top		   
*	Engineer		:	小梅哥
*	Target Device	:	EP4CE10F17C8
*	Tool versions	:	Quartus II 13.0
*	Create Date		:	2017-3-31
*	Revision		:	v1.0
*	Description		:  三线制数码管显示顶层设计
**************************************************/

module HEX_top(
	Clk,
	Rst_n,
	switch,
	sw,
	mode,
	disp_data,
	SEG7_SCLK,
	SEG7_RCLK,
	SEG7_DIO
);

	input Clk;	//50M
	input Rst_n;
	input switch;		//0：测试数码管，全亮 1：显示期望的内容
	input mode;
	input [7:0] sw;
	output SEG7_SCLK;	//shift clock
	output SEG7_RCLK;	//latch data clock
	output SEG7_DIO;	//shift serial data
	
	input [31:0] disp_data;
	
	wire [7:0] sel;//数码管位选（选择当前要显示的数码管）
	wire [7:0] seg;//数码管段选（当前要显示的内容）	

	HEX8 HEX8(
		.clk(Clk),
		.rst_n(Rst_n),
		.en(1'b1),
		.switch(switch),
		.sw(sw),
		.mode(mode),
		.disp_data(disp_data),
		.sel(sel),
		.seg(seg)
	);
	
	HC595_Driver HC595_Driver(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.Data({seg,sel}),
		.S_EN(1'b1),
		.SEG7_SCLK(SEG7_SCLK),
		.SEG7_RCLK(SEG7_RCLK),
		.SEG7_DIO(SEG7_DIO)
	);
	
endmodule
