## 2026-10-13 21:12:55 实板失败修正

用户反馈C11304在KEY1前后均黑屏无信号；两视频已抽帧，后视频可读DFC11304，音源A页变化、PCM源/输入CRC同F485（flag7），无格式错误。视频只拍数码管，黑屏来自用户描述。原本地PASS有效范围不变，候选状态改FAILED，旧bit/ZIP/325文件快照不改。C11305恢复C11206两份PHY文件、保留真实频谱，正在本地验证；尚未证明唯一原因。证据：工程build/board_failure_20261013。

# C11304 真实频谱柱候选

更新时间：2026-10-13 20:53:50（北京时间）。**C11304本地候选已交付，实板待验证；成功基线仍C11206。**

- [测试包](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_20261013.zip)；[操作卡](操作卡.md)。PROGRAM_SRAM/5MHz，D页须DFC11304；同卡/供电/HDMI默认音乐、KEY1内部音阶及回切、HOLD恢复；异常用包内bmp_scale.bit回退。
- 真实48kHz PCM→1024点Hann窗定点FFT→24段近似频谱幅值柱；低频在左、高频在右，柱快起慢落/峰值保持10帧。最终面板x16..623/y304..431、plot x128..511、pitch16/body12、高84行。VS后共享ALU49拍计算后原子提交，target双bank BRAM、level/peak/hold状态BRAM；冻结继续播放声音，恢复显示最新目标。
- 13合成1024点输入312段与独立定点gold零差异；direct DFT最大量化误差6.999；实际TEST.WAV两窗口48段零差异。最终650像素、实际PCM到renderer72段、4原子提交/5稳定窗口、同拍VS/frame_done、HOLD/恢复/peak/stale/source取消/reset均PASS；29输入SHA复核0差异。[模型结果](模型结果.json)。
- TD6.2.178840完整synthesis→physical→native fix_hold→bitgen通过且源码/脚本/数据库证据绑定；最终setup+0.557ns、hold+0.021ns、TNS0、coverage99.97%；16383LUT/9833reg/18049LE/44BRAM9K/11DSP/2GCLK。prehold HWNS-0.004/HTNS-0.008报告保留build/prehold；失败/超MSlice各轮也保留，未复用失败DB。
- eram_init on已配置；gate逐字重构1024 Hann/512 twiddle INIT与原始ROM零差异，[硬件初始化核验](系数硬件初始化核验.json)。HDL5314前端ROM warning与最终真实INIT的差异由最小探针实证；抽象BE警告在最终物理整字wea接口无BE端口，未做厂家全门级tone模型。
- 父C11303的user_source除waveform/两个ID源(3文件)外其余82文件继承；新增5文件(FFT、频带include、ROM两表、生成器)。两处build ID改为C11304，音频/FIFO/TF、PHY、PLL、引脚、SDC、3份al_ip字节一致；工程.al新增FFT并开启ERAM init，其他RAM初值与布局变化仍需此次实板回归。
- bit 680840bytes SHA256 `789913A1C0E332E3FB5ED73C55252BBECB1ABF7A1C19F7E3319AC56AE09EEB17`；ZIP655861bytes SHA256 `2E8F934195D94A96CB122922C5D41C16FA98E7C23378EC98338969578AD188A7`；candidate325文件SHA逐项通过，manifest `365ECA09CB3BB988FCA500519C45317661063EC24F5317E6DEC94B65F19C2A7A`。[交付凭据](交付凭据.json)。C11206、C11302/C11303源/位流/ZIP/原检查点保留。
- [音乐数据模型预览](音乐数据模型预览.png)由真实音乐与独立像素gold生成，非实板照片；视效参数为初值，观感、音质、真实卡/接收端、连续运行与冷启动均待反馈。未代理JTAG/TF写/Flash。内时序通过不证明HDMI外部电气裕量。

下一步：用户下载候选到实验室电脑，在相同条件按操作卡验证音画/两音源/HOLD及原集成功能；按实际观感微调，确认后再封存成功版本。当前仅本地交付通过。

---

2026-10-13 20:05（北京时间），用户已选定频谱柱并授权修改。以下为当时阶段记录；最终结论见页首交付摘要。

隔离工程 `E:/VSCODE-project/FPGA-ANLU/development/player_spectrum`；父源C11303 `player_music_envelope_phy`，继承四路完整字捕获/ODDR半周期数据准备。成功回退仍为C11206。旧候选位流、ZIP及检查点不改；本轮未操作JTAG/TF/Flash。

实现：实际送往HDMI核心的48kHz PCM/VALID只读分支；1024点定点FFT、Hann窗、每级/2，总归一/1024；单共享乘法器、同步RAM、24频段取各段max(max(abs(Re),abs(Im)))，是频段幅值近似而非功率谱。46.875Hz/bin，正频bins1..512，排除bin0；Hann使DC泄漏到相邻bin，不称DC全部消除。分析55,320个25MHz周期约2.21ms，与1024样本采集交替，推算42.5帧/秒；分析期间仅忽略观察支路新样本，不回压实际播放。

渲染：面板x16..623/y304..431，24柱15像素宽、21像素间距，柱高84行；对数幅值映射，VS快升(差值1/2)/慢降(差值1/8)，峰值保持10帧后每帧降2行且不低于柱顶。深色底/青色渐变/淡色峰值；SPECTRUM WAV/TONE或HOLD WAV/TONE；HOLD只冻结显示；切源在VS清柱/峰/冻结与标题；音频valid失联100ms后向零衰减。

模型已覆盖9组生产1024点输入、24段与独立定点/直接DFT参考，另有521主时钟/采样、连续帧、切源/复位中止。资源、综合、布局布线、时序、位流、完整像素/控制及真实音乐集成验证尚在进行。当前不能称整机候选通过或实板成功。

下一步：完成边界与像素模型、审阅RAM/DSP映射和整机资源；正式原约束setup/hold通过后生成候选、打包并SHA封存；由用户在同卡/供电/HDMI下检查画面、真实音乐与内部音阶、HOLD恢复。观感参数为初值，实板反馈后再调。

20:08综合阶段发现TD的readmemh相对路径优先以调用源文件目录解析，首轮../user_source/hdl_source路径使两个系数ROM未载入。已中止首轮(不计PASS/未出bit)，保留build/rejected_rom_path_2007日志与部分数据库，改ROM默认basename并从HDL目录跑模型；综合脚本新增HDL-5105/ROM无驱动拒绝闸门。重新完整综合，未沿用首轮数据库。声明mul_product顺序亦修正，算术不变；模型须按最终SHA重绑。

20:16第二轮推断4份FFT工作RAM失败并中止，保留build/rejected_rom_bram_mapping_2014。TD官方SWUG106与最小rom_probe证明：RAM属性应为bram；eram_init必须on；已找到的ROM仍出现HDL5314前端告警，但gate有正确非零BRAM INIT，所以单独no-driver告警不是ROM失败判据。探针对parameter/literal/explicit初始化都得到正确INIT；已将主RAM写端拆成单地址/单写独立always、使用bram/rom_style，开启工程和Tcl eram_init on，保留ROMnotfound/ignored-init拒绝条件。第三轮完整综合正在运行，最终必须核对全尺寸系数的gate INIT与实际RAM资源。两个中止尝试均不计PASS。

20:18第三轮完整综合完成、RAM映射41BRAM9K/11DSP，gate估计19628LUT略超19600；TD保存.al规范化造成scopeHash变化，证据闸门拒绝该轮。已留build/rejected_project_scope_font_area_2018，不跳过闸门。优化标题/legend字符间距为16/8像素(power2位选替代通用除法)并据此更新像素gold，用TD规范化后的.al做第四轮完整综合，最终资源与STA仍待验。13边界向量312band对fixedgold误差0、directDFT误差最大6.999；动态集成72band/528状态、390像素首轮通过，新字距需重新绑定。

20:33第四轮综合sourceHash认证成功，gate19555 LUT/9977reg/41BRAM/11DSP；布局PHY9009报MSlice5501超4900，未完成place/route、未生成bit。原DB/报告归档build/rejected_mslice_5501_round4。重构渲染为单ALU+18bit状态BRAM：VS抓完整ready target快照，在48计算拍后一次commit24根柱/峰/标题(25MHz下约1.96us，垂直消隐内)；源切换/复位24拍初始化私有state，front即时清零，HOLD不更新。FFT地址改stage固定拼接，10×512穷举与数学式全一致，analyzer与实际音乐回归已通过，新的控制模型/像素绑定与第五轮完整综合进行中。谱样式/高度公式不改；未删任何播放/OSD/诊断功能。

20:39第五轮gate17143LUT/10227reg/43BRAM/11DSP，primitive packing仍需MSlice5023>4900，失败日志DB保留build/rejected_mslice_5023_round5，未route/出bit。把频段target三份504bit寄存器及并行复制改为64×7双bank同步BRAM；band流写capturebank，完整frame_done翻readybank，VS只抓readybank/valid，串行ALU读取固定snapshotbank。analyzer帧间距(至少55320计算+1024采集拍)远大于49拍update，所读bank在此次更新内不会被下一下一帧覆盖；source/reset清valid并等待完整24段避免读旧表。算法/像素仍不变；gold据新存储结构重绑，第六轮综合进行中。初值RAM/原型probe未作为本轮板测。

20:43第六轮gate16616LUT/9732reg/44BRAM/11DSP，packing需要4908MSlice(超4900仅8个)，仍拒绝place/route。保留build/rejected_mslice_4908_round6。第七轮把24柱定位改power2：plot x128..511共384像素宽，pitch16/body12，LOW x128/HIGH x480；标题/面板/高度/渐变/峰值/数据算法不改。省掉24组48个横向比较器及优先选择网，最终需整机资源/STA确认；gold重新绑定新坐标。所有失败构建未生成/发布bit，成功基线C11206不动。

20:48第七轮综合通过且source/script证据绑定成功：gate16079LUT/9728reg/44BRAM/11DSP，全部1536个gate系数INIT逐字匹配。原约束place通过(约4745MSlice≤4900)，route进行中，未生成bit。最终renderer SHA91c239c2…，FFT1645b9fd…；模型29个输入SHA逐项复核0差异，650像素、72band集成与snapshot bank/目标字全程稳定、4次原子提交/5个front稳定窗口通过；真实音乐48band/合成312band exact。图形脚本基于实际音乐和独立像素gold生成本地预览，非实板照片。

- 黑屏后同条件回载C11206：用户确认画面和声音正常（本次新对照）。
