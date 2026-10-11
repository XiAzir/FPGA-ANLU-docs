module Edge_check(
	Clk,
	Wave,
	Flag_neg,
	Flag_pos
);
	input Clk;
	input Wave;
	output Flag_neg;
	output Flag_pos;
	
	reg buf_wave;
	reg reg_check;
	
	always @ (posedge Clk) buf_wave <= Wave;
	always @ (posedge Clk) reg_check <= buf_wave;
	
	assign Flag_neg = reg_check & (~buf_wave);
	assign Flag_pos = (~reg_check) & buf_wave;

endmodule 