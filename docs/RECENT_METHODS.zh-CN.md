# 近期 ADP 方法补漏与仓库调整

截至 2026-09-07。结论：原设计覆盖了经典方法的大类，但在初始化、学习对象、随机过程、数据质量和证书含义上仍有实质缺口。v0.2已把这些差异落实到规范、方法登记和skills；v0.3 进一步新增六篇独立方法实现，其已运行、失败和待调试状态见 [复现登记](../registry/reproductions.json)；下表保留 v0.2 调研结论，不代替当前运行状态。

本轮取得并阅读 **24篇2023–2026年相关工作的全文关键部分，另补读1篇2019年有限样本基础论文**。逐篇保存全文URL/hash、正式发表或预印本状态、实际阅读章节与未核证明。这里的“全文调研”指依据取得的完整正文核对方法、假设和关键定理，不表示逐行复证所有附录，也不声称穷尽全球所有ADP论文。搜索范围、仅摘要线索和限制见 [SEARCH_PROTOCOL.md](SEARCH_PROTOCOL.md)。

## 1. 原设计缺什么，现应怎样吸收

| 缺口 | 全文依据 | 对统一MATLAB工作的影响 | 本次状态 |
|---|---|---|---|
| 稳定初始化未独立 | [阻尼PI](https://arxiv.org/abs/2412.20845)、[随机谱配置初始化，2026-08](https://arxiv.org/abs/2608.05953) | 增加initializer；区分辅助系统与真实系统、候选策略与已满足条件的证书 | 规范/登记已补；算法待实现 |
| 默认所有方法都有critic | [Critic-free CT PI，2026-07](https://arxiv.org/abs/2607.08204) | 允许actor-only；端点消元、投影后秩和策略参数独立 | 规范/登记已补；算法待实现 |
| 输出反馈只有总标签 | [DT输出Q，L4DC2024](https://proceedings.mlr.press/v242/alsalti24a.html)、[CT输出PI/VI，2026-03](https://arxiv.org/abs/2603.14386) | 区分历史提升与动态滤波提升；保留阶数、lag、QR投影、滤波初值和导数来源 | 规范/登记已补 |
| 积分成本被视为精确输入 | [ICLR2024积分误差](https://arxiv.org/abs/2402.17375) | ODE增广成本与传感样本求积分开；记录误差来源与回归放大 | 来源字段及粗细求积对照测试已实现；BQ待实现 |
| 探索只在输入端 | [EIRL/dEIRL，TNNLS2025](https://doi.org/10.1109/TNNLS.2024.3392237) | 输入/参考端探索、线性化/全系统目标、耦合知识分开 | 规范/登记已补 |
| “随机”没有定义算子 | [随机连续PI/VI](https://arxiv.org/abs/2506.08121)、[随机VI，TNNLS2026](https://doi.org/10.1109/TNNLS.2026.3675892) | Itô生成元/Hessian、平均成本、噪声偏置、总体激励与重置采样独立 | 规范/登记已补 |
| 有限数据与有限样本理论混用 | [Krauth–Tu–Recht，NeurIPS2019](https://papers.neurips.cc/paper/9058-finite-time-analysis-of-approximate-policy-iteration-for-the-linear-quadratic-regulator.pdf) | 每轮新样本和固定批次复用须匹配定理；记录置信度、混合/激励和可计算误差界 | 规范/复现检查已补 |
| 在线辨识与PI没有完整时序 | [有噪间接PI，2025](https://doi.org/10.1515/auto-2024-0164) | 保存模型时间戳、RLS协方差和误差界，区分估计模型稳定与真实闭环稳定 | 规范/登记已补 |
| 安全只分惩罚/变换/过滤 | [NODE约束actor](https://arxiv.org/abs/2401.13148)、[分布鲁棒证书](https://doi.org/10.1109/OJCSYS.2024.3440051) | 增加直接约束策略、独立证书及备用策略；明确样本/期望/全域条件 | 规范/登记已补 |
| 风险/不确定性共用一栏 | [Ergodic risk](https://arxiv.org/abs/2409.10767)、[CT分布优势，NeurIPS2024](https://arxiv.org/abs/2410.11022)、[CTMC熵鲁棒性，2026-07](https://arxiv.org/abs/2607.03168) | 参数分布、回报分布、策略熵与物理噪声分开；不同风险成本独立 | 可选扩展登记 |
| 所有算法都解Bellman等式 | [一次离线批数据SDP](https://arxiv.org/abs/2409.10703) | Bellman inequality、PSD残差和噪声数据集需单独接口 | 探索性方法登记；预印本待独立验证 |
| 平均场被并入普通Nash | [社会最优LQG，Automatica2025](https://doi.org/10.1016/j.automatica.2024.111924)、[合作竞争团队](https://arxiv.org/abs/2403.11345) | 社会最优/团队Nash、共同噪声/独立噪声、总体均值和有限群体误差分别定义 | 可选扩展登记 |
| 特征只有手工基函数 | [Koopman PI，L4DC2025](https://proceedings.mlr.press/v283/zeng25a.html)、[KAE-LSPI，2026-03](https://arxiv.org/abs/2603.26464)、[鲁棒Koopman，2026-08版本](https://arxiv.org/abs/2604.05633) | 字典辨识与价值特征分开；支持双线性结构、字典冻结和误差界 | 可选表示/模型后端 |
| HJB只有稳态残差 | [有限时域PINN，IJRNC2025](https://doi.org/10.1002/rnc.70028)、[安全HJB，ICML2025](https://proceedings.mlr.press/v267/tayal25a.html) | 加时间导数、终端/边界、epigraph变量、HJB变分不等式与独立校准 | 可选PDE后端 |

上述条目相互可组合。例如“输出反馈＋稳定初始化＋off-policy Q”可能是一条算法路径，不能按标签数量宣称有几十个独立可运行算法。

## 最近月份的两项补查

补读了 [2026年8月随机微分博弈顺序PI](https://arxiv.org/abs/2608.17940) 的关键正文：模型已知、控制相关扩散、线性反馈Nash；每个参与者更新的中间策略组合保持均方稳定，收敛则是附加条件下的局部结论。已登记为计划扩展，需保存参与者更新顺序和移位/真实系统两种初始化证书。[阅读记录](literature/late-stochastic-game.md)

v0.4 已经 PolyU 认证访问取得 Automatica 2026 [非线性Bias-PI](https://doi.org/10.1016/j.automatica.2026.112821)正式版13页全文，并实现摆/双关节机械臂数值变体，见[全文卡](fulltext/bias_pi_automatica2026.md)。此前24篇计数属于v0.2历史批次；当前registry的逐篇声明范围内全文阅读计数为27，不能混同于27篇全部复现。早期访问失败记录仍作[历史](literature/late-bias-pi.md)保存。

## 2. 与你当前工作的优先顺序

**首先固化数据和理论口径。** 你的FxT-CL-ACI最直接依赖特征导数、真正的Bellman残差、历史栈秩、模型知识与求解器时间线。v0.2继续保留上游审查，新增数据一致性、积分来源和数值敏感性检查。下一次做FxT完整迁移时，应保留原程序、重构版、修正版和重新调参版的身份；本次尚未完成原论文全场景复现。

**随后增加可独立对照的基本算法。** 建议依次做DT LQR/Q/PI/VI、稳定初始化、DT输出反馈，再做CT EIRL/输出滤波。每项先通过解析或独立Riccati对照，再接入复杂非线性/机器人对象。2026预印本中的actor-only和随机不定成本算法先作为实验分支。

**随机、安全与博弈按明确问题接入。** 当确有乘性噪声时实现Itô生成元和随机LQ检查；当需要社会最优或团队博弈时增加相应总体状态和信息结构。风险指标改善不能代替安全证书，mean-square也不能被Hurwitz检查代替。

**Koopman、PINN和深度分布方法保留可选。** 它们有价值，但会引入辨识误差、自动微分/优化或PDE求解依赖，不必成为所有MATLAB论文的强制基础。MPC/rollout留终端价值与规划接口；本轮未建立近期MPC-ADP方法的完整复现证据。

## 3. 读到全文后，必须保留的条件

- 没有预先给定稳定策略，不代表允许在任意不稳定对象上安全采样。辅助系统稳定、有限数据候选稳定器、原系统均方稳定是不同状态。
- EIRL的非线性应用可以依赖漂移校正/耦合知识，相关结论可能针对线性化目标；不能简写成未知非线性系统全局最优。
- 稀疏求积、噪声偏置、总体Gram条件和reset采样是学习方程的一部分。理想期望或充分长数据的存在性结论不等于可计算有限样本保证。
- Koopman表示不普遍等于一个精确线性 `Az+Bu` 模型。人工粘性不是物理扩散；有限点误差包络不是全域界。
- PINN损失小不排除错误解分支，也不能推出梯度和策略误差小。概率校准必须保留抽样分布、数据用途、置信度及允许违例。

这些是本轮从论文条件提取的实现要求，具体文献的适用范围和未核证明以逐篇记录为准。个别来源还有复现前需核实的公式/证明连接，已保留在阅读记录中，不将其原式直接升级为仓库认证标准。

## 4. 本次融入到了哪里

- [METHOD_CONTRACTS.zh-CN.md](METHOD_CONTRACTS.zh-CN.md)：系统、目标、学习对象、数据、数值和证书的统一约定。
- [algorithms.json](../registry/algorithms.json)：保留原规划并加入具体近期方法，基线、具体方法变体与仍计划的家族分别标记；具体运行证据另见 reproductions.json。
- [method-capabilities.json](../registry/method-capabilities.json)：可组合能力维度；属于设计元数据，尚无通用运行时解析器。
- [method-intake.md](../templates/method-intake.md)：以后每篇新方法的接入模板。
- 六个仓库skills：开发、复现、理论、安全、实验和Simulink流程均增加相应检查。

逐篇材料分为 [核心算法](literature/core-methods.md)、[安全/随机/博弈](literature/safe-stochastic-methods.md)、[积分/Koopman/PDE](literature/main-methods.md)。完整索引为 [papers.json](../registry/papers.json)、[papers.csv](../registry/papers.csv) 和 [references.bib](../registry/references.bib)。工作副本中的PDF路径仅记录取证位置，全文PDF不随发布包分发；可通过各自全文URL与hash重新取得核对。

实际测试范围、失败后修复和未运行项目见 [VALIDATION.md](../VALIDATION.md)。这里没有把文献发表、下载成功、登记完成或静态扫描当成算法复现通过。
