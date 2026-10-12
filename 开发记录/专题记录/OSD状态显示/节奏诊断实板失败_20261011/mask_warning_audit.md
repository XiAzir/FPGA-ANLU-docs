# BitWriter mask 警告审计

审计日期：2026-10-11。范围：只读核对本机 TD 6.2.1 SP1 官方 BitWizard 手册及 `user_verify_sram.log`；未运行 BitWriter、bitgen 或任何板卡命令，未操作硬件。

## 结论

完整日志显示 `download ... -mode x_rdbk` 的流程执行了 `bit_to_vec ... -m x_rdbk`，随后执行该流程中的 `program -cable 0 -spd 6 -p`；整条 `download` 以 `RUN-1003 ... finish` 和 `GUI-1001 : Downloading succeeded!` 结束。结合当前模式及完成状态，可记录为：**工具层面 VERIFY_SRAM 完成成功，未报告比对失败。**

`PRG-5006 WARNING: Cannot find mask file` 与 `PRG-3001 ... ReadBack: completed, 0 bits have been masked` 同时出现。手册没有明确给出缺少 mask 时的比较覆盖定义，因此成功结果不构成“独立逐位 dump 已核对”或“用户 ERAM 已覆盖验证”的证明。更准确地说：**工具报告 VERIFY_SRAM 流程成功；没有独立逐位 dump 和用户 ERAM 覆盖证明。**

## 手册证据

来源：`C:/Anlogic/TD_6.2.1_SP1_6.2.178.840/doc/SWUG/SWUG110_BitWizard_User_Guide.pdf`，官方《TangDynasty BitWizard 使用指南》，版次 2024.12。

- PDF 第 8 页（印刷页 7），第 3.1 节 `General Option`：`gen_mask：产生校验FPGA ERAM文件罩`。手册说明该选项生成用于校验 FPGA ERAM 的 mask 文件，但没有说明缺少该文件时 VERIFY_SRAM 的比较覆盖或结果判定。
- PDF 第 20 页（印刷页 19），第 4.3.2 节 `Verify SRAM`：该模式可回读校验配置 RAM 数据，且“不包含用户ERAM数据”。这限定了文档承诺的验证范围。
- 手册没有定义日志中的 `PRG-5006`、`PRG-3001`，也未解释 `0 bits have been masked`、mask 文件缺失对比较范围的影响，或独立逐位 dump 的覆盖率。

## 日志阶段判读

`user_verify_sram.log` 中，器件识别成功后，工具在 `download ... -mode x_rdbk` 内调用 `bit_to_vec ... -m x_rdbk`，报告 mask 警告及 `ReadBack: completed, 0 bits have been masked`；随后同一 download 流程调用 `program -cable 0 -spd 6 -p`，耗时约 14.30 秒；之后 `download` 完成并报告 `GUI-1001 : Downloading succeeded!`。因此这里的 `program` 应视为 x_rdbk download 流程中的执行阶段，不能仅因命令名把它判断成重新编程，也不能把 `BIT2VEC::ReadBack completed` 单独拿来证明整个实板读回流程成功；流程级证据是外层 x_rdbk download 成功结束。

## 不确定性

可确认工具以成功状态结束 VERIFY_SRAM 流程，日志没有报告比对失败。由于手册未定义缺失 mask 对覆盖范围的影响，且该 VERIFY_SRAM 模式按文档不包含用户 ERAM，不能进一步声称独立逐位 dump 已校验、用户 ERAM 已验证，或配置中的所有用户数据均已覆盖。`0 bits have been masked` 表明日志报告屏蔽位数为零；手册没有据此定义总比较位数或完整覆盖率。
