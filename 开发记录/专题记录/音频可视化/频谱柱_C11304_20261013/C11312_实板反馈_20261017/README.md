# C11312 2026-10-17 实板反馈

本版实板异常，根因未定。用户在家远程开发，板卡在实验室同学处；本机未操作硬件。

## 现场证据

- `before_key1.mp4`、`after_key1.mp4`、`display.mp4` 是用户原视频的逐字节副本，SHA/时长/原路径见 `video_manifest.json`。
- 用户反馈：画面有绿色条带、频谱无柱、音频播放有噪音；回载基线正常。本轮不再重复要求基线对照。
- 父代理抽帧确认显示屏彩色条纹/方格、黑白UI及空频谱。杂音仅为用户反馈，未直接听取或量化。
- KEY1前17.5秒及后续重复轮次的固定版本页显示 `5FC11312`，源码应为 `DFC11312`，见 `version_word_17p5.png`。其他固定页头也改变：B→3、C→4、A→2、9→1、8→0，部分有效标志8→9，并有多处280000字段。不能只补回bit31后解码。
- `raw_transcription.json` 保存原始八位字、秒数和严格解码器的拒绝结果。它们不能当作可信FFT内部状态。KEY1后部分裁切/字形不确定，不强行拼成七页有效快照。

## 本机核查结果与边界

1. 595驱动、跨时钟邮箱与C11309/C11310对应RTL字节一致；未见新的译码/端序改动。C11312 routed两PLL的全部显式参数与C11309 routed、C11206 gate相同；这不证明板上实际时钟/抖动正常。
2. 从C11312最终routed网表提取邮箱destination至三根595引脚的闭合依赖锥：101个原厂原语（含3 PAD），未重新综合或替换算术。逐位闭合无未解析观察输入；共包但未观察的另一lane可悬空，外部边界的共包输出断至dummy。理想50MHz、全局reset副本和32位数据是测试输入，不含上游实际启动/时钟生成。
3. ModelSim SE-64 10.1c，原厂EG4模型与独立glbl，-novopt。43组正常向量（版本、全8、自检、七快照字、32位walking-one）及1组串行翻位负对照，总352位校验；正常零错误，负对照恰检出1错。未缩短生产扫描/移位分频，不force下游寄存器。
4. 同一最终物理DB只读导出SDF，保留101个cell、489项内部/输出连线和150项输入边界连线的原始延时。SDF成功反标，固定DFC11312八位正确；38项负时序限被ModelSim置零，因此只算有边界的延时测试，不是完整STA/SDF或电气验证。SDF日志沿用TB通用的“no SDF”旧banner；实际启用与成功反标以vsim -sdfmax命令及加载记录为准，后者确实使用SDF。
5. 完整C11312 routed顶层另补D页：七个快照字及DFC11312均正确到destination_hex。沿用受控PLL ready、快速启动、切tone/观察总线故障注入，以及全部page重复Q的force；未复现自然启动现场。

日志、提取/复跑脚本及机器结果在工程 `development/player_spectrum_trace/build/board_feedback_20261017/`。`verification_result.json`记录结果和日志SHA。

## 下一步：实验室先核文件和下载日志

暂不换bit或重复录相同页。请同学在实验室电脑检查**BitWriter实际下载的那份文件**，不要拿另一份包里的文件代替：

```powershell
.\check_lab_bit.ps1 -BitPath '实际下载的 spectrum_trace.bit 完整路径'
```

脚本只读文件，输出路径、大小、SHA及是否匹配C11312；不连接设备、不烧录，也不验证芯片内配置。预期634280字节，SHA256 `60AE6B971CE1F9ED09D76BEC14CF88DFC25CDFE7CBBEBE5DD9FC070115B812CE`。

同时保留该次BitWriter完整窗口/下载日志（所选文件、器件、PROGRAM_SRAM、JTAG频率、成功或错误信息）。若文件/下载一致，下一步需要独立于当前损坏显示链的现场观察，例如现有C11312的DIO/SCLK/RCLK逻辑分析仪采集，或经验证可用的JTAG内部采集。当前未确认实验室具备相应仪器/远程访问，不把这些操作写成已执行。

本轮未改生产RTL、旧bit/ZIP或冻结检查点，未发布新bit。诊断数据损坏可能来自上游数据、实现/配置、时序或外部传输，不能据本轮仿真宣称已排除或确定其中某项。

## 下载日志追加核查

用户随后提供三次完整下载片段，已保留bitwriter_user_log.txt。均识别EG4S20BG256，jtag/jtag_burst，bit_to_vec实际freq=5.000000 MHz（-spd 7不能读作7MHz），约15秒后Downloading succeeded，无所提供片段内报错。路径../../anlu/bit/spectrum_trace.bit是相对BitWriter工作目录，当前无法仅凭日志解析为实验室绝对路径。

结论：工具报告下载完成，没有证据要求继续反复下载。用户暂不能运行脚本，实验室文件SHA仍待核，不阻塞对已有证据的分析；日志没有显式逐字节配置读回比较记录，不能把成功提示等同于配置读回或功能通过。下一阶段仍需独立硬件观察，故障根因未变。

## 20:35 实验室文件哈希确认

用户截图确认E:/anlu/bit/spectrum_trace.bit为634280字节，SHA256与交付C11312完全一致，MatchesC11312=true。截图laboratory_bit_sha256.png及结构化laboratory_file_verification.json已保全。至此，所检实验室文件的版本拿错/复制损坏不再是未核项；三次下载日志也已报告成功。没有芯片配置读回证据，不能据此证明板上运行正确。

用户确认同学只有AL-LINK，无外接逻辑分析仪。下一步先离线核查ChipWatcher可实施性，接续10月11日source-IP断言、gate插入资源/自动1ns约束失败证据，避免原样重复；现有普通C11312位流不能凭空读任意FF。尚未构建或交付新调试位流，未要求用户重复下载/录像。

## 20:44 仅AL-LINK条件下的配置回读路线

只读审计复核旧C11105 ChipWatcher source-IP物理断言、gate新增hub自动1ns约束时序失败，没有找到已证实可用的绕过方式；本轮未重建/交付ChipWatcher，不把旧失败当当前C11312根因。

本机原厂SWUG110确认Verify SRAM和Read Save SRAM，SWUG111要求含调试核的bit才能采集任意内部信号。已从与冻结manifest一致的C11312最终DB隔离bitgen -gen_mask生成配套bmk，参考bit除Date注释4字节外与原bit完全相同；配置负载一致，原bit/旧ZIP/DB未改。交付c11312_sram_verify_mask_20261017.zip仅bmk/说明/证明，不含新bit。ZIP SHA a9052161463689a659a49bdbce322e7f9b2c618c6eae613ef5db756e1ac598bd，CRC及掩码成员SHA通过。

重要边界：离线jtag_rdbk向量转换虽成功，但仍报0 masked bits，尚未验证GUI是否正确装载bmk；错误mode/参数探测均留日志，不当通过。未运行program/download命令或连接板卡。下一步实验室在板内为C11312时选择Verify SRAM并发完整日志；要核对是否支持/装载掩码及实际比较，不能以普通Download成功替代。通过也不覆盖用户ERAM或运行/物理时序。详见配置回读校验说明.md。
