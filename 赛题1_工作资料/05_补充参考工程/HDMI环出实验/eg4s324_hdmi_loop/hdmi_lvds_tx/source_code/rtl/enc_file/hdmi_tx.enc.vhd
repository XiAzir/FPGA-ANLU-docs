-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;


entity hdmi_tx is
	Generic (FAMILY : STRING := "EG4");
	Port (
		PXLCLK_I : in STD_LOGIC;
		PXLCLK_5X_I : in STD_LOGIC;
		RST_N : in STD_LOGIC;
		
		--VGA
		VGA_HS : in std_logic;
		VGA_VS : in std_logic;
		VGA_DE : in std_logic;
		VGA_RGB : in std_logic_vector(23 downto 0);

		--HDMI
		HDMI_CLK_P : out  STD_LOGIC;
		HDMI_D2_P : out  STD_LOGIC;
		HDMI_D1_P : out  STD_LOGIC;
		HDMI_D0_P : out  STD_LOGIC		
	);
			  
end hdmi_tx;

`protect begin_protected
`protect version = 1
`protect encrypt_agent = "Anlogic"
`protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
TCsnJdTv+QI7twtEWHXfIhKrnCTSvwsJ75W73xaeUeNxDZVwBBPZashNry+Pf+GD
OXU1M0pkxY4JSMu+x8SMNZ0k+twePoT7YWxINbPnLh5tURnuH6JrFj5SucmDQggi
bcVgM28PIExDNk5M42c3so8B6norCk/Z4o9fqjlfHss=
`protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`protect key_block
dEowvgHQYcyLMf9ZFSceYP5z/r1VEJh3qmZz1m6iaqPgSBtWArEDwgMcFTLedTtS
V60wUkCu/TPGxdxxHUdMyD717or0ymlyCNoCi6aTpWh4ilEkh+qNQ2vMZZqeW/on
jq66ZKaMiBhUR8JSFO2n7/m0t9qQmky/TT4+hYeyMCZWk1RBqGZ00wsf18nUmHqX
8iJzhYP8GwtJA1Hq166rT4AHorRcVFc0ccBy4JeIZuGLvEz2Yvnynk66ZThv/udW
qozXrPGb/ovLU19grdqdGVEYcE3eIETa9GbJ8mzdqMnozr/iyjb7ps4guLSSvgaN
hPCyQk+unq6D9bLusotjZA==
`protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`protect key_block
W34vzO1PsIrn3cmimchIlOtqVQopIV1jcvU798RRGatoqtXkaZ95xhVeJrA0O2qS
uX4BIx3Z76I8MRetaFCemSSwtAZ+Knx0gI8zw+qjGW2C+/upTCRKd+SlIks3tia3
FuD7zygVz20UJV0DqeNH2qpQaDxqpX1FIMPQABQe95ij7n+O97e1j8ZzUD//RpEe
Rtt//4p688912g9xm4in8T+1q3PCJpQtrNKt3ic3Dguj/DLMg6szUJ9ESyt2ygMv
OCC0Cq4hQYyMf9uiovlJV3RuAQtZCb4IFO6rTNgxRA1UkzB7HotT69S/Yrv6ZfIj
G6lyKz3GnCXrgkD4JQ8zPw==
`protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
M0i/gtpTjl4b6xznlgRyFQOKwq4E8deoXfPxLVaPotnV7iEwRUkYBUfNisv8akuh
u/WqeGEBqaFKYDmeOuTVXxmEKx9bT3ZJ5WEN2+Fx5vsfgcimkSEonWQQHqMh8CQw
+HjbUxpdhgbYQLBJZg3V0pKQ9Ni4xKAJZeUCNQkmcO0=
`protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`protect key_block
E8xmXi7Zy00ypKbe+oRDsO6irAy0ngTB3GloznKouIDL8X2h+eP+E0p0INlzOyg+
ZS/2CHrqnaw+NXh7J7pqoCs7MbDm9xtjrR3zhKCdMKpId/vGRietwvwzzFNcXB6o
6G6PPXhaQTEV+hEPKwQY1ZStFJKFIVEkgCNndL0sUIkVqvdFR4iI5aOtU8qiodjQ
yzetOgy7nrD1yG6f/v85jYgwl5IMbnoh3oD7vBWMRWHthxZciWsw3xPV/GabyUzY
6dANJotqZMQJJKX9gopsJdA7MxflvMaL8ek2BfO4JHz/1aP9AoKMUOjy9mDHYTDa
qDjJPGDVDbXecL4NaLbSqA==
`protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`protect key_method = "rsa"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`protect key_block
CTF7CDMq6/PH4zam2xXDSX4VLGj1qxo2Hibp+C247w8YN2W9EuuYUYyI2jFcttND
ZAKL0I/6dtGv17Lp+yhno7cnLENpWH5BWs6khSxOjfJmDiQ+/nIeM2UidgOT0/96
pEMKGwt4D28hUsa6xOerjjEXNLXqGCgvxZRhaxEfCcQ=
`protect data_method = "AES128-CBC"
`protect encoding = (enctype = "BASE64", line_length = 64, bytes = 1168)
`protect data_block
M0hWQzkzdEtlcndrU21QZwAAiaHv/ov317nHROPGJ9cKdUYmDsnJHUJRFMWbWQKF
wIlETblNHEd+PGkyMBE3ax06q83scN8msfRCO9TtE4zFyRBI+8wemRukNcJkJ6Ey
Lkjvw1y98KExAZgnp0KaANcRIXlJ0t47K0awlDSCRWIODegEa7iIMtCcFy45PxRs
sYXuhefzSdUnaP5VsdQver7DH3uibLN4rgLYkgGbjSm5vNYXfq9rueov/fAKUJkl
fSt2dgWqXpl3cm9u0n5PKBerdZbzmQjQCLZyzw0/K0nyuMP7VeFLo+mv3NVNQ8Tj
TG+L7S6PVMVmXhisFWexj0EYuMgfS8uBplL5N6dPLGNzYZLqbe4gMZb+5ETxlUxV
fs68QA3wWz0dm+S07wKaQnWYtc1Z/4eHG2RmZkdKY4KLM5IjCDAex+7w6LjsjJhO
1pRtJoSJVIdw1V9w2zuZmAhua5KFHMmAP+gRUa0EaNyhEXsDdfufI+TNqU1ZWHDU
3detPvPZgnrYBMX4NMTz9HFwI+NuF4kYX9SPZg1lNZ7Z0VJ3uc/OtfUeRhXV56/v
ZjqVwwVaeaki1TbfAWMEUMQKzB1nDR8sLm/b8JBtIcsI3EmVHQhaTrl7Sf5/vg2F
CUVXN+rUVtYp4QdXFB/TYFP1FgDg+7wGAfBNuz/2Df5rNHHhuw1M1b9hQbOs2LGn
JgxuAVFVSsQv/bCdu1DdGZcr8LIWij2uuk7YNZAkeYkzu51wC6EBHQoXdkoJPa85
PcebZX4D6KyxVG5fL7UAFvVkhHhBHGHjeJvIfU27oZ3danAzzzs+0PmiZh1COsKQ
n1+/VTPe/aNzhufD52RHouWvQSxp3JnPRBatawBXMOaonh+VIfa+Mi9TUf7DUB4P
7x8ONFVmiDw5QmNvYCKRvR2l80D33ECVrGCpuKk9EMhk9VFTvfiqYf4rBlQ4fn1E
X20oSNuyftx2itncqQ6vFReqz2j1klS+1fqLcpskYem2LcIu7MFUGbpxKE8pcdaf
lHq+j3zVoQo+HIh48kzexGC2nFsezDDhUlXTDTHsaQ/JmkiH5xDkC+46758xNOfr
yF5Px34fazBjsrMi9Bzga1l5ggsYjd9cSFiQMzDM+OCMe9zjuiOYPn6IBz45fyEN
TKEYnBLfqT64xWBVtgO+LtwdUMqbm0e079Fl4MV/d/cTZRlwXVBw/fgUKBErhzmt
/TXlXS1x94N4/HQESif+AFKiwdYdDCWsNls2ALyFYHAL2Pf8tJvSIt97gd40Xm4b
actl3BATbV5kTuo6gWkPn2UxWcMVYVmw1infxgcWXLYt7i+6AixgFz1nhApLjPYs
yg6FUR6hPQUnve10AmK8y+/7PPntPNOHZ4MeHd5ILK8/sDcyr+XY7YmfoK4rYf84
drpa30ZLCk9n5t2Ok7vWuUiN1lVdt2Ym4jRY9gieFGN30Av1woMwRhGVN4svDiVn
XnHMXpqpaJmr+sz3TvSp6yG9uS79ieYLe7O2nbwtEkBULBpVT5F2DbsWkHkLrNVQ
TmCoc+m3PuEnBZ6ED0inKw==
`protect end_protected
