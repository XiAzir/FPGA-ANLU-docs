// Verilog netlist created by TD v5.0.32684
// Wed Jun 16 09:40:02 2021

`timescale 1ns / 1ps
module hdmi_pll  // hdmi_pll.v(24)
  (
  psclk,
  psclksel,
  psdown,
  psstep,
  refclk,
  reset,
  clk0_out,
  clk1_out,
  clk2_out,
  extlock,
  psdone
  );

  input psclk;  // hdmi_pll.v(38)
  input [2:0] psclksel;  // hdmi_pll.v(41)
  input psdown;  // hdmi_pll.v(39)
  input psstep;  // hdmi_pll.v(40)
  input refclk;  // hdmi_pll.v(36)
  input reset;  // hdmi_pll.v(37)
  output clk0_out;  // hdmi_pll.v(44)
  output clk1_out;  // hdmi_pll.v(45)
  output clk2_out;  // hdmi_pll.v(46)
  output extlock;  // hdmi_pll.v(42)
  output psdone;  // hdmi_pll.v(43)

  wire clk2_buf;  // hdmi_pll.v(48)

  EG_PHY_GCLK bufg_feedback (
    .clki(clk2_buf),
    .clko(clk2_out));  // hdmi_pll.v(50)
  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  EG_PHY_PLL #(
    .CLKC0_CPHASE(14),
    .CLKC0_DIV(15),
    .CLKC0_DIV2_ENABLE("DISABLE"),
    .CLKC0_ENABLE("ENABLE"),
    .CLKC0_FPHASE(0),
    .CLKC1_CPHASE(2),
    .CLKC1_DIV(3),
    .CLKC1_DIV2_ENABLE("DISABLE"),
    .CLKC1_ENABLE("ENABLE"),
    .CLKC1_FPHASE(0),
    .CLKC2_CPHASE(14),
    .CLKC2_DIV(15),
    .CLKC2_DIV2_ENABLE("DISABLE"),
    .CLKC2_ENABLE("ENABLE"),
    .CLKC2_FPHASE(0),
    .CLKC3_CPHASE(1),
    .CLKC3_DIV(1),
    .CLKC3_DIV2_ENABLE("DISABLE"),
    .CLKC3_ENABLE("DISABLE"),
    .CLKC3_FPHASE(0),
    .CLKC4_CPHASE(1),
    .CLKC4_DIV(1),
    .CLKC4_DIV2_ENABLE("DISABLE"),
    .CLKC4_ENABLE("DISABLE"),
    .CLKC4_FPHASE(0),
    .DERIVE_PLL_CLOCKS("DISABLE"),
    .DPHASE_SOURCE("ENABLE"),
    .DYNCFG("DISABLE"),
    .FBCLK_DIV(1),
    .FEEDBK_MODE("NORMAL"),
    .FEEDBK_PATH("CLKC2_EXT"),
    .FIN("74.250"),
    .FREQ_LOCK_ACCURACY(2),
    .GEN_BASIC_CLOCK("DISABLE"),
    .GMC_GAIN(4),
    .GMC_TEST(14),
    .ICP_CURRENT(13),
    .IF_ESCLKSTSW("DISABLE"),
    .INTFB_WAKE("DISABLE"),
    .KVCO(4),
    .LPF_CAPACITOR(1),
    .LPF_RESISTOR(4),
    .NORESET("DISABLE"),
    .ODIV_MUXC0("DIV"),
    .ODIV_MUXC1("DIV"),
    .ODIV_MUXC2("DIV"),
    .ODIV_MUXC3("DIV"),
    .ODIV_MUXC4("DIV"),
    .PLLC2RST_ENA("DISABLE"),
    .PLLC34RST_ENA("DISABLE"),
    .PLLMRST_ENA("DISABLE"),
    .PLLRST_ENA("ENABLE"),
    .PLL_LOCK_MODE(0),
    .PREDIV_MUXC0("VCO"),
    .PREDIV_MUXC1("VCO"),
    .PREDIV_MUXC2("VCO"),
    .PREDIV_MUXC3("VCO"),
    .PREDIV_MUXC4("VCO"),
    .REFCLK_DIV(1),
    .REFCLK_SEL("INTERNAL"),
    .STDBY_ENABLE("DISABLE"),
    .STDBY_VCO_ENA("DISABLE"),
    .SYNC_ENABLE("DISABLE"),
    .VCO_NORESET("DISABLE"))
    pll_inst (
    .daddr(6'b000000),
    .dclk(1'b0),
    .dcs(1'b0),
    .di(8'b00000000),
    .dwe(1'b0),
    .fbclk(clk2_out),
    .load_reg(1'b0),
    .psclk(psclk),
    .psclksel(psclksel),
    .psdown(psdown),
    .psstep(psstep),
    .refclk(refclk),
    .reset(reset),
    .stdby(1'b0),
    .clkc({open_n47,open_n48,clk2_buf,clk1_out,clk0_out}),
    .extlock(extlock),
    .psdone(psdone));  // hdmi_pll.v(81)

endmodule 

