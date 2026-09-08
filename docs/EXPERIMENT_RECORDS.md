# Recorded experiments and checks

These entries describe preserved numerical variants. Settings differ across methods. Local tests, full training, and matching a paper figure are distinct records.

| Method | Example | Recorded outcome or scope | Record |
|---|---|---|---|
| Integral policy iteration | Double integrator | The saved baseline reaches the analytic LQR gain in five policy-evaluation rounds; the final gain error is 8.37e-14. | [Record](../docs/assets/data/baseline-summary.json) |
| Koopman generator + PI | Normalized pendulum | Fifty recorded closed-loop trajectories have a maximum terminal state norm of 1.23e-3. Average cumulative cost across the 50 initial states is compared with true-model PI: the maximum absolute difference over 0–10 s is 3.15e-5. | [Record](../reproductions/koopman_l4dc2025/RESULTS.md) |
| Mean-field LQG | Finite population LQG | The documented 4,000-path run reports gain errors of approximately 0.53% and 0.85%. Low-sample failures and independent training repeats are retained. | [Record](../docs/fulltext/meanfield_lqg2025.md) |
| Off-policy Q-learning | Data-based LQR | The implementation documents a data-based stabilizing initialization, a discrete LQR comparison, and an explicit MIMO initialization variant. The linked record contains local checks. | [Record](../evidence/v0.3/root-peer-review/test-results.json) |
| Infinite-horizon HJB PINN | Scalar LQR & pendulum | The saved reduced pendulum experiment completes four closed-loop evaluations at each continuation horizon, from 1 through 4. The figure shows the trained value on the common grid at horizon 4. | [Record](../evidence/v0.3/pinn/reduced_20260907_110031_520/summary.json) |
| Safe epigraph PINN | Constrained boat navigation | Of the same 64 candidates, reduced training executes 64: 19 collisions, 47 budget violations. The author checkpoint executes 63: 1 collision, 9 budget violations. Events may overlap. | [Record](../evidence/v0.3/safe-pinn/RESULTS.md) |
| Robust Koopman PI | Lifted bilinear control | The fitted error bound fails on 25.55% of held-out points in the preserved evaluation. | [Record](../reproductions/robust_koopman2026/RESULTS.md) |
| Bias-policy iteration | Pendulum & two-link arm | The recorded arm variant stabilizes, with cost 8.84% above the local LQR comparison. | [Record](../reproductions/bias_pi_automatica2026/RESULTS.md) |
