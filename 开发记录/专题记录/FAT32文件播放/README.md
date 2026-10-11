# 480p只读FAT32文件播放

日期：2026-10-07（北京时间）。工程：E:/VSCODE-project/FPGA-ANLU/development/player_fat32。

## 最新进展（2026-10-08 20:49:32）

packet_diag图像/按键/轮播及两音源正常为用户反馈；两段视频已核对模式3/B、输入/包内样本/包数48000、F=E、所见BCH/TERC/内部tone异常0、CTS25000/N6144。无需再补录基线，旧故障根因仍未证实，下一步实际音乐/换文件与长时运行。见[完整视频判读与原字节归档](packet_diag两音源视频判读_20261008.md)、[当前状态](../../当前状态.md)。

## 首版目的与历史状态

把既有固定物理扇区试验版替换为只读文件访问：启动时挂载FAT32，根目录按短文件名收集最多4张BMP与TEST.WAV，再沿FAT簇链读取，允许文件碎片。以用户已确认显示正常的compact_data_d1_verified为源码基线，保留player_480p和其位流。文件层仿真、最终综合、布局布线、布线后保持修复及位流生成完成；candidate_v1用户上板固定乱码/无声，D2/D0亮，回载data_d1正常；已制作隔离诊断版，根因待定位。

## 数据路径

1. fat32_catalog在启动期间独占TF卡，读取MBR/VBR、校验几何和活动FAT、跟随根目录簇链，生成起始簇与文件大小描述符。挂载结束再交出读卡所有权。
2. 图片/音频各一份fat32_file_sector，把文件逻辑扇区映射到物理扇区。缓存顺序访问的当前簇；回读/切换描述符重新从起点遍历。FAT元数据不会冒充文件字节。文件链循环使用跨请求保留的Brent状态及4096簇上限检测。
3. tf_bmp_file_player检查BMP头，以实际像素偏移和文件大小读取BGR字节，发出24位RGB像素；完整帧写完再切显示缓冲。帧缓存继续采用已验证data_d1方案，由原帧缓存完成上下翻转。
4. tf_wav_file_player读取RIFF/WAVE，遍历fmt/data/未知块及奇数填充，缓存一扇区用于字段解析；支持data先于fmt并回读，按真实data长度输出和循环PCM。样本FIFO和HDMI桥继续工作。
5. sd_sector_arbiter在扇区边界仲裁；BMP等待时最多连续给音频2个物理扇区（包括FAT元数据），随后服务BMP。所有请求保持到end，之间至少3个时钟空隙。错误可通过LED观察。

## 首版支持边界

- 512字节扇区的FAT32，主MBR分区类型0x0B/0x0C或LBA0直接为VBR；不支持GPT、exFAT、FAT16、子目录与长文件名解码。长名对应的8.3目录项仍可按BMP扩展名收集。
- 每簇1/2/4/8/16/32/64/128扇区，最多1/2份FAT；禁用镜像时按ExtFlags选择活动FAT。根目录扫描最多256簇，单文件最多4096簇，超限报错，需复位后重试。BMP按目录项顺序收集前4个有效普通文件，不按名称排序；WAV只识别TEST.WAV的精确短名。
- BMP：640×480、底向上、24位BI_RGB；支持大于54字节的像素起始偏移，当前不支持压缩、负高度或其它几何。发现选中文件不合法则报错，不跳到下一张。
- WAV：48kHz、16位、单声道、PCM（tag1），blockalign2、byterate96000；fmt基本字段16字节及扩展、未知块和填充允许。data必须非空、长度为偶数且位于RIFF/文件范围内；重复data块拒绝。输出复制为HDMI双声道。
- 挂载只运行一次；换卡/换文件后需要重新复位。缺BMP或WAV不属于挂载错误，但对应功能不启动。本工程所有SD写端口固定禁用，未写TF卡。

## 已完成验证与证据

- Mapper专用仿真：SPC1/8/64、碎片/cache、回读与描述符改变、EOF、非法/free链、跨请求循环、超时和字节间隙，通过。build/fat_sim/mapper_sim.log（以实际脚本产物为准）。
- Catalog专用仿真15用例通过：非零启动代码MBR、合法superfloppy/VBR伪分区字段、活动FAT、两簇根目录、精确扫描上限、坏几何/目录/FAT及511字节/同周期结束、超时与扇区结束同拍等。build/fat_sim/catalog.log。
- WAV专用仿真通过：跨扇区字段、odd未知块/填充、data先于fmt、扩展fmt1024字节、短/长真实循环、截断/格式/响应超时、511/513字节、非法FIFO、同周期mapper错误；同步FIFO pop/push命中210次。build/fat_sim/wav_file_player.log。
- 仲裁专用仿真：连续18扇区，两客户端数据/end独占正确，12音频/6图片，优先上限2，通过。build/fat_sim/fat_arbiter.log。
- 首轮整机16×64与640×480，包含碎片BMP/WAV、字段跨扇区、三次精确RGB帧、KEY下一张和轮播开关、WAV2300样本真实循环，通过。模拟卡/文件系统，不替代真实卡或板卡验证。最终代码三场景复测均通过；12.5MHz SPI模型按每字节32个50MHz时钟、约48kHz（每1042拍）消费PCM，不屏蔽音频欠载检查，4600样本匹配。
- 脚本audit_fat_scope.py核对改动仅top、仲裁及新增4个文件层模块；像素codec/帧缓存/SDRAM/IP/PLL/引脚/SDC与成功检查点逐文件哈希一致，证据build/fat_source_audit.json。

## 尚未完成

最终综合15287LUT（77.99%）、7065寄存器、19BRAM9K、0DSP；WAV扇区缓存已实际推断为块RAM。最终布局布线和位流已完成（结果见下文）；candidate_v1用户上板回归失败，待定位和修复。ES8388、Flash固化、720p和长期稳定性不属于本次已完成范围。

## 依据

- Microsoft FAT32 File System Specification（fatgen103.doc），本地资料：赛题1_工作资料/02_关键IP与工具手册/fatgen103.doc。文件读取只实现上述支持范围。
- Microsoft RIFF说明：https://learn.microsoft.com/en-us/windows/win32/xaudio2/resource-interchange-file-format--riff-
- Microsoft BITMAPINFOHEADER：https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader

最终构建结果与下一步上板操作在本页补充；最新阶段以开发记录/当前状态.md为入口。

## 综合排查

首轮18806LUT/10794寄存器/18BRAM、gate SWNS-3.197ns：多读端口扇区cache形成4096FF和大mux，catalog几何动态乘加一路进入状态控制。证据封存build/attempt_unoptimized。修正catalog按FAT数1/2使用mux/移位并将几何计算分为PREP0/1/2/CHECK，缓存改单同步读口后15287以前曾降到15993LUT/7073寄存器/18BRAM（logic DRAM）。仅加ram_style=bram属性时SYN-5042推断失败退回FF；报告build/attempt_bram_inference_failed。再将RAM读写拆成独立always、不复位读数据寄存器，保留parser地址/valid门控，最终TD确认Infer Logic BRAM(u_wav_player/ramread1_syn_4)。WAV功能/错误用例继续通过。依据TD安装自带doc/SWUG/SWUG106_HDL_Coding_Synthesis_User_Guide.pdf第61–63页及template/verilog/Synthesis-Structure/Directive/RAM-Inference-Styles/ram_style.v。

文件链按请求遍历，未在挂载时预先检查整条文件链完整性；Brent检查可能在首次重复后的后续遍历才报错，4096簇上限防止无限读取。此为范围边界，不能把已测坏链场景推广为对所有损坏文件系统的完整诊断。
## 最终构建与待上板版本

- 位流：E:/VSCODE-project/FPGA-ANLU/development/player_fat32/build/manual/AC201_player_fat32_candidate.bit，629624字节，SHA256 0243EC0B5D33D2586561BF8349739C06BFC6BF8AFD7D972AF0F48CC4CDBB974E。
- 对应.info.json记录版本、哈希、仿真、真实卡操作与上板状态；仍为board pending。独立检查点checkpoints/fat32_candidate_v1保留源码、脚本、测试夹具、位流、路由DB、报告；manifest共157文件逐项哈希复核通过。
- TD6.2.178840最终Routed SWNS0.394ns、STNS0、HWNS0.022ns、HTNS0，coverage99.99%；16032LUT（81.80%）、7250寄存器、17134LE、19BRAM9K、0DSP。资源为路由结果，区别于较早综合15287LUT。
- 首次route后HWNS-0.008ns、HTNS-0.013ns，两端点位于WAV分布式FIFO；报告/DB封存build/attempt_hold_violation。按SWUG105与DefaultFlow.tcl在同一SDC下执行裸fix_hold，再final update_timing/export_db，保持违例消除，建立余量未下降。证据build/manual/hold_console.log与AC201_tf_hdmi_pr.timing/.ts。
- 构建顺序：scripts/build_candidate.ps1的synthesis、physical、hold、bitstream阶段。fix_hold.tcl只修改布线DB，不修改RTL、SDC或时钟；最终新DB用于bitgen。无通过放宽约束取得时序通过。
- 源码范围经audit_fat_scope.py核对；像素codec、data_d1帧缓存、SDRAM/IP、PLL/引脚/SDC与用户已验证检查点一致。原加密SDRAM内部clk/undriven告警、3 dummy和4/11 IO delay缺项仍保留；当前coverage/时序结果不能替代这些外部电气表征，也不证明所有CDC或长期稳定性。

## 用户下一步

1. 使用原TF卡，不格式化、不重新装素材。插拔卡时先断板卡电源；保持此前稳定的独立5V供电，AL-LINK连接电脑。
2. TF插回板卡后上电，在BitWriter按既有PROGRAM_SRAM、JTAG5MHz流程添加上述英文路径候选位流并下载；等待完成。代理未操作板卡。
3. 首图出现后检查苹果红色、图像无点带；KEY0手动切图，KEY1自动轮播开/关，四图均正确，TEST.WAV可听到并持续循环，切图期间声音不停止/乱音。若异常，记录图像、声音与LED状态，并回载player_480p/build/manual/AC201_tf_hdmi_data_d1.bit作A/B。
4. 上述基础回归通过后再验证更换文件/碎片或实际音乐；不要把现有卡正常推广为所有卡、所有音乐格式均通过。本版换卡/改文件后需复位重新挂载，未实现Flash自启动。
## 实物失败后的排查（2026-10-07 22:55）

用户确认新位流四张固定乱码、无声、D2/D0亮，切图间隔相近；回载稳定data_d1正常。故candidate_v1不可作为实物成功基线；上文board pending是构建时历史状态。

D:真实卡只读核查：分区物理LBA32、SPC64，4BMP/WAV完整文件及FAT链重建哈希与原素材一致，格式合法。快照与解析在player_fat32/build/actual_card_readonly。物理LBA0受OS权限拒绝，回放仅合成MBR，不能写成实际MBR已验证。

真实卡两帧/四帧回放PASS；四帧1228800像素和126473 PCM样本逐点匹配，CARD_GAP=1。小尺寸双帧文件层至真实FIFO/帧控制模型PASS，完整480p尚在运行。TD早期网表与gate导出完成，但Icarus StringHeap.cc:77断言阻止编译，停止重试，未取得网表功能结果。

隔离player_fat32_debug构建了4行HDMI诊断：错误flags/codes、BMP源像素完整帧求和、首次WAV错误位置及缓存字节/phase/首字节。说明见[E:/VSCODE-project/FPGA-ANLU/development/player_fat32_debug/README.md](E:/VSCODE-project/FPGA-ANLU/development/player_fat32_debug/README.md)。只在副本加入观测输出，未改文件层状态机或存储/SD/PLL/引脚/约束；WAV、monitor及叠字仿真通过。

诊断位流player_fat32_debug/build/manual/AC201_player_fat32_diagnostic.bit，629624字节，SHA256 22AC2160905621B147005F3689E4EB56D11485FE2D0C291AF7275FE163F2E624；Routed SWNS0.278ns/HWNS0.024ns/TNS0/coverage99.99%，初始微小hold经裸fix_hold消除，SDC未改。原warning边界保留。未上板，未修复完；待用户卡移回断电板卡、下载诊断版并拍清四行，以数据判断后续修复路径。


## 2026-10-08 屏幕诊断无信号，改用LED probe

用户同连接回载data_d1恢复全部图像/声音，diagnostic.bit下载日志明确成功但屏幕无信号，四灯全亮为display_valid分支，不能作错误码。PLL/pin/SDC/HDMI PHY与BitGen PLL编码核查一致；静态记录不能确定无信号机制。新player_fat32_probe去RGB叠字与视频诊断CDC、原RGB直通，用D3=FAT挂载、D2=最近完整源图求和匹配四原图之一、D1=首WAV字节RI、D0=音频primed且无错作独立观测。原诊断顶层向量先使用后声明的4条critical warnings在新副本修正，尚未证实是根因。Probe完成monitor/WAV回归和TD构建，SWNS0.306/HWNS0.031ns/TNS0/coverage99.99%；位流79E819D1F79EE3100406B1C30A730FF39F568F2C3B0C5027B404A6C25E59FF19，629624字节，未上板。全尺寸深层帧缓存仿真没有结果，不标PASS。后续以新四灯与HDMI/声音反馈继续定位，不改TF或Flash。详见[probe说明](E:/VSCODE-project/FPGA-ANLU/development/player_fat32_probe/README.md)、[本日日志](../../工作日志/2026-10-08.md)。



## LED probe图像/按键正常、静音继续定位（2026-10-08）

用户反馈probe图像、KEY0手动、KEY1自动均正常，四灯全亮但静音。旧D0就绪条件不能证明bridge.started/audio_valid：首request/ack未完成时primed可高而underflow仍0。新隔离player_fat32_audio_probe增加WAV消费/PCM变化/ACR观测，并用KEY1切换同HDMI核心的WAV/内部音阶；KEY0保留，本诊断KEY1暂不自动切图。自检覆盖启动卡住/音阶绕过/119样本及非零DC，原约束TD最终SWNS0.262/HWNS0.022ns/TNS0/coverage99.99%，位流4FC48C6678758FC1B74BD0BB9D9DA4FDD6132198BB1AEE8C294C6340EA81CF8C，629624字节。已构建未上板，未确定静音根因，未写TF或Flash。参见[音频probe说明](E:/VSCODE-project/FPGA-ANLU/development/player_fat32_audio_probe/README.md)和[本日日志](../../工作日志/2026-10-08.md)。


## 2026-10-08 音频诊断版上板基本播放通过

用户反馈：默认WAV正常、画面正常、KEY0手动切图正常，四灯全亮；KEY1切内部音阶后声音正常，D3闪烁、D2/D1/D0常亮。该版KEY1按设计不自动轮播。持续时长未记录、代理未直接测量；回切WAV与换文件/碎片实物未单独验证。

成功位流：E:/VSCODE-project/FPGA-ANLU/development/player_fat32_audio_probe/build/manual/AC201_player_fat32_audio_probe.bit，629624字节，SHA256 4FC48C6678758FC1B74BD0BB9D9DA4FDD6132198BB1AEE8C294C6340EA81CF8C。源码哈希与构建元数据匹配，139文件成功检查点位于development/player_fat32_audio_probe/checkpoints/audio_probe_20261008_verified。详见音频probe README/.info.json及本日日志。旧candidate乱码/overlay无信号/LED probe静音的具体根因仍未证实，不能把本次成功归因为某项已确定RTL修复。

当前top与pin.adc未接入AC201 74HC595数码管驱动，照片字形无播放器状态含义；可能保留先前显示或处于未驱动状态，具体段码来源未测。照片：2026-10-08/audio_probe_segment_display.jpg。下一步从成功副本恢复KEY1自动切图，独立保留音频诊断；本轮只封存/留档，未改HDL或构建、未写TF/Flash。

## 2026-10-08 16:15:58 自动轮播恢复版构建完成，待上板

从audio_probe成功检查点独立建立development/player_fat32_autoplay，仅改top恢复KEY1自动切图、固定WAV。KEY0仍手动；本版KEY1不切内部音阶。69个user_source核对，仅top变化；原音频桥/ACR/文件/图像/IP/引脚/SDC未改，综合会裁剪不可达音阶，物理布线改变。

629624字节，SHA256 A917B200BE2D058FB88AC7732FD0772800360F7CAC3B24CC6011F7211DAD4912；位流development/player_fat32_autoplay/build/manual/AC201_player_fat32_autoplay.bit。两个16×64并发模型PASS，包含自动开/关及每场景4600精确WAV样本。TD最终SWNS0.384/HWNS0.038/TNS0/coverage99.99%；初始微小hold已原约束fix_hold修复、保留前后DB/报告。源码/位流/报告等153文件封存checkpoints/autoplay_20261008_candidate，哈希核对一致。

新版上板待用户反馈，旧故障根因仍未确定；数码管/Flash等未完成，未写TF或操作板卡。下一步加载autoplay位流、检查KEY0手动和KEY1自动开关期间WAV持续，原audio_probe与data_d1回退保留。

## 2026-10-08 16:35:15 keepaudio对照版已构建，待上板

固定WAV autoplay上板严重杂音，图像/KEY0/KEY1正常；同连接回载成功audio_probe默认WAV/内部音阶均干净。已记录为实物音频失败。

从成功检查点建立player_fat32_autoplay_keepaudio，仅top恢复auto并延长诊断音源键至1.5s，保留动态tone/mux；短按KEY1正常自动轮播，长按用于音源诊断且也会触发一次轮播。短/长按模型PASS，实际TD tone实例保留；原约束时序SWNS0.394/HWNS0.027/TNS0/coverage99.99%，位流629624字节，SHA256 30BA033E29F0AFEBF2C3FC3FCE1633A4B3927AAF94F06C7B2E6E55653EA551A0，路径development/player_fat32_autoplay_keepaudio/build/manual/AC201_player_fat32_autoplay_keepaudio.bit；152文件检查点哈希核对一致。

真实路由网表的针对性文本审计未发现FIFO/PCM位宽/valid/ACR明显错接，非全等价或实物测量，根因仍未证实。详细审计：音频杂音网表审计_20261008.md。下一步先默认WAV与短KEY1听音；异常再长KEY1作同位流音阶对照。未写TF/Flash、未操作板卡。

## 2026-10-08 17:46:09 keepaudio回退与数码管分层观测

用户同条件回载audio_probe四项正常；失败keepaudio长KEY1后D3闪烁而听感不变，不能认定按键完全失效。PLL/HDMI PAD配置与对应STA针对性核查无明确异常，非波形/全网表等价证明。新[数码管诊断与证据](keepaudio黑屏诊断_20261008.md)完成独立模型、TD构建/原约束保持修复/封存，位流status_diag SHA256 0EE4EF71838B3CAD7F0C360E9FEAAA5672C2DE7C5FA6BA21C73F9EEE8B5BD907，SWNS0.253/HWNS0.024/TNS0ns、coverage99.97%，629624字节。五页观察HDMI输入像素/样本/PCM变化、启动/FAT状态；未上板、非已验证修复，根因仍未证实。下一步读取默认与长按音阶模式页值；成功回退audio_probe。未写TF/Flash。

### 2026-10-08 18:06:35 实板数码管视频已读取，声音仍杂音

status_diag默认WAV视频五页判读：1dA80000、2304b000、3300bb80、43008Cxx、5304b000；每名义秒48000音频valid，约359xx变化与源WAV静音结构相容，每帧有效/非黑307200。用户反馈画面正常、默认音阶循环但沙沙杂音；按请求长KEY1后仍沙沙。已保留原视频和取样图，live元数据更新，冻结候选不改。不能用计数证明样本逐点/包/TMDS正确，音频修复仍未完成。下一步补录同位流D3闪烁模式页；详见[诊断实物证据](keepaudio黑屏诊断_20261008.md)。


### 2026-10-08 19:12:00 内部tone视频已读；包观测工程尚未通过setup

第二视频已确认M=B、48000 valid与679/832/1017/555变化匹配DDS模型，用户仍反馈沙沙。
不确认两视频同一连续运行，不证明逐样本/包/PHY。视频副本见[内部tone视频](2026-10-08/status_diag_internal_tone.mp4)，
详细输入与输出观测路线见[诊断证据](keepaudio黑屏诊断_20261008.md)。
packet_diag包模型31项、九页与595模型PASS，但原约束SRAM输出setup仍SWNS-0.263ns，
hold0.031ns；替代route/目标HFN未解决、post-route reroute工具自身崩溃，全部失败证据保留。
尚无新位流/板测/已证音频修复；211文件未完成工程检查点已封存，下一步解决诊断setup再观测包。
用户暂不需补录status_diag；未写TF/Flash、未操作板卡。

- [包诊断候选下载与九页判读](packet_diag上板步骤_20261008.md)：2026-10-08最终构建/原约束STA通过，实板未验证；310文件检查点已保存。

