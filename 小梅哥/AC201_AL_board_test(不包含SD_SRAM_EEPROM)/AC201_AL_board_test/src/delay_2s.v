module delay_2s(
	clk,
	rst_n,
	flag_1s,
	flag
);
	input clk;
	input rst_n;
	output flag_1s;
	output flag;
	
	parameter CNT_MAX = 50_000_000;
	
	reg [25:0] cnt;
	always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		cnt <= 'd0;
	else if (cnt < CNT_MAX - 1'b1)
		cnt <= cnt + 1'b1;
	else
		cnt <= 'd0;
	
	assign flag_1s = (cnt == CNT_MAX - 1'b1);
	
	reg [2:0] cnt_num;
	always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		cnt_num <= 'd0;
	else if (flag_1s) begin
		if (cnt_num < 'd2)
			cnt_num <= cnt_num + 1'b1;
		else
			cnt_num <= cnt_num;
	end
	
	assign flag = (cnt_num == 'd2);

endmodule
