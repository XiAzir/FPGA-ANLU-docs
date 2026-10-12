`timescale 1ns/1ps
//`define H_rosolution 1024
//`define V_rosolution 768
//`define Refresh_rate 60
//`define pclk_freq 65000000

`define H_rosolution 1280
`define V_rosolution 720
`define Refresh_rate 60
`define pclk_freq 74250000



module vesa_timing_chk( 
	input  			Clk,
	input			Rst,
	
	input			Vsync,
	input			Hsync,
	input			De,

	output	 [2:0]	Flag	

);

reg			vsync_1d,vsync_2d,vsync_f;//synthesis keep
reg			hsync_1d,hsync_2d,hsync_f;//synthesis keep
reg			de_1d,de_2d,de_f;//synthesis keep
reg	[3:0]	vsync_f_sft,hsync_f_sft,de_f_sft;
reg	[6:0]	v_cnt='d0;//synthesis keep
reg	[10:0]	p_cnt='d0;//synthesis keep
reg [10:0]  row_cnt='d0;//synthesis keep
reg			time_1s_flag_1d,time_1s_flag_2d,time_1s_flag= 1'b0;//synthesis keep
reg	[27:0]	clk_cnt= 28'd0;
reg	[2:0]	test_flag='d0;//synthesis keep

always @(posedge Clk)
begin
	vsync_1d <= Vsync;
	vsync_2d <= vsync_1d;
	
	hsync_1d <= Hsync;
	hsync_2d <= hsync_1d;
	
	de_1d <= De;
	de_2d <= de_1d;
end

always @(posedge Clk)
begin
	vsync_f <= vsync_2d & (!vsync_1d);
	hsync_f <= hsync_2d & (!hsync_1d);
	de_f <= de_2d & (!de_1d);
end

always @(posedge Clk)
begin
	vsync_f_sft[0] <= vsync_f;
	vsync_f_sft[3:1] <= vsync_f_sft[2:0];
	hsync_f_sft[0] <= hsync_f;
	hsync_f_sft[3:1] <= hsync_f_sft[2:0];
	de_f_sft[0] <= de_f;
	de_f_sft[3:1] <= de_f_sft[2:0];
	
	time_1s_flag_1d <= time_1s_flag;
	time_1s_flag_2d <= time_1s_flag_1d;
end

always @(posedge Clk)
begin
	if(time_1s_flag_2d)
		v_cnt <= 7'd0;
	else if(vsync_f)
		v_cnt <= v_cnt+1'b1;
end

always @(posedge Clk)
begin
	if(de_f_sft[3])
		p_cnt <= 11'd0;
	else if(de_1d)
		p_cnt <= p_cnt+1'b1;
end

always @(posedge Clk)
begin
	if(vsync_f_sft[3])
		row_cnt <= 11'd0;
	else if(de_f)
		row_cnt <= row_cnt+1'b1;
end
////////////////////////////////////

always @(posedge Clk)
begin
	if(clk_cnt==`pclk_freq)
		begin
			clk_cnt <= 28'd0;
		end
	else
		begin
			clk_cnt <= clk_cnt+1'b1;
		end
end

always @(posedge Clk)
begin
	if(clk_cnt==28'd10)
		begin
			time_1s_flag <= 1'b1;

		end
	else
		begin
			time_1s_flag <= 1'b0;
		end
end



////check
//pixel check
always @(posedge Clk)
begin
	if(de_f_sft[1])
		if(p_cnt==`H_rosolution || p_cnt==11'd1024)
			test_flag[0] <= 1'b0;
		else
			test_flag[0] <= 1'b1;
	else
		test_flag[0] <= test_flag[0];
end

//row check
always @(posedge Clk)
begin
	if (time_1s_flag)
		test_flag[1] <= 1'b0;
	else if(vsync_f_sft[1])
		if(row_cnt==`V_rosolution || row_cnt==11'd1024 || row_cnt==11'd768)
			test_flag[1] <= 1'b0;
		else
			test_flag[1] <= 1'b1;
	else
		test_flag[1] <= test_flag[1];
end

//frame rate check
always @(posedge Clk)
begin
	if (time_1s_flag)
		test_flag[2] <= 1'b0;
	else if(time_1s_flag)
		if(v_cnt==`Refresh_rate)
			test_flag[2] <= 1'b0;
		else
			test_flag[2] <= 1'b1;
	else
		test_flag[2] <= test_flag[2];
end
assign Flag=test_flag;

endmodule


