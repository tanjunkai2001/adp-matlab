# ICML 2025 作者 Boat 代码：独立局部审计

2026-09-07。只读核验 [piml-soc 固定提交 b3fcda0873046fca67112b5289ba7b1261b41ac3](https://github.com/tayalmanan28/piml-soc/tree/b3fcda0873046fca67112b5289ba7b1261b41ac3)。新增下载的调用方、数据集与评估文件及 SHA-256 见 `author-audit-fetches.json`。没有执行作者训练或修改任何 本平台源码。以下为代码事实及其适用范围，不据此否定论文全部结论，也不把当前仓库代码自动当成发布 checkpoint 的训练记录。

## 1. 已确认：公开 Boat 训练分支的 VI 障碍项与论文 Eq. (6) 不同

完整调用链如下：

1. [cmds/cmd_Boat.txt:13–17](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/cmds/cmd_Boat.txt#L13-L17) 指定 `minWith=target`、`deepReach_model=reg`。
2. [Boat2DAug.py:12、74–75](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/dynamics/Boat2DAug.py#L74-L75) 的 loss_type 是 brt_aug_hjivi，而 boundary_fn 返回 `max(g(x),l(x)-z)`；本例 l=φ。
3. [utils/dataio.py:111–112、143–144](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/dataio.py#L111-L144) 在所有采样点计算该 boundary_fn 并返回 boundary_values。只有 brat_hjivi 分支另外生成 avoid_values；Boat 的 aug 分支没有这样做。
4. [experiments/experiments.py:379–391](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/experiments/experiments.py#L379-L391) 原样把 boundary_values 传给 aug loss。[run_experiment.py:285–287](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/run_experiment.py#L285-L287) 确认选择的是这个损失函数。
5. [utils/losses.py:56–70](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/losses.py#L56-L70) 计算 `min(V_tau-H,V-boundary_value)`。

所以这条公开代码路径实际求解的第二项是 `V-max(g,φ-z)`，不是论文 Eq. (6) 的 `V-g`。这是已确认的调用关系，不能用“boundary_value 可能只是变量名”消解。两者在 `φ-z<=g` 区域相同，在另一分支不同。本平台当前使用论文的 `V-g`。该事实并不能单独证明发布权重由此代码生成，也不能单独解释本次所有闭环误差。

## 2. 已确认：状态裁剪覆盖演示和标准批量验证

[traj_test/Boat.py:36–40](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/traj_test/Boat.py#L36-L40) 对 Euler 得到的 next_state 作 clamp。Boat 的 state_test_range 为 `x∈[-3,2]、y∈[-2,2]、z∈[-0.1,14.86]`，因此预算状态也被裁剪。

这**不只存在于演示脚本**：[utils/error_evaluators.py:269–275](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/error_evaluators.py#L269-L275) 的常规 scenario_optimization 分支同样执行 Euler 后 clamp；performance_scenario_optimization 的 [511–516 行](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/error_evaluators.py#L511-L516) 也如此。带 tStart_generator 的特殊冻结分支不同，本轮没有将其混同。

这改变了出域后的数值动力学，尤其预算不再始终满足未经裁剪的 `z'=−l`。本平台使用未裁剪 plant/budget、保持输入的增广 RK4，并记录出域情况，故轨迹与成本不能要求逐点吻合作者这些脚本。

## 3. 已确认但限于演示脚本：终端成本读取未写入的状态

[traj_test/Boat.py:11、42–47](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/traj_test/Boat.py#L42-L47) 先将整个轨迹缓冲区初始化为零；终端分支先读取 k+1 状态算成本，再把 next_state 写入该位置。因此分支触发时读到的 x,y 是零，终端成本固定为到目标 (1.5,0) 的距离 1.5，而非实际终态距离。默认 dt=0.0025、T=2 的最后一步会进入该分支。改变 dt 后浮点比较 `traj_time<=dt` 本身也可能影响是否进入分支。

这一赋值顺序错误**没有出现在本轮核对的批量性能评估路径**：[utils/error_evaluators.py:516–518](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/error_evaluators.py#L516-L518) 先写 k+1 状态再加终端成本。因此只能说演示脚本的打印成本有此错误，不能据此声称论文所有性能图或批量统计都使用了错误终端值。

## 4. 已确认：公开安全校准使用碰撞事件，未包含 C−z

[run_experiment.py:307](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/run_experiment.py#L307) 在 minWith=target 时选 BRT；[scenario_optimization:281–282](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/error_evaluators.py#L281-L282) 对 BRT 调用 dynamics.cost_fn；[Boat2DAug.py:86–87](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/dynamics/Boat2DAug.py#L86-L87) 的 cost_fn 只有沿轨迹的最大 obstacle g。未累计 C，也未把 C−初始预算加入这个标签。

[experiments.py 的 run_robust_recovery:753–805](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/experiments/experiments.py#L753-L805) 使用这个 costs，重新按 `costs>0 且 predicted V<=delta` 计数。因此该路径实际统计碰撞，不是论文 Eq. (12) 的联合 epigraph rollout `max(C−z,max g)`。本平台当前联合标签与它不同；根任务报告的预算违例不会被该碰撞标签计入。

另外，该 robust 脚本一次在总体域采 N 个点，扫描 delta 后用子集内的 k，但 Beta 参数仍保留总体 N；它没有在每个固定 delta 的条件集重新取得 N 个 IID 样本。写出的 `Beta.ppf(beta,N-k,k+1)` 是相应成功概率下界的方向，数值补数才对应失败概率上界，不能直接与 本平台的 `betaincinv(1-beta,k+1,N-k)` 当成同名 epsilon 比较。该脚本采用总体样本上的事件计数；本平台则在独立选择 delta 后进行新的条件 IID 审计。

性能验证是另一条路径：[performance_scenario_optimization:488、516–531](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/utils/error_evaluators.py#L488-L531) 计算 running+terminal cost 与选定预算之差的绝对值；它不等于上述碰撞标签，也不等于联合 epigraph 标签。这里还把“没有找到可行预算、用 50 作哨兵”的样本误差置为零，应作为单独的筛选规则记录。

## 5. 已确认：演示阈值不是本次校准阈值的同口径参照

[traj_test/Boat.py:91](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/traj_test/Boat.py#L91) 直接传入 delta=−0.02，没有在该脚本展示它与哪份校准数据绑定。[final_value.py:19–48](https://github.com/tayalmanan28/piml-soc/blob/b3fcda0873046fca67112b5289ba7b1261b41ac3/final_value.py#L19-L48) 在 210 个离散预算点上二分，隐含利用预测值随预算单调；未找到可行预算则返回哨兵 50。本平台目前是自己的预算网格和新联合事件校准，因此 −0.02 与本次得到的阈值没有可直接比较的保证。

## 可用于最终说明的结论

作者权重在 MATLAB 与 PyTorch 的值/梯度一致性，只证明推理移植正确。原仓库公开训练损失、轨迹裁剪、安全事件和演示成本之间有上面具体差异；本平台当前评价依据论文的未裁剪动力学、正确终端成本和联合 epigraph 事件，因此出现不同闭环/校准数值并不与推理 parity 矛盾。仍不能从源码快照推定该 checkpoint 的完整训练过程，或反推出论文图表究竟用了哪个脚本版本。
