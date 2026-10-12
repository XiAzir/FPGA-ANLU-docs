# SRAM 配置读回校验核对

核对日期：2026-10-11。范围：本机 TD/BitWriter 文档与静态文本；未启动下载流程，未连接/操作 AL-LINK，未触碰 Flash。

## 结论

- BitWriter 手册明确列出 `Verify SRAM`（BitWriter 下载模式栏，印刷页 19；PDF 第 20 页）：用于回读校验配置 RAM；原文：“不包含用户 ERAM 数据”。这能比对配置 RAM 内容，不能证明外部 SRAM/用户 ERAM 数据正确，也不能把“DONE”状态当作逐位内容校验。
- 同页前一节 `Program SRAM` 是把位流写入 FPGA 配置 RAM，掉电丢失（印刷页 18；PDF 第 19 页）。不要把它与 `Program Flash` 混淆。
- `Control Option` 的 `security` 会“禁止回读配置 RAM 数据”（印刷页 7；PDF 第 8 页）。因此，要先确认当前位流/器件安全设置允许读回；本次手册检查无法确认候选位流的该设置。
- 手册未给 `Verify SRAM`/`Read Save SRAM` 列出具体器件兼容表，且全文未提 EG4/EG4S20。结论只能是工具文档提供该功能，**不能据此确认它在 EG4S20BG256 上一定可用**。也未做实板验证。
- 手册没有说明 `Verify SRAM` 是否暂停、复位或以其他方式影响当前运行；不应承诺无扰。其定义是回读校验，但运行影响无文档证据。

## GUI 名称与相邻能力

- BitWriter 下载模式栏：`Verify SRAM`（读回校验）；`Read Save SRAM`（将配置 RAM 数据读回并保存为帧格式文件；印刷页 21，PDF 第 22 页）。`Refresh` 只读取器件 ID（印刷页 11，PDF 第 12 页），不是配置内容校验。
- ChipLinker 的 SVF 生成选项：`Check Status Done`（印刷页 35，PDF 第 36 页），且印刷页 37（PDF 第 42 页）说明它检查 Status Done 寄存器、检测器件是否已进入工作模式（Done 为高）。这不是 `Verify SRAM`，不能证明配置内容逐位一致；它先生成 SVF，需由外部 JTAG/SVF 执行工具运行，手册未描述该检查对运行态的影响。
- AL-Link BitWriter 的 TCK 下拉速率：16、8、5、3、2、1 MHz，以及 500、200 kHz（印刷页 18，PDF 第 19 页）。手册解释这是 TCK 频率。ChipLinker 生成 SVF 的 `Frequency` 另为 100 kHz–10 MHz（印刷页 30–31，PDF 第 31–32 页），不可与 BitWriter 下拉选项混为一谈。
- 项目工具约定记录已用 `PROGRAM_SRAM`、AL-LINK、5 MHz 下载整板测试位流；5 MHz 是下载 TCK，不是 FPGA 视频/运行时钟。参见 `E:/QQ CACHE/Download/安路资料/开发约定/工具与工程验证.md`。

## 安全边界

当前候选比较可优先考虑 BitWriter 明确标注的 `Verify SRAM`，但实际是否适用 EG4、security 是否阻止回读、以及是否影响运行均未由现有文档完全闭环。操作前必须确认界面当前动作名确为 `Verify SRAM`；禁止误选 `Program Flash`、`Erase Flash`、`Program SPIBIN`、`Dual Boot` 或任何向 SPI/Flash 写入或擦除的选项。本次未执行任何硬件动作。

## 来源

1. 本机 TD 6.2.1_SP1_6.2.178.840：`C:/Anlogic/TD_6.2.1_SP1_6.2.178.840/doc/SWUG/SWUG110_BitWizard_User_Guide.pdf`，版次页标 2024.12。关键印刷页 7、18–19、21–23、30–37；对应 PDF 第 8、19–20、22–24、31–37、42 页。
2. 资料目录副本：`E:/QQ CACHE/Download/安路资料/赛题1_工作资料/02_关键IP与工具手册/SWUG110_BitWizard使用指南_v1.1.pdf`，版次页标 2024.12。已抽查并确认上述 `Verify SRAM`、security、TCK 速率和 Check Status Done 条目一致；另在印刷页 37（PDF 第 42 页）找到 DONE 高低说明。
3. EG4 数据手册 `DS300_Eagle_EG4系列数据手册_v3.9.6_官方.pdf` 未找到 SRAM 配置回读能力的专门说明，因此不能补足器件适用性证据。



## GUI 入口与离线支持信息（补充）

### 文档能支持的操作顺序

1. 已打开 BitWriter 主界面时，模式位于文件列表上方的 `Mode` 下拉框；当前已有候选 bit 文件行时不需要先去其他菜单找“Verify”。主界面布局见印刷页 18（PDF 第 19 页，图 4-10）。
2. 在该 `Mode` 下拉框选 `VERIFY_SRAM`（印刷页 19，PDF 第 20 页，图 4-12）。图中这个操作只展示模式栏。
3. 点左侧工具栏的 `Run` 执行当前模式（工具栏说明印刷页 12，PDF 第 13 页；主界面也见图 4-10）。随后看底部状态/进度栏（印刷页 23，PDF 第 24 页）。

手册没有单独给 `Verify SRAM` 的完整逐步操作页，也没有明确说明它是否把当前 bit 文件行作为比较基准；因此以上只确认“Mode 下拉框 → `VERIFY_SRAM` → `Run`”的界面入口，不扩写文件行关联机制。手册截图明确区分：`PROGRAM_SRAM`、`VERIFY_SRAM`、`PROGRAM_FLASH` 都是同一个 Mode 下拉框选项；只能确认选中前看清模式名。

### `bw_commands_prompt` 静态核查

- 安装目录有 `bin/bw_commands_prompt.exe`，但未启动。没找到随包独立的、能离线给出 EG4 兼容列表的命令帮助文本；不运行二进制无法证明 `--help`/`-help` 不会初始化下载器。
- 安装文本 `doc/config/config.json` 全局列出 `VERIFY_SRAM`，把它映射到 `x_rdbk`；各 `Device` 项只有数字键和 `Mode_List` 数字，文件内没有器件名映射。因此它证明该安装版定义了 SRAM Verify 模式，**不能静态证明 EG4S20BG256 被列入支持该模式的器件**。
- 本次不运行 `bw_commands_prompt` 的任何命令，不连接下载器。主代理静态检查 bitgen console/AL 没找到 security 文本；这只能记为“未找到相关文本”，不能据此认定当前候选未启用 security。
