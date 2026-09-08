# Bias-policy iteration

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/bias_pi_automatica2026.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Ruiqing Zhang, Huaiyuan Jiang, Bin Zhou. [Adaptive dynamic programming for unknown continuous-time nonlinear systems via bias-policy iteration](https://doi.org/10.1016/j.automatica.2026.112821). Automatica 2026.

**Implemented scope:** Pendulum/arm variants; arm cost is 8.84% above local LQR. Eq43/48 fixed-data Bias-PI; pendulum and arm local-multistart variants, not exact paper 54/45 iterations

## Run from the repository root

```matlab
demo_reproductions('bias_pi_automatica2026');
```

This entry performs the method’s numerical experiment and saves a new run.

Required products: MATLAB; Control System Toolbox is needed for the arm example's LQR comparison. The native entry is `demo_bias_pi`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **12 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/bias_pi_automatica2026.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
