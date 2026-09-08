# Bias-PI 摆系统：实际结果与边界

2026-09-07，MATLAB R2025b。依据 Automatica 185 (2026) 112821 的完整 13 页正文独立实现；原文源码未取得。核心采用式 (43) 的外层 **γ(V_new−V_previous)** 偏置机制；式 (48) 只用于 Remark 6 初始化和降 γ 后内层。不是仅优化折扣成本的 PI。

原始单轨迹在本次明确种子与积分设置下没有复现成功；改成同样 5 秒总时长的局部多初值数据后，得到可运行变体。默认选择 `local_multistart` 与 `discounted_bootstrap`，对应 [完整保存运行](pendulum-final-bootstrap/metrics.json)。它不是原文 54 轮或完整图表复刻，也没有全域 HJB 或稳定性证书。

## 保留的配置与新增选择

系统为 x1dot=x2、x2dot=sin(x1)+u，状态角度不做 wrap；成本是 x1²+x2²+u²，没有 1/2。保留表中 7 个 critic、5 个 actor 基函数，Ts=.01、Td=5、γ0=6、δbar=8、δH=30、critic 权重平方变化阈值 1e−6。采集端使用真值，学习器只接收实际 x/u/Q(x) 数据、基函数及 R。

- 频率种子 20260907；50 个频率均匀取自 [−50,50]，探索幅值 .01。默认探索单独作为输入，遵循正文/表格；Algorithm 2 的 u0+e 可以通过 `behaviorMode='initial_plus_exploration'` 另行选择。
- 单轨迹从 [0;.01] 出发。半径阈值 3 在窗口末检查，超界后下一窗重置；这些是显式实现选择，原文未给半径。任何回归都不跨重置。
- 多初值变体以种子 20260908 从 [−.5,.5]² 取 20 个初值，各采集 .25 秒；总计仍为 500 个 .01 秒窗口。保存全部初值、频率与观测节点。该变体改变数据覆盖，不能称原文给定初值实验。
- 每窗 4 个 RK4 子步并全部保存，用复合 Simpson 计算局部指数加权积分。另做 8 子步对照。
- 阈值在 [−3,3]² 的 41×41 格点检查，不声称遍历所有 x。γ 触发时按式 (30) 的 β 递推，并在内层接受后显式重启 β；该重启细节原文未公布。
- 表格给定的 u0 与 V0 不构成精确 greedy 配对。默认按 Remark 6 先执行一次式 (48) 得到估计的配对初值；有限基函数与数据仍不证明条件 (13) 已全局满足。初值检查中的最大 V/Q 比值为正也不是正定性检查。

## 实际完成的对照

| 数据与初始化 | 实际结果 | 证据 |
|---|---|---|
| 原单轨迹、表格初始化 | 外层 4 后内层 200 次仍未达到低阈值；γ=4.161789，剩余格点 margin=108.32 | [失败与配置](pendulum-table-fullcheck/failure.json)，同目录 inputs.mat |
| 原单轨迹、Remark 6 bootstrap | 外层 2 后内层预算失败；γ=5.729987，margin=449.07 | [失败与配置](pendulum-bootstrap-fullcheck/failure.json)，同目录 inputs.mat |
| 原单轨迹、γ0=0 | 高阈值触发，但 γ=0 无法再降低，明确拒绝 | [失败](pendulum-gamma-zero/failure.json) |
| 多初值、表格初始化 | 35 外层、0 内层，γ始终6，35/35 个闭环终值范数<.01 | [结果](pendulum-final-table/metrics.json) |
| 多初值、bootstrap（默认） | 38 外层、0 内层，γ始终6，35/35 个闭环终值范数<.01 | [结果](pendulum-final-bootstrap/metrics.json) |
| 多初值、γ0=0 | 同样触发 γ 调度保护并拒绝 | [失败](pendulum-final-gamma-zero/failure.json) |
| 多初值、表格初始化、8 子步 | 35 外层，结果随求积加密变化很小 | [结果](pendulum-final-refined/metrics.json) |

γ=0 结果是完整 Algorithm 2 保护分支的拒绝，不是已完成的独立普通 PI 对照。成功的非线性变体没有触发内层降 γ；这一路径另由独立解析测试覆盖。默认采用 γ=6 仍包含上一 critic 的偏置项，所以不是常规 γ=6 折扣 PI。

默认运行回归秩 12/12，列缩放条件数 87.0206，相对数据回归残差 7.42307e−4。学习器得到的 actor 为：

`u = −2.36273846*x1 −2.39059453*x2 +.04319232*x1² −.02620243*x2² +.10924070*x1*x2`。

原点处真实闭环线性化极点为 −.938398、−1.452196。它们是模拟真值的局部诊断，不传入学习器。原文只打印了 4 个 actor 权重，却定义 5 个基函数；不猜测遗漏项，因此不提供伪造的完整 actor 权重误差。

35 个新初值以种子 1729 从 [−3,3]² 取样，连续反馈仿真 20 秒。默认 actor 对线性化 LQR（K=[1+sqrt(2),1+sqrt(2)]）的配对成本差为 **−.149875889 ± .065320926 标准误**。该标准误仅描述一组固定训练权重在不同初值上的成本差，不包含训练种子不确定性，也不是无限时域最优性证明。

8 子步相对 4 子步的表格初始化结果，critic 权重 L2 差 3.44694e−6、actor 差 1.31728e−6，35 个成本的最大绝对差 1.77152e−5。这说明该变体对本次积分加密不敏感，不是认证积分误差界。

## 小回归残差不等于全域 HJB 近似

以另一个种子 4242 生成 1000 个留出状态，利用真值仅作事后计算。默认运行在 [−.5,.5]² 的 optimized HJB RMS 为 .0542728；在 [−3,3]² 上升到 **21.6952**。actor 相对 critic 梯度 greedy 映射的 RMS 差相应为 .0244869 和 .829419。原始状态、完整度量保存在 result.mat / metrics.json。

因此，本次支持“局部采集的 Bias-PI 数值变体可执行，并在所测初值上产生收敛闭环”，不能支持“整个评估域的 HJB 近似已准确”。多初值对照支持数据覆盖是单轨迹失败的原因之一；它没有排除有限基函数逼近误差等其他原因。

## 重跑与图形

在方法目录加入 MATLAB 路径后：

~~~matlab
[result,runDir] = demo_bias_pi_pendulum('new-pendulum-default-run');
% 显式重现单轨迹、表格初值失败，失败后仍保存 inputs.mat/failure.json：
demo_bias_pi_pendulum('new-single-trajectory-run', ...
    struct('collectionMode','single_trajectory','initialization','paper_table'));
~~~

已有目录会被拒绝，不覆盖先前运行。闭环数据、初值、配置、完整学习历史、频率均保存在每次运行的 MAT 文件。默认图形已经渲染并目视核查：[PNG](pendulum-final-bootstrap/pendulum-results.png)、[可编辑 FIG](pendulum-final-bootstrap/pendulum-results.fig)。[结构化摘要及精度对照](pendulum-validation/summary.json)、[实际日志](pendulum-validation/pendulum-final.log)、[最终源码身份](pendulum-validation/source-files.json) 同时保留。

完整参数、索引更正和理论边界见方法全文卡与根验证报告。独立解析数学测试与非线性复现结果分别报告，测试通过不消除这里记录的失败和近似误差。
