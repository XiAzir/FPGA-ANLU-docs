## 2026-10-13 21:33:46 实板失败修正

用户反馈默认UI清楚但IMG0/0、无BMP/音乐、LED全灭；长KEY1后无背光/无信号，D3闪其他灯常亮。两视频已抽帧：DFC11305，1D97000A对应mount ready/无FS错误、BMP/WAV与两mapper错误/WAV mapper超时0A；默认33000000有效PCM0，tone后3B00BB80有效PCM48000/名义秒且内部lock/frame有效。prefix flag8/count0是切tone前capture未完成的early abort，不能当tone输入缺失。唯一根因未确认，源码相同不证明新物理实现正常；C11305 live标FAILED，旧bit/ZIP/221冻结保持。

下一步C11306恢复global eram_init off，显式局部ROM初始化频谱系数并逐字验证；实现/编译/实板尚未完成。工程证据build/board_failure_20261013。原本地通过范围见历史下文。

# C11305恢复基线HDMI发送电路

更新：2026-10-13 21:21:47（北京时间）。本地候选交付完成，实板PENDING；成功基线仍为C11206。

## 失败与改动

用户报告C11304 KEY1前后黑屏无信号；后视频DFC11304确认版本，源/输入前缀CRC F485、flag7，无格式错误；名义秒48000 PCM及核内部锁定/帧事件不证明HDMI引脚正确。用户本次同供电/HDMI回载C11206后音画正常。原C11304模型/STA仅在本地范围有效，live标FAILED，旧bit/ZIP/325文件快照保留。

独立工程`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_baseline_phy`，相对C11304仅4份user_source改变：hdmi_phy_warpper.v和lane_lvds_10_1.v逐字恢复成功C11206；top/status两处ID改C11305。FFT/渲染/其余源码和IP/引脚/SDC不改。eram_init保持on，影响HDMI FIFO这一变量未排除。未发现能证明C11303边沿语义错误的静态证据；新布局亦不同，唯一实物根因未确认。[审计](黑屏审计.md)。

## 本地验证

频谱gold回归：312合成频段/48真实音乐频段/72集成频段bit-exact，650像素通过；HOLD/恢复/切源/reset/100ms stale通过，29输入SHA核对。27组串行器普通数字延迟矩阵通过；此模型不含glbl全局配置复位、真实电气/接收器裕量，不证明实板。[模型](模型结果.json)。

TD6.2.178840 syn/physical/nativehold/bitgen成功，全部stage证据链接一致。最终setup+0.308ns/hold+0.030ns/TNS0、coverage99.97%；16409LUT/9811reg/17914LE/44BRAM9K/11DSP/2GCLK。hold前+0.308/+0.003报告/DB在build/prehold保留。gate1536系数INIT零差异。首轮错误路径替换导致blackbox的失败log保留build/rejected_path_replacement.log，修正工程注册/runner路径后完整重编译，没有从失败轮发布位流。

ZIP 6成员/5校验行、221冻结文件、29模型输入以及旧C11304 325冻结文件独立核验通过；原C11206/C11303/C11304 bit和旧ZIP哈希保持。未操作JTAG/TF/Flash。SOURCE恢复不等于旧路由恢复；实际接收器信号眼图/冷启动/长期未验证。

## 交付与下一步

[测试包](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_baseline_phy_20261013.zip)，[操作卡](操作卡.md)。加载spectrum_baseline_phy.bit，PROGRAM_SRAM/5MHz，D页DFC11305。先确认默认音画，再长KEY1内部音阶；异常包内bmp_scale.bit回退。候选尚未通过实板，不升为成功版。

bit SHA256：`768B510C951E5A12EE6F062CDFE053885D1DB6A4B9DDBFFE63944E96A082DE1F`；ZIP SHA256：`DFA9B4306712D261CD8D2BD9FEF41063E98629D10EA0E6D648DAEFBBDA5428D0`；manifest SHA256：`A69757029272521540B5A1AB05A0EEF70D6973DF26258B80F20D2137A10940C5`。[交付凭据](交付凭据.json)、[独立核验](独立交付校验.json)。

若仍无信号，另建候选恢复eram_init off并以独立验证方法保持频谱系数初始化，或固定源隔离；这些下一分支尚未执行。
