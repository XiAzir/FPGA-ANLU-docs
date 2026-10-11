// Company       : �人о·��Ƽ����޹�˾
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2021/07/21 00:00:00
// Module Name   : rgmii_to_gmii
// Description   : ��̫������rgmiiתgmii
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

module rgmii_to_gmii(
  reset,

  rgmii_rx_clk,
  rgmii_rxd,
  rgmii_rxdv,

  gmii_rx_clk,
  gmii_rxdv,
  gmii_rxd,
  gmii_rxer
);



    input                               reset                      ;

    input                               rgmii_rx_clk               ;
    input              [   3: 0]        rgmii_rxd                  ;
    input                               rgmii_rxdv                 ;

    output                              gmii_rx_clk                ;
    output             [   7: 0]        gmii_rxd                   ;
    output                              gmii_rxdv                  ;
    output                              gmii_rxer                  ;
  
    wire                                gmii_rxer_r                ;
  

    assign                              gmii_rx_clk               = rgmii_rx_clk;

  genvar i;
  generate
    for(i=0;i<4;i=i+1)
    begin: rgmii_rxd_i

IDDR_0  IDDR_rxd(
    .q1                                 (gmii_rxd[i+4]             ),//  1-Bit output. 1 bit negedge data output.     
    .q0                                 (gmii_rxd[i]               ),//  1-Bit output. 1 bit posedge data output.     
    .clk                                (rgmii_rx_clk              ),//  1-Bit input. Sampling clock.                
    .d                                  (rgmii_rxd[i]              ),//  1-Bit input. DDR data entered on I/O.       
    .rst                                (reset                     ) //  1-Bit input. Reset signal,high active.      
);

    end
  endgenerate


IDDR_0 IDDR_rxdv(
    .q1                                 (gmii_rxer_r               ),//  1-Bit output. 1 bit negedge data output.     
    .q0                                 (gmii_rxdv                 ),//  1-Bit output. 1 bit posedge data output.     
    .clk                                (rgmii_rx_clk              ),//  1-Bit input. Sampling clock.                
    .d                                  (rgmii_rxdv                ),//  1-Bit input. DDR data entered on I/O.       
    .rst                                (reset                     ) //  1-Bit input. Reset signal,high active.      
);

    assign                              gmii_rxer                 = gmii_rxer_r^gmii_rxdv;
endmodule