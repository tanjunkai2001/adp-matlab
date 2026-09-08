# Safe epigraph PINN

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/safe_pinn_icml2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Manan Tayal, Aditya Singh, Shishir Kolathaya, Somil Bansal. [A Physics-Informed Machine Learning Framework for Safe and Optimal Control of Autonomous Systems](https://proceedings.mlr.press/v267/tayal25a.html). ICML 2025.

**Implemented scope:** Boat example; collision and budget violations remain. Reduced training and author checkpoint both evaluated; finite-rollout safety/budget violations retained; conditional numerical calibration bounds only

## Run from the repository root

```matlab
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
[result,runDir] = demo_reproductions('safe_pinn_icml2025',outputRoot,5000);
S = load(fullfile(runDir,'result.mat'),'result');
S.result.metrics
```

This runs 5,000 neural-training updates and saves a new directory under `outputRoot`. The saved `result.mat` contains the trained network, fixed evaluation inputs, trajectories and metrics. No historical result or author checkpoint is needed.

Required products: MATLAB, Deep Learning Toolbox. The native entry is `demo_safe_pinn`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Optional author-checkpoint evaluation

Author weights and conversion tools are not distributed here. If you have separately obtained a compatible converted MATLAB file, replace the placeholder below with its path. The required tensors and independent value/gradient checks are defined in [`load_author_boat.m`](load_author_boat.m); [`SOURCE.json`](SOURCE.json) identifies the historical checkpoint. The loader requires Deep Learning Toolbox and does not read a raw PyTorch `.pth` file.

The comparison reuses the inputs from the training run above and saves its own directory:

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
weights = 'path/to/your/converted-author-weights.mat'; % Replace with your file
[authorNet,parity] = load_author_boat(weights);
comparison = fullfile(runDir,'result.mat');
authorRunDir = tempname(outputRoot);
authorResult = evaluate_boat_model(authorNet,authorRunDir,comparison);
audit = calibrate_boat(authorNet,authorRunDir);
```

## Validation and results

The current suite records **9 local tests** for this method. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](README.zh-CN.md) and [paper card](../../docs/fulltext/safe_pinn_icml2025.md). Larger historical data belong to the [artifact collection](../../docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
