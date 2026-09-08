# Domain context

This v0.5.0 release keeps the 81 MATLAB sources from v0.4.1 and organizes their public distribution, documentation and validation records. Previous method runs remain as history; earlier experiments live under evidence/v0.4 and current repository checks under evidence/v0.4.1. New user runs are stored under runs/.

The repository contains the preserved original CT integral-PI baseline and seven independent paper-method implementations under reproductions/. Each method declares its exact variant and validation status in registry/reproductions.json. A full-text reading, an implementation, a completed run, and a validated paper metric are separate facts. The standalone methods are not a universal ADP API.

- **Problem**: physical state, reference, dynamics, stage cost, constraints, and the information available to each algorithm.
- **Plant truth**: quantities available to the simulator. These are not automatically available to the learner.
- **Value function**: scalar expected/deterministic accumulated cost under a specified policy and horizon/discount convention.
- **Critic**: representation and estimator of that value (or Q function); specify which.
- **Actor**: policy representation. An analytic greedy map does not require a separate trained neural actor.
- **Identifier**: learned dynamics/uncertainty model, with estimation error distinct from critic error.
- **Behavior policy**: the input-generating process for collected data, including exploration, human input, filters, and execution changes as applicable.
- **Target policy**: the policy being evaluated or improved by the learning equation.
- **Bellman residual**: residual of a documented differential, integral, or discrete Bellman identity, not the stage cost.
- **History stack**: retained regression data with timestamps, selection policy, and rank diagnostics. Its size alone is not an excitation guarantee.
- **Executed input**: the command used by the plant after all specified transformations.
- **Run**: one immutable configuration and its raw data, metadata, diagnostics, and derived artifacts.
- **Reproduction**: a specific source version, scenario, metric and tolerance comparison; not merely running a script.

The baseline uses column states/inputs and stored trajectory rows, with CT stage cost x'Qx+u'Ru and no half factor. Paper packages may instead use state-by-time arrays or explicit trajectory/sample axes, and some papers use a half factor. The native method's declared dimensions and normalization take precedence; never transpose or rescale silently to imitate the baseline. The baseline uses continuous feedback and frozen evaluation. See docs/IMPLEMENTED_API.md and each method's full-text card.

The expanded taxonomy is in docs/METHOD_CONTRACTS.zh-CN.md. A method may learn only a policy, solve Q fixed-point equations, identify a model, or solve a time-dependent PDE. Stochastic process, uncertainty distribution, return distribution and randomized policy are distinct. Finite-horizon boundary conditions and stability certificate types are part of each method contract.

The unified demo_reproductions entry only selects a method and forwards its native arguments. run_all_tests discovers existing local tests without invoking neural training entry points; an absent test file is listed as zero, not as a passed method. Learned models, empirical Monte Carlo moments, actual neural weights and model-based or analytic oracles remain distinct. In the mean-field example, E[xx'] differs from E[x]E[x]'. In both PINN examples, PDE time/terminal conditions and physical rollout time are declared separately.

Bias-PI targets the undiscounted cost. Its outer equation includes gamma*Vprevious; its inner discounted PI and bootstrap omit that term. A coefficient stopping test can terminate with an indefinite critic and an unstable actor. Saved closed-loop and positivity diagnostics therefore describe distinct observations. Default examples use explicit local multistart data; paper-initial sampling failures are retained.

registry/reproductions.json is the single executable method inventory. adp_catalog reads that file; demo_reproductions and run_all_tests use it. Source archives omit historical evidence/results by design; the full archive preserves them. Both must run their current local tests without cached experiments or external author checkpoints.
