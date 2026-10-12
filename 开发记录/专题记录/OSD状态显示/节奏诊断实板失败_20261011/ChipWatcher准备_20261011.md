# ChipWatcher 准备（2026-10-11）

## 现场条件与边界

用户确认只有开发板和 AL-LINK，没有示波器/逻辑分析仪；随后明确板子不接本机，当前人在实验室，通过远程电脑操作。代理本轮仅做本机离线文件、网表和 TD 编译操作，未连接、下载或操作 JTAG/TF/Flash。后续实际采样必须在板卡和 AL-LINK 所接电脑运行 TD/ChipWatcher，再由用户导出数据。

当前成功回退仍为 osd_phy_fix.bit。cadence_probe 冷启动仍无信号、原视频和 x_rdbk 成功日志已取得，无需重复同一批录像；根因仍未确认。

## 路线与实际证据

- 本机 SWUG111（2025.07）给出 source IP / Mark Debug / gate 插入 ChipWatcher 路线，都需要重新编译；Watch 可导出 CSV。不能通过现有普通位流直接读任意 FF。器件 Catalog.xml 的 ChipWatcher deviceRegexp 包含 ^EG4；这只是器件目录支持，仍需编译与上板验证。
- 现有 top_inst.bid 的 19 项均 is_debuggable=n，不能把它当成现成可用的 RAM 在线读回配置。之前在隔离进程直接 import routed DB 后 export_bid 导致 TD coredump（原 DB/bit 未改），日志及 dump 保留在 cadence 工程的 chipwatcher_review。
- 手写旧结构 CWC 和 gate mark_debug 的预试虽返回成功，但 export 的配置为空、无新增采样资源，明确不计插入成功。旧 PH1A90 的 edid_debug.cwc 不是本项目活动调试配置。
- 使用安装包 ChipWatcher_1.0 的 source-IP 接口模板后，独立小模型综合实际出现 2 BRAM/采样逻辑；但该小模型物理流程在 ppm.cpp:610 assert，没有形成可交付位流，不能算物理支持验证。
- 已建独立工程 ../../../../../FPGA-ANLU/development/player_dynamic_text_cw_probe，来源 cadence_probe；build ID C11101。采样 32 bit，触发为 request_toggle，深度1024。只增加被动观察输出/实例、IP stub 和 build ID，不改变播放器功能控制逻辑。
- 完整工程早期失败：SystemVerilog 文件需要 System_Verilog 项目分组；source stub 的 1 bit probe 需与工具生成 [0:0] 声明匹配；嵌套实例被工具报 unconnected trigger clock pin。已据日志修正前两项，并将实例移到 top 通过只读输出连接。最新顶层实例综合正在进行，尚未得出物理/时序/位流结果。
- 构建脚本增加扫描 TD ERROR/assert/coredump 的失败门槛；此前有 ERROR 后工具仍写完成标记，因此仅凭退出码或 marker 不足。失败日志保存在 cw_probe/build/preflight，不发布这些候选。

## 捕获定义

probe0：bit31=tone_mode，30=audio_valid，29:26=page，25:24=self_test，23=ack_toggle，22=ack_sync1，21=request_toggle，20=hex_value[17]，19=received[17]，18=mailbox[17]，17:0=audio_count[17:0]。probe1 仅用于 request_toggle 触发。TD 实际生成 wrapper 已核对 RAM_LEN=32、触发bus宽1、depth1024。

采样时钟为 pixel_clk 上升沿；monitor 的显示/接收字段在 sys_clk 下降沿更新，需结合实际时钟关系解释，不把边沿附近跨域组合字段当原子快照。此观察器会重新布局，不能将其结果直接冒充原失败实现的内部波形，更不能测量 HDMI 引脚电气质量或绝对时钟频率。

## 当前交接点

14:28 顶层 source-IP 综合进行中。下一步要求完整工程无 TD ERROR，物理实现与原约束 setup/hold 通过，生成配套调试配置，并检查配置真的含采样实例后再准备远端操作包。目前没有新位流交付给用户，不需要用户额外实物操作。

## 14:30 最终阶段状态：综合通过，物理流程退出，未交付

- 顶层 source-IP 版本完整综合已通过，最终日志无 TD ERROR；16580 LUT、8044寄存器、23 BRAM9K。82 个综合输入文件的 SHA256 重新复核一致。此前失败的综合输出不作通过证据。
- 完整工程 physical 在 `arch/ppm.cpp:610` 断言退出，与独立小模型同位置；保留 `build/manual/physical_console.log`。未完成布局布线、setup/hold 或 bitgen。没有新的板测位流，不能交给用户下载。
- gate 导出中仍有调试 hub 的逻辑层实例，配置导出为空；追加的配置/compile_watcher 离线检查也未得到有效 CWC。尚不能区分当前 source-IP 命令行集成方式问题与工具问题，不直接认定 EG4 不支持，也不能用本轮现象解释原 HDMI 故障。
- 顶层放置使先前 KIT-8466 消失，是本次实测；手册未找到必须顶层例化的明确限制。数据/触发/clock 连接、4处用户源码差异经独立只读核查；status_hex595原连接未改。
- 构建状态在工程 `build/status.json`；所有本轮编译进程已结束，未保留后台构建。原 osd_phy_fix/cadence_probe 下载文件哈希复核不变。
- 下一步：先用 TD 原生 GUI 生成/核对配套 ChipWatcher 配置，或确认调试 hub 的完整物理映射流程，再依据新证据重试。本机只负责离线开发；待构建与调试配置验证完成，实际下载和采样须在用户远控的板卡/AL-LINK 所接电脑进行。目前不要求用户移动板卡、改卡或再录旧诊断页。


## 2026-10-11 15:07:50｜原生配置已取得，切换纯 gate 插入路线（进行中）

- 经用户处理本机 TD 授权，使用 computer-use skill 的 Windows API 仅操作本机离线 TD。板卡/AL-LINK 在另一台电脑；没有下载、扫描 JTAG、改 TF 或 Flash。
- 原生 GUI 在隔离 cw_probe 工程执行 Read Design/Optimize Gate 并打开 ChipWatcher。源码例化实例仍未出现在界面。原生添加 cw_count_data[31:0] 后保存得到 `src/td_project/chip_debugger/user.cfg`，不是可交付 CWC；配置含 EG4S20BG256、auto_created_cwc1、32 数据/触发位、1024 深度，clock=u_status_monitor/sys_clk，与 video_clk 同源。
- 原生 GUI physical 实际执行 insert_debugger ../../chip_debugger → config_chipwatcher user.cfg → compile_watcher → debug_hub/watcher OOC → pack -eco/legalize_phy_inst。但含原源码 IP 的工程仍在 ppm.cpp:610 断言。GUI run.log 到 GP Iteration 后没有记录断言，弹窗确认文件和行号；断言进程已终止，GUI 已关闭。不能因日志没有 ERROR 就认为物理通过。
- 新最小对照 `cw_probe/build/gate_smoke` 不含 source-IP stub，采用 GUI cfg 结构和 `insert_debugger chip_debugger -cwc chip_debugger/user.cfg`。TD 接受配置，32 位全部 Checked，4 BRAM，place/route 完成，无同类断言。最终 SWNS=-0.366ns、STNS=-1.019ns、HWNS=+0.011ns、HTNS=0，因此未生成 bit；它只证明该插入路线可完成布局布线，不是时序或上板通过。
- 新独立 `development/player_dynamic_text_cw_gate_probe`（C11102）已准备并综合，去掉源码 IP，保留被动 bus，使用工程已有 `fehdl keep="true"` 保留网名。综合网表实际保留 cw_count_data，未见 AL_LOGIC_DEBUGHUB/u_count_watch；无调试器时19 BRAM。源码功能路径、PLL、引脚、SDC不变。
- 首次综合时 TD 重写了 .al 工程格式；源/config 哈希保护拒绝继续 physical，定位仅 .al 有变化，HDL/约束/config未变。旧日志/scope保存在新工程 build/preflight，正在重新综合归一化后的工程再进入 physical。尚无新位流、实板根因未确认。
- 安路官方 FAQ 明确 ChipWatcher 可在 Read Design/Gate 阶段编辑，支持 IP/mark_debug/直接添加信号；本次采用直接添加后的 gate 路线，具体工具行为以本机日志为准。参考：https://tech.anlogic.com/Cn/Index/listView/catid/12/m/Cn/cate/32/tp/1/p/2.html 。未联系或向厂商发送文件。

### 2026-10-11 15:18:49｜进度核对｜已完成（说明与留档）

- 核对：完整 C11102 纯 gate 候选 physical_console.log 明确 PHY-9009：MSlice 5079 > 4900，未生成 bit。原 source-IP 断言与当前资源超限为两条独立构建证据，不当作 HDMI 实板根因。
- 已准备：全32位触发失败证据保存在 build/preflight/all32trigger_mslice_fail；当前触发仅 cw_count_data[21] request_toggle，仍采集全部32位；preparation.json 标记 NOT_REBUILT。构建证据辅助脚本已落盘，其审查及新配置编译未完成。
- 影响/下一步：暂不能提供新上板文件；继续核对脚本和配置，再综合/布局布线及原约束setup-hold，全部通过才生成匹配bit/CWC供远控电脑使用。没有新硬件操作，TF/Flash未改；成功基线仍download/osd_phy_fix.bit，原故障根因未确认。

### 2026-10-11 15:28:21｜C11103仅计数采样版｜综合与布局完成，布线进行中

- 单触发C11102物理仍失败：4989 MSlice超过4900；真实配置导出接受32数据位和1触发位，证据封存在cw_gate_probe/build/preflight/one_trigger_mslice_4989，连同源/脚本/阶段记录保留。
- 当前C11103只移除top中的被动player_cadence_probe实例；pages6..B显示FFFFFFF占位、pageC显示CFC11103，原producer/mailbox/received/显示和CW32位捕获保留。独立gpt-6-luna只读对比确认top其余内容一致，不改媒体/按键控制，其他源保持。README明确捕获字段和证据边界。
- 构建脚本修正：hold只核对产物哈希后允许负时序进入修复；receipt解析为hashtable允许新增结果字段；脚本哈希包括ps1及tcl；bit成功要求bit和两份CWC文件哈希。独立审查未发现旧失败证据可被自动认证；尚需最终交付同次bit/setup_debugger/add_bid证据。
- 当前结果：wrapper综合成功，布局4795 MSlice、低于4900；布局中间时序SWNS -0.865ns/HWNS -0.111ns仅为manhattan估算，不能代替最终STA。route正在运行、无新bit/CWC交付。
- 成功基线osd_phy_fix与原cadence位流哈希复核未变；本机板卡未连接，无JTAG/TF/Flash操作。下一步最终route时序，必要时fix_hold，全部非负后才生成并封存bit/CWC；原HDMI故障根因未确认。

### 2026-10-11 15:33:23｜C11103最终时序与实现策略｜未通过；新策略综合进行中

- high/routability正式route：SWNS -0.247/STNS -0.445/HWNS -0.065/HTNS -0.573ns、coverage99.97%。fix_hold完成后hold +0.022/TNS0，setup仍负，禁止bitgen；prehold及最终hold文件保存。
- 负setup报告出现在debug_hub自动生成的1ns max_delay，含ctrl/stat握手和U_tap复位的recovery；这些是新增采样器闭合问题，不当作原HDMI无信号根因。没有放宽原SDC或debug自动约束。
- 独立post-route phys_opt高努力reroute试验在Abnormal Timing Path check崩溃（Oops coredump，工具进程返回0但无trial完成标记），未导出trial.db或修改正式PR DB，明确不计通过。日志在cw_gate_probe/build/postroute_trial.log。
- 当前保留high/routability完整证据到build/preflight/C11103_high_routability。新的物理策略为place effort/opt_timing/post_place_opt ultra和route effort timing，本机set_param及report_param接受；实际效果仍待真实构建验证。为保持阶段脚本哈希一致，重新从wrapper综合，功能源码不改。
- 本机未连接板卡，无新bit，无TF/Flash操作。下一步新策略physical及最终STA；成功才交付，未通过则准确留档继续解决。

### 2026-10-11 15:48:50｜C11104失败后收窄到bit17｜C11105综合完成、physical进行中

- C11103 ultra/timing实际run为e72daf4d，source脚本hash93076433153953AF07C251D8A7FF18B37401DC7985A12EA03152D7A16D285D94；route -0.137/-0.409/-0.011/-0.020ns，hold后+0.027/0，setup仍负，保存在build/preflight/C11103_ultra_timing。不能把它混成此前high/routability。
- 第二次只读post-route试验采用手册原样phys_opt -post_route -effort high，不带mode，仍在Abnormal Timing Path check coredump，无trial完成标记/DB，正式DB未改。不再重复这条已失败命令。PH1/PH2官方策略JSON不是EG4专用，未套用或据此声称适用。
- 真实封存high routed网表已导出到build/high_hold_routed.v；gpt-6-luna核对mux7_syn_711/715的Q分别为slave_0_rst_sync1/cwc_slave_0_rst，SR接debughub reset。它们仅沿用u_status_hex物理slice名；原显示复位status_reset_pipe->u_status_hex/rst_dup_9独立。报告名字不构成debugger改坏数码管的证据。
- C11104只缩采样到32x256，布局4806MSlice、23BRAM，BRAM未下降；route normal最终PHY8023/RUN8102，一处资源冲突在x10y46_e2beg3（OSD frame_pixel_b_n与WAV mux270_syn_79）。没有当前run最终STA/bit，旧报告不作C11104结果。全源/脚本/log/scope/evidence封存preflight/C11104_depth256_route_fail。
- 当前C11105仅收窄被动输出到10位、64点、bit4触发，原三段计数/同步/显示always块逐字不改；gpt-6-luna核对宽度和配置一致。9=tone，8:5=内部page（显示标签3对应page=1），4=request_toggle，3/2/1/0分别hex/received/mailbox/audio_count的bit17；不采集完整数值，不能声称丢失其它计数位。README已更新。marker页C为CFC11105，pages6..B是不可用占位。
- wrapper综合已完成，physical正在运行（place high/route routability），无新bit/CWC交付。原SDC和调试自动1ns约束未放宽；板卡不接本机，无JTAG/TF/Flash操作，原成功基线和失败bit保持。
- 下一步：本候选完整route与最终setup/hold，必要时hold修复，全部非负且配置/位流成对后才交付；原HDMI根因未证实。

### 2026-10-11 15:52:28｜C11105布线完成，时序仍未通过｜未完成

- 最小10位/64点ChipWatcher版本route完成，21 BRAM；最终SWNS -0.102/STNS -0.271/HWNS -0.062/HTNS -0.495 ns。prehold报告和DB保存在工程build/prehold/C11105。
- 官方fix_hold执行完成，最终SWNS -0.102/STNS -0.271/HWNS -0.062/HTNS -0.160 ns；部分最小时序仍负，不能生成或交付新bit。证据为cw_gate_probe/build/manual/physical_console.log、hold_console.log及当前final报告、stage_evidence。
- 负setup具体为调试器自动1ns握手总线约束；原播放器常规setup均非负。此结论定位当前诊断版构建阻碍，不解释旧HDMI实板无信号。
- 下一步：只读核查TD合法布局约束/策略，针对调试路径改善；不放宽原SDC或ChipWatcher自动约束。板卡仍在用户远控电脑，无JTAG扫描、TF/Flash写入，原成功osd_phy_fix继续保持。

### 2026-10-11 15:58:16｜C11105 seed1结果与调试hub局部布局试验｜进行中

- 相同C11105 RTL/采样配置，启用flow enable_seed on并place seed1、route timing；commit日志确认enable_seed为on。完成route，SWNS -0.192/STNS -0.416/HWNS -0.002/HTNS -0.006ns，setup未通过，因此未bitgen。封存src/scripts/DB/报告/receipt至build/preflight/C11105_seed1_timing；当前未执行该实现hold。
- 只读gpt-6-luna按SWUG116 pp.30-36及本机TD help确认bound是布局前聚拢手段。当前新增floating 10x10 bound cw_debug_hub，仅加入debug_hub_top，在insert_debugger后place前执行；相同HDL/PLL/原SDC和调试自动1ns约束，不修改时序数值。wrapper重新综合进行中，区域是否成功应用和新route STA尚未验证。
- computer-use再次尝试本机TD入口：工具返回Anlogic TD标题但app标识为Codex，截图实际为Codex前台、无TD控件文字；刷新仍同样错误。未执行点击/键入，停止UI操作，不据此宣称TD界面可控。命令行构建可用，实际板卡仍只在用户远控电脑。
- 旧HDMI无信号/bit17来源仍未确认；无可交付新bit、无JTAG扫描/TF或Flash写入。下一步检查bound应用日志、route和最终STA，只有全部非负才导出配对bit/CWC；远控操作步骤待可交付文件后给用户。

### 2026-10-11 16:04:33｜ChipWatcher局部布局仍时序失败，切换轻量LED取证｜进行中

- C11105 floating10x10 debug_hub_top区域命令被TD接受，完成route；setup -0.044/-0.134 ns，hold -0.089/-0.609 ns。fix_hold完成后最小违例仍-0.089/-0.219 ns，setup不变。完整源/脚本/DB/报告/receipt封存build/preflight/C11105_hub10，prehold在build/prehold/C11105_hub10。未生成bit/CWC，不让用户下载未通过候选。
- 改用隔离player_dynamic_text_bit17_led_probe/C11106：板上4个active-low LED将锁存tone模式下异常bit17在计数器、mailbox、received、显示page3中的出现。保持原status计数/传递/显示逻辑和媒体逻辑，单独被动观察，不插入调试hub。gpt-6-luna准备源/局部模型，主代理后续审查与构建；此时尚未完成、未上板，不是HDMI修复版。
- 选择原因：手头只有开发板和AL-LINK，ChipWatcher额外资源/自动时序路径阻碍可交付采样；LED可利用现有硬件读取分层标志，但精度是级别/曾发生事件，不是精确周期波形，编译也会改变物理布局。
- 官方SWUG111已查明edge触发、64点position15及File > Export Wave Data；无工程打开CWC受支持，但无工程主菜单入口未具体记载。本机UI识别不准而未点击，当前用户无需再录旧页。
- 旧osd_phy_fix与cadence_probe哈希复核仍9E893B.../8C56A7...；根因未确认，无板卡扫描、TF/Flash写入。下一步LED模型、原代码差异、原约束最终STA全部通过后打包，只请求新的LED实板取证。

### 2026-10-11 16:13:22｜C11106 LED分层观察器｜模型与综合完成，布局布线进行中

- 独立工程 development/player_dynamic_text_bit17_led_probe；无ChipWatcher插入。模型 MODEL_PASS，覆盖四灯active-low映射、单周期事件锁存、显示页条件和回WAV清零。原player_status_monitor.v与C11105逐字哈希一致；观察器不反馈媒体/音源控制，但重新编译会改变布局。
- 首次综合被输入哈希保护拒绝，证据比较是source改变、scripts一致；定位TD把.al的UsedInP&amp;R自动归一化为UsedInP&R。首次DB/日志保存在build/preflight/synthesis_input_change，不作通过。冻结归一化工程后第二次wrapper综合成功，runId=68d40b4b-9b4d-488d-9f57-d26805c7cf7f，物理正在运行。
- LED仅tone模式锁存异常bit17：D0计数、D1 mailbox、D2 received、D3显示标签3页的hex值。默认WAV四灯灭是本版设计；D3不再音源闪烁。C页build ID=CFC11106；6..B为FFFFFFF不可用占位，不能当作测量。
- 尚无新bit、未上板；原HDMI根因未确认，本机未连板卡，无JTAG/TF/Flash操作。下一步原约束最终setup/hold全部非负后才bitgen与封存；用户在板卡所接远控电脑操作。

### 2026-10-11 16:16:41｜C11106第一轮最终STA｜未通过，第二布局策略进行中

- high/timing布线完成，physical runId=3a6e4ebd-5cbf-4323-9e80-e8a6593b4118；SWNS -0.287/STNS -0.938/HWNS -0.011/HTNS -0.015ns，coverage99.97%，16485 LUT/7590 reg/17815 LE/19BRAM9K。没有bitgen。
- 最坏setup来自SDRAM宏内rw_vld_reg_syn_12到dq[15]等输出三态控制，capture ext_mem_clk_sft；不是新增LED计数路径，也不等于实板故障根因。完整src/scripts/manual（含receipts和报告）封存build/preflight/C11106_high_timing。
- 第二策略采用已有axis工程的place opt_timing/crit_path_opt/post_place_opt/hfn优化，effort high、route routability，seed off。仅改物理脚本、不改RTL/PLL/原SDC；重新wrapper综合已成功，物理进行中。尚未通过最终STA、无新交付。
- 下一步第二策略route/hold检查，全部非负才生成bit；候选上板步骤草稿在工程build/delivery_readme_draft.txt，未交给用户执行。

### 2026-10-11 16:20:31｜C11106 LED诊断候选交付｜本地验证完成，实板待验证

- 第二物理策略完成route，SWNS +0.621/STNS0/HWNS -0.075/HTNS -0.089ns；prehold DB/报告/receipts保存在bit17_led_probe/build/prehold/C11106_timing_placement。官方fix_hold完成后SWNS +0.621/STNS0/HWNS +0.030/HTNS0ns、coverage99.97%；16484LUT/7606reg/17812LE/19BRAM9K/0DSP/2GCLK。原HDL/PLL/引脚/SDC保持该候选来源，外部SPI IO时序未表征。
- wrapper四阶段源码/脚本/DB/报告绑定通过：synthesis 0b09132b-8e73-44fe-8dee-705d1285d6c1；physical fb2d9d7d-6d9a-40d0-9e2f-8dbace0742b5；hold eff5c722-725b-4154-abda-0eac734f346b；bit d5f02989-adf2-44e1-a450-a3e293bf624c。bitgen完成，629624字节；download/bit17_led_probe.bit SHA256 62749E0485A34671D6FDF3B761B00DA17981768084482BEF7942F0C38A5DADB5。元数据为同名.info.json，状态DIAGNOSTIC_CANDIDATE/PENDING。
- 局部LED模型MODEL_PASS；gpt-6-luna只读复核按键/灯位/页条件。原status monitor仍与C11105 SHA 14D3B0441D6A652343BE0089AD9E6DA660305091639F3A600C5A13ECADF6EE9E一致。D3在标签3页逻辑上等于received同位、加页条件，不是独立595/数码管末级证据；D0..D3只是采样到高的粘滞事件，新布局可能让旧现象不再复现，不能据此宣称根因已定位。
- 封存：development/player_dynamic_text_bit17_led_probe/checkpoints/bit17_led_probe_20261011_candidate，136文件manifest逐项复核；manifest SHA A1C81FD98AD9251E37E0E656C6E9775483788D3E7CA2571662AC1873B5DEC639。
- 交付：[bit17 LED ZIP](../../../../../FPGA-ANLU/deliverables/bit17_led_probe_20261011.zip)，655168字节/SHA256 8A6DD06F91B51344487A7A42B4A0F69CC898C8DF63B62D15B02B0097310A1F8A；包含bit17_led_probe.bit、原osd_phy_fix.bit、README.txt、info和SHA256清单。解压文件逐项哈希一致，download别名一致。回退hash仍9E893B0B6C86BF6FBEE19E74B5FB58933C1BEA6AA07F203786CCE96F3B60AE6F，旧cadence位流未改。
- 本轮命令行构建均结束；本机GUI此前目标窗口识别不准，未继续点击。板卡仍在用户远控电脑，没有代理JTAG扫描/板卡下载/TF或Flash操作。新候选尚未上板，原HDMI无信号及旧bit17来源仍未确认，不称修复版。
- 下一步：用户传ZIP到板卡所接电脑，在英文路径解压；确认下载空闲后断电5秒、上电、BitWriter PROGRAM_SRAM/5MHz下载bit17_led_probe.bit并确认成功。默认四灯灭是本版设计，C页应CFC11106；只长按板上KEY1约2秒（不要同时KEY0）切tone，松开保持25秒，记录D3/D2/D1/D0亮灭及标签3/标签1完整8字符、HDMI和音频状态。D3不再闪烁，标签3第二字符8..F用于确认tone。记录后可回载同包osd_phy_fix。无需改TF或重录旧cadence。
