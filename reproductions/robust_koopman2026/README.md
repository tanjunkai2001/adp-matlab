# Robust Koopman PI

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/robust_koopman2026.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Yicheng Lin, Bingxian Wu, Nan Bai, Yunxiao Ren, Zhongkui Li, Zhisheng Duan. [Optimality Robustness in Koopman-Based Control](https://arxiv.org/abs/2604.05633). Preprint 2026.

**Implemented scope:** Held-out error bound fails on 25.55% of points. Explicit excitation/basis variant; branch-complete policy, sample-fit error bounds invalid on 25.55% of heldout points; nominal cost slightly better

## Run from the repository root

```matlab
demo_reproductions('robust_koopman2026');
```

This entry performs the method’s numerical experiment and saves a new run.

Required products: MATLAB. The native entry is `demo_robust_koopman`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **8 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/robust_koopman2026.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
