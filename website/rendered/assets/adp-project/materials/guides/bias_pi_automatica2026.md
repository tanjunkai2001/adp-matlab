# Bias-policy iteration

[中文说明](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/bias_pi_automatica2026/README.zh-CN.md) · [Equation and full-text notes](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/bias_pi_automatica2026.md) · [All APIs](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/IMPLEMENTED_API.md)

**Source:** Ruiqing Zhang, Huaiyuan Jiang, Bin Zhou. [Adaptive dynamic programming for unknown continuous-time nonlinear systems via bias-policy iteration](https://doi.org/10.1016/j.automatica.2026.112821). Automatica 2026.

**Implemented scope:** Pendulum/arm variants; arm cost is 8.84% above local LQR. Eq43/48 fixed-data Bias-PI; pendulum and arm local-multistart variants, not exact paper 54/45 iterations

## Run from the repository root

The default entry runs the pendulum with local multistart data and discounted bootstrap:

```matlab
[result,runDir] = demo_reproductions('bias_pi_automatica2026');
```

The reported **468.490 versus 430.435** costs belong to the two-joint arm over **5 seconds**. Select that example explicitly:

```matlab
[result,runDir] = demo_reproductions('bias_pi_automatica2026',[],struct('example','arm'));
```

Each command creates a separate run under `runs/` and returns its directory. The [result and configuration table](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/bias_pi_automatica2026/RESULTS.md) separates these defaults from the earlier arm run that stopped after 0.07435 seconds; its partial cost is not a 5-second comparison.

Required products: MATLAB; Control System Toolbox is needed for the arm example's LQR comparison. The native entry is `demo_bias_pi`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **12 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/bias_pi_automatica2026/README.zh-CN.md) and [paper card](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/bias_pi_automatica2026.md). Larger historical data belong to the [artifact collection](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
