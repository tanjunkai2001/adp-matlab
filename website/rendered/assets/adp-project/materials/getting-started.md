# Getting started

Clone the repository or extract a source ZIP, then open its root folder in MATLAB.

```sh
git clone https://github.com/tanjunkai2001/adp-matlab.git
cd adp-matlab
```

 No Python runtime is needed to run the control algorithms.

## Requirements

| Work | Products |
|---|---|
| Baseline, Koopman, robust Koopman, mean-field and pendulum Bias-PI | MATLAB |
| TAC Q-learning and Bias-PI arm LQR comparison | MATLAB + Control System Toolbox |
| Infinite-horizon PINN and safe PINN | MATLAB + Deep Learning Toolbox |
| Entire test suite | MATLAB + both toolboxes above |

The current source was tested on MATLAB R2025b Update 6, macOS Apple silicon. The standard JVM is used for SHA-256 result records. `check_environment` reads installed products; it does not check out a runtime license.

```matlab
check_environment();
catalog = demo_reproductions();
[r, folder] = demo_reproductions('baseline');
```

The baseline is an undiscounted, two-state double integrator with Q=I, R=1 and known B. Its learned gain is compared with `[1, sqrt(3)]`. Inspect `r.learning`, `r.metrics` and `r.evaluation`; `folder` contains the saved run. See [implemented API](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/IMPLEMENTED_API.md) for exact fields and conventions.

## Select a paper method

```matlab
[r, folder] = demo_reproductions('koopman_l4dc2025');
[r, folder] = demo_reproductions('qlearning_tac2023');
[r, folder] = demo_reproductions('bias_pi_automatica2026');
```

These execute numerical experiments. The [method table](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/METHODS.md) links the paper, implementation and numerical scope. Native argument conventions are preserved; there is no common controller class to configure.

To exercise the neural training workflow briefly:

```matlab
[r, folder] = demo_reproductions('pinn_infinite_horizon2025','smoke');
```

This performs 30 training updates and two independent 12-update prefix replays. For the recorded reduced-scale training procedure use `'reduced'`; it takes substantially longer. The `quartic` mode uses the explicitly corrected cost described in the paper card.

## Validate a change

```matlab
run_tests;                    % baseline and repository entries
run_all_tests('list');         % discover without running
results = run_all_tests;       % every current local test
```

Keep new runs in `runs/`. A single-run output directory must be new; an `outputRoot` parent may already exist. Do not add historical snapshots with `addpath(genpath(...))`.

When editing the project’s registry or presentation:

```text
python3 tools/build_project_docs.py
python3 tools/check_repository.py --source-only
python3 tools/build_project_docs.py --check
```

Python 3 uses only its standard library here. This updates the README tables and standalone project page; the MATLAB algorithms have no Python dependency.
