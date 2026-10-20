# C11307 对比 C11206：BMP/WAV BRAM 缓存与读延迟审计

日期：2026-10-14（北京时间）  
范围：只读检查 `player_spectrum_observed`（C11307）与成功基线 `player_bmp_scale`（C11206）的 BMP sector/row 缓存、WAV sector/FIFO 缓存、TD gate 与 C11307 routed primitive 配置，以及 BMP 头部字节数算术。未改 RTL、未重建、未操作硬件。板端结果按用户反馈记录：默认 WAV 有杂音、tone 正常、两音源频谱均工作、BMP 无画面；诊断观测为 `fsready=1`、`bmperror=1`、`wavprimed=1`，前 32768 个 PCM 样本输入前缀为 `F485`、flags 7、格式错误 0，未见 mapper/fs/wav 错误，样本速率约 48000/s。

## 结论

- 本轮检查的 4 个关键 RTL 文件在 C11206/C11307 逐字节相同（SHA256 相同）：`bmp_scale_engine.v`、`tf_bmp_file_player.v`、`fat32_file_sector.v`、`tf_wav_file_player.v`。媒体读取和缩放路径没有因 C11307 源码改动而改变。
- C11206 的 TD gate 与 C11307 的 TD gate 中，BMP sector RAM、RGB row RAM、WAV sector RAM、WAV FIFO 都映射为 DP8K BRAM；C11307 routed 导出仍保持相同缓存宽深/端口控制模式。配置中可见双端口时钟同接 `u_bmp_file_mapper/clk`、`REGMODE_A/B=NOREG`、`RESETMODE=ASYNC`、`RSTAMUX/BMUX=0`、`CS[A/B]0..2=1`、`OCEAMUX/BMUX=1`；各缓存读延迟与状态机安排吻合，没有发现读端被门控掉、误接时钟或启用额外 BRAM 输出寄存器的静态证据。
- `fat32_file_sector` 的簇缓存是单项寄存器缓存（当前簇、目标索引、簇链游走状态），不是 512 字节 BRAM sector cache；BMP 与 WAV 各有独立 mapper。它与两个文件播放器里的字节 sector RAM 不应混称。
- 对 BMP 已接受的尺寸边界，`source_stride` 和 `source_image_bytes` 的位宽足以容纳最大值；`pixel_end` 用 33 位加法。没有发现 `header_ok` 的乘法溢出/截断可解释当前报错。实际 BMP 头字节、停机阶段码和 scaler/frame write 提交状态尚未取得，故不能判定 `bmperror=1` 是由头校验、scaler、watchdog 还是帧提交失败引起。
- 这些证据排除了本次审计范围内的明显缓存映射/同步拍错接，但不能证明硅上 BRAM 数据、SD 时序、FIFO 全程供数或视频提交正确，也不能据此确定 WAV 杂音或 BMP 无画面的实板根因。C11206 只有 TD gate 文件可比；没有找到它的 routed 网表，故没有声称做了 routed-to-routed 等价比较。

## 文件与产物证据

关键 RTL 的 SHA256（C11206 与 C11307 相等）：

| 文件 | SHA256 |
|---|---|
| `src/user_source/hdl_source/bmp_scale_engine.v` | `A6C607738DB921E02C3D717F9C6CC9044CC3DDBC4FA02DD90B253FB541EF2C4D` |
| `src/user_source/hdl_source/tf_bmp_file_player.v` | `9CDDACB2F20A36D2E066EB74BF8FE55C5D675115281CE73B7D64EDAD3B8F93DF` |
| `src/user_source/hdl_source/fat32_file_sector.v` | `3F52481C29001B4489F5CBD0A54ACB0B209EA1DD073CB351A19EB8E00C9A6105` |
| `src/user_source/hdl_source/tf_wav_file_player.v` | `EF77371DBC8928AE6CDD3708B4FC555F253F0E6C727333AFFF9527416DADE082` |

用于核对的网表：

- C11206 gate：`development/player_bmp_scale/build/manual/AC201_tf_hdmi_gate.v`
- C11307 gate：`development/player_spectrum_observed/build/manual/AC201_tf_hdmi_gate.v`
- C11307 routed：`development/player_spectrum_observed/build/audit/routed_implementation.v`，SHA256 `1bbff31b4a68057807cbc04be5e1e973d33bb6b1696b6cbd2d055227cb8d7efa`。

各网表的层级注释表明上述 BRAM 分别来自 `u_bmp_file_player/u_scale/ramread0`（512×8 sector）、`ramread1`（1024×24 row，拆为 3 个 9-bit slice）、`u_wav_player/ramread0`（512×8 sector）以及 `ramread1`（2048×16 FIFO，拆为 4 个 4-bit BRAM）。C11307 routed 文件在 BMP 区域约 59271 行、WAV 区域约 210432 行；C11206 gate 对应约 71093 和 242332 行。实例参数与端口可直接在这些层级注释后的 `EG_PHY_BRAM` 实例核查。

## BRAM 控制与 RTL 拍数

BMP `bmp_scale_engine.v`：

- `sector_mem[0:511]` 为 512×8。写入条件是 `!rst && state==S_SECTOR && card_valid && sector_count<512`。sector hit 时 `S_BYTE` 锁存 `sector_raddr` 并转 `S_MEM_WAIT`；下一时钟沿在 `S_MEM_WAIT` 对 RAM 读并转 `S_BYTE_GOT`；再下一状态沿由 `S_BYTE_GOT` 消费 `sector_q`。所以地址判定到字节被状态机消费经过 RAM 读沿和后续消费沿，RTL 显式留有同步读间隔。
- `row_mem[0:MAX_SOURCE_WIDTH-1]` 为 1024×24。仅 `S_BYTE_GOT && component==2` 写入完整 RGB；读使能仅在 `S_ROW_READ`。状态机随后进入 `S_ROW_READ_WAIT`，在该状态把 `row_q` 锁存到 `pixel_rgb`，再进入发像素阶段。读地址/使能与输出取用之间有一个完整同步读拍。
- C11206 gate 与 C11307 gate/routed 的 sector/row primitive 均为 DP8K；row 为三片并接，地址 A=`src_col`、B=`x_src`，写数据为 RGB 三段；sector 地址 A=`sector_count`、B=`sector_raddr`。读端 `ceb` 分别由综合后的 `S_MEM_WAIT`/`S_ROW_READ` 状态位驱动，写端 `wea` 来自 `sector_mem_n`/`row_mem_n`。各 slice 的 clock A/B 均为 mapper clock。CS 常开、OCE mux=1、NOREG、异步 reset mux 0，与一个 RTL 同步读拍一致。

WAV `tf_wav_file_player.v`：

- `sector_mem[0:511]` 写入条件是 `!rst && ST_SCAN_ACTIVE && sd_valid && sector_write_count<512`；读语句 `scan_byte <= sector_mem[scan_pos[8:0]]` 是独立时钟过程、无 RTL 读使能。C11307 routed sector RAM 的地址 A=`sector_write_count`、B=`scan_pos`，写使能接 `sector_mem_n`，读输出接 `debug_scan_byte` 别名；门控没有从读端删除该通路。读出后 parser 用 `scan_byte_valid` 与 `scan_byte_pos` 对齐：先捕获地址/数据，再在后续 `ST_SCAN_PARSE` 沿消费匹配字节。
- `fifo_mem[0:FIFO_DEPTH-1]`（默认 2048×16）写使能是 `!rst && play_push`，同步读条件为 `!rst && fifo_load_head`，读地址是 `prefetch_ptr`。TD 将它拆为四个 DP8K 4-bit slice；C11307 routed 中四片地址 A=`wr_ptr`、B=`rd_ptr_b1`，写使能接 `fifo_mem_n`，读使能接 `fifo_ram_q_b_n`，时钟 A/B 同接 mapper clock，输出合并到 `fifo_ram_q[15:0]`。`fifo_head_valid` 仅随一次有效预取置位，并对同址读写使用 `fifo_head_bypass`，使样本数据与 valid 对齐；源码不依赖 BRAM 碰撞结果。
- C11206 gate 到 C11307 gate/routed 的可见模式相同：sector 512×8 / FIFO 2048×16、DP8K、无 BRAM 内部输出寄存器（NOREG），时钟同源；没有发现读使能、OCE、复位 mux 或读写端口配置出现版本差异。该静态比对不等价于对受保护 BRAM 行为模型做门级仿真。

注意：netlist 参数名 `CEAMUX/CEBMUX`、`OCEAMUX/OCEBMUX` 是 primitive 端口选择配置；具体动态读写条件还需看 `ceb`、`wea`、地址和时钟连线。本审计同时核了这些外部连线，没有只凭参数名断言缓存可读。C11307 routed 导出包含 `bmp_scale_engine.v` 和 `tf_wav_file_player.v` 行注释的 BRAM 实例，但没有导出 C11206 routed 网表用于逐实例布线后对照。

## BMP 头部算术边界

`tf_bmp_file_player.v` 先把文件宽/高字节组成 32 位无符号字段；宽度必须 `1..1024`，绝对高度必须 `1..768`，且排除 `height==0x80000000`。对所有可通过这些界限的 BMP：

- 最大行字节数为 `ceil(3×1024/4)×4 = 3072`，小于 12 位 `source_stride` 的最大值 4095。
- 最大图像字节数为 `3072×768 = 2,359,296`，小于 22 位上限 4,194,303；所以 22 位 `source_image_bytes` 不会在已接受的尺寸范围溢出。
- `pixel_end` 是 33 位 `pixel_offset + source_image_bytes`。`header_ok` 还检查 `BM`、DIB 大小/偏移、planes=1、24-bit、BI_RGB、图像范围不超过实际 `file_size`，且 `declared_size` 覆盖像素末端并不大于 `file_size`。

因此没有发现尺寸乘法截断造成“合法边界内 BMP 被误判”的确定 RTL 缺陷。若当前实物 `header_ok` 为假，仍需读取真实头字段和 `file_size/declared_size` 才能判断是素材不符合这组格式约束、头部读值错误还是其它停止阶段。

## 根因边界与下一步

已知 `bmperror=1` 且 `bmp_map_error=0` 将问题限定在 BMP loader/scaler/帧写提交错误路径，但 loader 没有保存错误阶段码；BRAM 静态映射与 RTL 拍数检查未找到可证的映射错误。WAV 前缀 CRC/flags、格式检查和 48000/s 只覆盖已观测窗口，不覆盖整段 WAV 每样本内容或瞬时欠载。频谱在两音源可工作也不能证明 WAV 全程 PCM 正确。

若继续定位，优先为 BMP 错误锁存 `state_code`、头字段（magic/width/height/pixel_offset/declared_size/file_size）、`scale_error` 来源及 WRITE_WAIT/COMMIT/watchdog 阶段；需要时再观察 BMP sector/row 的地址、读使能、读数据、mapper 返回握手。WAV 侧应补 FIFO 水位/欠载计数或扩大 PCM 前缀覆盖；只有数据或欠载证据指向供给后再调整仲裁。当前报告不提出缓存 RTL 修复。
