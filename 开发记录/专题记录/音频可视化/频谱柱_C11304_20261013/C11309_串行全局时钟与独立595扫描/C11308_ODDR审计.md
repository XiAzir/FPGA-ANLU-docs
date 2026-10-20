# ODDR / HDMI PAD 时序根因审计

日期：2026-10-14（北京时间）  
范围：只读审计 `player_spectrum_tf_margin`（现场版本 C11308）、父版 `player_spectrum_observed`（C11307）和成功基线 `player_480p/checkpoints/compact_data_d1_verified`（C11206）的源码、已存在的路由后网表、STA/QoR；未运行构建、仿真或硬件操作。上板现象是用户反馈，本文不把它当作代理直接测量。

## 结论

找到一个确定的约束缺口，但没有证据证明它单独造成 C11308 现象：C11308 的 `check.timing` 明确报告 `HDMI_CLK_P`、`HDMI_D0_P`、`HDMI_D1_P`、`HDMI_D2_P` 四个 HDMI 输出均无 output delay（全工程共有 14 个无 output delay 的输出）。因此，现有路由 STA 虽然检查到内部 `EG_PHY_PAD` DDR 输入寄存器的 setup/hold，也没有验证 HDMI 数据相对转发时钟到达接收端的输出延迟和 lane-to-lane 偏斜。`STA coverage 99.97%` 不代表这些板级输出已约束。

目前看不到 pixel/serializer 时钟被声明为 exclusive 或切断交叉路径。报告中 `video_clk` 是 25 MHz、波形 rise/fall 为 0/20 ns；`hdmi_5x_clk` 是 125 MHz、波形为 0/4 ns。二者由同一输入时钟派生，报告检查了 `video_clk -> hdmi_5x_clk`，约束文件也明确注释要求保留其固定 PLL 关系。没有证据支持“缺少有效时钟相位”或“必须加 exclusive”是当前根因。

C11308 在 PAD `do[]` 内部捕获端点上有半周期 setup 路径，已报告的最差 HDMI PAD `do[]` setup slack 为 2.576 ns、clock skew 0.277 ns；该值不是接收端输出裕量。其 serializer 输入数据来自 falling edge，PAD `do[]` 端点在下一 rising edge，路径预算 4 ns。不能把 `d1` 理解成在输入 falling edge 捕获：TD 安装目录未加密的 `EG_LOGIC_ODDR` 行为模型把 `d1` 在时钟上升沿取样，并在下降沿输出；`d0` 在上升沿取样并在高相位输出。因此 falling-edge 准备、下一 rising-edge 捕获给内部输入约半个 125 MHz 周期，不是同沿捕获。

## 证据

### TD 宏语义与 routed PAD 映射

TD 6.2.1 SP1（`6.2.178.840`）本地模型 [`eg_logic_io.v`](C:/Anlogic/TD_6.2.1_SP1_6.2.178.840/sim_release/eg4/eg_logic_io.v) 的 `EG_LOGIC_ODDR` 定义在 191 行附近：端口注释写明 `d1` 为“negedge output data”、`d0` 为“posedge output data”；行为代码则在 `posedge clk` 同时采样 `d1` 和 `d0`，把 `d1` 再送入下降沿寄存器，并用延迟时钟 mux 输出。该模型还表明 `rst` 高有效，默认 `ASYNCRST="ENABLE"`。这是本机仿真模型的证据；不是对受保护的 PAD 仿真模型作推断。

C11308 的 [`routed_implementation.v`](../audit/routed_implementation.v) 中四个 HDMI 正端口均变成 `EG_PHY_PAD`，`ODDRMODE("DDRX1")`、`OUTSCLKMUX("CLK")`、`OUTCEMUX("1")`；例如 `HDMI_CLK_P_syn_2` 约 9705–9725 行，`HDMI_D0/1/2_P_syn_2` 约 9738–9818 行。PAD 的 `.do` 接到相应 lane 的 `S_oddr_data[1:0]`，四个 PAD 的 `.osclk` 都接到 `u0_lane...I_serial_clk`。这证明综合/布局布线将逻辑 ODDR吸收到 I/O PAD 的 DDRX1 功能；它不证明外部接收端时序已满足。

C11308 lane 源码在 [`lane_lvds_10_1.v`](../src/user_source/hdl_source/lane_lvds_10_1.v#L64) 下降沿寄存 `S_shift_data[9:8]`，并连到 `d1=S_oddr_data[0]`、`d0=S_oddr_data[1]`（75–76 行）。C11307 与 C11308 该文件 SHA256 相同；C11206 基线则在上升沿更新 `S_oddr_data`，见 [`C11206 lane`](../../player_480p/checkpoints/compact_data_d1_verified/src/user_source/hdl_source/lane_lvds_10_1.v#L54)。所以“C11308 与 C11307 使用同一 lane 源码”成立；C11206 的输入寄存器边沿不同。

### 时钟与 ODDR 输入 timing

C11308 [`timing.sdc`](../src/user_source/constraints_source/timing.sdc#L2) 创建 50 MHz 基准时钟并执行 `derive_clocks`；第 7–8 行重命名 PLL 输出为 `video_clk` 和 `hdmi_5x_clk`。源文件没有 `set_clock_groups -exclusive`，还在第 9–10 行说明像素/serializer 时钟同时运行且不可为获得 Timing Clean 而设为 exclusive。路由报告的 clock summary 也列出 25 MHz `video_clk` rise/fall 0/20 ns 与 125 MHz `hdmi_5x_clk` rise/fall 0/4 ns。

C11308 [`final_timing.rpt`](../src/td_project/final_timing.rpt) 约 11340 行显示 `HDMI_CLK_P_syn_2.do[1]` setup 检查：launch 是 TMDS video source 在 `hdmi_5x_clk` falling@4 ns，capture 是 PAD 输入寄存器 rising@8 ns，Budget 4 ns，Data Path Delay 0.986 ns，Clock Skew 0.277 ns，Slack 2.576 ns。相邻 PAD `do[]` 路径 slack 为 2.777、2.837、2.934 ns。路径终点是 PAD 内部寄存器（报告标记 `PAD (reg)`），不是 HDMI 输出端外部负载。

C11307 的 PAD `do[]` setup 路径也有约 2.576 ns 最差 slack、0.277 ns skew，输入源显示为 lane 的 falling-edge `S_oddr_data_reg`。C11308 的对应路径起点显示为 TMDS source falling-edge 寄存器，途中直接到 PAD `do[]`，说明该中间寄存器在当前映射中被综合优化/合并；路径仍被 4 ns 半周期 setup 检查覆盖。C11206 报告能看到 PAD `do[]` 的 hold 路径（例：`HDMI_D1_P_syn_2.do[0]`，hold slack 0.357 ns），其 lane 数据寄存器发射边沿与 C11307/08 不同。上述报告中的 `do[]` 覆盖说明内部 PAD 输入弧受 STA 检查，不代表对芯片 PAD 到板端/接收端的延迟建模。

### 三版 routed QoR 对照

| 版本 | routed STA 摘要 | 可用证据与限制 |
|---|---|---|
| C11206 `compact_data_d1_verified` | Setup WNS +0.398 ns；Hold WNS +0.014 ns，TNS 0；slice 利用率 55.05% | 路由后报告；HDMI 四个 output delay 同样未约束，不能视作已验证板级输出时序。 |
| C11307 `player_spectrum_observed` | Setup WNS +0.365 ns；Hold WNS −0.060 ns、TNS −0.154 ns、6 个违例；slice 利用率 95.51% | 四 HDMI 输出同样无 output delay。用户反馈其 tone 干净、频谱正常，但 BMP 缺失/WAV 有杂音。 |
| C11308 `player_spectrum_tf_margin` | Setup WNS +0.120 ns；Hold WNS −0.020 ns、TNS −0.084 ns、route.qor 记录 5 个违例；slice 利用率 97.18% | 四 HDMI 输出无 output delay。负 hold 违例在全局报告中；没有证据将其归因到 HDMI PAD。用户反馈图像有绿色竖带、两音源静音、频谱运动。 |

C11308 的较高利用率和 C11307/C11308 全局 hold 违例值得关注，但不能据此判定 HDMI serializer 失效；已查看的 HDMI PAD 输入 setup 路径有正 slack。三版的 `check.timing` 均列出四个 HDMI 输出无 output delay（C11308 明确见 [`AC201_tf_hdmi_chk.timing`](../manual/AC201_tf_hdmi_chk.timing#L353)）。同一诊断还列出 led、SPI、数码管输出无 delay。`final_timing.rpt` 的 setup/hold 状态只覆盖 SDC 建模的路径。

## 可行的最小下一步

1. 先修约束缺口：以板端 HDMI 连接/AC201 输入与接收配置为依据，为实际转发 TMDS 时钟端口建立正确的 generated clock（像素率及相位需按时钟 lane 的 10-bit 图样核实），再对 `HDMI_D0_P/D1_P/D2_P` 加覆盖两种边沿的 `set_output_delay -max/-min`，表达接收端 setup/hold、板级数据/时钟走线差和允许偏斜。不要用过松的虚构数字，也不要把相关 PLL 时钟设为 exclusive 来清除路径。新约束后重跑完整 routed STA，要求检查无遗漏并审阅每条 HDMI 数据到输出端的 max/min 路径及 lane skew。
2. 若要做结构 A/B，保留四个 lane 共用同一 serializer clock，并把每 lane 的两位 DDR 输入以明确的 D0/D1 顺序送入已映射到 PAD 的 DDRX1；当前下降沿预备、下一上升沿捕获已获得内部半周期 setup。先核对 routed PAD `.do[]` 映射与捕获边沿，再以最小单 lane/固定 TMDS 图样做 bitstream 对照。只有在新 routed STA 或捕获波形显示边沿/位序不符时，才调整数据边沿或 ODDR 输入寄存器；不要仅因“d1”名称猜成下降沿采样而反转数据。
3. 由于 C11308/07 功能症状与已有 PAD 内部 setup slack 并不矛盾，物理输出延迟和接收端波形仍需新增约束及后续实测才能闭环。本文未改已有源、位流或 ZIP，也未执行这些下一步。

## 补充：显式全局时钟缓冲是否值得 A/B

C11308 routed netlist 的 `video_pll_m0/pll_inst.clkc[1]` 直接连接到 `u0_lane_lvds_8_1/I_serial_clk`，没有串联 `EG_PHY_GCLK`。该网驱动四个 HDMI PAD 的 `.osclk` 和 49 个内部时钟端点，clock summary 记为 125 MHz、fanout 53、clock skew 0.326 ns；路由后常规报告的 `hdmi_5x_clk` SWNS +0.392 ns、HWNS +0.244 ns。报告对 `do[]` capture 用 rising edge，但未给外部 HDMI 输出 delay，所以这是内部时钟路径摘要，不是板端数据/转发时钟 skew 的测量值。

TD 本地 `eg_logic_clk.v` 的 `EG_LOGIC_BUFG` 模型是纯 `buf`，本身无法证明低偏斜。当前 routed netlist 中 PLL feedback wrapper 的 `EG_LOGIC_BUFG` 确实映射为 `EG_PHY_GCLK`，所以在 `clkc[1]` 路径上显式加入一个 BUFG 是低改动、可证伪的 A/B 候选；目前没有证据证明它一定降低 `clk4` skew 或修复画面/音频。比较位流需检查新网表是否有独立 `EG_PHY_GCLK`、所有四个 PAD `.osclk` 是否仍来自同一缓冲输出、PAD capture clock 与 PLL 相位关系是否正确，以及 routed setup/hold、clock skew/latency 是否实际改善。若结果无改善或出现新违例，应撤回该结构候选。低改动且必要的首要修正仍是补真实接收端 output-delay 约束。
