# APUG092 GitHub 镜像

来源为用户指定仓库 `czp-1-A1/FPGA_Component_Inspector`，固定提交 `f87ccf1c6a38e84b58a4f86cecd532a71ae56e89`，下载日期 2026-10-04。保存对应目录的全部 17 个文件（约 5.75 MB），检查 Git blob SHA-1 与 SHA-256，未修改原始源码。

- [APUG092 手册 DOCX](<E:/QQ CACHE/Download/安路资料/赛题1_工作资料/05_补充参考工程/APUG092_GitHub镜像/doc/APUG092_HDMI1.4b_Transmitter_V1.0.docx>)，v1.0、2024-09，包含架构、参数、视频/音频/ACR 接口、EDID/DDC 及 PHY 说明。
- 与康芯官方赛题包中的同名 DOCX 逐字节一致，SHA-256：`070b22d3ff63e697ed7db39eee61e8653c60f58e0d6eb9cfdaf2ab16001b1543`。因此用户指定仓库提供的确是所需 APUG092 文档参考；当前官方包也已经有这份文档，无需继续依赖官网下载权限。
- GitHub 工程 `.al` 默认芯片 **PH1A90SBG484**，顶层 HDMI/PHY 的 `DEVICE="PH1A"`。加密核心支持 `EG`，但应按 EG4S20 重建器件、PLL、PHY 参数和 AC201 引脚约束。12 个工程文件引用全部存在，不代表可原样编译烧录 AC601。
- 优先从已取得的康芯 **lab_ex5_i2s** EG4S20 工程研究本赛题音视频链路；本目录作为原始多器件参考。

版本、来源 URL 和每文件校验值见 `镜像来源与校验.json`。仓库归档路径含 PH1P35/MIPI，但本手册与核心支持多器件，不能只凭目录名判断只能给 PH1P35 使用。
