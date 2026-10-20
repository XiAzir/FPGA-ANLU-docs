# C11206 五项扩展验收总表

整理日期：2026-10-12。本表归集已有实现、模型、构建、用户反馈与实拍证据；本轮没有重新构建或新增板测。实际录入时间见[归集凭据](整理凭据_可移植.json)。

整理日期：2026-10-12。本表归集已有实现、模型、构建、用户反馈与实拍证据；本轮没有重新构建或新增板测。实际录入时间见[归集凭据](整理凭据.json)。

**现状：五类扩展已在同一C11206设计中实现，所要求功能获用户总体正常反馈；波形带两项已知显示问题。验收资料归集完成，G4逐项动态演示和最终封版尚未完成。** 当前无需重复已经确认的普通功能测试。

## 1. 版本与支持范围

| 项目 | 当前保留范围 |
| --- | --- |
| 成功位流 | [bmp_scale.bit](<E:/VSCODE-project/FPGA-ANLU/download/bmp_scale.bit>)，C11206，629624字节；SHA256 `C60464C0D4396D316DB7622E4CB0B70B5DE12C25148AFE234AC7C795C818625D` |
| 已验证快照 | [bmp_scale_20261012_verified](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/manifest.json>)，268项；manifest SHA256 `71F87A4B82F974092F63102E0D7522B6C5577BD367B6789C6AD0DDDA37A76FB7` |

| 成功位流 | [bmp_scale.bit](E:/VSCODE-project/FPGA-ANLU/download/bmp_scale.bit)，C11206，629624字节；SHA256 `C60464C0D4396D316DB7622E4CB0B70B5DE12C25148AFE234AC7C795C818625D` |
| 已验证快照 | [bmp_scale_20261012_verified](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/manifest.json)，268项；manifest SHA256 `71F87A4B82F974092F63102E0D7522B6C5577BD367B6789C6AD0DDDA37A76FB7` |
| 输出与缓存 | 固定640×480，名义像素时钟25MHz，800×525总时序；紧凑RGB888帧缓存，RGB各8位。名义时钟与时序来自实现，未独立测量显示器识别的刷新率 |
| 文件系统 | 只读FAT32、512字节扇区；MBR的0x0B/0x0C主分区或直接VBR；根目录短名目录项，最多4张BMP，音乐为精确短名`TEST.WAV`。目录扫描顺序不保证按文件名排序；根目录上限256簇、单文件上限4096簇 |
| 图片规格 | 24位未压缩BI_RGB，宽1..1024、高绝对值1..768，支持正/负高度、行padding；FPGA加载时最近邻等比适配，居中补边。范围是RTL支持规格，本轮实板只验证下表四尺寸 |
| 音频规格 | RIFF/WAVE PCM16、48kHz、单声道，复制到HDMI左右声道；解析fmt/data块与填充，按data长度循环；可切内部音阶。当前音乐是60秒天ノ弱片段，不是直接解码m4a |
| 参数与图层 | 参数作用于底图，之后叠加图片状态OSD、运行计时/滚动字幕、参数OSD和PCM波形。补边也属于底图，非默认亮度/对比度时可随调节变色 |
| 硬件与配置 | 板卡与AL-LINK在远控实验室电脑；当前SRAM临时下载。LED和数码管是诊断辅助，不代替功能、音质和长期证据；Flash固化待做 |

源码入口：[当前top](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/src/user_source/hdl_source/top_tf_hdmi_audio.v>)。像素路径为底图→亮度/对比度→静态OSD→动态字幕→参数OSD→波形→HDMI；波形另观察送给HDMI的`audio_valid/audio_left_data`。同位流功能由此连线及当前正式构建绑定，而非用不同bit拼接功能。

源码入口：[当前top](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/src/user_source/hdl_source/top_tf_hdmi_audio.v)。像素路径为底图→亮度/对比度→静态OSD→动态字幕→参数OSD→波形→HDMI；波形另观察送给HDMI的`audio_valid/audio_left_data`。同位流功能由此连线及当前正式构建绑定，而非用不同bit拼接功能。

当前不列入支持表：GPT/exFAT、子目录/长名解码、JPEG/PNG/MP3/m4a硬件解码、双声道WAV/其他采样率、热插拔、FFT、双线性、交叉淡化、720p/1080p、ES8388音频输出。可选增强不阻碍当前保留范围收尾。

## 2. 五项扩展与验收状态

E01–E05沿用原规划的功能类别；TC编号按原计划详细用例正文映射。`TC32`是可选增强用例，不算作擦除或最近邻首版已通过项。照片可证明静态外观；动态过程和声音采用对应用户反馈，不把两种证据互相替代。

| 编号 / 用例 | 同位流实现及操作 | 已有证据与当前结论 | 尚缺的展示证据 / 保留项 |
| --- | --- | --- | --- |
| E01 动态字幕；TC16，静态OSD另见TC15 | 图片序号/总数、MANUAL/AUTO；RUN运行分钟秒与底部`FPGA MEDIA PLAYER`滚动。随播放运行，切图仍显示；RUN是运行计时，不是WAV播放进度 | 当前源码与正式构建绑定；C11204组合测试明确正常，C11206总体功能反馈正常；当前四照片有文字外观。**功能反馈通过** | 当前同bit连续滚动、计时变化和边界裁剪的完整影像待最终演示保存；早期失败版字幕视频不作成功证据 |
| E02 连续转场；TC20 | KEY0下一图、KEY1自动轮播均保留自上而下擦除；每显示帧推进8行，480行共60次更新 | C11205地址/RGB888/后端握手模型与用户转场反馈；C11206继承读侧逻辑并获总体正常反馈。**首版功能反馈通过** | 当前版转场过程动态影像、忙时快速触发的实板专项记录待补；没有实测动画/加载耗时。读请求受理ACK不能写为整帧读完ACK |
| E03 多尺寸FPGA缩放；TC09、TC21 | 根目录原尺寸BMP由FPGA解析并等比适配640×480；用KEY0或AUTO切换四测试图 | 当前六帧1843200像素完整loader逐像素gold及错误/背压模型；四张原始实拍布局与方向符合预期，用户功能正常。**四尺寸首版实板通过** | 最大规格、其他受支持素材、异常文件/换卡/碎片实物矩阵待验证；仅最近邻，不承诺平滑插值 |
| E04 实时参数及OSD；TC17、TC18 | KEY0长按轮转PLAY/BRI/CON；编辑模式KEY0减/KEY1加；双键长按恢复B+00/C1.00并回PLAY。RGB饱和裁剪至0..255，参数在VS边界提交 | C11201定点/控制模型及用户反馈、C11204明确组合回归；当前控制/运算/OSD源继承并绑定C11206，当前总体反馈正常。照片可见默认值。**功能反馈通过** | 当前各档/极值画面与数值变化影像待补；默认值照片不单独证明参数生效和极值无溢出 |
| E05 真实PCM波形；TC19，冻结为本项目附加操作 | 观察实际HDMI输入PCM；WAV、TONE及HOLD状态；PLAY双键短按冻结/恢复，声音继续。PLAY长KEY1切音源并解除冻结 | 祖先波形/冻结模型，用户曾明确音乐随音、弱音接近平线、音阶方波、HOLD消除双线；C11204组合通过，C11206总体通过且四照片可见WAV波形。**功能通过，显示质量有已知项** | 动态双线、HOLD消失，唯一成因未确认；128组×横向4像素、纵向57级，锯齿/清晰度优化待做。当前版静音/音阶/HOLD连续对照影像待最终演示归档；不是FFT频谱 |

本版用户原话：**“看起来没什么问题，功能也验过了没问题”**，记录于2026-10-12 14:06；解释范围来自上一轮操作卡。它是总体现场功能反馈，没有逐项过程、次数或时长。照片与C11206的关联来自对话上下文，未独立读出板上build ID或回读位流。不能补造当前逐项测量；[原反馈与照片](../../图片缩放/多尺寸最近邻首版_20261012/验收记录.md)保留原始边界。

## 3. 当前四图证据

| 素材 | 原尺寸与方向 | 模型规定的输出 | 当前实拍 |
| --- | --- | --- | --- |
| SCALE1.BMP | 320×240，bottom-up | 640×480铺满 | [IMG 1/4](../../图片缩放/多尺寸最近邻首版_20261012/实板照片/scale1_320x240.jpg) |
| SCALE2.BMP | 800×600，bottom-up | 640×480铺满 | [IMG 2/4](../../图片缩放/多尺寸最近邻首版_20261012/实板照片/scale2_800x600.jpg) |
| SCALE3.BMP | 191×321，top-down，padding3字节/行 | 285×480，左右黑边177/178像素 | [IMG 3/4](../../图片缩放/多尺寸最近邻首版_20261012/实板照片/scale3_191x321_topdown.jpg) |
| SCALE4.BMP | 512×128，bottom-up | 640×160，上下黑边各160像素 | [IMG 4/4](../../图片缩放/多尺寸最近邻首版_20261012/实板照片/scale4_512x128.jpg) |

输出尺寸与黑边数来自规格/黄金模型；照片作宏观范围、颜色布局和方向对照，受透视、摩尔纹和叠加遮挡影响。照片处于B+00/C1.00默认参数。素材原文件哈希见[交付素材清单](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/delivery/media_manifest.json>)；这是交付文件哈希，未重新读实验室TF卡。音乐包参考SHA见[音乐包审计](<E:/VSCODE-project/FPGA-ANLU/deliverables/real_music_20261008.package_audit.json>)，同样不等于本轮实物卡哈希。

输出尺寸与黑边数来自规格/黄金模型；照片作宏观范围、颜色布局和方向对照，受透视、摩尔纹和叠加遮挡影响。照片处于B+00/C1.00默认参数。素材原文件哈希见[交付素材清单](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/delivery/media_manifest.json)；这是交付文件哈希，未重新读实验室TF卡。音乐包参考SHA见[音乐包审计](E:/VSCODE-project/FPGA-ANLU/deliverables/real_music_20261008.package_audit.json)，同样不等于本轮实物卡哈希。

## 4. 统一操作表

长按阈值为1.5秒，实际操作保持约2秒后松开；短按在消抖后的松开时触发。两键组合先同时按下并形成重叠，最后两键都松开，避免分别触发单键动作。

| 模式/动作 | KEY0短按 | KEY1短按 | 长按/组合 |
| --- | --- | --- | --- |
| PLAY | 下一张，带上下擦除 | MANUAL/AUTO切换 | KEY0长按→BRI；KEY1长按→WAV/TONE并解除冻结 |
| BRI | 亮度降低一档 | 亮度增加一档 | KEY0长按→CON |
| CON | 对比度降低一档 | 对比度增加一档 | KEY0长按→PLAY |
| PLAY双键短按 | 两键重叠短按并松开：HOLD/动态切换 | 同左 | 只冻结波形；音频继续 |
| 任意模式双键长按 | 两键持续按约2秒 | 同左 | 恢复亮度/对比度默认并回PLAY；不是整机所有状态复位 |

亮度九档：−64、−48、−32、−16、0、+16、+32、+48、+64，默认0；对比度五档：0.50、0.75、1.00、1.25、1.50，默认1.00。按到边界停在极值。运行时无需改TF文件。当前没有音乐暂停按键，波形HOLD不等于暂停播放。

## 5. 证据来源与可复核入口

| 证据层 | 入口 | 用途与边界 |
| --- | --- | --- |
| 当前构建/封存 | [验收凭据](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/build/acceptance_verified.json>)、[已验证info](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/manual/AC201_player_bmp_scale.info.json>) | C11206位流和268项快照对应；正式SWNS+0.628ns/HWNS+0.004ns/TNS0，coverage99.97%；15031LUT/8803reg/28BRAM9K/8DSP/2GCLK。STA范围限制仍保留 |
| 当前缩放模型 | [gold凭据](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/scaler_validation_receipt.json>)、[范围说明](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/verification_scope.md>) | 六帧逐点检查，四错误控制模型目标32×24；实际pack/backend/FIFO压力4096像素，max_used481。主机逻辑扇区/mock writer，不是实物TF或加密SDRAM长稳 |
| 继承模块一致性 | [父源审计](<E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/parent_source_audit.json>)、[本次证据索引](证据索引_可移植.json) | C11206对C11205为79源不变/5改/1新；本次选定三扩展/读侧擦除源与祖先verified逐项字节比较。相同源不是物理实现等价证明 |
| 祖先参数/三扩展 | [C11201反馈](../../图像实时调节/亮度对比度首版_20261012/board_feedback.json)、[C11204组合反馈](../../三扩展集成/C11204验收_20261012/feedback.json) | C11204原话“已补测，以上都正常”；是祖先版本明确组合反馈，不串写为C11206逐项测试 |
| 祖先转场 | [C11205验收](../../图片转场/上下擦除首版_20261012/验收记录.md)、[转场模型范围](<E:/VSCODE-project/FPGA-ANLU/development/player_transition_wipe/checkpoints/transition_wipe_20261012_verified/build/model/verification_scope.md>) | 四图擦除/AUTO/两音源等用户反馈“都没问题”；旧模型非C11206重跑，动画时长未测 |
| 祖先波形/冻结 | [波形专题](../../音频可视化/真实PCM波形首版_20261012/README.md)、[动态/HOLD反馈](../../音频可视化/真实PCM波形首版_20261012/keyfreeze_board_feedback.json) | 形状关联、动态双线/HOLD消失及用户暂留决定；旧重影照片不贴成当前版媒体 |
| 当前现场反馈 | [C11206反馈](../../图片缩放/多尺寸最近邻首版_20261012/board_feedback.json)及上述四照片 | 同位流总体功能正常反馈与缩放外观；没有补造计时长稳或每项动态媒体 |

封存模型文档中的“实板待验证”是构建时历史快照；当前实板状态以新反馈和live验收凭据为准。原verified/candidate/ZIP不改写。每个引用文件的当前路径、类别、字节数与SHA，以及源码继承比较，已记录在[证据索引](证据索引_可移植.json)。

| 当前构建/封存 | [验收凭据](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/build/acceptance_verified.json)、[已验证info](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/manual/AC201_player_bmp_scale.info.json) | C11206位流和268项快照对应；正式SWNS+0.628ns/HWNS+0.004ns/TNS0，coverage99.97%；15031LUT/8803reg/28BRAM9K/8DSP/2GCLK。STA范围限制仍保留 |
| 当前缩放模型 | [gold凭据](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/scaler_validation_receipt.json)、[范围说明](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/verification_scope.md) | 六帧逐点检查，四错误控制模型目标32×24；实际pack/backend/FIFO压力4096像素，max_used481。主机逻辑扇区/mock writer，不是实物TF或加密SDRAM长稳 |
| 继承模块一致性 | [父源审计](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/checkpoints/bmp_scale_20261012_verified/build/model/parent_source_audit.json)、[本次证据索引](证据索引.json) | C11206对C11205为79源不变/5改/1新；本次选定三扩展/读侧擦除源与祖先verified逐项字节比较。相同源不是物理实现等价证明 |
| 祖先参数/三扩展 | [C11201反馈](../../图像实时调节/亮度对比度首版_20261012/board_feedback.json)、[C11204组合反馈](../../三扩展集成/C11204验收_20261012/feedback.json) | C11204原话“已补测，以上都正常”；是祖先版本明确组合反馈，不串写为C11206逐项测试 |
| 祖先转场 | [C11205验收](../../图片转场/上下擦除首版_20261012/验收记录.md)、[转场模型范围](E:/VSCODE-project/FPGA-ANLU/development/player_transition_wipe/checkpoints/transition_wipe_20261012_verified/build/model/verification_scope.md) | 四图擦除/AUTO/两音源等用户反馈“都没问题”；旧模型非C11206重跑，动画时长未测 |
| 祖先波形/冻结 | [波形专题](../../音频可视化/真实PCM波形首版_20261012/README.md)、[动态/HOLD反馈](../../音频可视化/真实PCM波形首版_20261012/keyfreeze_board_feedback.json) | 形状关联、动态双线/HOLD消失及用户暂留决定；旧重影照片不贴成当前版媒体 |
| 当前现场反馈 | [C11206反馈](../../图片缩放/多尺寸最近邻首版_20261012/board_feedback.json)及上述四照片 | 同位流总体功能正常反馈与缩放外观；没有补造计时长稳或每项动态媒体 |

封存模型文档中的“实板待验证”是构建时历史快照；当前实板状态以新反馈和live验收凭据为准。原verified/candidate/ZIP不改写。每个引用文件的当前路径、类别、字节数与SHA，以及源码继承比较，已记录在[证据索引](证据索引.json)。

## 6. 任务状态与后续入口

| 计划任务 | 本次整理后的状态 |
| --- | --- |
| T29/T30 | 四尺寸最近邻首版本地验证及实板反馈通过，保持已封存结论 |
| T32 | 640×480同位流五扩展实现、正式布局布线及总体功能反馈已有；集成表/操作映射/版本证据本轮整理完成，显示器实际识别模式记录待最终补证 |
| T33/G4 | 五类实现/功能反馈已归集并有TC映射；逐项动态展示证据、当前参数效果对照仍不足，**完整演示签核待补**。不据五类RTL数量宣称5/5正式闸门完成 |
| T36 | 保留范围草案：基础文件播放+这五类扩展；波形已知项继续列入。显示优化/验证尚未结束，**最终功能冻结与RC封版未执行** |
| S5 | FFT、高清等可选增强默认不安排；无须等它们完成才能继续S6验收封版 |

下一步按[后续验证清单](后续验证清单.md)收尾：计划先独立优化波形分辨率与线条，再对通过版本安排长稳/异常回归及一次连续五扩展演示。质量优化可以跳过，C11206带已知项也可直接补证与验收；现有普通功能反馈不重置。优化版是新候选，须保留C11206回退并做相关回归。最终Flash、报告和视频使用同一最终版本。

旧版回退：C11205 `transition_wipe.bit`只能配原四张640×480 BMP，须恢复电脑备份素材后再下载；当前多尺寸素材不能用于评判旧版。详细步骤见[已验证操作卡](../../图片缩放/多尺寸最近邻首版_20261012/已验证操作卡.md)。

规划依据：[执行规划](<E:/VSCODE-project/FPGA-ANLU/planning/20261007/执行规划.md>)、[原方案任务与TC正文](<E:/VSCODE-project/FPGA-ANLU/planning/20261007/source/安路赛题一_开发到提交规划_20261007.md>)。它们是内部执行依据；本表不新增主办方门槛或评分结论。

## 通用分支路径复核

本页通用路径与当前文本哈希于 Git 接续审查中静态重核，详见[可移植整理凭据](整理凭据_可移植.json)和[可移植证据索引](证据索引_可移植.json)。路径以工程仓根为基准，跨资料仓使用同级相对路径；本轮不增加实板、音频或长稳结论。[原始索引](证据索引.json)与[原始整理凭据](整理凭据.json)保留当时的路径和 SHA，供历史对照，当前链接/文本以通用视图为准。

规划依据：[执行规划](E:/VSCODE-project/FPGA-ANLU/planning/20261007/执行规划.md)、[原方案任务与TC正文](E:/VSCODE-project/FPGA-ANLU/planning/20261007/source/安路赛题一_开发到提交规划_20261007.md)。它们是内部执行依据；本表不新增主办方门槛或评分结论。
