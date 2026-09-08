# Infinite-horizon HJB PINN

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/pinn_infinite_horizon2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Filippos Fotiadis, Kyriakos G. Vamvoudakis. [A Physics-Informed Learning Framework to Solve the Infinite-Horizon Optimal Control Problem](https://doi.org/10.1002/rnc.70028). IJRNC 2025.

**Implemented scope:** Reduced LQR/pendulum training; corrected quartic cost identified. Reduced scalar-LQR/pendulum training history retained; five independent equation/derivative/terminal tests, including two single-update replays.

## Run from the repository root

```matlab
demo_reproductions('pinn_infinite_horizon2025','smoke');
```

This short workflow trains scalar LQR for 10 updates and the pendulum for 10 updates at each of two horizons. It also runs two independent 12-update prefix replays. It does not produce the horizon-4 experiment shown on the project page.

To run the reduced configuration used for that figure:

```matlab
[result,runDir] = demo_reproductions('pinn_infinite_horizon2025','reduced');
```

This trains scalar LQR for 2,000 updates, then the pendulum at horizons 1, 2, 3 and 4 for 3,000 updates each, followed by the same prefix checks. The pendulum network has three hidden layers of width 48. The saved [September 7 summary](../../evidence/v0.3/pinn/reduced_20260907_110031_520/summary.json) and the project figure belong to this reduced-scale experiment; the full paper training schedule is not a reproduced result. Each call creates a new directory containing its configuration, networks, loss histories and evaluations.

Required products: MATLAB, Deep Learning Toolbox. The native entry is `run_pinn_reproduction`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Validation and results

The current suite records **5 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/pinn_infinite_horizon2025.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
