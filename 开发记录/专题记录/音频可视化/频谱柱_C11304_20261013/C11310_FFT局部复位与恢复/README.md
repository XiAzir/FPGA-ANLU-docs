# C11310：FFT局部复位与停滞恢复候选（实板待验证）

C11309 已获用户音画及非频谱功能正常反馈，但默认音乐、内置音阶均没有频谱，视频显示 B7000000 / C7840000：FFT完成帧数为0。C11310对FFT内部复位增加两拍同步释放，保留五位状态编码及异常状态恢复，并在4096个输入采样脉冲仍无完整帧时只重启FFT。具体板上停滞原因尚未证实。

## 下载与观察

BitWriter使用 PROGRAM_SRAM、JTAG 5MHz，加载 spectrum_fft_recover.bit。D页应为 DFC11310。保留当前TF卡、接线和拨码，无需重新装素材。先看默认音乐频谱，再长按KEY1看内置音阶频谱；同时确认声音和图片仍正常。包内 spectrum_clock_route.bit 为已获音画正常反馈的C11309回退（频谱空），bmp_scale.bit 为C11206完整成功基线。

数码管启动4秒自检，之后每页2秒、完整轮转32秒。如频谱仍为空，分别在两音源录至少36秒数码管，覆盖B/C/F2/F3/F4；尽可能录两轮看变化，直接提供视频路径。

- B页：原采样校验flags + FFT完成帧数（后六位十六进制）；应持续增长。
- C页：原频谱阶段flags/最大幅值；前台空commit不代表FFT帧完成。
- F2页：后六位为 {state5位,捕获计数10位,窗索引低9位}，由程序解码即可；0捕获，1..3加窗，4..10/14..16蝶形，11..12扫描，13发送，17..31异常值。
- F3页：F3 00 RR SS，RR为局部超时恢复次数，SS为音源变化脉冲数；各8位FF饱和。默认稳定播放时SS不应连续增长，切换音源会增长。
- F4页：后六位为FFT实际接受的采样累计数，24位饱和；切换音源清零，局部超时不清累计数。

## 本地验证范围

312个合成频段、48个真实WAV频段、72个集成频段对独立定点模型零误差，650个独立RGB采样及遥测/状态页通过。单独恢复模型保留生产4096阈值与521clk采样节奏，覆盖非对齐复位释放、所有非法状态、停滞注入后恢复及计数饱和。快速数学/渲染/集成夹具关闭看门狗，只用于加速；不充当生产看门狗证明。

同源TD综合、布线、nativehold和位流生成；时钟及ROM INIT审计绑定最终网表。原参数逐字审计发现SIG/INV不同并保留原始FAIL，另以控制网真值穷举证明有效启用逻辑一致。模型使用行为ROM，未仿真厂商受保护BRAM或测量板上电气。原HDMI时钟、PLL参数、TF/BMP/音频生产链路字节继承C11309。尚未下载板卡、写TF或固化Flash，实板结果待验证。

## 交付凭据与当前证据

- 记录时间：2026-10-14 20:34:51（北京时间）；状态：本地候选交付，实板待验证。
- 候选：[完整包](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_fft_recover_20261014.zip)；[直接bit](E:/VSCODE-project/FPGA-ANLU/download/spectrum_fft_recover.bit)。
- bit 634280字节，SHA256 9A076C4170DEB9BA84526B61E9F086A12EF59399DB7721EAFB5F7A80186BFA0C；ZIP 330659006C9D8DFE3D6DB72310C9790ECBB7C192F6280EF8575FBC442584A864。
- 冻结 266 文件，manifest B72108D1DEFF5615D322661F1306485A389B908A00E45FC18AA39F5D704B7522；清单逐项长度/SHA、ZIP全部成员逐字核验，C11309旧240冻结/bit/ZIP及C11206成功bit不变。
- **C11310 FFT局部复位/停滞恢复候选已本地交付，实板待验证**：独立工程player_spectrum_fft_recover，仅analyzer/renderer-wrapper/top被动诊断/status四源修改；FFT内部异步复位两pixel拍释放、5位binary none/default容错、4096输入有效采样无帧时局部恢复，无反馈到音频或全局复位。312合成/48真实WAV/72集成段定点误差0、650独立像素/遥测/状态页/595模型通过；真实WAV和恢复模型默认4096/521clk，加速夹具timeout0明确仅数学用途。恢复模型注入非法态/停滞后不用全局复位即可输出下一帧。TD同源syn/phy/nativehold/bit，setup+0.236/hold+0.027ns/TNS0，17001LUT/10085reg/18508LE/44BRAM/12DSP/3GCLK；gate/routed时钟各45检查、1536系数INIT通过。原ROM参数SIG→INV逐字FAIL保留，补充按实际双lane逻辑穷举32态有效启用证明PASS。266文件冻结/ZIP成员逐字验证，旧C11309 240冻结/bit/ZIP与C11206回退不变。PROGRAM_SRAM/5MHz、DFC11310、spectrum_fft_recover.bit；启动4秒自检后32秒16页循环，F2=state5+capture10+window9，F3=00恢复8+切源8，F4=接受样本24。实板停滞物理根因仍未确定，protected BRAM/外部HDMI电气未验证，未JTAG/TF/Flash。[包与操作](专题记录/音频可视化/频谱柱_C11304_20261013/C11310_FFT局部复位与恢复/README.md)。
- 当前源绑定[模型结果](E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_fft_recover/build/model/model_result.json)；[时钟审计](E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_fft_recover/build/audit/routed_clock_route.md)；[ROM有效极性证明](E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_fft_recover/build/audit/rom_polarity_evidence.md)。
- 原控制参数逐字审计发现SIG→INV差异，原FAIL不覆盖。另读取实际gate/routed逻辑、正确区分双lane LUT/FF与组合解码，穷举32状态有效Hann/twiddle使能后PASS，不以“应该是优化”猜测放行。
- 用户C11309视频分别1.947511/2.613400秒，WAV/tone均B7000000/C7840000，tone有声且无频谱；没有D页独立版本读数，版本按上下文。完成帧0，C84仅PCM曾见/空前台曾commit，无系数非零标记；系数全0也应推进固定FFT控制，支持先定位控制进度，未证实具体硅上根因。
- 视频输入与提帧原证据在 development/player_spectrum_clock_route/build/board_feedback_spectrum。未执行JTAG、TF写入或Flash，未进行厂商protected BRAM行为仿真或实物电气测量。布局改变仍需实板检验，音画代码继承不能作为新位流实板保证。
- 下一步：用户PROGRAM_SRAM/JTAG5MHz加载DFC11310，看默认音乐和内置音阶两种频谱及音画；如仍空，各音源录至少36秒，覆盖B/C/F2/F3/F4数码管，以新状态/事件/接受采样值继续定位。无需重装TF素材。
