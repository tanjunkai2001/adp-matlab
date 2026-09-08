# 实际运行结果

最终运行目录：[validated-v03-20260907](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/results/validated-v03-20260907/metrics.json)。MATLAB R2025b Update 6，maca64，进程 exit=0；8/8 自动测试通过。测试后实际运行并保存原始数据、模型、配点、迭代、控制轨迹、配置、环境及图，源码固定为该目录 `source_hashes.json` 的 8 个文件。图已人工查看。

| 指标 | 实测 |
|---|---:|
| 辨识秩 | 19/19 |
| 训练拟合 c1=c2 | 0.0542969858218434 |
| 鲁棒外迭代次数 | 6 |
| 鲁棒配点 PDE RMS | 0.00129788023563016 |
| 名义配点 PDE RMS | 0.000396379204403799 |
| 解析策略积分与 V* 最大误差 | 1.73277725501464e-10 |
| 鲁棒控制最大终态范数，15 s | 2.20210213831989e-5 |
| 独立 2000 点训练界违反比例 | **25.55%** |
| 独立点提升模型残差 RMS | 0.128570183972288 |

训练点不确定性界没有推广到独立样本，不能支撑全域鲁棒证书。名义无扰动评估中，鲁棒变体在全部六个初值的成本均高于名义数据模型 PI；本次没有复现论文中相应性能优势，也没有开展对抗扰动实验来证明鲁棒收益。

| x0 | 解析 V* | 名义数据模型成本 | 鲁棒变体成本 | 鲁棒额外成本 |
|---|---:|---:|---:|---:|
| (-1.5,-1.2) | 1.282500 | 1.282632500 | 1.282963329 | 0.036127% |
| (-0.5,1.2) | 0.782500 | 0.782546368 | 0.783138255 | 0.081566% |
| (1.5,-0.6) | 0.742500 | 0.742505643 | 0.743248660 | 0.100830% |
| (1.2,0.9) | 0.765000 | 0.765007278 | 0.765367689 | 0.048064% |
| (0.2,-1.4) | 0.990000 | 0.990020454 | 0.990608732 | 0.061488% |
| (-1.2,0.6) | 0.540000 | 0.540002844 | 0.540554266 | 0.102642% |

![冻结策略评估](https://github.com/tanjunkai2001/adp-matlab/raw/v0.5.0/reproductions/robust_koopman2026/results/validated-v03-20260907/control_comparison.png)

## 测试范围

| 自动测试 | 检查内容 |
|---|---|
| AnalyticHalfCostHjbAndValue | 独立解析 HJB 恒等式、六个初值 V*、数值积分 |
| LiftAndAmbientValueDerivatives | 原状态链式梯度、9维梯度和 Laplacian 的有限差分 |
| BilinearDerivativeRegressionOnExactModel | 独立闭合双线性系统恢复、19维秩及零残差 |
| SubgradientControlBothBranches | 活跃/零输入分支、次梯度条件、独立稠密输入网格比较 |
| InvalidRegressionRejected | 无激励拒绝、NaN 导数拒绝 |
| BoundIsSampleFitAndNotCertificate | 训练点约束、样本界标记、学习器配置不含仿真参数 |
| ExecutedNonlinearScenario | 真实非线性闭环、成本有限、终态、冻结和输入通道 |
| ViscosityAndZeroUncertaintyLimits | c1=c2=0 与 ε=0/1e-4/1e-3 的数值敏感性 |

零不确定项下，ε=0、0.0001、0.001 的 PDE RMS 分别为 8.90402312276918e-5、9.21439814633782e-5、3.96379204403799e-4，三者外迭代均收敛；策略确实随黏性变化。更小残差不自动等于更强理论结论。

静态 checkcode 扫描了全部 8 个 .m 文件，只有 3 条 AGROW 性能提示（构造 25 项字典和补足配点时增长小数组），没有其他诊断。依赖分析只列 MATLAB。未声称对其他 MATLAB 版本、GPU、外部硬件、完整 9 维 PDE 或作者代码做过测试。

## 调试和保留的负结果

首个协议采用较弱的输入偏置，训练拟合 c=0.399508202147528；30 次外迭代未收敛，PDE RMS=0.358742357931903，六点额外成本约 4.06%–25.12%。原始结果完整保存在 [debug-first-20260907](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/results/debug-first-20260907/metrics.json)。保留该例可看到：秩充足和闭环终态很小都不能证明 PI 已收敛或成本可靠。

改进采集输入后第一次 7 项测试为 6/7：NaN 导数未被主动拒绝；随后增加有限性校验，最终 8/8 通过。该失败日志和 CSV 仍保留。中间 [recalibrated-input-20260907](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/results/recalibrated-input-20260907/metrics.json) 结果是开发快照，不与最终源码哈希混用。最终版本还改为通用二次价值初猜、独立样本检查和固定 5000 配点。

证据：[测试 CSV](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/evidence/final-test-results.csv)、[完整日志](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md)、[静态检查](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/evidence/final-checkcode.json)、[依赖环境](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/robust_koopman2026/evidence/final-dependencies.json)。最终运行结果和源码哈希均可由这些文件追溯。历史失败快照只有当时原始数据和日志，未伪称绑定当前源码。
