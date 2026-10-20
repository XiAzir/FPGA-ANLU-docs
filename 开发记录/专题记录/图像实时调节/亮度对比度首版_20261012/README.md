# T22 亮度/对比度首版 C11201

2026-10-12 10:22:04（北京时间），完成本地实现/模型/构建/封存/交付；上板待验证。

用户针对C11109的30分钟WAV/AUTO、手动切图及RUN/滚动回复“没问题”，记用户现场短稳反馈通过；未升级为长稳/冷启动回归。

工程：../../../../../FPGA-ANLU/development/player_image_adjust。继承成功141文件verified快照并全哈希复核，原音频FIFO/FAT/SDRAM/HDMI/PHY/SDC不改；新增控制/RGB定点饱和/参数栏三模块，top连接及状态BUILD_ID变化。产品双键手势替代旧组合视频probe，不再触发隐藏测试图。PLAY短动作释放生效、长KEY1只切音源，编辑模式音乐/轮播继续。

工程：E:/VSCODE-project/FPGA-ANLU/development/player_image_adjust。继承成功141文件verified快照并全哈希复核，原音频FIFO/FAT/SDRAM/HDMI/PHY/SDC不改；新增控制/RGB定点饱和/参数栏三模块，top连接及状态BUILD_ID变化。产品双键手势替代旧组合视频probe，不再触发隐藏测试图。PLAY短动作释放生效、长KEY1只切音源，编辑模式音乐/轮播继续。

B±64/步16，C0.50..1.50/五档。clip(floor((p-128)*C)+128+B)，默认恒等；参数VS提交/模式文字帧锁，底图调节、文字独立保持原色。

模型11524RGBvectors；缩放控制+生产25MHz参数断言+真实legacy debounce集成；三帧1152000周期和24576参数栏比较。根代理复核/重跑，修正生产整数溢出、多process pending驱动、同步初值、组合优先及legacy脉冲高间隔；独立gpt-6-luna只读集成复核无新增必改。范围见工程build/model/README.md，未模拟加密核/实际PHY。

TD正式三阶段输入/脚本/数据库/报告哈希绑定。SWNS+0.576/HWNS+0.011ns，TNS0、coverage99.96%；12944LUT/8151reg/14388LE/23BRAM9K/0DSP/2GCLK；无需fix_hold，未放宽原约束。真实PCM FIFO仍四块2048×4 BRAM；保留原IP/IO/CDC警告边界，不把STA代替实板。

候选download/image_adjust.bit，SHA256 5482E8E2D2AE912E47D9EA21F93892559F39AF77C907D025EBDA46AE9994C2FA; ZIP deliverables/image_adjust_20261012.zip逐项解包哈希通过；冻结检查点 E:\VSCODE-project\FPGA-ANLU\development\player_image_adjust\checkpoints\image_adjust_20261012_candidate，共131文件，详见delivery_receipt.json。成功基线仍C11109 SHA A5F2C25BA1F65B05051419093BC78EC2DD05E510502D914450DD77673CB7E0C0；ZIP含此直接回退。未本机JTAG/写TF/Flash，旧位流/ZIP/检查点保持。

下一步用户用PROGRAM_SRAM上板验证默认显示/音乐/按键/字幕、亮度和对比度五档效果/饱和/数值同步、双键恢复以及两音源。仅全部通过后记T22实板验收，随后T23真实PCM波形；无需改卡/重录旧页。

## 实板反馈更新：2026-10-12 10:37:00

用户针对上轮验收步骤回复：“每个功能都测试过了，完全正常，画面显示正常，音频播放正常。” 记录为全部所列T22功能、显示/音频用户反馈通过；代理未直接上板，未新增视频/CRC/时长证据。C11201 image_adjust.bit（SHA 5482E8E2D2AE912E47D9EA21F93892559F39AF77C907D025EBDA46AE9994C2FA）成为当前成功开发基线，C11109/osd_phy_fix保留回退。

本轮无RTL改动或重新构建，live info更新PASS_REPORTED_T22_FUNCTIONS；新133文件verified快照 E:\VSCODE-project\FPGA-ANLU\development\player_image_adjust\checkpoints\image_adjust_20261012_verified，manifest SHA 52E1D0B64D95D71BDF6C2568E74A0B25CB9BC6C245E21F208C650421DC595DA4。旧131文件candidate/ZIP保持PENDING历史，不覆盖；反馈见board_feedback.json，工程receipt在build/board_feedback_20261012。

下一步T23实际送HDMI的PCM波形可视化，尚未实现。C11201长稳/多次冷启动/碎片/换文件实物回归仍未验证；不套用C11109的30分钟结果。本机未连接JTAG/写卡/Flash。
