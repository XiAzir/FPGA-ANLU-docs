module mode(
	clk,
	rst_n,
	en_s0,
	en_s1,
	mode,
	time_date
);
	input clk;
	input rst_n;
	input en_s0;
	input en_s1;
	output reg mode;
	output reg time_date; //0:show time ,1:show date
	
	always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		mode <= 1'b0;
	else if (en_s1)
		mode <= mode + 1'b1;
	
	always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		time_date <= 1'b0;//show time
	else if (!mode) begin
		if (en_s0)
			time_date <= time_date + 1'b1;
		else
			time_date <= time_date;
	end

endmodule
