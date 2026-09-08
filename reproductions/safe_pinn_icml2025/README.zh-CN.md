# Safe epigraph PINN / ICML 2025

需要 Deep Learning Toolbox。模型、成本、控制域和时间符号见[全文映射](../../docs/fulltext/safe_pinn_icml2025.md)。

在仓库根目录运行缩小版训练（5,000 次更新）：

```matlab
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
[result,runDir] = demo_reproductions('safe_pinn_icml2025',outputRoot,5000);
S = load(fullfile(runDir,'result.mat'),'result');
S.result.metrics
```

`runDir` 是本次新建的运行目录，包含训练网络、固定评价输入、轨迹和指标。此流程不需要历史实验文件或作者检查点。

## 可选：评价单独取得的作者权重

作者权重及其转换工具不随源码分发。下面的步骤仅适用于已经单独取得兼容 MATLAB 权重文件的读者，仍需要 Deep Learning Toolbox。文件格式和独立值/梯度校验字段见 [`load_author_boat.m`](load_author_boat.m)，历史检查点版本见 [`SOURCE.json`](SOURCE.json)；原始 PyTorch `.pth` 文件不能直接传入该函数。

将下面的占位路径替换为自己的已转换权重文件。评价使用上一步 `runDir` 中的相同初值和留出输入：

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
weights = 'path/to/your/converted-author-weights.mat'; % 替换为自己的文件
[authorNet,parity] = load_author_boat(weights);
comparison = fullfile(runDir,'result.mat');
authorRunDir = tempname(outputRoot);
authorResult = evaluate_boat_model(authorNet,authorRunDir,comparison);
audit = calibrate_boat(authorNet,authorRunDir);
```

9个测试覆盖HJB导数、边界、单位圆极小化、RK4独立积分参照以及校准样本有效性。已有训练与检查点评估都保存了违例，查看[运行结果](../../evidence/v0.3/safe-pinn/RESULTS.md)后再选择后续训练配置。
