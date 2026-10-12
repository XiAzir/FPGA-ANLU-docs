# C11106 实板音频失败与下一轮取证

### 2026-10-11 16:46:59｜C11106实板反馈与C11107音频包取证准备｜反馈核对完成，构建进行中

- 用户反馈C11106画面正常、默认天之弱炸音/大量杂音、长按KEY1后仅沙沙底噪无音阶，两模式四灯全灭。保持卡/供电/HDMI/音量回载osd_phy_fix后两音源恢复清晰（用户反馈）；故C11106记BOARD_FAIL_AUDIO，当前成功基线不变。
- root已读取两视频完整页：before 1DA80000、3300BB80、CFC11106；after 1DA80000、3B00BB80、CFC11106。音阶mode位确实由0到1，两窗口audio_valid数均48000，无额外bit17；灯全灭与本探针定义相容。不能把这次判成按键没切换，不能把计数正确等同PCM/包/引脚正常。6..B仍为不可用占位。
- 两段视频原始副本/哈希与关键帧归档到[本轮实板证据](feedback.json)；源码/位流/原136文件checkpoint与ZIP保留未覆盖，live info另记FAIL_AUDIO。
- gpt-6-luna只读核查：音频源/mux/ACR、加密发射核、PHY/lane和实际25/125MHz PLL及SDC与成功版相关文件同哈希；top的probe选源门控和FAT mapper收宽有差异，当前mode已证切换。HDMI并行包内容及物理输出仍未知，旧官方ODDR模型通过不能替代板上波形。未确认唯一根因。
- 新隔离development/player_dynamic_text_audio_packet_probe/C11107：只改top恢复原audio-probe LED和同源hdmi_packet_monitor被动实例，status只增D页DFC11107、10页轮转；其余媒体/动态字幕/FAT/PHY/lane/PLL/原SDC不改。.al Project Path改为新目录是工程元数据差异。CTS/N接线为20位到原24位显示输入、零扩展；页6样本数、7包数、8BCH、9TERC、A内部音阶负载错误、B CTS、C真实N、D版本。LED恢复WAV四事件/tone D3闪语义。
- 页面模型13项及回绕PASS；原功能包模型用本候选monitor重跑47断言/0失败，反射BCH向量重建通过。均不包含加密核/物理输出。第一次综合TD归一化.al触发源码哈希保护、脚本哈希不变，拒绝认证，证据封存build/preflight/synthesis_project_normalization；冻结归一化输入后重综合进行中，尚无新bit或上板。
- 下一步：新候选综合/物理/原约束最终setup-hold、bit和封存全部通过才交付；用户无需改TF或重录旧视频。本机未连接板卡，无代理JTAG/TF/Flash操作。

### 2026-10-11 16:53:31｜C11107音频包诊断候选交付｜本地验证完成、实板待验证

- C11106证据已核对/归档：模式从3300BB80变3B00BB80、均48000，额外bit17未复现；用户同条件回退osd_phy_fix两音源清晰。当前音频故障位置与唯一根因仍未确认；没有新增板卡操作。
- C11107综合runId753b69d8-091e-4037-9a1d-e2c5fe4495dd，physical5b818aef-d0e7-4662-876f-0e0eda1c2e89；route SWNS+0.225/STNS0/HWNS-0.008/HTNS-0.018ns，prehold封存build/prehold/C11107。官方fix_hold a42b581a-e9b4-4415-a405-9207bb749902后SWNS+0.225/STNS0/HWNS+0.027/HTNS0ns，coverage99.97%，17190LUT/8017reg/18523LE/19BRAM9K/0DSP/2GCLK。原SDC/PLL/媒体/PHY/lane源码未改，SPI外部IO仍未表征。
- bitgen runId9f469327-5222-41bb-b6a3-3911e78fcc53与源/脚本/DB/最终报告绑定通过；download/audio_packet_probe.bit629624字节，SHA256 F60D473DA14C2EC813B80534CDE228E8B05B1E630AD81664E35B9B456B32224D。状态AUDIO_PACKET_DIAGNOSTIC_CANDIDATE/PENDING，未上板、不称修复版。
- 缩放页面模型自检/10页/回绕通过；正式monitor47断言0失败、反射BCH向量与32字重建通过。新观察器只是发射核并行TMDS支路，采样video_clk，不能证明串行器/HDMI引脚/接收端正常。模型不包含加密核或实物。原始源码差异与主代理核对在工程README，.al的Project Path是必要工程元数据差异。
- 封存development/player_dynamic_text_audio_packet_probe/checkpoints/audio_packet_probe_20261011_candidate，142文件逐项SHA复核，manifest SHA FC288ACE94B1698D2AAFDD283BB10C6E4884B1F3569CCB2ED2EF81EF88F7D101。
- [交付ZIP](E:/VSCODE-project/FPGA-ANLU/deliverables/audio_packet_probe_20261011.zip)674243字节/SHA256 9B6AC8778E8B851ACD90A13D70F90B688DA49BF450DAAFC128DE74932F812212；含新bit、原osd_phy_fix、README/info/SHA。解压逐项与download别名哈希一致；原成功回退位流hash9E893B...保持，C11106旧ZIP/checkpoint保留。live C11106 info标FAIL_AUDIO，不覆盖冻结历史。
- 下一步用户在板卡所接远控电脑：英文路径解压；下载空闲后冷断电5秒/重上电，PROGRAM_SRAM/5MHz下载audio_packet_probe.bit成功；默认WAV等10秒录25秒，长按板KEY1约2秒后松开等3秒、再录25秒，同时拍LED和数码管。D页应DFC11107，C页是真实ACR N；本版D3恢复音阶闪烁，默认LED恢复原音频事件语义。记录画面/两音源听感及灯态后可回退同包osd_phy_fix。TF无需改动，无需ChipWatcher/CWC。
- 本轮命令行构建全部结束。根因尚未确认；本机无板卡连接，没有代理下载/JTAG扫描/TF或Flash写入，远控下载由用户完成。

