# Validation record

The v0.5.0 release source completed **102/102 local MATLAB tests**, with 0 failures and 0 incomplete tests, on 2026-09-08 at 00:59:51 UTC. Environment: 25.2.0.3312555 (R2025b) Update 6, macOS Apple silicon. The suite took 36.44 seconds and did not depend on historical MAT/FIG data, paper PDFs or author checkpoints.

[Summary](docs/validation/matlab-tests.json) · [Per-test CSV](docs/validation/matlab-tests.csv) · [81 source hashes](docs/validation/matlab-source-hashes.json)

| Group | Passed |
|---|---:|
| Baseline and repository entries | 46 |
| Koopman L4DC 2025 | 8 |
| Mean-field LQG | 7 |
| Off-policy Q-learning TAC 2023 | 7 |
| Infinite-horizon HJB PINN | 5 |
| Safe PINN ICML 2025 | 9 |
| Robust Koopman 2026 | 8 |
| Bias-PI Automatica 2026 | 12 |

One PINN replay test executes two single Adam updates to check determinism. They do not retrain the historical paper experiments. The 81 MATLAB files are byte-identical to the tested v0.4.1 source; v0.5.0 changes distribution metadata, documentation, publication assets and workflow configuration.

## Numerical reproduction scope

| Method | Recorded result and unresolved scope |
|---|---|
| Baseline | Analytic LQR gain/value comparison and Bellman checks. Figures retain the recorded September 7 experiments. A fresh September 8 quickstart independently returns the same gain; see its [metrics](docs/validation/quickstart-baseline.json). |
| Koopman | Normalized pendulum implementation with independent identification/closed-loop checks; not all original tables. |
| Mean-field | 100/4000-path numerical records; finite-sample failures are retained. |
| TAC Q-learning | Matrix Bellman implementation, with an explicitly identified MIMO initialization variant. |
| Infinite-horizon PINN | Reduced LQR/pendulum neural training and held-out checks; quartic-cost mismatch identified and corrected variant distinguished. |
| Safe PINN | Reduced boat run: 19/64 collisions, 47/64 budget violations. Author-checkpoint evaluation: 1/64 collision and 9/64 budget violations. |
| Robust Koopman | Held-out model-error bound fails on 25.55% of points; the nominal comparator has slightly lower cost. |
| Bias-PI | Local-multistart pendulum/arm variants. The arm stabilizes but costs 8.84% more than local LQR. Original single-trajectory failures and iteration mismatches are retained. |

See the [method cards](docs/fulltext) for source versions, equations, configurations and each result’s scope. Historical records are described in [ARTIFACTS](docs/ARTIFACTS.md).

## Publication infrastructure

The GitHub Actions workflow is prepared but has not run on GitHub. It targets Linux and MATLAB R2025bU6 with Control System Toolbox and Deep Learning Toolbox. Its first cloud run and a second-machine reproduction remain separate checks. No CI-passing badge is shown.

The project page and README use the same registry-driven method table. Local document/build checks establish their consistency; they do not prove scientific completeness, original-paper equivalence or hardware safety.
