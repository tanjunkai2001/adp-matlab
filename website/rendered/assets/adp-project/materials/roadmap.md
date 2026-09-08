# Roadmap

The first public version should be useful without waiting for every planned algorithm. It contains the working baseline, seven independent paper implementations and explicit evidence. The remaining 35 algorithm entries and 18 module groups are a research backlog.

| Milestone | Concrete outcome | Acceptance evidence | Status |
|---|---|---|---|
| v0.5: public reference | Bilingual README, complete entry navigation, source-only checkout, contribution templates, citation, project page | [Validation and source identity](https://github.com/tanjunkai2001/adp-matlab/blob/main/VALIDATION.md), MIT license, [first GitHub CI record](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/validation/github-actions-first-run.json), published repository and project page | [v0.5.0 published](https://github.com/tanjunkai2001/adp-matlab/releases/tag/v0.5.0) on 2026-09-08 |
| v0.6: FxT-CL-ACI | Version-pinned migration of the maintainer’s existing code | Legacy result retained; equation map; feature-gradient checks; history-stack/rank behavior; learning-clock semantics; new/old comparison | Next implementation |
| v0.7: constrained execution | One complete PPC or CBF control experiment | Nominal/filtered/applied inputs recorded; feasibility and constraint margins; learning identity checked with the executed input | Planned |
| v0.8: robot bridge | One offline MATLAB/Simulink robot experiment | Units, sampling and hold behavior; comparable trajectories and control commands; solver/model versions recorded | Planned |

These are ordered outcomes, not promised calendar deadlines. Hardware experiments remain a separate step after the offline robot comparison.

## Small tasks suitable for the first issues

Completed on 2026-09-08: the [first Linux CI run](https://github.com/tanjunkai2001/adp-matlab/actions/runs/34177624955) passed the repository checks and 102/102 MATLAB tests on Ubuntu 24.04 with R2025b Update 6. The [run record](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/validation/github-actions-first-run.json) and [per-test results](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.0/docs/validation/github-actions-tests.csv) preserve this code-level check; full paper experiments on another machine remain separate work.

| Suggested issue | Expected contribution | Done when |
|---|---|---|
| Try the first-use guide on a second machine | Improve the new-user experience | A new user runs the baseline from the source package without historical files |
| Reproduce one Koopman paper table | Narrow the gap between the current variant and the original experiment | Original settings are documented, unavailable details stated, and original/new metrics compared |
| Expand the PINN training comparison | Add a larger-network or repeated-training record | Exact configuration, seeds, training budget, held-out residual and closed-loop outcomes are saved |
| Migrate one FxT-CL-ACI scenario | Connect the project to the maintainer’s original work | Legacy and new implementations are compared under the same inputs and settings |

Each new algorithm needs one complete experiment before a common module is extracted. Avoid empty framework classes, parallel registry lists or a large collection of unvalidated examples.
