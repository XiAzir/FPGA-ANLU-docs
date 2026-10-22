# C11319 颜色弹性流水候选记录

更新时间：2026-10-21 20:15（北京时间）
状态：独立核回归完成；生产候选由父任务以 C04 集成构建。

## 产物与源码

- 修改范围：`development/video19_work/color_pipeline/candidate_src/C03/jpeg_output.v`。生产候选 SHA256 `B9539FF30324CA6A6FFCEEDFAF0A865BCB16DD6948CECF2899F8BD8126CB012D`；C04已集成同一RTL。
- C03原输出模块快照：`development/video19_work/color_pipeline/sim/jpeg_output_C03_before_pipeline.v`，SHA256 `3806A1AA079BF0F0060750111E04DC40BACFE03F07C1CF44253FEF00B2C08BBF`。
- 差异：将原来的单级RGB输出寄存器改成两级valid/ready弹性流水。一级保持Y及四路原始系数乘法、移位结果和坐标/模式；二级执行原32位求和及原有截断/饱和。像素消费、Y/Cb/Cr弹出、块索引和420子采样计数统一跟随一级接收事件；末级数据在持续背压时保持。idle等待EOF被观察并且颜色流水两级均清空。完整补丁：`development/video19_work/color_pipeline/sim/color_pipeline.patch`。
- 四路系数整数表达、32位乘积/截断、坐标计算、EOF标记解释均保留C03语义；全帧比较覆盖C03与A08原核。

## 验证结论

运行环境：Icarus Verilog 12.0（devel）。每条full frame输出是2,150,400字节（little-endian x/y + RGB）。全部全帧均307,200像素，坐标覆盖完整，重复/越界/停顿保持错误为0。

| 激励 | 结果与输出 SHA256 |
| --- | --- |
| frame000，候选 MODE2、seed324508639 | 76,683 stalls；与C03及A08逐字节一致；`A4D4B3B4B86A23831D06D4B3051DD4C9486B2141EBC4E5C62D67A605A9000440` |
| frame109，候选 MODE3/GAP7/seed324508639/ABORT_BYTES=10000 | abort后复位并完整重放；77,263 stalls；与C03/A08逐字节一致；`CDE70E8F13E1982BC48F72480221462D1D3E4EA35B4C1584A8309A4754263E87` |
| frame299，候选 MODE3/GAP7/seed1597463007 | 77,495 stalls；与C03/A08逐字节一致；`53A1A0AF77BCAB1ED8130C177865C7D55C0FB1ABCE99250CBA4FE6C7929F3485` |
| `solid_zero_ac.jpg` 64×64，MODE3/GAP7 | 4,096像素/997 stalls；与C03逐字节一致 |
| `dc_step_negative.jpg` 64×64，MODE3/GAP7 | 4,096像素/997 stalls；与C03逐字节一致 |
| `dense_ac.jpg` 64×64，MODE3/GAP7 | 4,096像素/961 stalls；与C03逐字节一致 |
| `dc_step_negative.jpg` 末像素 `(63,63)` 定向停顿8拍 | 实际停顿8拍；停顿期间若idle置位测试台会fatal；hold_errors=0，最后idle=1，输出与C03逐字节一致 |

A08原核在frame000/109/299的无背压输出与C03原核三帧逐字节一致。候选在C03对应基线之上通过随机背压、输入gap与abort/reset重放。

最终完整冻结收据：`development/video19_work/color_pipeline/sim/runs/candidate_C03_frame_000_2_0_0_20261021_201258_740/manifest.json`，绑定24个RTL文件、testbench和fixture SHA，记录Icarus版本、compiled `.vvp` SHA及输出SHA。synthetic和A08 run目录同样保留运行前source snapshot与manifest。更早的frame000、109、299运行目录没有编译前快照；`development/video19_work/color_pipeline/sim/early_run_postrun_receipts.json` 明确标记了后补时间和哈希，没有伪造编译时间。父代理确认这些候选run期间RTL SHA保持`B953…012D`。

## 失败记录与限制

开始两次仿真时，Windows下Icarus `$fopen` 未接受绝对输出路径，日志保留在 `sim/runs/baseline_C03_frame_000_0_0_0_20261021_195740_854/` 与 `.../195803_051/`。改为在run工作目录写相对文件名后，full-frame仿真正常结束，最终候选/基线证据均为有效结果。

ModelSim 对生产文件内wire声明次序有编译限制；生产RTL保持与综合一致的SHA，父任务在独立ModelSim冻结副本中按兼容机制调整声明位置。父任务负责C04同源整机综合、布局布线、图像/引脚和最终时序结论。本子任务未单独跑TD面积/时序消融。

## 接续

如父任务需要重新回归：

```powershell
& ./development/video19_work/color_pipeline/sim/run_color_pipeline.ps1 `
  -Fixture 'E:/VSCODE-project/FPGA-ANLU/development/video_codec_trial_20261021/decoder_fixture/frame_000.jpg' `
  -Variant candidate_C03 -Mode 2 -Seed 324508639
```

每次会创建唯一run目录，冻结RTL与testbench，保留compile/run日志、像素记录、manifest和所有产物哈希。
