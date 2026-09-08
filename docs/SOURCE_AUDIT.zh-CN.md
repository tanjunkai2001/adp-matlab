# 来源核验与设计依据

检查日期：2026-09-07。三条来源均完成实际源码的有限范围静态阅读，未执行上游 MATLAB 程序。原始下载副本留在此次任务的研究缓存，交付包只包含报告与来源/散列登记。

| 来源 | 固定版本/范围 | 本次结论 |
|---|---|---|
| [FxT-CL-ACI](https://github.com/tanjunkai2001/FxT-CL-ACI) | `e6fd86390f6895a588390c01957a3e4393ffe432`，19 个文本文件与 Git blob 哈希一致 | 适合首个论文迁移对象，先核对公式与记录语义 |
| [Adaptive-dynamic-programming-algorithms](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms) | `ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f`，11 算法目录、38 个 `.m` | 提供方法分类；不能宣称已经覆盖独立 CT VI 实现 |
| [Lewis 研究软件页](https://lewisgroup.uta.edu/code/Software%20from%20Research.htm) | 读取目录，下载 4 个 ZIP、静态审查 9 个 `.m`；逐包 SHA-256 已记录 | 有价值的历史参考代码，尚无统一接口或测试契约 |

## 对规范设计最直接的五项依据

1. **特征梯度需要可执行核对。** FxT 的 `func_phi_6NN.m:4–5` 中，`x1^2*x2^2` 对 x2 的导数少系数 2。迁移时保留旧版本，新版本独立核对并重算受影响结果。[固定源码](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Utilization/func_phi_6NN.m#L4-L5)
2. **成本和 Bellman 残差分别记录。** FxT `main:242` 保存 r1/r2，而绘图按 Bellman error 命名；实际 delta1/delta2 在 225–226 行。新 result schema 不允许以含混的 `Bellman` 字段承载这些不同量。[固定源码](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L225-L242)
3. **回归门槛检查秩和条件数。** lujingweihh 的 IRL 使用矩阵范数门槛；Lewis 的部分 DT 示例使用正规方程。新基础回归器返回奇异值和残差，秩不足时拒绝拟合。[IRL 源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/integral_reinforcement_learning/irl_main.m#L43-L70)
4. **ODE 求值与学习/日志更新分开。** FxT 在回调内写全局缓存和日志。`tspan` 输出间隔不是固定内部步长；重构必须明确其代表连续学习还是采样学习。[固定源码](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L251-L261)、[ode23 官方文档](https://www.mathworks.com/help/matlab/ref/ode23.html)
5. **所有命令阶段和成本通道明确。** Lewis 经验回放包区分 nominal 与探索/截断输入；成本与系统采用的输入不完全相同。这需要结合原论文核对，不能静态断言论文错误；它直接说明统一库必须记录行为策略、实际输入及各回归量的来源。[官方包](https://lewisgroup.uta.edu/code/reza%20experience%20replay.zip)

## 详细审查与不确定性

- [FxT 实码审查](audits/fxt.md)：逐项位置、严重度、影响、修改方案和验收步骤；包含待论文核对的项。
- [ADP 算法集合实码审查](audits/adp_algorithms.md)：11 类算法、完整文件清单、知识假设和数值风险。
- [Lewis 与研究方向核验](audits/lewis_scholar.md)：4 个下载包的 SHA-256、目录覆盖、版权文字、本人代表工作及 DOI 核验层级。
- [机器可读来源登记](../registry/upstream.json)：固定 commit/ZIP 散列及审查、许可、执行状态。

Scholar 返回 403/访问失败，未取得完整 Scholar 列表；本人身份与代表方向通过 FxT README、本人主页以及可访问出版社/元数据核对。未按标题推定论文算法细节，未核验完整引用数。

两 GitHub 仓库未发现许可证文件；Lewis 同步 actor–critic 包有 “All rights reserved” 文字。这里仅记录检查到的材料。本次交付采用原创最小基线，未再分发这些上游代码。
