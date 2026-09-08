# 核心 ADP / Control RL 补漏研究（截至 2026-09-07）

已取得并定向阅读 **2023–2026 范围内 8 篇完整 PDF 的正文方法、假设和所列定理**；另补读 1 篇 2019 年有限样本历史核心论文。附录证明只以逐篇记录为准，未进行全篇形式化证明审计。2026 年 Lin–Huang 综述仅取得出版社索引与书目，不计入全文数量。未运行作者代码，也不声称检索穷尽。

## 与当前 v0.2 的对照

本轮对照 `docs/DESIGN.zh-CN.md` 和 `registry/algorithms.json`。当前设计已有 CT/DT PI、VI、Q-learning、off-policy IRL、output-feedback、stochastic 等规划标签，但只有 CT、已知 B、确定性、on-policy integral PI 基线实现。遗漏主要是这些标签内的不同数学前提和数据契约，不宜把每篇论文机械扩成一个互不相通的包。

| 优先级 | 当前缺口 | 必须落实的接口 | 主证据 |
|---|---|---|---|
| P0 | PI 默认从稳定 K0 开始，却缺少如何取得 K0 | initializer 独立；稳定性类别、辅助/真实系统、candidate/certified、阶段与停止条件 | Li–Dong；Cao 等 |
| P0 | CT/DT output-feedback 共用笼统标签 | DT 历史提升 / CT 滤波提升分开；lag/order、投影、部署内存、导数来源 | Alsalti 等；Xie 等 |
| P0 | 所有方法套用同一秩门槛和 critic | informativity 对象/维数由算法声明；critic 可空；投影与容差可追踪 | Wu 等；Alsalti 等 |
| P0 | 随机目标沿用确定性总成本与 Bellman 回归 | average-cost、噪声偏置、重置事件、期望估计、经验/总体 Gram 分开 | Cui 等；Cao 等 |
| P0 | 稳定与收敛证据没有足够区分估计模型、线性化和真实系统 | guarantee.target / stability.kind / model_version / error_bound | Wallace–Si；Song–Iannelli；Cao 等 |
| P1 | IRL 不区分输入探索、参考探索与分散耦合知识 | exploration.port、w/g/B 知识、loop_partition、条件数诊断 | Wallace–Si |
| P1 | 在线辨识与 PI 更新是两个并列模块 | 时间戳、协方差、误差界及采样/辨识/改善顺序组成间接 PI 契约 | Song–Iannelli |
| P1 | “有限数据实验”容易误写成有限样本理论 | 证据区分 exact-expectation、asymptotic、finite-sample-bound；记录置信度与 T0 是否可计算 | Cui 等；Cao 等 |

## 逐篇记录

### wallace-si-eirl-2025
**Continuous-Time Reinforcement Learning: New Design Algorithms With Theoretical Insights and Performance Guarantees** — Brent A. Wallace; Jennie Si。IEEE TNNLS 36(4):6940–6954，2025-04；DOI 含 2024，所读文本为 2023 arXiv v1，未作版本逐字比较。
[全文](https://arxiv.org/pdf/2307.08920v1)；[DOI](https://doi.org/10.1109/TNNLS.2024.3392237)；arXiv 2307.08920v1。日期：{"submitted": "2023-07-18", "journal_issue": "2025-04"}。

实际阅读：Table I、Remark 2.2；§III.A–D，Algorithm 1，式 (18)、(22)–(32)；Theorems 4.1–4.3、Remarks 4.1–4.2；§V.B 条件数讨论。

知识/数据前提：连续时间、固定二次值函数/线性反馈；K0 使线性化闭环 Hurwitz。 非线性耦合 EIRL 需 x,u,w=f−Ax,g；线性版本需 B。分散耦合版本需对应输入行 B_j、非对角 A_jk；并非所有模型量都未知。

残差/算子：积分线性回归 Θ_i v(P_i)=Ξ_i；非线性漂移校正项与输入/参考激励显式进入回归。 秩检查对象 I_B(x,x)，并记录回归奇异值、条件数及列缩放。

保证与边界：精确、满秩数据及初始稳定条件下，与 Kleinman 迭代等价；P 单调、线性增益稳定并收敛。 非线性例子中的定理目标是线性化 CARE，不等于全局非线性最优性。 分散定理是各环路条件化结论；不能自动提升为任意耦合非线性整体安全。 参考端激励改善所示条件数，不自动构成 PE 证明；论文条件数为其报告结果，未复现。

模块动作：新增 learner.knowledge 的 w/g/B/off_diagonal_A 字段；exploration.port=input|reference；loop_partition 与耦合证据。 诊断记录原始/缩放回归的 singular_values、condition_number；保证对象记录 linearization|loop|full_system。

代码：[https://github.com/bawalla2/TNNLS-2023---dEIRL](https://github.com/bawalla2/TNNLS-2023---dEIRL)；论文参考文献报告链接，GitHub 仓库页面可打开；未审计源码、未运行。
本地 PDF：`local research copy (not distributed)`；SHA256 `396d5ec4c123ba723cce551f8619f05868866e9948d145a216db5ca49320c925`。

### li-dong-damping-pi-2025
**Data-Based Efficient Off-Policy Stabilizing Optimal Control Algorithms for Discrete-Time Linear Systems via Damping Coefficients** — Dongdong Li; Jiuxiang Dong。arXiv 预印本；本轮未核得正式发表 DOI。
[全文](https://arxiv.org/pdf/2412.20845v2)；arXiv 2412.20845v2。日期：{"submitted": "2024-12-30", "revised": "2025-03-19"}。

实际阅读：§III–V；Theorems 1、3、4；Algorithms 1–2；式 (14)–(16)、(27)、(33)、(59)，Remarks 6–10。

知识/数据前提：未知 A,B，已知 n,m,Q>0,R>0；系统可稳定；确定性且离线数据满足相应完整秩条件。 原系统初始稳定增益可未知；首先选择足够小阻尼，使辅助缩放系统可从零增益开始。

残差/算子：辅助系统的 Lyapunov/二次 Q 参数回归；两种参数化有不同未知量维数与秩目标。 累计缩放 c 与每步阻尼增量共同决定迭代对象。

保证与边界：文中条件下初始化阶段取得原系统稳定增益，再标准 PI 收敛。 辅助系统稳定不代表该步增益已稳定真实原系统；须等累计因子越过指定阈值。 无初始稳定策略要求不等于开放环采集安全；所读定理不提供噪声有限样本保证。

模块动作：新增 initialize.damping/homotopy，记录 phase、cumulative_factor、auxiliary_dynamics、original_system_certificate。 policy_eval 参数化与 rank_target 分离；允许复用固定行为批次，不将每次目标增益误记成行为策略。

代码：所读正文未发现代码链接；未据此断言代码不存在。
本地 PDF：`local research copy (not distributed)`；SHA256 `39efb4de289222475427e8518f27883b86fd17be6d90821830770b5ea645360e`。

### alsalti-output-q-2024
**An efficient data-based off-policy Q-learning algorithm for optimal output feedback control of linear systems** — Mohammad Alsalti; Victor G. Lopez; Matthias A. Müller。L4DC 2024，PMLR 242:312–323；所读为正式会议 PDF。
[全文](https://proceedings.mlr.press/v242/alsalti24a/alsalti24a.pdf)；arXiv 2312.03451v2。日期：{"submitted": "2023-12-06", "arxiv_revised": "2024-08-20", "conference_year": "2024"}。

实际阅读：§2–3；式 (5)–(7)、(20)、(28)；Lemma 3、Algorithm 1、Theorem 6、Remarks 5、7。

知识/数据前提：未知最小实现 A,B,C；DT，状态不可测但 u,y 可测；可控、可观，已知系统阶 n 与 observability lag ℓ。 输入 PE 阶 ℓ+n+1；初始提升反馈 K0,z 必须稳定，可用数据 deadbeat/LMI 构造。

残差/算子：由有限输入输出历史和 Γ 构造 z；rank[Z0;U0]=m(ℓ+1)+n。 选取线性无关数据列求广义离散 Lyapunov 方程 (28)，由 Θ_uu 与 Θ_uz 更新反馈。

保证与边界：精确数据和上述条件下每次策略稳定、迭代二次收敛。 Remark 7 明确未完成噪声理论分析，不能把其有限噪声数值表现写成有噪输出反馈保证。

模块动作：新增 observation.history_lift：n、lag、Γ、raw/lifted_dim、column_selection、warmup。 为提升后的 Q 回归给独立 rank_target 和状态内存更新契约；稳定初始化成为前置组件。

代码：[https://doi.org/10.25835/zmlriehg](https://doi.org/10.25835/zmlriehg)；浏览工具失败后，经 DOI 直接请求读到 LUH 机构数据仓库落地页。页面有 MATLAB ZIP、comparison_QL_SDP.m 入口、CVX 依赖，标 CC BY-NC 3.0。仅核落地页，未解包或运行。
本地 PDF：`local research copy (not distributed)`；SHA256 `871997bc531f9826245c36da013dae6358a1db376c5809fc06548f42749be434`。

### cui-stochastic-rlsvi-2026
**A Fully Data-Driven Value Iteration for Stochastic LQR: Convergence, Robustness, and Stability** — Leilei Cui; Zhong-Ping Jiang; Petter N. Kolm; Grégoire G. Macqueron。IEEE TNNLS Early Access，2026；所读为 arXiv v4。Crossref 仅给年份及页 1–10。
[全文](https://arxiv.org/pdf/2505.02970v4)；[DOI](https://doi.org/10.1109/TNNLS.2026.3675892)；arXiv 2505.02970v4。日期：{"submitted": "2025-05-05", "v2": "2026-01-07", "v3": "2026-03-17", "v4": "2026-05-04"}。

实际阅读：§2.1–2.4、§3、§4.2–4.3；Algorithm 1；Assumptions 1–2；Theorems 3–4、Propositions 1、4、5；式 (9)–(10)、(22)–(29)。

知识/数据前提：DT 加性 iid 高斯过程噪声；未知 A,B,S,R，但观测逐步成本；v4 假设 S>0,R>0 及可稳定。 平均成本目标，存在常数噪声偏置；行为采样可重置状态，采样 Kc 不必稳定。 重置诱导不变分布下总体特征 Gram 正定；不是仅要求一批经验矩阵满秩。

残差/算子：归一化二次特征附加截距，条件期望 Bellman 关系含 μ(P)=tr(C′PC)。 缓存 Θ_T、Ψ_T、Ξ_T 并构造值迭代映射；Schur complement 更新。

保证与边界：小评估扰动下值迭代 ISS；固定有限误差通常只收敛到邻域。 足够长数据使最终误差任意小的渐近/存在性结论（Theorem 4）。 Theorem 4 的 T0 存在性不是给定置信度的可计算非渐近样本复杂度。 原始 x_next 与 reset 后状态不得混写；物理实验是否可重置另需满足。 未稳定行为策略在无重置真实系统上的安全不由此证明。

模块动作：新增 cost.objective=average；bias/intercept 参数块；noise.class 与 reset_before/after 数据。 新增 empirical_rank 与 population_informativity 分开的证据，inexact_eval_budget、PSD/Schur/Q_uu 检查。 VI 初始化不沿用 PI 稳定 K0 契约，显式记录 reset_sampling 依赖。

代码：所读正文未发现代码链接；未据此断言代码不存在。
本地 PDF：`local research copy (not distributed)`；SHA256 `4ce5c077f679cf9a122b90c2fe3efbaec73faa1caa120912873241907c8e192a`。

### song-iannelli-noisy-indirect-pi-2025
**Robustness of Online Identification-based Policy Iteration to Noisy Data** — Bowen Song; Andrea Iannelli。at – Automatisierungstechnik 73(6):398–412，2025-05-28；Crossref DOI/卷页已核。所读为 arXiv v2/作者稿。
[DOI](https://doi.org/10.1515/auto-2024-0164)；[全文](https://arxiv.org/pdf/2504.07627v2)；arXiv 2504.07627v2。日期：{"submitted": "2025-04-10", "revised": "2025-04-11"}。

实际阅读：§2、§3、§4；Algorithms 2–3；Assumptions 1–4；Theorems 3–5。

知识/数据前提：未知可稳定 DT A,B；先 RLS 估计模型再 PI，属于间接数据驱动控制。 区分逐点有界噪声与有限能量噪声；目标是无噪名义系统最优增益。 局部持续激励、数据有界；某些结论另要求估计模型始终可稳定或初始估计误差足够小。

残差/算子：RLS 参数误差/协方差，结合估计模型下 Lyapunov 评估与策略改善。 Alg.3 的评估、采样、辨识和改善时序必须保留。

保证与边界：RLS 误差对有界噪声 ISS；减弱/有限能量噪声条件下进一步收敛。 附加定量初始化条件可保证真实闭环稳定。 估计模型稳定不保证真实 A+BK 稳定；文中明确 on-policy 数据有界不能自动获得。 固定有界噪声通常留偏差/误差界，不能写成精确最优收敛。

模块动作：新增 indirect_rl 分支及 model_estimate 的 timestamp、covariance、excitation、error_bound。 分开 estimated_model_stability/plant_stability，控制采集策略和模型/策略更新时序。

代码：[GitHub](https://github.com/col-tasas/2024-SysIDbasedPIwithNoisyData)；正文给出链接；实际打开仓库页、README 和目录，页面标 MIT。未审计源代码或运行。
本地 PDF：`local research copy (not distributed)`；SHA256 `fe2ff66ad924fa4f87a5302ce751d2b15d6ffd54ab5d7f4d463f7e0cbf05a1c5`。

### wu-critic-free-ctpi-2026
**Data-Driven Critic-Free Policy Iteration for Continuous-Time Linear Quadratic Regulation** — Jiacheng Wu; Yang Zhu; Hongye Su。arXiv v1 预印本，未核得正式发表。
[全文](https://arxiv.org/pdf/2607.08204v1)；arXiv 2607.08204v1。日期：{"submitted": "2026-07-09"}。

实际阅读：§II–III；式 (6)–(26)、(31)–(36)；Assumptions 1、3；Lemma 1、Proposition 1、Theorems 1–3、Corollary 1、Algorithm 1。

知识/数据前提：未知 CT A,B，已知 Q,R，状态和输入可测；已知稳定 anchor F。 可稳定及 (A,Q^(1/2)) 可检测；数据 u=−Fx+v。 端点矩阵 D 的核投影消去 critic；投影后 actor 回归秩必须等于 mn。

残差/算子：D 由端点 xx′ 差，X,Z 由区间 ∫xx′、∫vx′；W 为 ker(D) 的正交基。 式 (25) 只求 mn 个增益参数；critic P 无需显式估计。

保证与边界：精确投影秩条件下 actor 更新与 Kleinman 等价，继承稳定与收敛结论。 输入 PE 不能直接替代投影后 actor informativity；仍需稳定 anchor。 定理不是带噪端点投影的误差保证。 Algorithm 1 的正规方程求逆不能直接当作通用数值实现规范。

模块动作：learner.critic 可空；增加 endpoint_annihilator 的构造、SVD 容差与 rank_target=mn。 记录 anchor_policy 和 actor_map 证据；实现用 QR/SVD 并记数值实现差异。

代码：所读正文未发现代码链接；未据此断言代码不存在。
本地 PDF：`local research copy (not distributed)`；SHA256 `acc9aeac1d797393a81f55fc2b088ec0027ee99a2d26d3d7e271dfbe5d0a5c9e`。

### xie-ct-output-pivi-2026
**Data-Enabled Policy and Value Iteration for Continuous-Time Linear Quadratic Output Feedback Control** — Jun Xie; Yuan-Hua Ni; Yiqin Yang; Bo Xu。arXiv v1 预印本，未核得正式发表。
[全文](https://arxiv.org/pdf/2603.14386v1)；arXiv 2603.14386v1。日期：{"submitted": "2026-03-15"}。

实际阅读：§2、§3 的提升秩/投影构造、§4.2–4.3、§5 的系统阶讨论；Theorem 3.1、Lemma 3.4、Propositions 4.5–4.6、Algorithms 1–2、Remarks 4.4、4.7；式 (16)、(30)、(32)–(33)。

知识/数据前提：未知 CT A,B,C，x 不可测，u,y 可测；假设 (A,B) 可控、(A,C) 与 (A,Qx^(1/2)) 可观。 已知稳定滤波器与自治初值通道，需满足文中光滑 PE 条件；一般 ZOH 探索不自动满足。 PI 需要稳定初始提升反馈；VI 使用半正定初值、递减步长与扩展集合。

残差/算子：输入/输出滤波状态有冗余，通过 QR 投影取有效坐标；广义 Sylvester 方程评估。 滤波状态导数由已知滤波器方程得到，并非数值差分原始 y。 VI 的步长、投影及越界后内部重置是算法组成部分。

保证与边界：在文中精确数据及结构条件下，提升坐标中的 PI/VI 与目标 CT 输出反馈 LQ 解相连。 滤波器结构表述使用 n，文中又以数据秩推出 n；自动阶数获取/滤波器阶选择的采集闭环仍需复现澄清。 未读到噪声下稳健秩判定/端到端有限样本证书。 PI 内部或 VI 集合重置不是物理系统重置。

模块动作：新增 observation.filtered_lift：filter_coefficients、initial_state_channel、QR_basis、rank_tolerance、derivative_provenance。 新增 VI stepsize/projection/algorithm_reset；矩阵方程求解器独立于数据采集。

代码：所读正文未发现代码链接；未据此断言代码不存在。
本地 PDF：`local research copy (not distributed)`；SHA256 `965d92dc841e46282a60c29d9b1974e960d1f5a2d301fdf7437324acbdbdf09f`。

### cao-stochastic-stabilizer-2026
**Stabilizer Design for Policy Iteration in Stochastic Linear Quadratic Control: A Spectrum-Assignment Approach** — Xinyu Cao; Bing-Chang Wang; Ying Cao。arXiv v1 预印本，未核得正式发表。
[全文](https://arxiv.org/pdf/2608.05953v1)；arXiv 2608.05953v1。日期：{"submitted": "2026-08-06"}。

实际阅读：§II；§III 的谱平移解释；§IV.A–E；Assumptions 1–2、4–5；Theorem 1、Theorem 2、Corollary 1、Algorithm 2；式 (2)–(4)、(10)–(17)、(39)–(41)、(63)、(83)、(85)。附录证明未逐项读。

知识/数据前提：CT 状态/控制相关乘性 Wiener 噪声；未知 A,B,C,D；均方可稳定。 不定 Q,R，但要求严格可行的 SARE/LMI 集合非空，且 R+D′PD>0。 理论数据回归使用精确期望、对应阶段满秩；有限数据用样本均值估计。

残差/算子：Phase I 用辅助正定 Qa,Ra 和 Lyapunov 算子谱平移找稳定增益；Phase II 恢复原不定代价。 回归同时估计 P 与漂移/扩散耦合参数；秩、最小奇异值、拟合残差及 R+Γ 正定为数值诊断。

保证与边界：Theorem 2 是条件证书：精确期望、步长/秩成立，且累计因子达到阈值时才保证原系统均方稳定。 Corollary 1 在这些条件下恢复不定 SLQ PI 单调收敛。 Algorithm 2 明确输出有限数据候选 stabilizer；残差小和样本矩阵满秩不能提升为 Theorem 2 的精确期望证书。 条件 if Phase I reaches 不等于证明任意有限数据运行必定有限步到达。 Hurwitz(A−BK) 不足以证明有乘性扩散的均方稳定。

模块动作：新增 stability.kind=mean_square 与 Lyapunov_operator；噪声 drift/diffusion 参数化。 cost 允许带严格可行性证据的不定权重；原目标与辅助初始化代价分开。 initializer 输出 candidate|certified 和期望估计来源，严禁经验诊断自动变成均方稳定证明。

代码：所读正文未发现代码链接；未据此断言代码不存在。
本地 PDF：`local research copy (not distributed)`；SHA256 `739518f7f288425aeedb6357baeaa24759d1f568274aaefc618ac8d52f7b465e`。

## 没有补成“已读”的文献

- **Lin, Liquan; Huang, Jie (2026)**, *Data-driven control for continuous-time linear systems via integral reinforcement learning: An overview*, [DOI](https://doi.org/10.1016/j.jai.2026.08.004)。出版社索引显示 2026-08-22 online / pre-proof；直接 HTML/PDF 请求失败，API XML 只有 coredata。输出调节、协同调节和内模路线是后续补读线索，不能据摘要认定其定理细节。
- **Song–Iannelli (2024)**, *The Role of Identification in Data-driven Policy Iteration: A System Theoretic Study*, [arXiv 2401.06721v2](https://arxiv.org/abs/2401.06721)。已下载，尚未定向读正文，不计入 8 篇。
- **Wallace–Si (2024)**, *A New, Physics-Informed Continuous-Time Reinforcement Learning Algorithm with Performance Guarantees*, [JMLR 25(400)](https://jmlr.org/papers/v25/24-0017.html)。已取得 PDF；本轮未读正文，不能与 EIRL 论文当作同一篇，也不计数。

## 历史方法和有限样本缺口

2023–2026 文献不能替代 Kleinman/Hewer、integral RL、经典 off-policy IRL、LSTD-Q/LSPI 的历史母方法。本轮补读 **Karl Krauth; Stephen Tu; Benjamin Recht (2019)**, *Finite-time Analysis of Approximate Policy Iteration for the Linear Quadratic Regulator*，[NeurIPS 正式 PDF](https://papers.neurips.cc/paper/9058-finite-time-analysis-of-approximate-policy-iteration-for-the-linear-quadratic-regulator.pdf)，arXiv 1905.12842。实际读 §2.1–2.2、Theorems 2.1–2.2、Algorithms 1–2、式 (2.3)–(2.14)，未读另载的扩展版证明。

该文对稳定行为/评估策略下的 LSTD-Q 给出带置信度的有限样本参数误差界，并对每轮新数据的 LSPI 给出稳定性和策略精度保证。其平均成本回归包含过程噪声偏置修正；界依赖稳定暂态、探索方差、噪声和初始协方差。**定理分析 Algorithm 2 每轮新批次；Algorithm 1 固定批次复用的分析被明确留待后续。** 不能把两种数据策略在接口中合并后继续引用同一定理。

模块上需增加 `finite_sample_contract`（delta、error_target、burn_in、stability_envelope、noise_covariance_knowledge、exploration_variance）和 `batch_reuse`。Cui 等的充分长数据阈值存在性与 Cao 等的精确期望证书仍不能替代这类非渐近界。该接口的实现暂未验证。代码链接未核得；本地 `local research copy (not distributed)`，SHA256 `57e87b66448363f035752084e5efb7832361e69dff76f6e32962a8655157c8ad`。

## 执行建议

先补注册表与数据/学习器契约，再选一条额外可执行基线。优先 DT off-policy Q-learning + 明确稳定初始化；随后做 DT 输出历史提升。CT EIRL 的参考激励与条件数诊断可在现有线性基线上作为独立变体。2026 年预印本中的 critic-free、滤波输出 PI/VI、不定随机 SLQ 首先进入 theory-derived / prototype-only 注册状态，不能仅因公式可编码就提升为可复现实现。

每条实现至少给出：数据生成和行为策略、学习器可见知识、算法专属回归未知量与 informativity、实际使用输入、初始化证据、残差定义、保证对象和容许噪声，以及失败后输出的状态。哈希和逐篇结构化记录在 `core-papers.json`。
