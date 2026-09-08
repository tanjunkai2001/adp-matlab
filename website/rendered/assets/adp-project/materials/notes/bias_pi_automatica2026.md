# Automatica 2026：未知非线性连续系统的 Bias-PI

Ruiqing Zhang、Huaiyuan Jiang、Bin Zhou，*Adaptive dynamic programming for unknown continuous-time nonlinear systems via bias-policy iteration*，Automatica **185 (2026), 112821**，[DOI 10.1016/j.automatica.2026.112821](https://doi.org/10.1016/j.automatica.2026.112821)。正式稿首页记录：2024-07-26 收稿、2025-08-20 修回、2025-11-30 接受、**2026-01-09 在线发表**。

本轮通读正式 PDF 全部13页，包括正文证明、p11 Appendix、参考文献和作者信息；p5、6、7、8、10另核PDF图像。不是此前的摘要/预览记录。[所读PDF](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/ARTIFACTS.md) SHA-256：`93ca24abebbe6a139457b32fa387f197ba54f76f7a3e17f07dbda72837df1e69`。下述均为正式PDF页码。全文未给代码下载地址，不据此断言作者没有代码。

## 问题和主机制

系统是确定性、连续时间、控制仿射ODE：`xdot=f(x)+g(x)u`。目标仍是无折扣无限时域成本 `∫[Q(x)+u'Ru]dt`，Q正定、R正定，没有1/2系数。正文假设最优策略存在、正定最优值函数唯一。数据学习器不知道f、g，接收状态、实际输入、Q/R、基函数和采样时刻。p2将g的值域写成R^m，按动力学维度应为R^(n×m)。

p3式(10)–(11)为：

```text
∇V_i' (f+g u_i) − γ(V_i−V_{i−1}) + Q + u_i'R u_i = 0
u_{i+1} = −0.5 R^{-1}g'∇V_i
```

偏置项让开始阶段可以评价原无折扣成本不可积的策略。若迭代收敛，`V_i−V_{i−1}→0`，极限满足原无折扣HJB。**γ是辅助算法参数，不是最终任务的折扣率，也不要求每一步都将它降到零。**

值函数超过高阈值时，p6式(33)和p7 Algorithm 1切换到固定γ的折扣PI：

```text
∇v_new' (f+g u_target) − γ v_new + Q + u_target'R u_target = 0
u_next = −0.5 R^{-1}g'∇v_new
```

内层把值函数压回较低阈值后，恢复外层Bias-PI。γ下降公式是 `gamma_new=gamma_old*(beta_i−1)/beta_i`，分子是**β_i减1**，不是β_{i−1}。式(30)给出固定γ段的递推：

```text
beta_i = 1 + gamma*deltaBar/(1+gamma*deltaBar)*(beta_{i−1}−1)
beta_1 = 1+gamma*delta,   V0<=delta*Q
```

γ改变后如何重启/沿用β的计数和初值，数值实现应明确记录。

## 可实现的积分回归

p7–8式(38)–(48)沿实际行为输入u_b积分，免去f、g。为避开原文的下标混用，一次更新可明确命名为：冻结当前目标策略kappa和上一值函数Vref，回归产生Vnew和下一策略unext。

对不跨重置的区间[a,b]，定义 `w_gamma(t)=exp[-gamma*(t-a)]`：

```text
Δφ = exp[-gamma*(b-a)]*φ(x_b) − φ(x_a)
y  = −∫_a^b w_gamma*[Q+kappa'R*kappa+s]dt
Δφ'c_new + 2∫_a^b w_gamma*unext'R*(u_b-kappa)dt = y
```

- 外层Bias-PI对应**(43)**：`s=gamma*Vref`。
- 内层折扣PI对应**(48)**：`s=0`；Remark 6的初始化也用此式。
- 固定一批数据可反复使用；γ或目标策略变化后，需要重算相应指数加权项和策略项。

令 `Vnew=c_new'φ`、`unext=W_new'*ψ`，ψ有p个标量基函数，输入m维；实现中的W_new为p×m，actor共有p×m个权重。按MATLAB列优先向量化，W_new(:)按输入通道分块，actor回归块为 `2∫w_gamma*kron(R*(u_b-kappa),psi)dt`。全部区间堆叠后解：

```matlab
coeff = Theta \ Y;  % 满列秩时的QR；近奇异情况显式采用SVD策略
cNew = coeff(1:nCritic);
WNew = reshape(coeff(nCritic+1:end),nActorBasis,nInput);
```

保存秩、奇异值、列尺度、秩容差、残差及积分规则。arm的10个critic特征、每个输入8个actor特征，应有 **10+2×8=26** 个未知量，不能按10+8建立回归。

p9 Remark 6给出可用初始化入口：先选u_{−1}，用足够大的γ解一次无偏置项的(48)，得到配套V0和贪婪u0。所得V0/策略、回归秩、正定性和工作域上的初始化条件需要实际检查。若采用bootstrap，就不能再声称所得V0严格等于Table 1所写初始多项式。

## 内部不一致及处理

| 位置 | 已核对的问题 | 实现处理 |
|---|---|---|
| p8 Algorithm 2，第7、11行 | 内层引用(43)、外层引用(48)，与推导和Algorithm 1相反 | 内层解(48)，外层解(43)，分别是否含gamma*Vref |
| p8 Algorithm 2，第8行 | 内层停止判断仍用外层c[i]，循环内没有更新这个检测量 | 检测最新内层c[i,j]；循环下标与数据区间下标分开 |
| p8式(49) | 已定义Theta为l×d，却写(Theta*Theta')^{-1}*Theta*Y，维度不相容 | 解Theta*coeff=Y；即使正规方程也应为(Theta'*Theta)^{-1}Theta'*Y，实际优先QR/SVD |
| p7–8式(41)–(48) | critic索引i对应V_i，actor权重却对应u_{i+1}；(44)附近内层u/v梯度下标也混用 | 分别记录targetPolicy与nextPolicy，下一轮才用新actor |
| p10 Table 1 | φ行标成Actor、ψ行标成Critic，与(41)/(42)相反 | φ是值函数特征，ψ是策略特征 |
| p10 Table 1 | deltaBar=8/16标Upper，deltaH=30/60标Lower；算法要求deltaH>deltaBar | 30/60是内层触发高阈值，8/16是退出低阈值 |
| p10摆最终权重 | ψ有5项，最终actor却只印[−2.415,0.065,0.011,0.058]四项；图像确认不是OCR丢失 | 不补零、不猜缺项，不能据此重建完整作者控制器 |
| p10初始函数 | 摆V0=x1²+x2²按g=[0;1]的greedy应为−x2，与表列−x1−x2不配对；arm的V0=x1²+x2²在四维状态上仅半正定 | 使用Remark 6 bootstrap，或明确标记改用全状态正定V0的变体，不能同时声称照搬原表且满足全部初始化假设 |

Algorithm 1/2中的max_x也缺少检测域/网格定义，Appendix只出现未具体定义的Ω。摆的最终critic含非零三次项，Q为二次函数；若对全R²取上确界，V−delta*Q通常无界。因此实现必须规定有限工作域及检测方法，不能把网格检验写成全域不等式证明。

## 两个算例的参数和结果

**倒立摆，p9–10 §4.1。** `xdot1=x2, xdot2=sin(x1)+u`；Q按二状态欧氏平方理解，R=1，初值[0;0.01]。采样间隔0.01s、采集5s，然后施加学习控制器。critic按原表顺序为 `[x1²,x2²,x1³,x2³,x1*x2,x1²*x2,x1*x2²]`；actor为 `[x1,x2,x1²,x2²,x1*x2]`。γ0=6，低/高阈值8/30，停止量为critic系数变化平方和、阈值1e−6。

探索为 `0.01*sum_{j=1}^{50}sin(omega_j*t)`，频率在[−50,50]随机取值。§4.1把该正弦和直接称作u，而Algorithm 2第1行写u0+e；实现应说明采用纯探索还是叠加u0。种子、具体频率和相位没有公布。

论文报告54次迭代，critic最终为 `[3.415,2.414,−0.206,−0.007,4.829,−0.125,−0.061]`；actor缺项如上。Table 2报告γ0=[0,0.5,1,6,12,48,96]时迭代数分别为[22,15,19,54,105,385,738]。γ0=0的迭代终止不等于得到稳定控制。Fig.5比较35个随机初值、各状态在[−3,3]的LQR成本；没有给随机初值列表、成本积分终点/尾项或误差条定义，不应按图构造这些数值。

**二关节手臂，p10–11 §4.2。** 坐标为绝对关节角及误差：`x=[theta1−pi/4,theta2−3*pi/4,thetaDot1,thetaDot2]'`。动力学为 `D(theta)*thetaDDot+C(theta,thetaDot)*thetaDot=u`：

```text
D=[k1,k3*cos(theta2-theta1);k3*cos(theta2-theta1),k2]
C=[0,-k3*sin(theta2-theta1)*thetaDot2;
   k3*sin(theta2-theta1)*thetaDot1,0]
(k1,k2,k3)=(0.265,0.052,0.0844) kg*m²
(l1,l2)=(0.33,0.32) m
Q=diag(5000,2000,20,10), R按u²理解为I2
```

初始角度[0;pi/2]，目标[pi/4;3*pi/4]；初始角速度没有明确给出，取零时应记录。采样0.05s、采集10s、γ0=15、低/高阈值16/60、停止阈值1e−10。critic为 `[x1²,x2²,x3²,x4²,x1*x2,x1*x3,x1*x4,x2*x3,x2*x4,x3*x4]`，每通道actor为 `[x1,x2,x3,x4,x1²,x2²,x3²,x4²]`。论文报告45次迭代，展示第0、8、45次的手部路径及状态，p10–11给出10个critic、16个actor数值。表中二维探索只写一个正弦和，未说明两个通道的独立频率/相位，不能默认同一探索就满足完整actor回归秩。

**两例共同缺少的实现参数**：Remark 7的重置半径C及数据分段；探索种子和多输入配置；积分器/求积及容差；阈值检测域/网格；β所需初始delta及γ切换后的计数规则；LS尺度、秩阈值和近奇异处理；最大内外循环次数与异常退出。Remark 7明确采用超出C后重置到初值的采样方式；跳变不能放入连续积分Bellman区间。

## 理论证据与平台结果的分界

p3–7理论链为：Lemma 2通过V0<=delta*Q及初始非负HJB余量建立β/δ上界；Theorem 1在δ序列有界时证明收敛；Theorem 2给足够小γ条件；Lemma 3分析折扣内层；Theorem 3组合为Algorithm 1。条件(13)还包含exp(−gamma*t)*V0(x(t))→0，不能只检查瞬时残差。C0应读作依状态变化的非负余量，其后C1表达式也支持这种解释。

式(31)的充分界满足 `exp[gammaBar*delta*(gammaBar*deltaBar+1)]=deltaBar/delta`。Algorithm 1/2还要求`deltaBar*Q>V*`，涉及未知最优值；按有限网格选出一个工作阈值，并不等于已验证这条先验条件。

证明另有具体核对点：p4式(22)把归纳条件写成V_{i−1}<=beta_i*V_i，与(15)反向；p6 β3推导的一行左侧用V0、右侧用V1，不能按原样成立。p5 Theorem 1从值函数极限直接传递到含梯度的HJB，没有展开梯度收敛/正则性条件；p7 Theorem 3以各β项有限排除β趋于无穷，还需统一上界补足。这些应分别作为排版修正和证明待补步骤，数值运行不会自动补出证明。

数据条件(50)要求完整回归向量的经验Gram矩阵有严格正下界并覆盖各次迭代；加入正弦探索不自动证明该条件。p11 Appendix的Lemma 4省略证明、指向Jiang & Jiang (2017)，Theorem 4用该近似引理和模型迭代收敛，再用三角不等式得到存在性结论。它不是有限字典、固定批次、带积分误差的显式误差上界；Remark 10将测量噪声与鲁棒性列作扩展方向。

本卡记录论文内容、逐式核验和实现解释。54/45次迭代及图表比较属于论文结果；平台实际运行、另选参数、公式修正后的变体及失败记录应由本方法配置和v0.4证据单独给出，不能写成已重现原文数字。v0.3代码和历史证据保持冻结。
