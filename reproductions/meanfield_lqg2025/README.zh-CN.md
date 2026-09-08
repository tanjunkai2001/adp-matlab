# Automatica 2025：乘性噪声下的平均场 LQG 社会优化

对应 Xu, Wang, Shen, *Mean field LQG social optimization: A reinforcement learning approach*, **Automatica 172 (2025), 111924**，DOI [10.1016/j.automatica.2024.111924](https://doi.org/10.1016/j.automatica.2024.111924)。完整方法与证据边界见 [全文阅读卡](../../docs/fulltext/meanfield_lqg2025.md)。

这是根据论文公式独立编写的 MATLAB 实现，覆盖论文二维单输入例子的 Algorithm 1：从重复随机轨迹学习反馈增益 K、平均场增益 Ks，再通过重复轨迹计算平均场。学习器没有 A/B/C/D 参数。

在仓库根目录运行：

~~~matlab
addpath('reproductions/meanfield_lqg2025');
report = demo_meanfield_lqg2025;
~~~

这会运行论文规模的 100 路径学习、8 次独立训练和 40 个体的群体评估，保存原始训练轨迹、输入、Brownian 增量、配置、观测矩、每次迭代、图和成本。

完整验证及更高 Monte Carlo 精度对照：

~~~matlab
outcome = run_verified_meanfield;
~~~

完整入口先运行局部测试，再保留 100 路径结果、同一探索输入下的 100/400/1000/4000 路径对照，以及 4 次独立 4000 路径拟合的增益标准误。增加路径数是显式数值精度实验，不是改种子挑选结果。

已运行证据在 [verified-20260907](../../docs/ARTIFACTS.md)。实际结果表明 100 路径的新随机数据有明显拟合波动，8 次中 1 次被拒绝；没有删去失败后把剩余结果当作无条件均值。4000 路径主实验的两组增益相对完整模型参考误差约 0.53% 和 0.85%。这不等价于有限样本收敛定理。

| 文件 | 数学职责 |
|---|---|
| mf_collect | 论文 (1)/(51) 的 Euler–Maruyama 观测轨迹，包含 D*u 乘性噪声 |
| mf_build_data / mf_window_moments | (29)/(38) 的两套观测矩；先合并路径均值，再形成均值外积 |
| mf_learn | (32)、(39)–(42) 两阶段离策略 PI；秩、条件数与不可接受估计直接报错 |
| mf_reference | (12)–(18) 的模型广义 Riccati 参考，另可算固定上游估计的第二阶段参考 |
| mf_mean_trajectory | (43)/(44) 平均场近似 I；重置初态为已知均值后采样 |
| mf_evaluate | 固定 40 个体的社会成本；按独立群体给标准误，共享随机数做配对比较 |
| mf_precision_check | 同一 probe 下的重复路径精度检查，不注入解析矩 |

需要 MATLAB 基础功能；不依赖 Control System Toolbox、Reinforcement Learning Toolbox 或深度学习工具箱。当前实际验证版本为 R2025b。仅实现 n=2、m=1、独立标量 Brownian 噪声的论文数值例子；多维输入、共同噪声、非齐次个体和辨识平均场支路 II 尚未实现。

成本是 0–20 秒的有限时域积分，参考策略是完整模型得到的平均场分散控制器，不是有限 N 集中式最优解。成本标准误以固定学得增益和一次估计的平均场轨迹为条件，来自 48 个独立群体；增益标准误来自独立训练实验，两者不能互换。
