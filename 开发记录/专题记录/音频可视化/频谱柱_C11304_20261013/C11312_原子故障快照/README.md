# C11312 原子故障快照

时间：2026-10-15 21:15（北京时间）。状态：本地诊断候选已交付，实板待取证；C11310根因未确认，未宣称修复。

- 工程：`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_trace`，来源失败C11310。四处原HDL改动及一个新被动模块；移除观察端口及声明顺序调整后，FFT analyzer/renderer逐token对比不变。PLL/SDC/引脚及媒体控制未改，但新实现会改变物理布局。
- 本轮C11310验证：原gate完整FFT 1029实例/14BRAM/1DSP及routed依赖锥485原语，各3帧72频带定点误差0、自主重采样2次；实际gate视频源至锁定控制1440整行/921600像素，locked1。范围与日志SHA见失败工程 `build/board_feedback_no_signal_20261014/verification_20261015.json`。都未复现现场，非完整SDF/实板证明。
- 诊断触发：原因1为第四SOF时锁定且FFT已运行的参考快照；原因2为第四SOF起仍未锁定；原因3为连续4096有效样本无FFT完成；原因4为允许写入后下一拍sample/accepted增量不符。原因2/3/4冻结相邻两拍的progress/accepted和控制标志；切换音源重装。参考1可被后续故障覆盖。
- 6页显示原因、音源/HDMI/音频/帧标志及前后control；7/8为前后progress；9/A为前后accepted；B/C为捕获时帧数及恢复/切源计数。7..C第二位8表示有效。D=DFC11312。F2/F3/F4仍实时，不能当作原子快照。
- 本地模型：77快照检查；真实FFT+观察器两帧48频带定点零误差；176显示页采样；C11312完整gate/routed原厂模型均完成故障注入、冻结，并将7字全部正确传到mailbox destination。测试台强制PLL ready、快启动和accepted观察故障；不等于已复现原板故障。
- 测试夹具修正留证：FFT集成最初误期望切源后帧数累计2，原设计切源清零，改期望1后通过；全gate测试最初选到参考库旧top，改为优先work并验证加载日志；直接读取被优化裁掉的header常量位会见Z，最终改验实际显示邮箱完整7字；原ROM控制脚本硬编码旧eq14网名被eq15重命名触发，改为绑定实际端口/分析器scope和完整32态真值后通过。旧失败日志保留，均不当作硬件缺陷。
- TD：同源synthesis/physical/hold/bitstream证据绑定通过。初始hold -0.012/TNS -0.016ns已封存 `build/prehold/initial`；官方fix_hold后setup +0.060/hold +0.024ns，TNS0/coverage99.98%。16934LUT/10061reg/18481LE/44BRAM9K/12DSP/3GCLK。1536系数逐字、四ROM读控制32态逻辑及45时钟映射检查通过；原参数字符串SIG/INV不一致FAIL保留，逻辑等价证明单独绑定。
- bit SHA256：`60ae6b971ce1f9ed09d76bec14cf88dfc25cdfe7cbbebe5dd9fc070115b812ce`。封存233文件，manifest SHA `46d4ceefd0a70cdc2600157d52e7fad61e35df5fd7764be1939a4dc46ffc2abb`；ZIP SHA `ea9d90701c7946689668fb99a1c943e02fe22fc4b914a3582c860948ed7873ce`，ZIP成员与展开交付逐项核验。
- [诊断ZIP](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_trace_20261015.zip)，内含spectrum_trace.bit、C11206 bmp_scale.bit、操作说明、离线解码及哈希。旧C11206/C11309/C11310下载位流哈希核对不变。用户本轮确认板卡未连接；没有JTAG/TF/Flash操作。
- 下一步：用户在板卡所接电脑PROGRAM_SRAM/5MHz加载spectrum_trace.bit，确认DFC11312；默认模式先不按KEY1，录40秒可读数码管（6..C及D），提供路径和HDMI/声音/频谱结果。先取一段新原子数据，不要求重录旧实时页或重复既有回载。
