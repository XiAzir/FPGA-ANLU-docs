//////////////////////////////////////////////////////////////////////////////
//
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1ps

module dvi_decoder (
  input  wire tmdsclk_p,      // tmds clock
  input  wire blue_p,         // Blue data in
  input  wire green_p,        // Green data in
  input  wire red_p,          // Red data in

  input wire reset,          // rx reset
  input wire pclk,           // regenerated pixel clock
  input wire pclkx5,         // sample pixel clock

  output wire hsync,          // hsync data
  output wire vsync,          // vsync data
  output wire de,             // data enable
  output wire [7:0] red,      // pixel data out
  output wire [7:0] green,    // pixel data out
  output wire [7:0] blue,     // pixel data out  
  output wire [29:0] sdout,   

  output wire [9:0]  ch0_rawdata,
  output wire [9:0]  ch1_rawdata,
  output wire [9:0]  ch2_rawdata
);    

`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
co6HYZ1NMV9cMEw4iE/FKxaPtDKTtj46VVFNQb0zshOH//Fj7HiEGS+McKEYKuGA
P3N8aMlcQoBKL9k0VNaGbx6cE/de4BTttpSsGDC313CRvQ92NdGdBqEzJhJ7ykK2
rJG//phnmYY0iKSukWEHrkeYj/QAHU2aAWV5TAV6N5Q=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
pkk7KyYGqxIa8VVCBrcczWr07PRhp8RzyafwmhqvEfPFlK5eUmElEw9cYccP2BPV
wKA4ozwllzcgG3qmcNTe87JIpD/07NpErFCHf7zqKi2UkADZ4nyWvi5OhCsvpTXd
zgxDSQevcp6DI1yGREXg+fYLR/sEkeOtySHD95ropJ4XIYMApFd3RIyxRGNpJhLS
Mf0TP6XaGJPeqD8tQDu0TEoIBdlDhZErqrJPWYfycGnb5NdeKzbr3YN1TsSWJ9AY
qSR/SSCz9EQ5B7DNQ6lQ3Ca4wFyniagoiwpj6oiYxud6bd/8zKAOi9lTx3NkhUdt
qM3geiZ7R+PxAaXKMwhrdQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
UkZLXyw0yYcLvYQu18WNK186ZZpIBG6X76y0oZN8VwcHDMVaL+4CeAxOQK8FzGYs
bqXJjepC/8manKy/MBNYpU2tt4h2auTLCUSif6zN9GxLiAcHGk4V3k/T8c5vCOtp
Osk5tMRl/TtzbmaJ+j6fPes/kh8ozAJ5C+e0gzcD+9fAoVOu092dsUMe3zM/bkpc
ZcfUWv19BzmvCfgEB+I7f6uEfJCqlWYKMNNn7S6hokra4gBS9eRS5DwY6+sOhKwI
M5cnxvJQDv3BH+kRyyJS0CjjG1aBTK0Ykr1TxkS6Wj45V4ic+m03YlzhKMeTibDR
W+rqfbgq92RPhw39sKTQjQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
h4qP4rFQqen/VD/bylKvgO8y/qpPJRf3IrA2vwlZQYLuKbIMNg3239pnZ8iRddOR
Snm1jwqxeaOqaAblve0UYasBK7Ha6X/XLuS07qJWbeVrPj/Qjvw1X32TCmwXRUdx
px1aPkkUwIsi6nDpEqpF9PujHt/QNXdyeTFXk+tT5eU=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
KKbG76h41tiYND9BTfh8uc+u7mArojWq4ApcQmUjLK1cRg3gkFJZdZjVQz7NBoOH
8/Ty99i3f4fOOU0Q/C5qSL+XOx3Qld6bBVKAIL80s7Mgyuz9mCZxXlgrUsigVyhQ
giGj8Bmr28IDDXEKlKwD0fCEd0vjU47a+k0bd+sHYpxIuxJYWSzBq7eEzYRfWRli
c5QNaBVwB8LiZXrL+Nr1FuOxtr7h6csOyLoVgGYr7PA3XtoulCN326l3jkxXee7V
S9Vwb8kKYlbIyB1YRGkyWU+LTXqtzq+MjXHuMo6PY40ksUYWj3u0tLcEhxJu4mD9
naiby3udCBq3PsPaKI9kiQ==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
lyez9ffPxsOy5DqHKHWrbx5srSqBij84fCRvzUq2NxoCUqqFx8nRxX4x5ftI6svT
1C7mhhJPVmfiIuqgvAgNwNwNCAKwwcHpY7YdL+WazGCtFH5nM1iqFMrAUpdshljA
R933+6JCB55ljoidSOO5YO4Cd49rsWU2wcMFL4HlEoI=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 5552)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
