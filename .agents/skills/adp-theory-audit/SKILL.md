---
name: adp-theory-audit
description: Audit mathematical consistency between MATLAB ADP control implementations and their stated equations or assumptions. Use for Bellman, feature-gradient, learning-law, convergence and guarantee reviews.
---

# ADP equation-to-code audit

Start from the active source and paper version. Prefer read-only review unless modification is requested. For each finding provide location, severity, evidence, effect, correction and a runnable verification step. Distinguish demonstrated algebraic/code errors from assumptions requiring the paper or author to resolve.

Trace this chain: problem and information available → coordinates/features → value and policy → residual/regression → adaptation → executed dynamics → stated conclusion.

Check cost half factors, feature cross terms, gradient orientation, finite-difference derivatives, tracking/transform chain rules and explicit time terms. Check whether a logged Bellman residual is actually a cost, Hamiltonian, TD error or integrated quantity.

For least-squares/history learning, inspect rank, singular values, threshold/scaling, regularization, sample selection, model-error contamination and whether the theorem's excitation premise is met. A large matrix norm or large buffer does not establish full rank.

For finite/fixed/prescribed time claims, identify the convergence object and exact versus practical neighborhood. Inspect initial-condition requirements, time singularities, gain constraints and digital implementation. Do not infer a uniform bound from several fast trajectories.

Trace all information used by the learner. True drift/derivatives, inverse models or disturbance values available in simulation may invalidate a stated knowledge assumption.

Check adaptive-solver callbacks for hidden updates, event ordering and discarded/repeated evaluations. Separate implementation defects from the different experiment represented by continuous feedback versus sample-and-hold.

Use focused counterexamples or identity tests where useful. Do not change proof assumptions, relax numerical gates, or remove failed scenarios solely to obtain a passing result. Mark unavailable mathematical evidence explicitly.

## Method expansion checks

For recent methods, use docs/METHOD_CONTRACTS.zh-CN.md: verify Ito generator/Hessian and mean-square stability; CTMC rate generators; average/risk objectives; Q fixed points versus Bellman residual minimization; critic-free outputs; initialization premises; quadrature amplification and PDE boundary conditions. Value error alone does not imply gradient/policy error. Sampled constraints do not establish uniform certificates.
