# C11301 波形清晰度优化

基线：[C11206五扩展总表](../../整机集成/C11206五扩展验收_20261012/README.md)。用户2026-10-13授权“下一步开始”，按后续清单推进可选质量优化。

## 目标与证据

原128组×4横向像素改512列×1像素，各列保留2样本极值，1024样本窗口与增益保持。幅值使用四分之一像素定位、四档青色边缘、相邻中点连通。输出仍640×480、图形仍57物理行；不宣称屏幕分辨率增加。冻结/换源/字幕/参数/缩放/转场保留；动态双线按既有已知项记录。

隔离工程：[player_waveform_fine](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/README.md)。[规格与预算](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/build/waveform_spec.md)、[父268项核验](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/build/parent_receipt.json)、[独立gold报告](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/build/model/wave_fine_report.txt)、[冻结回归](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/build/model/keyfreeze_wave.log)、[整机叠加模型](E:/VSCODE-project/FPGA-ANLU/development/player_waveform_fine/build/model/integration.log)。旧继承但未运行的模型不计本轮通过。

## 阶段记录

2026-10-13 16:09:45：C11301隔离开发已开始：C11206 verified268逐项SHA通过后复制有效源码与构建入口，未复制旧TD数据库。512列×2样本保持1024样本窗口，Q2幅值/四档边缘与相邻连通，物理波形仍57行。独立gold30229检查/29184图形像素通过；继承冻结回归3123检查和144000密集音频事件通过；真实音乐/参数/字幕/空白两帧叠加768000周期、58368图形像素通过。正式TD综合成功，波形为两个同步BRAM9K（1024×16裁零位），PCM缓冲四BRAM保留，整机29BRAM9K/14621LUT/8677reg。布局布线进行中，最终时序/位流/封存/实板未完成，成功基线仍C11206；动态双线原因未证实，未做硬件操作。

下一步完成原约束setup/hold检查、生成新候选、封存并交付用户相关板测。清晰度、音质、实际显示均待用户反馈；模型和STA不能替代板测。

## 本地交付（实板待验证）

2026-10-13 16:13:29：C11301本地候选已封存、实板待验证。512列/Q2边缘/连通，窗口1024样本与物理57行/增益保持；独立gold30229项（29184图形像素）、冻结3123项/144000密集音频事件、音乐与参数字幕两帧768000周期/58368图形像素通过，静态审查完成。原约束setup+0.615ns/hold+0.019ns/TNS0、coverage99.97%；资源{'LUT': 14910, 'reg': 8791, 'LE': 16379, 'BRAM9K': 29, 'DSP': 8, 'GCLK': 2}。波形BRAM2/PCM4，85源字节不变、3源变化（waveform及top/status版本ID），无新源。位流SHA30C45D0A9B82B9C4F78C5A14A81CEFA13C704AF9C91C34EB4C625974FDAA4B96；ZIPwaveform_fine_20261013.zip SHAAB54BB8B8501787EA557E6FFED6934C0C5D3784A95D5CAE0D49DEA19BD48C2C2；candidate175项manifestSHAF6F5DA1F9228DF3231EB46CC0113E81894D3E99B412C528F3684BBED8F0EA0EE。C11206 verified268/candidate260/ZIP/回退bit逐项不变。动态双线仍已知、物理清晰度/音质/真实卡/长期未验证；未代理JTAG/TF/Flash。

下载：[候选与C11206回退压缩包](E:/VSCODE-project/FPGA-ANLU/deliverables/waveform_fine_20261013.zip)。下一步用户按[操作卡](操作卡.md)在实验室电脑下载，TF素材无需变更，确认音画/冻结/清晰度及相关五扩展功能。所有历史模型/构建阶段记录保持时间边界。

## 统计口径更正

2026-10-13 16:14:53：交付复核中更正live工程README资源口径：14621LUT/8677reg属于综合阶段，最终物理为14910LUT/8791reg（29BRAM9K/8DSP）。原info/phy.area及资料交付记录已正确。冻结candidate175原README保留初版统计误标，正式值以其info/phy.area为准，源/bit/ZIP/清单未更改。

2026-10-13 16:15:36：独立交付只读复核通过，175项manifest逐项SHA/字节数及ZIP五成员对live delivery一致；候选/回退位流匹配，板测pending标记一致。见[复核凭据](独立交付复核.json)。


### 2026-10-13 16:23:49｜用户视觉反馈与下一版方向

- 用户反馈C11301“确实好很多”，但波形运动过快、不够优雅，提出转向美学价值。仅记视觉改善与体验不足，不扩写为两音源/整机/冻结/长期全部通过，成功基线仍C11206。
- 源码核对：512列×2样本共1024样本，48kHz名义窗口约21.33ms；完整back在VS交换，新音频窗替换front。线条清晰度改善未改变时间运动逻辑。此为源码推导，不是实测刷新率，也未确定动态双线原因。
- 建议下一版改为音乐能量包络显示：更长的可见历史、缓起缓落/时间平滑、细线与克制亮度过渡，让静音趋近平线、强弱起伏可见。具体时常需视觉调参，不把振幅包络标为FFT频谱；现有PCM版本留作对照。
- 当前只讨论方向，尚未修改RTL、编译或操作硬件。待用户认可后，在隔离候选中实现并做相关验证。详见[原反馈](清晰度与美学方向反馈.json)。
