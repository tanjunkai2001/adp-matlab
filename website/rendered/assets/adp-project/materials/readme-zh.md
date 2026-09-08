# ADP-MATLAB

[项目主页](https://tanjunkai2001.github.io/projects/adp-matlab/) · [v0.5.3](https://github.com/tanjunkai2001/adp-matlab/releases/tag/v0.5.3) · [CI](https://github.com/tanjunkai2001/adp-matlab/actions/workflows/checks.yml) · [MIT](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.3/LICENSE)

**用于自适应动态规划控制的 MATLAB 参考实现与可复现实验。**

[English](https://github.com/tanjunkai2001/adp-matlab/blob/main/README.md) · [快速开始](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/QUICKSTART.zh-CN.md) · [方法表](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/METHODS.md) · [验证记录](https://github.com/tanjunkai2001/adp-matlab/blob/main/VALIDATION.md) · [发展路线](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ROADMAP.md)

从一个积分策略迭代例子开始，逐步学习 Koopman、神经 HJB、平均场控制和控制期刊中的相关方法。每个实现都对应原始方程、MATLAB 函数、适用条件和实际结果。

<!-- SNAPSHOT:START -->
**v0.5.3：** 8个可运行入口 · 7个论文实现包 · 本地测试107/107通过 · 6个研究skill。实际环境：25.2.0.3312555 (R2025b) Update 6（MACA64）。
<!-- SNAPSHOT:END -->

<p align="center"><img src="https://github.com/tanjunkai2001/adp-matlab/raw/v0.5.3/docs/assets/baseline-reference.svg" width="640" alt="实际MATLAB基线：策略迭代逼近解析LQR增益，闭环状态收敛。" /></p>

图中使用当前双积分器例子的真实运行数据，原始CSV和配置在[`docs/assets/data`](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/docs/assets/data)中。

## 第一次运行

克隆仓库或解压源码 ZIP，然后在 MATLAB 中打开仓库根目录：

```sh
git clone https://github.com/tanjunkai2001/adp-matlab.git
cd adp-matlab
```

```matlab
check_environment();
demo_reproductions();
[result, runDir] = demo_reproductions('baseline');
result.learning.K                % 解析参照：[1, sqrt(3)]
run_tests;
```

基线只需基础MATLAB及标准JVM。全套测试另外需要Control System Toolbox与Deep Learning Toolbox。`run_all_tests('list')`列出测试；`run_all_tests`实际执行，其中一个PINN重放测试执行两次单次Adam更新，Safe PINN测试包括零更新评价，以及三种在第二次训练更新中注入的受控故障；完整神经训练另行启动。

## 已实现方法

<!-- METHODS:START -->
| 方法 / 来源 | 模型与学习机制 | 测试 | 实际复现范围 |
|---|---|---:|---|
| [积分策略迭代基线](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/GETTING_STARTED.md) · Reference baseline | 连续时间LQ，已知B | 46 | 双状态参考例子，解析LQR独立对照。 |
| [Koopman生成元与PI](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/koopman_l4dc2025) · [L4DC 2025](https://proceedings.mlr.press/v283/zeng25a.html) | 连续非线性，辨识生成元 | 8 | 归一化摆数值变体，未完整复刻原表。 |
| [平均场LQG](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/meanfield_lqg2025) · [Automatica 2025](https://doi.org/10.1016/j.automatica.2024.111924) | 连续随机系统，双增益PI | 8 | 有限样本社会优化，保留小样本失败。 |
| [离策略Q-learning](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/qlearning_tac2023) · [IEEE TAC 2023](https://doi.org/10.1109/TAC.2023.3235967) | 离散LQR，矩阵Bellman方程 | 7 | 数据驱动LQR，MIMO初始化为明确变体。 |
| [无限时域HJB PINN](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/pinn_infinite_horizon2025) · [IJRNC 2025](https://doi.org/10.1002/rnc.70028) | 神经HJB，逐步延长时域 | 5 | 缩小网络的LQR/摆训练，标明四次代价修正。 |
| [安全epigraph PINN](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/safe_pinn_icml2025) · [ICML 2025](https://proceedings.mlr.press/v267/tayal25a.html) | Epigraph HJB神经值函数 | 13 | 船舶场景，仍存在碰撞和预算违例。 |
| [鲁棒Koopman PI](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/robust_koopman2026) · [Preprint 2026](https://arxiv.org/abs/2604.05633) | 提升双线性模型，鲁棒PI | 8 | 留出点中25.55%违反拟合误差界。 |
| [偏置策略迭代](https://github.com/tanjunkai2001/adp-matlab/tree/v0.5.3/reproductions/bias_pi_automatica2026) · [Automatica 2026](https://doi.org/10.1016/j.automatica.2026.112821) | 未知连续非线性系统，固定数据 | 12 | 摆/机械臂变体，臂成本比局部LQR高8.84%。 |
<!-- METHODS:END -->

测试计数描述代码检查，复现范围描述与论文的数值对应关系。安全PINN违例、鲁棒Koopman误差界失效和Bias-PI性能未优于参照等结果仍明确保留。

## 目录与使用方式

| 目录 | 作用 |
|---|---|
| `src/+adp` | 小型共享库：模型、基函数、积分PI、仿真和结果保存。 |
| `reproductions` | 各篇论文的直接MATLAB函数，保留各自的数据与数学契约。 |
| `registry` | 论文、方法、工具箱依赖和实际状态的统一登记。 |
| `docs/fulltext` | 全文阅读卡、公式映射、参数差异和复现范围。 |
| `templates` | 接入新方法、对应方程和记录实验的模板。 |
| `.agents/skills` | 编码、复现、理论、安全、实验比较、Simulink六个可选工作流程。 |

新实验进入`runs/`。大型历史数据以版本附件保存，源码仓库保持轻量。参见[贡献指南](https://github.com/tanjunkai2001/adp-matlab/blob/main/CONTRIBUTING.md)、[数据附件说明](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md)和[公开版本计划](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/RELEASE_PLAN.zh-CN.md)。

下一步优先完整迁移FxT-CL-ACI，再增加一个约束执行例子和一个机器人/Simulink例子。43个算法条目中还有35个规划项，不能把登记目录视为已实现能力。

## 引用与许可

使用[CITATION.cff](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.3/CITATION.cff)中的软件信息，并同时引用所使用方法的原论文。请记录软件版本或commit。当前尚未分配软件DOI。

独立编写的软件和项目文档采用 [MIT 许可证](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.3/LICENSE)。原论文 PDF、上游源码压缩包和作者 checkpoint 不随源码分发，仍适用各自条款。来源及推理适配器的归属见 [THIRD_PARTY](https://github.com/tanjunkai2001/adp-matlab/blob/main/THIRD_PARTY.md)。

维护者：[Junkai Tan / 谭浚楷](https://tanjunkai2001.github.io/)。
