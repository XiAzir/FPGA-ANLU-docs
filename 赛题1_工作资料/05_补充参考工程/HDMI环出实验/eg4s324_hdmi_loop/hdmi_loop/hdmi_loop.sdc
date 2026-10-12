
create_clock -name SYS_CLK -period 20.000 -waveform {0 10} [get_ports {SYS_CLK}]


create_clock -name HDMI_CLK_IN -period 15.384615 -waveform {0 7.6923075} [get_ports {HDMI_CLK_P}]

create_clock -name I2S_MCLK -period 81.380 -waveform {0 40.69} [get_ports {iis_mclk}]


create_generated_clock \
  -name PCLK \
  -source [get_ports {HDMI_CLK_P}] \
  -master_clock HDMI_CLK_IN \
  [get_pins {u1_pll/clk0_out}]


create_generated_clock \
  -name PCLKX5 \
  -source [get_ports {HDMI_CLK_P}] \
  -master_clock HDMI_CLK_IN \
  -multiply_by 5 \
  [get_pins {u1_pll/clk1_out}]


create_generated_clock \
  -name I2S_LRCLK \
  -source [get_ports {iis_mclk}] \
  -master_clock I2S_MCLK \
  -divide_by 256 \
  [get_ports {iis_lrclk}]

create_generated_clock \
  -name I2S_SCLK \
  -source [get_ports {iis_mclk}] \
  -master_clock I2S_MCLK \
  -divide_by 4 \
  [get_ports {iis_sclk}]
  
set_clock_groups -asynchronous \
  -group {HDMI_CLK_IN PCLK PCLKX5} \
  -group {SYS_CLK I2S_MCLK I2S_SCLK I2S_LRCLK}


