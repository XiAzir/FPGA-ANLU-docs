# C11320 视频播放器资源优化

2026-10-21，本轮目标为 Slice 使用率降到90%以内。选中D02，最终实际路由网表为 **8637/9800 Slice＝88.13%**，较C11319 C04的9554减少917，降低9.36个百分点。Setup **+0.795 ns**、Hold **+0.024 ns**，两项TNS均0。

## 实现与资源

工程 `../../../../../FPGA-ANLU/development/player_video20`，实验 `development/video20_work`，Build ID `00C11320`。综合15479 LUT/8740 FF；物理16418 LUT/8814 FF/62 BRAM9K/26 DSP/2 PLL/3 GCLK。最终hold网表中4334个MSLICE加4303个LSLICE，精确计数8637；目标8820，余出183 Slice，器件空余1163 Slice。

选中的结构改动：

- X/Y两遍IDCT共用一个算术核，分别跟踪输入阶段和输出阶段；完整64拍块预约，Y输入第62拍预启动下一块X。
- 转置数据准备到第54位置后启动读取，交叠计算和读取；读检查要求数据在此前周期已经写入。阈值53负控触发同拍读写，阈值54保留一个完整20 ns周期的写后读间隔。
- Y路径删除一层重复乘积寄存器，配套调整控制延迟；两路181常数乘法精确映射到DSP。32位运算截断、符号和原除256向零语义保持。
- JPEG核保留默认动态参数；生产视频实例固定JPEG420、640×480编译配置，匹配既有MJP封装。图片路径保持RGB888，视频缓存保持RGB565。
- RGB亮度/对比度采用等价整数表达式，收窄中间量；98304通道、128种选择组合穷举一致。

SPI mode3/12.5 MHz、时钟、PLL、SDC及既有图片、音频、频谱、按键逻辑沿用。相对C11319共7份HDL变化，其中1份为Build ID，106份HDL相同。没有新增运行时输入保护分支。

位流 `build/manual/AC201_player_video20.bit`，SHA256：
`2c97c1152d69a1a7a9b7681d543f3834c2a4fdd4a0f15ec0982bc90579310e6d`。

## 消融选择

| 方案 | 实际结果 | 选择 |
| --- | --- | --- |
| C11319 C04 | 9554 Slice，Setup+0.289/Hold+0.024 ns | 保留原版 |
| D00，仅ID/工程路径变化 | 9526 Slice，Setup+0.648/Hold−0.012 ns | 同ID控制；28 Slice来自映射差异 |
| D01，串行共享IDCT | 综合16013 LUT/9018 FF/22 DSP；Q90短窗口137.4718892 ms迟帧，581888像素 | 淘汰，保留失败 |
| D02，交叠/提前读/retime/DSP/固定配置/RGB组合 | **8637 Slice，+0.795/+0.024 ns**；应用峰值帧48.23407 ms | 选中 |
| reader位宽收窄 | 40000周期差分通过，面积反增3 LUT | 淘汰 |
| catalog显式高位归零 | 几何/名称/trace精确；独立持平，组合多32 LUT | 淘汰 |
| mapper等待计数收窄 | 四参数差分通过；综合器原已裁剪，资源持平 | 淘汰 |
| MCU计数收窄D03 | 完整307200像素精确；比固定配置多63 LUT | 淘汰 |

独立固定JPEG配置消融：C04 17025 LUT；只固定420为16849；固定420及尺寸为16730。RGB单元174→153 LUT。共享Y的retime+DSP独立核803 LUT/848顺序单元/14 DSP，768笔真实器件原语门级事务精确。独立消融用于判断方向，最终收益以整机实际路由Slice计数为准。

## 精度、时序与功能证据

- 共享IDCT：48块/3072输出事务，随机全16位输入、稀疏/正负极值、12次在途img_start及复位，16300次RAM读准备检查通过。54阈值正控通过；53阈值在3.23 us触发`READ_BEFORE_X_WRITE bank=3 addr=8`。
- 完整JPEG：共享v3原108帧在正常、随机gap/背压、在途abort/reset后均307200像素精确；固定配置成熟TB完整307200唯一坐标、idle=1，与动态核一致。首次自制TB遗漏empty-last导致306688像素/idle=0，失败证据保留，最终改用成熟TB核验。
- 当前选中组合HDMI355 ms：1536000解码像素、5次commit、4不同显示内容；4源帧逐坐标对独立C03 JPEG参考，3完整不同内容帧、6124468个串行恢复像素匹配最终AXIS。PCM送出12840，pin检查12839，最后一笔在流水；BCH/TERC clean，欠载0、迟帧0。
- 照片122 ms：307200写读像素、6378/4447 PCM，3 FFT帧72 bands误差0。当前实际综合gate FFT同样72 bands精确。
- 当前gate与最终routed系数ROM各1536词/3072 lane精确，四bank各27严格参数零差异；6路控制×32状态共192行真值及28项时钟检查通过。所有Q绑定按真实FF lane解析。
- 当前位流对应四个正式阶段：syn `3ad0291b-3f04-444e-b43c-ccbe8caf6f55`，physical `1a4b9f3a-541b-4b4a-969b-8bb74b578b99`，hold `3a5afb62-ab26-4bd9-9bc1-83a4e41c8ff4`，bit `4991f333-5904-4ac0-99d5-f76a0d5cf8ff`。

工程证据入口：`video20_work/whole/D02`、`shared_idct/equiv_215144`、`idct/retime_shared/{review_final,gate_verify}`、`huffman/{shared_validation,final_pin}`、`photo_regression`、`final_route_audit`及`player_video20/build/{manual,audit,gate_verify}`。

## 解码时间取舍与媒体

本轮以共享计算换取面积下降。应用模型原108最大JPEG帧在50 ms短窗口用时48.23407 ms，余量1.76593 ms；C11319对应值为41.52511 ms/余量8.47489 ms。新355 ms引脚测试五个commit的解码用时47.116/48.234/47.877/48.402/49.000 ms，全部按测试时序完成。首帧显示约87.557 ms。完整20秒、各帧不同运算复杂度及长期时钟/实卡条件仍需后续整机与实板验证。

媒体保持640×480、15 fps、20秒/300帧JPEG420 Q90，原片16～36秒，640×360内容上下各60像素黑边，原声48 kHz/PCM16单声道960000样本，HDMI左右复制。JPEG平均3.3165 Mbps，MJP+WAV文件约4.1767 Mbps。

TF根目录文件：`VIDEO.MJP` SHA `239a413b3fc9462ab362918177f3e62e7069f10559281815e7c3198457525c31`；`TEST.WAV` SHA `30eaf10a6ff1800163cecb3225cce685873b38c9a8e42635f1e5c92b0e95b5de`。位流保存播放器电路配置，媒体保存在TF卡。302记录/16755 LBA的全片reader证据沿用相同源码、相同媒体的C11319结果，指定帧整机与reader全片范围分列。

## 最终封存（2026-10-22 11:07）

真实SDRAM器件模型在10月22日11:05连续完成221 ms，正常退出0：1008128解码像素、3 commits、2不同显示内容帧、6408原声样本，欠载0、迟帧0。峰值108为48.25877 ms，50 ms预算余量1.74123 ms；第三帧48.40089 ms。五条709 ns启动命令/hold诊断原样保留，运行期模型错误0，状态PASS_AFTER_STARTUP_TRANSIENT，无SDF。

最终967项源/阶段/数据库/位流/兼容副本/HDMI参考绑定PASS；另有755项重跑媒体、脚本及优化设计文件身份核验PASS。旧100 ms和190 ms中断日志、WinError623、审批503未执行记录均保留。10月22日通过执行审批启动同一优化设计并加六个仿真检查点，本次从头连续完成，未使用restore。当前环境阻碍已解除，最终结果见`video20_work/physical_final/final_result.json`。

冻结位置`player_video20/checkpoints/C11320_video20_20261021_offline`共1412文件，manifest SHA `312ca272b5c29b83c471a36ec8d2388f2cbbf489a2d8bfc50a0d4dcc98b963be`。下载入口[video20.bit](../../../../../FPGA-ANLU/download/video20.bit)与手工构建、交付目录和冻结交付四份bit一致。

[离线包](../../../../../FPGA-ANLU/deliverables/video20_c11320_20261021.zip)共14个payload文件，11630946字节，ZIP CRC和逐文件SHA通过；ZIP SHA `92dcf4a71d0f428484549fbad14d455a4728f767cb6db906326da73231e71fa2`。包内有[操作说明](../../../../../FPGA-ANLU/deliverables/video20_c11320_20261021/操作说明.txt)、位流、相同Q90媒体、原声、电脑预览、许可及核验凭据。C11319源码/冻结包/zip和C11318位流128项保全检查通过，无上板、写卡、Flash、提交或push操作。

本轮90%目标与离线封存完成。用户具备板卡后按装卡说明进行SRAM加载，核对Build ID、完整20秒原声同步/循环/暂停/重播/切图/频谱、SD CRC/欠载及持续时长；完整20秒整机回放、SDF与实体SPI/TF/SDRAM/HDMI条件仍待后续验证。
