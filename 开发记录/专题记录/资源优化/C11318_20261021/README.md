# C11318：按键事件接口资源优化

2026-10-21，北京时间。最终选择A01_key_events，离线封存完成，板测待补。工程：`../../../../../FPGA-ANLU/development/player_spectrum_ctrl18`。

## 结果与归因

| 项目 | C11317交付 | C11318同ID控制A00 | 最终A01 |
| --- | ---: | ---: | ---: |
| Slice / 9800 | 7231（73.7857%） | 7050（71.9388%） | **6972（71.1429%）** |
| Gate LUT / FF | 12528 / 7348 | 12140 / 7348 | 12062 / 7266 |
| Setup / Hold WNS ns | +0.415 / +0.011 | +0.630 / +0.019 | +0.110 / +0.004 |

最终相对C11317减少259 Slice，下降2.6429个百分点。按键结构改动相对同ID控制组实际减少78 Slice、78 Gate LUT及82 FF；控制组相对C11317的181 Slice差额来自版本常量/工程位置变化后的全局映射，分开记录。

最终Physical为12648 LUT / 7323 FF / 13243 LE，45 BRAM9K / 9 DSP / 2 PLL / 3 GCLK；Setup/Hold TNS均0，STA coverage99.98%。SDC、PLL、HDMI PHY/IP、FFT点数/精度、RGB888存储格式与SPI mode3/12.5MHz均继承C11317。

## 采用的变化

`player_adjust_control.v`保留物理按键同步/20ms消抖、单键长按、组合键优先、释放重臂、亮度/对比度VS提交，以及音调/频谱冻结动作。PLAY短按通过next/auto两条独立request/acknowledgement toggle发送；每键一个cooldown计数器取代原pulse/gap两计数器，保留一深pending合并。

`tf_bmp_file_player.v`取消对已经识别的合成按键电平再次进行50ms消抖，接收端双级同步请求、更新ack并产生一拍内部事件；loader主状态机与C11317逐字节一致。顶层连接四条req/ack线，两个端点使用共同复位。新增运行时输入校验0。

动作接受时间相对原二次消抖约提前50ms。加载忙闲边界附近的事件到达时点会相应提前；loader既有单比特next_pending合并策略继续生效。缩放模型中，连续三次短按合为两次，首个和合并后续的源端事件逐拍相同；测试参数下间隔201拍。生产参数对应5000001个25MHz拍（约200ms）的后续事件间隔。

最终controller SHA256：`17977380e33edc3844b98c207bc0435c584e2bcc628eff27e0c9adcd9d7e56ab`；loader SHA256：`e46169101374f6d28094d4ad408ff7f2b399908d0cb6fa30e613edebe5fe5ab4`。具体源差异在工程`build/source_delta.patch`与`build/selected_changes.json`。

## 消融与淘汰

| 候选 | Gate LUT / FF | 物理Slice | Setup / Hold ns | 处理 |
| --- | ---: | ---: | ---: | --- |
| A00 同ID控制 | 12140 / 7348 | 7050 | +0.630 / +0.019 | 控制 |
| A01 仅按键事件化 | 12062 / 7266 | **6972** | +0.110 / +0.004 | 采用 |
| A02 仅595同域化 | 12357 / 7276 | 未跑PNR | 未测 | 单项LUT增加217，保留证据 |
| A03 两项组合 | 12110 / 7194 | 7000 | +0.457 / +0.003 | 比A01多28 Slice，淘汰 |

595同域方案保留原驱动RTL，把scanner接到既有25MHz视频域以退出32bit跨域mailbox。独立双相位串行协议与页面碰撞测试通过；SCLK常规周期1020→1080ns，完整8位帧8.261760→8.277760ms（刷新约121.040→120.806Hz）。本轮最终保留原50MHz scanner/mailbox。

各轮源、综合数据库/报告、stage记录和实际参数保存在`build/attempts/`；A00/A01/A03均有物理报告。A01/A03分别通过完整整机，选中A01后按已认证源scope、脚本与数据库哈希恢复其synthesis/physical记录，再用原stage守卫生成bit。验证入口与门槛保持。

## 验证证据

- `development/ctrl18_work/key_events`：reference/candidate差分76项断言，覆盖抖动、短按、连击合并、next/auto交错与同拍请求、长按、组合键近阈值优先、编辑/VS提交、音调、冻结、共同reset及重臂。reference副本仅改模块名。异步10ns/14ns模型接收提前686ns（49个接收拍）；生产约50ms为按原消抖参数推算。
- `development/ctrl18_work/integration_audit`：真实loader+scaler实例35项检查，测试台仅为选择场景deposit内部状态，全部事件穿过实际sink。覆盖WAIT_CATALOG、IDLE、PAYLOAD忙态合并/自动播放、WAIT_DISPLAY完成与事件同拍、共同reset；next/auto共7/3个sink脉冲，reset后残留0。独立static审查通过168父源/1809冻结文件/7旧bit/36保护源/状态机字节及stage guard。
- 最终整机`build/system_fast_20261021_141358`：122ms，14份生产源override，1536000串行RGB像素、4447有序PCM对、3 FFT帧72频带最大误差0；可见频谱柱体像素2844。CRC58/0、欠载0；首帧95044989ns，全部已报数值性能字段与C11317相同。A03整机`system_fast_20261021_142507`亦通过，作为淘汰候选留证。
- 最终实际门级FFT3帧72频带误差0；gate/routed ROM1536逻辑词3072lane、各192控制真值通过；route时钟/引脚46 PASS、0 WARN、0 FAIL。原strict六项SIG/INV差异仍记FAIL，实际LUT+极性真值单独PASS。
- 时钟审计新增绑定top所选legacy/video架构与源scope；legacy两域mailbox检查保留，另验证SDC/PLL/IP/HDMI源字节。两架构错时钟、PAD错域、残留mailbox等负控均拒绝；最终使用legacy实网表46项通过。正式checker相对独立审查副本仅适配所在目录的根路径索引。
- 首次只读route导出因Windows反斜杠被TD解释而未生成网表，后续存在性检查拦截。修正传入Tcl路径为正斜杠，并要求export完成标志后重新导出/审计通过；失败日志保存在`build/audit/attempts/export_windows_path`。生产RTL/数据库/bit未受影响。
- 第一份已验证冻结草稿be7e7fd9保存在`build/verified_freeze_drafts/`。随后修正复用的性能定义说明：C11317与C11318均按shared mapper物理issue起点计时，重新绑定与冻结；采用下列最终manifest。

## 交付与复现

- 位流：`../../../../../FPGA-ANLU/download/spectrum_ctrl18.bit`，配套info.json。
- 位流SHA256：`68e3ad82238f6e10f3ef2c69de2b5f90a8aa2f66a7a5f313455c9c0372a61f24`，634280字节。
- checkpoint：`development/player_spectrum_ctrl18/checkpoints/C11318_ctrl18_20261021_offline`，2460文件。
- 最终manifest SHA256：`c4b413059787e94e330d34acf1e6736353df0c82a33fc2748ec91f214d88de08`。
- `build/final_binding.json` PASS：98 scope / 14 override / 2107 unit证据文件 / 三份bit相同，编译副本、原收据、夹具、综合→物理→bit阶段链与冻结文件逐项绑定。
- synthesis `99d7e67a-5594-480a-a2e2-1ef24b0e895c`；physical `532f1863-a4f4-4780-ac58-9ee57eac444e`；bitstream `bf9859c6-c73f-4c5c-8e36-4b1b03725c42`。
- 构建入口为候选`scripts/build_candidate.ps1 -Stage synthesis|physical|bitstream`；专用回归/绑定/封存在`development/ctrl18_work`，原参数、工具命令及输入哈希见各receipt。交付机读信息见[delivery_receipt.json](delivery_receipt.json)。

用户暂无板卡。整机采用nominal PLL replay、数字SD及应用接口SDRAM模型，排除首个冷视频帧；本轮按键忙态和595协议为独立模型验证。实板按键切源、物理SDRAM、完整SDF与持续运行待补。有板后加载C11318，确认Build ID、冷启动、连续/组合按键、多图、音源切换/频谱冻结及持续播放。C11317交付与旧位流保留；本轮未提交、push或操作硬件。