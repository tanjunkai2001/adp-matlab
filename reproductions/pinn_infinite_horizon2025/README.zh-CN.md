# 有限时域 HJB 神经 PINN 与时域延长

已实际运行一维 LQR 诊断和论文摆系统的 `T=1→2→3→4` 神经训练。实现依据 Fotiadis、Vamvoudakis，*A Physics-Informed Learning Framework to Solve the Infinite-Horizon Optimal Control Problem*，IJRNC 2025，[DOI 10.1002/rnc.70028](https://doi.org/10.1002/rnc.70028)。完整逐页阅读、方程位置和一个算例中的代价不一致见[全文记录](../../docs/fulltext/pinn_infinite_horizon2025.md)。

## 运行

在仓库根目录启动 MATLAB R2025b，需 Deep Learning Toolbox：

```matlab
addpath(fullfile(pwd,'reproductions','pinn_infinite_horizon2025'));
[result,runDir] = run_pinn_reproduction('reduced');
report = analyze_pinn_run(runDir);
```

也可直接从仓库根目录调用统一入口：

```matlab
[result,runDir] = demo_reproductions('pinn_infinite_horizon2025','reduced');
```

`reduced` 对应项目页 T=4 图的缩小规模配置：CPU、固定随机种子，先训练一维 LQR 2000 次，再训练摆的四阶段、每阶段 3000 次。每次运行新建结果目录，保留网络、数据、随机状态、全部 loss、测试残差、闭环轨迹、源文件哈希和图。`smoke` 只训练 LQR 10 次和摆 T=1、2 各10次，不生成 T=4 结果；两个模式还分别执行两次独立12步前缀检查。`quartic` 为可选的**修正代价**算例配置，历史记录没有执行该训练。

`train_hjb_pinn` 的训练数据只有状态、时间和已知模型。神经网络通过 HJB 微分残差训练，没有解析值函数监督标签。延长时域时，上一网络在局部时间 0 的输出成为下一阶段的冻结终端目标；每阶段仍只解长度 1 的局部时间 PDE。控制器在真实物理时间中执行冻结的 `u(x,0)=-g(x)'∇V(x,0)/2`。

## 已取得的结果

运行记录：[reduced_20260907_110031_520](../../evidence/v0.3/pinn/reduced_20260907_110031_520/summary.json)，MATLAB R2025b Update 6，2026-09-07，整个训练与评价流程约 5 分 43 秒。

| 总时域 | 摆：独立有限 HJB MSE | 终端 MSE | t=0 稳态 HJB MSE |
|---:|---:|---:|---:|
| 1 | 7.9850e-4 | 1.1813e-4 | 2.4445e-2 |
| 2 | 8.1669e-5 | 1.3133e-5 | 1.1594e-4 |
| 3 | 3.0757e-5 | 2.8630e-6 | 2.6146e-5 |
| 4 | 1.6985e-5 | 6.6236e-7 | 2.7385e-5 |

每阶段使用 2048 个独立随机测试点；另由 `analyze_pinn_run` 在所有时域共用的 41×41 网格重算稳态残差，分别为 `0.0262203、1.15795e-4、2.76153e-5、2.74509e-5`，保存为 `pendulum_horizon_comparison.csv`。第 3 到第 4 阶段已基本持平；随机点估计略升、共同网格略降，两种结果均保留。

四个摆初值为 `[-.8;.2]`、`[-.4;.8]`、`[.8;-.2]`、`[.4;-.8]`。T=4 的 8 秒累计成本为 `1.292178、0.414937、1.292178、0.414937`，末状态范数分别约 `2.28e-9、2.42e-10、2.28e-9、2.42e-10`，四条轨迹都完成且没有离开训练域。这个量级已到积分器绝对容差附近，应读作四次闭环仿真收敛到数值零附近。同模型、同初值、同时间的线性化 LQR 成本为 `1.292135、0.414922`（另两条对称重复），本轮 PINN 与其接近，没有表现出成本优势。LQR 增益为 `[0.218619,0.861305]`，独立 CARE 恒等式残差为 `2.22e-16`；完整比较保存为 `pendulum_closedloop_comparison.csv`。

一维 LQR 的解析有限时域解为 `V=tanh(T-t)*x^2`。解析自动微分 HJB 误差 `1.11e-16`，训练网络的有限 HJB MSE `3.72e-6`，对解析有限时域值函数的 RMSE `1.17e-3`；网络输入导数与中心差分最大差 `9.82e-11`。该诊断只训练 T=1，其稳态 HJB MSE 为 `0.03725`，符合尚未达到无穷时域解的事实。独立重复 12 次更新的种子检查，参数、loss 和训练点均完全一致；未执行完整训练的第二次重复。

## 规模与实现选择

摆使用 3×48 tanh、10000 个 flow 点、1600 个终端点、minibatch 256/128、初始学习率 0.003 和固定 3000 次更新。论文为 3×100、flow minibatch 500、初始学习率 0.005，并以全部 minibatch loss 达阈值停止。这里是保留主机制的较小网络运行，没有执行原文全部规模或第三阶算例。

对称模型采用 `V(x,t)=(N(x,t)+N(-x,t))/2-N(0,t)`，精确满足原点值和原点梯度。这是记录在配置中的结构变体，终端条件仍通过软损失训练。换成非对称动力学或成本时应先改回适合其问题的值函数结构。

论文四次算例所写 Q 与所称解析 V 代回 HJB 后得到 `-x2^4`；`quartic_paper` 保留该原始 Q，不输出已验证 oracle。仅 `quartic_corrected` 把 Q 的四次项系数改为 2 后使用解析参照。每次运行的确定性诊断都会核验这个差别。

## 文件

- `pinn_problem.m`：已知模型与成本，解析解仅供评价。
- `pinn_value.m`、`pinn_loss.m`：非线性神经值函数、输入自动微分、高阶参数梯度和损失。
- `train_hjb_pinn.m`：固定种子采样、冻结终端数据、Adam、自动微分图缓存。
- `evaluate_hjb_pinn.m`：独立测试、导数差分、连续反馈闭环和真实成本。
- `run_pinn_reproduction.m`：完整可运行入口与原始证据保存。
- `analyze_pinn_run.m`：共同网格、明确对数轴的图和独立线性化 LQR 比较。

训练时源码快照保存于主结果目录的 `source_snapshot/`，对应 `summary.json` 中的哈希。训练完成后只修正了默认训练图的对数坐标和未验证 quartic oracle 的输出标签；未改动该次 LQR/摆训练的动力学、网络、loss、采样或权重。评价支持这些具体配置的数值行为，不代替原文理想 PDE 解的收敛证明。

## v0.4.1 维护

新增 testPinn.m 的5项独立检查：解析HJB、原四次代价差异、物理导数、PDE损失和冻结终端目标/单步重放。共做两次单Adam更新，未重训历史实验。新运行保存到仓库 runs/pinn_infinite_horizon2025/；也可调用 `run_pinn_reproduction(mode,newOutputDirectory)`。模式只能是 reduced、smoke、quartic；拼写错误会在训练前拒绝。
