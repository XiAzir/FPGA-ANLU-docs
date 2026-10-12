//Company: Anlogic Infotech Co., Ltd
//Engineer:  ae
//Create Date:  25/04/2021
`timescale 1 ns / 1 ps


module hdmi_rx_top (

  	input wire        FPGA_SYS_25M_CLK, 
  
  	//hdmi rx
  	input wire       	HDMI_CLK_P, 
  	input wire       	HDMI_D2_P,
  	input wire       	HDMI_D1_P,
  	input wire       	HDMI_D0_P,
    	
    input		[1:0]	KEY,	

	//edid
	inout              	sda        ,
	input              	scl        ,
	output  			hpd_reset,
 	 
 	 ////decoder
  	output wire 		rx_vsync,
  	output wire 		rx_hsync,
  	output wire 		rx_de,
  	output wire [23:0]  rx_pdata,
  	////rx clk
  	output wire 		rx_pll_lock,
  	output 				rx_pclk,
  	output 				rx_pclkx5,
  	  
 	output 	[1:0]		LED,


	output wire 		iis_lrclk,
	output wire			iis_sdata,
	output wire 		iis_sclk,
	output wire 		iis_mclk,
	output wire 		fifo0_full,
	output wire 		fifo1_full

	
	// output reg			info_AVI_valid_r, /* synthesis keep */
    // output reg [2:0] 	RGB_YCbCr_r,/* synthesis keep */
    // output reg [6:0] 	VIC_Value_r,/* synthesis keep */
    // output reg [15:0] 	TopBar_r,/* synthesis keep */
    // output reg [15:0] 	BottomBar_r,/* synthesis keep */
    // output reg [15:0] 	LeftBar_r,/* synthesis keep */
    // output reg [15:0] 	RightBar_r/* synthesis keep */
  
);


	wire info_AVI_valid;
	wire [2:0] RGB_YCbCr;
    wire [6:0] VIC_Value;
    wire [15:0] TopBar;
    wire [15:0] BottomBar;
    wire [15:0] LeftBar;
    wire [15:0] RightBar;



wire [9:0]  ch0_rawdata;//synthesis max_fanout=100
wire [9:0]  ch1_rawdata;//synthesis max_fanout=100
wire [9:0]  ch2_rawdata;//synthesis max_fanout=100

  /////////////////////////
  //
  // Input Port 0
  //
  /////////////////////////
(* keep *)wire rx0_pclk, rx0_pclkx5,bufpll_lock;
wire 		hsync;     /*synthesis keep*/   // hsync data
wire 		vsync;     /*synthesis keep*/     // vsync data
wire 		de;        /*synthesis keep*/     // data enable
wire [7:0] rx_red; /*synthesis keep*/     // pixel data out
wire [7:0] rx_green;/*synthesis keep*/    // pixel data out
wire [7:0] rx_blue; /*synthesis keep*/    // pixel data out
wire [29:0] rx_sdata;/*synthesis keep*/
wire rx0_blue_vld;
wire rx0_green_vld;
wire rx0_red_vld;
wire rx0_blue_rdy;
wire rx0_green_rdy;
wire rx0_red_rdy;

wire hdmi_clk_bufg;	
(* keep *)wire 	[2:0]	Flag;	//vesa timing check flag

// data island pack
wire [31:0]	packet_header;/*synthesis keep*/
wire [63:0]	subpacket0;/*synthesis keep*/
wire [63:0]	subpacket1;/*synthesis keep*/
wire [63:0]	subpacket2;/*synthesis keep*/
wire [63:0]	subpacket3;/*synthesis keep*/

// audio data in pclk domain
wire [23:0] left_o;
wire [23:0] right_o;
wire AUDIO_VALID;
wire data_island_data_valid;

wire [23:0] left_chan;
wire [23:0] right_chan;
wire audio_fifo_re;
wire empty_l;
wire empty_r;

// wire [15:0] info;/*synthesis keep*/
// wire [15:0] TB;/*synthesis keep*/
// wire [15:0] BB;/*synthesis keep*/
// wire [15:0] LB;/*synthesis keep*/
// wire [15:0] RB;/*synthesis keep*/
// reg info_fifo_re;/*synthesis keep*/
// wire info_fifo_empty;/*synthesis keep*/
// wire info_fifo_empty0;/*synthesis keep*/
// wire info_fifo_empty1;/*synthesis keep*/
// wire info_fifo_empty2;/*synthesis keep*/
// wire info_fifo_empty3;/*synthesis keep*/

// assign info_fifo_empty = (info_fifo_empty0)&&
//                         (info_fifo_empty1)&&
//                         (info_fifo_empty2)&&
//                         (info_fifo_empty3);




reg		tmdsclk_p_dly;
reg		pclkx5_wire;
//always @(*)
//begin
//	tmdsclk_p_dly <= #0.5 HDMI_CLK_P;
//end

// `ifdef SIMULATION
// always @(*)
// begin
	// pclkx5_wire <= #0.080 pclkx5;
// end
// `else
always @(*)
begin
	pclkx5_wire <=  pclkx5;
end	
// `endif

wire		clk2;
(* keep *)wire		psclk;
(* keep *)wire		psstep,psdown;
(* keep *)wire [2:0]  psclksel;
(* keep *)wire		pslock;	//synthesis keep
(* keep *)wire [5:0]	ps_num;	//synthesis keep

wire HDMI_CLK_P_BUFG;
BUFG_user u_EF4_LOGIC_BUFG(
  .o            ( HDMI_CLK_P_BUFG          ), //  1-Bit output. BUFG output port.              
  .i            ( HDMI_CLK_P          )  //  1-Bit input. BUFG input port.               
);
PLL_hdmi_rx_tx  u1_pll// pll_ip.v(23)
  (
	.refclk		(HDMI_CLK_P_BUFG),
	.reset		(1'b0),
	.clk0_out	(pclk),
	.clk1_out	(pclkx5),
	.clk2_out	(clk2),
	
  	.psclk	(psclk),
  	.psclksel(psclksel),
  	.psdown	(psdown),
  	.psstep	(psstep),
//  	.psclk	(1'd0),
//  	.psclksel(3'd0),
//  	.psdown	(1'd0),
//  	.psstep	(1'd0),
	.psdone	(),
  	
	.extlock	(bufpll_lock)
  );
wire reset=!bufpll_lock;

pcfg_chk_timing  u2_cfg
	 (
		.clk(clk2),	
		.rst(reset),

//		.hsclk(),
//		.ctrl_flag(),
//		.rawdata(),	
//		.vesa_flag	(3'd0),
		.hsclk(pclkx5),
		.ctrl_flag(~de),
        .rawdata(ch0_rawdata),	
		.vesa_flag	(Flag),
		.hdmi_rxpll_locked(bufpll_lock),
		
		.psclk(psclk),
		.psclksel(psclksel),		
		.psstep(psstep),		
		.psdown(psdown),		
		.pslock(pslock),		
		.ps_num(ps_num)	
  );


  
assign LED[1]=pslock;
assign rx_vsync=vsync;
assign rx_hsync=hsync;
assign rx_de=de;



  dvi_decoder dvi_rx0 (
    //These are input ports
    .tmdsclk_p   (HDMI_CLK_P),
    .blue_p      (HDMI_D0_P),
    .green_p     (HDMI_D1_P),
    .red_p       (HDMI_D2_P),


    //These are output ports
    .reset       (reset),
    .pclk        (pclk),
    .pclkx5      (pclkx5),

    .hsync       (hsync),
    .vsync       (vsync),
    .de          (de),

    .sdout       (rx_sdata),
    .red         (rx_red),
    .green       (rx_green),
    .blue        (rx_blue),
	.ch0_rawdata (ch0_rawdata),
	.ch1_rawdata (ch1_rawdata),
	.ch2_rawdata (ch2_rawdata)
	); 
assign rx_pdata={rx_red,rx_green,rx_blue};

i2cSlaveTop iic (
	.SYS_CLK(FPGA_SYS_25M_CLK),
	
	.sda	(sda)        ,
	.scl	(scl)        ,
	.hpd_reset(hpd_reset),
	
	.LED()
); 


reg	[21:0]	led_cnt;
always @(posedge pclk)
begin
	if(bufpll_lock)
		led_cnt <= led_cnt+1'b1;
	else
		led_cnt <= 22'd0;
end

assign LED[0] =led_cnt[21];



vesa_timing_chk u2_timging_chk( 
	.Clk(pclk),
	.Rst(reset),
	
	.Vsync(vsync),
	.Hsync(hsync),
	.De(de),

	.Flag(Flag)	

);


//	to detect data islands 
// only audio sample suported currently
data_island_extract ux_DIE(
	.PCLK(pclk),
	.C0_RAW(ch0_rawdata),
	.C1_RAW(ch1_rawdata),
	.C2_RAW(ch2_rawdata),
	.FPGA_SYS_25M_CLK(FPGA_SYS_25M_CLK),
	

	//data island
	.packet_header(packet_header),
	.subpacket0(subpacket0),
	.subpacket1(subpacket1),
	.subpacket2(subpacket2),
	.subpacket3(subpacket3),

	// this signal can be used as fifo-wr_en
	// synchronized with data above(ph, sp0, sp1,...)
	.data_island_data_valid(data_island_data_valid)
	
	
);


// info_AVI u_info_AVI(
//     .rst_n                  ( rst_n                  ),
//     .clk                    ( pclk                    ),
//     .data_island_data_valid ( data_island_data_valid ),
//     .packet_header          ( packet_header          ),
//     .subpacket0             ( subpacket0             ),
//     .subpacket1             ( subpacket1             ),
//     .subpacket2             ( subpacket2             ),
//     .subpacket3             ( subpacket3             ),
//     .info_AVI_valid         ( info_AVI_valid         ),
//     .RGB_YCbCr              ( RGB_YCbCr              ),
//     .VIC_Value              ( VIC_Value              ),
//     .TopBar                 ( TopBar                 ),
//     .BottomBar              ( BottomBar              ),
//     .LeftBar                ( LeftBar                ),
//     .RightBar               ( RightBar               )
// );

// fifo_16bit u_fifo_16bit_0(
//     .rst        ( 1'b0        ),
//     .di         ( {RGB_YCbCr,VIC_Value,6'b0}         ),
//     .clkw       ( pclk       ),
//     .we         ( info_AVI_valid         ),
//     .do         ( info         ),
//     .clkr       ( FPGA_SYS_25M_CLK       ),
//     .re         ( info_fifo_re         ),
//     .empty_flag ( info_fifo_empty0 ),
//     .full_flag  (   )
// );

// fifo_16bit u_fifo_16bit_1(
//     .rst        ( 1'b0        ),
//     .di         ( TopBar         ),
//     .clkw       ( pclk       ),
//     .we         ( info_AVI_valid         ),
//     .do         ( TB         ),
//     .clkr       ( FPGA_SYS_25M_CLK       ),
//     .re         ( info_fifo_re         ),
//     .empty_flag ( info_fifo_empty1 ),
//     .full_flag  (   )
// );

// fifo_16bit u_fifo_16bit_2(
//     .rst        ( 1'b0        ),
//     .di         ( BottomBar         ),
//     .clkw       ( pclk       ),
//     .we         ( info_AVI_valid         ),
//     .do         ( BB         ),
//     .clkr       ( FPGA_SYS_25M_CLK       ),
//     .re         ( info_fifo_re         ),
//     .empty_flag ( info_fifo_empty2 ),
//     .full_flag  (   )
// );

// fifo_16bit u_fifo_16bit_3(
//     .rst        ( 1'b0        ),
//     .di         ( LeftBar         ),
//     .clkw       ( pclk       ),
//     .we         ( info_AVI_valid         ),
//     .do         ( LB         ),
//     .clkr       ( FPGA_SYS_25M_CLK       ),
//     .re         ( info_fifo_re         ),
//     .empty_flag ( info_fifo_empty3 ),
//     .full_flag  (   )
// );

// always @(posedge FPGA_SYS_25M_CLK) begin
//     if(~info_fifo_empty)
//         info_fifo_re <= 1'b1;
//     else
//         info_fifo_re <= 1'b0;
// end

audio_pll u_audio_pll(
    .refclk   ( FPGA_SYS_25M_CLK   ),
    .reset    ( 1'b0    ),
    .extlock  (   ),
    .clk0_out (  ),
    .clk1_out ( iis_mclk )
);


// to extract audio sample(both left and right)
audio_store u_audio_store(
    .rst_n         ( rst_n         ),
    .clk           ( pclk           ),
    .packet_header ( packet_header ),
    .subpacket0    ( subpacket0    ),
    .subpacket1    ( subpacket1    ),
    .subpacket2    ( subpacket2    ),
    .subpacket3    ( subpacket3    ),

	.data_island_data_valid(data_island_data_valid),

	// left and right channels are both 24bits
    .left_o        ( left_o        ),
    .right_o       ( right_o       ),
	// this signal can be used as fifo-wr_en
    .AUDIO_VALID   ( AUDIO_VALID   )

	
);

    fifo_24bit fifo_l(
        .clkw(pclk),
        .di(left_o),
        .full_flag(),
        .we(AUDIO_VALID),
        .rst(1'b0),

        .clkr(iis_sclk),
        .empty_flag(empty_l),
        .do(left_chan),
        .re(audio_fifo_re)
    );

    fifo_24bit fifo_r(
        .clkw(pclk),
        .di(right_o),
        .full_flag(),
        .we(AUDIO_VALID),
        .rst(1'b0),

        .clkr(iis_sclk),
        .empty_flag(empty_r),
        .do(right_chan),
        .re(audio_fifo_re)
    );

i2s_tx#(
    .AUDIO_DW   ( 32 )
)u_i2s_tx(

	//input
	.rst        ( 1'b0        ),
    .iis_mclk   ( iis_mclk   ),	//mclk = 49.152Mhz in this design
	.prescaler  ( 32  ),	//typically = 32

	.FIFO_empty  ( audio_fifo_empty  ),	//audio sample fifo
	.left_chan  ( left_chan  ),	//each 24bit, dout of fifo
    .right_chan ( right_chan ),

	//output, iis interface
    .sclk       ( iis_sclk       ),
    .lrclk      ( iis_lrclk      ),
	.sdata      ( iis_sdata      ),

	//output, audio sample sifi re  
    .FIFO_re    ( audio_fifo_re    )
    
);




assign rx_hdmi_clk=HDMI_CLK_P;
assign rx_pclk=pclk;
assign rx_pclkx5=pclkx5;
assign rx_pll_lock=bufpll_lock;
assign audio_fifo_empty = empty_l||empty_r;




endmodule
