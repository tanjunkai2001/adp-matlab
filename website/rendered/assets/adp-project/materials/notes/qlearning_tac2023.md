# TAC 2023：离线 Q-learning

Victor G. Lopez, Mohammad Alsalti, Matthias A. Müller, *Efficient Off-Policy Q-Learning for Data-Based Discrete-Time LQR Problems*, IEEE TAC 68(5):2922–2933, 2023. [正式条目](https://www.irt.uni-hannover.de/en/forschung/publikationen/publikation-detail/publications/efficient-off-policy-q-learning-for-data-based-discrete-time-lqr-problems)，[DOI](https://doi.org/10.1109/TAC.2023.3235967)，[所读作者全文 v3](https://arxiv.org/pdf/2105.07761v3)。本轮读完12页，包括§VI噪声分析、§VIII对照实验和参考文献；公式(29)另核了PDF图像。它是正式 TAC 基础方法，年份为2023，不列成2026新方法。

## 方法与实现

系统为离散线性 `x(k+1)=A*x(k)+B*u(k)`；成本 `sum(x'*Q*x+u'*R*u)`，无折扣、无半系数。学习器仅接收状态/输入数据、Q/R和初始K，仿真真值A/B只在采样器和独立评估出现。固定一批数据贯穿全部迭代。

`Theta` 表示 Q 函数：`Q_K(x,u)=[x;u]'*Theta*[x;u]`。QR选出 `eta=n+m` 个独立数据列得到 Z；当前策略构造 `Y=[Xnext;-K*Xnext]`，直接解

```text
Z' Theta Z = Z' diag(Q,R) Z + Y' Theta Y       (29)
Knew = Theta_uu \ Theta_ux                    (17)
```

MATLAB 使用 `dlyap(Y',Z'*Qbar*Z,[],Z')`。返回前再次评估最终K，使保存的K、Theta、P属于同一策略。数据算法不会调用 `dlqr(A,B,...)`；该函数只提供独立参照。

初始稳定器使用§V的观测数据构造：F=X0的右逆，G=null(X0)，Abar=X1*F，Bbar=X1*G，最后 `K0=-U*(F-G*Hbar)`。SISO采用零极点，属于Algorithm 2的deadbeat特例。MIMO采用同一数据对上的不同小极点[-0.2,0.2]，是明确记录的稳定化变体；没有实现原文MIMO规范形构造。

## 全文核对对代码的直接影响

- **p3–5，式(16)与(29)：实现关键。** 仅有eta个标量对角等式，不能确定eta(eta+1)/2个对称未知数；独立向量不自动提供全部交叉等式。实现采用原文最终的完整矩阵式(29)，测试中给出“对角为零但矩阵非零”的反例。矩阵式本身由系统恒等式推得，足以支撑这份实现。
- **p7–9，式(44)/(56)：噪声条件。** 输入PE与数据满秩不等于真实闭环稳定；噪声界还涉及模型范数及策略/值函数量。程序记录噪声实验的失败和真实A-BK谱半径，没有把经验噪声幅值当定理上界。
- **p10–11，Table I–V：对比口径。** 原文比较100组随机系统、不同维数、CVX-LMI与RL基线。本轮独立种子20组n=5,m=2，比较QL与数据辨识后DARE，尚未执行CVX及n=50时间对比。原文没有给随机种子、具体PE输入及Q/R，代码显式取Q=I,R=I和均匀输入；不追平原表数值。
- **初始化实测修正。** 浮点误差会使Bbar出现超过已知输入数m的数值秩，首轮无噪声也可能产生错误稳定器。按rank(Bbar)<=m保留最多m个独立列后，无噪声20组全部成功。噪声下这一步属于同样明确的低秩近似。

## 运行

在仓库根目录：

```matlab
addpath(fullfile(pwd,'reproductions','qlearning_tac2023'));
[result,runDir]=demo_qlearning_tac2023;
tests=runtests('reproductions/qlearning_tac2023/testQL.m');
```

依赖 Control System Toolbox。每次生成独立run，含全部采样、原始噪声、训练历史、增益、成本、CSV和图。主例是显式三状态系统；有DARE、deadbeat、Bellman交叉等式、最终策略/价值配对和噪声对照检查。最终数字见仓库VALIDATION及evidence目录。

本文件是原创算法解读与独立实现映射；作者代码搜索未定位到可确认的本篇仓库，没有复制第三方源码。
