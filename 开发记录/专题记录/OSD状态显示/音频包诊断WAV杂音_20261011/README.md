# C11107 音频包诊断：WAV杂音，内部音阶清晰

更新：2026-10-11 17:15:55（北京时间）。用户在远控实验室电脑下载；代理只处理本地代码/视频，无JTAG/TF/Flash操作。

用户反馈：画面正常；默认天之弱可辨但杂音很重，与C11106杂音听感不同；长按KEY1后内部音阶完全正常，与osd_phy_fix相同。本次不把新候选记为全功能成功。

两视频每段约20秒，已覆盖全部10页（开始时已过自检）。原始视频/哈希及每页全帧见feedback.json和before/after目录，fps2提取仅用于目视解码，没有做物理HDMI或声学测量。

| 页 | WAV | 内部tone | 含义 |
| --- | --- | --- | --- |
| 1 | 1DA80000 | 1DA80000 | 文件/启动状态无编码故障 |
| 3 | 3300BB80 | 3B00BB80 | mode从0到1，两名义窗口输入各48000 |
| 6 | 6E00BB80 | 6E00BB80 | 包内样本各48000 |
| 7 | 7E00BB80 | 7E00BB80 | 有效音频包各48000 |
| 8 | 8E000000 | 8E000000 | 采样窗口BCH错误0 |
| 9 | 9E000000 | 9E000000 | 采样窗口TERC错误0 |
| A | AE000000 | AE000000 | 内部tone负载错误0，仅tone模式可据此判断 |
| B | BE0061A8 | BE0061A8 | CTS25000 |
| C | CE001800 | CE001800 | N6144 |
| D | DFC11107 | DFC11107 | 明确版本 |

E事件flags为island/audio/ACR已见且无粘滞格式/符号错误。计数是名义窗口快照，不是全视频累计或物理Hz。校验正确不证明WAV样本内容正确；内置音阶清晰支持当前输出路径能播放该信号，但不能排除与音乐数据有关的打包/串行物理故障。当前根因未确认。

动作：live音频包info标FAIL_WAV_AUDIO_TONE_CLEAR，构建时142文件checkpoint/ZIP保持冻结。gpt-6-luna只读核对确认WAV播放器、bridge、audio_probe与成功版同hash；未发现有证据的字节序/FIFO/CDC源码回归。

下一步正在隔离development/player_dynamic_text_pcm_crc_probe/C11108：三个边界固定同ordinal窗口的CRC16，SD组样本实际push、FIFO实际pop、HDMI核输入PCM16。三段各先跳65536事件再采32768事件，完成冻结后才比较，不用任意时间窗口对齐。另检查核输入左右相同/低8为0、记录首个被哈希样本的高byte绝对偏移与data_offset。CRC不能分辨push前每个具体层，也不覆盖WAV并行包内容/物理引脚，CRC16有碰撞，短文件参考需按循环重复。

实际本机音乐文件SHA D5244FD3935052A743379D9331EE78109C8A913241ED60DE472CB9E34A17FECF，5760044字节，data_offset44；首非零样本61477，故原首32768纯静音方案在仅综合后弃用/封存build/preflight/silent_prefix_rejected，未生成bit。选用样本65536..98303，31281个非零，Python binascii.crc_hqx独立参考F485；三段完成页预计6700F485/7700F485/8700F485，9错误97000000，A计数A7008000，B高byte位置B702002D，C文件payload偏移C700002C，版本DFC11108。本机素材并非本次远控TF文件新哈希。

当前C11108仅源码准备/局部编译通过，模型与正式重综合/物理/原约束时序/位流/封存尚未完成，不让用户下载未验证产物。TF不需改动。成功回退仍osd_phy_fix。

### 2026-10-11 17:23:48｜C11108固定音乐数据窗口诊断候选交付｜本地验证/封存完成，实板待测

- C11107实板记录完成：用户反馈显示/tone清晰、WAV严重杂音；两视频全部10页均已读，输入/包内样本48000、包数48000、BCH/TERC/内部tone负载错误0、CTS25000/N6144、DFC11107。这只证明所见结构/名义窗口，未证明WAV包内PCM或物理输出。当前成功基线仍osd_phy_fix；live C11107 info=FAIL_WAV_AUDIO_TONE_CLEAR，旧checkpoint/ZIP不覆盖。[证据](../专题记录/OSD状态显示/音频包诊断WAV杂音_20261011/README.md)。
- 新独立C11108：相对C11107只新增player_pcm_prefix_probe、top换被动观察器/显示载荷、tf_wav_file_player只加四个debug alias、status仅版本/注释；.al路径/新增源条目归一化。桥/音源/媒体控制/FAT/SD/PHY/lane/PLL/引脚/原SDC保持，源/脚本四阶段hash一致。用户音乐前61477样本静音，故首32768方案仅综合后弃用、源码/报告封存build/preflight/silent_prefix_rejected，未生成位流。正式各阶段跳65536事件、采32768再冻结；CRC16初FFFF/poly1021、低byte再高byte。source/popup/HDMI输入按同ordinal对齐，完成bus两拍+ready三拍同步；早tone abort，不连续拼接；完成后mode不改CRC。首窗口高byte文件位置131117与dataoffset44均可显示。
- 独立Python素材参考：本机TEST.WAV仍SHA D5244FD3935052A743379D9331EE78109C8A913241ED60DE472CB9E34A17FECF，样本65536..98303中31281非零、CRC F485。非本次远控TF新读取哈希。完整参考在build/model/host_music_reference.json。
- gpt-6-luna只负责只读审计及build/model；root独立重跑正式src模型：合成跨扇区头/data、异步clock、bytegaps、短payload循环三CRC0DD5；仅被动支路pop/HDMI样本一bit注入使对应CRC98A6，低8格式故障计1、早tone abort/完成后freeze都PASS。真参数CRC单元直驱本机音乐首98304向量得F485/32768；不是全真参数播放器/bridge/加密HDMI实测。页面自检/10页/DFC11108/回绕PASS。日志在build/model/pipeline_model.log、pipeline_compile.log、status_pages.log、reference_generation.log；无compile警告。
- 正式综合788f1d3e-6ee0-4720-a2dd-59a5253dc2e8，physicalc5d7dc36-74c7-4db0-a217-0ae550d9740b：route SWNS+0.633/STNS0/HWNS-0.008/HTNS-0.014ns；prehold完整报告/DB保留build/prehold/C11108。官方holddd3d4c71-ce8a-4e8d-8bbd-6b124bfaf8ba后SWNS+0.633/STNS0/HWNS+0.035/HTNS0ns，coverage99.97%；16825LUT/7995reg/18215LE/19BRAM9K/0DSP/2GCLK。外部SPI IO未表征等边界不变。
- bitgenb6f1381e-e8c1-47d6-942b-71a9f047be3f及源/脚本/DB/最终报告绑定通过：download/pcm_crc_probe.bit 629624字节/SHA F467BA1C05D27BB762E735016AFC7CF02D404B1E724D23203F56100C879749E4。[新交付ZIP](E:/VSCODE-project/FPGA-ANLU/deliverables/pcm_crc_probe_20261011.zip)679575字节/SHA 015D3751FBCBDE004778694D1B1844B9AA883231D8B69670B52D1F3B73C8DA6A，含新bit、原osd_phy_fix、README/info/素材reference/SHA；6项解压逐项哈希及download别名复核通过。134文件checkpoint冻结逐项复核，manifestSHA 191AB52A84F4E2E00E0EDB9CE6EEDAA7792720B32FC2A1C2EBF8D7E66ECCBA1C。build/package_delivery.py保留可审计打包步骤，不覆盖旧历史。
- 下一步用户在板卡所接远控电脑英文路径解压；BitWriter空闲时断电5秒/上电，PROGRAM_SRAM/5MHz下载pcm_crc_probe.bit成功；默认音乐等10秒后录数码管+四灯至少25秒，先不长按KEY1。页D=DFC11108，6/7/8正常完成预期6700F485/7700F485/8700F485，9=97000000、A=A7008000、B=B702002D、C=C700002C；第二位7表示三处完成且未提前切tone。录完再长KEY1约2秒反馈tone听感/D3闪即可，不需再录同一组冻结CRC。TF不用改，回退同包osd_phy_fix。
- C11108仍诊断候选PENDING，不称修复；CRC16可能碰撞，短窗口仅止于HDMI核输入，不覆盖WAV包内PCM/串行引脚或长期播放。若3段匹配仍有杂音，下一层需核对WAV包内PCM；若某段分歧，按边界细查，不能凭静态相同源码排除实物数据错误。全部CLI构建已结束；本机没有板卡连接，无代理JTAG/TF/Flash操作，根因仍未确认。
