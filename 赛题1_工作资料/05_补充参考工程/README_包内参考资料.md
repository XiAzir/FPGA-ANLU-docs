# 补充参考资料

本目录收录从四个本机原始 ZIP 包中筛选提取的参考资料，供两仓 `main` 同级克隆后的资料查阅使用。原始 ZIP 保留在本机外置备份中，不随 Git 克隆提供；提取内容只作原厂参考，未改动、未导入或编译原厂工程。

| 来源包（本机外置备份） | 入库内容 | 入口 |
| --- | --- | --- |
| 设计参考文档.zip | 原包中 lab_ex_1～3 DOCX；lab_ex_4/5 与已跟踪文件逐字节相同，不重复复制。 | [lab_ex_1.docx](设计参考文档补充/lab_ex_1.docx)、[lab_ex_2.docx](设计参考文档补充/lab_ex_2.docx)、[lab_ex_3.docx](设计参考文档补充/lab_ex_3.docx) |
| HX4S20安装驱动文档.zip | 安装前提示 TXT、TD 安装教程 DOCX；不含驱动二进制或 license。 | [安装前先看这个.txt](TD安装与前置说明/安装前先看这个.txt)、[安路TD开发工具软件安装教程.docx](TD安装与前置说明/安路TD开发工具软件安装教程.docx) |
| HDMI环出实验.zip | HDMI 环出接收、发送、环回项目的源码、IP、MIF、约束、项目文件、仿真 testbench 和脚本；构建/仿真生成物已跳过。 | [TD 项目](HDMI环出实验/eg4s324_hdmi_loop/hdmi_loop/hdmi_loop.al)、[仿真 testbench](HDMI环出实验/eg4s324_hdmi_loop/hdmi_lvds_tx/source_code/tb/tb.v)、[环出说明](HDMI环出实验/eg4s324_hdmi_loop/loop_test.txt) |
| APUG011_high_performance_sdram_read_write_reference_design_v1.2.zip | SDRAM 参考项目、HDL/IP、I/O 约束、仿真 testbench 和脚本；PDF 已与已跟踪手册校验为同哈希，不重复复制。 | [TD 项目](APUG011_SDRAM参考工程/prj/sdram_as_ram.al)、[顶层](APUG011_SDRAM参考工程/source_code/rtl/top.v)、[仿真 testbench](APUG011_SDRAM参考工程/source_code/tb/tb.v)、[已跟踪手册](../02_关键IP与工具手册/APUG011_基于ERAM接口实现的高性能SDRAM读写v1.2.pdf) |

每个原始 ZIP 的 SHA-256、全部成员路径/大小/成员 SHA-256、提取或排除理由及目标相对路径见[来源与校验清单](包内参考资料来源与校验.json)。所有项目引用的文件均已检查存在：HDMI 项目 45/45，APUG011 项目 9/9。检查只验证归档文件与项目引用完整性，不代表使用 Tang Dynasty 或 ModelSim 重新打开、编译或验证了参考工程。
