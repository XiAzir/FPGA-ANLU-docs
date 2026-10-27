# C11341：SDRAM周期刷新独立修复

## 基线与阶段

2026-10-27用户确认C40“一切正常”，已绑定`download/video40_spi25.board_feedback.json`。当前C41独立工程`development/player_video41_refresh`，保持TF25MHz、SDRAM50MHz、原HDMI和现有480p播放。C40源/位流/ZIP保持，作为实板功能回退。

18:18阶段：公开逻辑消融已通过，唯一TD综合进行中；尚无C41位流或板测。随后须核对综合网表真实AREF命令数及请求/命令比例，当前请求常数仍待该项收敛。

## 已确认问题与规格

- 旧`SDR_CLK_PERIOD`无括号，`SELF_REFRESH_INTERVAL`文本展开为0；C32/C40综合周期`Sdr_ref_req`常量0，已由宏/公开前缀模型和gate复现。
- 本地DS301 v2.7.8 PDF第7页确认合封SDRAM型号EM638325。APUG011按行地址数2048计算请求周期；公开前缀注释写4096次/64ms。根进一步读取Etron原厂Rev3.2，PDF第1页Features与第16页AutoRefresh明确要求**4096条实际AREF命令/64ms**。
- 原厂PDF：`参考资料/EM638325_Rev3.2_Etron_官方.pdf`，SHA256 `dc148ee92375cbf4d14c279c85cbf0fb15fdfbceefd42c9512e411a02899f4ff`。来源：https://etron.com/wp-content/uploads/2022/04/EM638325_Rev-3.2.pdf 。已渲染并目视第16页（图中4096/64ms正文清晰），字体替代警告保留。
- 初次沙箱内Invoke-WebRequest/curl因Windows TLS凭据失败；经自动审批的定向提升curl成功下载原厂文件，未关闭TLS校验。一次厂商模型预览越过保护标记显示原始编码文本，未解码/分析；后续只用公开前缀和合法编译器加载原模型。

## 当前最小候选与消融

当前两个源差异：`global_def.v`刷新宏、top版本00C11341；111份user_source保持。SPI、PLL、约束和SDRAM IP与C40同字节，top除版本外同文本。审计`video41_work/audit_source.py`实际PASS，输出`player_video41_refresh/verification/source_audit.json`。

当前试验宏：`SELF_REFRESH_INTERVAL (64000000/(`SDR_CLK_PERIOD)/4096-1)`，50MHz终值780、公开计数0..780使请求间隔781拍/15.62µs。该值按每请求一条AREF计算；APUG参考式可能隐含每请求多条命令，因此须在门级观察实际编码和仲裁后再封包，不先宣称命令层符合要求。

公开前缀仿真最终证据：`development/video41_work/refresh_model_final/summary.json`，只复制首个保护标记前的合法公开逻辑，未改变加密实现。覆盖：

1. C40原宏：5000个活动周期0请求，复现。
2. C41强制init_done单元：4097个单拍请求，相邻781拍，4096间隔63.97952ms。
3. C41自然启动：原公开上电/初始化时序后得到同一节拍。
4. 三个负控：原零刷新、仅括号但按2048行、遗漏终值减1，分别被无请求/过慢/间隔782拍断言检出。

第一轮TB没有直接include头文件，波形/间隔断言已通过，但宏打印出现undefined警告和错误显示32；补显式include后全部矩阵重跑到`refresh_model_final`，正确打印20ns/780，旧结果保留在`refresh_model`。当前仅证明公开请求逻辑与测试夹具的ACK模型，未含受保护命令编码、器件保持或SDF。

## 后续验证

委托gpt-6-luna核对本地规格后，进一步准备短门级对照，限定`video41_work/gate_refresh`：对实际EG_PHY_SDRAM端clk/ras/cas/we计AREF，核对每请求命令数、闲置/读写负载、请求/ACK与实际命令间隔。只使用已综合普通网表与原厂合法仿真模型；为观察命令可用明确空壳器件，必须单列范围。门级短测和TD重任务串行执行，模拟force与原gate SHA绑定。确认最小充分请求频率后再完成最终综合/route/时序/位流及上板交付。

下一轮100MHz仍需核对10ns周期、144°相移4ns、初始化计时、控制器关键路径、CDC/FIFO与真实读返回。历史现场黑屏/花屏与该旧宏的因果关系尚待独立对照。

## 19:17：实际命令复现与ACK移位入口修复

- 第一轮宏修复综合成功，gate SHA `3d5c2dfaaa2bb07d458ea689a61114f1727cd0c5d51f36069982facffe8c3c9e`；原源/收据/DB/网表已保存到`video41_work/macro_only_implementation/`。本轮只恢复宏仍不足以交付。
- C40单周期请求注入：`gate_refresh/run_C40_20261027_182749`，req1/ack1/实际AREF1，确认每请求一条命令。C41闲置`run_C41_20261027_190527`，req10/ack10/AREF10、全部781拍。仿真强制控制器50MHz与相移8ns（最早C40注入用同相），并加速公开上电计数，器件用明确无存储行为shell观察真实命令，不含SDF。
- 旧17拍混合流地址恒定且未查刷新有效，违反APUG地址/启动契约；失败记录保留。之后改为每4字连续递增、起始检查busy/refvld、结束留16拍，再补齐被映射优化拆开的读地址低位alias强制；混合流仍复现连续两拍AREF，确认超出旧夹具问题。
- 决定性trace：`run_C41_20261027_191126/command_trace.csv`，cycle3156周期req到达且rw_vld刚结束；3157 direct_ref_ack与sdr_op_over同时有效；3158/3159对外raw ACK连续为高；3163/3164物理命令均001=AREF。两路ACK是`req&&!rw_vld`与`ref_pending&&sdr_op_over`经寄存/合并的结果。公开前缀原样把ACK每个高电平拍移入20级链，从而产生重复命令事件。该时序已在数字门级定位；未将它外推为历史C40黑屏/花屏根因。
- 独立gpt-6-luna静态核对接口/ACK锥并抽取730个原样controller/命令PAD实例，逐实例哈希匹配。报告`contract_review/C41_refresh_contract_audit.md`、`C41_cone_readiness.md`和提取器/manifest保留。初版checker要求raw ACK上升数==req数过严：在刷新到达后新操作已进入pipeline时，可先direct ack再完成ack，首个命令会被RW窗口遮蔽。后续按真实AREF与req数量、命令间隔判断，raw ACK至少覆盖实际命令。
- 原gate只在仿真中将`sdr_ref_ack_sft[0]`驱动改为raw ACK上升沿：`run_C41_20261027_191346`得到req6/AREF6，原重复命令消失，间隔763/781/782拍；raw ACK7使旧过严checker失败，原始日志保留。
- 最小生产修法仅在公开prefix增加`sdr_ref_ack_1d`寄存，移位入口改为`Sdr_ref_ack & ~sdr_ref_ack_1d`；外部ACK接口和保护payload保持。`apply_ack_edge_fix.py`绑定修改前后保护后缀SHA均为`090edd71e139c8d240d8853e8046b954968976e8e8273f454ef4c82b6715e360`；最终全文件SHA `eba99d0903a7eff706553b4d21a15afb560c428a58556e373a29f4cc1f41ec5b`。
- 最终公开前缀请求六例重跑到`refresh_model_ackfinal`全部PASS；新增ACK宽度1/2/3/8及复位五例只产生一次移位触发，旧prefix宽度2明确负控失败。源审计3文件变化/110文件保持（宏、公开prefix、版本号）；SPI/PLL/约束同C40。19:18启动最终源单一TD重新综合，当前无最终C41 bit或板测，后续按最终gate再做命令验证/路由。

## 19:28：最终生产gate混合流通过，路由进行中

- 最终源综合完成，gate SHA `1c0dc1b9799724c18ead8dd27214d6ba75e161c8d92453a19fa16849c6d14263`。正式门级使用整份原gate，仅重命名顶层，ACK入口无仿真覆盖。
- `gate_refresh/run_C41_20261027_192512`：4字连续混合读写114次WRITE/114次READ，req6/raw ACK上升7/AREF6；真实命令间隔782/782/763/781/781拍，最小763，未触发短于4拍的命令约束，无X/缺命令。与旧macro-only相同输入的连续两拍AREF形成数字A/B。
- 19:26开始唯一physical任务，当前无最终route/bit/板测；随后补256字长突发和最终空闲。仿真器工作集约454MiB，退出后才启动TD，未并行EDA重任务。
- 代理cone子树730实例逐字节匹配仅证明文本；尝试补fan-in闭包后9539实例/127未解析net，不满足独立仿真输入闭合要求，未用于验收。根删除runner未使用的UseCone分支，并在该实验readiness文档标明失败状态；正式证据继续采用完整gate。

## 19:38：最终离线交付

- 最终physical setup/hold +1.177/+0.003ns，TNS0，覆盖99.99%。Slice8797/9800（89.77%，比C40少21，此为整版综合/布局结果）；LUT16850、REG8744、BRAM62、DSP26。未执行hold修复，最终physical已通过。
- 源/构建脚本/综合/路由DB/报告/位流绑定校验PASS，`verification/final_stage_binding.json` SHA dddc0d44599b0b3054055b02467f35a897708cffd417de0c81368c8562c92ff1；最终routed网表SHA a8ccaa65b235e18caa20b037ba24630b0773bd33b7f2c9c22f280255a8418fe3。
- 最终routed 256字长突发：`gate_refresh/run_C41_20261027_193406`，576次WRITE/512次READ、req6/rawACK6/AREF6，间隔838/835/838/566/835拍；最大观察请求→命令245拍=4.9µs。最终routed空闲`run_C41_20261027_193626`，应用enable均0且未force内部rw_vld，req2/ACK2/AREF2，相邻781拍。连同最终syn短突发114写/114读，汇总并绑定为`video41_work/final_gate_commands.json` PASS。
- 这些是完整生产网表实际命令的功能证据；仿真外部驱动时钟50MHz/相移8ns及reset，公开上电计数加速，器件为显式无存储行为观察器，不包含SDF或数据保持。routed实例较syn增加BANKREF模型，首轮缺该模型失败后补官方模型；第二轮已路由优化使6个旧alias失效，随后按真实net映射应用/初始化/请求/时钟并对原reset全部复制网施加同一测试reset，清单/bench/runner/hash均在各run保存。失败日志保留，未替换控制器实现。
- `raw_io_report.tcl`只在分析进程附加人工20ns max/0ns min delay，提取最终routed SCK/MISO；原project bytes执行后恢复，生产SDC/PR DB保持。SCK pad6.280ns，MISO内部3.408ns，required21.422ns，可供card tOD+PCB往返预算估计11.734ns；报告SHAe0eb15e28922cb0e082edd5306e2c80487de01dc9f267e876d6b8b1c24b87862。该估计与生产片内时序分项记录。
- 位流`download/video41_refresh.bit`634280B，SHA f572afe5baa74dc61df58132c172298690c92171d5c631630fec6b02d3c6b7ac。ZIP`deliverables/video41_refresh_20261027.zip`801592B，SHA d90beeed47e9ed9c10995131bc2862a7a7a78f356f12db6ed601403125bb1949；16份payload+manifest、ZIP完整性/逐文件SHA、C41及C40相同字节回退逐项通过。info/receipt为OFFLINE_VERIFIED_REFRESH_BOARD_PENDING / PACKAGE_HASH_VERIFIED_BOARD_PENDING。
- 当前C40用户功能通过保持，C41待PROGRAM_SRAM同卡/同外接5V/原HDMI实测。指南包含图片静置5分钟/切图、原声和音阶、视频3分钟/模式往返、3次冷启动、C/E三页与回退反馈。未操作硬件/TF/Flash、未提交/push；TD与仿真均串行完成并已退出，最终routed仿真进程峰值约1.15GiB。下一步C41板测后再评估SDRAM100及高清整机。
