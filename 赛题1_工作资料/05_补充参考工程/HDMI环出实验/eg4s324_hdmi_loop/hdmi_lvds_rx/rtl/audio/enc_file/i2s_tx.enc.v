//Company: Anlogic Infotech Co., Ltd
//Engineer:  Fan Junling
//Create Date:  25/04/2021
/*
 * //bclk=2*AUDIO_DW*lrclk(fs)
 * //mclk=nx * fs ,in this module nx = 256
 * //so mclk/lrclk= 2*AUDIO_DW*nx
 * mclk is cs534 system master clk ,common 92,128,196,256x lrclk
 * when nx = 256, fs = 48khz, mclk = 12.288Mhz
 * when nx = 256, fs = 192khz, mclk = 49.152Mhz
*/

module i2s_tx #(
	parameter AUDIO_DW	= 32
)(

	// sclk & lrclk are both derived from iis_mclk
	// user should provide only iis_mclk external
	// as standard frequency
	input 				iis_mclk,	//12.288Mhz
	output reg			sclk,
	output reg		lrclk,
	output reg 		sdata,

	input			rst,

	// Prescaler for lrclk generation from sclk should hold the number of
	// sclk cycles per channel (left and right),
	// which should be `d32 in a standard specification
	input [7:0]	prescaler,

	

	// audio sample data
	// data are read from fifo 
	// these are interface to be connected to fifo
	// the fifo`s read clock should be iis_sclk/sclk(bclk)
	input [23:0]	left_chan,
	input [23:0]	right_chan,

    output reg      FIFO_re,
    input           FIFO_empty
);

`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
hWPunmfeNLOS724zvTVRGfaOQS2/2aW8VG9sLsAb6YRK2wT+XM5vKUHIdVfzGRhm
KwKC5DnpaRDinS1n28SwYh5x7sVpQkAUM0+GDKIcKLcrg3DqVEPqhxYFCyTQwcFn
vNrcUdFFh5JANGP7xac07fLYS/CS2YoMaQmM5uzfUrs=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
PJRQAzqTjgJFC67MdGS+1ORqdsUL+tMJWukZeCxZttkCE8hfXH+EAvNUrSiytShl
ooRfU9PtES/QsNVDFEGfXmZdimvOfPiPHgfrOqVQQFlIHziiU7glHncG3SUG0hYb
jjz0Y3lhLnQmJzpXdBW7yHJRjG/wcVkpvrfR73ONZ78jqHI3LfUjCF8J+RsPGqDL
RWGU78CKxnpIByz1Be+Dm8hbJMYGcWEfvlt1OoxP5jWKusDwf4/lrNhKnZKRY0Sd
4axdZXs1auFPixUw8q8AsuYUsRnJ1+slq7NQsqt3BbZEemKiSMF+/glxRSjPmfsa
Tz+kUFfAYIbDvDHTS8l6SQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
KsjHpypM3aIWClpkJaiDhDhVduAa7NAH4WqnEltPCFx+BLaR8TZ67n2tyoLMIzpG
VEeLvWg4P8D4XuyjH+cE4/aaBf9IRlx+yNQeCo3X2+I5p1FNJugYFKfMwKkGyBqH
aWeoZkc6KI7pxVntIMegdN+7bz8+6Fu6MSPy3mD9iOk=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
lbuRNxQ2o7Uft99RpIuVet9dC5kTwxbzfh233qlQOpRAS2GbYKG7rIq3iXmQmHTf
YuIaBEsFwW4llIr8Iqn0UlhdZDSEpJoh/F00/qijz/H1C6IcCjPQUrpOuQyoVRvt
Cu1/uEk32NReQ/DWrskv+RF3hcX13m/AJqClp/8rUjz4+fJaDAqyYxGmTVGoGbp/
qR6Brkxd4D/UHyHthiaZRkvzxg18FqBU3i/d8pxZP3/QGGO6MqO5r3JhP6fwWCwO
l/aEZ7qV/mrlSRxzgS/k8jJ4wMq7Txa3zI9wXOmz4wGyPlkL01jm7TznoWYdgjjh
o71C2FryvIZhiqoTrokXiw==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
O7OMxhtgHpooDThcw162UWdtjIw5IH+O2pPAMZrObViuwe1FKEnxlIqJ05csFkJ+
AheY68CAiNiiH89ml3PvOStJ++GK69caio+mQjCXeIpqpXBJAGNCGh/WPXNevmRy
EDaloP/qp/fyGTGh1DGMxg6HFwVSDl90MOnWnzxUQn4=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 4432)
`pragma protect data_block
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
8tU1gxd/e7lT1uD6QBdNog==
`pragma protect end_protected

endmodule
