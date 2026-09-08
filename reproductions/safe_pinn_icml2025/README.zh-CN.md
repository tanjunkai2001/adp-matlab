# Safe epigraph PINN / ICML 2025

需要 Deep Learning Toolbox。模型、成本、控制域和时间符号见[全文映射](../../docs/fulltext/safe_pinn_icml2025.md)。

## 1. 独立运行缩小版 MATLAB 训练

在仓库根目录运行 5,000 次更新：

```matlab
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
[result,runDir] = demo_reproductions('safe_pinn_icml2025',outputRoot,5000);
S = load(fullfile(runDir,'result.mat'),'result');
S.result.metrics
```

`runDir` 是本次新建的运行目录，包含训练网络、固定评价输入、轨迹和指标。此流程不需要历史实验文件或作者检查点。

## 2. 评价外置作者检查点

这条路径读取权重并做推理，不重训作者网络。需要两份单独准备的文件：

- 已转换的 MATLAB 权重文件，包含 `W1`–`W5`、`b1`–`b5`、`checkpoint_epoch` 和独立值/梯度参照数组；准确字段见 [`load_author_boat.m`](load_author_boat.m)。历史权重身份及归一化见 [`SOURCE.json`](SOURCE.json)。作者权重、原始 PyTorch `.pth` 和转换工具均不随仓库分发，`.pth` 不能直接载入。
- `demo_safe_pinn` 保存的 `result.mat`，其中必须有 `result.heldoutInputs` 和 `result.testInitial`。评价复用这批留出输入与候选初值，再由待评价网络重新选择预算。已有兼容结果时无需重新训练；下面使用步骤 1 的运行结果。不能把权重文件或评价输出 `evaluation.mat` 当作 `comparisonFile`。

将 `weightFile` 替换为自己的文件；每次评价写入新目录：

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
weightFile = '/absolute/path/to/converted-author-weights.mat'; % 替换
comparisonFile = fullfile(runDir,'result.mat'); % 或已有兼容训练结果的路径
[authorNet,parity] = load_author_boat(weightFile);
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
if ~isfolder(outputRoot), mkdir(outputRoot); end
authorRunDir = tempname(outputRoot);
authorResult = evaluate_boat_model(authorNet,authorRunDir,comparisonFile);
authorResult.metrics
```

载入器将 MATLAB 的值和物理输入梯度与权重文件中的独立参照比较。评价保存 `evaluation.mat`、`metrics.json` 和轨迹图；它直接写入指定目录，因此每次使用新的 `tempname`。两条路径均需要 Deep Learning Toolbox。

## 如何理解已有计数

[2026-09-07 运行记录](../../evidence/v0.3/safe-pinn/RESULTS.md)中，使用当前成本积分器的固定输入评价为：

| 网络 | 候选初值 | 预测可行并实际执行 | 执行中的碰撞数 | 执行中的预算违例数 |
|---|---:|---:|---:|---:|
| MATLAB 自训 5,000 次 | 64 | 64 | 19 | 47 |
| 作者 epoch 250,000 检查点 | 相同 64 个 | 63 | 1 | 9 |

每个网络在两秒时域、`[0,14.86]` 的 100 个预算点中搜索，找到预测 epigraph 值非正的预算后才执行。作者网络剩余的 1 个候选没有执行，不能计为成功。碰撞和预算违例可能发生在同一条轨迹，不能相加。上表用步长 `0.005`，事件分别为严格的 `maxObstacleG > 0` 和 `cost > initialBudget`。

## 可选：单独进行条件校准

这套样本与上面的固定 64 个候选不同：

| 阶段 | 样本及作用 |
|---|---|
| 阈值选择 | 2,000 个均匀 `(x,y,z)` 候选，评价预测集合并选择 `delta` |
| 新条件样本审计 | 目标为 300 个满足 `V <= delta` 的新样本，统计碰撞/预算/非有限轨迹的联合事件 |

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
netForAudit = result.network; % 作者检查点改用 authorNet
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
if ~isfolder(outputRoot), mkdir(outputRoot); end
calibrationDir = tempname(outputRoot);
mkdir(calibrationDir);
audit = calibrate_boat(netForAudit,calibrationDir);
```

采样范围为 `x∈[-3,2]`、`y∈[-2,2]`、`z∈[0,14.86]`，种子为 25052。程序每批提出 2,000 个点，再截取前 300 个接受样本，**不能用 `300/proposalCount` 估计集合覆盖率**。样本不足时不返回条件概率上界。这里采用 `>= 0` 的非严格事件并计入非有限轨迹，不能与固定初值表的事件口径混用。

已记录的自训/作者网络条件审计分别为 15/300、2/300 联合违例，95% 单侧上界为 7.5949%、2.0836%。这些数字对应选定集合中的数值轨迹标签；采样与步长加密结果见[方程说明](../../docs/fulltext/safe_pinn_icml2025.md)。

9个测试覆盖HJB导数、边界、单位圆极小化、RK4独立积分参照以及校准样本有效性。已有训练与检查点评估都保存了违例，查看[运行结果](../../evidence/v0.3/safe-pinn/RESULTS.md)后再选择后续训练配置。
