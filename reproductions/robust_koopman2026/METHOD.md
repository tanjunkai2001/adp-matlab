# Robust Koopman 2026：可执行方法变体

这是 Lin 等 [arXiv:2604.05633v2](https://arxiv.org/abs/2604.05633v2) 的原创 MATLAB 方法变体。预印本于 2026 年 8 月修订、投稿 Automatica，尚不能标作正式期刊发表。已阅读全文，原例对象、半因子成本、9 维双线性提升、5000 样本/配点和 ε=0.001 均保留；未逐点复现原图表，未完成原文全部 PDE 边界条件。

在仓库根目录运行：

```matlab
method = fullfile(pwd,'reproductions','robust_koopman2026');
addpath(method);
results = runtests(fullfile(method,'test_robust_koopman.m'));
assert(all([results.Passed]));
[result,runDir] = demo_robust_koopman;
```

只需 base MATLAB，已在 R2025b Update 6、Apple Silicon 上实际执行。入口恢复 path/rng；无参数运行会新建唯一 results 子目录，有名目录已存在则拒绝覆盖。`demo_robust_koopman(struct('saveOutputs',false))` 只返回内存结果。

## 实际算法

- `rk_identify(data)` 只接收 x、u、带噪测得 xdot。通过 `Jψ(x)*xdot` 和 `[z,u,z*u]` 的 19 列回归辨识 A/B0/B1，不接收解析 f/g 或 V*/u*。
- `rk_lift(x)` 给出三阶单项式与链式导数。阶数为 (1,0),(0,1),(2,0),(1,1),(0,2),(3,0),(2,1),(1,2),(0,3)，缩放为 1/(p1!p2!)；原文未明确全部三阶项缩放，本约定已显式固定。
- `rk_basis(z)` 从 z 的二次乘积中按索引首次出现去除在 x 中重复的单项式，得到 25 项，保留每项的 9 维梯度和 Laplacian。具体 pairs 随结果保存。
- `rk_solve(model,x,config)` 固定不确定性罚项，内层用解析 Jacobian、Gauss–Newton 与回溯求解非线性 HJB 残差。计算实际包含 `-epsilon*Delta_z V`。初始化来自普通二次价值候选和已辨识的输入矩阵，不传入解析控制规律。
- `rk_control(solution,x)` 完整解标量凸 Hamiltonian：`u=-sign(a)*max(abs(a)-b,0)/R`，其中 a=B'p，b=c2*norm(p)。它覆盖零输入分支，是隐式 Eq(34) 的标量解；不同于 Eq(47) 的滞后方向更新。
- `rk_rollout(solution,x0,config)` 在原 Eq(55) 上冻结评估 15 秒，RK4 步长 0.005、各子阶段重新计算连续反馈。明确的 `analytic_oracle` 仅用于独立评估。记录 nominal/behavior/filtered/applied 四个输入通道；此例四者相同，没有安全过滤器。

## 原文缺失参数的选择

100 条轨迹、每条 50 个样本、记录步长 0.02、积分内部步长 0.005；初值均匀取 [-0.8,0.8]^2。输入为幅值 0.2 的 0.7 Hz 正弦加随机正负 0.75 偏置；每轨迹独立相位。采集扰动为幅值 0.01 的 0.4 Hz 正弦/余弦，带同一轨迹相位，进入采集状态和观测导数。控制评估回到原确定性对象。

5000 配点来自 [-1,1]^2，排除 norm(z)<0.05。原文六初值中部分位于该域外，因此六条评估也包含外推。本实现没有外推安全保证。

c1=c2=c 取训练样本上 `max(norm(residual)/(norm(z)+abs(u)))`，是 Eq(56) 在指定一维切片上的最小可行系数，不是一般二维 LP 的最优解，也不是全域界。另留出 2000 个独立 x/u 点检查这一界的泛化；检查在学习结束后使用原模型计算，只作评估。

25 项在二维 lift manifold 上配点，未求整个穿孔 9 维域的边值问题。`converged` 只表示外迭代策略变化达到阈值，PDE RMS 另行报告，不能视为全域 HJB 解或最优性/鲁棒性证明。

[全文与页码/公式映射](../../docs/fulltext/robust_koopman2026.md) · [实际结果、负例和测试](RESULTS.md)
