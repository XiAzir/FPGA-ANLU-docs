//Company: Anlogic Infotech Co., Ltd
//Engineer:  ae
//Create Date:  25/04/2021
//HDMI_Sink aims to detect data islands 
`timescale 1ns/1ps
module data_island_extract (
    input FPGA_SYS_25M_CLK,

    input PCLK,

    //10bits rawdata in from 3 channels
    input [9:0] C0_RAW,   
    input [9:0] C1_RAW,
    input [9:0] C2_RAW,


    //when a packet transmits over
    //these signals are synchronized,
    //data_island_data_valid can be used as fifo_we to store 
    //packet_header and subpackets
    output data_island_data_valid,
    output [31:0] packet_header,
    output [63:0] subpacket0,
    output [63:0] subpacket1,
    output [63:0] subpacket2,
    output [63:0] subpacket3

);


`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
TPJpg08CD5+KNpuuj8VGpgqg8zg1/cm3jNV53sHnxXEnf8Kkg4/pYn1/OJiBJ2qy
BVu2FNTtK4L6f0iiUC5Kj7Ru0nrAIBpboGHwYFB8etAN8Oib6XRmd0vfPeSBNekL
icvXL5ldUOLkFFu1HZH8g5mQHsdVFXi0pHXtS1n0cxk=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
XOjMR8PmNzYtYb62fZNvV2mRPQZfWeABnk6un2T+tAo68DyTTNVkYhR/F0O630Kt
P56y2M6NX1Ztzh3TvWkEIS2ahDjZUBTJglFQDuMg6AWj1jkan9mX+qKyLIqZnFPk
uQpi+JRjyuxTF5MPfat3jSmem+HEIwscHSvWsTQgJvhhGfCONYtnx4NATsN4wMqn
v4QJ1wtS9zfTffkc602JkxeUeRh1W17g/MMacPVyvtU7NrED9ziBBuAioVm0LhZZ
5XIJbmnYQerQFTmhUIa+6pU68ICBaM3rNTUwtr07POd2Uieq1SyrXo1DJHdhr3e9
p0ISzjHsO5H/TzhyipXn7w==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
HZ6QZPjbFhtRB4qFhg/ckM+adUAzVYCLYTqWzyzw0dj/Jd4qAkVJCZTKyYIX+uvK
EUSrKPX/7vE2ITfbGqynt0VAUgWi6rj9mIeCQyD9jUKW4a4Id5fnJxPhZ6quaLGN
nNXe8e2e1n1hrp9o2Kx32hrrgT75x6vfrrrexIgmFak=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
FNnu4F28N4AfMG5AwvAWU80rJgKjf+0lpa2V/EFeCPNSWi8hiL6TuMlNzk3UZXlx
xmsiPpQOMCUtw8RI2hS4ceDeEZtJEXEfOQCuWhMrRTo+EVZlplzaHo0lZODFD2l6
3DpM84U3FxCi8LbmUaUL6bJizqoTtK2L4aclt7aSE5kPuKKrercLhB8XyO6wmHkk
WTx2X3z+BFsLvCFtC5YfBUWpR5ebUypHwg3+EBFDSRONe89PWrSz71MCcE6L+wVq
SbR0i1v+QEx0xuHC9S0A8Azo2tPUoc8KrzH+rkzH6D4iOIdUiXkQyUZlwBozut6l
C9PElKD0pO6Z495zDGWS0A==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
mlbcii4r7Qp2CIUpMClC+eMmLYQViWsoQbW7nETV0jnA8jfkfALjKRKfGfCCn1bb
4xW1knwM2YGPQ6GlXMJmRV+TyQ0WDKX4cg5Yfyyg7AQQdyVXS9fRGONL/0Ekp+tL
r39A5KlmiqKtM3k8VnLidMwBeeuhTS6T1B6YDhFTLPI=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 1264)
`pragma protect data_block
MWxhSzJNRmZnYW1oQ3ZpNpMNISudM+19by4Etbv3WE1+VdhEfBKb5jHRWWi2JJl7
SCgZJq+aKtbhgjtVb/dPwvBop5SiFU+8IBXP8rZVhugVB5DZNo9ZVcNEl3u2AukM
kWo5dgQ48Gm4fVjnxuJpNhWRkZ4sEg6madNirT3I6Fw/5AdBkDvI0YqkEqJbicyP
EcqZnL41jSER2tMakUJxxI/8UteIjBl55ebf8C8caAbnJeTCQY/Gb6rXe7UPzcFW
G3bWnixdBeoEShevyX06wvvXscdzokWGfITL1ZLtxzW+inVKfaBlqCdvejo94REw
5zgFdrt7MBRyd9OS4oswpYcx6iR/nGjF/Qu+qeI7CEjMZzBcFET1E1QIT2LqWSSj
gk8rSxubr/mOsmPvbZmJaKC3cq3VIyF6UdMJdfTjKzF8UVle9+8U7dTdF64w+s9G
fkvz6Wpx2tjQneD+HTQ+rlS/EqNEMzRlATShziI5gZvUlrzkSN91oL/Rzk1FuGUd
baqAvZ+2/4R4hXxrJRewJIktmVRXtogW9wrgxJo88o4W23+8wz8YJ/6Tsu+14B5h
6/LwOJzkEyGffIUomNzM0LCM6ybshxBH0UCCyhun9CuQS3CefIp39EwvX0QP2GVh
veETWbmTD26P/dZFE4oVkAIpvbuYp7G/befeO141idTKVHzvdEoePq1DWHeGXqb2
EcOgP2O9JnpKhWIeqIL9Xe1MaTk7EB2Ej32Pp75yJaUY/5BCRahigelB4tyt3C9g
FbJMYHjYiR04qnI4yk9jyq9g4YGkjSVLuBsSc1ZKKUMw9UPsNRjvceokNkjp4vZt
Iu0PCit+qYJfZLedQ58p4VRU9wXX0pkMSroy/rPRg2p5xpKocAsJVAm2xP8iL0Pi
Qdo5pFIkClwc5Vy681vF8evt5SDk6sV+PtKRkszsi4Jl6Ym3q5uJHMVCzCEpQBqB
KkLC/84nnyi2Bys+qyNMLN1LWMzRJ7Fw8xs7UJA1hEoe7Y5k4DOiQCOg/68ZwT46
TuEEUgiMpQ3HT/UOKybqmNP0CAeuYCjFF2h3fT6lfR9CCsLIEpuTJBYH5UjKiMdZ
3Tp2/CugpjWuW5tSKcNXYSFokq7OcwRq26Z9tdeuvkasm2Sbdy/ZXreUjqymfOPR
TO6OW7Aam8TTVsfgqMOoLl8HeCzNsTc1718XukM+JnDKiKymzREvco1FuE9AiowI
IHr6LN4ReDf1RjmJyp05RcTic6mEN8V+Ml6aoILCYIhvq+QGcEcXo3+iacYhaqNu
/Anxov1P/8J2FZl2O+3+l2dU55GGkVPKhRb1Kvm6/4DGBGp/Iv46mcTBZoqsgnuf
9M7PZUYihlNEAUvwULQkwn8s/TVBtriZDj0WOskS0GmeS5xPQVpZptcYqWmtdmMk
4a6MQ5aYG9a5kNE/+gQM38Tf7sTc9oMxHk+vDYs22OI5pX3j/4IvyYux9R0Hh2CF
tspqZB4sR34aVeC/+8amfTnMNeq+ztsUWdIRFctUX1rZs6xZDU7bynoNo9Pi9ppO
5DBjWyPLl1cr9WbgMpgKtE1ol/GogXKSuckFFi5J76PpojfmU8ctJjyfgMOHnasv
t42WMO98TcReX9OOgHXdJCuMuoh2BBJhh9CozbwWJ5muUi0LBymvIlkPRiMehNQH
MvBcjvSDzqd8Eq9Yvr/1Rw==
`pragma protect end_protected   

endmodule