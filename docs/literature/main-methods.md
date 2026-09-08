# 数值积分、Koopman与PDE后端：全文阅读记录

阅读日期：2026-09-07。全文阅读指取得正文并核对所列章节；不表示每个附录证明已经独立验算。文献的实验数字没有移用为本仓库结果。

## Impact of Computation in Integral Reinforcement Learning for Continuous-Time Control

来源：[作者/出版页面](https://arxiv.org/abs/2402.17375)；[所读全文](https://arxiv.org/pdf/2402.17375v1)。状态：published_conference。

阅读位置：全文正文 PDF pp.1–10；重点 §2–3、Theorems 2–3、Corollary 1；附录证明未逐行复核。

方法：将积分近似误差作为策略评估误差输入，分析其经回归条件数及PI迭代传播；包含梯形与Bayesian quadrature。

条件：确定性CT仿射系统；控制通道已知；初始策略可容许；回归满列秩、光滑性及局部Newton条件。隔离积分误差时忽略函数逼近误差。

限制：收敛阶有光滑性/核空间条件；ODE增广积分的机器精度不能代表稀疏传感数据IRL精度。

规范落点（P0）：数据必须记录积分来源、采样时刻、求积规则、误差界及其是否经证明；积分误差与回归放大分开。

代码：repository_and_readme_verified_python_not_run。本仓库尚未实现此方法。

## A Physics-Informed Machine Learning Framework for Safe and Optimal Control of Autonomous Systems

来源：[作者/出版页面](https://proceedings.mlr.press/v267/tayal25a.html)；[所读全文](https://raw.githubusercontent.com/mlresearch/v267/main/assets/tayal25a/tayal25a.pdf)。状态：published_conference。

阅读位置：PDF正文 pp.1–8；重点 §2 epigraph/HJB-VI、§3.1–3.4、Theorems 3.1–3.2；附录未完整证明审计。

方法：用额外成本坐标z把有限时域受约束最优控制转为HJB变分不等式，再训练PINN并用独立轨迹校准。

条件：已知动态、终端成本、状态约束；概率量针对指定初值分布和IID校准样本；需记录置信度与违例水平。

限制：校准给概率层面的结论；训练残差小、样本100%安全不等于所有状态确定性安全。实现时需核对阈值选择/校准数据复用。

规范落点（P2）：增加终端条件、epigraph坐标、HJB-VI算子和校准协议；应放可选PDE后端。

代码：author_project_page_verified_code_link_present_not_run。本仓库尚未实现此方法。

## Data-driven optimal control of unknown nonlinear dynamical systems using the Koopman operator

来源：[作者/出版页面](https://proceedings.mlr.press/v283/zeng25a.html)；[所读全文](https://raw.githubusercontent.com/mlresearch/v283/main/assets/zeng25a/zeng25a.pdf)。状态：published_conference。

阅读位置：PDF正文 pp.1–9；重点 §2、§4.1–4.4、§5/Theorem 6、Remark 5；正文指向的预印本证明未逐行复核。

方法：用resolvent/Yosida近似辨识Koopman生成元，恢复控制仿射模型，再用随机特征价值函数做模型PI。

条件：可容许初始策略、紧不变域、数据充分稠密与函数光滑；渐近辨识精度条件。

限制：不是普遍精确的Az+Bu表示；固定迭代的渐近一致性不能改写成有限数据全局近优保证。

规范落点（P2）：分开模型字典、价值特征、lifted动态结构和模型误差；在真实系统上另做冻结策略评估。

代码：no_author_code_url_found_in_read_body。本仓库尚未实现此方法。

## Automatic feature identification in least-squares policy iteration using the Koopman operator framework

来源：[作者/出版页面](https://arxiv.org/abs/2603.26464)；[所读全文](https://arxiv.org/pdf/2603.26464v1)。状态：preprint。

阅读位置：PDF全6页；重点 §II LSTDQ、§III Eq.12/Algorithms 1–2、§V未解决问题。

方法：先由离线转移数据学习Koopman autoencoder特征，冻结后做离散时间折扣LSPI。

条件：DT折扣MDP；示例为有限动作集合；特征维数仍需选定，回归可解性需独立检查。

限制：正文明确将收敛/遗憾理论留为未来工作；不能与CT HJB或普通Bellman最小二乘互换。

规范落点（P2）：Q/value/actor类型分开；LSTDQ与Bellman residual minimization分开；保存特征训练/冻结版本。

代码：no_author_repository_url_found_in_fulltext。本仓库尚未实现此方法。

## Optimality Robustness in Koopman-Based Control

来源：[作者/出版页面](https://arxiv.org/abs/2604.05633)；[所读全文](https://arxiv.org/pdf/2604.05633v2)。状态：preprint。

阅读位置：PDF正文 pp.1–13；Assumptions 1–6、§4、Algorithm 1/Theorem 4、Remark 5–7；附录未逐行复核。

方法：用双线性lifted模型及范数有界误差建立鲁棒最优问题，以带人工粘性项的PDE迭代求解。

条件：紧不变域、已知误差/噪声界、满秩辨识、可容许策略、充分小误差；算法分析排除原点附近并另需局部控制。

限制：粘性项是分析/数值正则化，不是物理Itô噪声；数据点拟合误差界不是全域证明。文中也说明两种性能界无附加条件不可严格排序。

规范落点（P2）：记录双线性项、界的来源与有效域、原点分母处理及局部控制切换；不可直接套用普通线性LQR。

代码：no_author_repository_url_found_in_read_body。本仓库尚未实现此方法。

## A Physics-Informed Learning Framework to Solve the Infinite-Horizon Optimal Control Problem

来源：[作者/出版页面](https://onlinelibrary.wiley.com/doi/10.1002/rnc.70028)；[所读全文](https://arxiv.org/pdf/2505.21842)。状态：published_journal。

阅读位置：作者预印本PDF pp.1–12；§2–5、Theorems 1–3/Algorithm 1；出版信息另核对Wiley。

方法：用带终端条件的有限时域HJB与逐次延长时域逼近无限时域价值，避免直接训练稳态HJB时的解分支问题。

条件：已知f/g、正定代价、紧域和价值函数正则性；理论针对PDE解的逼近，NN优化收敛另议。

限制：正文明确PINN训练无一般严格收敛保证；值函数一致误差不能在任意实现中自动当作梯度/策略误差界。

规范落点（P2）：时间导数、终端边界、时域扩展记录、值/梯度误差分开；作为PDE后端，不能标成已完成actor–critic。

代码：no_author_repository_url_found_in_read_body。本仓库尚未实现此方法。
