`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 14:32:11
// Design Name: 
// Module Name: time_adjust
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//     via uart_rx ,accept command and then produce a signal to adjust the 
//     RTC8563 chip.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module time_adjust(
    //System clock reset
    input           sys_clk       , //系统时钟输入，50M
    input           sys_rst_n     , //复位信号输入，低有效
    
    input  [7:0]    uart_data     , //
    input           data_valid    , //
    
    output          set_time      ,
    output  [23:0]  set_time_data ,
    output          set_date      ,
    output  [31:0]  set_date_data 
);
    reg [87:0] sync_date_time;
	wire checked;//if true checked sync command
	always @ (posedge sys_clk or negedge sys_rst_n)
	if (!sys_rst_n)
	    sync_date_time <= 'd0;
	else if (data_valid)
	    sync_date_time <= {sync_date_time[79:0], uart_data};
	
	//                     1    3    2    4    年   月   日   周   时   分   秒
	//char mxstime[10] = {0x01,0x03,0x02,0x04,0x17,0x10,0x29,0x07,0x17,0x11,0x11};
	assign checked = (sync_date_time[87:56] == 32'h01030204);
	
	reg checked_r;
	always @ (posedge sys_clk)
	    checked_r <= checked;
	
	// imitate key delay
	parameter DLY_MAX = 5_000_000;
	reg [25:0] cnt_dly;
	wire dly_done;
	reg dly;
	always @ (posedge sys_clk or negedge sys_rst_n)
	if (!sys_rst_n)
	    cnt_dly <= 'd0;
	else if (set_time)
	    cnt_dly <= DLY_MAX;
    else if (cnt_dly > 0)
        cnt_dly <= cnt_dly - 1'd1;
    else
        cnt_dly <= cnt_dly;
	
	assign dly_done = (cnt_dly == 1);
	always @ (posedge sys_clk)
	    dly <= dly_done;
    
	assign set_time = (checked && (!checked_r)); //写入预设时间
	assign set_date = dly_done && (!dly);	     //写入预设日期
	
	assign set_time_data = sync_date_time[23:0];	//时间为00:23:20
	assign set_date_data = {sync_date_time[55:40], sync_date_time[31:24], sync_date_time[39:32]};
    
endmodule
