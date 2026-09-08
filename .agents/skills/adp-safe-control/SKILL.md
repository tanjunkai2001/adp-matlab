---
name: adp-safe-control
description: Integrate or review safety and constraints in MATLAB ADP controllers, including PPC, barrier transforms, constrained policies and CLF/CBF filters. Use when constraints or input execution are changed.
---

# Safety and constraints in ADP

Identify where the requested mechanism enters: cost/learning, coordinates/value representation, or policy/execution filtering. Preserve the task's intended mechanism instead of adding a generic QP by default.

Write the feasible domain, constraint convention, relative degree where needed, initial-state requirements, model/uncertainty assumptions, input bounds and timing. Verify the relevant paper's formulas before claiming invariance or performance guarantees.

For PPC/time-varying transforms, include reference derivatives and time terms, check inverse-domain consistency and monitor original-coordinate margins. Do not hide singularities through clipping unless the altered method is explicitly documented and analyzed.

For filtering/optimization, log solver status, actual constraint residuals, slack, bounds, solve time and final applied input. Reject nonfinite or stale outputs. Distinguish hard constraints from relaxed constraints; a positive slack cannot be silently counted as satisfying the original certificate. Define an infeasibility/timeout outcome consistent with the task; zero input is not a universal safe fallback.

Trace nominal, exploration/shared, filtered, communicated/held and applied inputs, including timestamp and whether the applied value is simulated, measured or only commanded. Compute certificate residuals for the applicable executed dynamics. A post-filter saturation can violate a certificate satisfied by the QP output.

Recheck the learning identity when behavior differs from the policy being evaluated. Logging the applied command is necessary for diagnosis but does not automatically supply an off-policy correction or theorem. If the data-policy identity is unresolved, retain the samples for diagnosis and disable that unsupported learning update; continue only the separately justified evaluation/control path.

Run appropriate boundary, infeasible, disturbance and timing tests, with finite experimental conclusions. Distinguish sampled feasibility, continuous-time certificate assumptions, actuator feasibility and hardware evidence. Do not escalate an authorized software change into hardware operation.

## Method expansion checks

Also consider direct actor constraints, learned certificates and constrained HJB/epigraph backends. Keep the performance critic separate from the Lyapunov/barrier certificate and backup policy. Record uncertainty persistence, ambiguity set/radius, domain, probability quantifiers and calibration data split. A fixed uncertain parameter is different from Brownian diffusion. Follow docs/METHOD_CONTRACTS.zh-CN.md.
