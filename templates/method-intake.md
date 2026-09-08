# 新方法接入记录

- 文献标题、DOI/arXiv版本、正式发表/预印本、检索日期：
- 所读全文URL/hash、实际阅读章节、未核对证明：
- 上游代码URL、commit、语言、许可和已运行场景：
- 与已有方法的关系：新算子 / 新学习结构 / 新初始化 / 数值改进 / 场景组合：
- 系统类型（ODE/Itô/CTMC/DT/hybrid）和可观测量：
- 成本/回报符号、折扣/平均/有限时域、终端条件：
- 学习对象（V/Q/q/actor/model/distribution）及评估算子：
- 已知模型量、初始策略/数据条件、稳定性概念和有效域：
- 数据生成、on/off-policy、实际输入与目标策略的关系：
- 跨迭代数据复用（fresh_batch/fixed_batch/replay）、样本依赖/独立性及与定理的对应：
- 特征/梯度/Hessian、积分/统计/辨识误差、数值解法：
- 论文保证成立的条件；论文未保证但容易被误读的内容：
- 复用的公共模块、确需新增的接口、可选依赖：
- 最小解析/独立对照算例、反例、容差、失败标准：
- 当前状态：discovered / fulltext_reviewed / implemented / numerically_validated / paper_reproduced：
- 实现入口和证据（没有则写未实现）：

接入前阅读 docs/METHOD_CONTRACTS.zh-CN.md。文献发表与代码验证分开；全文可读与证明已审计分开。
