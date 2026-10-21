# C11314：继续压缩至80%以下

本轮接续用户确认功能、声音和频谱正常的C11313，于2026-10-20开始、2026-10-21完成离线交付。最终B04使用7748/9800 Slice＝79.06%，较C11313的8243减少495（相对减少6.01%，占用下降5.05个百分点）；较C11312减少1964。严格低于80%的目标已完成。所有实验保持原时钟、引脚、SDC与PHY配置；基线源码、旧bit和冻结清单保持。新C11314实板待测。

工程：`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_resource_80`；实验：`development/resource80_work`。用户反馈原文、版本关联依据见[基线与反馈](board_feedback_and_baseline.json)。C11313用户板测反馈按交付上下文关联，本轮新位流在离线完成后另行板测。

## 全工程消融

|版本|改动|Slice|占用|Setup ns|Hold ns|选择|
|---|---|---:|---:|---:|---:|---|
|C11312|原资源基线|9712|99.10%|+0.060|+0.024|历史|
|C11313 A10|上一轮算法优化、AreaHigh|8243|84.11%|+0.101|+0.011|用户反馈通过|
|B01|mapper精简+WAV v2|8232|84.00%|+0.126|+0.003|已封存|
|B02|同B01 RTL，AdderThreshold18|7837|79.97%|-1.364|+0.003|建立时序违规，退出|
|B03|catalog锁存合并、BMP header压缩与stride化简|7892|80.53%|+0.687|+0.012|时序通过，尚差53 Slice|
|B04|两路mapper稳定请求/已验证几何专门化，WAV静态描述符|7748|79.06%|+0.633|+0.011|最终选中，TNS0|

全工程结果均由该次成功synthesis和physical的runId关联，完整source/scripts/sim/manual与当前gate审计归档在candidate/build/attempts。器件LUT、generic LUT分别记录，最终Slice采用route.qor的实际值。

B04 gate为13151器件LUT/7793FF，physical为13976LUT/7858FF/14779LE/45BRAM9K/10DSP/2PLL/3GCLK，STA coverage99.98%。目标最多7839 Slice，当前还留91 Slice的整数余量。source/物理配置由阶段范围守卫绑定，约束与PLL/IP另行逐文件SHA核对保持。

## 算法与冗余消融

- 两路mapper：walk/cache_walk计数与index恒等，删除重复寄存；合法访问目标至4095，递增到目标即取数据，删除不可达4096-hop分支。簇值28bit、Brent power/length13bit、byte计数10bit；先28bit减2再补零，保留完整地址进位检查；FAT offset对齐且完整512字节已保证四目标字节齐备，删除got_mask。
- WAV v2：按字节移位组装、固定PCM16/mono48k profile累积匹配、data_end消除播放热路径求和、priming饱和计数13bit、fmt索引5bit、RIFF部分字段24bit。AreaHigh独立1347LUT/641FF→1291/468。v1在AreaHigh下LUT退化，退出。
- catalog selected_latch：MBR分区表仅在LBA0首次解析，选中后冻结selected_start/size供VBR使用，删除chosen重复64bit。AreaHigh独立2131LUT/837FF→2021/773，优于其它组合；10项单项/组合数据保留。
- BMP header：固定magic/planes/bpp/compression字段按字节累计匹配；宽度保留低11bit与高位非零标志，高度保留符号/低10bit与高位全0/全1标志。非法尺寸的低位stride、image bytes仍按旧位宽计算，完整failure mask两个extent位保持。独立2173LUT/814FF/DSP7→2052/699/DSP6。
- BMP stride恒等式：令w=4q+r，则ceil(3w/4)=3q+r。实现为10bit `stride_words=q+(q<<1)+r`后补两个0，模4096结果对全部2048个width_low等价。B02原width→两级MULT18→extent链Setup-1.364ns，B03化简后Setup+0.687ns；最终全top DSP11→10。
- scaler rowstep实验独立LUT1033→1104、FF352→363，虽DSP5→4，面积负收益退出。额外43FF header字节定时流水独立验证后保留备选，B03时序已通过。
- B04按调用链消除重复存储：两路mapper的几何来自已验证catalog，事务内caller保持sector/start/size；WAV描述符在enable期间固定。编译期参数去掉重复请求快照、重复几何检查和WAV cache identity tags，BMP保留跨图像cache identity。全top比B03减少74LUT/226FF；同策略双实例独立消融为2069LUT/690FF→2015/569。原始声明位数、独立综合净值与全top净值分别保留。八参数组合覆盖通用与实际实例行为，新增运行时防御分支为0。

mapper独立AreaHigh：baseline1129LUT/397FF；计数精简1097/371；位宽1108/375；先减后扩1126/397；mask删除1105/393；组合1080/345。组合收益每实例-49LUT/-52FF，全top含两实例。逐项运行日志、源SHA与命令均在实验目录。

## 功能验证与记录修正

- mapper四单项与组合各13344拍边界差分；组合6381198拍、12295扇区，4096/4097簇、EOC/环、cache回退、Brent边界均通过。独立短/长SD、末字节与sd_end同拍对照通过。
- B04 BMP101专门化6381198拍、WAV111专门化6381201拍，两组各12295扇区，对原A889 generic逐周期接口与Brent状态对照全部通过。包含4096簇合法上限、4097超限、长EOC、迟发loop、cache顺读与回退。目录几何不等式和请求保持证明见mapper_specialize/README.md，接入前后源SHA与补丁见integration_manifest.json。
- WAV独立5900个gold样本、跨扇区/odd padding/大fmt/data-before-fmt、1024 prime、坏fmt、511/513字节扇区、FIFO并发、文件错误/超时逐拍通过。
- catalog 511几何473529拍、396根目录接受，175目录/525事务逐拍对照通过。
- BMP 538项诊断、512组raw32尺寸/边界、四坏帧与六图1843200像素对照通过；独立width4096类/height6144类、magic/planes/bpp各65536值等价证明通过。stride2048值穷举通过。
- B01与B03首次整机适配器只override9项，遗漏tf_wav_file_player.v，使用了归档夹具WAV；对应PASS保留为局部联调证据。已修正为10项，并断言归档夹具与候选间全部改动RTL都被选入；最终交付仅绑定修正后的完整回放。被动仿真监测验证真实caller的几何、请求稳定和WAV静态描述符合同，无新增综合逻辑。
- 修正后的B03 `system_20261020_222013`和最终B04 `system_20261020_222306`均完整122ms通过；最终10项override SHA对应全部8个实际RTL差异。1536000串行RGB、4446PCM对、3FFT帧72band误差0、2844可见频谱柱体像素；被动合同监测BMP 3次/WAV 27次请求通过。
- 最终B04 gate FFT3组72band固定点误差0，gate与routed的1536逻辑ROM词/3072 lane条目均逐字初始化一致；strict报告保留6项SIG→INV参数差异及FAIL原件，gate/routed真实LUT与pin mux分别穷举32状态×6控制共192行，均全部等价。routed时钟45 PASS、0 WARN、0 FAIL（另有9项INFO元数据）。

整机夹具采用已核验的nominal PLL edge replay、应用接口SDRAM模型（data领先valid一拍）和短BMP/WAV素材，串行HDMI逐内容记分排除首冷帧。summary中的C11312为夹具谱系；候选Build ID和实际源SHA由source_receipt记录。物理SDRAM、完整SDF与新版本实板表现另行验证。

## 交付与复现

- 新bit：`E:/VSCODE-project/FPGA-ANLU/download/spectrum_resource_80.bit`，634280 bytes，SHA256 `60ed79eecfcbd271bbc2b9a9333d5da03668e00b580a6be751ebcd61f0fa4d28`；同名info.json及[交付凭据](delivery_receipt.json)记录资源、时序、仿真假设、阶段ID和板测状态。
- 冻结目录：candidate/checkpoints/C11314_resource80_20261021_offline，282文件，manifest SHA `3ac05765fdd42deeb4b7b6fa14239465d0d3faffefef7ee52172e16c561d515f`。包含源、约束、构建脚本、阶段记录、当前gate/routed网表、实际策略参数、全部ROM/时钟证明、选中整机源码/日志与独立bit。
- final_binding.json为PASS：99项源scope、10项整机override、夹具文件/测试台SHA、gate FFT日志/manifest、routed ROM/clock/控制证明、3份bit和282文件清单全部核对，Slice≤7839及最终四项WNS/TNS均通过。C11313父源169文件、原C11312源168文件、8外部blob、3个旧bit及C11313冻结206文件核对保持。
- synthesis run `619c41c8-338e-4143-92b2-799c3122013c`；physical run `99966ac9-088e-4f3e-ab6d-232d2bc71ad6`；bitstream run `d1bd4900-43f0-4dd5-9df6-4ce85e60bac5`。选中source/阶段/仿真/位流绑定，不采用前轮残留physical数据。

工程根PowerShell调用：`pwsh -NoProfile -File development/player_spectrum_resource_80/scripts/build_candidate.ps1 -Stage synthesis`，随后同入口`-Stage physical`、`-Stage bitstream`。整机：`python development/resource80_work/run_system_candidate.py`；单项消融入口与命令在resource80_work各README/manifest。只读routed导出后运行gate_verify/run_c11314_routed_audit.ps1，参数绑定当前synthesis/physical ID与timing报告。重新构建产生新的runId和哈希，需按同一流程更新审计与交付凭据。

下一步为C11314上板检查Build ID、启动/多图切换、声音、频谱、按键与持续运行，记录实际观察和时长。C11313用户通过版本及独立位流继续保留。本轮尚未上板、提交或push。
