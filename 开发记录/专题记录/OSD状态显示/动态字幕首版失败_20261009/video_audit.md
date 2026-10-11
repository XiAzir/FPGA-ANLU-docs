# 新视频数码管抽帧复核

复核对象：`board_video/frame_01..30.jpg`（来自 30.046211 s、1280×720 视频）。以下只解读题定帧中数码管数值及源码标签，不从视频推断画面/音频内容。

| 帧 | 可见 8 位码 | 页标签与数值 | 读数 |
|---:|---|---|---|
| 07 | `8D006615` | `8` BCH 错包计数，flags=`D`，值 `0x006615` | 26,133 |
| 09 | `9D000056` | `9` TERC 错符号计数，flags=`D`，值 `0x000056` | 86 |
| 11 | `AD000000` | `A` tone payload 错计数，flags=`D`，值 `0` |
| 18 | `3B00BB80` | `3` 像素域状态 mailbox；高 nibble `B`，样本计数 `0x00BB80` | 48,000；mailbox flags `1011`：tone_mode=1、underflow=0、hdmi_locked=1、frame_seen=1 |
| 22 | `7D006603` | `7` 音频包计数，flags=`D`，值 `0x006603` | 26,115 |
| 24 | `8D0066ED` | `8` BCH 错包计数，flags=`D`，值 `0x0066ED` | 26,349 |
| 26 | `9D000057` | `9` TERC 错符号计数，flags=`D`，值 `0x000057` | 87 |

标签来自 `player_status_monitor.v`：页7/8/9/A依次显示packet_count/bad_bch/bad_terc/tone_bad；页3为pixel域mailbox中的状态与音频样本计数。注意帧18的`D`是mailbox状态位，帧7/9等的`D`是`hdmi_packet_monitor.probe_flags`，含义不同。packet flags `D=1101` 表示 observed island、audio packet、format/symbol error置位，ACR good未置位（与现场说明吻合）。

抽帧独立确认：BCH错误计数约26.1k/26.3k，TERC错符号数86/87，audio packet计数约26.1k；tone_bad为0。mailbox样本计数48,000，且捕获时 underflow=0、hdmi_locked=1、frame_seen=1。该状态与“monitor看到活动和错误”一致，但这些值本身不证明板外听感或视频输出质量。

证据边界：`hdmi_packet_monitor.v`在 dynamic_text 与成功 baseline 中 SHA256相同（`E0755EEF660DF07B56C576E6A07565B9189C50E68112F885CD2A08831B38024B`），顶层实例位于 HDMI core 并行 ch0/ch1/ch2 数据、进入 PHY 之前。计数器/flags可证明监视器输入和其判定逻辑观察到这些事件；不能唯一归因为 core 错误、也不能称问题仅在 PHY，因为监视器虽在 PHY 前取样，其输入仍由 core 和 control产生，而整条core/PHY/时钟链共同影响实板观测。baseline 先前“正常”仅为历史板测背景，不是本视频内的对照波形。此视频没有拍到显示器画面；OSD消失、音乐停止仅依据用户反馈，本审计未听音频、未直接操作板卡。

## 复核更正（frame18/frame24）

初版曾将 frame18 读作 `3D006680`，并据此写成 samples=26,240、underflow=1、hdmi_locked=0。经重新查看原帧并对照 `status_hex595.v` 的 B/D 七段字形，第二位是小写 `b` 字形，不是 `d`；右侧低24位为 `00BB80`，故应为 **`3B00BB80`**。相应 mailbox 位为 `B=1011`：tone_mode=1、underflow=0、hdmi_locked=1、frame_seen=1；0xBB80=48,000。表格与结论已同步更正，初版读数仅保留在本更正记录中，不再作为证据。

Frame24 重看为 **`8D0066ED`**：标签后 flags 位是小写 `d` 字形，右侧 `66ED` 与 counter 数字相符；没有发现需修改初版读数。Frame24 的 `D` 是 HDMI packet monitor flags；frame18 的 `B` 是 pixel mailbox flags，两者位定义不同。该次更正不改变报告对监视器位置、core/PHY归因边界或未听音频的说明。
