// Verilog netlist created by TD v4.6.15768
// Mon Jun 22 17:54:08 2020

`timescale 1ns / 1ps
module DRAM16X1  // al_ip/DRAM16X1.v(14)
  (
  di,
  raddr,
  waddr,
  wclk,
  we,
  do
  );

  input [9:0] di;  // al_ip/DRAM16X1.v(23)
  input [3:0] raddr;  // al_ip/DRAM16X1.v(25)
  input [3:0] waddr;  // al_ip/DRAM16X1.v(24)
  input wclk;  // al_ip/DRAM16X1.v(26)
  input we;  // al_ip/DRAM16X1.v(26)
  output [9:0] do;  // al_ip/DRAM16X1.v(28)

  parameter ADDR_WIDTH_R = 4;
  parameter ADDR_WIDTH_W = 4;
  parameter DATA_DEPTH_R = 16;
  parameter DATA_DEPTH_W = 16;
  parameter DATA_WIDTH_R = 10;
  parameter DATA_WIDTH_W = 10;

  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  EG_LOGIC_DRAM16X4 dram_c0 (
    .di(di[3:0]),
    .raddr(raddr),
    .waddr(waddr),
    .wclk(wclk),
    .we(we),
    .do(do[3:0]));
  EG_LOGIC_DRAM16X4 dram_c1 (
    .di(di[7:4]),
    .raddr(raddr),
    .waddr(waddr),
    .wclk(wclk),
    .we(we),
    .do(do[7:4]));
  EG_LOGIC_DRAM16X4 dram_c2 (
    .di({2'b00,di[9:8]}),
    .raddr(raddr),
    .waddr(waddr),
    .wclk(wclk),
    .we(we),
    .do({open_n47,open_n48,do[9:8]}));

endmodule 

