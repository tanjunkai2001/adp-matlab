# Methods and current scope

This table is generated from the implemented-method registry.

| Method / source | Model & learning | Tests | Implemented scope |
|---|---|---:|---|
| [Integral policy iteration](GETTING_STARTED.md) · Reference baseline | CT linear quadratic · known B | 46 | Analytic LQR comparator; two-state example. |
| [Koopman generator + PI](../reproductions/koopman_l4dc2025) · [L4DC 2025](https://proceedings.mlr.press/v283/zeng25a.html) | CT nonlinear · identified generator | 8 | Normalized pendulum variant; not every paper table. |
| [Mean-field LQG](../reproductions/meanfield_lqg2025) · [Automatica 2025](https://doi.org/10.1016/j.automatica.2024.111924) | Stochastic CT · two-gain PI | 7 | Finite-sample social optimization; low-sample failures retained. |
| [Off-policy Q-learning](../reproductions/qlearning_tac2023) · [IEEE TAC 2023](https://doi.org/10.1109/TAC.2023.3235967) | DT LQR · matrix Bellman equation | 7 | Data-based LQR; explicit MIMO initialization variant. |
| [Infinite-horizon HJB PINN](../reproductions/pinn_infinite_horizon2025) · [IJRNC 2025](https://doi.org/10.1002/rnc.70028) | Neural HJB · horizon continuation | 5 | Reduced LQR/pendulum training; corrected quartic cost identified. |
| [Safe epigraph PINN](../reproductions/safe_pinn_icml2025) · [ICML 2025](https://proceedings.mlr.press/v267/tayal25a.html) | Epigraph HJB · neural value | 9 | Boat example; collision and budget violations remain. |
| [Robust Koopman PI](../reproductions/robust_koopman2026) · [Preprint 2026](https://arxiv.org/abs/2604.05633) | Lifted bilinear · robust PI | 8 | Held-out error bound fails on 25.55% of points. |
| [Bias-policy iteration](../reproductions/bias_pi_automatica2026) · [Automatica 2026](https://doi.org/10.1016/j.automatica.2026.112821) | Unknown CT nonlinear · fixed data | 12 | Pendulum/arm variants; arm cost is 8.84% above local LQR. |

## Native entry points

| ID | Entry | Required products | Equation map |
|---|---|---|---|
| `baseline` | `demo_integral_pi` | MATLAB | [Method card](../docs/METHOD_CONTRACTS.zh-CN.md) |
| `koopman_l4dc2025` | `demo_koopman` | MATLAB | [Method card](../docs/fulltext/koopman_l4dc2025.md) |
| `meanfield_lqg2025` | `demo_meanfield_lqg2025` | MATLAB | [Method card](../docs/fulltext/meanfield_lqg2025.md) |
| `qlearning_tac2023` | `demo_qlearning_tac2023` | MATLAB, Control System Toolbox | [Method card](../docs/fulltext/qlearning_tac2023.md) |
| `pinn_infinite_horizon2025` | `run_pinn_reproduction` | MATLAB, Deep Learning Toolbox | [Method card](../docs/fulltext/pinn_infinite_horizon2025.md) |
| `safe_pinn_icml2025` | `demo_safe_pinn` | MATLAB, Deep Learning Toolbox | [Method card](../docs/fulltext/safe_pinn_icml2025.md) |
| `robust_koopman2026` | `demo_robust_koopman` | MATLAB | [Method card](../docs/fulltext/robust_koopman2026.md) |
| `bias_pi_automatica2026` | `demo_bias_pi` | MATLAB; optional: Control System Toolbox | [Method card](../docs/fulltext/bias_pi_automatica2026.md) |

Full training, local mathematical tests and matching a paper’s figures are different records. See [VALIDATION](../VALIDATION.md).
