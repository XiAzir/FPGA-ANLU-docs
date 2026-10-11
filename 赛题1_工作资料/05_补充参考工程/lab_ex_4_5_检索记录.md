# lab_ex_4 / lab_ex_5 官方参考工程检索

核查日期：2026-10-04（用户时区 Asia/Shanghai）。

## 确认的官方入口

- 本地《赛题解析一》及康芯选题指南列出的原分享：https://pan.baidu.com/s/1ysv_FmmgZKuM0rBiHfSv8w ，提取码 M5N1。
- 带提取码入口：https://pan.baidu.com/s/1ysv_FmmgZKuM0rBiHfSv8w?pwd=M5N1 。
- 分享标题：HX4S20_Contest_202606；页面显示 2026-07-03 09:26 建立，永久有效。
- 已通过无登录隔离浏览器查看公开目录。

## 本地没有的优先核查包

- 路径：HX4S20_Contest_202606 / 7_lab_ex_2026_nosoft / 全国大学生嵌入式芯片与系统设计竞赛'2026选题指南_康芯.zip。
- 页面显示大小：583.8M（网盘显示值，不是精确字节数）。
- 修改时间：2026-06-22 14:40（网盘显示值）。
- 目录直达链接：https://pan.baidu.com/s/1ysv_FmmgZKuM0rBiHfSv8w?pwd=M5N1#list/path=%2FHX4S20_Contest_202606%2F7_lab_ex_2026_nosoft&vmode=list 。
- 点此包“下载”后弹出“扫码登录 / 账号登录 / 短信登录”。没有登录账号、安装客户端或使用非官方下载服务。
- 因此未下载原包，未取得 SHA-256，未能查看包成员；不能把“目录包存在”说成“已确认包含 lab_ex_4/5”。
- 本地 inventory.json 与 rg --files 均没有找到同名 583.8M 包；只找到已提取的康芯选题指南 DOCX。

## 其他核查

- 2_Example：DEMO实验介绍 文件夹（37 个文件）；DEMO_TD版本6.2.1.zip（210.8M，2026-06-22）。未确认这是 lab4/5。
- 9_康芯开发板使用手册及实验平台：HX4S20开发板手册-HDL版2410.pdf（2.3M）与 安路教学实验平台2509.pdf（18.6M），不含独立工程文件。
- 8_FPGA学习资料：一般培训、软件与语法教程；公开目录未列 lab4/5。
- 安路官网下载列表接口 POST /Cn/Index/getFile.html，对 lab_ex_2026、lab_ex_4、HX4S20 检索均返回 html 为空。
- GitHub 仓库搜索 HX4S20 返回 6 个仓库。相关公开代码为 2025 年项目；未发现对应 2026 多媒体播放器官方工程镜像。
- GitHub 精确仓库搜索 HX4S20_Contest_202606 与 hdmi_audio_tone_i2s_64fs 均为 0。此检索范围是仓库元数据，不代表全网代码不存在。
- Askuafwx629/lab_ex_5_HX4S20_OV5640 名称易混淆：2025 年 OV5640 摄像头项目，非当前 2026 TF 卡多媒体播放器，不作为补齐包。
- Bing 精确词查询无可用匹配，部分查询退化为通用 LAB 字词，未据此声称官方工程没有公开。

## 交接结论

官方分享有效，最值得用户下载并交由后续核查的是 583.8M 康芯赛题 ZIP。当前真实阻碍是百度网盘下载登录，不能确认压缩包内部文件。用户下载后应核对 .al/.v/.vhd、IP、.adc/.sdc、doc/TF卡图片、sync_to_sd.py，并确认 lab_ex_4 / lab_ex_5 标识及 2026 版本。

本任务未下载任何工程包，也未修改主资料索引或缺项清单。
