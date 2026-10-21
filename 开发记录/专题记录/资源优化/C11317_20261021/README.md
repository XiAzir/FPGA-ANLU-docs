# C11317：结构复用资源优化

2026-10-21，北京时间。最终选择 A04，离线验证与封存已完成，实板验证待补。

## 最终结果

| 项目 | C11316 父版 | C11317 A04 |
| --- | ---: | ---: |
| Slice / 9800 | 7584（77.3878%） | **7231（73.7857%）** |
| Gate LUT / FF | 12815 / 7708 | 12528 / 7348 |
| Physical LUT / FF | 13708 / 7768 | 13151 / 7402 |
| Physical LE | 14461 | 13764 |
| BRAM9K / DSP | 45 / 9 | 45 / 9 |
| PLL / GCLK | 2 / 3 | 2 / 3 |
| Setup WNS | +0.649 ns | +0.415 ns |
| Hold WNS | +0.024 ns | +0.011 ns |
| Setup / Hold TNS | 0 / 0 | 0 / 0 |
| STA coverage | 99.98% | 99.98% |

本轮减少 **353 Slice**，占用下降 3.6020 个百分点。系统时钟、SDC、PLL、HDMI PHY、640×480 RGB888 帧存格式、FFT 精度与现有功能保持；SPI 继续 mode 3、12.5 MHz，初始化 100 kHz。

工程：`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_arch17`。

## 采用的结构变化

1. **一个 FAT 执行器服务两个独立文件上下文。** 将两份 mapper 与原仲裁器收敛为 `fat32_dual_file_sector`。BMP/WAV 各自保留文件身份、walk、Brent 检环、cache、请求握手和 watchdog；共用物理扇区执行、字节计数、FAT 字段提取及地址运算。每个 FAT/data 扇区后调度，BMP pending 时 WAV 最多连续两扇区。工作状态与完成缓存共用生命周期存储。生产工程删除退役的 `fat32_file_sector.v`、`sd_sector_arbiter.v` 及无用物理客户端 wire。
2. **RGB 解包缓存复用 FIFO 的保持输出。** 原 normal FIFO 在没有 read enable 时保持输出；reservoir 高半部分可由这份已有输出重建，本地缓存由 64 bit 降到 32 bit。字节对齐状态使用五种固定拼接；FIFO pop、像素、underflow、reset/clear 的逐拍行为保持。
3. **缩放器复用父层稳定头字段。** `HEADER_VALIDATED=1` 生产分支直接使用父 loader 已保持的宽、高、stride；默认 generic=0 分支保留原锁存行为。采用编译期专门化，新增运行时输入校验为 0。

最终 core SHA256：`084b7dc884b1b33e3ebc2804283bc820b0e5a38eb248e7dc14a6303d70f67bfb`。codec SHA256：`414a74a76a828b45f9baa2f0c56f5f80d5c6311b21001e309246d2f60a333552`。engine SHA256：`cde50900d2307674272134b2043c1cd26b53f1372fad913eef1b227a7f9706e2`。

## 消融结果

独立 TD 项目使用 EG4S20BG256、20 ns、AreaHigh + Adder18，相同输入/输出 wrapper；完成标志、实际参数与源码哈希均留存。独立数值与顶层数值分开记录。

| 独立实验 | LUT 前→后 | FF 前→后 | 结论 |
| --- | ---: | ---: | --- |
| 双 mapper 工作/缓存生命周期合并 | 2015→1849 | 569→381 | A01 中间实验；合并到 A02 后取得物理收益 |
| RGB 仅固定字节拼接 | 209→208 | 69→69 | 仅少 1 LUT，独立版本退出 |
| RGB FIFO 保持输出复用 | 209→176 | 69→37 | 采用 |
| 目录 dir_size / FAT entry 存储复用 | 1956→1973 | 710→686 | LUT 增加 17，淘汰 |
| BMP 生产头字段生命周期复用，完整 loader | 1868→1866 | 698→677 | 采用；BRAM4 / DSP5 保持 |
| 最终 084 共享 mapper 对照双 mapper + arbiter | 2029→1494 | 642→396 | 采用，减少 535 LUT / 246 FF |

| 完整顶层候选 | Gate LUT / FF | 物理结果 | 处理 |
| --- | ---: | --- | --- |
| C11317 A00，仅 Build ID / 工程位置 | 12929 / 7708 | 未跑 PNR | 同 ID 控制组 |
| A01，仅 mapper 生命周期合并 | 13023 / 7520 | 未跑 PNR | 对 A00 多 94 LUT、少 188 FF，继续组合测量 |
| A02，生命周期合并 + FIFO 复用 | 12654 / 7488 | 7383 Slice；+0.614 / +0.004 ns | 整机、gate/routed 审计和内部 bit 通过，保留 fallback |
| A03，B9 共享 core + FIFO 复用 | 12605 / 7369 | 未跑 PNR | 名义整机通过；由 084 参数边界修订取代 |
| **A04，084 core + FIFO + header 复用** | **12528 / 7348** | **7231 Slice；+0.415 / +0.011 ns** | **最终选择** |

A00 与 C11316 的差异包含 Build ID 常量及工程位置带来的全局映射变化。A03→A04同时包含 core 修订与 header 复用；77 LUT 的顶层变化按组合记录。单体节省值未直接相加推导顶层收益。

证据入口：工程 `build/ablation_summary.json`、`build/attempts/`，以及 `development/arch17_work/{mapper_lifetime,codec,codec_hold,catalog_storage,scaler_lifetime,shared_mapper}`。

## 功能与算法验证

- 最终完整 top：`build/system_fast_20261021_124327`，122 ms，12 个生产源码 override。实际编译副本另有 `compiled_copy_binding.json`，逐份内容与生产源/既定声明位置适配核对，原 `source_receipt.json` 保持夹具原始 SHA。
- 串行 HDMI 检查 1,536,000 RGB 像素、4,447 PCM 对；3 FFT 帧、72 bands，定点参考最大误差 0，实际可见柱体像素 2844。排除第一个完整冷启动视频帧。
- SD 共 58 扇区，CRC 58/0，音频欠载 0，prime 后 FIFO 最小 1023；数据 SCLK 80 ns。首帧 commit 95,044,989 ns，相对 C11316 增加 200 ns。共享版每客户端 service 从实际物理 issue 开始计时，原版从客户端物理 demand 开始计时，分别在性能 JSON 注明。
- 实际生产 FIFO 输出保持监视：627240 拍通过，其中 live high suffix 587197 拍。codec 独立差分 1000020 拍，486128 次 pop、748838 次像素消费、8 次 clear、全部 0..8 字节占用状态通过。
- mapper 独立并发主场景 4100 笔物理交易：4095 次 BMP FAT hop 后到 cluster4097，BMP 同 sector cache 重读，WAV sector0→1 cache 延续；WAV 连续服务最大 2。另测换文件/seek payload、bad FAT/EOC/loop/short、独立双 pending timeout、reset、disable/re-enable 排空及 valid/end 边界。reference 与最终 084 均通过。
- A01 生命周期中间版本另有全部 8 参数边界模式、3 种长链模式各约638万拍/12295扇区逐拍通过，保留为独立别名证明。
- scaler 默认 13 case、生产合法域 7 case、538 诊断、无复位32×24→17×13双图均通过。fresh 六图配对：191×321 top-down、320×240、512×128、800×600、640×480 native、800×599 odd；总 1,843,200 像素匹配 golden，160-bit loader 公共输出逐拍一致。证据 `scaler_lifetime/full_six/`；源码固定 C11316 baseline f3d77… 与候选 cde509…，同 loader 8c4c…，均 `HEADER_VALIDATED=1`。

## 共享核心修订与审计修正

- 6A 早期版本存在 watchdog 同拍派发覆盖、active disable 后快速重新启用的数据归属风险；B9 移动 timeout 优先级并使用原 C_DRAIN 保持 owner 排空。完整独立回归与 focused review 通过后继续审查。
- 对 B9 只推进旧 client 的 watchdog 到边界，可复现 C_IDLE 旧 owner 的 timeout 覆盖另一路新调度；084 将 C_IDLE 的 timeout 限于退役自身队列。自然 WAIT_LIMIT=1/2 双方均 timeout、无 orphan；默认50M下该老化计数器组合的可达性尚未证明，记录为参数边界。各版源码、报告和反例分别保存，未据此解释现场故障。
- 删除旧 arbiter 源后 TD 自动归一化 CompileOrder。首次 A03 综合工具完成，但 scope 门禁拒绝；仅固定该元数据后用原 guard 重建成功，保留拒绝证据。
- A02 routed parser 曾漏识别普通实例名；A04 又遇到 TD 复制状态 bit0。检查器补齐合法实例名解析，并对重复 FF 的完整参数、寄存器 lane、data a..e/有效 MI、clock/enable/reset/初始模式进行结构等价证明后才建立别名。独立六项负控（data、clock、reset、MI、REG_SD、SRMODE）均拒绝，原失败输出保留。生产 RTL、路由网表和 bit 未因检查器修正而改变。
- 最终门级实际 FFT 3帧/72bands零误差；gate/routed ROM各1536逻辑词、3072lane与192控制真值通过；routed时钟/引脚45 PASS、0 WARN、0 FAIL。原始 strict 六项 SIG/INV 参数差异仍记 FAIL，实际 LUT+极性证明单独记 PASS。
- 封存首次核对发现编译副本哈希回填改变原 source receipt。按夹具记录的 SHA `d09113c31fa4b4274f73ee07a296f8a4e8d793af70fe1814ff4b76635ca2ce2c` 恢复原字节，将派生绑定另存 JSON。失败冻结与随后元数据脚本修正前的验证草稿均保留在 `build/failed_freezes/`、`build/verified_freeze_drafts/`；最终入口使用下列 manifest。

## 交付与绑定

- 位流：`E:/VSCODE-project/FPGA-ANLU/download/spectrum_arch17.bit`，配套 `spectrum_arch17.info.json`。
- 位流 SHA256：`09cb0c482796cd2a7c113be8a7cd27e038646582db8be91ba0cce91e3e70d97a`。
- 冻结：`development/player_spectrum_arch17/checkpoints/C11317_arch17_20261021_offline`，**1809 文件**。
- manifest SHA256：`d9ac3d0354ed3c8c2f27044deff2ef1923bae0cf68010a19700bb34c89add169`。
- `build/final_binding.json` PASS：98 scope、12 override、1445 unit 证据文件、三份 bit 相同；原始/编译副本/夹具哈希、综合→物理→bitstream链、路由 artifacts、策略和全冻结清单均核对。
- synthesis `6a499e72-76a7-4cb8-b29e-06453b4eed42`；physical `4ef973d1-997c-4028-99b5-a7ec9d9d8c9d`；bitstream `2114fd9d-811d-4a22-8cb9-91da7cad9e2c`。
- 父 C11316 的169源码文件、500冻结文件及六份旧 download bit 保持。工程和资料均为本地留档，本轮未提交、push或操作硬件。

可机读交付信息见 [delivery_receipt.json](delivery_receipt.json)。

## 后续

用户当前无板，板测待补。现有整机证据使用 nominal PLL edge replay、数字 SD 与应用接口 SDRAM 模型（data领先valid一拍）；物理 SDRAM、完整 SDF、非名义时钟和实际按键切源仍待验证。有板后加载 C11317，记录 Build ID、冷启动、多图切换、声音/频谱、按键及持续运行；C11316与A02保留作回退。继续离线优化时以本次 A04 的完整组合和证据作为基线。
