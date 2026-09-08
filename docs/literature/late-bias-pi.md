# 非线性 CT Bias-PI：打包前单篇补查

**历史记录：**以下为v0.2的访问失败与待办状态。v0.4已取得正式全文并实现两个算例，当前状态见 [全文卡](../fulltext/bias_pi_automatica2026.md)。

v0.3补充：用户指定PolyU图书馆，已核对[官方ScienceDirect资源入口](https://www.lib.polyu.edu.hk/node/2002)，并在Edge打开学校Login Service。当前等待用户本人完成学校认证，尚未取得正文，也未根据摘要编造算法。下面保留v0.2的公开路径检索记录。

**结论：这是应保留的近期核心方法线索；完整正文未取得，不能计入已读全文。** 建议状态 `discovered_pending_fulltext`，不据此新增数值实现或宣称其初始化条件已核。

Ruiqing Zhang, Huaiyuan Jiang, Bin Zhou，*Adaptive dynamic programming for unknown continuous-time nonlinear systems via bias-policy iteration*，**Automatica 185 (March 2026), 112821**，[DOI](https://doi.org/10.1016/j.automatica.2026.112821)。作者、卷号、文章号和月份由出版社与 Crossref 交叉核对。Elsevier 的 `2026-03-31` 是 coverDate；首次在线发表日未核得。

## 实际读到哪里

已阅读[出版社预览](https://www.sciencedirect.com/science/article/pii/S0005109826000051)在搜索索引中可见的 **Abstract、Introduction 和论文组织说明**。未取得 §II 问题设定、§III 具体算法/回归/收敛证明、§IV 仿真或附录。**没有已核的公式、算法或定理编号**。

预览能支持的范围：该文处理未知连续时间非线性系统，用 bias value function 放宽初始可容许控制要求，并介绍模型型及数据型方法。引言提到指数折扣性能指标，并说明受早期线性 Bias-PI 中 Fréchet 导数加偏置思路启发。摘要中的有界性、收敛和效率结论属于作者报告，本轮没有核对其条件和证明。

## 对当前设计的影响

现有初始化/评价算子框架能容纳这个方向，但 DT damping、一般 nonlinear PI 标签尚未明确记录这一**非线性 CT 偏置值函数与初始化机制**。可增加待全文核对的 `ct-nonlinear-bias-pi` 线索；先复用现有初始化、目标与评价模块，不新增空的算法实现。

接入前需取得：偏置值函数定义；目标成本与辅助折扣/偏置的关系；初始策略放宽后的条件和域；偏置参数更新、算子可逆及停止条件；数据回归、已知模型量、激励与误差前提。在这些信息缺失时，不推断其等同于 DT damping，也不将它的 bias 与平均成本模型的相对值函数 bias 混为一项。这里是架构补漏判断，**不是已核出的新方程接口**。

历史关联仅作导航：Huaiyuan Jiang, Bin Zhou，*Bias-policy iteration based adaptive dynamic programming for unknown continuous-time linear systems*，Automatica 136:110058 (2022)，[DOI](https://doi.org/10.1016/j.automatica.2021.110058)。书目已核，2026 引言有明确关联；本轮未补读该文。

## 有界获取记录与停止理由

- 出版社 HTML/PDF 直接请求失败；PDF 返回 403。
- Elsevier FULL 接口返回 401；默认 XML 只有 1844 字节 coredata，明确非 OA，不是全文。
- 精确题名/主题的 arXiv 搜索未发现可核稿；export API 单次请求超时，不据此断言没有预印本。
- [HIT 作者主页](https://homepage.hit.edu.cn/binzhou)已打开，本次可见内容没有该文 PDF。未向作者发信、请求全文或使用付费权限。
- 辅助 OA 链接检索单次返回 429 后未重试。本轮在出版社、预印本与作者三条公开路径完成有界尝试后停止。

代码链接尚未核得，未获取或运行源码。未改已交付 core 数据和 outputs。结构化记录及元数据哈希见 `late-bias-pi.json`；完整 PDF 哈希为 null，防止把元数据文件冒充正文。
