# 日常使用

推荐从轻量源码包开始，把解压后的仓库根目录设为MATLAB当前文件夹。它包含当前源码、测试、规范、全文卡和skills；历史MAT/FIG/日志在完整证据包中。两种包的算法源码一致，源码包的测试不依赖历史数据、论文PDF或作者checkpoint。

```matlab
check_environment();          % 查看已安装产品，不运行算法
demo_reproductions();         % 查看方法入口及是否启动神经训练
run_all_tests('list');        % 查看实际发现的测试数量
run_tests;                    % 基础库与仓库入口检查
results = run_all_tests;      % 全部局部测试；包括两个单步神经更新检查
```

完整测试需要MATLAB、Control System Toolbox和Deep Learning Toolbox。本次实际环境为R2025b Update 6/macOS；环境检查只确认安装情况，不代替许可可用性或跨版本测试。

先试一个不需要神经训练的例子：

```matlab
[r,folder] = demo_reproductions('baseline');
[r,folder] = demo_reproductions('bias_pi_automatica2026');
```

运行完整PINN训练必须显式选择该方法。仅核对安装/训练流程时可用短演示：

```matlab
[r,folder] = demo_reproductions('pinn_infinite_horizon2025','smoke');
```

`smoke`只运行短训练流程，不能替代论文实验。PINN、平均场和两个Koopman的新结果进入仓库`runs/`；其他方法也使用被忽略的`runs/`目录或用户指定的新目录。显式指定单次运行目录时应使用新目录，以免覆盖旧实验；`outputRoot`参数是容纳多个新运行的父目录，可以已存在。不要对整个仓库执行`addpath(genpath(...))`，尤其不要把历史源码快照加入路径。

## 新增自己的方法

1. 复制`templates/method-intake.md`和`templates/equation-map.csv`到新论文目录，先固定原文版本、模型知识、成本、数据来源和目标指标。
2. 在`reproductions/你的方法/`编写模型、配置、学习和评估函数；优先复用数学契约相同的现有函数，不做万能控制器类。
3. 添加一个可直接运行的入口、README和有独立参照的`test*.m`。先完成小问题，再接论文大算例。
4. 在`registry/papers.json`与`registry/algorithms.json`登记论文/算法，在`registry/reproductions.json`登记实现入口、目录、依赖、训练标记和证据。`adp_catalog`会把它交给演示和测试发现，不再修改三份方法名单。
5. 运行下列结构检查及MATLAB测试，再保存新版本与实验结果。

```text
python3 tools/check_repository.py
```

轻量源码包缺少历史证据是有意安排；检查它时使用`--source-only`。这个检查器只验证本地登记、路径和文档，不能评价论文证明或数值正确性。

只把新场景实际用到的部分提取到`src/+adp`。目前约束、CL/FxT、博弈、时钟、观测器和Simulink仍需独立实现；完整状态见[完整性检查](COMPLETENESS.zh-CN.md)。
