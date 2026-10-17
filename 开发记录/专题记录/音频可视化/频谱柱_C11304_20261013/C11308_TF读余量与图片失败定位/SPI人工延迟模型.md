# `spi_master` CPHA0 MISO 延迟边界模型

日期：2026-10-14（北京时间）  
范围：独立 Icarus 测试只实例化工程原有 `src/user_source/hdl_source/SD/spi_master.v`，不改生产 RTL，不建模整张 SD 卡、sector controller、仲裁器或板级信号。输入时钟为 50 MHz（周期 20 ns），CPOL=0、CPHA=0；从机首位预先驱动，之后在每个下降沿后延迟指定时间更新 MISO。

## 执行方式与证据

运行：`pwsh -NoProfile -ExecutionPolicy Bypass -File .\sim\run_spi_margin.ps1`（在 `development/player_spectrum_tf_margin` 下）。使用随工程保存的 Icarus Verilog 12.0。测试台及运行脚本为 `sim/tb_spi_margin.v` 和 `sim/run_spi_margin.ps1`；原 RTL SHA256：`37F7A21144FA5CCA3CC5C3B5F68A5AD40B3108336B600E45A1367734AC61403C`。编译/执行输出及 VVP 文件保存在本目录。

每个 `div × MISO 延迟` 组合读 24 字节：常量 `00/FF/55/AA/01/80/3C/C3` 加 16 个固定种子的 `$random` 字节。每组都复位/等待 SPI 状态机空闲后逐字节发起读取。总计 12 组、288 字节。测试台断言：延迟小于半周期时必须零误码；延迟大于半周期时应出现旧位采样错误。所有断言通过。

| `clk_div` | 半周期 | SCLK | MISO 更新延迟 | 错误/24 |
|---:|---:|---:|---:|---:|
| 0 | 40 ns | 12.5 MHz | 0 / 15 / 35 ns | 0 |
| 0 | 40 ns | 12.5 MHz | 55 / 75 / 85 ns | 22 / 24（每组） |
| 2 | 80 ns | 6.25 MHz | 0 / 15 / 35 / 55 / 75 ns | 0 |
| 2 | 80 ns | 6.25 MHz | 85 ns | 22 / 24 |

日志摘要：288 个字节读周期均完成；符合预期的延迟范围检查通过。`div=0` 在 55ns 及以上延迟出现错误，`div=2` 将无误码范围从 35ns 扩展到 75ns；85ns 均出现错误。这是该数字从机时序模型中的 40ns 与 80ns 半周期边界示例，不是实板 MISO 建立时间/波形测量，也不能证明 C11307 的 WAV 杂音来自 SPI。

## 频率和有效字节速率估算

`sd_card_top.v` 的参数注释与 `spi_master` 计数器关系给出 SPI 半周期：`H=(clk_div+2)×Tsys`。因此 `div=2` 时 `H=80ns`、SCLK 周期 160ns、频率 6.25MHz；`div=0` 时 SCLK 为 12.5MHz。

按 SPI master 的最短逐字节握手路径估算有效负载节拍：一个字节首个 SCLK 边沿到第 16 个边沿跨 `15H`；末边沿后，`LAST_HALF_CYCLE→ACK→ACK_WAIT→IDLE→下一字节首边沿` 至少另需 `(2×div+6)×20ns`。于是首边沿到下一字节首边沿约为 `(17×div+36)×20ns`：`div=2` 为 1.40µs/字节，理想有效字节率约 714 kB/s；`div=0` 为 0.72µs/字节，约 1.11 MB/s。该估算包含 master 的 ACK 状态间隙，假定上层在观察 ACK 后立即准备下一字节；未计入 SD 命令/响应/令牌/CRC、控制器状态转换和扇区间等待，不能当作整卡实测吞吐。

48 kHz 单声道 PCM16 的有效载荷为 96 kB/s。在完全忽略 SD 协议与服务空拍的理想模型中，`div=2` 的 SPI 字节节拍约为音频负载的 7.4 倍。若 BMP 与 WAV 均持续请求、仲裁长期按 2 个 WAV sector 对 1 个 BMP sector 分配，单以 payload 字节和相同服务时间估算，WAV 理想份额仍约 476 kB/s（约 5.0 倍音频负载）。这仅是条件化的容量上界；本 SPI 测试台没有接入真实的 sector 请求/仲裁，故不能据此证明当前整机持续音频带宽或 WAV FIFO 不欠载。
