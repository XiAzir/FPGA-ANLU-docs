//Company: Anlogic Infotech Co., Ltd
//Engineer:  Fan Junling
//Create Date:  25/04/2021
// to extract audio sample(both left and right)

module audio_store (
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
    output [23:0] left_o,
    output [23:0] right_o,
    output reg AUDIO_VALID // this signal can be used as fifo-wr_en
);

`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
DfEv+sojf5KRa/rl/VdXvhXkXR8gpw+Fkh1D9UfWa3JxXr1kNIEQhdlqkekpZyv3
P8TqUA2k+LwBDaHzl5WSPwZQLLt0yP8w7TyYxaeuZWW1TLRdCMZONl8NsaMJvyHW
rW2Kdu6yqAPTUWOIWfMpZRXua5gY9kJvwPC8CjYaKDs=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
VHoHqQFkox56ETxsIx1MJjdZ3SHPqPj+4NBS2Msae2KIxVODQO8XSO5ZTw2bTyeg
or1QgylIb+GiGnVSsQzBgaFQL6x0euklc8eqKbJRbWp2gCIWGntGRkNQerMpzmse
HXER0u767cmbTEz/JmrAzOw0gBXyvTAOBFV+Sh+Xrvv6fwXsVIQzGPUizgiqI5cJ
2jYBB9CT7R47N6ppmXKvjZ2KoYYwHkVyxlTVXxMayDlK4twAFlJpYnb/HA48Galf
nFqSV/+JUfM8Jo+5VUClbRSENRDpJF9nqmXr9qkr2hz+PqRwBQ4i4xo1BVBQDU5E
JCAeuSGgOrvcEZKpofr7FA==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
pUdYBG0AASWQGWmuN0pmrLhMbYpTCypPIHoqbOvcNJcBLNKSjtg5J0h+w0IYXuik
fbLY4gEKq2gciq37Q7dklSpqUsgpynLjCuk3IsNv6eNYqvorXgpC650kjMjDPrED
2idFh/KGcHATn/KPI/DwSUlYaISuyoNzREJH1EGh/UQ=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
QXBI99xNzzgFi5M3IvPhawAsnxGW1DYGXZQiZCaItZ7s+6Ze0V7rk5+zVUrLmzTK
JFJyUcR3DgSkI+rMZtpnouSI1wSR3iOAzeseT0a7LeDM4yOaEMKxtxJqjqV81m6/
NbHxbshD8d+NBcavWHPdyxGH1/3xmuNm6QkefTcITdxeIaR+dfF2hy/SrzzmcAIE
KNTnsMzlg3q/GZT22h/tkBZ65GR7kLCwAAakkteZryklyWMdwgB+1jwH166PFs4V
k6rGuTr8BrpIpwpWTJUirUc6V0WTMVCXi0j2FaA7qRa5MwBHlWEiepZ28CCTIDpo
9Ma5W4mP1Q6+oDrXU8Sv5w==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
NQrohRUTT3xmt5+D6tNnzoA/1C6/gvXuIuNsr2hNfTeVhF6WFNc52DDUS+n1342F
Uls3eG/GegWoEd93XvncVUuqICXwXmGRxQWBFuNRyi2m1cyzh5cPZSszaN8+53X5
PisyPxuU6LCdYvHIn7Ip198gyO0Ez3c/xQAlMZ5plko=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 3344)
`pragma protect data_block
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
`pragma protect end_protected

endmodule