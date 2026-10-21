# 安路 C11312 资源优化｜本地 Agent 交接包

**编制：2026-10-20｜状态：交接资料，未执行新综合、修改RTL或生成位流。**

## 一句话使用方法

把本 ZIP 解压到一个**英文短路径**（例如 `E:/ANLU_Handoff`），向本地 Agent 发送 `PROMPT_直接交给Agent.txt` 的全部内容，告诉它本地两个仓库路径。Agent 应先检查两仓 `AGENTS.md`、当前Git状态和历史构建报告，然后在**隔离副本**中开始资源优化。

## 必须给 Agent 的实际输入

| 优先级 | 材料 | 用途/备注 |
|---|---|---|
| 必需 | `FPGA-ANLU` **完整工程仓库** | RTL、IP、TD `.al`、SDC/ADC、仿真、编译脚本；仅此 ZIP 无法重建项目 |
| 必需 | `FPGA-ANLU-docs` **完整资料仓库** | AGENTS、协作约定、已验证状态、板卡约束和日志 |
| 必需 | **本交接 ZIP** | 提示词、资源基线、模块排序、验收矩阵、解析工具、已有诊断 |
| 构建时需要 | Anlogic TD **6.2.1_SP1_6.2.178.840** 或已验证兼容版本、有效许可 | 新机克隆不会自动提供工具/许可；版本变化必须记录 |
| 单元测试时需要 | PowerShell 7、Icarus Verilog (`iverilog`/`vvp`)，部分用例需要ModelSim/厂商模型 | 如果某工具不可用，必须清楚报告未执行测试范围 |
| 可选（仅需板测时） | AC601+AC201实板、AL-LINK、原TF卡、已知良好供电、HDMI显示器 | 不属于本轮离线瘦身必需；没有明确授权不得下载、写TF、烧Flash |

### 两仓来源

- 工程仓：https://github.com/XiAzir/FPGA-ANLU
- 资料仓：https://github.com/XiAzir/FPGA-ANLU-docs
- GitHub 本次只读核查锚点：工程 `main@e3c37f27db431446950c841fca89405f4636842a`；资料 `main@64b76fd95ed759c28704de22e2fb2829b2b851a9`。
- 另有两仓 `XiAzir` 分支；应成对使用同名分支。`main` 默认**同父目录**：`FPGA-ANLU/` 和 `FPGA-ANLU-docs/`；维护者 `XiAzir` 保留私有本机路径布局。**不得为了适配本包而强制reset/checkout。**
- 当前 `main` 稳定已上板基线：`development/player_bmp_scale` / **C11206**，bit `download/bmp_scale.bit`，不可破坏。
- 本轮优化输入：`development/player_spectrum_trace` / **C11312**，板端已报告异常，且诊断数码管亦不可靠。**不等于修复基线。**

## 文件索引

- `PROMPT_直接交给Agent.txt`：可直接复制粘贴，授权 Agent 在隔离副本中主动实施资源压缩、测试、构建、留档；不授权硬件/发布操作。
- `01_task/任务范围和优化顺序.md`：优化目标、先后顺序、子系统约束。
- `01_task/验证矩阵与停机条件.md`：功能回归/负例/时序/保护的可检查标准。
- `01_task/需要读取的仓库文件.md`：源文件与报告路径、优先检索顺序。
- `01_task/Agent_输出报告模板.md`：每轮结束必须输出的数据字段。
- `02_data/resource_baseline.csv`、`hierarchy_C11312.csv`：基于存档报告整理的结构化基线。
- `02_data/source_provenance.json`：来源和固定版本锚点，复核是否发生新提交。
- `03_tools/resource_compare.py`：Python标准库**只读**读取本地TD报告，输出对比表；不会重新编译，也不能代替时序或硬件测试。
- `03_tools/preflight_readonly.ps1`：PowerShell 7只读检查Git状态、目录和可用工具；**没有自动clone或改动**。
- `04_reference/diagnostic_report_20261020.md`：此前的全链路诊断和720p评估（只读历史资料）。
- `04_reference/local_agent_playbook_20261020.md`：此前的故障诊断工作手册（不替代本轮优化任务书）。
- `SHA256SUMS.txt`：交接包内各文件SHA-256。

## 交接包的范围说明

- **没有**包含两仓完整RTL/IP/受保护HDMI核、TD数据库/原始bit、原TF素材、工具安装程序或许可证。那些必须使用本地仓库/授权工具；避免拿老版本源码副本覆盖当前项目。
- `.csv` 中的资源统计是**历史编译结果**，不是本包产生的新跑分；本地Agent需核实同源报告并重新编译候选。
- `route.qor`是**route阶段**报告，不一定反映修复后Hold；最终setup/hold使用 `build/manual/AC201_tf_hdmi_phy.ts` 与源/DB/阶段证据对应。
- 资源改善不能自动证明C11312已修复；不能把局部仿真通过写成实板通过。

## 快速只读检查示例

```powershell
pwsh -File ./03_tools/preflight_readonly.ps1 -CodeRoot 'E:/VSCODE-project/FPGA-ANLU' -DocsRoot 'E:/VSCODE-project/FPGA-ANLU-docs'
python ./03_tools/resource_compare.py --code-root 'E:/VSCODE-project/FPGA-ANLU'
```

注意：示例路径仅作为用法说明，维护者可能把资料仓放在其他位置；按本机实际传参。若Python命令在Windows上不可用，可以使用 `py -3`。
