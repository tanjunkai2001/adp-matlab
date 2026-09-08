---
name: adp-paper-reproduce
description: Reproduce or migrate a control and ADP paper's MATLAB code with pinned sources, equation mapping and quantitative comparisons. Use when a paper or upstream research implementation is the reference.
---

# ADP paper reproduction

Inspect the supplied paper, code and existing results. Fix the paper version, source commit/archive hash, entry point, required toolboxes and license evidence. Keep upstream code in an isolated copy and prevent its same-named functions from entering the new library path.

Use the project's paper contract and equation map if present; otherwise create concise local equivalents. Map dynamics, features, gradients, costs, actor/critic/identifier updates, history selection, timing and execution to actual source locations. Do not invent equation numbers or infer theorem assumptions solely from a README.

First define the target: a named scenario, figure or metric with a reference value and tolerance. A cached MAT file is reference data, not evidence of a fresh run. Where the original result is unavailable, state which comparisons are possible.

Preserve two paths when needed: the pinned original behavior and an explicitly corrected version. A mathematical correction is not a behavior-preserving refactor. Save independent run IDs, configs and differences. Tuning to resemble a picture is recalibration even when the changes are recorded; it is not evidence of reproducing the published parameter setting.

Audit the original entry point for destructive operations and external side effects before execution. Execute authorized research simulations in an isolated output location. Do not run hardware callbacks or publish/send results as part of an ordinary reproduction.

Check simulator truth versus learner knowledge, target/behavior policy, CT versus sampled control, data rank, and train/evaluate differences. Compare numerical values, not only visual similarity.

Track variant (original, refactored, corrected, recalibrated) separately from evidence stage (source_reviewed, run_completed, numerical_match, independent_rerun). A corrected variant can still be unrun. Attach evidence paths and the next unresolved item. A successful simulation does not by itself validate the paper's theorem.

## Method expansion checks

Use registry/papers.json and docs/literature/ as dated leads, then pin the actual full-text version. Record sections read and unresolved proof assumptions. Distinguish publication status, source-code availability, implementation and reproduction. Use templates/method-intake.md before promoting a new family. Do not convert a preprint or a downloaded PDF into a verified theorem.

For finite-sample guarantees, record fresh-batch versus fixed-batch/replay use and cross-iteration sample dependence. Do not apply a theorem for newly collected batches to fixed-data reuse without a separate argument.

For the implemented methods, start with the corresponding `docs/fulltext/` card. These cards distinguish published versions, author preprints, reduced training, corrected equations and released checkpoints. If author code differs from the paper, identify the exact calling chain; the current public source does not by itself establish how an older checkpoint was trained. An imported checkpoint should pass value and gradient parity checks before being used as a comparison.
