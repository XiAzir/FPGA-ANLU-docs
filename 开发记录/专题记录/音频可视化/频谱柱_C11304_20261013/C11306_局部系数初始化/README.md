## 2026-10-13 22:21:19 实板失败修正

用户反馈默认无音画；长KEY1后有图/闪点、内置音阶伴杂音、频谱不动，翻页/轮播/亮度对比度正常，旧文件回载正常。视频DFC11306、1D880000，默认3300BB80/tone3B00BB80，源/FIFO/HDMI前缀均F485/flag7，格式错误0，读取超时未见。支持把当前问题定位到PCM输入之后及未观测的频谱阶段，但未证明唯一根因。live FAILED，原bit/ZIP/232冻结不改。后续C11307只改ODDR准备沿并补被动频谱诊断，正在本地审计/实现，尚未交付。

# C11306局部系数初始化候选

更新：2026-10-13 21:53:11（北京时间）。本地交付完成，实板PENDING；成功基线C11206不变。

## 现场证据与本次动作

C11305用户反馈：默认仅UI/空频谱/IMG0/0，无BMP/音乐、LED全灭；长KEY1后无信号无背光，D3闪、其他灯亮。两视频可读DFC11305、1D97000A：fs_ready1/fs_error0/display0/BMP与WAV和两mapper错误，WAV mapper timeout0A。默认33000000表示有效PCM0；tone后3B00BB80表示名义秒48000且内部lock/frame有效。prefix flag8/count0源于early_tone_abort，不表示tone PCM为0。C11305 live已FAILED，原bit/ZIP/221冻结不改。[反馈](C11305实板反馈.json)。

审计未发现本轮SD握手源码变化：catalog/两mapper/arbiter、BMP/WAV、SD SPI与bridge均继承C11206。普通ready移交无确定首拍竞争；arbiter仅card_end释放owner，若SD一次runtime请求不结束，可造成两个mapper相继timeout。这是异常恢复缺口，不是本次已证实根因。eram_init并不直接初始化arbiter或mapper簇缓存寄存器，但确实扩及HDMI FIFO/WAV RAM/帧缓存且改变实现；不能据off候选就宣称根因已定位。

新工程`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_private_init`：C11306恢复成功C11206的global gate eram_init off；仅频谱系数由四块显式EG_PHY_BRAM INIT/INITP保存（1024x16 Hann拆9+7，512x32 twiddle拆18+14）。相对C11305，仅analyzer ROM接线和top/status两处ID改动；新增ROM/generator/manifest三文件，频谱运算/渲染、PHY、PLL/reset、引脚/SDC、TF/播放链路不改。ROM接口仍同步一拍、独立en。位流634280字节，比629624基础配置多4656字节，与4个初始化块的长度相符；未据长度声称独立解码bit ROM数据。

## 本地验证与限制

独立probe在eram_init off下4BRAM INIT正确。正式综合最后设置off，private gate1536字零差异；最终hold后DB只读导出routed_implementation.v，再核1536字也零差异。bitgenstage证明最终routeDB/report未改变。[综合核验](综合系数核验.json)、[路由后核验](布局布线后系数核验.json)。

本地Icarus使用PRIVATE_ROM_BEHAVIORAL_SIM：1024 Hann/512 twiddle全地址与独立使能/保持通过，13合成向量312段+真实音乐48段+集成72段bit-exact，650像素与HOLD/恢复/切源/reset/stale通过；32模型输入SHA逐项核对。官方EG_PHY_BRAM模型为pragma-protected，Icarus无法运行；行为分支读取.mem，不能冒称官方原语或整机门级仿真通过。硬件常量分别以gate与routed INIT证明，仍没有实板读出或raw bit ROM独立解码。

TD6.2.178840全流程成功：setup+0.452/hold+0.030ns/TNS0/coverage99.97%；16345LUT/9822reg/17817LE/44BRAM9K/11DSP/2GCLK。hold前HWNS/HTNS -0.012ns保留build/prehold；nativefix_hold消除。首次综合因复制的global on覆盖run off被拒；第二次off正确但TD规范化AL改变字节被scope门禁拒；第三次在稳定native AL上完整综合成功。两拒绝轮日志/DB保留build/rejected_global_init_on、rejected_al_normalization，没有发布失败轮。TD会删掉默认off的AL标签，当前Property为空、syn Tcl明确run off、最终gate命令off，审计检查最后有效setting而非早期run命令。

候选232冻结文件、ZIP6成员/5行、32模型输入及旧C11305 221冻结文件独立核验；既有C11206/C11303/C11304/C11305 bit/ZIP保持。未操作JTAG/TF/Flash。新模型/STA/INIT参数不证明实板音画或接收器电气裕量；唯一实物根因、长稳/冷启动/异常卡均未完成。

## 交付与下一步

[测试包](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_private_init_20261013.zip)，[操作卡](操作卡.md)。加载spectrum_private_init.bit、PROGRAM_SRAM/5MHz，D页DFC11306。先不按键检查默认图片/天ノ弱音乐；正常再长KEY1切内部音阶。异常包内bmp_scale.bit回退。

bit SHA256 `5D730E2C92602CE92560AC37FE2EE97BC6755AD20D24DDFE8F6BB9313DF881FB`；ZIP SHA256 `B869FE27729719D2C422F5EC1DD13448D4860D343662DE6D0AD8E2CAE85A8EE3`；manifest SHA256 `2496BA28835D656D1C121776B8A060CC12D50F735FE50A6006AC65D64A712632`。[凭据](交付凭据.json)、[独立核验](独立交付核验.json)。

若继续mapper timeout，下一隔离应在首次runtime请求记录arb_card_read/address、SD控制器状态和valid/end，区分请求未接、CMD17/token未回、返回门控丢失；若tone仍失锁，需进一步隔离固定视频/音频包与实际PHY输出。以上后续尚未执行。
