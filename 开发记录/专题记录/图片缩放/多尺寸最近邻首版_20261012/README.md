# C11206 多尺寸 BMP / 最近邻首版

开发工程：[player_bmp_scale](../../../../../FPGA-ANLU/development/player_bmp_scale)。当前C11206缩放首版已获用户功能正常反馈并封存为新成功基线；C11205保留回退（须恢复原640×480素材）。

规格见[scaler_spec.md](../../../../../FPGA-ANLU/development/player_bmp_scale/build/scaler_spec.md)。显示固定640×480，在FPGA加载时对原尺寸24位BI_RGB做等比居中最近邻，黑边补零；宽1..1024，高绝对值1..768，支持bottom-up/top-down和奇数宽padding。不是在PC预缩放后冒充板内缩放。

开发工程：[player_bmp_scale](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/)。当前C11206缩放首版已获用户功能正常反馈并封存为新成功基线；C11205保留回退（须恢复原640×480素材）。

规格见[scaler_spec.md](E:/VSCODE-project/FPGA-ANLU/development/player_bmp_scale/build/scaler_spec.md)。显示固定640×480，在FPGA加载时对原尺寸24位BI_RGB做等比居中最近邻，黑边补零；宽1..1024，高绝对值1..768，支持bottom-up/top-down和奇数宽padding。不是在PC预缩放后冒充板内缩放。

新增真实写FIFO反压。压力模型使用实际pack/framebackend/FIFOIP，通过4096像素、3072word、max_used481、5908次暂停、phase mask d（观察到ready落沿时pack相位0/2/3），未覆盖加密SDRAM或真实缩放引擎。以强制App_rd_busy模拟长时间读占用；Sdr_busy输入在原writer中未用。两份初期失败日志是TB错误（SHOW_AHEAD抽样时机、busy信号假设），修正TB后通过，没有以此修改RTL。

完整BMP解析/逐像素黄金、资源映射/原约束时序已通过，四尺寸实板照片与用户功能反馈正常；本版长期/冷启动/异常媒体与Flash仍未验证。动态波形双线和低清晰度按用户选择留到优化阶段。

全流程现处S4转场与缩放：功能开发粗估80%，全流程粗估60%–65%。这是基于剩余工作量的判断，非官方评分。四尺寸缩放首版现已通过用户反馈验收；仍需集成证据整理、显示优化、长稳/异常卡和文件验证、Flash固化、报告/视频及提交。

## RAM映射迭代

2026-10-12 13:27:41 C11206首次真实loader六帧1843200像素gold与四种真实错误输入通过，绑定engine9846713515DDADFC9D5F9B758F76E68CE7B3E80B0A08A247965016399974358C、loader9CDDACB2F20A36D2E066EB74BF8FE55C5D675115281CE73B7D64EDAD3B8F93DF，first_pass receipt保留。修复了首轮黑边X（黑边行未抑制row读取）、portrait错误offy及底黑边进入首content的相位；奇数黑边/正负高度/padding/背压等已逐像素覆盖。首次TD综合17897LUT/25BRAM/8DSP，scale仅sector1BRAM，row映射分布式存储；place返回BUILD_ERROR空文本，未取得可交付最终时序/位流，不能唯一确定place失败机制。旧gate/DB/报告/日志保留build/initial_ram_mapping/manual。新engine增加ram_style="bram"、独立无reset同步write与10bit行RAM索引，SHA A6C607738DB921E02C3D717F9C6CC9044CC3DDBC4FA02DD90B253FB541EF2C4D；smoke/elaboration再次通过，新全量gold/综合正在运行。无JTAG/TF/Flash操作，成功基线仍C11205。下一步正式BRAM映射、原约束setup/hold与最终hash封存候选，板测未完成。

首次placement原因补证：根代理核实initial_ram_mapping/manual/physical_console.log第384行PHY-9009：mslice5099超过器件上限4900。行RAM从DRAM改为BRAM后新placement/route通过，原约束最终SWNS+.628ns/HWNS+.004ns/TNS0。先前只摘末尾空BUILD_ERROR，现以完整错误码修正原因记录。


## 本地候选交付

2026-10-12 13:34:22 C11206多尺寸BMP/FPGA最近邻候选本地完成、实板待验证。完整loader六帧逐像素gold 1843200像素和错误/ready回归通过；实际pack/backend/FIFO压力4096像素/max_used481通过，静态审查无阻塞。TD原约束时序{'SWNSns': 0.628, 'STNSns': 0.0, 'HWNSns': 0.004, 'HTNSns': 0.0} coverage99.97% holdFix=False，资源{'LUT': 15031, 'reg': 8803, 'LE': 16520, 'BRAM9K': 28, 'DSP': 8, 'GCLK': 2}，BRAM映射保留PCM4/波形1且缩放4。源/脚本/DB/报告/bit来源与ZIP逐项SHA通过；bmp_scale.bit SHAC60464C0D4396D316DB7622E4CB0B70B5DE12C25148AFE234AC7C795C818625D；ZIPE:\VSCODE-project\FPGA-ANLU\deliverables\bmp_scale_20261012.zip 636284bytes SHA9371A293616AAF37FD72E2DFD9466616FADD7BCB583E06FC84357146B2D380D5；checkpoint260文件/manifest6082AB5E2A40CE8DD6FD73265CF59CECB35B35B883DD6466BB839CE68A1B1A9D。79源不变/5改/1新，支持24位BI_RGB宽<=1024/高<=768正负高度/padding/等比黑边640×480。未代理JTAG/TF/Flash，真实卡/加密SDRAM/实际音画待板测；成功基线仍C11205，波形已知显示问题保留。功能开发约80%、全流程60%–65%为主观估算，未将待板测缩放计为已验收。

交付时的准备步骤保存在[原操作卡](操作卡.md)；本轮结果见下方验收记录。回退仍须恢复旧图片再回载C11205。

## 2026-10-12 14:06:00｜用户反馈功能通过，C11206新成功基线

四张原始照片已保存，宏观缩放/方向/留黑符合预期；用户回复“看起来没什么问题，功能也验过了没问题”，按上一轮操作卡要求范围记录功能通过。已知动态波形双线/低清晰度保留。源码与bit不改，原candidate260与ZIP不变，新verified 268文件，manifest SHA `71F87A4B82F974092F63102E0D7522B6C5577BD367B6789C6AD0DDDA37A76FB7`。本版长稳/冷启动/异常媒体/Flash与正式五扩展证据矩阵未完成。下一步整理集成验收范围/证据并进入显示优化和稳定性验证（计划，未执行）。详见[验收记录](验收记录.md)、[反馈](board_feedback.json)、[封存凭据](verified_receipt.json)。

- 2026-10-12 14:07:38 封存后只读独立复核通过（gpt-6-luna）：verified268逐项manifest、candidate260及原ZIP、四照片project/docs副本SHA一致；两处live C11206与位流哈希一致；用户反馈/照片/未验证边界与记录吻合，无阻塞。不重构建、不操作硬件。
