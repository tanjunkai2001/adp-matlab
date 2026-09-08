# Automatica 2025：乘性噪声下的平均场 LQG 社会优化

对应 Xu, Wang, Shen, *Mean field LQG social optimization: A reinforcement learning approach*, **Automatica 172 (2025), 111924**，DOI [10.1016/j.automatica.2024.111924](https://doi.org/10.1016/j.automatica.2024.111924)。完整方法与证据边界见 [全文阅读卡](../../docs/fulltext/meanfield_lqg2025.md)。

这是根据论文公式独立编写的 MATLAB 实现，覆盖论文二维单输入例子的 Algorithm 1：从重复随机轨迹学习反馈增益 K、平均场增益 Ks，再通过重复轨迹计算平均场。学习器没有 A/B/C/D 参数。

在仓库根目录运行：

~~~matlab
report = demo_reproductions('meanfield_lqg2025');
~~~

默认实验使用 **100 条训练路径**、种子 `20260907`、8 次独立训练，以及 48 组各含 40 个体的群体评估；成本积分到 20 秒。完成后在 `runs/meanfield_lqg2025/` 下的新目录保存原始训练轨迹、输入、Brownian 增量、配置、观测矩、迭代、图和成本。

项目页约 **0.53% / 0.85%** 的两组增益误差来自历史 **4000 路径**实验，默认100路径命令不对应这组数字。现有精度子流程在同一探索输入下池化 **40 批、每批100路径**，依次在100/400/1000/4000路径拟合：

~~~matlab
addpath(fullfile(pwd,'reproductions','meanfield_lqg2025'));
cfg = mf_config;
outputDirectory = fullfile(pwd,'runs', ...
    ['meanfield-precision-' char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
precision = mf_precision_check(outputDirectory,cfg,40);
~~~

完成后，`precision.mat` 保存配置、批次种子、共享频率、池化观测矩和拟合结果；`mc-precision.csv` 保存增益及误差，`cost-comparison.csv` 保存有限时域成本对照。主实验批次种子为 `cfg.seed + (0:39)`。仅将 `cfg.train.paths` 改成4000会改变随机数抽样和分批方式，不能视为同一随机实验。

完整验证及更高 Monte Carlo 精度对照：

~~~matlab
addpath(fullfile(pwd,'reproductions','meanfield_lqg2025'));
outcome = run_verified_meanfield;
~~~

完整入口先运行局部测试、默认100路径实验和精度子流程，再执行另外3次4000路径拟合。`gain-uncertainty-4000.csv` 给出总计4次独立拟合的增益标准误；成本标准误则以主拟合策略和一次采样均值曲线为条件，来自48个独立群体。

若默认100路径的首个拟合报错，完整入口会在精度阶段之前停止；精度子流程自身也会先拟合较小样本，可能在到达4000路径之前停止。上述命令沿用现有流程，不跳过拒绝的拟合，也不替换种子。

[历史记录](../../docs/fulltext/meanfield_lqg2025.md)中，100路径主实验增益误差为18.23% / 30.01%，8次训练有1次被拒绝；4000路径主实验误差约0.53% / 0.85%。这些是既有结果，不是本次重新运行所得。原始MAT/CSV属于单独保留的[历史归档](../../docs/ARTIFACTS.md)，公开源码保留摘要。上述命令明确了现有流程；要核对与某次历史实验的精确对应，还需其保存的配置和数据身份。未删除失败训练来形成无条件均值，也不据此宣称有限样本收敛定理。

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
