# C11319 视频播放集成

当前实现为 C04，位流已生成，主媒体选择 Q90。离线核验已通过，用户当前仍无上板条件，交付离线装卡包与后续板测清单。最新机器可读进度见 [progress.json](progress.json)。

## 已选实现

- 工程：`E:/VSCODE-project/FPGA-ANLU/development/player_video19`，Build ID `C11319`。
- 位流 SHA256：`2cc753d6cc2d241cc06e8ecb1e7b5bc86bc08eb99a6f074cba5ca5bf0791e430`。
- 20 秒素材取原片 16～36 秒，640×480、15 fps、300 帧；640×360 内容上下各补 60 像素黑边。
- 主媒体 JPEG420 Q90，视频帧缓存 RGB565；图片主线保持 RGB888。原声为 48 kHz / PCM16 / 单声道，960000 样本，经 HDMI 复制到左右声道。
- 时钟、PLL、SDC 与 SPI mode3 / 12.5 MHz 保持。C11318 源码、位流和既有冻结记录保留。
- [候选装卡包与操作说明](E:/VSCODE-project/FPGA-ANLU/deliverables/video19_c11319_20261021/操作说明.txt)。

## 实现结果与消融

| 实现 | Slice | Setup / Hold WNS | 结果 |
| --- | ---: | --- | --- |
| 初版视频 | MSlice 5613 / 4900 | packing 超量 | 保留失败证据 |
| C03 | 9548 / 9800，97.43% | −0.812 / −0.013 ns | 绿色通道长路径尚存 |
| C04 最终 post-hold | **9554 / 9800，97.49%** | **+0.289 / +0.024 ns** | Setup/Hold TNS 均 0，已生成 bit |

C04 是在 C03 上增加精确的两级弹性颜色流水，较 C03 多 6 Slice。32 位整数运算、截断、坐标、valid/ready 和 EOF 排空语义保留。Gate 为 17025 LUT / 9762 FF；物理实现为 17889 LUT / 9812 FF / 62 BRAM / 27 DSP / 2 PLL / 3 GCLK。pre-hold 的 −0.020 ns Hold 违例经路由后修复关闭，前后数据库和报告均保留。

此前已选入系数 RAM slot 预清、精确 IDCT/颜色常数、OUT17/TRANS21、并行 Huffman 与紧凑地址，退役重复诊断页及旧 snapshot/mailbox。读优先仲裁对照中，旧写优先在并发显示时复现 x256/y2 错误，新方案完整 307200 像素通过。DSP 化绿色表达式和受保护 HDMI FIFO 缩深均未选入。详细证据见 [进展索引](progress.json)和工程 `video19_work` 各实验目录。

## Q95 相位失败与 Q90 选择

显示刷新周期为 16.8 ms，15 fps 内容周期为 66.6667 ms。等待显示读帧边界再回收双 buffer，会使解码预算随相位变化；相位约每 63 帧重复，模型最短窗口约 50.133 ms。

| 编码 | JPEG 平均码率 | 最大 JPEG | 有效画面软件 PSNR | 实际链路证据 |
| --- | ---: | ---: | ---: | --- |
| Q95 | 4.6103 Mbps | 43231 B | 45.633 dB | 良好相位最大帧 52.481 ms；原 62/63 帧短窗回放出现迟帧 |
| **Q90** | **3.3165 Mbps** | **31115 B** | **43.904 dB** | 最大帧 41.525 ms；50 ms 短窗通过，余量 8.475 ms |

Q90 的分辨率、帧率、片段和原声保持一致。MJP 扇区封装加 WAV 文件共约 4.1767 Mbps。主 MJP SHA 为 `239a413b3fc9462ab362918177f3e62e7069f10559281815e7c3198457525c31`，WAV SHA 为 `30eaf10a6ff1800163cecb3225cce685873b38c9a8e42635f1e5c92b0e95b5de`。

Q95 实际相位消融为 [run203329](E:/VSCODE-project/FPGA-ANLU/development/player_video19/build/video_system_20261021_203329/summary.json)：`AUDIO_PHASE=780`，137.8885292 ms 触发 `frame_late`，已输出 583424 像素。Q90 为 [run203750](E:/VSCODE-project/FPGA-ANLU/development/player_video19/build/video_system_20261021_203750/summary.json)：`AUDIO_PHASE=800`，205 ms、3 commits、2 个不同显示内容帧、6446 个原声样本全部匹配，欠载 0 / 迟帧 0。这两项均为隔离相位注入的整机应用模型测试。原始失败及 Q95 素材保持。

## 验证证据

- [颜色流水](E:/VSCODE-project/FPGA-ANLU/development/video19_work/color_pipeline/README.md)：原 C03/A08 对照与候选 frame000/109/299 逐字节精确；输入 gap、随机背压、abort/reset、三类系数夹具及末像素 8 拍停顿/EOF 排空通过。
- [照片与原声/FFT](E:/VSCODE-project/FPGA-ANLU/development/video19_work/photo_regression/runs/photo_system_20261021_200426/summary.json)：307200 像素写/读，6378/4447 PCM，3 FFT 帧 / 72 bands 误差 0。
- [Q90 全片 reader](E:/VSCODE-project/FPGA-ANLU/development/video19_work/cadence_analysis/README.md)：300 帧、回环与 reset 重播，共 302 帧长度/CRC、16755 个 LBA 全匹配独立原 MJPEG；随机 gap/BP、empty tail 与 error 传播通过。
- [当前实际 gate FFT](E:/VSCODE-project/FPGA-ANLU/development/player_video19/build/gate_verify/input_manifest.json)：3 帧 / 72 bands 误差 0；gate 与最终 post-hold routed 系数 ROM 均为 1536 逻辑词 / 3072 lane 逐字匹配。
- [最终 routed 审查](E:/VSCODE-project/FPGA-ANLU/development/video19_work/final_route_audit/README.md)：四个 ROM 严格参数逐项匹配，6 控制 pin × 32 状态共 192 行真值通过，28 项时钟检查通过。
- [HDMI 串行引脚](E:/VSCODE-project/FPGA-ANLU/development/video19_work/video_pin_scoreboard/README.md)：338 ms，5813228 个串行恢复像素与匹配全局帧号的最终 AXIS 队列一致，12830 个原声 PCM 样本逐一匹配；四个源帧逐坐标对照独立 C03 JPEG 核，帧缓存读回对照其 RGB565 量化参考，三个不同内容完整帧通过，BCH/TERC 错误 0。RGB 与 PCM 翻位负控均精确检出错误。
- [真实 SDRAM 控制器](E:/VSCODE-project/FPGA-ANLU/development/video19_work/physical_resume/final_result.json)：C04 实际 gate + APUG011 IS42s32200 引脚模型，Q95 标准前缀负载 221 ms，通过 921600 像素 / 3 commits / 2 个不同显示帧 / 6408 原声 PCM，欠载 0、迟帧 0；约 709 ns 启动阶段 5 条命令/hold 诊断原样保留，1 us 后模型错误 0。状态 PASS_AFTER_STARTUP_TRANSIENT，无 SDF。
- [源与阶段绑定](E:/VSCODE-project/FPGA-ANLU/development/video19_work/combined_area/C04/final_source_binding.json)：当前源、脚本、四构建阶段、数据库、位流及照片/Q95/Q90/physical 编译副本和独立 HDMI reference，共 961 项文件哈希及阶段链接核对通过。

全片 302 帧证据属于 reader 字节流与扇区序列；整机数据/像素验证采用上述指定帧与场景。当前使用名义 PLL 重放及数字模型，实板的 20 秒原声循环、按键和持续播放待用户具备硬件后完成。

## 交付与后续板测

主包目录 `E:/VSCODE-project/FPGA-ANLU/deliverables/video19_c11319_20261021/` 包含位流、Q90 VIDEO.MJP、原声 TEST.WAV、PC 预览、操作说明、第三方许可和交付校验凭据；同名 zip 为便携包。下载入口为 `download/video19.bit`，冻结位置为 `development/player_video19/checkpoints/C11319_video19_20261021_offline`，文件清单见 checkpoint manifest 与包内 delivery_receipt。

用户有条件后，按操作说明加载 SRAM、装 FAT32 TF 卡，核对数码管状态页 00C11319，再执行完整 20 秒原声同步、回环、暂停/重播、返回图片和持续播放。名义 PLL/数字 SD/应用模型及器件模型已分别验证；完整 20 秒整机解码、实体 TF/SDRAM/HDMI、SPI 板级 I/O 延迟与 SDF 待后续验证。当前无上板、写卡、Flash、提交或 push 操作。

## 最终封存凭据（2026-10-21 21:10）

- checkpoint：3430文件，manifest SHA256 `b7259ba867b930231194942784d40dd1808475155a860a2a9ebe901879d2d920`。
- zip：11649855字节，SHA256 `002dbe02cc30bc6f647a1ca20e5d42678949bbad9fa6ff499895c219519ded15`，CRC与包内文件SHA全通过。
- live与冻结源码/构建脚本逐文件一致，下载/包内/checkpoint三份bit一致；最终绑定961项PASS。
- 全部子任务已结束；后续依赖用户具备板卡/TF条件执行实物清单。
