# 2026 年 8 月补读：随机 LQ 博弈顺序 PI

**建议增加一个明确的随机 LQ Nash 子类，保留为 planned；不改已冻结实现。** 这篇论文直接补充了当前“随机系统”和“一般和 Nash”之间缺少的接口：控制相关扩散、逐玩家更新顺序、均方稳定可行域及 homotopy 初始化。[arXiv 原始记录](https://arxiv.org/abs/2608.17940)

论文：Karl Handwerker、Felix Thömmes、Lucas Günther、Balint Varga、Sören Hohmann，*Policy Iteration for Linear-Quadratic Stochastic Differential Games with State- and Control-Dependent Noise*。2026-08-18 提交，v1 预印本；未核实正式刊会发表。DOI `10.48550/arXiv.2608.17940`。已取得并阅读 16 页 PDF 的方法、假设、关键定理和算法正文，阅读范围详细记录在 [late-stochastic-game.json](late-stochastic-game.json)。全文 SHA-256：`a697b284f7687f539d91b71208be9c479567adf3d4eafcf86edf38293bc13e4e`。[全文](https://arxiv.org/pdf/2608.17940)

## 正文核对结果

| 要点 | 具体范围与证据 |
|---|---|
| 博弈类别 | 有限 N 玩家、非零和、无限时域无折扣 LQ；常矩阵、常增益全状态反馈。Definition 2 的偏离比较限于仍使联合系统 MSS 的常增益策略；不能标成任意非线性策略 Nash。§II，Eqs.(1)–(12)。 |
| 随机结构 | `dx=(Ax+ΣB_i u_i)dt+(Cx+ΣD_i u_i)dW`，共享单个一维 Brownian 通道。控制相关扩散带来 `D_iᵀP_iD_j` 耦合。§II–III。 |
| 顺序 PI | Algorithm 1 每次只更新一个玩家；后续玩家在包含前面新增益的 partial profile 上重新求值。Theorem 1 保证每个中间 profile 均方稳定，Proposition 1 刻画固定点。不能仅在整轮末记录策略。 |
| 收敛 | Lemma 4 要求均衡处迭代映射导数谱半径小于 1，只给局部线性收敛。Lemma 6 表明 N≥3 时顺序可能改变局部吸引性；循环移位保持谱。Theorem 2 的顺序/同时更新比较有指定加权范数条件。 |
| Homotopy | Algorithm 2 先把全部控制通道合成辅助单控制器，再从负漂移移位系统的 K=0 出发逐步移除漂移。Assumption 1 仍要求原系统存在联合均方稳定增益；无需每个玩家单独具有稳定能力。§V，Lemmas 7–10、Theorem 3。 |

## 应保留的三个限制

1. **保持 MSS 不代表从任意稳定初值全局收敛到 Nash。** 原文既允许多个稳定均衡，也给出了不同顺序在同一均衡附近可能吸引或排斥的情况。
2. **Homotopy 中间证书针对移位系统。** 在 `σ<β` 时，得到的 gain 未必稳定原物理系统；只有达到目标层或安全越过目标层后，才有原系统 MSS 结论。不能把中间控制器直接标为可部署。
3. **有限步指外层 continuation。** Theorem 3 内层采用已经收敛的辅助 PI/value 解；它未给任意浮点近似或有限批数据情况下的端到端保证。“game data”是模型/成本矩阵，这不是已证明的无模型 IRL。[§III–V 全文](https://arxiv.org/pdf/2608.17940)

Algorithm 2 和 Theorem 3 的页 12 已渲染核对，图像为 `papers/safety/late-game-page12.png`。未穷尽精读附录，未复证所有定理，未运行算法。全文与 arXiv 元数据中未找到作者代码 URL；依父任务的有界要求，没有扩查其他论文或仓库。

## 对以后接口的具体建议

下列是库设计推论，均不改变当前冻结版本：

- `GameSpec` 明确 `equilibrium_target=stabilizing_linear_feedback_Nash`、允许的单边偏离、`Q_i/R_ij`、玩家顺序与 sequential/simultaneous 更新方式。
- `StochasticModel` 保存每个玩家的 `B_i/D_i` 和噪声通道共享关系；不能默认将多个输入的噪声独立化。
- `PolicyEvaluation` 增加广义 Lyapunov 方程与其残差；`Certificate` 区分 drift Hurwitz 与 MSS，每个中间玩家 profile 都要检查。
- `InitializationSpec` 保存辅助成本、漂移移位 `β`、层级 `σ`、步长因子 `η`、内层收敛精度，以及独立的 `target_system_MSS` 状态。
- registry 以 `ct-stochastic-lq-nash-sequential-pi` 为计划子类，标记已知模型、局部收敛条件和当前只具文献证据；不把它混入 mean-field、Stackelberg 或仅邻居观测的 distributed ADP。

本次仅新增 `local research copy (not distributed)` 及工作目录中的论文证据，未修改 core 数据、`outputs/` 或任何冻结 `.m` 文件。
