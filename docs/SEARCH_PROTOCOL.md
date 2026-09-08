# 查新范围与访问记录

检索/阅读日期：2026-09-07；主要窗口2023-01-01至2026-09-07，另补2019年有限样本LSPI基础论文。目的为MATLAB ADP研究仓库补漏，属于多源定向方法调研，不是有穷尽保证的系统综述。

## 来源与过程

使用 nature-academic-search 的主源检索、全文核对、版本去重流程。专用学术检索MCP未挂载，本轮通过web、arXiv、出版社/会议论文页、作者代码页及Crossref元数据交叉查询。原Google Scholar页面访问受限，未把本轮结果称为用户全部论文列表。

先从三组原代码的算法谱系建立类别，再检索新方法和引用线索；只有取得PDF并实际阅读所列方法/假设/定理的条目计入全文阅读。先按DOI，再按arXiv工作ID、标题/作者去重。作者稿与正式刊会作为同一工作保存，但保留所读版本；未逐字比对作者稿和最终版的项目明确注明。

主要检索组（保留主题与代表查询，可重新执行；不是搜索引擎全部命中结果的历史快照）：

| 组 | 代表查询 | 核对来源 |
|---|---|---|
| 总体查新 | adaptive dynamic programming 2025 2026 survey continuous time integral policy iteration | 出版社、arXiv、Crossref |
| 初始化 | stabilizing policy iteration damping homotopy 2024 2025；stochastic stabilizer spectrum assignment 2026 | 作者PDF、arXiv版本页 |
| 学习结构/观测 | critic-free policy iteration 2026；output feedback Q learning；continuous time output policy value iteration | PMLR、arXiv |
| 数值与有限数据 | integral reinforcement learning computation quadrature；finite-time approximate PI LQR；noisy identification policy iteration | ICLR/OpenReview、NeurIPS、作者稿、DOI |
| 随机与风险 | stochastic policy value iteration 2025 2026；ergodic risk policy optimization；continuous time distributional advantage | arXiv、NeurIPS、正式DOI |
| 安全与批数据 | safe adaptive dynamic programming 2024 2025；distributionally robust Lyapunov certificate；direct data driven discounted LQR | 作者稿、OJCSYS、代码仓库 |
| 多体 | mean field LQG social optimization reinforcement learning；cooperative competitive mean field independent RL | Automatica、arXiv |
| 表示/PDE | Koopman policy iteration 2025；physics informed HJB finite infinite horizon；safe optimal control PINN 2025 | PMLR、Wiley、arXiv |
| 最近月份补查 | site:arxiv.org adaptive dynamic programming Sep 2026；policy iteration Aug 2026；ADP output regulation integral 2026 | arXiv、Automatica出版社及Crossref |
| 扩展筛查 | multi-step optimistic adaptive dynamic programming 2025；ADP model predictive terminal value 2025 | JFI、NLD、出版社摘要/索引 |

逐篇已读范围、PDF SHA-256和元数据来源由 registry/papers.json 及 docs/literature/*.json 记录；不是每篇都做了完整证明审计或代码审计。

## 未进入全文已读计数的线索

| 线索 | 来源/状态 | 未计入原因 |
|---|---|---|
| Lin–Huang CT IRL overview，2026-08 | [10.1016/j.jai.2026.08.004](https://doi.org/10.1016/j.jai.2026.08.004) | 出版社索引/元数据可得，直接正文请求失败；不据摘要声称已读 |
| 约束ADP综述，2026 | [10.1080/21642583.2026.2671530](https://doi.org/10.1080/21642583.2026.2671530) | 仅发现线索，未完整阅读 |
| 多智能体optimistic PI，2025 | [10.1016/j.jfranklin.2025.107764](https://doi.org/10.1016/j.jfranklin.2025.107764) | 仅出版社摘要；GPI/部分评估作为结构接口，未吸收具体定理 |
| 多步off-policy安全/扰动ADP，2025 | [10.1007/s11071-025-11329-3](https://doi.org/10.1007/s11071-025-11329-3) | 仅摘要筛查，未复现算法 |
| Identification in data-driven PI，2024 | [arXiv2401.06721](https://arxiv.org/abs/2401.06721) | 下载但未定向读正文，不计数 |
| Physics-informed CT RL，JMLR2024 | [JMLR25(400)](https://jmlr.org/papers/v25/24-0017.html) | PDF取得但未读正文；不与EIRL混为一篇 |

## 还不能声称覆盖的范围

没有对所有收费全文、刚上线未被索引的论文、非英文工作、全部期刊卷期或每个作者仓库进行穷尽扫描。MPC/rollout、输出调节/内模、混杂/切换、时滞系统、部分观测belief/POMDP、非二次输入成本、特殊机器人执行约束仍需结合具体论文继续深化。原设计已有的一些标签不因此自动达到复现标准。

这轮已足以识别影响框架结构的主要新增维度。后续查新应复用 method-intake 模板，优先处理会改变数据、算子或证书的新方法；仅改变应用对象或名称的工作无需独立造一个模块。


## 最后一次按月份补查

2026年8月18日的随机微分博弈顺序PI已取得全文并纳入计数；非线性Bias-PI（Automatica185:112821，2026）在早期v0.2检索中仅有预览；v0.4已通过PolyU认证取得正式版13页PDF，完成全文卡、两算例实现与实际测试，见 [当前记录](fulltext/bias_pi_automatica2026.md)。早期403/401记录继续作为访问历史。

本次最终合计24篇近期工作和1篇2019年基础论文的实质全文段落阅读。额外筛到的[adjoint portfolio PI](https://arxiv.org/abs/2608.17808)、[时间不一致MDP](https://arxiv.org/abs/2608.20811)及[MPC终端价值](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=7233158)仅作为边界线索，未阅读全文、未计数、未迁入算法。值梯度/DHP/GDHP、adjoint/costate、PDE被控对象（不同于HJB求解器）的详细分类仍需专项补读，不把它们视作已实现的普通critic。
