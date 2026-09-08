# Safe PINN 执行结果

2026-09-07，MATLAB R2025b Update 6、Deep Learning Toolbox，CPU实际运行。

| 路径 | 核心结果 | 证据 |
|---|---|---|
| 自训5000步 | 留出HJB MSE 0.52289682→0.03643165；硬终端误差0；训练约139.7秒 | `tp179e3df5_31a2_4d23_8277_6e2e2b8668eb/result.mat`、training.csv |
| 当前积分器重评自训网络 | 64/64预测可行，19碰撞、47预算违例，52出训练域 | `reduced-reevaluated/` |
| 作者epoch250000检查点 | 128点值/梯度移植最大差8.88e-16/1.78e-15 | `author-checkpoint/parity.json` |
| 同输入评估作者网络 | 63/64预测可行，1碰撞、9预算违例，16出训练域 | `author-checkpoint/evaluation.mat`、metrics.json |
| 自训网络独立校准 | 15/300联合违例，95%上界7.5949% | `reduced-calibration/` |
| 作者网络独立校准 | 2/300联合违例，95%上界2.0836% | `author-checkpoint/calibration.mat`、calibration.json |
| 方法测试 | 9/9通过；含独立RK4参照、自动梯度和校准有效性 | `../root-peer-review/`及统一测试日志 |

校准使用训练之外的种子25052。阈值选择与新条件样本审计分开，所有样本和逐轨迹标签在MAT中。步长0.005减至0.0025后，两份校准均无标签变化；这仍是有限步长的数值证据。

另从保存的原始轨迹重算事件分解：两份校准均0碰撞；15次及2次联合违例全部为预算违例，见各自 `calibration-events.json`。作者检查点在同一4096个输入上，对论文PDE的MSE为0.017780，对公开代码PDE的MSE为0.000272758，见 `author-checkpoint/pde-comparison.json`；这是损失分支差异的数值诊断。

`smoke.log` 保留100步路径；`training5000.log` 保留真实训练输出；`author-evaluation.log` 保留推理移植、评估和校准的实际输出。最初训练run中的闭环字段采用早期成本积分器；当前闭环指标以 `reduced-reevaluated/` 为准，训练网络未变。代码已将成本和预算改为同一RK4阶段积分，针对性测试能区分旧公式。

图中的轨迹只显示前20条，标题计数对应全部预测可行初值。已人工检查生成PNG的坐标、障碍、目标和文字；对应FIG可继续编辑。

两条路径都尚未达到零违例。作者公开代码与论文的训练VI项、状态裁剪和校准事件存在差异，详见[逐行核对](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/safe_pinn_author_code_audit.md)。当前源码、权重和实际数据足以继续定位差异，未将论文报告的99.9%安全率移植为本次结论。
