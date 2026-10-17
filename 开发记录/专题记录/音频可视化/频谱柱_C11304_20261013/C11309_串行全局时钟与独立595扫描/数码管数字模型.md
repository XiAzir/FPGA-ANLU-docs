# C11309 status clock-route model

Result: PASS in five integrated source/destination phase cases (0, 5, 10, 15, 19 ns). Each case used the production `player_status_mailbox.v` and `status_hex595.v`, 25 MHz source, 50 MHz destination, and 1000 Hz scan request.

The testbench observes only `destination_hex`, `seg7_dio`, `seg7_sclk`, and `seg7_rclk`. It reconstructs all 16-bit transfers at the SCLK edge, checks DIO setup, one-hot digit order, 16-bit RCLK latch boundaries, and decodes full eight-digit frames. It covers `01234567`, `88888888`, `DFC11309`, `E4000000`, `F0000000`, and `F1000010`; more than 100,000 source updates across a live display frame using three distinct patterns (the frame must remain one coherent value); a source-clock pause after handshake while the 595 scan continues on the frozen value; then asynchronous reset, zeroing, and restart.

The 1 MHz serial setting produces a measured 1020 ns interval between SCLK rising edges inside each word (about 0.980392 MHz). The additional 20 ns is the driver's `ST_SHIFT_SET` cycle. All five runs observed the same period and passed the setup/latch assertions.

This is a digital RTL model. It does not validate routed FPGA PAD timing, board wiring, the external 74HC595, display enable switches, or electrical levels. The source status pages are supplied as input values; the monitor's page-generation logic is outside this test's scope.

Files and SHA-256 bindings: `status_clock_route_binding.json`. Compilation and simulation logs: `status_clock_route_compile.log` and `status_clock_route_run.log`.
