# C11316 继续离线资源优化

状态：2026-10-21，离线优化与交付完成，实板验证待补。用户暂时无上板条件；C11315 作为已冻结父基线保留。

C11316 最终 **7584/9800 Slice＝77.3878%**，相对 C11315 减少48个Slice、1个DSP；Setup +0.649ns、Hold +0.024ns，Setup/Hold TNS均为0，STA coverage99.98%。媒体行为和已测性能保持逐拍一致。

| 项目 | C11315 | C11316 | 变化 |
|---|---:|---:|---:|
| Slice | 7632（77.8776%） | 7584（77.3878%） | -48，-0.4898个百分点 |
| Gate LUT / FF | 13054 / 7791 | 12815 / 7708 | -239 / -83 |
| Physical LUT / FF | 13896 / 7864 | 13708 / 7768 | -188 / -96 |
| LE | 14571 | 14461 | -110 |
| DSP / BRAM9K | 10 / 45 | 9 / 45 | -1 / 0 |
| Setup / Hold WNS（ns） | +0.157 / +0.011 | +0.649 / +0.024 | +0.492 / +0.013 |

位流：[spectrum_opt16.bit](E:/VSCODE-project/FPGA-ANLU/download/spectrum_opt16.bit)，配套 [info.json](E:/VSCODE-project/FPGA-ANLU/download/spectrum_opt16.info.json)。位流SHA256 `1de561dda1428c86c2f3127cf55b4b391cae8598c51111394ef9bde0ee971afa`。

冻结目录 `development/player_spectrum_opt16/checkpoints/C11316_opt16_20261021_offline` 共500文件，manifest SHA256 `cb4730c01a5eb5ccc4503d7df4c0e847e538b1db846f926bce2eb66bd1dc3fb1`。绑定结果：[final_binding.json](E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_opt16/build/final_binding.json)，交付摘要：[delivery_receipt.json](delivery_receipt.json)。

父基线：7632/9800 Slice（77.8776%），Gate LUT13054/FF7791/DSP10；Physical LUT13896/FF7864/BRAM45/DSP10；Setup +0.157ns、Hold +0.011ns、TNS0。父位流 `download/spectrum_spi12p5.bit` SHA256 `a9de55c166cd730db1203fc9d1d882eee885237cec68fd389dad26d0d972e22f`。

## 已完成的单项消融

| 改动 | 功能证据 | 独立综合结果 | 选择 |
|---|---|---|---|
| FAT 解码临时值改28位wire | BMP101/WAV111边界各13344拍、长链各约638万拍/12295扇区逐拍一致 | 2015LUT/569FF保持 | 无收益，拒绝 |
| 595显示计数器精确宽度 | 默认参数52000拍输出一致 | 127LUT/84FF保持 | 无收益，拒绝 |
| BMP image/row手工共享乘法 | 7有效/6异常逐拍一致；6图1843200像素golden通过 | scaler1062→1047LUT，352FF保持，DSP5→4；全top13359LUT/7790FF/DSP9，相对C11315增加305LUT、相对同ID控制组增加316LUT | A01封存，淘汰 |
| BPB四组固定16位字段改4个valid flag | 15非空组合各逐拍差分；最终geometry1970/names525记录，含MBR/VBR、短长扇区和坏字节组合 | 独立fresh TD：2003→1956LUT、773→710FF、generic1265→1234 | 合入最终组合 |
| BMP已验证生产调用域省去重复检查 | 默认0通用13case、参数1合法7case、538诊断逐拍一致；786432组几何边界核查；6图1843200像素golden与160位loader可观察输出逐拍配对通过 | 完整loader2064→1868LUT、699→698FF、DSP6→5 | 合入最终组合 |

详细证据分别在工程 `development/opt16_work/{mapper,small,catalog,scaler}`。A01 全top结果封存 `development/player_spectrum_opt16/build/attempts/A01_shared_multiplier`。单体面积和全top资源分别记录，最终选择依据全top Slice、时序与完整功能回归。

另有同C11316 Build ID、仅版本常量与工程路径变化的A00控制组：Gate13043LUT/7791FF/DSP10；最终组合相对A00减少228LUT/83FF/1DSP。A00与A01仅做综合消融；最终组合完成P&R。目录单体首轮批量TD的后续项目出现同20ns重复时钟告警，最终全字段候选已用独立fresh TD重跑，无该告警，采用其1956/710资源结果。scaler独立工程模板调试曾触发TD open_project崩溃与项目名不匹配，换用既有成功模板并修正项目名后，基线/候选均重新成功综合；这些失败尝试未进入交付流程。

## BMP 生产调用域优化条件

生产loader在完整512字节HEADER与CHECK后才发出scale_start，接受宽1..1024、高1..768且pixel_offset+stride*height<=file_size的BMP24。这些字段在PAYLOAD期间保持稳定。stride=ceil(3w/4)*4>=3w，行r<h、列c<w、分量k<=2，因此每次访问满足pixel_offset+r*stride+3c+k<pixel_offset+h*stride<=file_size。完整范围校验已覆盖逐行/逐字节的检查。

scaler新增编译期HEADER_VALIDATED参数，默认0保留通用模块行为，仅生产loader明确设置1。省去S_IDLE尺寸、S_SETUP完整extent、S_ROW_CHECK行溢出、S_BYTE字节地址溢出/越界四组重复判断；通用默认模式及短长扇区、file_error等传输诊断保留原行为。最终整机将增加被动header稳定、范围和start先行条件断言。

## 最终验证与绑定

- 新工程 `development/player_spectrum_opt16`；3份算法RTL、2份Build ID与项目路径变化，其他当前scope保持。SPI mode3、初始化DIV248/100kHz、高速DIV0/12.5MHz、PLL/PHY/SDC保持父版本设置。
- 122ms整机 `build/system_fast_20261021_111126` 通过：1536000串行RGB、4447对PCM、3FFT帧72bands误差0、2844个可见频谱bar像素；CRC58/0、欠载0、FIFO最低1023、SCLK80ns。所有SPI性能字段与C11315相同，包括首帧commit95044789ns；header契约starts1/rows480/bytes770通过。
- 门级FFT3帧72bands误差0；gate/routed ROM1536逻辑词、3072lane entries相符，各192行控制真值通过；routed时钟/引脚45 PASS、0 WARN、0 FAIL。原strict报告6项SIG/INV差异完整保留，实际前级LUT与极性组合的32状态证明通过。
- 独立SD CRC回归5块、2次故意损坏均检出；fault snapshot77项通过。最终unit证据166文件，封入checkpoint；500文件冻结清单、99 scope、11个整机override、manual/download/checkpoint三份位流哈希绑定通过。
- synthesis `ec6c76a1-fe11-4a53-baae-41e0e5e1be43`；physical `aef7acca-be50-4426-9d6f-aef5bf4764b0`；bitstream `4a0690ac-f488-44b3-836e-60926fb38c9c`。
- 父C11315的169源码/脚本/仿真文件、324冻结文件以及5个旧download bit逐项SHA保持。本轮没有提交、push或上板。

整机使用标称PLL边沿回放、数字SD与应用层SDRAM模型；物理SDRAM、完整SDF和实板运行待补。后续具备板卡条件时，检查C11316 Build ID、冷启动、多图切换、音频、频谱、按键和持续运行；C11315仍可回退。
