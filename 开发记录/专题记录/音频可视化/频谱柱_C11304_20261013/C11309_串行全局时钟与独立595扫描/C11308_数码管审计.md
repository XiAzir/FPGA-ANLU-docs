# C11308 数码管时钟与输出静态审计

时间：2026-10-14（北京时间）。范围：只读比较 `player_spectrum_observed`（C11307）与 `player_spectrum_tf_margin`（C11308）的数码管时钟、复位、数据源、595 输出 PAD、约束和已有实现证据。未改 HDL、约束、位流、交付 ZIP；未运行 TD 或操作硬件。

## 现场现象与可用照片

父任务提供的最新用户反馈为：C11308 左侧单个“8”持续超过 30 秒；图片切换、OSD、频谱在活动，用户表示视频时钟正常且拨码未改。此处记作用户反馈，代理没有测量板端信号。C11307 的归档视频/接触表（`player_spectrum_observed/build/board_feedback_20261014/after_contacts.jpg`）确实显示数码管轮换到多个状态页；但目前 C11308 工程没有 `build/board_feedback_current` 的原始现场照片，所以不能从旧图断定两次拨码状态不同，也不应要求用户重复已证明的 C11307 全量回载。

按项目硬件入口读取匹配用户 AC201/ES8388 的底板图纸。其可提取文字把 `S2` 标注为 `KEY`，并把它接入 `keys[2..0]` 信号；它不是图面上明确标注的数码管拨码使能。现有板卡约定只说明数码管显示受拨码控制，未给出可据此确认的具体拨码位/方向。因此不把照片中的拨码外观或 S2 当作已改变的原因，也不建议盲目拨动。

## C11307 与 C11308 的共同路径

- 两版 `status_hex595.v` SHA256 相同（`AFF2A8B7…`）；`video_pll.v` 相同（`57E45A06…`）；`pin.adc` 相同（`234048B3…`）。两版 `timing.sdc` 文本也相同。
- 顶层两版均令 `status_clk = video_clk`，`status_hex595` 的 `CLK_HZ` 为 25 MHz。C11308 顶层把该时钟同时接到显示扫描器和状态监视器的 `sys_clk`。两版 SDC 均对 video PLL 的 `clkc[0]` 命名为 `video_clk`。
- C11308 gate 网表中的 `EG_PHY_GCLK video_pll_m0/bufg_feedback` 把 PLL 的 `clk0_buf` 接到 `u_status_monitor/sys_clk`；PLL gate 参数/约束报告给出 `video_clk` 为 25 MHz（40 ns 周期）。数码管输出 PAD 的 `osclk` 均是同一个 `u_status_monitor/sys_clk`。C11307 gate 具有相同 GCLK 拓扑和同样 PAD 时钟连接。两份 routed 实现也保留这三个 PAD 与状态复位网络；没发现状态显示时钟被接去 TF/SPI 域或接成常量的网表证据。
- 两版 pin 约束都把 `seg7_dio/R14`、`seg7_rclk/R12`、`seg7_sclk/T14` 设为 LVCMOS33、drive 8、无上下拉，与板卡已验证的串行显示接口映射相同。PAD gate cell 使用 `DO_DFFMODE("FF")`，输出由状态机/移位寄存器驱动；不是固定的“8”常量。
- `status_reset_pipe` 源码初始值为 `2'b11`，仅由 `rst_n` 异步拉高复位，并在 `status_clk` 上升沿移入 0；两级后产生 `status_sys_rst`。显示驱动连 `status_sys_rst`，而不是 `rst_all`。因此播放/媒体全局复位按源码不会直接让数码管保持复位；如果 `rst_n` 长期低或显示所用时钟未运行，复位无法释放仍是电气/配置层候选，但与用户报告“视频时钟正常、画面在活动”不吻合，尚无电平测量证据。
- C11308 gate 将复位管线两级映射为 `AL_MAP_SEQ`、`REGSET("SET")`，异步复位输入来自 `rst_n`（`SRMUX("INV")`）；首级 D=0，次级 D=首级 Q。源码初始 1 在 gate 文本里体现为 SET 属性，`.INIT(1'b1)` 行被注释。该静态 gate 可证综合映射意图与外部复位路径，不能单独证明配置期间 GSR/复位释放的板端电气行为。
- `status_hex595` 在复位时把 `frame_value=0`、`shift_word=16'hFF00`、`digit_index=0`，并设置 `seg7_dio=1`、`seg7_sclk/rclk=0`；退出复位后每个槽依次写 blank、段码和位选，`digit_index` 递增覆盖 0…7。十六进制 8 的段码是 `7'b0000000`，只会因当前被扫描的 nibble 为 8 而显示，RTL 不会把左侧单个 8 作为常态。驱动每位约 1 ms 一个槽，8 位一帧约 8 ms；单个位静止 30 秒不能由正常扫描/自检页顺序解释。

## C11308 的实际差异与时序证据

C11308 顶层新增 `bmp_diag` / `sd_crc_diag` 跨域采样和诊断页输入；`player_status_monitor` 从 C11307 的 10 个工作页扩到 13 个（E、F0、F1），并更新 build ID。`status_hex595`、PLL、显示时钟/复位管线及引脚约束没有改。新增逻辑会改变布局布线，故源码与连线相同不能证明 C11308 物理实现一定与 C11307 等价；这个实现差异与当前只在新候选反馈的固定显示相关，但还没有因果证据。

C11308 路由 STA 的 `video_clk` 显示 25 MHz。`page_reg` 在 falling edge 更新，`frame_value` 在 rising edge 捕获；对应半周期路径余量 9.770 ns（`AC201_tf_hdmi_pr.timing` 的跨边沿页计数到显示帧数据路径）。这条已报告路径有余量，不能说明外接 595 的板端波形一定正确。全芯片 setup WNS +0.120 ns 的最差路径落在 `sd_card_clk` 下 BMP 诊断逻辑（width 到 failure detail），不是显示路径；不应把全芯片 WNS 当成单 8 的已证原因。

合成日志另有新增警告：C11308 的诊断同步器在顶层第 96/97 行引用 `rst_all`，而 `wire rst_all;` 在后面才声明（HDL-5373）。gate 显示该网用于 BMP/CRC 诊断采样复位；`status_reset_pipe` 与显示 PAD 的复位仍走 `rst_n`，所以此先用后声明警告值得后续消除，但现有映射不支持它是数码管固定 8 的直接原因。状态监视器中 `request_toggle` 也有先用后声明警告；同样没有映射到 `status_reset_pipe` 的证据。

## 结论与下一步隔离

静态证据排除了“C11308 RTL/约束把数码管编码硬设为 8”以及“C11308 源码把数码管时钟/复位显式改到错误域”这两类解释。C11307 与 C11308 的显示源/时钟/引脚继承关系明确；C11308 gate/routed 中对应输出仍有可切换的寄存器与同源时钟。它不能排除布局导致的特定实现问题、配置/复位实际电平、板上 595/数码管使能/拨码或焊接、电气输出异常，也不能从图片/仿真证明任何一种。

若主代理需要继续区分，最有信息量的证据是针对 C11308 当前已观察到的故障，确认 R14/T14/R12 三线是否持续切换：

- 三线在 FPGA PAD 侧都不动：优先看实际配置版本、`rst_n`、video PLL 到 PAD 的时钟/复位是否释放；这不要求再跑 C11307 已完成的十页整机验证。
- `SCLK/RCLK/DIO` 正常切换而屏上仍只剩一个 8：查外接 595 锁存/位选/段选及板级使能/拨码状态；先按匹配图纸确认具体开关，再判断是否需要改动。
- 三线切换但串行内容固定：查看 DIO 与 RCLK 采样内容，区分 monitor 的 `hex_value/frame_value` 是否变化和 PAD/595 之后是否异常。

该分支需要有针对性的波形/逻辑采样或清晰的拨码近照；目前未测，不要求用户重复同条件回载 C11307/C11206。C11308 的模型“诊断页通过”只证明数字模型产生页值，不证明板上显示驱动运行。

## 证据位置

- C11307 源码、gate/routed：`development/player_spectrum_observed/src/user_source/hdl_source/top_tf_hdmi_audio.v`、`status_hex595.v`、`constraints_source/pin.adc`、`constraints_source/timing.sdc`、`build/manual/AC201_tf_hdmi_gate.v`、`build/audit/routed_implementation.v`、`build/board_feedback_20261014/feedback.json`。
- C11308 源码、gate/routed/STA：`development/player_spectrum_tf_margin/src/user_source/hdl_source/top_tf_hdmi_audio.v`、`status_hex595.v`、`player_status_monitor.v`、`constraints_source/pin.adc`、`constraints_source/timing.sdc`、`build/manual/AC201_tf_hdmi_gate.v`、`build/audit/routed_implementation.v`、`build/manual/AC201_tf_hdmi_pr.timing`、`build/manual/synthesis_console.log`。
- 硬件资料：匹配的 `E:/QQ CACHE/Download/安路资料/赛题1_工作资料/03_小梅哥硬件与例程/AC201_底板_旧版_ES8388.pdf`；图面 S2 标为 KEY。
