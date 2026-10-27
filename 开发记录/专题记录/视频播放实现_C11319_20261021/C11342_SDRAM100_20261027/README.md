# C11342 SDRAM 100MHz

状态：2026-10-27 22:44，最终phase8位流与离线包已交付。C41为用户再次确认正常的回退基线；C42板测待进行。

交付位流：`E:/VSCODE-project/FPGA-ANLU/download/video42_sdram100.bit`，634280B，SHA`bf8e700b9a046576b0ceec99a37085137e31ba0ef6fee44e3401905a76ba6059`。完整包：`E:/VSCODE-project/FPGA-ANLU/deliverables/video42_sdram100_20261027.zip`，2823485B，SHA`e5bca945bedf7a89f6cdaa4bea56ae24efa21548a857010837048ae910c45ebb`。62项payload、manifest与ZIP CRC/逐项SHA通过；含C41相同字节回退。`verification/delivery_receipt.json`记录封包凭据，板测状态为PENDING。

下一步：按包内`00_START_HERE.md`用PROGRAM_SRAM加载00C11342，同卡同供电/HDMI验证图像、声音、视频/重播、快速往返、C/E页、3次冷启动及连续运行。通过后再推进高清内容与帧缓存集成；本轮没有硬件、TF或Flash操作。

## 最终实现与证据

工程`development/player_video42_sdram100`。SDRAM100MHz、转发相位288°/8ns；TF25MHz、SD逻辑50MHz、HDMI25/125MHz。照片640×480 RGB888、视频640×480/15fps Q90及原声继续使用当前TF素材。

最终read接口选择DATA_DELAY0；32条DQ路径设置setup2，对应source8→capture20，hold检查source8→capture10（周期等价下一word18→capture20）。实际routed DQ setup/hold+1.572/+2.392ns，SDRAM输出组setup/hold+2.011/+1.780ns；全局+0.285/+0.037ns、TNS0、coverage99.99%。TD硬IP DQ max/min为5/1ns，功能模型采用tAC5.4ns，按最慢档额外0.4ns折减后read setup预算约+1.172ns，板级偏斜/物理测量仍待。

最终Slice8884/9800（90.65%，较C41多87）、LUT17004、Reg8701、BRAM62、DSP26。9份user_source改动，104份保持；加密控制器源码全部同字节。初次单纯提频的时序失败促成读时序对齐及FIFO仲裁简化，过程保留如下。

| 核验 | 结果及工程仓证据 |
| --- | --- |
| 最终完整routed gate＋官方PAD＋APUG存储模型 | `memory_bench/run_C42_20261027_221201`：256字应用突发，4352写/读/返回全部匹配；周期req6/ACK6/AREF6；`221527`短4字突发460字匹配、req3/ACK3/AREF3 |
| 初始化 | 两组均PREALL1/MRS1、两AREF后external done；原wrapper单元覆盖init下降沿排除和复位后重新计数，`startup_unit/run.log`通过 |
| 最终PLL | `units_20261027_222447`官方模型确认100MHz及8ns相位；旧50MHz PLL负控被检出 |
| 刷新 | `units_20261027_200951`公开prefix自然启动4097脉冲，1562拍/15.62µs，4096间隔63.97952ms；旧计数负控被检出 |
| 写仲裁 | `fifo_timing/production256_20261027_203423.log`4782拍新旧相同；提前一字准入负控cycle170检出；reset-ready简化模型31边沿/4复位epoch通过，删同步释放负控检出 |
| 单字错误负控 | `memory_bench/run_C42_20261027_222536`翻转一个观察样本的1bit：raw768/768，capture767/768，scoreboard按预期报错 |
| 旧取数拍反事实 | `memory_bench/run_C42_20261027_222654`同一final gate当前拍768/768，前一拍0/768；严格前一拍比较按预期报错，保留原失败日志 |
| 源/构建/位流绑定 | `verification/final_stage_binding.json`PASS，bit绑定同一次synthesis与hold route；`verification/offline_checks.json`按各项实际输入分别绑定 |

完整routed网表SHA`437d44141607624e94ad9d04bea60f8eca6eec0d2d034d92573c8eec0230097c`；生成bit SHA`bf8e700b9a046576b0ceec99a37085137e31ba0ef6fee44e3401905a76ba6059`。模型对外部App/clock/reset施加输入，跳过power counter；SDRAM命令、DQ与返回数据经过生产gate。无SDF，覆盖SDRAM控制器接口和分开的仲裁逻辑；整机媒体播放、冷启动、长时间运行为接下来的实板验收内容。

22:07首次routed夹具装载因网表alias变化失败；对应`run_C42_20261027_220730`保留。后续将reset replicas和canonical read/write aliases按当前网表绑定后，22:12与22:15通过。此前phase9、C41夹具调试失败、trace及源均保留，未混入最终通过结果。

以下为历次候选的历史记录。

## 首轮消融

独立工程`development/player_video42_sdram100`最初只改5份源（PLL的v/vhd/ipc、周期宏、版本）。TF25/SD逻辑50、像素25/串行125MHz、480p15媒体保持。内存100MHz、转发144°4ns。官方PLL模型与公开刷新prefix通过；自然启动后4097脉冲、4096间隔63.97952ms；旧PLL/旧周期宏负控均检出。

完整TD布局布线的setup WNS=-4.428ns/TNS=-214.089ns，hold+0.003ns/TNS0。具体缺口：DQ返回采样-4.428ns，输出使能sdr_t→DQ -2.001ns，mem→SD ready传播-1.329ns，FIFO水位→仲裁-0.139ns。原源/脚本/gate/pr DB/时序/manifest保存在`development/video42_work/initial_100mhz_4ns`；没有生成该版bit。

## 当前候选

- FIFO写端以remaining_words代替write_cnt与write_len_latch之和，水位准入直接比较。生产256字突发、photo/JPEG、复位与抢占的逐拍对照4782拍PASS；提前准入1字负控cycle170检出。源与日志在`video42_work/fifo_timing`。
- 去除write_fifo_ready重复的raw reset组合门控，保留已有异步清零/同步两级释放与满/水位判据。定向unit31个采样、4复位epoch通过，删除同步释放负控检出；物理复位路径在新STA中核查。
- 100MHz转发时钟候选改324°9ns，上升沿采样明确对应source n@9到mem@20，读数据参数从延迟1改0。仅对专用于SDRAM的sft→mem返回路径设置setup2，保留由setup派生的hold检查；相邻word为source19/capture20，与报告source9/capture10等价，不另放宽hold。此时序/数据对应仍待新的完整gate/route验证。
- C41完整生产gate在870ns内部init_done时观测PREALL1/MRS1/AREF0，初始化规格要求两次AREF。C42 wrapper将外部init_done延后到两次周期ref_valid完整结束，使用raw_init_done的前一拍排除initflag自身下降，IP内部done保留以驱动周期刷新。新增4FF；真实命令检查将验证完整顺序。

## 测试夹具与失败记录

`video42_work/memory_bench`用完整gate、厂商PAD模型和APUG原版IS42总线功能模型，保留外部App/clock/reset强制与启动加速的范围。当前C41基线数据回放仍在校准；初版夹具曾有PowerShell switch/变量名大小写冲突、标量化BA/ADDR引用、POR阶段误检以及MRS/AREF顺序过严的问题，原run日志均保留。命令译码已经按RAS/CAS/WE修正，实际器件允许MRS前或后执行初始AREF。

原厂EM638325表20经根重新提取，tWR=2tCK，100MHz为20ns；先前代理误读2ns已修正。器件模型参数和TD SIP模型的速度档差异需要保留。

一次对旧pr数据库直接create_clock的分析调用因目标pin解析为空造成TD coredump，没有产生有效分析结果；后续采用候选真实PLL+SDC重新综合。TOFF/PAD探针仅准备过，当前选用9ns完整接口周期方案，TOFF探针没有实施。

## 下一步

新候选综合→完整数据/命令回放与负控→布局布线→核对setup/hold真实边沿与覆盖→位流和同字节C41回退包。每次只运行一个EDA/完整gate仿真重任务。C42上板待离线通过后进行。
