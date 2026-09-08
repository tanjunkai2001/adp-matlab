# Mean-field LQG

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/meanfield_lqg2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Zhenhui Xu, Bing-Chang Wang, Tielong Shen. [Mean field LQG social optimization: A reinforcement learning approach](https://doi.org/10.1016/j.automatica.2024.111924). Automatica 2025.

**Implemented scope:** Finite-sample social optimization; low-sample failures retained. n=2,m=1 independent Ito paths; two gains, MC mean, finite-N costs; 100-path failures retained

## Run from the repository root

```matlab
demo_reproductions('meanfield_lqg2025');
```

This entry performs the method’s numerical experiment and saves a new run.

Required products: MATLAB. The native entry is `demo_meanfield_lqg2025`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **7 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/meanfield_lqg2025.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
