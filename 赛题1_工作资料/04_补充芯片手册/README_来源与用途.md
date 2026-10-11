# 补充芯片手册：来源与阅读说明

检索日期：2026-10-04。现已保存五份原始 PDF，核对内容、版本、页数及 SHA-256。DS300、DS301、GD25Q16E 和 SRAM 来自芯片厂商官网；ES8388 为原厂文档的 LCSC 经销商镜像，未确认厂商最新版本。

| 文件 | 版本 / 页数 | 来源页面 | 下载入口 |
| --- | --- | --- | --- |
| DS300_Eagle_EG4系列数据手册_v3.9.6_官方.pdf | v3.9.6 / 119 页 | [来源](https://www.anlogic.com/support/tools-downloads) | [下载](https://www.anlogic.com/cn/skippower/downloadFile/id/211/mid/15.html) |
| DS301_EG4S20数据手册_v2.7.8_官方.pdf | v2.7.8 / 37 页 | [来源](https://www.anlogic.com/support/tools-downloads) | [下载](https://www.anlogic.com/cn/skippower/downloadFile/id/212/mid/15.html) |
| GD25Q16E_Rev1.3_官方数据手册.pdf | Rev1.3 / 58 页 | [来源](https://www.gigadevice.com/product/flash/spi-nor-flash/gd25q16e) | [下载](https://download.gigadevice.com/Datasheet/DS-00473-GD25Q16E-Rev1.3.pdf) |
| ES8388_Rev5.0_201807_数据手册_LCSC镜像.pdf | Revision 5.0 / 36 页 | [来源](https://www.lcsc.com/product-detail/Audio-Interface-ICs_Everest-semi-ES8388_C365736.html) | [下载](https://www.lcsc.com/datasheet/C365736.pdf) |
| IS61WV51216EDBLL_RevB1_20200724_官方数据手册.pdf | Rev B1 / 19 页 | [来源](https://www.issi.com/US/product-asynchronous-sram.shtml) | [下载](https://www.issi.com/WW/pdf/61-64WV51216EDBLL.pdf) |

DS300 查 EG4/EAGLE 系列架构、电气、PLL/IO/配置；DS301 查 EG4S20 合封 SDRAM、封装引脚。不能把 DS300 中其他型号引脚表直接用于 EG4S20。网站上传日期与文档内部修订日期分别记录。

GD25Q16E 订货表覆盖 GD25Q16ESIGR，容量 16 Mbit = 2 MiB。芯片已在板上，器件手册不能替代 TD Program Flash 操作说明。

ES8388 Revision 5.0，2018-07，36 页，来自 LCSC。检查了 ES8388 QFN-28 引脚、时钟/采样频率、I2S 与配置接口。厂商当前公开产品下载目录未列 ES8388，因此没有将镜像说成厂商当前最新版。

ISSI SRAM Rev B1，2020-07-24，19 页，第17页明确列 IS61WV51216EDBLL-10TLI，容量512K×16=1MiB，匹配AC601图纸。该手册不覆盖25616；实装芯片顶标和容量仍未核实。芯片板上已有，无需额外购买。

若采用 FPGA 内生/TF 卡数字音频 → HDMI 屏幕，ES8388 不必参与；图像帧缓存可优先使用 EG4S20 合封 8MiB SDRAM，外部 SRAM 可不用。

完整下载来源、哈希和型号核对见同目录 `下载来源与校验.json`。
