module key_handle(
	Clk,
	Rst_n,
	Key_S1,
	Key_S0,
	En_S1,
	En_S0,
	Key_flag
);
	input Clk;
	input Rst_n; 
	input Key_S1;
	input Key_S0;
	output En_S1;
	output En_S0;
	output Key_flag;
	
	wire key_state3;
	wire key_state4;
	
	assign Key_flag = En_S1 | En_S0;
	
	Key_filter key_filter_S1(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.Key(Key_S1),
		.Key_state(key_state3)
	);
	
	Key_filter key_filter_S0(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.Key(Key_S0),
		.Key_state(key_state4)
	);
	
	Edge_check edge_check_S1(
		.Clk(Clk),
		.Wave(key_state3),
		.Flag_neg(En_S1),
		.Flag_pos()
	);
	
	Edge_check edge_check_S0(
		.Clk(Clk),
		.Wave(key_state4),
		.Flag_neg(En_S0),
		.Flag_pos()
	);
	
endmodule
