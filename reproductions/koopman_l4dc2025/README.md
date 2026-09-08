# Koopman generator + PI

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/koopman_l4dc2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Zhexuan Zeng, Ruikun Zhou, Yiming Meng, Jun Liu. [Data-driven optimal control of unknown nonlinear dynamical systems using the Koopman operator](https://proceedings.mlr.press/v283/zeng25a.html). L4DC 2025.

**Implemented scope:** Normalized pendulum variant; not every paper table. Yosida generator identification and PI; explicit numerical variant, not all original tables

## Run from the repository root

```matlab
demo_reproductions('koopman_l4dc2025');
```

This entry performs the method’s numerical experiment and saves a new run.

Required products: MATLAB. The native entry is `demo_koopman`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **8 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/koopman_l4dc2025.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
