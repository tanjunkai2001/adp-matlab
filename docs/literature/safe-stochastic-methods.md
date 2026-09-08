# 随机、安全、风险与多智能体 ADP：v0.2 接口缺口核查

核查日期：2026-09-07。检索时间窗为 2023–2026-09-07，实际精读样本是 9 篇 2024–2026 代表论文。这是针对仓库设计的定向取样，不是穷尽综述。完整书目信息、PDF SHA-256、实际阅读范围与代码核查状态在 [safe-stochastic-papers.json](safe-stochastic-papers.json)。论文 PDF、提取文本和 Crossref 元数据保存在 `papers/safety/`。

这里的 `fulltext_read=true` 表示已经取得整篇全文，并阅读记录中的问题定义、关键数学条件和算法正文；不表示逐页通读所有附录，更不表示已经独立复证。没有执行任何论文代码或仿真。下列模块名均是设计建议，未修改输出仓库。

## 最应补充的内容

当前 `docs/DESIGN.zh-CN.md` 和 `registry/algorithms.json` 已涵盖确定性 PI/VI、IRL、ACI、CL、H∞、Nash、约束与触发机制。主要缺口不是再增加几项论文名，而是 **相同算法名背后的数学问题无法由现有字段准确表达**。例如 `stochastic-shared-adp` 同时混合了物理扩散、人的随机策略和共享控制，不足以决定 Bellman 算子、可用数据与稳定性判据。

| 优先级 | 问题类别与现有缺口 | 建议接口/模块 | 支持正文 |
|---|---|---|---|
| P0：现在明确契约 | Itô 随机最优控制；现有 HJB 残差只有一阶项 | `dynamics_kind`、`drift`、`diffusion`、生成元、基函数 Hessian、Brownian 维度与随机积分器 | Feng/Wang §2、§6.1；Xu/Wang/Shen §2–3 |
| P0：现在明确契约 | 安全 actor 约束、性能 critic、Lyapunov/CBF 证书混淆 | `performance_value`、`lyapunov_certificate`、`barrier_certificate`、`backup_policy`；证书域、量词、模型误差、验证方法 | Zhao 等 §II–III；Long 等 §IV–VI |
| P0：现在明确契约 | 不确定性类型混合；稳健、风险敏感和随机不是同一字段 | `UncertaintySpec` 与 `RiskSpec` 分开；固定参数、时变扰动、物理噪声、模型歧义集、随机策略分别表示 | Long Remark V.5；Talebi/Li §2、§4；Cao 等 §2 |
| P1：近期扩展 | 仅有 Bellman 方程回归，缺少冻结批数据上的 Bellman 不等式/SDP | `training_regime=offline_batch`、数据版本/hash、噪声协方差来源、`solver_class=SDP`、矩阵残差与证书 | Esmzad/Modares §3–4 |
| P1：研究扩展 | 均值风险、平均成本、指数风险等目标无法区分 | `objective_kind`、风险函数/预算/矩条件、稳定性与风险可行性分别检查 | Talebi/Li §2、§4–5 |
| P1：研究扩展 | 单个 Nash 条目无法表达社会最优、团队 Nash 与平均场 | `PopulationSpec`、`GameSpec.equilibrium_target`、共噪声条件均值、团队规模、训练/执行信息 | Xu/Wang/Shen §2–3；uz Zaman 等 §2–4 |
| P2：可选后端 | 回报分布与分布鲁棒控制混淆；高频动作价值退化 | 分位数/回报分布表示、风险偏好、动作保持时间与缩放 | Wiltzer 等 §2–4 |
| P2：先标边界 | 连续时间跳跃 Markov 链与 diffusion 混淆 | `dynamics_kind=ctmc_jump` 可选分支；不能复用 Itô/Hessian 实现 | Cao 等 §2–3.1 |

P0 是接口与诊断规范优先，不是要求立即实现所有算法。基础 MATLAB 库无需把 SAC、NODE、quantile-DQN 或神经网络验证器设为强制依赖。

## 1. 随机模型需要改变 Bellman 算子

建议将以下表达式作为仓库内部最小化约定下的统一接口推导，而不是逐字照搬各论文的奖赏符号：

\[
dX_t=b(X_t,u_t)dt+\Sigma(X_t,u_t)dW_t,
\qquad
\mathcal L^uV=\nabla V^Tb+\tfrac12\operatorname{tr}(\Sigma\Sigma^T\nabla^2V).
\]

折扣无限时域的残差是 `ell + generator(V) - rho*V`；有限时域还需要 `V_t`。应存储 `brownian_dimension`、噪声协方差、`state_dependent`、`input_dependent`、独立/共噪声关系以及强/弱误差检查方式。基函数 Hessian 在 diffusion 问题中是必需能力，不能继续标为笼统“必要时”。[Feng/Wang 全文](https://arxiv.org/pdf/2506.08121)

随机策略平均模型时应平均 `ΣΣᵀ`，再取平方根，不能先平均 `Σ`。此外，物理 Brownian motion、探索随机数与优化迭代的 Langevin 噪声需要独立的来源与种子。Feng/Wang 的学习时间 `τ` 与物理时间 `t` 不同；其连续函数/PDE 收敛依赖额外单调性和曲率，不能转成任意特征近似 ACI 的收敛标签。[§2、§6.1](https://arxiv.org/pdf/2506.08121)

对于 `dX=(AX+Bu)dt+(CX+Du)dW`，随机 LQ greedy 更新出现 `R+DᵀPD` 和 `BᵀP+DᵀPC`。因此现有“已知 B + 二次代价”的确定性 policy improvement 不能用于控制相关扩散。可先建立一个小型随机 Riccati oracle，再接受学习算法接入。[Xu/Wang/Shen §2–3](https://arxiv.org/pdf/2410.15119v1)

建议未来验证项：Hessian 对有限差分的一致性；线性二次生成元解析检查；相同 Brownian 增量下的步长比较；均方稳定与均值稳定分开报告；`E[XXᵀ]` 与 `E[X]E[X]ᵀ` 不混用；Monte Carlo 期望近似必须有路径数量与误差统计。

## 2. 安全训练与证书需要独立对象

NLBAC 正文将 NODE、性能 critic、Lyapunov critic、主 actor、backup actor 分开，actor 训练带 CLF/CBF 条件。建议把这类方法登记为 `safe-actor-constrained-ac`。但这篇论文对确定性 ODE 采样，随机 actor 不等于物理 SDE；基于学习模型的 minibatch 约束也不自动构成真实系统全状态域证书。[Zhao 等正文 §II–III](https://arxiv.org/pdf/2401.13148)，[已打开的作者代码](https://github.com/LiqunZhao/Neural-ordinary-differential-equations-based-Lyapunov-Barrier-Actor-Critic-NLBAC)

推荐 `CertificateSpec` 至少包含：

- `certificate_kind`: CLF / CBF / stochastic Lyapunov / Bellman inequality。
- `guarantee_type`: 样本经验满足、区域统一满足、均方稳定、参数高置信稳定、实用稳定等明确枚举。
- `domain`、`excluded_neighborhood`、初始集/终端集、模型来源与误差界。
- `quantifier`: 逐状态、同一不确定参数对整个域、期望、概率；避免把量词交换。
- 风险容忍 `epsilon` 与样本置信失败率 `epsilon_bar` 分开。
- 训练损失、独立验证残差、验证器状态、实际执行输入下的证书余量分别存储。

Long 等使用的是 **轨迹内固定的随机参数**，Remark V.5 明确排除了随时间变动的随机参数；其全域 chance condition 与可训练的逐点替代损失不同。神经证书 Proposition VI.5 还保留零损失、状态覆盖、Lipschitz 界和排除原点 `δ` 邻域等条件。Remark VI.7 明确将逐点损失的全局稳定分析留作后续工作。[Long 等 §IV–VI](https://arxiv.org/pdf/2404.03017)

**复现前必须核查的一处公式—证明衔接**：所读作者稿第 8 页 Eq.(30) 将状态样本求和置于 positive-part 外，Proposition VI.5 的证明却由该总损失为零推出每个状态样本的不等式。按印出的式子，不同状态的正负项可以抵消；总和非正本身不能推出所有项非正。已渲染核对 PDF 第 8 页，图像为 `papers/safety/long-page8.png`。这是一项具体的待核问题，未据此裁定整篇论文结论；仓库不应原样接受这个损失作为独立认证门槛。应显式存储每点余量，并对训练损失与定理所需条件做分别检查。[Eq.(30)、Proposition VI.5](https://arxiv.org/pdf/2404.03017)

## 3. 离线数据、风险目标与稳健保证分开

Esmzad/Modares 提供了直接批数据 + SDP/Bellman 不等式的例子。这提示仓库不能只支持反复 Bellman 等式最小二乘。其随机 LQR 为加性 Gaussian noise；设计和保证还依赖秩、协方差、可行性与折扣条件。文中的 SNR/性能界包含真实系统和未观测噪声相关量，不能把论文中存在的界自动填为实验中可计算的证书。此条保持探索性预印本参考。[§2–4](https://arxiv.org/pdf/2409.10703v2)

建议 `DatasetSpec` 记录冻结数据版本、状态/输入/噪声观测权限、行为策略、协方差是已知还是估计、独立轨迹关系、训练/评估划分、激励与条件数。`Result` 分别记录 Bellman 等式误差、PSD 不等式余量、真实模型 oracle 误差及其可计算性。

风险应是独立的对象。Talebi/Li 的例子优化长期平均成本，并对中心化累计风险的渐近条件方差施加限制；这与折扣期望、指数成本、回报 CVaR 或 H∞ 不相同。该文的强对偶和 Algorithm 5.1 限制在 `Rc=0`、无仿射偏移等情形，并要求噪声有限四阶矩。正文最后把真正的数据驱动端到端样本复杂度留给读者，不能将它登记为已经解决有限批数据误差的算法。[§2、§4–5](https://arxiv.org/pdf/2409.10767v3)

`RiskSpec` 建议包含 `kind`、作用于瞬时代价/累计回报/证书约束、时间聚合方式、预算、所需矩条件、可用统计量和是否有单独验证。指数风险敏感 ADP 值得保留路线项；本次没有取得并精读相关 2024 JSSC 原文，因此不据摘要填写其细节实现。

## 4. 多智能体首先区分目标与信息结构

Xu/Wang/Shen 是社会成本最优的 mean-field control；uz Zaman 等是团队内合作、团队间一般和竞争的 mean-field-type game，目标为 team Nash。这两类问题不能共享一个未带目标标签的 `nash` 求解器。[Automatica 2025 作者稿](https://arxiv.org/pdf/2410.15119v1)，[MRNPG 作者稿](https://arxiv.org/pdf/2403.11345)

建议先有 `PopulationSpec` 与 `InformationSpec`：团队/代理数量、平均场统计量、共噪声下的条件均值、代理可见量、训练 oracle 权限与执行可见量。社会最优应测社会成本和有限群体误差；Nash 应测单边最佳响应收益/可利用度。MRNPG 的 independent 指独立梯度更新，其策略与成本 oracle 仍有明确的信息要求，不等于任意通信图上的邻居局部控制；其收敛还依赖耦合矩阵可逆、对角占优、梯度误差与步长。[§2–4](https://arxiv.org/pdf/2403.11345)

本轮没有充分覆盖图拓扑约束的 distributed ADP、非线性共噪声 mean-field PDE、部分可观测多智能体和一般非线性 Nash。应该保留 `information_pattern`/`graph` 扩展位，但不把这些称为已由这 9 篇覆盖的能力。

## 5. 两个适合保留、但不应强制实现的扩展

Wiltzer 等研究的 distributional 指 **回报概率分布**，并分析动作保持时间趋小时动作价值分布的退化。其 superiority/quantile 算法帮助规范 `dt`、物理折扣、分位数表示与风险偏好；不能把回报风险排序当作安全证书，也不能混称为不确定模型的 distributionally robust control。把它放在可选 `distributional_return` 后端即可。[NeurIPS 2024 正式页](https://proceedings.neurips.cc/paper_files/paper/2024/hash/55769e1208c7f45e9acc98f06279c10c-Abstract-Conference.html)，[作者实现](https://github.com/harwiltz/distributional-superiority)

Cao 等 2026 entropy robustness 论文的基本对象为有限 CTMC，生成元是跳跃率矩阵。仅“continuous-time”同名不足以归入机器人 diffusion ADP；reward/rate 联合扰动也不是普遍的精确鲁棒等价关系。现阶段以 `dynamics_kind` 和鲁棒保证方向的元数据保留入口即可。[§2–3.1](https://arxiv.org/pdf/2607.03168)

## 可供 skill 使用的检查规则

这些规则是本轮基于文献的仓库设计建议，不是宣称论文已经全部证明了这些检查器。

1. `adp-problem-contract`：先确认 ODE / DT map / Itô / jump、成本时域、目标/风险、噪声持续方式与观测权限，再选择算法族。
2. `adp-stochastic-derivation`：核对生成元二阶项、基函数 Hessian、控制相关扩散、期望回归项和随机积分器；物理时间、学习时间分别定义。
3. `adp-certificate-audit`：逐项对齐定理条件、损失聚合、验证区域和概率量词；训练通过、样本余量、全域证书与真实系统误差分别报告。
4. `adp-offline-data-audit`：冻结批数据与元数据；检查秩/条件数/协方差来源；任何性能界注明哪些量已知、估计或不可计算。
5. `adp-game-information-audit`：记录 social optimum / agent Nash / team Nash / Stackelberg 及训练—执行信息模式；选择与目标对应的验证指标。

建议在算法 registry 中新增字段而不只新增名字：`dynamics_kind`、`objective_kind`、`risk_operator`、`information_pattern`、`equilibrium_target`、`training_regime`、`solver_class`、`sample_requirements`、`certificate_scope`、`evidence_level`。派生字段须支持 unknown，不应默认认为所有假设已满足。

核查时的两个输入文件 SHA-256：

- `docs/DESIGN.zh-CN.md`: `e74c37d484efb3fd4cda35b6effcd59343fc9f93421b6f40aa6510df61bbed9e`
- `registry/algorithms.json`: `d2f4b4616562beb2b1860bbe97d75448bf3a64b5c3973d022a2d61dd72a7acab`

后续版本如已变化，应把本报告当作该快照的设计差距记录，再核对父任务的整合结果。
