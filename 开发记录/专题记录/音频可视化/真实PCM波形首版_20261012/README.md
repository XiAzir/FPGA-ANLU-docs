# T23 真实 PCM 波形首版 C11202

2026-10-12 10:59:17（北京时间），本地实现/模型/代码审查/正式构建/封存/交付完成，实板待验证。

用户“好。开始”授权开发。继承 C11201 verified 133 文件并逐项 SHA 校验，新增 player_pcm_waveform，top 插入零延迟叠加链、状态 BUILD_ID 改 C11202；80 个继承源码不变，音频 FIFO/FAT/SDRAM/PHY/PLL/原 SDC/控制无修改。成功基线仍 download/image_adjust.bit。未本机 JTAG/TF/Flash 操作。

只观察送往 HDMI 的 audio_valid/audio_left_data，PCM16 取 signed [23:8]，128 bin×8 样本极值窗口，名义 48kHz 下 21.333ms；双 bank 完整窗 VS 提交，音源变化或 100ms 无样本请求下个 VS 清旧图。等待 VS 时只丢观察事件，播放无反压。图形 X4、超出 ±28 像素截顶；底部黑面板青色波形，PCM WAV/TONE 标题。保留原状态、调节/RUN/滚动/音画，TF 不改。

单元模型根代理重跑 303 检查/1024事件，含边界与换源/超时/VS 同沿。独立 gpt-6-luna 集成只读复核无必改。两帧 768000周期、58368波形像素与真实音乐独立参考一致，原区域外叠加/调节/blanking保持；模型范围及素材哈希/选窗方法见工程 build/model/integration_review.md 和 music_reference.json。本地模型不包含加密核/完整实际卡读取/板级 PHY。

TD6.2.178840 正式 synthesis/physical/bitstream wrapper 绑定源/脚本/DB/报告/bit 哈希，通过后复核当前绑定。SWNS +0.660ns / HWNS +0.003ns、STNS/HTNS0、coverage99.97%；13097LUT/8221reg/14688LE/24BRAM9K/0DSP/2GCLK。未执行 fix_hold/改约束。波形实体一块 PDPW8K，256×14 常量位优化为256×12；播放 FIFO 仍四块 DP8K。映射摘录留档，保留原警告/未约束边界，不用 STA 代替板测。

位流 download/pcm_waveform.bit（629624字节），SHA D753D6893AA6C1EB98323C189FC7889A7FBCB96D3C12ECA5966AF515AE397D49。ZIP deliverables/pcm_waveform_20261012.zip 内含候选、成功回退 image_adjust.bit、校验/操作说明；逐项 ZIP 哈希通过。冻结 133 文件 checkpoint，manifest C5B58E2F7FE26E8E88638F62E0FCD888ECE7BBB73C667DECFFE567BE07519E72，ZIP SHA EA0C3899B22DA7DABF829F564C9B02BDF936849267223F0C5553907AA496DA73；详见 delivery_receipt.json。C11201 verified manifest 与原 ZIP 重新复核保持不变。

下一步用户远控实验室电脑，用 PROGRAM_SRAM / 5MHz 下载，检查音乐 WAV 波形、PLAY 长 KEY1 的清晰音阶/TONE 波形、切图/自动/原字幕/B/C/恢复以及音画。全部通过前保持 PENDING，不称 T23 实板完成；异常同条件回载包内 image_adjust.bit。无需重复全部数码管视频。长期/冷启动/碎片文件实板验证仍待后续，未承接父版本短稳结果。


## 2026-10-12 11:09:06｜波形板测反馈与显示解释

用户反馈音乐波形/弱静音平线/音阶方波正常，记波形相关部分通过；音阶模块实际生成方波，因此不是误画正弦。用户提出同x多y、低分辨率锯齿：源码每8样本min/max竖条复制4像素、128组/512px、纵向57档，可解释区间画法及粗糙阶梯；没有新图/视频，未直接证实是否有另一个独立残影。按名义连续48kHz/25MHz/800×525时序推导约29.76次波形更新每秒，非实测；刷新率影响动态流畅，不是min/max竖条的根因。

原功能回归及两音源音质尚未逐项明确反馈，live info标PARTIAL_PASS_REPORTED_WAVEFORM，成功基线仍C11201，未创建verified/改RTL/重构建。原133文件candidate和ZIP原SHA重新核验保持。优化候选为更多横向bin、折线/插值、纵向高度/增益、音阶触发对齐、更短窗或滚动捕获；均尚未实施，可在480p优化。下一步补齐上一条圈出的回归，完整通过后封存T23并推进T24/T25操作卡与集成验收，再T26/T27一种连续转场。详细反馈见board_feedback.json。


## 2026-10-12 11:14:45｜新增照片与肉眼重影反馈：修正前一解释

用户提供三张原始照片，已按字节归档于波形重影照片/，SHA见photo_findings.json。第二张存在中间有黑色间隔的两条独立青色轨迹，第三张可见亮轨迹旁的暗轨迹。用户进一步明确“肉眼也明显有”，因此不能只归因于手机跨帧曝光；上一条min/max区间解释适用于粗线/阶梯，不足以解释分离完整曲线。

RTL bar_pixel为连续上下界区间，未主动保留/叠加旧曲线，display_bank只在VS变化；源码和模型意图不能替代实体链路。新旧波形的显示时间响应/视觉残留或实际换帧读链路均为未证实假设，尚无单帧直接捕获。低空间分辨率和约30Hz推算可解释粗糙/更新感，不能直接当作此重影的已证根因。

live info改WAVEFORM_GHOSTING_REPORTED_PENDING_DIAGNOSIS；音乐关联/静音及音阶形状反馈保留，T23不得整体标通过，成功基线仍C11201。下一步建议独立冻结front一完整窗且音乐照播的诊断；静态保留重影则查静态绘制/读取，静态干净则再分辨动态换帧与显示残留。该诊断尚未开发/构建/上板，也不能单凭冻结消失唯一证明显示器原因。原功能回归待补，不因照片认为音质/按键已通过。没有改RTL/重构建/JTAG/TF/Flash；candidate/ZIP冻结未修改。


## 2026-10-12 11:27:44｜C11203冻结front诊断交付，实板待验证

独立player_pcm_waveform_freeze，继承C11202冻结133文件逐项SHA核验；80源不变，仅wave冻结/HOLD字形及top/状态BUILD_ID改变。144000同音源有效事件后VS完整窗冻结，冻结两bank不可写且stale不清图，音乐照播、换源/复位重装；同沿threshold/VS使用旧request可延后一个完整窗。WAV头已避开，本地3秒窗口非零（RMS490），实际freeze窗起点随VS变化。

unit303/两帧真实音乐集成及专用冻结模型根代理重跑/独立luna只读审查通过，生产144000计数采用密集事件不计真实48k时序实测。专用范围/像素连通/字形及边沿条件见新工程build/model/freeze_review.md。TD三阶段源/脚本/DB/报告/bit绑定通过，原约束{"SWNSns": 0.304, "STNSns": 0.0, "HWNSns": 0.019, "HTNSns": 0.0}，coverage99.97%，资源{"LUT": 13342, "reg": 8231, "LE": 14990, "BRAM9K": 24, "DSP": 0, "GCLK": 2}，holdFix=False；一wave PDPW8K和四PCM DP8K。

候选download/waveform_freeze.bit SHA 2761C212E7F59C52846003F026AEB0286DFC45E2AD3FA3085D89268938C5E88F；ZIP E:\VSCODE-project\FPGA-ANLU\deliverables\waveform_freeze_20261012.zip SHA 9366E59195283150863B23EEFB91DD304E9F5E3174F38EBE9C06DAABAA96BB8F，含原动态C11202和成功回退C11201；143文件checkpoint，manifest FB9BE10F216026114DB434CEDFAC99545054CF871B1B5BC6C6F8212AC951861B，逐条/ZIP哈希通过。旧候选/ZIP未改。未上板/未本机JTAG/TF/Flash，不称修复或新成功基线。

下一步用户PROGRAM_SRAM /5MHz下载、观察HOLD WAV和HOLD TONE各稳定5秒后的单/双线、是否仍移动及两音源清晰连续。灰线不算第二轨迹。静态干净不唯一证明显示器，物理实现变化也需计入证据；失败音画同条件回载image_adjust。


## 2026-10-12 11:48:39｜C11204按键冻结诊断交付，实板待验证

2026-10-12 11:48:39 C11204按键冻结诊断本地完成、实板待验证。PLAY双键短按松开冻结/恢复当前front，VS提交；取消自动三秒冻结，长双键复B/C默认、长KEY1换源解除冻结。模型unit303、control38+chord11、wave819及动态/冻结真实音乐全512列两帧通过，根代理重跑；TD三阶段/原约束时序 {'SWNSns': 0.66, 'STNSns': 0.0, 'HWNSns': 0.003, 'HTNSns': 0.0}，coverage99.97%，holdFix=False，源/脚本/DB/报告/bit绑定与ZIP校验通过。download/waveform_keyfreeze.bit SHA A16326B8266ED6CB52CE27E163B89DC1C2B37551B393AE5F1116BA16C6F54790。ZIP E:\VSCODE-project\FPGA-ANLU\deliverables\waveform_keyfreeze_20261012.zip / 866673bytes / SHA 4A297394A026851C2D6C74F03602D950C679DD3FAD6C2B43E194827108FA3C5D，154文件checkpoint manifest 3F1C818A7B23D509BEE072430A20F65BA8F7E70548541D79B28E6AFB2CB7A420。父143文件/ZIP不改，成功基线C11201，非重影修复。未JTAG/TF/Flash。

79源不变，改变wave手动请求/VS保持与controls短组合脉冲和topwire/BUILD_ID、状态BUILD_ID；音频/FIFO/FAT/SDRAM/PHY/PLL/约束不改，实际重布局。波形1PDPW8K、PCM4DP8K。专项wave用缩放SAMPLES1/stale，另默认144000密集事件无自动冻结；真实音乐集成用SAMPLES8/520-521间隔1024输入、两帧全图冻结保持与其它OSD/亮度/滚动像素核验，冻结后密集极值pressure不是实板48k测量。

下一步用户下载waveform_keyfreeze.bit，出现重影时PLAY双短冻结看HOLD等5秒、再双短恢复，并长KEY1换tone后同样冻结/恢复；反馈单双线/是否静止/两源音质。音画异常同条件image_adjust回退。静态干净不能唯一证明显示器，根因仍待确认。详见新工程build/delivery/README.md及build/model两份review。


## 2026-10-12 12:11:31｜按键冻结同位流动态/静态对照反馈

2026-10-12 12:11:31 C11204用户确认同一按键冻结版“动态时有双线，HOLD后消失”。这是动态/HOLD对照的用户反馈，支持时间叠影或动态更新相关因素，静态固定双轨迹假设降优先；屏幕响应/处理与视觉暂留是候选，尚不能唯一归因屏幕硬件或完全排除动态读/换bank链路。live info标PARTIAL_PASS_REPORTED_STATIC_TRACE_DYNAMIC_GHOSTING，成功基线仍C11201。无新增照片/视频/实测像素流，WAV/TONE分别、音质和原功能未逐项反馈。源码/位流不改，154文件候选/ZIP逐项哈希保持；未JTAG/TF/Flash。

静态停止刷新时消影、动态恢复有双线，符合动态因素。EIZO官方解释LCD响应慢可造成运动模糊/拖影（https://www.eizo.com/library/basics/response_time_figures/），仅为机制参考，不能代替此显示器测量。当前可避免继续盲改静态绘制或升级分辨率来“修复双线”；保留冻结作为诊断/查看功能。后续有现成另一显示器时，同一bit同接线/设置对照更能判断屏幕相关性，非本轮必须操作。主线继续前新候选原功能/两音源仍需明确反馈，不升级成功基线。
