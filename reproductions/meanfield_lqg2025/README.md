# Mean-field LQG

[中文说明](README.zh-CN.md) · [Equation and full-text notes](../../docs/fulltext/meanfield_lqg2025.md) · [All APIs](../../docs/IMPLEMENTED_API.md)

**Source:** Zhenhui Xu, Bing-Chang Wang, Tielong Shen. [Mean field LQG social optimization: A reinforcement learning approach](https://doi.org/10.1016/j.automatica.2024.111924). Automatica 2025.

**Implemented scope:** Two-state, single-input social optimization with independent Itô paths: two learned gains, a sampled mean trajectory and finite-population costs. The historical records include low-sample failures.

## Run from the repository root

```matlab
report = demo_reproductions('meanfield_lqg2025');
```

The default experiment uses **100 training paths**, seed `20260907`, eight independent training fits and 48 evaluation populations of 40 agents. Costs are integrated over 20 seconds. A completed run saves its configuration, data, fits and evaluation under a new `runs/meanfield_lqg2025/` directory.

Required products: MATLAB. The native entry is `demo_meanfield_lqg2025`. The full API page lists its inputs and outputs; the shared selector forwards them directly.

## Higher Monte Carlo precision

The project page's approximately **0.53% / 0.85%** gain errors refer to a historical **4,000-path** experiment, rather than the default 100-path call. The existing precision procedure pools **40 batches of 100 paths** under one common probing signal, fitting at 100, 400, 1,000 and 4,000 paths:

```matlab
addpath(fullfile(pwd,'reproductions','meanfield_lqg2025'));
cfg = mf_config;
outputDirectory = fullfile(pwd,'runs', ...
    ['meanfield-precision-' char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
precision = mf_precision_check(outputDirectory,cfg,40);
```

On completion, `precision.mat` contains the configuration, batch seeds, shared frequencies, pooled moments and fits; `mc-precision.csv` contains gains and errors, and `cost-comparison.csv` contains the finite-horizon cost comparison. The primary batch seeds are `cfg.seed + (0:39)`. Setting only `cfg.train.paths=4000` changes the random draws and batching, so it does not reproduce this same random experiment.

For the complete existing verification sequence, including four independent 4,000-path fits:

```matlab
addpath(fullfile(pwd,'reproductions','meanfield_lqg2025'));
outcome = run_verified_meanfield;
```

This sequence runs method tests, the default 100-path experiment, the precision procedure and three further 4,000-path fits. The resulting `gain-uncertainty-4000.csv` reports variation across four fits; the cost standard error instead describes 48 independent populations conditional on the primary fitted policy and sampled mean curve.

An error in the first 100-path fit stops the complete sequence before the precision stage. The precision procedure also fits its smaller pooled samples before reaching 4,000 paths, so it can stop at one of those fits. These commands preserve the existing procedure; they do not skip rejected fits or substitute seeds.

## Replay a rejected primary fit

`demo_meanfield_lqg2025` saves `cfg` and `raw` to `training-data.mat` after collection, appends `data` after building the observed statistics, and appends `learned` only after a successful primary fit. If that fit fails, `failure.json` records its stage, error identifier and message; the original error is still thrown.

Set `runDirectory` to the failed demo's directory to replay the fit without collecting new data:

```matlab
addpath(fullfile(pwd,'reproductions','meanfield_lqg2025'));
runDirectory = '/path/to/failed-demo-run'; % Replace with your run directory
saved = load(fullfile(runDirectory,'training-data.mat'),'cfg','data');
learned = mf_learn(saved.data,saved.cfg.cost,saved.cfg.K0,saved.cfg.learn);
```

With the same inputs and options, the rejection is reproduced. This reruns only the primary fit; it does not resume the complete experiment or add checkpoints to `mf_precision_check`.

## Validation and results

The current suite contains **8 local tests** for this method, including preservation and replay of rejected primary-fit inputs. Run `run_all_tests('list')` to inspect discovery, then `run_all_tests` for the combined suite. Independent equations and comparators are documented in the test functions and full-text notes.

The [paper card](../../docs/fulltext/meanfield_lqg2025.md) records the earlier 100-path gain errors of 18.23% / 30.01%, one rejected fit among eight repeats, and the 4,000-path result above. These are historical results, not new measurements from the commands shown here. Their original MAT/CSV records are in the separately retained [artifact collection](../../docs/ARTIFACTS.md); the public source contains the summary. The current procedure is specified above, while an exact match to the historical run requires its saved configuration and data identities. The test count does not imply that every original figure or theoretical guarantee has been reproduced.
