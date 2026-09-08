# FxT-CL-ACI 实码审查与迁移建议

检查日期：2026-09-07。只读审查，没有运行 MATLAB 仿真，没有验证论文定理、图形重现或硬件结果。未操作用户其他研究目录。

## 1. 固定来源与审查范围

- 上游：https://github.com/tanjunkai2001/FxT-CL-ACI
- 默认分支 `main`；本次核对的 HEAD：`e6fd86390f6895a588390c01957a3e4393ffe432`，2025-04-10，`Update README.md`。永久页面：[commit](https://github.com/tanjunkai2001/FxT-CL-ACI/commit/e6fd86390f6895a588390c01957a3e4393ffe432)。
- 获取方式：完整浅克隆未成功；改为 GitHub tree 元数据与逐个源码下载。19 个文本文件已逐一按 Git blob SHA-1 与 tree 清单核对，全部一致。源码只读研究副本 `work/upstream/fxt_source/`，元数据 `work/fxt_tree.json`。没有把缓存 MAT 文件作为本次复现结果。
- tree 未发现 LICENSE/COPYING/NOTICE 文件。此事实说明没有在仓库找到明确许可证；不能仅凭“公开仓库”把其中第三方代码自动赋予新仓库许可证。用户自己的贡献可单独确认授权；当前规范可原创实现算法接口，并保留来源清单。
- 目录：`Simulation/` 两个主脚本；`Utilization/` 14 个函数文件，含基函数、模型回归器、参考轨迹、数值积分辅助；`Data/` 有 `data_case1.mat`（约 16.3 MB）、变量 CSV 和一个三行脚本；根目录 README、图片、`.gitattributes`、`.DS_Store`。tree 中未发现自动化测试、CI、环境锁定、例子注册表或依赖清单。
- README 给出的入口是 `Simulation/main_FxT_CL_ADP.m`；绘图入口为 `Simulation/plot_fig_FxT_CL_ADP.m`，说明使用 `Data/data_case1.mat`。README 的论文和硬件视频链接仅是来源指引，不是此次运行证据。

## 2. 实际默认实验是什么

默认二维非线性系统，两个控制输入、一个对抗输入；模型参数估计器 4 维；两组 critic、两组 actor 各 6 维；另有二维辅助变量 `y`。`model=0`（源码注释称 model-free/SysID），`H2Hinf=1`，`umax=5`，`gamma=5`，`Q=I`、`R=20I`，仿真区间 0–20 s，指定输出间隔 0.0005 s。状态和学习权重共同进入 `ode23`。

主脚本在一个局部 `func_ode` 内同时执行：参考生成、真实模型与估计模型、基函数、饱和策略、系统积分、Stackelberg 辅助项、两种阶段代价、Bellman 残差、固定时间幂次学习律、历史梯度缓存和日志。固定时间变换是 `sig(z,0.8)+sig(z,1.2)`。默认基函数是 6 项二维多项式，StaF 与其他基函数是手动注释切换；不是通用算法注册/配置接口。

源代码地图（全部固定到同一 commit）：

| 责任 | 位置 | 对新规范的意义 |
|---|---|---|
| 配置/初始化 | [main:9–72](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L9-L72) | 提取为显式 experiment config，并记录每个符号的维度与单位 |
| 组装、积分、保存 | [main:74–98](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L74-L98) | 独立 runner、状态布局、solver config、result schema |
| 模型及输入通道 | [main:132–146](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L132-L146)、[func_fx:1–6](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Utilization/func_fx.m#L1-L6) | 分开 true plant、available observation、identified model |
| 基函数与策略 | [main:148–179](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L148-L179) | basis.value/basis.jacobian 与 policy 不互相藏参数 |
| Stackelberg 辅助动力学 | [main:186–208](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L186-L208) | 独立 game formulation；不可混入所有 ADP 算法核心 |
| 代价、残差、学习律 | [main:210–261](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L210-L261) | cost、Bellman operator、update law、history stack 分离 |

## 3. 必须阻断直接迁为“规范”的问题

P1 表示会影响科学含义或数据正确性；P2 表示可复现/可扩展问题。本次全部为静态结论；标注“待论文核对”的项不能当成已判定的论文错误。

| 严重性、位置 | 已确认事实与影响 | 修改方案及可执行门槛 |
|---|---|---|
| P1 [func_phi_6NN:4–5](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Utilization/func_phi_6NN.m#L4-L5) | 第 6 项为 `x1^2*x2^2`，给定对 x2 导数却是 `x1^2*x2`，缺少系数 2。直接影响策略、残差和权重动力学。8NN 同样问题。 | 冻结原版；新版本改为 `2*x1^2*x2`；先用独立有限差分验证整个 Jacobian，再比较修正前后轨迹。不能保留旧图却声称来自修正模型。 |
| P1 [main:242](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L242)、[plot:368–380](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/plot_fig_FxT_CL_ADP.m#L368-L380) | `Bellman` 保存的是 r1/r2 阶段代价，绘图却标 Bellman error；真正残差是 main:225–226 的 delta1/delta2。 | result schema 分开 `stageCost`、`bellmanResidual`、`integratedCost`，图从语义字段取值；回放独立重算 residual 并与记录比较。 |
| P1 [main:63–67](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L63-L67)、[251–261](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L251-L261) | 默认 N=1，缓存覆盖后立即求和，因此 critic/actor 更新退化为 10 倍当前梯度；没有多样历史样本提供额外信息。缓存的是旧梯度而非显式数据/回归器，没见 rank/最小奇异值诊断。 | 不先把它命名为已验证 CL 模块。按论文确定原始样本、残差重评估和采样规则，记录 Gramian 最小特征值、秩、条件数、样本年龄和接受理由；N=1 与 N>1 做区分。 |
| P1/P2 [main:80](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L80)、[181–182](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L181-L182)、[251–256](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L251-L256) | ODE 回调中增长 U/V/Bellman 并更新全局缓存。日志对应 RHS 求值点，不能保证等同于接受步/输出网格；N>1 时旧梯度与求解器试探/拒绝步耦合。默认 N=1 的缓存退化使该历史问题不改变默认梯度历史，但日志问题仍在。`T` 是输出网格间隔，不是 ode23 固定内部步长。 | continuous RHS 必须无副作用；采样/缓存插入在明确的控制学习时钟执行，或将真实连续内部状态纳入增广状态；统一在结果网格重算可观测量；测试同一 `(t,state)` 两次 RHS 相同。 |
| P1 [main:139–141](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L139-L141)、[227、249](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L225-L249) | 标作 model-free 的默认分支，其识别误差 delta3 直接使用真实 f−估计 f。源码没有观测导数/滤波器/积分数据接口来提供该量。 | 明确 `oracleDerivative` 的模拟假设；实用路径必须由 x、实际施加的 u/v、导数估计或积分回归构造。可做“隐藏真实参数”接口测试，防止 controller 读到 plant 真值。 |
| P1 待论文核对 [main:132–144](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L132-L144)、[func_fx:6](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Utilization/func_fx.m#L6) | model=1 分支第二分量含 `x2*(1-cos(2*x1+1)^2)`；model=0 真模型含 `x2*(cos(2*x1)+2)`。切换 model 标志同时改了被控对象，不能直接当作“相同对象上 model-based vs identified model”对照。 | plant 固定、observer 策略单独切换；若确为两个 benchmark，分别给 ID 与参数。 |
| P1 待论文核对 [main:21–22、126–127](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L126-L127)、[func_reference:5–6](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Utilization/func_reference.m#L5-L6) | 初值来自正弦参考函数，但动态里使用 `dxref=[-1 1;-2 1]*xref`，不是该函数的时变导数。此代码真正跟踪的是该自治线性参考的轨迹。 | reference 必须统一 value/derivative 或明示 autonomous exosystem；配置不得把另一参考名称沿用到结果。 |
| P1 待论文核对 [main:165–167、203–208、218–225](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L165-L225) | 策略使用 tanh，阶段代价仍为二次型；辅助 `dv_dV2=-0.5/gamma^2*k'` 未显式含 tanh 导数，du1/du2 设零，dg2 设零而 g(2,2) 随 x1 变化。不能据代码命名确认与某套饱和/Stackelberg 理论一致。 | 把策略、代价、Hamiltonian 的相容性设为论文迁移专门门槛；按具体推导检查一阶条件、符号、Jacobian、输入约束模型。此处未阅读论文推导，保留待确认。 |
| P2 [main:110、254](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L110) | `dW_a2_` 在脚本是 global，但局部 RHS 的 global 列表漏了它；N>1 时该缓存不按其他缓存持久化。 | 所有 learner state 显式传入/返回；每个缓存统一结构，维度由注册布局计算。 |
| P2 [plot:255–257](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/plot_fig_FxT_CL_ADP.m#L255-L257) | U 本来就是逐行存储的 `[u',t]`，`reshape(U(:,1:len_x),2,length(t_))'` 按 MATLAB 列序重新排列，通常会混淆时间/通道。还把 len_x 当 len_u。 | 直接 `u_=U(:,1:len_u)`；用各通道值不同、各时刻值不同的小矩阵验证日志到绘图不会换位。 |
| P2 [main:5–8、98](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/main_FxT_CL_ADP.m#L5-L8)、[plot:2–7、22、132](https://github.com/tanjunkai2001/FxT-CL-ACI/blob/e6fd86390f6895a588390c01957a3e4393ffe432/Simulation/plot_fig_FxT_CL_ADP.m#L2-L7) | 相对路径与 `cd` 依赖调用目录；仿真改变到 repo 根，绘图又假设从 Simulation 出发。tree 没有 Figures 目录，但绘图即使 savefig_flag=0 也执行 cd(path_fig)。另有未包含的 `../ZoomPlot-MATLAB`（实际调用受保存标志控制），`utilization` 大小写不符；save 覆盖固定 MAT 并保存整个工作区。 | root 由入口文件定位；函数式 `run(config)`、`plot(result,opts)`；自动建立唯一 run 文件夹；保存精确字段与 MATLAB 版本/commit/配置/solver/provenance；可选绘图依赖显式检查。 |

关于 ODE 输出网格的判断已核对 [MathWorks ode23 文档](https://www.mathworks.com/help/matlab/ref/ode23.html)：多点 tspan 指定输出点，内部积分仍采用自身步点。

其他扩展注意点：状态切片多次手写并隐含 len_W1=len_W2，绘图固定 6 个基函数、2 个状态；没有 manifest 写出 MATLAB release/工具箱要求；默认初始化是确定的 ones，只有被注释的 rand，因此不能把“无 rng(seed)”当作当前默认路径随机不复现的证据。`RK1.m` 内首函数名为 `Simul_Dyn`，应在迁移中统一文件与函数名；固定步 RK4 也不能解决 RHS 内历史更新发生于 4 个 stage 的语义问题。

## 4. 可抽取模块与优先级

1. **先建立基础契约（P0 迁移工作）**：`Plant`（f/g/k、尺寸、参数）、`Observation`（可得测量及实际输入）、`Reference`、`Basis`（phi/Jacobian/Hessian 是否可用）、`Cost`、`Policy`、`LearnerState`、`RunResult`。保留 legacy 快照；与修正版基准分开。
2. **先落地可证明的小基准（P0）**：LQR/CARE 解析对照、线性已知值函数、二维多项式基函数导数检查、固定策略 Bellman 残差检查、积分器阶数/网格收敛、日志通道保持。将这些作为 MATLAB ADP 核心的可执行规范。
3. **再迁移本仓库实验（P1）**：先完成 fixed-time 变换、参数化 identifier、两 actor/two critic 更新、饱和策略、明确的历史样本接口；至少建立 `legacy_snapshot` 与 `corrected_basis_and_logging` 两个变体。历史算法和论文 Hamiltonian 不一致处先写 issue，再决定修正后的理论版本。
4. **扩展模块（P2）**：StaF、积分强化学习、并发学习/经验回放、H∞/非零和/Stackelberg、PPC/CBF、约束优化、机器人/Simulink 适配。核心模块不默认假设这些都启用。
5. **配套 skills（工作协议）**：`adp-new-experiment`（符号/尺寸/信息模式/基准）、`adp-paper-reproduction`（论文—公式—实现—图表清单）、`adp-basis-audit`（独立导数）、`adp-learning-audit`（残差、数据来源、excitation、history、固定时间条件）、`adp-run-and-report`（环境、结果、失败记录）、`adp-safe-control-extension`（nominal/requested/received/applied 输入、CBF/PPC 可行性及 solver 语义）。Skill 应要求证据文件，不能仅靠散文规范；默认阻止把缓存图认作新仿真。

建议验收层级独立标示：`source_audited`、`implementation_verified`、`numerically_reproduced`、`paper_claim_checked`、`hardware_validated`。本仓库目前仅完成此次有限范围的 `source_audited`，未进入其余层级。
