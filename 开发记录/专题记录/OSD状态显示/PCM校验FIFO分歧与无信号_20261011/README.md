# C11108实板：FIFO前后CRC分歧，HDMI无信号

更新：2026-10-11 17:42:52（北京时间）。本轮代理只读视频/操作本地文件；板卡在远控实验室电脑。

用户反馈pcm_crc_probe直接无信号；保持卡/供电/HDMI回载同包osd_phy_fix，图片/默认WAV/长按内部tone三项均恢复正常。C11108记FAIL_NO_SIGNAL_CRC_DIVERGENCE，不是成功候选。原134文件checkpoint/ZIP保留构建时PENDING历史，live info已记失败。

两视频19.633389/19.331556秒，均覆盖完整10页，原始视频与全帧关键页/哈希见feedback.json、before/after。数码管采用fps2提取目视解码，不是物理HDMI取样。

| 页 | KEY1前 | KEY1后 | 判读 |
| --- | --- | --- | --- |
| 1 | 1DA80000 | 1DA80000 | 文件/启动未见编码错误 |
| 3 | 3300BB80 | 3B00BB80 | 切tone成功；所见窗口48000/underflow0 |
| 6 | 6700F485 | 6700F485 | 实际push CRC等于本机素材F485 |
| 7 | 7700D2D6 | 7700D2D6 | FIFO pop CRC与push分歧 |
| 8 | 8700D2D6 | 8700D2D6 | HDMI核输入与FIFO pop一致 |
| 9 | 97000000 | 97000000 | 捕获窗口左右/低8格式错误0 |
| A | A7008000 | A7008000 | 捕获32768样本 |
| B | B702002D | B702002D | 窗口首样本高byte位置131117正确 |
| C | C700002C | C700002C | data_offset44正确 |
| D | DFC11108 | DFC11108 | 确认候选版本 |

7 flags表示三段采集完成、未早tone abort。KEY1后CRC为此前WAV冻结结果，不能称tone内容CRC；locked位不能证明显示器锁定。源CRC/位置正确、pop与核输入共同D2D6，为优先排查FIFO读取/头预取/消费边界提供首次明确数据差异；仍需排除探针/显示数据错误和序号错位，CRC16有碰撞。不能凭音频CRC说明无信号的唯一原因，也不能称SD整文件或长期场景已验收。

本机素材101项有限错误指纹（固定bit置0/置1/翻转、字节交换、±16样本平移、重复/抽取、位移音量）均未得到D2D6，详见crc_fingerprints.json。不是穷举，不能排除其他动态错误。

正在隔离C11109 development/player_dynamic_text_pcm_bram_candidate：仅改WAV样本存储为规范同步BRAM、独立无reset RAM端口、注册同地址读写旁路，控制/解析/count/pointer时序保留；top/status仅版本DFC11109。CRC、桥、读卡/FAT、HDMI/PHY/PLL/原约束保持。原WAV样本FIFO为分布式存储/宽读取选择；拟缩短并规范读取路径，是否修复需上板，不把映射变化当根因定论。

已有原WAV完整模型PASS（合法/错误/超时/短长扇区/并发pop-push210次等），新旧有效输出等价与prefix pipeline/正式RAM映射/最终时序/位流仍验证中；未生成C11109下载包。下一步先完成这些检查再交付，TF不用改、无需重录C11108。

### C11109 本地综合与布局布线里程碑

2026-10-11 17:50（北京时间）：综合与正式 physical 完成；实际网表中样本存储为四个 EG_PHY_BRAM DP8K/2048×4，23块BRAM9K（父版19）。最终12128 LUT、7935reg、13703LE；原约束SWNS +0.660ns、HWNS +0.014ns、STNS/HTNS均0，coverage99.95%。当前无负hold，不需要fix_hold。阶段源/脚本/DB/报告绑定已成功，见新工程build/manual/stage_evidence。

原WAV模型、实际player/bridge异步流水线与三段CRC模型、状态10页与版本DFC11109通过；流水线包含被动观察支路故障注入，非实际HDMI包/引脚验证。模型中真实音乐默认参数CRC单元得F485，但不代表完整生产播放器已对真实音轨仿真。新旧有效输出等价模型仍在冻结/独立重跑，尚未生成位流或交付包，实板仍未验证。待这些检查完成再bitgen/封存/交付。


### 2026-10-11 17:52:48（北京时间）｜C11109同步BRAM候选｜本地验证/构建/封存/交付完成，实板PENDING

- 动作：隔离工程development/player_dynamic_text_pcm_bram_candidate；相对C11108仅tf_wav_file_player样本FIFO改规范同步BRAM/无reset读寄存器/显式寄存同址旁路，top与status只改build ID。user_source其余文件逐个哈希不变，原SDC/PLL/PHY/HDMI/读卡/桥未改。
- 实际综合：4个EG_PHY_BRAM DP8K/2048×4为样本FIFO，全工程BRAM9K19→23；最终12128 LUT、7935reg、13703LE、0DSP、2GCLK。旧分布式FIFO也见于成功基线，不能据此认定唯一根因或解释HDMI无信号。只读父工程审计留在build/model/parent_fifo_audit.md。
- 模型：原WAV合法/错误/超时/扇区/并发210次通过；实际player/bridge缩放异步流水线、跨扇区header、loop和被动监视支路故障注入通过；production参数仅通用CRC单元对真实音乐窗口F485，非完整真实音轨播放器仿真。状态10页/DFC11109/wrap通过。根代理独立重跑新旧FIFO有效输出+软件队列：D256 push780/pop771、空/单元素/满同时读写bypass10/1/1、wr/rd wrap3；D2048 push2572/pop2563、10/1/1、wrap1；复位丢弃9项后重装正确，无有效输出顺序差异。模型不模拟EG_PHY_BRAM碰撞原语或加密HDMI/引脚。
- 正式构建：synthesis/physical/bitstream三阶段成功，源/脚本/gate DB/最终报告哈希匹配；原约束SWNS+0.660ns/HWNS+0.014ns、TNS0、coverage99.95%。初次路由无负hold，未执行fix_hold，原约束未放宽。阶段ID：{"synthesis": "6d014cfb-1b2a-4cc1-8c93-273e3545300e", "physical": "dc69e485-1579-4436-b9b3-e7b1bd83ea40", "bitstream": "03536f7d-8cad-426a-8b3e-b17dd4d58016"}。
- 产物：download/pcm_bram_candidate.bit，629624字节，SHA256 A5F2C25BA1F65B05051419093BC78EC2DD05E510502D914450DD77673CB7E0C0；deliverables/pcm_bram_candidate_20261011.zip，617722字节，SHA256 EBFF3DE96CC71677A2BC8566923F64ED8C081B1BB6D6D107B9D48EBD7ACB2839；ZIP6条目解压逐项校验，含osd_phy_fix回退；139文件checkpoint，manifest SHA E24D02BD582353B8E19797ABF1DB96A38306091CB1B2ED2B10552CACCBEEF218。live与冻结info均PENDING，未把候选记修复成功。
- 已确认旧候选：用户同卡/供电/HDMI回载osd_phy_fix后图片/WAV/内部tone全部恢复；C11108 source F485而FIFO pop/HDMI输入D2D6的诊断差异仍需新候选实板确认，不能据此证明HDMI无信号同一根因。C11108旧134文件checkpoint/ZIP保留，live info为FAIL_NO_SIGNAL_CRC_DIVERGENCE。
- 未完成/边界：C11109尚未上板；CRC16可能碰撞、仅固定窗口到核输入，未验证实际WAV包内PCM或物理链路；原约束覆盖率及既有外部IO/时钟例外不因本次STA通过而视为实物已验收。板卡在远控实验室电脑，代理未操作JTAG、TF或Flash。
- 下一步：将新ZIP发到板卡电脑解压英文路径，BitWriter空闲后断电5秒/上电/PROGRAM_SRAM5MHz下载pcm_bram_candidate.bit；等默认WAV10秒录数码管/四灯至少25秒，D应DFC11109，6/7/8应6700F485/7700F485/8700F485，再长KEY1约2秒听内部tone并反馈画面/音乐/KEY0/短KEY1。无需改TF，不必重录旧候选；失败同条件回载同包osd_phy_fix。


2026-10-12后续：C11109用户所反馈全部功能通过，三段CRC都F485，版本DFC11109。原C11108失败结论不改；原因证据与范围见[新通过记录](../同步BRAM实板通过与原因证据_20261012/README.md)。
