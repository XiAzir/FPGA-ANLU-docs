# C11303 HDMI PHY 补强候选

时间：2026-10-13 19:32:24（北京时间）。本地模型、TD、位流与封存完成，实板仍待验证；成功基线仍 C11206。C11302 的整屏规则绿/彩条与无声已记录为失败，用户同条件回载 C11206 音画恢复。

## 实际改动

隔离工程 `E:\VSCODE-project\FPGA-ANLU\development\player_music_envelope_phy`；仅两处 PHY 功能源及两个 build ID 源不同，其余 81 个 user_source 文件和三个 al_ip 源继承 C11302。包络 RTL 原 SHA 保持，PCM读取/FIFO/bridge、图片缩放、按键、PLL、引脚、SDC不改。

- hdmi_phy_wrapper 在像素下降沿一次寄存四路完整10bit TMDS字，包括三数据lane和clock；所有视频/control/audio data-island走同一捕获级。
- lane marker/toggle 改到像素下降沿，与已有25/125MHz零相位PLL的串行上升沿相隔约4ns；原pending/shift控制序列保持。
- S_oddr_data 两位在串行下降沿准备。官方 EG_LOGIC_ODDR 模型在上升沿同时采D0/D1，D1在随后下降沿发出；因此两位都提前半周期稳定。D0/D1位序和四lane一致性保持。此前历史测试stub使用不同ODDR边沿语义，不能用它证明当前PAD接口；本轮模型重新采用官方语义。

## 证据与验证

用户视频WAV/tone均48000 PCM/名义秒、无欠载，source/FIFO/HDMI-input 32768样本prefix CRC同F485，format错误0；该证据不覆盖核内部/物理发送。异常覆盖FPGA直接生成文字区域，故优先查图音共用发送链。[失败证据](../实板失败_20261013/README.md)。

本轮按官方ODDR语义复用最终生产源做相位/逐位延迟/复位/连续字序模型，四路只允许一次共同整体对齐；28组候选/5077字位置的字、位、目标捕获与独立源序列均0错，并注入D0/D1/PAD clock边界传播延迟作旧失败/新通过反例。具体范围、统计、SHA与限制见[模型凭据](E:/VSCODE-project/FPGA-ANLU/development/player_music_envelope/build/board_feedback_20261013/serializer_model/result.json)；独立实现审查见[审查报告](E:/VSCODE-project/FPGA-ANLU/development/player_music_envelope_phy/build/audit/C11303_phy_audit_20261013.md)。延迟都是模拟值，并非板上测量；模型复现机制不能唯一确认实板根因。

最终原约束 STA setup +0.119ns、hold +0.024ns、TNS0，coverage 99.98%；资源 {'LUT': 16129, 'reg': 8993, 'LE': 17699, 'BRAM9K': 29, 'DSP': 8, 'GCLK': 2}。初次路由 hold -0.025ns/HTNS -0.104ns 的DB/报告已保留build/prehold，官方fix_hold后通过。只有输入寄存的早期综合保留build/attempt_input_retime_only，无bit交付。四TMDS端口的外部output delay/板端眼图未表征，内部STA不证明真实链路电气裕量。

## 交付与复核

[交付 ZIP](E:/VSCODE-project/FPGA-ANLU/deliverables/music_envelope_phy_20261013.zip)；位流 [music_envelope_phy.bit](E:/VSCODE-project/FPGA-ANLU/download/music_envelope_phy.bit)；操作说明见工程[README](E:/VSCODE-project/FPGA-ANLU/development/player_music_envelope_phy/README.md)。

- C11303 bit SHA256 `1D0BD4198379E924EA59D8F62E940612AA3DFE0034C858C219F0ED77F6FE803F`。
- ZIP SHA256 `3F5CEC3DADECD4680111941F7F8A8E4D041BB3C5B1D6F58071CD199458CACABA`，6成员CRC与逐项字节核对通过。
- frozen checkpoint 176项 SHA/大小逐项核验通过，manifest SHA256 `D756A18AF58D9F28A1E7DF209740CFC9EE1541645B63E57F9CD9BAA168A58AAF`。
- C11302原255文件checkpoint逐项核查0差异，原ZIP SHA53457C1D...不变；C11206回退bit SHA C60464C0...不变。

解压到板卡电脑英文路径；BitWriter Add music_envelope_phy.bit，PROGRAM_SRAM /5MHz，Run，D页必须DFC11303。保持现卡/供电/HDMI/音量；先确认默认音乐、图/白字/黑底没有绿/彩条，长KEY1约2秒切内部音阶并回音乐。音画正常后再看HOLD/恢复。异常同条件回载包内bmp_scale.bit。

本轮没有代理JTAG、TF写或Flash操作。候选音画、实卡/接收端、包络观感、长期/重复启动均未验证；不标成功修复或继承旧板测。下一步等待同条件候选实板反馈，再决定是否收敛或继续抓真实发送数据。
