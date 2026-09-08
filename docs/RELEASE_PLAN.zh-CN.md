# ADP-MATLAB 发布与维护

首个公开版本为 **v0.5.0**。仓库地址为 `tanjunkai2001/adp-matlab`，项目主页位于 `/projects/adp-matlab/`。源码发布状态以 `registry/project.json` 为准，测试结果以 `docs/validation/` 和 GitHub Actions 为准。

## 首版范围

| 内容 | 交付范围 |
|---|---|
| MATLAB 实现 | 81 个现有源文件、积分 PI 基线、7 个论文方法包 |
| 入门与扩展 | 双语 README、依赖表、原生调用、方程映射、贡献模板、6 个可选研究 skills |
| 验证 | 102 项本地测试、逐项结果、源文件 SHA-256、新运行的基线指标 |
| 实验资料 | 各方法的紧凑记录和负结果、两个可编辑图包与绘图数据 |
| 许可 | 独立编写代码和项目文档采用 MIT；第三方论文、源码和作者权重各自保留原条款 |
| 网站 | 保留个人主页的一处入口；项目页的代码、下载和文档链接由同一登记表生成 |

算法源码与 v0.4.1 保持一致。本次整理修正分发和使用说明，不新增算法，也不把已运行的数值变体升级为原论文完整复现。完整历史研究包保留在原版本中，未直接并入公开仓库。

## 发布步骤

1. 运行 `python3 tools/check_repository.py --source-only` 和 `python3 tools/build_project_docs.py --check`。
2. 在 MATLAB 中运行 `run_all_tests`，并独立运行 README 的 baseline；保存当前测试表与源哈希。
3. 从实际 Git 文件制作干净源码包，在解压副本检查入口和资料，避免本地未追踪文件掩盖遗漏。
4. 建立公开仓库并推送。检查真实 GitHub Actions 结果，保留失败日志；不以本地通过代替云端通过。
5. 给最终提交建立 `v0.5.0` 标签，核验公开 ZIP；用生成的个人网站项目文件接通 Code / Download 入口。

## 日常维护

- 方法、入口和工具箱依赖：`registry/reproductions.json`。
- 人可读名称、实验摘要：`registry/method-display.json`。
- 项目版本、链接、许可证和发布状态：`registry/project.json`。
- 本地测试与源码身份：`docs/validation/`；旧记录保留为历史，新增运行放 `runs/`。
- 更新 README 表格和项目页：`python3 tools/build_project_docs.py`。
- 导出个人网站新增文件：`python3 tools/build_project_docs.py --personal-site-dir /path/to/overlay`；复核后只同步项目专属文件。

CI 使用 MathWorks 官方 MATLAB Actions、R2025b Update 6 和所需的两个工具箱。公开项目的许可方式见 [Setup MATLAB 官方说明](https://github.com/matlab-actions/setup-matlab#licensing)。工作流只运行本地测试，不启动完整 PINN 训练。上传日志用于定位失败，不通过跳过失败来制造绿色状态。

首批扩展继续按 [ROADMAP](ROADMAP.md) 推进：FxT-CL-ACI 迁移、约束执行示例、一个离线 MATLAB/Simulink 机器人例子。当前没有软件 DOI，后续取得后再更新 CITATION.cff。
