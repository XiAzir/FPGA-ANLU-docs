# 6.25→12.5MHz SPI可行性评估

**10:40实施完成：** C11315修复工作态分频参数被硬编码覆盖，明确配置12.5MHz；两速度参考对照及全链路离线核查通过，7632 Slice＝77.88%，Setup+0.157ns/Hold+0.011ns/TNS0。新bit已生成并冻结，新版本板测待补，详见[C11315实施记录](C11315_实施记录.md)。原C11314数据阶段已名义12.5MHz，前期仅依据top DIV2所作的6.25MHz判断已修正。

以下为2026-10-21 10:18原可行性评估记录：当时仅只读核查并新增独立mode3数字延迟测试，保持C11314源码与位流。

**10:30续查修正：** 用户授权实施后，真实SCLK监测揭示`sd_card_sec_read_write.v`的`S_WAIT_READ_WRITE`把`spi_clk_div`硬编码为0，覆盖top的DIV2。因此C11314工作态名义数据SCLK已为12.5MHz；前文根据顶层参数认定实际6.25MHz的判断需要更正。原独立mode3测试直接输入DIV2/0，其40/80ns结果保持。C11315现将工作态赋值修正为跟随参数、top明确选DIV0，并新增真正DIV2参考对照；这轮验证以实际SCLK与服务时间为依据。以下为原可行性分析及当时方案，最终实施结果另行追加。

## 交接资料与当前实现

- 用户提供的`ANLU_C11312_Resource_Agent_Handoff_20261020.zip`，`01_task/任务范围和优化顺序.md:57`明确将SPI升频列为独立后续课题；资源优化目标已在C11314以79.06%完成。
- 包内`04_reference/diagnostic_report_20261020.md`第4.1节要求核验512字节/LBA/CRC、token/整块等待、有效吞吐及BMP/WAV各自最长等待；指出按卡输出时延、板级延迟和FPGA输入时序建立预算。将这些作为本轮后续提速的验证依据。
- 当前`development/player_spectrum_resource_80/src/user_source/hdl_source/top_tf_hdmi_audio.v:450`实例为`sd_card_top #(.SPI_HIGH_SPEED_DIV(2))`。系统PLL的clk0与routed timing均为50MHz，公式`fSPI=50MHz/[2×(DIV+2)]`，DIV2为6.25MHz，DIV0为12.5MHz。
- `sd_card_top.v`默认初始化分频248，对应100kHz；高速值在初始化完成后切换。建议只改高速分频2→0，初始化参数、50MHz系统时钟和HDMI PLL保持。
- 实际实例CPOL=1/CPHA=1（mode3）。历史C11308延迟测试为mode0，故本次使用当前原样spi_master.v重新覆盖mode3。

## 本次独立测试

工程：`../../../../FPGA-ANLU/development/spi_rate_feasibility_20261021`；命令`pwsh -NoProfile -File development/spi_rate_feasibility_20261021/run.ps1`。原spi_master SHA `37F7A21144FA5CCA3CC5C3B5F68A5AD40B3108336B600E45A1367734AC61403C`，实际SHA以build/receipt.json为准。

两种分频×6个MISO延迟×256种字节值，共3072字节全双工，检查MOSI/MISO、每字节8个升沿/8个降沿、46080个边沿间隔。slave在每个下降沿后延迟更新MISO，mode3首个下降沿送bit7；延迟超半周期的组作为灵敏度反例。

|分频|SCLK|半周期|零误码延迟组|预期检出误码组|连续请求字节周期|
|---:|---:|---:|---|---|---:|
|2|6.25MHz|80ns|0/15/35/55/75ns，每组256值|85ns，256/256|1400ns|
|0|12.5MHz|40ns|0/15/35ns，每组256值|55/75/85ns，每组256/256|720ns|

2048个正向字节全部无误；1024个越界反例均检出MISO误码；3072个MOSI字节全部正确。测试脚本exit0并输出`PASS MODE3`。该模型为外部延迟参数扫描，实板总预算还需计入SCK输出、板线、卡tCO、返回板线、FPGA输入建立时间及偏斜。

## 收益与验证重点

- 理想连续线速上限由0.78125→1.5625MB/s。当前master逐字节接口的本测试周期为1.40→0.72µs，约0.714→1.389MB/s，提升约1.94倍；SD命令/token/CRC/FAT访问、卡内部等待、上层握手与音频竞争将影响整机收益。实际目标为缩短图片加载/切图等待，并增加音频服务余量。
- 旧SPI人工模型文档将0.72µs写为1.11MB/s，属于算术笔误，本次更正为1.389MB/s；旧实验波形和延迟结论保持。
- 采样半周期由80减为40ns。当前SDC注明板级SPI I/O延迟尚未表征，C11314的内部STA+0.633/+0.011ns用于内部路径结论。提速后单独核验外部读入预算；MISO按当前源同步采样机制分析，保留精简接口。
- 历史C11307曾使用12.5MHz，随后为排查图像/声音问题降至6.25MHz；其时多项后续HDMI/频谱问题尚在排查，现有记录未建立SPI速度与故障的单独因果。以当前功能正常的版本作同卡、同素材A/B对照。
- SD协会简化物理规范列出默认速度模式最高25MHz，可作为频率等级参考：[官方规范入口](https://www.sdcard.org/downloads/pls/)、[7.10版规范](https://www.sdcard.org/cms/wp-content/themes/sdcard-org/dl.php?f=Part1_Physical_Layer_Simplified_Specification_Ver7.10.pdf)。目标板输入预算仍按实际卡与连线核验。

## 建议的下一轮

1. 从冻结C11314建立独立C11315，仅高速分频2→0与Build ID更换，保持现有CRC观察和诊断。
2. mode3实际参数下跑SD命令/512字节/CRC、碎片文件与图声竞争回归，记录有效吞吐、token最长等待、各caller最长服务时间、WAV FIFO低水位/欠载、frame commit用时。
3. 同约束综合/P&R确认Slice继续低于80%、时序通过，按实际I/O预算审计MISO采样；独立生成12.5MHz bit。
4. 同卡同素材上板对照：冷启动、反复切图与轮播、WAV和频谱持续运行、CRC坏块与欠载计数及加载耗时。原C11314位流和新候选分别保留。

当前状态：可行性核查与mode3局部模型已完成；整机提速回归、TD与实板A/B待实施。本轮未改生产RTL/约束、未调用TD、未生成或下载新bit。
