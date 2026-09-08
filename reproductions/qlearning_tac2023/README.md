# Off-policy Q-learning

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/qlearning_tac2023.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Victor G. Lopez, Mohammad Alsalti, Matthias A. Müller. [Efficient Off-Policy Q-Learning for Data-Based Discrete-Time LQR Problems](https://doi.org/10.1109/TAC.2023.3235967). IEEE TAC 2023.

**Implemented scope:** Data-based LQR; explicit MIMO initialization variant. Matrix Bellman equation Algorithm 1; SISO deadbeat and explicit MIMO pole-placement variant

## Run from the repository root

```matlab
demo_reproductions('qlearning_tac2023');
```

This entry performs the method’s numerical experiment and saves a new run.

Required products: MATLAB, Control System Toolbox. The native entry is `demo_qlearning_tac2023`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **7 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/qlearning_tac2023.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
