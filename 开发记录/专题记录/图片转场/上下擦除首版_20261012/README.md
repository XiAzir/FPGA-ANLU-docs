# 上下擦除首版 C11205

2026-10-12 12:33:50 C11205上下擦除 RTL/地址922360检查/RGB888四帧1228800像素/局部ownership模型/63源TD导入通过，静态集成审查无阻塞；正式综合完成、布局布线进行中。源码78继承不变、5改变、1新增，生产640×480/8行、每帧900批次；旧buffer至最终全新帧请求受理ACK后才释放（不是整帧读完ACK）。地址/RGB模型不含加密SDRAM，ownership loader用COMMIT状态注入，不代表完整BMP解析或板测。未生成交付bit，成功基线C11204，已知动态波形双线/低清晰度留后；未JTAG/TF/Flash。

下一步：完成实际backend握手模型、原约束布局布线及setup/hold检查、位流来源绑定和封存，再由用户远控上板检查转场/音画/原功能。工程证据：../../../../../FPGA-ANLU/development/player_transition_wipe/build。

下一步：完成实际backend握手模型、原约束布局布线及setup/hold检查、位流来源绑定和封存，再由用户远控上板检查转场/音画/原功能。工程证据：E:/VSCODE-project/FPGA-ANLU/development/player_transition_wipe/build。

## 2026-10-12 12:42:08｜本地候选交付，板测待验证

2026-10-12 12:42:08 C11205上下擦除候选本地完成，实板待验证。地址922360检查/RGB888四帧1228800像素/ownership/实际backend握手模型通过，静态审查无阻塞；TD原约束时序 {'SWNSns': 0.247, 'STNSns': 0.0, 'HWNSns': 0.011, 'HTNSns': 0.0} coverage99.97% holdFix=False，源/脚本/DB/报告/bit绑定与ZIP逐项SHA通过。资源{'LUT': 13131, 'reg': 8238, 'LE': 14651, 'BRAM9K': 24, 'DSP': 1, 'GCLK': 2}，download/transition_wipe.bit SHA 748E0AF0F9BF0656410C09735E371F655BEDD330C259E43858B614B1D95AE8F9；ZIP E:\VSCODE-project\FPGA-ANLU\deliverables\transition_wipe_20261012.zip 578847bytes SHA B9F6B9F7142B058424AD7BB84BCCC45E73B1DA8EA034AFC4AF90B2DD55581C76；165文件checkpoint manifest 55BDA6F491CCF5B7B15E70BD0E12B6F6F225EB4964B67ACAA7801ECE0824A82F。78源保持、5改、1新，640×480/每帧8行/60帧边界/900批次，最终全新帧请求ACK后释放旧buffer。成功基线仍C11204，原动态波形双线/低清晰度保留；未JTAG/TF/Flash，加密SDRAM和实际音画待用户验证。

模型范围与TB边界见工程build/model/verification_scope.md；ownership COMMIT注入不是完整BMP文件测试。下一步下载新候选，检查四图从上往下完整擦除、AUTO两轮、两音源/字幕/参数/冻结恢复；异常同条件回载同包C11204。[板测操作卡](操作卡.md)。

## 2026-10-12 12:47:24｜用户测试通过，新成功基线C11205

# C11205 上下擦除实板反馈与封存

记录：2026-10-12 12:47:24（北京时间，反馈记录时间，非实测起止时间）。

用户对上一轮完整测试清单回复“都没问题”。因此将四图上下擦除、AUTO、两音源及字幕/参数/冻结恢复记为所要求功能通过（用户反馈）；代理未下载板卡、操作TF/Flash或直接测量。成功开发基线更新为C11205 transition_wipe.bit，C11204继续直接回退。

位流SHA256：748E0AF0F9BF0656410C09735E371F655BEDD330C259E43858B614B1D95AE8F9。生产640×480、每显示帧8行；未实测时长，不能把代码推算约1秒写成测量结果。

T26所有权审计和T27一种连续转场完成上述范围验收。已知动态波形双线/HOLD消失、低清晰度继续保留；无唯一屏幕根因结论。计时长稳、冷启动矩阵、新文件/卡与碎片、Flash未验证。原165文件candidate与ZIP保持历史pending，新verified只增加本轮反馈/验收记录和更新info，源与bit保持原字节。

下一开发项按执行规划为T29多尺寸BMP测试基准及T30 FPGA最近邻缩放：不同受支持尺寸由FPGA适配到640×480画面，先规格/资源/行padding及方向模型，再独立候选集成；尚未启动RTL或上板。不以720p60为前置，波形清晰度优化留后。

[已验证操作卡](已验证操作卡.md)；[封存凭据](verified_receipt.json)。
