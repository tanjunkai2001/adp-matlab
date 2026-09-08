# Bias-PI：本次实际复现结果

正式全文13页已取得并通读；两个非线性算例已实现和调试。当前提供明确的局部多初值数据变体，未复现论文的全部权重和54/45轮迭代数。独立方程/采样11项和机械臂功率恒等式1项均通过，且包含在全平台94/94测试中。

| 项目 | 摆（默认） | 双关节机械臂（默认） |
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

摆的完整多初值、原单轨迹失败、γ=0拒绝、4→8积分子步对照与留出残差见 [摆结果](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/evidence/v0.4/bias-pi/PENDULUM_RESULTS.md)。积分加密后的actor差约1.32e−6；在[−3,3]²的HJB RMS仍为21.695，35个稳定闭环不代表该整个范围的值函数已准确。

机械臂原单初值反复重置的数据虽有26列秩，条件数约1.40e8，47轮后critic出现负方向，闭环在0.07435s达到状态上限100。其27069.29是提前终止的部分成本，不能和5s LQR作同期限比较。原数据、权重、轨迹与图仍在 [失败运行](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/evidence/v0.4/bias-pi/arm-bootstrap/summary.json)，终止时刻和完整谱数据见 [独立审计](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/evidence/v0.4/bias-pi/independent-tests/arm-audit.json)。

保持模型、代价和字典不变，改用目标附近20个初值各0.5s后，得到上表的稳定机械臂变体；数据初值尺度为[.15,.15,.2,.2]，两输入各用独立50频率正弦，频率种子20260907，resetRadius=.8。默认critic最小特征值.126815，局部闭环最大极点实部−12.9589。它改善了数据覆盖和条件数，但成本仍差于局部LQR，不能写成已重现论文的最优性优势。[成功运行](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/evidence/v0.4/bias-pi/arm-local-multistart/summary.json)保存完整MAT、PNG和可编辑FIG。

全平台测试验证了具体方程、数值接口和运行分支。两个默认变体是可用的后续研究起点；原文未公开的采样/检测域参数仍阻止逐数字的完整复刻。

## 直接运行

在仓库根目录的MATLAB会话中：

```matlab
[r,folder] = demo_reproductions('bias_pi_automatica2026');
[r,folder] = demo_reproductions('bias_pi_automatica2026',[],struct('example','arm'));
results = run_all_tests;
```

前两条自动建立新的运行目录。若要复查失败配置，显式指定新路径：

```matlab
demo_reproductions('bias_pi_automatica2026','new-single-pendulum', ...
    struct('collectionMode','single_trajectory','initialization','paper_table'));
demo_reproductions('bias_pi_automatica2026','new-paper-arm', ...
    struct('example','arm','dataMode','paper_initial'));
```

原始全文章节/公式映射见 [METHOD](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/reproductions/bias_pi_automatica2026/METHOD.md) 和 [全文卡](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/fulltext/bias_pi_automatica2026.md)。默认方法学习只用基础MATLAB；机械臂演示中的独立LQR参照需要Control System Toolbox。
