# C11304黑屏与C11305隔离证据

来源：用户两段视频、同条件回载反馈、本地源码/网表和TD功能库静态核查；非实物电气测量。

- 用户反馈C11304在KEY1前后黑屏无信号；两视频主要拍数码管，显示器无信号来自用户描述。后视频约末段DFC11304确认版本；前视频3300BB80对应名义秒48000样本、HDMI核内部锁定/帧事件。后视频A7008000显示切内部音阶；6700F485/7700F485表示输入前缀CRC一致、flag7，97000000表示格式错误为0。不能据这些诊断值证明HDMI引脚发送或接收器锁定。
- 用户本次同供电/HDMI回载C11206后画面和声音正常，支持异常依赖新版位流。
- C11303/C11304相对C11206，HDMI wrapper在pixel负沿捕获四路整字，lane marker改负沿，ODDR输入整对改serial负沿准备。TD `sim_release/eg4/eg_logic_io.v:191-235`的模型在上升沿采样D0与D1，D1经下降沿输出。未发现能证明黑屏的边沿语义错误；既有模型未测硅后或板端裕量，不能用模型PASS排除该变量。
- C11304相对C11303的PLL、reset、SDC未改；top仅改build ID。global gate eram_init从off变on，确实扩及HDMI核视频/音频FIFO（综合日志838-868），不是只作用于频谱ROM。初始化/资源/布局同时变化，唯一原因未确认。
- C11305只恢复成功C11206的hdmi_phy_warpper.v和lane_lvds_10_1.v逐字源码，以及两处build ID C11305；实际FFT和renderer逐字不变，保持eram_init on和所有原PLL、reset、SDC、TF、音频源。新布局必然不同，恢复源不等于恢复旧物理实现。
- 新频谱gold回归PASS；新串行器常规数字延迟矩阵27组/两个reset周期均零字/位错。模型不含glbl全局配置复位、抖动、亚稳态、真实引脚/PCB/接收器时序。ROM gate INIT与1024 Hann+512 twiddle文件全部一致。
- 板测分支：C11305恢复音画时，支持PHY改动或相关布局影响；仍无信号时，优先另建候选恢复eram_init off，同时用独立可验证的方法保持频谱系数初始化，或先做固定视频源隔离。不能为追求对照直接关初始化并把零系数频谱宣称为真实FFT。

所有旧bit/ZIP/checkpoint保留；未操作本地JTAG/TF/Flash。C11305状态必须保持PENDING_BOARD_VALIDATION直至用户反馈。
