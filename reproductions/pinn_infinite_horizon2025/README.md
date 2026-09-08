# Infinite-horizon HJB PINN

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/pinn_infinite_horizon2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Filippos Fotiadis, Kyriakos G. Vamvoudakis. [A Physics-Informed Learning Framework to Solve the Infinite-Horizon Optimal Control Problem](https://doi.org/10.1002/rnc.70028). IJRNC 2025.

**Implemented scope:** Reduced LQR/pendulum training; corrected quartic cost identified. Reduced scalar-LQR/pendulum training history retained; five independent equation/derivative/terminal tests, including two single-update replays.

## Run from the repository root

```matlab
demo_reproductions('pinn_infinite_horizon2025','smoke');
```

This entry performs actual neural training. Check the native configuration and training budget before running it.

Required products: MATLAB, Deep Learning Toolbox. The native entry is `run_pinn_reproduction`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **5 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/pinn_infinite_horizon2025.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
