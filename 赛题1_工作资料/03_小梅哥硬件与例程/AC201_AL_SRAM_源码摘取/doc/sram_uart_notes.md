# SRAM UART 验证说明

## 方案说明

- 顶层模块：`sram_uart_top`
- 时钟：`clk50_i`，50 MHz
- 串口参数：`115200 bps`，`8-N-1`
- SRAM 器件：`IS61WV25616EDBLL-10TLI`
- 访问单位：`16bit` 字访问
- 合法地址范围：`0x00000 ~ 0x3FFFF`

## 串口命令格式

- 读命令：`RAAAAA<CR>`
- 写命令：`WAAAAA=DDDD<CR>`

说明：

- `AAAAA` 是 5 位十六进制字地址
- `DDDD` 是 4 位十六进制 16bit 数据
- 大小写十六进制字符都支持
- 行结束符支持 `CR` 或 `LF`
- 推荐上位机发送 `CR`，如果发送 `CRLF` 也能正常工作

## 串口返回格式

- 写成功：`OK<CR><LF>`
- 读成功：`DDDD<CR><LF>`
- 命令非法或地址越界：`ER<CR><LF>`

## 使用示例

- 向地址 `0x0005A` 写入 `0xA55A`
  `W0005A=A55A`
- 读回地址 `0x0005A`
  `R0005A`
- 期望返回
  `A55A`

## 约束说明

- `clk50_i`：`K14`
- `uart_rx_i`：`E4`
- `uart_tx_o`：`P2`
- SRAM 地址、数据和控制引脚沿用原工程约束

## 仿真说明

- 默认 batch 脚本：`run_sim_batch.ps1`
- 默认 GUI 脚本：`run_sim.ps1`
- 默认 testbench：`tb/tb_sram_uart_top.v`
- 默认波形脚本：`sim/wave_sram_uart_top.do`

## 仿真覆盖点

- 普通地址写入并读回
- 最高合法地址 `0x3FFFF` 写入并读回
- 越界地址 `0x40000` 返回 `ER`
