module Key_filter(
	Clk,
	Rst_n,
	Key,
	Key_state
);
	input Clk;
	input Rst_n;
	input Key;	//low valid
	output reg Key_state;	//low valid

	parameter MASK_TIME  = 500_000;	//10ms
	localparam KEY_OFF   = 4'b0001;	//one hot
	localparam ON_SHAKE	 = 4'b0010;
	localparam KEY_ON	 = 4'b0100;
	localparam OFF_SHAKE = 4'b1000;
	
	reg [3:0] c_state;
	reg [3:0] n_state;
	reg [18:0] cnt;
	reg [1:0] buf_key;
	wire key_n;
	
	always @ (posedge Clk) buf_key <= {buf_key[0], Key};
	assign key_n = buf_key[1];
	
	always @ (posedge Clk or negedge Rst_n)
	if (Rst_n == 1'b0)
		c_state <= KEY_OFF;
	else
		c_state <= n_state;
	
	always @ (*)
	case (c_state)
		KEY_OFF:
			if (key_n == 1'b0)
				n_state = ON_SHAKE;
			else
				n_state = KEY_OFF;
		ON_SHAKE:
			if (key_n == 1'b1)
				n_state = KEY_OFF;
			else	
				if (cnt < MASK_TIME - 1'b1)
					n_state = ON_SHAKE;
				else
					n_state = KEY_ON;
		KEY_ON:
			if (key_n == 1'b1)
				n_state = OFF_SHAKE;
			else
				n_state = KEY_ON;
		OFF_SHAKE:
			if (key_n == 1'b0)
				n_state = KEY_ON;
			else
				if (cnt < MASK_TIME - 1'b1)
					n_state = OFF_SHAKE;
				else
					n_state = KEY_OFF;
		default	:	n_state = KEY_OFF;
	endcase
	
	always @ (posedge Clk or negedge Rst_n)
	if (Rst_n == 1'b0)
		cnt <= 'd0;
	else	
		case (c_state)
			KEY_OFF:
				cnt <= 'd0;
			ON_SHAKE:
				if (key_n == 1'b1)
					cnt <= 'd0;
				else
					if (cnt < MASK_TIME - 1'b1)
						cnt <= cnt + 1'b1;
					else
						cnt <= 'd0;
			KEY_ON:
				cnt <= 'd0;
			OFF_SHAKE:
				if (key_n == 1'b0)
					cnt <= 'd0;
				else	
					if (cnt < MASK_TIME - 1'b1)
						cnt <= cnt + 1'b1;
					else
						cnt <= 'd0;
			default	:	cnt <= 'd0;
		endcase
	
	always @ (posedge Clk or negedge Rst_n)
	if (Rst_n == 1'b0)
		Key_state <= 1'b1;
	else
		if (c_state == KEY_ON || c_state == OFF_SHAKE)
			Key_state <= 1'b0;
		else
			Key_state <= 1'b1;
	
endmodule 