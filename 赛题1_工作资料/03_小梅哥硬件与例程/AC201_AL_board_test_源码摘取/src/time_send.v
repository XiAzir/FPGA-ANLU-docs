`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 15:50:45
// Design Name: 
// Module Name: time_send
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module time_send(
    //System clock reset
    input           sys_clk       , //系统时钟输入，50M
    input           sys_rst_n     , //复位信号输入，低有效
    
    input  [47:0]   time_data     ,
    input           Go            ,
    
    output reg [7:0]uart_data     , //
    output reg      data_valid
);
    parameter CNT_MAX = 50_000_000;
	reg [25:0] cnt_1s;
	wire flag_1s;
	assign flag_1s = (cnt_1s == CNT_MAX - 1'b1);
	always @ (posedge sys_clk or negedge sys_rst_n)
	if (!sys_rst_n)
	    cnt_1s <= 'd0;
    else if (cnt_1s < CNT_MAX - 1'b1)
        cnt_1s <= cnt_1s + 1'd1;
    else
        cnt_1s <= 'd0;
	
	// one second update send data
    reg [111:0] date_time;
    always @ (posedge sys_clk)
    if (flag_1s) begin
        date_time[111:104] <= 8'd2 + 8'h30;//"2"
        date_time[103:96 ] <= 8'd0 + 8'h30;//"0"
        date_time[95 :88 ] <= {4'd0,time_data[47:44]} + 8'h30;//YY
        date_time[87 :80 ] <= {4'd0,time_data[43:40]} + 8'h30;
        date_time[79 :72 ] <= {4'd0,time_data[39:36]} + 8'h30;//MM
        date_time[71 :64 ] <= {4'd0,time_data[35:32]} + 8'h30;
        date_time[63 :56 ] <= {4'd0,time_data[31:28]} + 8'h30;//DD
        date_time[55 :48 ] <= {4'd0,time_data[27:24]} + 8'h30;
        date_time[47 :40 ] <= {4'd0,time_data[23:20]} + 8'h30;//hh
        date_time[39 :32 ] <= {4'd0,time_data[19:16]} + 8'h30;
        date_time[31 :24 ] <= {4'd0,time_data[15:12]} + 8'h30;//mm
        date_time[23 :16 ] <= {4'd0,time_data[11:8]}  + 8'h30;
        date_time[15 :8  ] <= {4'd0,time_data[7:4]}   + 8'h30;//ss
        date_time[7  :0  ] <= {4'd0,time_data[3:0]}   + 8'h30;
    end
    
    reg [15:0] cnt_num;
	always @ (posedge sys_clk or negedge sys_rst_n)
	if (!sys_rst_n) begin
	   uart_data <= 'd0;
	   data_valid <= 1'b0;
	   cnt_num <= 'd0;
    end else begin
        if (Go)
            cnt_num <= cnt_num + 1'b1;
        
        case (cnt_num)
            0  : begin                                  data_valid <= 1'b1; end  //
            1  : begin uart_data <= date_time[111:104]; data_valid <= 1'b1; end  //2 YYYY
            2  : begin uart_data <= date_time[103:96 ]; data_valid <= 1'b1; end  //0
            3  : begin uart_data <= date_time[95 :88 ]; data_valid <= 1'b1; end  //1
            4  : begin uart_data <= date_time[87 :80 ]; data_valid <= 1'b1; end  //9
            5  : begin uart_data <= 8'h2D;              data_valid <= 1'b1; end  //-
            6  : begin uart_data <= date_time[79 :72 ]; data_valid <= 1'b1; end  //0 MM
            7  : begin uart_data <= date_time[71 :64 ]; data_valid <= 1'b1; end  //1
            8  : begin uart_data <= 8'h2D;              data_valid <= 1'b1; end  //-
            9  : begin uart_data <= date_time[63 :56 ]; data_valid <= 1'b1; end  //0 DD
            10 : begin uart_data <= date_time[55 :48 ]; data_valid <= 1'b1; end  //1
            11 : begin uart_data <= 8'h20;              data_valid <= 1'b1; end  //space
            12 : begin uart_data <= date_time[47 :40 ]; data_valid <= 1'b1; end  //1 hh
            13 : begin uart_data <= date_time[39 :32 ]; data_valid <= 1'b1; end  //2
            14 : begin uart_data <= 8'h3A;              data_valid <= 1'b1; end  //:
            15 : begin uart_data <= date_time[31 :24 ]; data_valid <= 1'b1; end  //0 mm
            16 : begin uart_data <= date_time[23 :16 ]; data_valid <= 1'b1; end  //0
            17 : begin uart_data <= 8'h3A;              data_valid <= 1'b1; end  //:
            18 : begin uart_data <= date_time[15 :8  ]; data_valid <= 1'b1; end  //0 ss
            19 : begin uart_data <= date_time[7  :0  ]; data_valid <= 1'b1; end  //0
            20 : begin uart_data <= 8'h0A;              data_valid <= 1'b1; end  // LF(换行)
            default : begin
                       uart_data <= 8'h00;//"$"
                       if (flag_1s) begin
                           cnt_num <= 1;
                           data_valid <= 1'b1;
                       end else begin
                           data_valid <= 1'b0;
                       end
                 end
        endcase
    end
    
endmodule
