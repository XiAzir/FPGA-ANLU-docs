//Company: Anlogic Infotech Co., Ltd
//Engineer:  Fan Junling
//Create Date:  25/04/2021
// to extract audio sample(both left and right)

module info_AVI (
    input rst_n,
    input clk,

    // data island packets input
    input data_island_data_valid,
    input [31:0] packet_header,
    input [63:0] subpacket0,
    input [63:0] subpacket1,
    input [63:0] subpacket2,
    input [63:0] subpacket3,

    // signals below can be used as fifo`s inputs
    // as they are synchronized
    // the wr_clock should be clk which is input above
    
    output  reg info_AVI_valid, // this signal can be used as fifo-wr_en
    output  [2:0] RGB_YCbCr,
    output  [6:0] VIC_Value,
    output  [15:0] TopBar,
    output  [15:0] BottomBar,
    output  [15:0] LeftBar,
    output  [15:0] RightBar
);


    //packet TYPEs
    wire [3:0] packet_type;
    //data packets
    localparam TYPE_NULL = 4'd0;
    localparam TYPE_ACR = 4'd1;
    localparam TYPE_AS = 4'd2;
    localparam TYPE_GC = 4'd3;
    //info packets
    localparam TYPE_VS_info = 4'd11;
    localparam TYPE_AVI_info = 4'd12;
    localparam TYPE_SPD_info = 4'd13;
    localparam TYPE_AUD_info = 4'd14;
    localparam TYPE_MS_info = 4'd15;

    wire [7:0] type_code;

    wire [7:0] PB0;
    wire [7:0] PB1;
    wire [7:0] PB2;
    wire [7:0] PB3;
    wire [7:0] PB4;
    wire [7:0] PB5;
    wire [7:0] PB6;
    wire [7:0] PB7;
    wire [7:0] PB8;
    wire [7:0] PB9;
    wire [7:0] PB10;
    wire [7:0] PB11;
    wire [7:0] PB12;
    wire [7:0] PB13;
    wire [7:0] PB14;
    wire [7:0] PB15;
    wire [7:0] PB16;
    wire [7:0] PB17;
    wire [7:0] PB18;
    wire [7:0] PB19;
    wire [7:0] PB20;
    wire [7:0] PB21;
    wire [7:0] PB22;
    wire [7:0] PB23;
    wire [7:0] PB24;
    wire [7:0] PB25;
    wire [7:0] PB26;
    wire [7:0] PB27;

    /**      subpacket0      **/
    //PB0
    assign PB0[0] = subpacket0 [63];
    assign PB0[1] = subpacket0 [62];
    assign PB0[2] = subpacket0 [61];
    assign PB0[3] = subpacket0 [60];
    assign PB0[4] = subpacket0 [59];
    assign PB0[5] = subpacket0 [58];
    assign PB0[6] = subpacket0 [57];
    assign PB0[7] = subpacket0 [56];

    //PB1
    assign PB1[0] = subpacket0 [55];
    assign PB1[1] = subpacket0 [54];
    assign PB1[2] = subpacket0 [53];
    assign PB1[3] = subpacket0 [52];
    assign PB1[4] = subpacket0 [51];
    assign PB1[5] = subpacket0 [50];
    assign PB1[6] = subpacket0 [49];
    assign PB1[7] = subpacket0 [48];

    //PB2
    assign PB2[0] = subpacket0 [47];
    assign PB2[1] = subpacket0 [46];
    assign PB2[2] = subpacket0 [45];
    assign PB2[3] = subpacket0 [44];
    assign PB2[4] = subpacket0 [43];
    assign PB2[5] = subpacket0 [42];
    assign PB2[6] = subpacket0 [41];
    assign PB2[7] = subpacket0 [40];

    //PB3
    assign PB3[0] = subpacket0 [39];
    assign PB3[1] = subpacket0 [38];
    assign PB3[2] = subpacket0 [37];
    assign PB3[3] = subpacket0 [36];
    assign PB3[4] = subpacket0 [35];
    assign PB3[5] = subpacket0 [34];
    assign PB3[6] = subpacket0 [33];
    assign PB3[7] = subpacket0 [32];

    //PB4
    assign PB4[0] = subpacket0 [31];
    assign PB4[1] = subpacket0 [30];
    assign PB4[2] = subpacket0 [29];
    assign PB4[3] = subpacket0 [28];
    assign PB4[4] = subpacket0 [27];
    assign PB4[5] = subpacket0 [26];
    assign PB4[6] = subpacket0 [25];
    assign PB4[7] = subpacket0 [24];

    //PB5
    assign PB5[0] = subpacket0 [23];
    assign PB5[1] = subpacket0 [22];
    assign PB5[2] = subpacket0 [21];
    assign PB5[3] = subpacket0 [20];
    assign PB5[4] = subpacket0 [19];
    assign PB5[5] = subpacket0 [18];
    assign PB5[6] = subpacket0 [17];
    assign PB5[7] = subpacket0 [16];

    //PB6
    assign PB6[0] = subpacket0 [15];
    assign PB6[1] = subpacket0 [14];
    assign PB6[2] = subpacket0 [13];
    assign PB6[3] = subpacket0 [12];
    assign PB6[4] = subpacket0 [11];
    assign PB6[5] = subpacket0 [10];
    assign PB6[6] = subpacket0 [9];
    assign PB6[7] = subpacket0 [8];

/**      subpacket1      **/

    // //PB7
    // assign PB7[0] = subpacket0 [7];
    // assign PB7[1] = subpacket0 [6];
    // assign PB7[2] = subpacket0 [5];
    // assign PB7[3] = subpacket0 [4];
    // assign PB7[4] = subpacket0 [3];
    // assign PB7[5] = subpacket0 [2];
    // assign PB7[6] = subpacket0 [1];
    // assign PB7[7] = subpacket0 [0];

    //PB7
    assign PB7[0] = subpacket1 [63];
    assign PB7[1] = subpacket1 [62];
    assign PB7[2] = subpacket1 [61];
    assign PB7[3] = subpacket1 [60];
    assign PB7[4] = subpacket1 [59];
    assign PB7[5] = subpacket1 [58];
    assign PB7[6] = subpacket1 [57];
    assign PB7[7] = subpacket1 [56];

    //PB8
    assign PB8[0] = subpacket1 [55];
    assign PB8[1] = subpacket1 [54];
    assign PB8[2] = subpacket1 [53];
    assign PB8[3] = subpacket1 [52];
    assign PB8[4] = subpacket1 [51];
    assign PB8[5] = subpacket1 [50];
    assign PB8[6] = subpacket1 [49];
    assign PB8[7] = subpacket1 [48];

    //PB9
    assign PB9[0] = subpacket1 [47];
    assign PB9[1] = subpacket1 [46];
    assign PB9[2] = subpacket1 [45];
    assign PB9[3] = subpacket1 [44];
    assign PB9[4] = subpacket1 [43];
    assign PB9[5] = subpacket1 [42];
    assign PB9[6] = subpacket1 [41];
    assign PB9[7] = subpacket1 [40];

    //PB10
    assign PB10[0] = subpacket1 [39];
    assign PB10[1] = subpacket1 [38];
    assign PB10[2] = subpacket1 [37];
    assign PB10[3] = subpacket1 [36];
    assign PB10[4] = subpacket1 [35];
    assign PB10[5] = subpacket1 [34];
    assign PB10[6] = subpacket1 [33];
    assign PB10[7] = subpacket1 [32];

    //PB11
    assign PB11[0] = subpacket1 [31];
    assign PB11[1] = subpacket1 [30];
    assign PB11[2] = subpacket1 [29];
    assign PB11[3] = subpacket1 [28];
    assign PB11[4] = subpacket1 [27];
    assign PB11[5] = subpacket1 [26];
    assign PB11[6] = subpacket1 [25];
    assign PB11[7] = subpacket1 [24];

    //PB12
    assign PB12[0] = subpacket1 [23];
    assign PB12[1] = subpacket1 [22];
    assign PB12[2] = subpacket1 [21];
    assign PB12[3] = subpacket1 [20];
    assign PB12[4] = subpacket1 [19];
    assign PB12[5] = subpacket1 [18];
    assign PB12[6] = subpacket1 [17];
    assign PB12[7] = subpacket1 [16];

    //PB13
    assign PB13[0] = subpacket1 [15];
    assign PB13[1] = subpacket1 [14];
    assign PB13[2] = subpacket1 [13];
    assign PB13[3] = subpacket1 [12];
    assign PB13[4] = subpacket1 [11];
    assign PB13[5] = subpacket1 [10];
    assign PB13[6] = subpacket1 [9];
    assign PB13[7] = subpacket1 [8];


/**      subpacket2      **/

    //PB14
    assign PB14[0] = subpacket2 [63];
    assign PB14[1] = subpacket2 [62];
    assign PB14[2] = subpacket2 [61];
    assign PB14[3] = subpacket2 [60];
    assign PB14[4] = subpacket2 [59];
    assign PB14[5] = subpacket2 [58];
    assign PB14[6] = subpacket2 [57];
    assign PB14[7] = subpacket2 [56];

    //PB15
    assign PB15[0] = subpacket2 [55];
    assign PB15[1] = subpacket2 [54];
    assign PB15[2] = subpacket2 [53];
    assign PB15[3] = subpacket2 [52];
    assign PB15[4] = subpacket2 [51];
    assign PB15[5] = subpacket2 [50];
    assign PB15[6] = subpacket2 [49];
    assign PB15[7] = subpacket2 [48];

    //PB16
    assign PB16[0] = subpacket2 [47];
    assign PB16[1] = subpacket2 [46];
    assign PB16[2] = subpacket2 [45];
    assign PB16[3] = subpacket2 [44];
    assign PB16[4] = subpacket2 [43];
    assign PB16[5] = subpacket2 [42];
    assign PB16[6] = subpacket2 [41];
    assign PB16[7] = subpacket2 [40];

    //PB17
    assign PB17[0] = subpacket2 [39];
    assign PB17[1] = subpacket2 [38];
    assign PB17[2] = subpacket2 [37];
    assign PB17[3] = subpacket2 [36];
    assign PB17[4] = subpacket2 [35];
    assign PB17[5] = subpacket2 [34];
    assign PB17[6] = subpacket2 [33];
    assign PB17[7] = subpacket2 [32];

    //PB18
    assign PB18[0] = subpacket2 [31];
    assign PB18[1] = subpacket2 [30];
    assign PB18[2] = subpacket2 [29];
    assign PB18[3] = subpacket2 [28];
    assign PB18[4] = subpacket2 [27];
    assign PB18[5] = subpacket2 [26];
    assign PB18[6] = subpacket2 [25];
    assign PB18[7] = subpacket2 [24];

    //PB19
    assign PB19[0] = subpacket2 [23];
    assign PB19[1] = subpacket2 [22];
    assign PB19[2] = subpacket2 [21];
    assign PB19[3] = subpacket2 [20];
    assign PB19[4] = subpacket2 [19];
    assign PB19[5] = subpacket2 [18];
    assign PB19[6] = subpacket2 [17];
    assign PB19[7] = subpacket2 [16];

    //PB20
    assign PB20[0] = subpacket2 [15];
    assign PB20[1] = subpacket2 [14];
    assign PB20[2] = subpacket2 [13];
    assign PB20[3] = subpacket2 [12];
    assign PB20[4] = subpacket2 [11];
    assign PB20[5] = subpacket2 [10];
    assign PB20[6] = subpacket2 [9];
    assign PB20[7] = subpacket2 [8];

/**      subpacket3      **/

    //PB21
    assign PB21[0] = subpacket3 [63];
    assign PB21[1] = subpacket3 [62];
    assign PB21[2] = subpacket3 [61];
    assign PB21[3] = subpacket3 [60];
    assign PB21[4] = subpacket3 [59];
    assign PB21[5] = subpacket3 [58];
    assign PB21[6] = subpacket3 [57];
    assign PB21[7] = subpacket3 [56];

    //PB22
    assign PB22[0] = subpacket3 [55];
    assign PB22[1] = subpacket3 [54];
    assign PB22[2] = subpacket3 [53];
    assign PB22[3] = subpacket3 [52];
    assign PB22[4] = subpacket3 [51];
    assign PB22[5] = subpacket3 [50];
    assign PB22[6] = subpacket3 [49];
    assign PB22[7] = subpacket3 [48];

    //PB23
    assign PB23[0] = subpacket3 [47];
    assign PB23[1] = subpacket3 [46];
    assign PB23[2] = subpacket3 [45];
    assign PB23[3] = subpacket3 [44];
    assign PB23[4] = subpacket3 [43];
    assign PB23[5] = subpacket3 [42];
    assign PB23[6] = subpacket3 [41];
    assign PB23[7] = subpacket3 [40];

    //PB24
    assign PB24[0] = subpacket3 [39];
    assign PB24[1] = subpacket3 [38];
    assign PB24[2] = subpacket3 [37];
    assign PB24[3] = subpacket3 [36];
    assign PB24[4] = subpacket3 [35];
    assign PB24[5] = subpacket3 [34];
    assign PB24[6] = subpacket3 [33];
    assign PB24[7] = subpacket3 [32]; 

    //PB25
    assign PB25[0] = subpacket3 [31];
    assign PB25[1] = subpacket3 [30];
    assign PB25[2] = subpacket3 [29];
    assign PB25[3] = subpacket3 [28];
    assign PB25[4] = subpacket3 [27];
    assign PB25[5] = subpacket3 [26];
    assign PB25[6] = subpacket3 [25];
    assign PB25[7] = subpacket3 [24];

    //PB26
    assign PB26[0] = subpacket3 [23];
    assign PB26[1] = subpacket3 [22];
    assign PB26[2] = subpacket3 [21];
    assign PB26[3] = subpacket3 [20];
    assign PB26[4] = subpacket3 [19];
    assign PB26[5] = subpacket3 [18];
    assign PB26[6] = subpacket3 [17];
    assign PB26[7] = subpacket3 [16];

    //PB27
    assign PB27[0] = subpacket3 [15];
    assign PB27[1] = subpacket3 [14];
    assign PB27[2] = subpacket3 [13];
    assign PB27[3] = subpacket3 [12];
    assign PB27[4] = subpacket3 [11];
    assign PB27[5] = subpacket3 [10];
    assign PB27[6] = subpacket3 [9];
    assign PB27[7] = subpacket3 [8];

    // reg info_AVI_valid_r;
    reg [2:0] RGB_YCbCr_r;
    reg [6:0] VIC_Value_r;
    reg [15:0] TopBar_r;
    reg [15:0] BottomBar_r;
    reg [15:0] LeftBar_r;
    reg [15:0] RightBar_r;

// PacketByteDecoder u_PacketByteDecoder(
//     .subpacket0 ( subpacket0 ),
//     .subpacket1 ( subpacket1 ),
//     .subpacket2 ( subpacket2 ),
//     .subpacket3 ( subpacket3 ),
//     .PB0        ( PB0        ),
//     .PB1        ( PB1        ),
//     .PB2        ( PB2        ),
//     .PB3        ( PB3        ),
//     .PB4        ( PB4        ),
//     .PB5        ( PB5        ),
//     .PB6        ( PB6        ),
//     .PB7        ( PB7        ),
//     .PB8        ( PB8        ),
//     .PB9        ( PB9        ),
//     .PB10       ( PB10       ),
//     .PB11       ( PB11       ),
//     .PB12       ( PB12       ),
//     .PB13       ( PB13       ),
//     .PB14       ( PB14       ),
//     .PB15       ( PB15       ),
//     .PB16       ( PB16       ),
//     .PB17       ( PB17       ),
//     .PB18       ( PB18       ),
//     .PB19       ( PB19       ),
//     .PB20       ( PB20       ),
//     .PB21       ( PB21       ),
//     .PB22       ( PB22       ),
//     .PB23       ( PB23       ),
//     .PB24       ( PB24       ),
//     .PB25       ( PB25       ),
//     .PB26       ( PB26       ),
//     .PB27       ( PB27       )
// );



packet_type_checker ux_PTC(
    .head(packet_header),
    .type(packet_type),
    .type_code(type_code)
);

    
    // assign AUDIO_VALID = ((packet_type == TYPE_AS)&& data_island_data_valid)?1'b1:1'b0;
    always @(posedge clk) begin
        if(/*packet_type == TYPE_AVI_info */(type_code == 8'h82)&& data_island_data_valid)
            info_AVI_valid <= 1'b1;
        else
            info_AVI_valid <= 1'b0;
    end
    

    
    always @(posedge clk) 
    begin
        if(/*packet_type == TYPE_AVI_info */ (type_code == 8'h82)&& data_island_data_valid)
        begin
            RGB_YCbCr_r <= PB1[6:5];
            VIC_Value_r <= PB4[6:0];
            TopBar_r <= {PB7,PB6};
            BottomBar_r <={PB9,PB8};
            LeftBar_r <= {PB11,PB10};
            RightBar_r <= {PB13,PB12};
        end
        else
        begin
            RGB_YCbCr_r <= 2'b0;
            VIC_Value_r <= 7'b0;
            TopBar_r <= 16'b0;
            BottomBar_r <= 16'b0;
            LeftBar_r <= 16'b0;
            RightBar_r <= 16'b0;
        end
    end

    // assign info_AVI_valid = info_AVI_valid_r;
    assign RGB_YCbCr = RGB_YCbCr_r;
    assign VIC_Value = VIC_Value_r;
    assign TopBar = TopBar_r;
    assign BottomBar = BottomBar_r;
    assign LeftBar = LeftBar_r;
    assign RightBar = RightBar_r;



endmodule