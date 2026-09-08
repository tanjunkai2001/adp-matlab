---
name: adp-benchmark
description: Design and run MATLAB ADP method comparisons, ablations and reproducible research figures from raw experiment data. Use for benchmark suites, multi-scenario evaluations and result reconstruction.
---

# ADP experiments and figures

Inspect the scientific question and existing protocol. Establish common plant, learner knowledge, cost, constraints, execution timing, stopping rules and method tuning budgets before comparing outcomes.

Separate training from evaluation, and say whether evaluation freezes learning. Use named initial-state/disturbance sets and seeds; use independent noise streams or pre-generated disturbances so solver calls do not determine randomness.

Select metrics that answer the question: cost, tracking, input use, constraint margins, residuals, learning diagnostics, trigger/communication counts or computation. Define thresholds and time-to-convergence semantics. Include every expected scenario and failed/missing run.

Create unique run directories; save serializable config, raw trajectories, learning states, environment and source/data hashes. Check artifact hashes before reusing cached results, and label cached-only validation separately from recomputation.

Generate figures from named saved results. Compute metrics from full data; downsampling is display-only. Preserve units, meaningful color/line/marker encoding and inspect at final inclusion size. Do not smooth data or alter numerical values to improve appearance.

Run the smallest justified experiment first, then the planned comparison. When a test fails, retain failure details; do not silently drop a seed or widen tolerance. Report finite-sample evidence and uncertainty without turning a benchmark into a general convergence or safety theorem.

## Method expansion checks

Record integralSource, quadratureRule, sampling times and whether integrationErrorBound is proved, estimated or unavailable. Compare sparse sampled quadrature separately from solver-integrated cost. Keep Monte Carlo error, finite-population error, model mismatch and feature error distinct. Run matched physical time/discount/horizon and report all sensitivity configurations; machine precision in one analytic case is not a universal tolerance.

For finite-sample guarantees, record fresh-batch versus fixed-batch/replay use and cross-iteration sample dependence. Do not apply a theorem for newly collected batches to fixed-data reuse without a separate argument.

In this repository, `run_all_tests('list')` lists available numerical tests and `run_all_tests` executes them. Neural training is a separate explicit run. For saved PINN experiments, inspect residuals, terminal conditions and closed-loop cost/constraints separately. For level-set calibration, use fresh audit samples after selecting the threshold and state the sampling distribution and violation event. A lower HJB loss alone does not establish better control.
