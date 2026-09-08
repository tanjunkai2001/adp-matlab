# Bias-PI：已记录的配置与结果

下表汇总 2026-09-07 保存的两个非线性算例。它们采用明确的局部多初值数据变体，未复现论文的全部权重和54/45轮迭代数。当时的12项方法测试包含在94/94历史全库记录中；当前发布版本的测试范围与环境见 [VALIDATION](https://github.com/tanjunkai2001/adp-matlab/blob/main/VALIDATION.md)。测试记录与下面的闭环实验分别解读。

| 项目 | 摆（入口默认） | 双关节机械臂（显式选择 arm） |
|---|---|---|
| 初始处理 | Remark 6 折扣bootstrap | Remark 6 折扣bootstrap |
| 数据 | 总5s、500窗、20个局部初值 | 总10s、200窗、20个局部初值 |
| 外层/内层迭代 | 38/0，γ保持6 | 27/0，γ保持15 |
| 回归秩 | 12/12 | 26/26 |
| 列缩放条件数 | 87.02 | 1877 |
| 非线性闭环 | 35/35初值20s后范数<.01 | 论文目标运动5s后范数1.74e−27 |
| 对局部LQR | 配对成本差−.149876 ± .065321 SE | 成本468.490 vs430.435，高8.84% |
| 仍未匹配 | 论文54轮；5项actor只印4权重 | 论文45轮；actor权重相对差55.52% |

成功运行的γ没有降到0，但每轮都含γ*Vprevious，固定点仍针对无折扣HJB。降γ和内层更新路径由独立解析测试实际覆盖。

摆的完整多初值、原单轨迹失败、γ=0拒绝、4→8积分子步对照与留出残差见 [摆结果](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.1/evidence/v0.4/bias-pi/PENDULUM_RESULTS.md)。积分加密后的actor差约1.32e−6；在[−3,3]²的HJB RMS仍为21.695，35个稳定闭环不代表该整个范围的值函数已准确。

## 机械臂：配置与闭环应一起读

两条机械臂记录使用同一模型、代价、字典、总10秒采集/200窗和折扣 bootstrap。下表的诊断数值来自 [独立审计](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.1/evidence/v0.4/bias-pi/independent-tests/arm-audit.json)，与 [单初值摘要](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.1/evidence/v0.4/bias-pi/arm-bootstrap/summary.json)、[多初值摘要](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.1/evidence/v0.4/bias-pi/arm-local-multistart/summary.json) 对应；模式/半径行说明当前入口如何选择配置，不能代替历史MAT中的完整cfg。

| 配置/诊断 | 单初值反复重置 | 局部多初值（当前 arm 默认） |
|---|---:|---:|
| 数据模式 | `paper_initial` | `local_multistart` |
| 当前入口未覆盖的 `resetRadius` | 2 | 0.8 |
| 外层迭代 / 内层迭代 | 47 / 0 | 27 / 0 |
| 回归秩 | 26/26 | 26/26 |
| 列缩放条件数 | 1.39599984e8 | 1877.08224 |
| critic 最小特征值 | −257.31824 | 0.126815 |
| 原点真实闭环最大极点实部 | +6.55581 | −12.95887 |
| 实际闭环时长 | 0.0743454 s，触发状态上限100 | 完成5 s |
| 学习策略成本 | 27069.2926，仅提前终止前的部分成本 | 468.4900，完整5 s |
| 与5 s局部LQR成本430.4350的比较 | 时域不同，不计算成本比率 | 高8.8411% |

两条记录的学习器状态均为 `converged`，表示系数变化满足停止阈值；第一条的负 critic 方向、正闭环极点实部及提前终止仍必须保留。不能把回归满秩或停止条件满足读成闭环成功。

局部多初值变体从目标附近20个初值各采集0.5秒，初值尺度为[.15,.15,.2,.2]；两输入各用独立50频率正弦，频率种子20260907。当前 [配置函数](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.1/reproductions/bias_pi_automatica2026/bp_arm_config.m) 在选择 `paper_initial` 且未显式给出半径时，会将 `resetRadius` 从0.8改为2。按此入口切换模式会同时改变初值安排和重置边界；现有记录不能把条件数或闭环差异单独归因于“多初值”。局部多初值记录的成本仍高于局部 LQR，未显示论文所述最优性优势。大型MAT/FIG保留方式见 [历史归档说明](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md)。

方法测试覆盖具体方程、数值接口和运行分支。两个默认变体可作为后续研究起点；原文未公开的采样/检测域参数仍阻止逐数字的完整复刻。

## 直接运行

在仓库根目录的MATLAB会话中：

```matlab
% 默认摆：35个初值、20秒闭环评价。
[r,folder] = demo_reproductions('bias_pi_automatica2026');
% 机械臂：对应上表完成5秒的局部多初值配置。
[r,folder] = demo_reproductions('bias_pi_automatica2026',[],struct('example','arm'));
```

以上两条分别建立新的运行目录。若要复查历史失败配置，显式指定未使用的新路径：

```matlab
demo_reproductions('bias_pi_automatica2026','new-single-pendulum', ...
    struct('collectionMode','single_trajectory','initialization','paper_table'));
demo_reproductions('bias_pi_automatica2026','new-paper-arm', ...
    struct('example','arm','dataMode','paper_initial','resetRadius',2));
```

原始全文章节/公式映射见 [METHOD](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/bias_pi_automatica2026/METHOD.md) 和 [全文卡](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/bias_pi_automatica2026.md)。默认方法学习只用基础MATLAB；机械臂演示中的独立LQR参照需要Control System Toolbox。
