# 两仓双分支同步（2026-10-23）

归档C27启动故障分析、C28 HDMI/图片观测、C29媒体流观测及用户三模式声画正常反馈，含源码、脚本、诊断录像提帧、分析结果、位流、两份交付ZIP与资料记录。

- 工程main：4d46bc38deff8af1600406a064fd0003c7d09047；XiAzir：08f9c680。两分支已推送CNB，main为XiAzir祖先。
- C28/C29各126项原始输入SHA通过；两份ZIP的CRC与收据逐文件SHA通过。最终gate/pr四份数据库SHA分别匹配综合及hold阶段收据，并精确纳入Git忽略例外。
- main两份活动.al入口Path改为`.`，原始入口分别保存到同工程verification/original_project.al，供原始阶段输入哈希核对。XiAzir原始入口保持本机路径。历史JSON、位流与交付ZIP保留原始字节。
- 资料main链接按同级FPGA-ANLU和FPGA-ANLU-docs布局转换；XiAzir保留本机布局。两分支开发内容受控整合，保留目录差异。
- 本轮工程新增1114项归档文件（含四份最终数据库），main另含两份原始入口快照；初始普通新增1110文件约140.69MiB，单份均小于50MiB。
- 本轮仅Git归档与文件一致性核查，无新构建、仿真或硬件操作。C29声画正常依据用户反馈；往返切换、重播、冷启与长时稳定性待后续验证。

归档核查见[JSON](归档核查.json)。CNB工程/资料四分支推送成功；首轮GitHub资料两分支ref已匹配，工程镜像尚在等待。最终远端结果在本轮回复说明。

## 远端核对完成

2026-10-23，本轮工程CNB/GitHub main=4d46bc38deff8af1600406a064fd0003c7d09047、XiAzir=08f9c680d6458c2cedac2d2f7df8a0d287e166c3逐项一致；资料CNB/GitHub main=ed87400177af9cc9fdf310c76c20a12dc73d0916、XiAzir=a3a51bd10c7816ac67840daa938fca2d46e25962逐项一致。两仓当前检出XiAzir、工作区干净，main均为XiAzir祖先。随后仅追加本收尾记录，最终资料提交号以远端ref为准。发布完成；无强推。
