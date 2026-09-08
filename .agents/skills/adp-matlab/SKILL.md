---
name: adp-matlab
description: Develop or modify MATLAB adaptive dynamic programming control code using explicit model, feature, learning and execution contracts. Use for ADP implementations and reusable research modules.
---

# MATLAB ADP development

Locate the current project's README.md and CONTEXT.md. If it follows this reference repository, read the relevant sections of docs/DESIGN.zh-CN.md and the implemented function help. Do not assume every planned module exists or use a fixed filesystem path to another project.

Before implementing a learning rule, establish CT/DT, affine/nonaffine, coordinates, value/Q representation, cost scaling, horizon/discount, and what model information the learner is allowed to access. Inspect the actual source equations when available; label any missing formula as unresolved rather than inventing it.

Use functions with explicit configuration/state and MATLAB namespaces. Keep model dynamics, feature derivatives, learning state and execution semantics inspectable. Introduce abstractions when distinct methods actually need them; do not create pass-through classes or empty algorithm stubs.

For an analytic greedy CT policy, check the factor-of-two convention from the stage cost and value gradient. For a constrained/nonaffine policy, derive or reference the applicable minimization instead of copying the unconstrained formula.

Record target versus behavior policies and nominal versus applied commands. Keep ODE right-hand sides free of hidden history-stack writes and random/logging side effects. Represent continuous adaptation as integrated state; implement sampled updates once per declared sample/event.

Choose checks that can detect actual mistakes: analytic LQR, Bellman identity, numerical feature gradients, rank-deficient regression rejection, or execution timing. Purely cosmetic edits do not require a new numerical campaign.

Save a unique run with exact config, raw data and numerical diagnostics. Report implemented capability separately from planned extensions. Preserve original research versions when a change affects formulas, data or conclusions.

For a paper-specific migration, use the available paper contract template and the adp-paper-reproduce skill if installed. For safety changes or explicit theorem audits, use the corresponding skill only when relevant; ordinary development does not require loading every skill.

## Method expansion checks

For new algorithm families, read docs/METHOD_CONTRACTS.zh-CN.md and fill templates/method-intake.md. Declare learned object (V/Q/q/actor-only/model), initialization and dynamics kind. Keep physical diffusion, policy randomization and numerical viscosity distinct. Add interfaces only when a concrete implementation needs them.

In the current version, use `demo_reproductions()` to discover the working examples and `docs/IMPLEMENTED_API.md` for their native arguments. Paper examples live in `reproductions/`; add only the selected directory to the MATLAB path. The baseline `src/+adp` API is not a mandatory wrapper for new methods.

For Koopman models, keep lifted coordinates and input-coupled features explicit; a fit on observed samples is not a uniform model-error bound. For neural HJB, check physical input/value scaling, time-to-go sign and spatial automatic derivatives before training. Keep checkpoint inference and fresh training as separate operations.

Read `check_environment()` before selecting optional toolboxes. Add a method to `registry/reproductions.json`; the shared catalog drives both demo and test discovery. Save new experiments under `runs/` and preserve versioned evidence. `tools/check_repository.py` checks metadata, paths and documentation without MATLAB.
