# keepaudio黑屏与颤单音：本次证据和下一观测

更新：2026-10-08 17:19:49（北京时间）。现场结果来自用户反馈。

## 回载结果

keepaudio位流SHA256：30BA033E29F0AFEBF2C3FC3FCE1633A4B3927AAF94F06C7B2E6E55653EA551A0。
显示器从无信号/无背光进入有背光的黑色；不是用户所见的无信号。
声音单一且颤，短按两键无可见变化，长KEY1听感不变。
补充证据：四灯全亮，长KEY1后D3闪烁。因此控制路径和tone_mode指示运行，不能认定所有按键停止。
同卡/供电/HDMI/音量回载audio_probe：图片、默认WAV、KEY0、KEY1内部音阶全部正常。
成功位流SHA256：4FC48C6678758FC1B74BD0BB9D9DA4FDD6132198BB1AEE8C294C6340EA81CF8C。

## 静态和实际构建审计

- 69个原user_source文件只有top不同：key_auto恢复key2，tone debounce50改1500ms。
- 消抖实际计数37,500,000，32位足够，无整数溢出。新LED反馈也证明长按触发。
- sys/video PLL源码、原引脚/SDC相同。实际routed网表10个PLL/HDMI PAD实例参数逐项一致。
- 25→125MHz组31端点均分析，keepaudio setup6.201/hold0.390ns，无违例；serial自域无违例。
- 共享reset跨域未逐域同步释放是风险，两版相同且recovery报告正裕量；未证实为本次原因。
- STA与配置文本核查不能证明实际TMDS字/HDMI包或板级信号正确；四灯锁存也不能证明连续供数。

网表证据：E:/VSCODE-project/FPGA-ANLU/development/player_fat32_autoplay_keepaudio/build/hdmi_impl_audit。
包含导出TCL/log、keepaudio_routed.v、compare_phy.py、phy_comparison.json。该核查不是全网表等价证明。
只读子代理审计与主代理核查一致，未发现能直接证明黑屏/颤音的源码机制。不重试曾崩溃的完整Icarus网表编译。

## 被动状态版（构建完成，未上板，非修复）

工程：E:/VSCODE-project/FPGA-ANLU/development/player_fat32_status_diag。
保持keepaudio播放控制，只在top增加监测扇出、接HDMI的O_video_locked及595引脚；新增status_monitor与status_hex595。
原69文件仅top/ADC不同；67文件哈希相同，SDC/IP/PLL/文件/播放核心不改。观测会改变物理实现，不能反推旧位流内部状态一样。
数码管前2秒01234567，后2秒88888888，随后五页每2秒切换。参数和译码见新工程README。
监测启动/FAT/提交状态、送HDMI的上一完整帧非黑与有效像素数、每名义秒audio_valid数/PCM变化数。
所有数值为十六进制。48k样本应00BB80，640x480有效像素应04B000；实际时钟未测，数据只证明送入接口的观察。
状态mailbox每名义秒一次、请求/应答同步，92位总线在正常非复位期间保持到接收确认；最终显示复用像素时钟，复位释放独立于播放器复位，复位会取消未完成事务。

RTL状态测试与外部595链模型均PASS；不是完整HDMI/SDRAM或实物验证。
首轮布局布线有setup-0.638ns/hold-1.539ns，原约束fix_hold未消除；保存build/attempt_initial，不生成位流。
给新增观测时钟使用BUFG后重新综合中；未放宽/删除原约束，未改播放PLL。最终时序与位流另追加实证结果。
本轮未写TF、未烧Flash、代理未操作板卡。根因和修复仍未完成。

### 2026-10-08 17:38:23｜诊断实现时序处理（进行中）

- 原参考时钟捕获的93条状态/mailbox保持路径不达标；加BUFG仍HWNS-1.539ns，归档attempt_status_bufg。改为负沿捕获后原约束fix_hold得到HWNS0.024ns，但外部SRAM移相setup仍SWNS-0.790ns/STNS-4.448ns，归档attempt_status_negedge。未生成位流。
- TD post-route phys_opt relocation自身崩溃（optimize_console.log，minidump-20261008-172852.dmp）；未重复这条崩溃流程。
- 当前更低影响方案：观测/595共用已运行的25MHz像素时钟，观测仍负沿读快照，显示复位与播放rst分离。该方案不保证像素时钟停转时继续显示；已有D3闪烁证明用户报告的故障版像素时钟运行。播放PLL、原SDC、文件/音频/图像逻辑不改。综合完成，常规布局布线进行中。
- 595仿真改用实际25MHz参数，外部链模型PASS：128锁存/64有效位，SCLK0.926MHz，帧刷新120.806Hz。状态模型仍PASS；PCM变化计数的窗首样本可以与前窗末样本比较，复位会取消未完成mailbox事务；已精确化说明。


### 2026-10-08 17:46:09｜诊断版构建与封存完成｜实物验证待用户

- 最终方案复用已有25MHz像素时钟，状态快照负沿接收、595按25MHz参数运行且复位独立于播放rst；若像素停钟显示也停止。原播放逻辑/IP/PLL/SDC保持keepaudio，69原源仅top与ADC两文件不同、67相同，新增player_status_monitor/status_hex595。不可将新诊断版结果反推旧位流波形完全一样。
- TD6.2.178840综合/常规布局布线完成，pixel方案初始SWNS0.253/HWNS-0.020/HTNS-0.037ns保存在build/attempt_pixel_prehold；原约束fix_hold后SWNS0.253/HWNS0.024/STNS0/HTNS0ns、coverage99.97%，全部分析端点无setup/hold违例。16533LUT/7912reg/17907LE/19BRAM9K/0DSP/2GCLK。外部HDMI/595等板级IO延迟、加密IP等已有验证边界保留。
- 仅在最终setup/hold非负后生成development/player_fat32_status_diag/build/manual/AC201_player_fat32_status_diag.bit；629624字节、SHA256 0EE4EF71838B3CAD7F0C360E9FEAAA5672C2DE7C5FA6BA21C73F9EEE8B5BD907。.info.json保存源哈希/阶段/边界；checkpoints/status_diag_20261008_candidate共142文件manifest逐项复核一致，包含原约束时序、模型日志和失败实现报告/DB。TD优化自身崩溃现场保留，未重复崩溃流程、未从违例尝试生成位流。封存脚本报告解析缩进已修正，未改HDL或重编译。
- 已完成的独立模型：状态页/样本/PCM变化/帧计数/黑与非黑/独立复位PASS；外部595链模型25MHz参数PASS（0.926MHz SCLK、120.806Hz刷新）。不含完整HDMI/SDRAM、卡或实板，不能称音视频修复验证。
- 未完成：诊断版未上板；keepaudio黑屏/颤音及自动轮播版杂音具体根因仍未证实，同版FAT32自动图像+干净音频交付未完成。成功回退audio_probe本轮获用户确认四项全好。本轮未写TF或Flash，代理未操作板卡。
- 下一步：同卡/供电/HDMI/音量PROGRAM_SRAM加载status_diag；初始4秒数字自检后等待稳定，记录默认模式图声+五页完整8字符（或覆盖完整循环的清晰视频）；再长KEY1约2秒至D3闪，记录3/4页与音阶听感。用HDMI输入非黑/有效像素、audio_valid/PCM变化分层判断，必要时回载成功audio_probe。

### 2026-10-08 18:06:35｜status_diag 默认模式视频判读及音源对照｜实物图像通过、音频仍失败

- 用户视频45.876544秒、720x1280 H.264/AAC，原文件SHA256 B5FF3DEFA1FB1F25BDE782D5568C93673C03F9BE3AA23E5DC5F81D0C96F1B2CE；已只读取样并逆时针90度旋转用于判读，不改原文件。原视频副本归档[status_diag默认WAV视频](2026-10-08/status_diag_default_wav.mp4)，逐帧/联系图/判读JSON保存于工程development/player_fat32_status_diag/build/board_video_20261008。副本哈希一致。
- 用户明确未长按KEY1，视频是默认WAV；用户反馈图片正常，声音仍沙沙、已恢复循环音阶而非此前单颤音。数码管由代理从视频判读：页1=1dA80000；页2=2304b000；页3=3300bb80；页4=43008C5E/43008CA5/43008C79/43008C95/43008C46等；页5=5304b000。多轮稳定观察。不是代理仪器直接测量，屏幕图像/音质结论来自用户反馈。
- 解码：两PLL锁/播放复位已释放/SD初始化，FAT就绪/帧提交/WAV预充高，所示FAT/BMP/WAV/mapper错误flag与code为0。M=3：默认WAV、bridge underflow0、HDMI video_locked1、frame_seen1。非黑像素和有效像素均307200；每名义25MHz秒48000 valid音频事件；PCM变化数35910..36005。状态不支持当前黑帧或完全停样解释，但不能证明逐样本值/顺序或输出包正确。
- gpt-6-luna只读核对canonical TEST.WAV（SHA256 b29c1669416da2c492187a9db66e0e97bfcd2e6fa9812b33ed300c1c21ca80a7），8个750ms音符+250ms静音，自然每秒变化数35902..35997。视频变化率相容，不能用变化低于48000推断掉样；计数窗与WAV边界不同，尚未逐样本核对。审计文档已纠正页2/3归属、与audio_probe的top差异（除监测外还有auto及长按阈值）。本轮未重读实物卡。
- 用户按请求长KEY1约2秒后补充“仍有沙沙杂音”；未提供长按后的页值/视频，尚无该模式M和样本计数实读。两音源仍杂音支持继续查共享HDMI音频/时钟路径，不能据此确定包/TMDS/接收器具体原因，或完全排除上游样值。此次默认图像恢复亦不能归因为某一已证RTL修复；观测版改变实现布线。
- 动作：更新live status_diag .info.json/README；原142文件candidate检查点仍保留构建时pending状态，不覆盖。证据字节与位流SHA256仍0EE4EF71838B3CAD7F0C360E9FEAAA5672C2DE7C5FA6BA21C73F9EEE8B5BD907。无HDL改动、无构建/新位流、未写TF/Flash、代理未操作板卡。
- 未完成/下一步：音频修复未完成。当前同一位流先补录D3闪烁的内部音阶模式数码管完整一轮，核实M=B（无欠载时）、页3有效节拍及页4方波变化；不需重新下载。在取得这组同实现输入观察后，优先判断共享发送路径；必要时追加输入PCM序列CRC或包级观察，均尚未实施，避免只为改变布局反复盲编译。


### 2026-10-08 18:38:44｜status_diag 内部音阶视频判读｜输入计数有效，杂音未修复

- 用户提供第二视频23.067289秒、1280×720原生横向，无需旋转；6264756字节，SHA256 `71D32F9BBCFB8A7239D6D365B0414DE6559163AE2A92BE5122B67ECEB4896742`。原视频已复制到[内部音阶视频](2026-10-08/status_diag_internal_tone.mp4)，副本哈希一致，判读裁图为`2026-10-08/status_diag_tone_display_crops.jpg`；逐帧、observations.json、独立DDS数学模型保存在工程`development/player_fat32_status_diag/build/tone_video_20261008`。原视频不改。
- 代理视觉判读：起始数码管01234567/88888888自检，7.5秒仍3300bb80；8.5秒以后为内部tone模式B，页1=1dA80000、页2=2b04b000、页3=3b00bb80、页4=4b0002A7/4b000340/4b0003F9/4b00022b（679/832/1017/555）、页5=5b04b000。B含tone=1、underflow=0、HDMI locked=1、frame_seen=1；每名义秒48000 valid，每完整帧307200有效/非黑像素。用户反馈内部音阶仍沙沙杂音。是否重新下载/复位、是否与第一视频属同一连续运行未确认，不宣称同一不间断周期。
- 独立Python样本域数学模型按原DDS LUT/32位phase/48kHz/每音24000样本及输出寄存器延迟计算变化序列556、679、832、1017、555、679、832、1017；与上述实读数值吻合。只证实模式及输入计数符合预期，不证明逐样本幅值/顺序、输出包、物理TMDS；不能单用TF/WAV问题解释内部tone也杂音，优先查共享HDMI发送路径，根因仍未确定。
- 已在隔离工程`development/player_fat32_packet_diag`接入并行TMDS被动包观察分支，扩展数码管到12页；原音视频/PHY/PLL/引脚/SDC不改。包解析独立BCH向量+22项定向仿真PASS，12页状态模型PASS；正在TD综合，尚无新位流、尚未上板、不是修复结论。首个工程属性错误UsedInSim已纠正，失败日志保留`build/project_attr_failure.log`。未写TF/Flash，代理未操作板卡。
- 下一步：包观察工程完成综合、布局布线与原约束时序核对后才生成候选位流；观察音频样本/包数、BCH/TERC错误、内部tone幅值、CTS/N，继续区分核心输出和PHY/接收端。暂不要求再次补录status_diag视频。


### 2026-10-08 18:46:14｜包观测容量处理｜进行中，未生成位流

- 首轮packet_diag综合17379 LUT/8742寄存器，但TD布局打包报PHY-9009：5060 MSlice超过器件4900上限。报告/综合DB/当轮monitor源归档development/player_fat32_packet_diag/build/attempt_capacity_full；非时序通过、未产生位流。工程新增UsedInSim属性导致的首次打开失败已修正并留日志，不是板故障原因。
- 不改原播放链路/IP/PLL/引脚/SDC：保留原92bit输入mailbox，包计数本来同像素时钟且已按秒寄存，直接在595每帧锁存，省去328bit重复快照；包观察仅保留24/56位payload，BCH在线比对；5组计数改16位65535饱和，秒计数取必要宽度。计数页仍六位hex，上限00FFFF。
- 协议边界已按primary规范修正：ACR HB1/HB2忽略、CTS0保留旧值、absent子包flat不拒绝整包。独立反射BCH向量与31项定向测试PASS，12页字段模型PASS、25MHz外部595模型PASS（0.926MHz/120.806Hz）。模型不证明实际加密核心/TMDS音频正确。
- 压缩版重新综合已完成，常规布局布线进行中；不以gate资源宣称实际可布局，不出违例位流。音频根因及修复未完成，尚无新板测。下一步完成原约束STA并封存候选，观察实际核心输出包以定位；未写TF/Flash、代理未操作板卡。


### 2026-10-08 18:50:00｜包观测第二轮容量与595计数压缩｜进行中

- 移除重复快照/缩减payload与packet计数后综合16888 LUT/8287reg；第二轮place仍4918 MSlice>4900，报告/DB/三诊断源已归档build/attempt_capacity_compact，未生成位流。
- 继续只改诊断595：slot_count与half_count由32位取参数最小宽度，25MHz下15/4位；没有改变扫描/移位/锁存时序。外部595模型重跑PASS（0.926MHz SCLK/120.806Hz），packet31项重新PASS；第三轮综合完成、布局布线中。相对status_diag现变更top、player_status_monitor、status_hex595三文件，新增hdmi_packet_monitor；原播放/IP/PLL/ADC/SDC不改。
- 源哈希核对加入分阶段构建脚本，防止使用变更前DB出位流；最终资源/STA未得到，音频修复未完成，实物未测。下一步完成原约束时序，失败则留档而不提供违例位流。


### 2026-10-08 18:53:32｜包观测改为9页集中诊断｜进行中

- 第三轮缩595位宽仍4962 MSlice>4900，实际打包不随位宽单调下降；归档build/attempt_capacity_595，未生成位流。恢复595与status_diag逐字节相同。
- 将packet_diag显示集中到1/3/6/7/8/9/A/B/C九页（18秒周期），保留启动文件错误、音源模式及输入valid计数，去除上一status_diag视频已取得的像素/PCM变化计数器与重复mailbox。不是修改音视频链路，也不是音频修复。原输入mailbox缩至28bit，包计数仍同像素时钟直接显示；595每轮锁存32bit。
- 九页精确字段/独立复位模型PASS，恢复原595后外部链模型PASS；31项packet模型依旧覆盖当前源码。相对status_diag仅top/status两源变化、新增packet observer，ADC/SDC/IP/PLL/播放/595保持原样。重新综合进行中，后续仅从对应新DB布局并核对STA；尚无新板测、未写卡/Flash。


### 2026-10-08 18:55:11｜9页packet_diag布局容量通过｜时序与位流仍待完成

- 9页集中观测版综合16757 LUT/8036reg；实际place打包4872 MSlice（上限4900），开始Detailed Placement，突破前三轮容量错误。此时尚未route/STA，不将中间放置估计负裕量当最终时序或宣称可下载。
- 九页为1/3/6/7/8/9/A/B/C，每2秒，18秒一轮；保留输入valid/模式/启动文件状态和7项包观察。原2/4/5页由status_diag视频已取得，不在新版重复测量。packet源码计数16位65535饱和、BCH31项模型PASS；数码管/ADC/SDC/音视频/PLL/IP与基线相同，新增被动扇出会改变实现。
- 下一步原约束route与必要fix_hold；STA不过不出位流。新候选实物待用户，未写TF/Flash，音频根因/修复仍未完成。


### 2026-10-08 18:58:25｜9页packet_diag路由完成但setup未通过｜位流未生成

- 常规route完成：SWNS-0.263/STNS-0.708ns，HWNS-0.020/HTNS-0.058ns，coverage99.98%；17296 LUT/8186reg/18600 LE/19 BRAM9K/0DSP/2GCLK。prehold DB/完整报告归档build/attempt_packet_prehold。
- 原约束fix_hold完成，HWNS0.031/HTNS0ns；SWNS-0.263/STNS-0.708ns仍在，不能产生可验证候选位流。
- 具体负setup路径为ext_mem_clk→ext_mem_clk_sft，原加密SDRAM三态控制sdr_t_reg_syn_11到sdram.dq[14]等4端点；34 fanout，数据net delay2.784ns，最差总延迟11.349ns。不是包监测内部慢逻辑，也不是旧杂音实板原因已证。新增观测改变物理实现，原SDRAM约束保留。
- 正核对TD官方本地支持的原约束setup优化路径；不重复曾崩溃的phys_opt relocation、不放宽SDC/PLL或新增falsepath。模型31项包/9页/595已通过，仍缺最终STA和新板测；未写TF/Flash、未操作板卡。


### 2026-10-08 19:01:19｜TD post-route reroute自身崩溃｜原DB保留，常规替代route进行中

- 依据本机TD精确help及SWUG105，隔离副本尝试phys_opt -post_route -effort low -mode reroute（不是旧失败relocation），在Abnormal Timing Path check/start_timer -keep_rs处TD自身coredump，minidump-20261008-185941.dmp。未运行至优化结果/bitgen，原manual及attempt_packet_setup_input DB保持，完整日志build/attempt_packet_reroute/reroute_console.log。
- 不再调用post-route phys_opt各模式；改用官方受支持的route effort=routability，从已保存place DB进行常规route+原约束fix_hold，输出独立build/attempt_packet_routability。参数来源是本机TD_User_Guide_V6.2.pdf route properties与setup_help.log；不修改源/SDC/PLL，不宣称该尝试已通过。
- 旧默认路由setup-.263ns仍未解决，音频根因未证；没有新位流、未操作板卡/TF/Flash。下一步等待常规route最终真实STA。


### 2026-10-08 19:05:39｜常规routability仍setup失败，目标高扇出优化调查｜进行中

- routability从原place DB完整route/fix_hold成功，但最终SWNS-0.329/STNS-0.922ns，HWNS0.031/HTNS0；独立输出保留build/attempt_packet_routability。没有新位流。
- 依据phys_opt精确帮助的force_replication_on_nets/fanout_threshold选项，针对已证当前诊断构建瓶颈的sdr_t 34负载，尝试原约束高扇出复制。首次从gate DB执行因physical model尚未建立报PHY-9005/OPT-8004，日志保留build/attempt_packet_replicated；无优化DB。
- 调整为已placed DB上进行目标HFN复制后常规route，输出新独立build/attempt_packet_replicated_placed；不用任何post-route模式，不改源/约束/PLL。此动作只解决新诊断构建的setup问题，不能称为旧杂音根因/修复；结果尚待，代理未操作硬件/卡/Flash。


### 2026-10-08 19:12:00｜第二视频分析完成；packet_diag模型/工程留档｜音频根因及新位流未完成

- 第二视频已确认内部tone模式B、48000 valid/名义秒、679/832/1017/555次PCM变化与独立DDS模型吻合；用户反馈仍杂音。原视频副本/裁图/逐帧/observations.json及模型均已保存；不确认与第一视频为同一连续运行，不证明逐样本幅值/顺序、HDMI包或PHY。两源共有杂音使共享发送路径成为优先调查对象，尚未取得具体机制证据。
- player_fat32_packet_diag源码及功能模型已完成：独立反射BCH向量D0/96/4D/BE/D1、31项packet断言PASS；9页(1/3/6-C)精确字段与独立启动观察PASS；外部595 25MHz模型PASS（0.926MHz SCLK/120.806Hz刷新）。相对status_diag的71源仅top/status变化、69个原源哈希一致，新增packet observer；原播放/IP/PLL/ADC/SDC/PHY/595保持。
- 9页版实际route完成，但默认route原约束fix_hold后SWNS-0.263/STNS-0.708/HWNS0.031/HTNS0ns；routability替代仍SWNS-0.329/STNS-0.922ns。瓶颈已定位新构建的SDRAM三态控制到DQ12..15；不能称为旧噪音原因。post-route reroute工具自身崩溃已留minidump/日志，未重复该模式。placed HFN命令成功但0个复制，后route仍原setup；get_nets集合形式复核同样0复制，规范net和34个PAD TS负载已证，优化器未复制的具体原因未证。不继续同样的无效重布线。
- 没有生成AC201_player_fat32_packet_diag.bit，没有供用户下载的新候选。未完成源/测试/DB/报告/错误日志211文件封存`development/player_fat32_packet_diag/checkpoints/packet_diag_20261008_incomplete`，manifest逐项SHA256核对一致，保存`build/incomplete.info.json`，明确INCOMPLETE/NO BITSTREAM。原成功/失败位流及历史检查点不改。
- 下一步：解决原约束下诊断工程的SRAM输出setup（进一步压缩/局部放置或复核官方工具支持路径），再生成包观测位流并由用户实测默认WAV/内部tone包；当前不要求继续录status_diag或反复回载。音频杂音修复、输出包/PHY/接收器检查均未完成，本轮未重新读卡、未写TF/Flash、代理未操作板卡。所有shell已结束，无后台编译。

## 20:11｜包观测候选可下载（实板pending）

在线ACR/tone校验保留九页和47项模型覆盖，综合少530LUT/153reg。默认与seed2/3仍有SDRAM控制到PADts setup违例；它是本观测工程构建阻碍，不能解释旧杂音。TD只读命令/占用查询后，普通fullname字符串move_cells成功将含sdr_t与addr16的MSLICE由(2,24)移到(17,36)，重新route和原约束fix_hold通过，final SWNS0.102/HWNS0.027/TNS0ns、coverage99.97%，16789LUT/8028reg/18206LE/19BRAM9K。

位流`player_fat32_packet_diag/build/manual/AC201_player_fat32_packet_diag.bit`已生成，629624字节，SHA256 C2B3DEAFB78355C124CE8958015EED31CEBA38CD4B0B41D9179A7190E4200818；选用DB SHA256 30FD59F47628FEC376F5E011961AE72295E51254BB58EC979DF66B2E49B0D10E。310文件candidate检查点hash逐项一致；旧211文件incomplete冻结以及全部失败DB不覆盖。观察器对核心输出被动旁接；69个原user源不变，原SDC/PLL/引脚保持，未新增时序例外或放宽。

本阶段无助手硬件操作/卡/Flash写入。实板包结果与旧杂音根因仍待用户反馈；下一步见[下载与九页判读](packet_diag上板步骤_20261008.md)，无需重复录旧status_diag。原加密IP/宏位置/IO delay/频率边界和包分析未覆盖项均保留。

## 2026-10-08 20:32:27｜packet_diag首次上板基础功能通过（用户反馈）

- 用户反馈：图像正确，KEY0手动切图、KEY1自动轮播正常；长按KEY1前后两种音源音阶均正常。按设计对应默认TEST.WAV与内部音阶，音源模式寄存器未拍摄；没有数码管记录、客观音频/波形或持续时长。
- 版本：packet_diag，629624字节，SHA256 `C2B3DEAFB78355C124CE8958015EED31CEBA38CD4B0B41D9179A7190E4200818`。本机原件与英文短路径 `E:/VSCODE-project/FPGA-ANLU/download/packet_diag.bit` 哈希一致；运行版本按前序下载上下文关联，用户未提供本次BitWriter日志。独立反馈文件：`E:/VSCODE-project/FPGA-ANLU/development/player_fat32_packet_diag/build/board_feedback_20261008.json`。
- 状态：本候选可作为已获用户基础功能通过的回退位流；新增包观察器的实板读数尚未采集，不能声称BCH/TERC/CTS/N及tone幅值实板检查通过，也不能把旧沙沙声归因为本次MSLICE移动或某一项RTL改动。
- 留存：原310文件candidate及211文件incomplete检查点保持冻结；只更新live元数据/说明/当前状态并添加反馈。源码、约束、DB与位流未修改，无重新构建、代理板操作、TF或Flash写入。
- 下一步：建议保持当前位流补录正常基线，默认模式录25秒数码管并带声；长按KEY1切内部源，松开等至少3秒再录25秒。此项用于核对观察器及保留正常包数据，不妨碍将本次基础播放判为通过。后续再验证实际音乐、换文件/碎片与长时运行；旧故障根因仍未证实。

## 2026-10-08 20:49:32｜packet_diag两源视频判读与归档｜已完成（观察窗范围）

- 用户提供长按前627fe2...、长按后4d68c8...视频；26.733333/25.833622秒，原字节分别SHA256 4A9755F1612F60A89672A815EFD502E8F63564969717914579B8994321047A3F / 380AEB0B16C21FEBF59D52C6C058E42DF470E46E79585CA7974D1AA23A96B10B。原视频及双模式逐页截图已核验归档，完整表和来源见[两源视频判读](packet_diag两音源视频判读_20261008.md)。
- 判读：1DA80000；页3默认3300BB80/内部3B00BB80，6E00BB80/7E00BB80，8E000000/9E000000/AE000000，BE0061A8/CE001800。稳定计数窗输入/包内样本对/包数48000，F=E，所见错误0，内部幅值异常0，CTS25000/N6144。WAV A页不检查幅值；相等的样本/包数符合每包1组，不能用4组/包的12000预期判错。b与6段码已视觉复核。
- 两段短视频/已显示窗符合预期，先前声音干净/按键图片正常为用户反馈；没有完整PCM顺序、PHY/接收器波形、校准音质或实测时钟频率/长时证据。新观察器改变实现，旧杂音机制仍未证实。
- 已更新live.info.json、工程README、当前状态和专题入口；原用户反馈文件/310候选及211未完成检查点不改，源码/约束/DB/位流不改，无重新构建及代理板卡/TF/Flash操作。
- 下一步：无需再补录基线；保留成功位流，后续实际音乐TEST.WAV、换文件/碎片与长时验证。
