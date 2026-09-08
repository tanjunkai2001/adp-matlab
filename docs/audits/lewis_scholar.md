# Lewis 软件与本人研究方向核验（2026-09-07）

范围：为统一 MATLAB ADP 库提炼模块、接口和复现规则。所有下载代码仅作静态阅读，未运行；没有把静态检查等同于复现成功或理论验证。以下设计建议是本次判断，不是原作者对统一库的建议。

## 1. 来源与读取范围

- 官方来源：https://lewisgroup.uta.edu/code/Software%20from%20Research.htm
- 下表的四个源包已于 2026-09-07 下载并静态阅读，包版本与 SHA-256 见 [registry/upstream.json](../../registry/upstream.json)。原始包和访问日志不随源码分发。
- 研究方向参照本人[主页](https://tanjunkai2001.github.io/)及[发表列表](https://tanjunkai2001.github.io/publications/)。未取得 Google Scholar 完整条目，未核验其引用数；书目核验结果分别记录。

## 2. Lewis 官方目录确实覆盖什么

官网是按论文和研究主题组织的下载目录，并声明 “This software is not supported.”；不是有统一 API、测试和版本发布的工具箱。主题包括：微电网协同控制；连续/离散图博弈；积分 RL 输出反馈；DT ADP（HDP、DHP、ADHDP/Q-learning、ADDHP）；CT PI、LQT、off-policy H∞ 跟踪、经验回放；部分可观测 ADP；同步 actor–critic/博弈；神经自适应；离线 HJB/HJI 逼近；飞行器/四旋翼；离散事件系统。官网还保留早期论文的 “to appear” 信息，因此当前书目信息需另核。

与统一 ADP 库直接相关、在官网实际列出的下载 URL：

| 主题 | 官方包 URL | 本次状态 |
|---|---|---|
| DT HDP/DHP/ADHDP/ADDHP | https://lewisgroup.uta.edu/code/ADP%20code.zip | 下载并读 4 个 .m |
| CT PI，线性/非线性 | https://lewisgroup.uta.edu/code/vrabie.zip | 下载并读 2 个 .m |
| CT constrained-input IRL + replay | https://lewisgroup.uta.edu/code/reza%20experience%20replay.zip | 下载并读 1 个 .m |
| CT 同步 actor–critic | https://lewisgroup.uta.edu/code/online%20synch%20opt%20ctrl.zip | 下载并读 2 个 .m |
| DT 非线性/零和 | https://lewisgroup.uta.edu/code/asma.zip | 仅目录链接核验 |
| DT Q-learning 跟踪 | https://lewisgroup.uta.edu/code/1.%20LQT%20Q%20learning%20Automatica%202014.zip | 仅目录链接核验 |
| CT LQT | https://lewisgroup.uta.edu/code/reza%20LQT%20using%20RL.zip | 仅目录链接核验 |
| CT off-policy H∞ 跟踪 | https://lewisgroup.uta.edu/code/reza%20hinf%20tracking%20with%20off%20policy.zip | 仅目录链接核验 |
| 输出反馈 | https://lewisgroup.uta.edu/code/opfb%20adp.zip | 仅目录链接核验 |
| IRL 输出反馈 | https://lewisgroup.uta.edu/code/Lemei%20codes.zip | 仅目录链接核验 |
| CT 图博弈 | https://lewisgroup.uta.edu/code/CT%20graph%20games.zip | 仅目录链接核验 |
| DT 图博弈、Q-learning | https://lewisgroup.uta.edu/code/DT%20GG.zip ; https://lewisgroup.uta.edu/code/DT%20GG%20Q.zip | 仅目录链接核验 |
| 同步 H∞ | https://lewisgroup.uta.edu/code/online%20synch%20Hinf.zip | 仅目录链接核验 |
| 离线 HJB/HJI | https://lewisgroup.uta.edu/code/code%20MAK%20HJB.zip ; https://lewisgroup.uta.edu/code/code%20MAK%20HJI.zip | 仅目录链接核验 |

### 2.1 实际包散列与版权状态

| 文件 | bytes | SHA-256 | 许可证据 |
|---|---:|---|---|
| ADP code.zip | 165843 | ab24deff7c82d5a752952571c4232cf1d1bfbebe91807e0a494d4c30675592cf | 4 个 MATLAB 文件 + Landelius.pdf；无 LICENSE 文件；代码头有作者/日期，无明确开源授权 |
| vrabie.zip | 2901 | bb874daa3cc59723dbc6ce46fa747653af3e4d131610cf6212809ce2f22aa880 | 2 个 MATLAB 文件；无 LICENSE 文件、未找到授权条文 |
| reza experience replay.zip | 936476 | a9accd1480f888125136300db4b84456ae0b896292afbe53fb26a3e63c130819 | 1 个 MATLAB 文件 + 论文 PDF；无 LICENSE 文件、未找到代码授权条文 |
| online synch opt ctrl.zip | 2480 | 973a8ece7f0886d803d02b61eb26d16ffc575447ab12377652ad0d6c261169dc | 两个 .m 第 4 行均为 “All rights reserved” |

本次只确定是否出现许可文件/文字，没有给出法律结论。**公开可下载不能自动改称具有开源再分发许可。** 最稳妥结构是保留原始来源/散列/获取脚本，将原包放独立、默认不发布的 upstream 区；核心规范实现依据数学定义独立编写并引用论文。准备搬运原代码时，逐包确认许可，不能为整个 Lewis 集合统一贴 MIT。

### 2.2 四类静态观察及其规范意义

以下位置都以包内实际文件的 1-based 行号为准。

| 位置 | 重要程度 | 发现/原因 | 统一库应落实的修改方案与可执行指令 |
|---|---|---|---|
| `ADP code/ADHDP.m:53–78`，`HDP.m:37–51` | 高 | 手写二次特征；还原对称矩阵时交叉项除以 2；使用正规方程与 `inv(C)`，ADHDP 只输出 rank | 建 `features.quadratic` + `svec/unsvec`，固定交叉项 convention；建 QR/SVD 最小二乘求解器，返回 rank、sigma_min、condition、residual；rank 不足必须 `insufficient_data`，不静默输出权重 |
| `ADP code/DHP.m:42–46`，`HDP.m:51` | 高 | 价值梯度或策略改进显式使用模型 A/B；不能仅凭包名统称 model-free | 每个 algorithm manifest 明确已知 `f/g/A/B/jacobian`、输出/状态可用性、在线数据要求；模型与 learner 端输入分离 |
| `vrabie/ONLINEpolicyiteration_lin.m:1,4–5,42–80,89` | 高 | 主函数名为 odestart，与文件名不符；global；积分成本与特征差建立批量方程，care 是线性参照 | 上游入口适配需保留原件；核心使用 `run(config)`、显式 learner state；将积分回归器、policy evaluation、policy improvement、CARE oracle 分开 |
| `vrabie/ONLINEpolicyiteration_nonlin.m:28–60` | 高 | 初始稳定策略有文字假定；在线循环中随机重置系统状态，未设随机种子 | `initial_policy` 明确稳定性证据/适用域；区分一条连续闭环轨迹与 reset 数据采样协议；随机种子、每次 reset、PE 输入应进日志 |
| `online synch opt ctrl/dynamicsnew3.m:25–37,49,67,69–78` | 高 | critic/actor 权重分别属于 ODE 状态；回归使用 u，系统使用加入探索的 unew | 建算法级 `learner.flow`；记录 `u_policy/u_probe/u_applied` 及 Bellman 回归输入定义；切勿把未解释的输入差当成 off-policy 校正已完成 |
| `reza experience replay/.../My_IRL7.m:70–93,282–305,490–513` | 中 | 24 个多项式与导数多处复制，易出现特征顺序/微分漂移 | 唯一 `FeatureMap` 定义输出 phi 与 Jacobian，单元测试做解析梯度与有限差分比对；固定维数、顺序、状态归一化 |
| 同文件 `:322–352,551` | 高 | replay 容量 S=68，按特征差范数替换样本；范数增大本身不等于满秩/持续激励 | buffer 存原始 transition 与派生量版本；分别实现 FIFO、rank-aware、原论文规则；记录 Gramian 最小特征值与经验矩阵秩，不以填满 buffer 替代 excitation 假设 |
| 同文件 `:519–556` | 高 | nominal u 经探索后成 unew，再截断 [-1,1]；状态导数使用 unew，积分代价使用 u；`atanh/log` 在数值极限需检查 | **这是口径核验点，不凭静态代码判论文错误。** manifest 必须声明成本评估的是哪条输入；新增 saturation-stable cost primitive；以测试覆盖 u→±1、nominal/applied 差值及回放口径 |
| 多个包入口和 plotting 段 | 中 | clear/close/global、绘图混入仿真、硬编码模型和时长、无统一结果 schema | 模型、控制器、算法、仿真器、metrics、plot 分层；保存 struct/MAT + JSON manifest；plot 从已保存 result 重画；每次 run 有唯一目录 |

目录中的 H∞、图博弈、OPFB 包尚未下载阅读，不能把上述 4 包观察无条件外推到全部包。以上发现用于设计，不是对这些历史参考程序的运行缺陷定论。

## 3. 本人身份链与可验证工作方向

身份链已建立：本人主页显示 Junkai Tan / 谭浚楷，同时链接指定 Scholar ID、GitHub 账户 tanjunkai2001、FxT-CL-ACI；FxT-CL-ACI README 又反向链接本人论文主页。Wiley 论文页作者 Junkai Tan 与 ORCID 0009-0002-0558-6357、XJTU 单位对应。没有使用其他同名作者的论文归入本人。

下面只选直接影响 ADP 库接口的代表工作，并区分证据层级。不是完整发表或贡献清单。

| 研究工作/方向 | 已核实出处 | 对规范库的直接映射 |
|---|---|---|
| FxT-CL-ACI，鲁棒跟踪、未知参数辨识、输入饱和、Stackelberg H2/H∞ | Springer 官方标题/作者/摘要/DOI核验：https://link.springer.com/article/10.1007/s11071-025-11235-8 。DOI `10.1007/s11071-025-11235-8`；2025；本人主页直接关联代码 | `learners.actor_critic_identifier`、`buffers.concurrent`、`games.stackelberg`、`policies.saturated`、`benchmarks.tracking` |
| 安全 ADP 共享控制、level-k、Softmax 人行为、非对称状态变换 | Wiley 官方页：https://onlinelibrary.wiley.com/doi/abs/10.1002/rnc.7931 。DOI `10.1002/rnc.7931`；2025；标题/作者/摘要核验 | `games.level_k`、`human.behavior`、`shared.arbitration`、`constraints.transforms` |
| 多玩家非零和与四旋翼有限时间安全 RL | 本人发表列表 + 上述 Springer 参考文献双重关联；DOI `10.1016/j.ins.2025.122117`；出版社正文访问失败 | `games.nonzero_sum`、逐玩家 cost/value/gradient、`plants.quadrotor`；此处没有核验全部理论或代码 |
| PPC 鲁棒最优跟踪/Stackelberg | 本人主页直连 IEEE document 10916718；Springer 参考文献核对 DOI `10.1109/TASE.2025.3549114` | `performance.envelopes`、tracking transform、game response；精确算法仍需论文全文 |
| UAV–UGV 追逃/对接 | 本人发表列表 + Springer 参考文献核对 DOI `10.1007/s11071-025-11021-6` | `games.pursuit_evasion`、`scenarios.docking`、多实体状态/控制布局 |
| 数据驱动 UAV 共享控制 | 本人发表列表 + Springer 参考文献核对 DOI `10.1016/j.neucom.2025.129428` | lifting/identified-model adapter、human command provenance；未读全文，不能仅标题推定具体 Koopman 实现 |
| 可调状态/输入约束与 prescribed-time actor–critic | 本人主页 + Crossref 精确标题及作者匹配；DOI `10.1109/TNNLS.2026.3693754`；IEEE document 11552882 只有极少可提取正文 | `constraints.time_varying_bounds`、`clocks.guaranteed_time`，时间承诺和作用对象需单独记账 |
| 随机人–UAV 交互、状态输入约束 | 本人主页 + Crossref 精确标题/作者匹配；DOI `10.1109/TIE.2025.3603074`；卷期年份与 DOI 年份可不同 | stochastic process、seed stream、Monte Carlo metric、inverse-objective 未来适配；不可仅标题预设扩散模型 |
| 动态事件触发 finite-time ACI | 本人发表列表 + Crossref 精确标题/作者；DOI `10.1016/j.ins.2025.122651`，本人为合著者 | `scheduling.event_trigger`，t_measure/t_learn/t_apply 分离、事件日志、held input |
| Dual-Clock、灵活饱和 | 本人主页列出并直连 IEEE document 11609294；本次 Crossref 429，DOI 未核验 | clocks 与 saturation 作为独立模块；不能把网页标题/链接当理论范围已审计 |
| 混合 FDI–DoS 下约束 critic-learning | 本人主页列出并直连 IEEE document 11649534；本次 Crossref 429，DOI 未核验 | `channels.attack_delay_dropout`、`signals.u_received/u_applied`、缺包/伪造输入日志；保留为扩展适配 |

本人主页明确的研究兴趣归为安全学习/控制、自主系统与多智能体、人机共享自主。程序库应以控制 ADP 主线优先；车辆路径规划等离散组合 deep RL 工作即使同属本人研究，也适合单独 adapter，不应强行共用 HJB 连续控制 API。

## 4. 建议交给主设计的模块边界

1. 先建立可验证线性参照：CT/DT LQR、PI 与 quadratic Q-learning；用 CARE/DARE 比较是数值参照，不是非线性算法正确性证明。
2. 共同核心放 `systems/costs/features/data/numerics/signals/results`。CT HJB、integral Bellman 与 DT Bellman 各有明确 residual，禁止一个万能 `bellman_error` 隐藏数学口径。
3. `learners` 区分离散 `update` 与连续 `flow`。ODE 右端必须无副作用；buffer 插入、随机采样、控制器发布等发生在被接受的时间节点/事件上，避免自适应求解器重复调用导致学到不同算法。
4. `policy`、`exploration`、`safety_filter`、`actuator/channel` 顺序可配置但必须写出每段输入信号；reward/cost 与 regression 分别声明所用输入。
5. safety/PPC/fixed-time 是具有假设、定义域和验证证据的模块，不是布尔开关。模型误差界、初始可行性、QP 失败、reset、PE、饱和、采样实现均需单独状态。
6. 上游复现的第一产物应是 `source_manifest + equation_to_code + run_config + reference_comparison`；先忠实复现原程序并记录修补，再抽象模块。不能在统一接口中无痕更换原算法。
7. skill 集合至少包含 `adp-source-audit`、`adp-equation-contract`、`adp-matlab-implementation`、`adp-reproduce`、`adp-safety-clock-audit`、`adp-evidence-release`。技能负责证据和工作流；算法实现在有测试的 MATLAB 模块，避免技能文案与代码形成两套算法真源。

下一步应选择 FxT-CL-ACI 与一个 Lewis CT PI 作为首批 adapter。当前只证明来源、文件内容与架构问题已核验；未完成原包运行复现、论文逐式核对或统一库科学验证。
