/************************************************************\
**	Copyright (c) 2012-2026 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Gen time	:	Apr 20 2026 17:55:58
**	IpTool version	:	2026.01(189136 2026/01/26)
**	App version	:	6.2.2(build number:190657)
**	Ip Version	:	3.0
\************************************************************/
`timescale 1ns/1ps
module eth_msg_buf
(
  input                         srst,
  input   [111:0]               di,
  input                         clk,
  input                         re,
  input                         we,
  output  [111:0]               dout,
  output                        empty_flag,
  output                        aempty,
  output                        full_flag,
  output                        afull,
  output                        valid,
  output                        overflow,
  output                        underflow,
  output                        wr_success,
  output  [4:0]                 rdusedw,
  output  [4:0]                 wrusedw,
  output                        wr_rst_done,
  output                        rd_rst_done
);

  soft_fifo_eth_msg_buf
  #(
      .COMMON_CLK_EN(1),
      .MEMORY_TYPE(0),
      .RST_TYPE(2),
      .DATA_WIDTH_W(112),
      .ADDR_WIDTH_W(4),
      .DATA_WIDTH_R(112),
      .ADDR_WIDTH_R(4),
      .DOUT_INITVAL(112'h0),
      .OUTREG_EN("NOREG"),
      .SHOW_AHEAD_EN(0),
      .AL_FULL_NUM(3),
      .AL_EMPTY_NUM(2),
      .RDUSEDW_WIDTH(5),
      .WRUSEDW_WIDTH(5),
      .ASYNC_RST_SYNC_RELS(0),
      .SYNC_STAGE(2)
  )soft_fifo_Inst
  (
      .srst(srst),
      .di(di),
      .clk(clk),
      .re(re),
      .we(we),
      .dout(dout),
      .empty_flag(empty_flag),
      .aempty(aempty),
      .full_flag(full_flag),
      .afull(afull),
      .valid(valid),
      .overflow(overflow),
      .underflow(underflow),
      .wr_success(wr_success),
      .rdusedw(rdusedw),
      .wrusedw(wrusedw),
      .wr_rst_done(wr_rst_done),
      .rd_rst_done(rd_rst_done)
  );
endmodule
