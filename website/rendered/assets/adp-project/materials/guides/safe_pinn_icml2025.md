# Safe epigraph PINN

[中文说明](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/safe_pinn_icml2025/README.zh-CN.md) · [Equation and full-text notes](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/safe_pinn_icml2025.md) · [All APIs](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/IMPLEMENTED_API.md)

**Source:** Manan Tayal, Aditya Singh, Shishir Kolathaya, Somil Bansal. [A Physics-Informed Machine Learning Framework for Safe and Optimal Control of Autonomous Systems](https://proceedings.mlr.press/v267/tayal25a.html). ICML 2025.

**Implemented scope:** A reduced boat-training example and a separate author-checkpoint evaluation. Both recorded paths have collision and budget violations. Independent conditional calibration is a third, distinct experiment.

## 1. Train the reduced MATLAB model

From the repository root:

```matlab
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
[result,runDir] = demo_reproductions('safe_pinn_icml2025',outputRoot,5000);
S = load(fullfile(runDir,'result.mat'),'result');
S.result.metrics
```

This runs 5,000 neural-training updates and saves a new directory under `outputRoot`. The saved `result.mat` contains the trained network, fixed evaluation inputs, trajectories and metrics. No historical result or author checkpoint is needed.

Required products: MATLAB, Deep Learning Toolbox. The native entry is `demo_safe_pinn`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

After completing evaluation, the demo saves `result.mat`, `metrics.json` and `training.csv`, then checks held-out loss improvement and terminal error. If a final check fails, these files remain and the original assertion still throws. The console prints `Saved Safe PINN evaluation:` followed by the directory. A call that throws does not return new `result` or `runDir` values; use the printed directory to inspect it:

```matlab
savedDirectory = '/path/printed/by/the/demo'; % Replace with the printed directory
S = load(fullfile(savedDirectory,'result.mat'),'result');
S.result.metrics
```

The presence of these files does not mean the final checks passed. This saves completed evaluations; it does not provide recovery from nonfinite losses during training or from earlier evaluation errors.

## 2. Evaluate an external author checkpoint

This path loads weights for inference without retraining the author's network. It needs two files obtained or created separately:

- A converted MATLAB weight file. The loader expects `W1`–`W5`, `b1`–`b5`, `checkpoint_epoch` and independent reference value/gradient arrays; see [`load_author_boat.m`](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/reproductions/safe_pinn_icml2025/load_author_boat.m) for the exact fields. [`SOURCE.json`](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/reproductions/safe_pinn_icml2025/SOURCE.json) records the historical checkpoint and normalization. Weights and conversion tools are not bundled, and a raw PyTorch `.pth` file cannot be passed directly to the loader.
- A `result.mat` saved by `demo_safe_pinn`, containing `result.heldoutInputs` and `result.testInitial`. `evaluate_boat_model` reuses these inputs, but selects the budgets again with the supplied network. An existing compatible run can be used without retraining; the snippet uses the run from step 1. Its `comparisonFile` cannot be replaced with the weight file or the evaluator's `evaluation.mat`.

Replace `weightFile` with your converted file. The evaluation writes into a new directory:

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
weightFile = '/absolute/path/to/converted-author-weights.mat'; % Replace
comparisonFile = fullfile(runDir,'result.mat'); % Or your existing demo result
[authorNet,parity] = load_author_boat(weightFile);
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
if ~isfolder(outputRoot), mkdir(outputRoot); end
authorRunDir = tempname(outputRoot);
authorResult = evaluate_boat_model(authorNet,authorRunDir,comparisonFile);
authorResult.metrics
```

The loader checks MATLAB values and physical-input gradients against the reference arrays in the converted file. Evaluation saves `evaluation.mat`, `metrics.json` and trajectory figures. It writes directly to the supplied directory; use a fresh `tempname` for every evaluation. Deep Learning Toolbox is required for both paths.

## Read the recorded counts

The [September 7 record](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/evidence/v0.3/safe-pinn/RESULTS.md) reports the following fixed-input evaluations with the current cost integrator:

| Network | Candidate initial states | Predicted feasible and executed | Collisions among executed | Budget violations among executed |
|---|---:|---:|---:|---:|
| Reduced MATLAB training, 5,000 updates | 64 | 64 | 19 | 47 |
| Author checkpoint, epoch 250,000 | Same 64 | 63 | 1 | 9 |

Each network searches 100 budgets in `[0,14.86]` at a two-second horizon and executes only candidates with a predicted nonpositive epigraph value. The author's remaining candidate is not executed or counted as a successful trajectory. Collision and budget events may overlap; their counts must not be added. These evaluations use step `0.005` and strict `maxObstacleG > 0` / `cost > initialBudget` event tests.

## Optional: independent conditional calibration

This samples augmented states separately from the fixed 64-candidate comparison:

| Stage | Samples and purpose |
|---|---|
| Threshold selection | 2,000 uniform `(x,y,z)` proposals; evaluate the predicted set and select `delta` |
| Fresh conditional audit | Target 300 new samples satisfying `V <= delta`; evaluate joint collision/budget/nonfinite events |

```matlab
addpath(fullfile(pwd,'reproductions','safe_pinn_icml2025'));
netForAudit = result.network; % Use authorNet for the author checkpoint
outputRoot = fullfile(pwd,'runs','safe_pinn_icml2025');
if ~isfolder(outputRoot), mkdir(outputRoot); end
calibrationDir = tempname(outputRoot);
mkdir(calibrationDir);
audit = calibrate_boat(netForAudit,calibrationDir);
```

The sampler uses `x` in `[-3,2]`, `y` in `[-2,2]`, `z` in `[0,14.86]` and seed 25052. It draws proposals in batches of 2,000 and retains the first 300 accepted samples; `300/proposalCount` is **not a coverage estimate**. If too few samples are obtained, no conditional bound is returned. This audit uses non-strict event thresholds (`>= 0`) and includes nonfinite rollouts, unlike the fixed-input count table.

The recorded reduced/author audits had 15/300 and 2/300 joint violations, with respective 95% one-sided upper bounds 7.5949% and 2.0836%. These concern the selected set and numerical rollout labels. See the [equation notes](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/safe_pinn_icml2025.md) for the sampling and step-refinement checks.

## Validation and results

The current suite contains **10 local tests** for this method, including a zero-update demo that evaluates the fixed inputs and checks that a rejected final result remains saved. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The detailed experiment record and numerical differences are preserved in the [Chinese implementation notes](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/safe_pinn_icml2025/README.zh-CN.md) and [paper card](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/fulltext/safe_pinn_icml2025.md). Larger historical data belong to the [artifact collection](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md). The test count does not imply that every original figure or theoretical guarantee has been reproduced.
