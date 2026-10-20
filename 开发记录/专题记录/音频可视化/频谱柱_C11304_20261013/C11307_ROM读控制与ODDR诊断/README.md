## 2026-10-14 18:45:17 实板反馈修正

用户反馈默认WAV有杂音/无图但频谱正常，长KEY1后内置音阶和频谱正常/仍无图。视频DFC11307、1D980000（挂载ready、BMP loader error、WAV primed，无fs/mapper/WAV error），FFT帧数持续增长、C=FE。完整板测失败；音阶/频谱部分通过用户反馈。CRC F485三端匹配当前60秒素材跳过65536后32768样本窗口；A8000是捕获样本数，不是data offset。历史首32768措辞不适用于当前探针。IMG0/0是未提交首帧OSD默认，不能证明目录无BMP。现存live元数据更新，原bit/ZIP/281冻结保持。下一版降低TF读取频率并补扇区CRC/BMP首错详情，具体物理根因未确认。

# C11307 ROM读控制与ODDR准备沿、被动频谱诊断

更新：2026-10-13 22:42:18（北京时间）。本地候选交付完成，实板PENDING；成功基线仍C11206。

## 现场结果与动作

C11306默认无音画，tone后有图/闪现亮点、音阶伴杂音、频谱空；原翻页/轮播/亮度对比度正常，用户报告旧文件回载正常。两视频DFC11306、1D880000、默认3300BB80/tone3B00BB80；源/FIFO/HDMI输入WAV前32768样本prefix均F485/flag7、format_bad0。本次未见C11305 mapper timeout；前缀冻结不证明后续或tone/实际TMDS内容。[反馈](C11306实板反馈.json)。C11306 live FAILED，原bit/ZIP/232快照不改。

新工程`E:/VSCODE-project/FPGA-ANLU/development/player_spectrum_observed`：

- 四系数ROM读通路显式控制对齐C11304 TD推断映射：Hann9b SP8K同步CEA；twiddle18b PDPW8K使用CE mux0/1、CSA/CSB最高位由FFT ISSUE控制、WE mux1/0，其余CLK/OCE/REG/GSR/RESET和地址/DOA-DOB照推断配置。前版将issue接CE而CS恒高，等价性未被证明。常量INIT保留，global eram_init仍off；对齐推断配置不等于已证实硅后因果/无写入行为。
- HDMI只将lane中S_oddr_data两位的准备沿从serial posedge改negedge。保持C11206 pixel marker posedge、wrapper直通和load/shift/位序；没有继承C11303的另外两个改动。独立108组数字延迟矩阵：baseline nominal27pass、boundary0/27；最小变体nominal+boundary54/54pass。注入D0/D1/PAD延迟非测量，未含真实眼图/抖动/亚稳态。
- 新增只读频谱诊断，B页完成FFT帧数（切源清零），C页8状态bit+上帧16bit最大幅值。状态从bit7到0为PCM见到/FFT完成/非零频段/Hann非零/twiddle非零/前台提交/前台非零/前台冻结。通常非静音运行FE、HOLD为FF；仅为阶段定位，不单凭某个瞬间判故障。B/C取代历史first_high_pos/data_offset两字段，D版本位置/翻页周期不变。

相对C11306仅8份user_source变化（lane、top、status、analyzer、overlay、ROM、generator、manifest），无新增生产文件。包门禁核对lane唯一样本沿差异、top去诊断/ID后与parent相同；其余85user_source及IP/引脚/SDC/PLL保持。诊断只去七段数码管，无路径回TF/audio/HDMI控制或FFT运算。

## 验证与边界

独立行为回归：312合成段+48真实音乐段+72集成段bit-exact，650像素和HOLD/恢复/切源/reset/stale通过；新遥测TB验证非零系数/完成帧/非零帧最大值/前台、HOLD时FFT继续、切源与global reset清零。35源绑定逐项核查。PRIVATE_ROM_BEHAVIORAL_SIM不使用受保护官方BRAM模型，不能声称其门级仿真通过。

正式gate和hold后routed导出网表分别核：1536系数零差异、4bank各27项MODE/位宽/CE/CS/OCE/CLK/WE/REG/GSR/RESET参数（共108）对齐。动态端口来自生产generator静态接线与manifest说明；参数匹配不证明实板读值。[综合/路由后读控制](路由后读控制核验.json)、[系数](路由后系数核验.json)。

TD6.2.178840 native规范化后首轮syn/physical/hold/bitgen均success，scope/scripts/DB一致。最终setup+0.365/hold+0.024ns/TNS0/coverage99.97%；16563LUT/9758reg/17926LE/44BRAM9K/11DSP/2GCLK。hold前HWNS-0.060/HTNS-0.154ns报告/DB保留build/prehold，nativefix_hold消除。候选281冻结、ZIP6成员/5行、35模型绑定、旧C11306 232冻结独立核验；旧位流与ZIP保持。未操作JTAG/TF/Flash。

唯一实物根因、白点/杂音是否消失、默认WAV与频谱反应、长期/冷启动均待板测；眼图/接收端和raw bit ROM数据未独立测量/解码。恢复ROM读控制是实际差异修正，ODDR变体解决的是数字模型中的混采风险，二者不构成实板已修复结论。

## 交付与下一步

[测试包](E:/VSCODE-project/FPGA-ANLU/deliverables/music_spectrum_observed_20261013.zip)、[操作卡](操作卡.md)。加载spectrum_observed.bit PROGRAM_SRAM/5MHz，D页DFC11307。先检查默认音乐/画面/柱，再长KEY1检查tone；仍异常请保留整轮数码管约22秒（特别B/C），异常回包内bmp_scale.bit。

bit SHA `8CFD873C1B9727A18C8A3731233943B6C43D56DD56677623CDAEC0962B7A2AF4`；ZIP SHA `F96C748747BD008A18461D5728247A7430C0AF1FF0BB4E87A6FBC8B5A5E9D626`；manifest SHA `B9935A54B29B31CC39CCBDE6661445F434223A42D4420C0C62BFD3E41C22730F`。[凭据](交付凭据.json)、[独立核验](独立交付核验.json)。
