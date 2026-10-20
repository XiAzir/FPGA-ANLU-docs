# 双分支同步与文档整合（2026-10-20）

本轮在 `main` 同步整合 `XiAzir` 的最新开发记录与证据说明。已解决文档冲突并保留两侧有效内容；`AGENTS.md`、资料清单及专题记录等均保留通用入口和最新记录。活动说明采用同级双仓相对路径，历史日志、冻结脚本及证据中的本机路径维持原貌。

新机入口明确 C11206 为已通过功能基线、C11312 为最新实板故障排查对象，并链接到 C11312 现场反馈与补验记录。协作约定明确两仓分支成对维护、每轮功能与记录同步、跨布局受控合并并审阅差异。工程仓与资料仓的 CNB Git Sync 均按来源分支独立配置 push 目标：`main` 设置 `settings.branch=main`，`XiAzir` 设置 `settings.branch=XiAzir`，各自 push 镜像至远端同名分支。

## 整合与本地核验

- 工程main候选：`90bcf15386d18d63b501237b242b4e5828b79115`，合并原XiAzir全部开发；main原有便携入口保留。96个频谱scripts/sim文件适配仓库、WAV、TD、Icarus与Python路径；13个新活动TD工程根Path归一。历史系统综合输入和冻结快照保留。
- 原XiAzir的21714个工程路径全部保留，main原13163个路径全部保留；合并阶段8563个近期归档路径保持原始blob。后续只调整明确列出的当前脚本/活动.al；HDL、所有checkpoints、位流和视频的原始字节保持。
- 42份历史manifest全部校验通过；335个历史.db/.vvp引用缺失0。见[冻结完整性](冻结完整性.json)。
- 87个PS1解析、47个Python AST、37个Tcl路径静态核查通过。迁移目录故障快照77检查通过，频谱13组/312频带/最大定点误差0；[TD导入68源文件通过](TD工程导入.log)。这些是文件/局部模型/工程导入验证，实板故障事实仍保留。
- 两仓YAML解析通过，main与XiAzir分别配置同名branch目标，沿用原secret引用和认证方式。原设置只在main push时触发，插件未指定branch时默认同步全部分支；依据[官方Git Sync说明](https://cnb.cool/cnb/plugins/tencentcom/git-sync/-/blob/main/README.md)。本轮显式按分支触发与同步，避免个人分支更新滞后。

## 发布与接续

首轮整合发布完成，CNB与GitHub四个ref均已通过git ls-remote逐一核对：

| 仓库 | main | XiAzir |
| --- | --- | --- |
| 工程 | e3c37f27db431446950c841fca89405f4636842a | ae9e1fda878426087fa6fd7b9c199300ca5c6c1b |
| 资料（首轮发布，随后追加本核验记录） | 332541e12366229da28dacb72442639275960908 | 4caad8c0f03c33e804251da979c3da147dbfd34c |

两仓main均为XiAzir祖先；工程main...XiAzir独有提交数0/2，资料首轮为0/1，差异为受控回整合提交及有意保留的布局。工程56个差异文件仅AGENTS/活动.al根/共享工具资料根/跨仓Markdown链接；资料12个差异文件仅个人入口、路径约定和跨仓链接。两分支HDL/checkpoints/bit/ZIP/JSON及资料视频/图片保持一致。

独立克隆验证：工程21725文件（含1个pyc）、资料1029文件全部逐Git blob SHA1匹配；42个manifest全量通过。入口链接103个相对目标均存在，未见活动入口绝对文件链接。clean clone与原机器默认资料根[环境检查通过](环境核查.json)；clean clone[故障快照77项通过](故障快照模型.log)、[频谱13组通过](频谱模型.log)、TD导入68源通过。测试过程中产生的tracked run.log已恢复为原始归档字节，新的输出独立保存在本专题；原始归档日志全部保全。

原目录继续使用XiAzir，工程E:/VSCODE-project/FPGA-ANLU、资料E:/QQ CACHE/Download/安路资料；新机器按两仓main同级布局接续。每轮整合先审查路径差异并验证main，再回整合XiAzir并保留个人入口与资料根；同轮同步两仓，并核对CNB/GitHub同名ref。当前收尾记录随资料两分支提交发布，最终ref以Git提交图及本日末条日志为准。
完整独立克隆与保护文件比对见[机器核验报告](独立克隆核验.json)：工程checkpoints7680/HDL8061/bit228/ZIP30，以及资料21个MP4/166图片均与原XiAzir一致，含C11302/C11312六份现场视频。
