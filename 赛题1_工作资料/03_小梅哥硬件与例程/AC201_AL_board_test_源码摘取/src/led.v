module led(
	clk,
	rst_n,
	led
);
	input clk;
	input rst_n;
	output reg [3:0] led;

	parameter CNT_MAX = 6_250_000;
	
	reg [25:0] cnt;
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n)
			cnt <= 'd0;
		else if (cnt < CNT_MAX - 1'b1)
			cnt <= cnt + 1'b1;
		else
			cnt <= 'd0;
	end
	
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n)
			led <= 4'b1110;
		else if (cnt == CNT_MAX - 1'b1)
			led <= {led[2:0],led[3]};
		else
			led <= led;
	end

endmodule
