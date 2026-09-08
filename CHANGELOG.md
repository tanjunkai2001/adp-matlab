# v0.5.2 — retain rejected Safe PINN evaluations, 2026-09-08

- Save the completed Safe PINN network, history, fixed inputs, trajectories and metrics before applying the existing heldout/terminal assertions. Print the saved directory before a rejection.
- Added a real zero-update demo regression; all 104 local tests passed. A one-update success comparison preserved network parameters and numerical results, excluding timing.
- Corrected the test-runner description: the suite now includes zero-update Safe PINN evaluation, while full training remains separate.
- Preserved v0.5.1 validation/source records and bound the mean-field comparison to its original source identity. Network formulas, default settings, acceptance criteria and historical experiments are unchanged.

# v0.5.1 — mean-field failure-data preservation, 2026-09-08

- Save the primary mean-field configuration and raw observations after collection, and its statistics before fitting. Append the learned result on success.
- Record primary-fit failures in `failure.json` and rethrow the original exception; its saved inputs can be replayed without collecting new data.
- Added one deterministic failure/replay regression. All 103 local MATLAB tests passed; a reduced success comparison matched all saved numerical results except elapsed time.
- Preserved the v0.5.0 tag, test/source records, learner formulas, default settings and historical experiments.
- Included the preceding baseline note and experiment-command documentation improvements.

# v0.5.0 — first public source release, 2026-09-08

- Added the MIT license, consistent release metadata and a reproducible source package.
- Re-ran all 102 local MATLAB tests and the baseline quickstart; the 81 MATLAB sources remain byte-identical to v0.4.1.
- Passed all 102 tests and repository checks on GitHub Actions with MATLAB R2025b Update 6 on Ubuntu 24.04.
- Repaired external-checkpoint instructions, archived evidence links and the links inside downloadable project notes.
- Included the two project-generated figure bundles in Git; preserved their original data and checksums.
- Added complete CI failure logs and connected release-aware code/download links to the independent project page.

# v0.5.0-dev — public-project preparation, 2026-09-07

- Added English/Chinese GitHub READMEs, registry-generated method tables, contribution and issue templates, citation metadata and a first CI workflow.
- Added an independent project-page design, an additive Jekyll integration package and a real MATLAB baseline figure with CSV data.
- Re-ran all 102 local tests from the prepared source directory. The 81 MATLAB files remain byte-identical to v0.4.1.
- Kept large numerical archives outside the Git checkout; removed local retrieval paths from the distributable provenance copies.
- Repository publication, first GitHub Actions run and the maintainer’s license choice are pending.

# v0.4.1 — 仓库检查与整理，2026-09-07

- 方法/依赖登记统一由registry驱动；新增只读环境检查。演示原生参数保持可用。
- 补充3项仓库入口检查和5项PINN数学/终端测试；保留原94项和历史神经训练。
- 修复PINN无效模式误进入长训练的问题；PINN、平均场和两个Koopman的新输出改入runs，保留原evidence/results。
- 统一当前文档与七个方法README，列清公共模块/算法缺口；同时提供轻量源码包和完整证据包。
- 保留v0.4目录与ZIP，未改科研算法、已有论文数值或公开发布状态。

# v0.4.0 — 2026-09-07

- 通过用户已认证的 PolyU 访问取得 Bias-PI Automatica 2026 正式版13页全文；原PDF独立于代码包保存。
- 新增真实数据驱动偏置外层、折扣内层/初始化、两例模型与数据采集、积分回归和闭环评估。按正文推导更正原文公式引用与最小二乘维数。
- 摆与机械臂局部多初值变体已运行；保留单初值采样失败、机械臂性能未优于LQR以及论文权重/迭代数不匹配。
- 新增11项独立方程/采样测试与1项机械臂功率恒等式测试；统一入口现有8项，包括原创基线与7篇方法。实际统一结果见VALIDATION。
- 六个仓库skills继续使用原简洁结构；没有新增框架或类层。原v0.3目录、ZIP和运行保持不动。

# v0.3.0 — 2026-09-07

保留 v0.2 的原创 CT 积分 PI、43 项测试及历史证据。在新目录增加六篇方法的独立 MATLAB 实现，不改写上游仓库，也不把计划模块统称为已实现。

- 已完成实际运行的主要新增方法：Koopman 生成元辨识/PI、平均场随机两增益 PI、TAC 离线矩阵 Q-learning、有限时域 HJB 神经 PINN 的时域延长。
- 安全 epigraph PINN 的简化训练已执行并保留安全验收失败；作者 checkpoint 已载入并核对值/梯度，独立条件校准仍有违例。鲁棒 Koopman 已实际运行、8项测试通过，留出误差界不成立和成本未优于 nominal 的负结果明确保留。
- 每篇新增完整阅读卡、公式到函数的映射、实际计算规模与原文差异。特别记录平均场的两种矩、Table 2 条件参考、Q-learning 完整矩阵等式、PINN 的终端传递与原四次代价差异。
- 新增轻量 demo_reproductions 和 run_all_tests；前者不带参数只列目录，后者不调用神经训练入口。共享库和复现包维持不同的原生接口，不新增框架/类。
- 统一入口已实际完成82/82局部测试，未重训PINN；各方法历史训练和负结果另外保留，最终交付字节身份另核对。旧 reference-run 继续绑定 v0.2 的旧源码集合。

# v0.2.0 — 2026-09-07

保留v0.1全部文件及原发布包；v0.2在新目录开发。

## 实现修正

- 加强on-policy数据入口：目标/行为策略、记录输入、轨迹端点与回归数据需一致。
- 完善小尺度数值一致性检查，并绑定采集时的二次成本和已知输入矩阵，拒绝参数串线。
- 记录ODE增广成本的积分来源、求积方式及尚无经证明误差上界的事实。
- 完善结果清单格式、必需文件、大小、路径与源码清单检查。清单未签名，验证不构成来源认证。
- 扩展数学/错误分支/持久化与数值敏感性回归测试。最终实际数量、运行日志和残留静态提示以VALIDATION.md为准。

## 调研与规范

取得并定向阅读24篇近期论文全文和1篇历史基础论文，保存版本、hash、实际阅读范围、假设、代码状态和适用限制。

新增方法契约、接入模板、能力登记、逐篇文献索引及六个skills的扩展检查。重点补入稳定初始化、actor-only、CT/DT输出提升、Itô/CTMC、平均成本、数据复用、数值积分误差、模型/证书分离；Koopman、PINN、平均场与分布风险作为可选扩展。

只有CT确定性线性二次on-policy积分PI具有本仓库实现和数值验证。其余新增条目为planned。第三方源码的静态扫描与论文算法的完整仿真复现分别报告。
