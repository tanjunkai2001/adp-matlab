# Bias-PI 非线性系统

在仓库根目录运行默认摆算例，采用局部多初值数据和折扣 bootstrap：

```matlab
[r,folder]=demo_reproductions('bias_pi_automatica2026');
```

网页上 **468.490 对 430.435、高 8.84%** 的成本对应机械臂 **5 秒**实验，需显式选择：

```matlab
[r,folder]=demo_reproductions('bias_pi_automatica2026',[],struct('example','arm'));
```

每条命令在 `runs/` 下新建一次运行，`folder` 返回保存目录。默认摆使用基础 MATLAB；机械臂的独立 LQR 参照使用 Control System Toolbox。[结果与配置表](RESULTS.md) 另列出 0.07435 秒提前终止的机械臂记录，其部分成本不能当成 5 秒成本。

[实际结果](RESULTS.md) · [全文与方程映射](../../docs/fulltext/bias_pi_automatica2026.md) · [全库入口参数](../../docs/IMPLEMENTED_API.md)。保存的结果是已执行的具体变体；源码包不包含历史MAT/FIG，完整包保留这些文件。
