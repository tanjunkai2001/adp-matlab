# Adaptive-dynamic-programming-algorithms 源码审查

核查日期：2026-09-07。只读审查和静态分析；未运行上游 MATLAB 代码，未核对所引论文的全文证明或图表。

## 1. 固定来源与使用边界

- 来源：<https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms>。
- 默认分支：`main`；检出 commit：`ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f`。
- commit 日期：2025-07-31T11:19:18+08:00；提交消息：`Update README.md`。
- 11 个顶层算法目录，38 个 `.m` 文件，5 个 `.mat` 文件，4 个 README；本次完整枚举 git 跟踪文件，未发现 LICENSE / COPYING / NOTICE 或测试、CI、MATLAB Project 文件。
- README 只声明 MATLAB，未声明版本和工具箱。未发现可确认的再分发许可证；公开可读不能视为允许复制进新框架。新规范应记录 URL、commit、入口和人工迁移说明，上游副本只留研究缓存；共用内核采用独立原创实现，第三方代码的分发另行核查。
- 永久树：[固定来源快照](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/tree/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f)。

## 2. 完整算法族和可提炼对象

下列覆盖按源码和 README 分类。CT VI 没有独立目录；不能把本仓库描述成 CT/DT PI/VI 四类均已有完整实现。

| 目录 | 当前演示 | 主要入口及实现 | 适合提炼的模块 |
|---|---|---|---|
| `policy_iteration` | DT 模型已知 PI，二维线性例子 | `pi_state_data.m` 生成数据；`pi_icp.m` 以 DLQR 策略初始化；`pi_algorithm.m` 训练；`pi_validation.m` 验证 | 数据集、初始可容许策略、有限时域 policy evaluation、神经网络拟合、动作优化 |
| `policy_iteration_continuous_time` | CT 模型已知 PI，4 状态线性例子 | `pi_algorithm.m`：二次基函数梯度、HJB 线性最小二乘、LQR 比较 | 二次基函数、P/权重打包约定、模型已知 policy evaluation |
| `value_iteration` | DT 模型已知 VI，线性例子 | `vi_state_data.m`、`vi_algorithm.m`、`vi_validation.m` | 一步 Bellman target、actor/critic 交替更新、独立冻结验证 |
| `value_iteration_positive_semi_definite_initial_value_function` | DT 以正半定初值命名的 VI 例子 | `vi_pf_main.m` + 独立 actor/critic basis、cost、plant | 线性参数 critic/actor、解析参照；初值实际利用存在下述风险 |
| `integral_reinforcement_learning` | CT 部分模型已知 on-policy IRL | `irl_main.m`、`irl_ode.m`：状态与代价增广积分、拟合 P、已知 B 改进 K | 片段积分数据、integral Bellman regression、秩与可辨识性门槛 |
| `model_free_integral_reinforcement_learning` | CT parallel control，两个例子、各两个 case | `eg1/eg1_c1_main.m`、`eg1/eg1_c2_main.m`、`eg2/eg2_c1_main.m`、`eg2/eg2_c2_main.m` | 输入动态增广、已知增广输入通道、积分 critic 更新、actor 更新阈值 |
| `model_free_nonzero_sum_games` | CT 两玩家非零和博弈及 CACC | `eg_two_player_ndg/tndg_model_free_learning.m`、`eg_cacc/cacc_model_free_learning.m` | 玩家索引、各玩家代价、增广输入、历史数据栈 |
| `model_free_nonzero_sum_games_discrete_time` | DT 两玩家线性/非仿射博弈 | `eg1/tps_linear_model_free_learning.m`、`eg2/tps_nonaffine_model_free_learning.m` | 转移批次、各玩家 critic/actor、输入增量执行 |
| `online_learning_policy_update` | DT online policy update | `puol_algorithm.m`：历史状态/代价窗、critic least squares、模型已知动作优化 | 在线批次、状态重置事件、学习与控制更新时序 |
| `online_learning_without_initial_admissible_control` | CT online learning | `ol_algorithm.m`：Lyapunov 条件学习项、探测噪声 | 候选 Lyapunov 数据、连续权重动力学、噪声和实际输入区分 |
| `parallel_control_based_optimal_tracking` | CT 非仿射 tracking | `pc_ot_adp_main.m`、`pc_ot_adp_ode.m`、基函数梯度 | 参考生成器、输入增广、原始/增广代价分开记录 |

## 3. 逐类源码证据

所有链接均固定到本次 commit。

### DT PI/VI

- DT PI：`policy_iteration/pi_algorithm.m:12-38` 使用全局 A/B/Q/R、相对路径 MAT 文件、`newff(...,'trainlm')`；`40-74` 将 400 步有限和作为 policy evaluation target，并用 `fminunc` 拟合改进 actor；`85` 保存覆盖固定训练结果。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/policy_iteration/pi_algorithm.m#L12-L85)
- `policy_iteration/pi_icp.m:6-26` 用 DLQR 得到初始策略，`cover=1` 导致直接重训并覆盖 actor；`pi_validation.m:18-36` 的实际代价为 50 步和，`Jopt=x0'*Popt*x0` 是无限时域解析值。这两者不能无尾项说明直接作为同口径最优性差距。[初始化](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/policy_iteration/pi_icp.m#L6-L26)；[验证](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/policy_iteration/pi_validation.m#L18-L36)
- DT VI：`value_iteration/vi_algorithm.m:54-81` 通过 actor 优化构造目标，critic 使用旧值函数的一步目标；`81` 强制 x 与 -x 共享 target。这对于当前对称线性/二次案例有结构依据，不能不经检查用于一般非线性问题；`54,64` 的 actor target 按单输入分配/写入，不是通用多输入实现。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/value_iteration/vi_algorithm.m#L54-L87)
- 正半定初值 VI：`vi_pf_main.m:16-35` 指定并记录非零初值，但第 1 次循环没有改进 actor，`60-67` 将 critic 直接重拟合为零输入 stage cost，覆盖初值而未将旧值带入第 1 次 Bellman target。静态可见：设定的初值影响初始展示点，但从第 1 次覆盖后迭代不依赖其数值。是否违背对应论文算法需按论文递推式另审，不能据目录名判定已复现该理论。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/value_iteration_positive_semi_definite_initial_value_function/vi_pf_main.m#L16-L67)

### CT PI 和 IRL

- CT PI：`policy_iteration_continuous_time/pi_algorithm.m:12-34` 明确 A、B、Q、R，并用 LQR 初值和参考；`44-53` 随机训练点；`67-86` 计算二次基函数梯度、`u=-0.5 R^{-1}B' dphi' w`、用模型方向导数构造回归。这是模型已知基线，值得作为单元验证 oracle，不应混入 model-free 标签。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/policy_iteration_continuous_time/pi_algorithm.m#L12-L86)
- IRL：`irl_main.m:24-36` 增广代价状态和 0.05 s 片段；`43-66` 以状态二次特征之差和积分代价拟合 P，改进 K 需要已知 B；`irl_ode.m:5-10` 在 ODE 每次调用中重算 `u=-K*x`，属于连续反馈，不是输入在采样期间零阶保持。[主程序](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/integral_reinforcement_learning/irl_main.m#L24-L70)；[ODE](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/integral_reinforcement_learning/irl_ode.m#L1-L10)
- IRL 的 `norm(X)>tol` 仅测试矩阵非零，不能保证满列秩；`pinv` 会给出欠定/病态的数值结果但没有可辨识性证据。规范中应记录奇异值、有效秩、条件数及拒绝理由，rank 不足时拒绝策略更新。

### Model-free parallel IRL

- `eg1/eg1_c2_main.m:15-24` 定义真实线性 plant 和解析参照；`eg1_c2_ode.m:10-16` 把实际输入 u 作为状态，虚拟动作 v 通过已知增广输入通道生成；`eg1_c2_main.m:69-81` 以特征差和代价积分更新 critic，达到 critic 更新阈值后跟随更新 actor。[主程序](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_integral_reinforcement_learning/eg1/eg1_c2_main.m#L15-L88)；[ODE](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_integral_reinforcement_learning/eg1/eg1_c2_ode.m#L10-L16)
- 非仿射例子 `eg2/eg2_c1_ode.m:17-21` 是带 `tanh(u)+u` 的 plant，并用 `log(1+u'Ru)` 输入代价、虚拟动作二次代价。统一 `Cost` 不能写死为 Q/R 二次型；应允许 stage function 与积分定义。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_integral_reinforcement_learning/eg2/eg2_c1_ode.m#L11-L21)
- “仿真器中写有真模型”本身不否定 model-free learning；审计边界应检查 learner 实际获得什么信息。此处应将真实 plant 隐藏在 simulator 内，明确 learner 可访问增广通道、观测、特征和代价，不给 learner 任意调用真模型的权限。

### CT/DT 非零和博弈

- CT 两玩家例子 `tndg_model_free_learning.m:27-33` 分玩家输入矩阵与耦合代价；`58-64` 注释要求秩但只按基函数数目设缓存长度；`104-107` 随机重设控制；`115-145` 维护滑动历史并累计每个玩家 critic 更新；没有运行时 rank 门槛。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_nonzero_sum_games/eg_two_player_ndg/tndg_model_free_learning.m#L27-L145)
- `tndg_model_free_learning.m:208-246` 将 plant、两个原代价、两个增广代价和权重动态封装在同一个 ODE；这是可提炼 `PlayerSpec`、`Augmentation`、`CostChannels` 的具体起点。[ODE](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_nonzero_sum_games/eg_two_player_ndg/tndg_model_free_learning.m#L208-L246)
- DT 非仿射例子 `eg2/tps_nonaffine_model_free_learning.m:103-163` 明确转移样本和输入增量 `u_next=u+v`；`233-240` 包含 `tanh(u1)` 和交叉项 `u1*u2`；`302-328` critic 回归/actor 梯度使用样本及已知增广通道。[转移与学习](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_nonzero_sum_games_discrete_time/eg2/tps_nonaffine_model_free_learning.m#L103-L163)；[plant](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_nonzero_sum_games_discrete_time/eg2/tps_nonaffine_model_free_learning.m#L233-L240)；[更新](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/model_free_nonzero_sum_games_discrete_time/eg2/tps_nonaffine_model_free_learning.m#L302-L328)
- DT critic 使用 `varphi*pinv(varphi'*varphi)`；无 rank/condition 记录，normal-equation Gram 矩阵会放大病态影响。工程层应采用显式分解并返回诊断，算法替换必须另列与原代码的差异。

### Tracking 与 online learning

- Tracking 明示实现与论文不同：`pc_ot_adp_main.m:13,32-34,60-62` 说明构造顺序和学习率差异；`73-74` 在学习中直接重设包含物理状态的增广状态；`78-90` 在同一轨迹中学习、累计代价、作图，无独立冻结策略评估。这些图不能直接视为无重置的 tracking 实验。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/parallel_control_based_optimal_tracking/pc_ot_adp_main.m#L13-L93)
- Tracking ODE `16-43` 在学习中使用非仿射 plant/参考的模型表达式和方向导数；模型信息需求必须显式标注，不能因使用 parallel control 就自动标为 model-free。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/parallel_control_based_optimal_tracking/pc_ot_adp_ode.m#L16-L48)
- DT online 的 `puol_algorithm.m:68-74` 明确说论文未解释激励实现，因此以随机状态重置替代；`162-167` 的 actor update 调用真实模型做动作优化。这是重要的 code/paper 差异清单项。[重置](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/online_learning_policy_update/puol_algorithm.m#L68-L74)；[actor](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/online_learning_policy_update/puol_algorithm.m#L162-L171)
- CT online `ol_algorithm.m:11-13` 声明全局 u，但入口没有给它初值；ODE `118` 用 u 算 dV，直到 `131` 才赋 `u=ux+probing_noise`。静态高风险：新会话可能遇到空 u 的维度错误，旧会话可能读取上次 ODE 调用的 u；应先按算法明确 dV 使用 nominal 还是实际输入，再局部计算并测试，不能盲目调整赋值顺序充当理论修正。本次未运行确认。[源码](https://github.com/lujingweihh/Adaptive-dynamic-programming-algorithms/blob/ac4ceb3d2607a5e69960c84ac2aef53e4757bc9f/online_learning_without_initial_admissible_control/ol_algorithm.m#L93-L134)

## 4. 应写入统一规范的问题和可执行处理

| 重要程度 | 位置/现象 | 原因/影响 | 新框架中的处理指令 |
|---|---|---|---|
| 高 | IRL `irl_main.m:60-66`；game 回归 | 非零矩阵/缓存装满不等于满秩；pinv 不证明可辨识 | `fitValue` 必须返回 singularValues/rank/condition/residual，rank 不足抛明确错误；拒绝更新而不伪造成功 |
| 高 | CT online `ol_algorithm.m:118,131` | 先读取全局 u 后赋值，RHS 存在跨调用状态 | ODE RHS 使用局部量；明确每个输入通道；为调用顺序不依赖历史设置回归测试 |
| 高 | PSD VI `vi_pf_main.m:60-67` | 首轮覆盖掉宣称的初值 | 为 Bellman 递推写首轮输入/输出契约；核论文公式后才决定修法 |
| 高 | tracking `main:73-74`；online `puol:68-74` | 物理状态重置改变实验问题 | 日志标 `reset_event`、原因、前后状态；学习轨迹和无重置冻结评估分开保存 |
| 高 | 所有 model-free 模块 | Simulator 的真模型与 learner 可用信息没有程序隔离 | 定义 information contract：已知 B/增广通道、可测状态、代价、导数是否允许；禁止 learner 读取 plant 私有参数 |
| 中 | DT PI/VI 验证 | 有限累计代价和无限时域 oracle 混用 | 所有指标带 horizon/discount/tail 定义；比较同一有限时域或补解析尾项 |
| 中 | 多处 `global`、入口无参数/返回值、重复 `pi_algorithm` 名称 | MATLAB path 顺序和会话残留影响结果 | 用 `+adp` 包、显式 config/state、`result=run(config)`；不要全库 `addpath(genpath(...))` |
| 中 | 多处 `rand`/`randn`，未发现 `rng` | 数据/激励/NN 初始化不可精确复现 | 保存 seed、rng algorithm 和初始/最终 RNG state；记录训练数据或其哈希 |
| 中 | `ode45`/`ode23` 无 `odeset` | `tspan` 的输出网格并非固定内部步长；默认容差隐式 | 分开写 outputTimes、samplePeriod、RelTol、AbsTol、MaxStep；标 continuous feedback/ZOH |
| 中 | `newff/trainlm`、`fminunc`、LQR/DLQR | README 仅 MATLAB，实际 API 显示额外工具箱需求 | 环境预检按用到的函数判断依赖；legacy NN backend 单独适配；核心二次基函数/LS/ODE 尽可能 base MATLAB |
| 中 | 固定相对路径 `.mat` load/save | 依赖当前目录、不可追踪旧缓存、覆盖结果 | 输出写唯一 runId；保存 resolved config、版本、原始数据；禁止默认覆盖；显式区分 generate/train/evaluate |
| 中 | VI 单输入硬编码、对称 augmentation | 换模型时悄悄改变算法或维度不匹配 | 标 dimensions 和 symmetry assumptions；加入 2 输入 shape test；默认不做隐式对称扩充 |
| 中 | 全库未见 assert/test/CI | 图像和权重展示没有自动数值门槛 | 从解析 LQR/DARE/CARE oracle、自洽 Bellman residual、梯度、秩拒绝、日志完整性五类开始 |

依赖分类来自代码调用的静态推断，未在特定 MATLAB release 中逐项解析：基础 ODE/线性代数属于核心候选；`newff/train/trainlm` 是 legacy 神经网络工作流；`fminunc` 需要优化相关产品；`lqr/dlqr` 需要控制相关产品。正式环境报告应使用安装实例的函数解析和产品版本核查，不能直接把 README 的 “MATLAB” 当成无工具箱保证。

## 5. 从该仓库提炼出的接口建议

- `ProblemSpec`：timeDomain、state/input/player dimensions、stage-cost callbacks、reference/augmentation、运行区间；真 plant 与 learner 的 known model 分开。
- `Basis`：`phi(x)`、`jacobian(x)`、weight packing、degree/scaling、对称约定。二次型必须声明交叉项系数，否则 P/权重常差 2 倍。
- `Policy`：`uNominal=policy.evaluate(t,x,state)`；actor/critic 连续更新与离散更新分别实现，不以一个含混 `step()` 混合。
- `TransitionBatch`/`IntegralBatch`：起止时间、起止状态/特征、积分 stage cost、nominal/behavior/filtered/applied 输入、reset flags、policy snapshot；积分回归不可只保留最终 X/Y 丢弃轨迹。
- `CriticFit`：weights、residual vector、singular values、numerical rank、condition、accepted/rejected reason。
- `ExecutionSpec`：continuous-feedback 或 ZOH、噪声注入位置、执行器/增广输入动态、ODE 容差；tspan 不是执行语义。
- `GameSpec`：按玩家索引策略和 cost，不将两个玩家写死成 `w1/w2`；明确各玩家可测/已知信息。
- `Experiment`：train 与 frozen evaluate 分开；逐个记录作者给出的代码/论文差异；oracle 只用于独立评估。
- `RunRecord`：seed、resolved config、MATLAB/product versions、code commit/content hash、raw trajectory、diagnostics、metrics、plots、status。不同算法的证据汇总在同一 schema 内，但不能把数值通过升格为理论证明。

## 6. 完整文件清单

清单由固定 commit 的 `git ls-tree -r --name-only HEAD` 生成。

```text
README.md
integral_reinforcement_learning/irl_main.m
integral_reinforcement_learning/irl_ode.m
model_free_integral_reinforcement_learning/README.md
model_free_integral_reinforcement_learning/eg1/eg1_c1_main.m
model_free_integral_reinforcement_learning/eg1/eg1_c1_ode.m
model_free_integral_reinforcement_learning/eg1/eg1_c1_parallel_ode.m
model_free_integral_reinforcement_learning/eg1/eg1_c2_main.m
model_free_integral_reinforcement_learning/eg1/eg1_c2_nn_pf.m
model_free_integral_reinforcement_learning/eg1/eg1_c2_nn_pf_dphi.m
model_free_integral_reinforcement_learning/eg1/eg1_c2_ode.m
model_free_integral_reinforcement_learning/eg2/eg2_c1_main.m
model_free_integral_reinforcement_learning/eg2/eg2_c1_nn_pf.m
model_free_integral_reinforcement_learning/eg2/eg2_c1_nn_pf_dphi.m
model_free_integral_reinforcement_learning/eg2/eg2_c1_ode.m
model_free_integral_reinforcement_learning/eg2/eg2_c2_main.m
model_free_integral_reinforcement_learning/eg2/eg2_c2_ode.m
model_free_nonzero_sum_games/README.md
model_free_nonzero_sum_games/eg_cacc/cacc_model_free_learning.m
model_free_nonzero_sum_games/eg_two_player_ndg/tndg_model_free_learning.m
model_free_nonzero_sum_games_discrete_time/README.md
model_free_nonzero_sum_games_discrete_time/eg1/tps_linear_model_free_learning.m
model_free_nonzero_sum_games_discrete_time/eg2/tps_nonaffine_model_free_learning.m
online_learning_policy_update/puol_algorithm.m
online_learning_without_initial_admissible_control/ol_algorithm.m
parallel_control_based_optimal_tracking/pc_ot_adp_main.m
parallel_control_based_optimal_tracking/pc_ot_adp_nn_pf_dphi.m
parallel_control_based_optimal_tracking/pc_ot_adp_ode.m
policy_iteration/pi_algorithm.m
policy_iteration/pi_icp.m
policy_iteration/pi_state_data.m
policy_iteration/pi_validation.m
policy_iteration/training_data/actor_init.mat
policy_iteration/training_data/state_data.mat
policy_iteration/training_results/actor_critic.mat
policy_iteration_continuous_time/pi_algorithm.m
value_iteration/training_data/state_data.mat
value_iteration/training_results/actor_critic.mat
value_iteration/vi_algorithm.m
value_iteration/vi_state_data.m
value_iteration/vi_validation.m
value_iteration_positive_semi_definite_initial_value_function/vi_controlled_system.m
value_iteration_positive_semi_definite_initial_value_function/vi_cost_function.m
value_iteration_positive_semi_definite_initial_value_function/vi_pf_actor.m
value_iteration_positive_semi_definite_initial_value_function/vi_pf_critic.m
value_iteration_positive_semi_definite_initial_value_function/vi_pf_main.m
value_iteration_positive_semi_definite_initial_value_function/vi_state_data.m
```
