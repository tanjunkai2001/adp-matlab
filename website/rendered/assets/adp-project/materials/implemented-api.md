# Implemented APIs and paper-method entry points

v0.4.1 has a preserved two-state LQ baseline and seven standalone paper-method packages. They retain native mathematical/data contracts. This page lists the shared selection/test functions first, then the unchanged baseline API.

| Entry | Actual contract |
|---|---|
| check_environment() | Read-only installed-product report per method; no simulations or license checkout. |
| adp_catalog() | Reads IDs, native functions, directories, training flags and products from registry/reproductions.json. |
| demo_reproductions() | Lists baseline + seven methods without executing a demo. |
| demo_reproductions(method,varargin) | Calls exactly the selected native function below, forwarding inputs and outputs; restores path/RNG/working directory on success or error. |
| run_tests() | Original 43 baseline tests plus 3 repository entry/environment tests. |
| run_all_tests('list') | Discovers direct test*.m files in the baseline tests folder and the seven method folders; does not execute test setup or training. |
| run_all_tests() | Runs all discovered local suites; fails if any result is failed/incomplete. No full neural training is run. One PINN replay test performs two single Adam updates. Safe PINN tests cover zero-update evaluation and injected training failures after one completed update. Small non-neural simulations are also included. |

| ID | Native signature | Dependency / current boundary |
|---|---|---|
| baseline | [result,runDir]=demo_integral_pi(options) | Base MATLAB/JVM; options.saveOutputs, outputRoot, runId |
| koopman_l4dc2025 | [result,runDir]=demo_koopman(options) | Base MATLAB; options.saveOutputs/config/runId/outputRoot; defaults to runs/koopman_l4dc2025; declared paper variant |
| meanfield_lqg2025 | report=demo_meanfield_lqg2025(outputDirectory,cfg) | Base MATLAB; default 100-path experiments. Native run_verified_meanfield adds 4000-path precision and independent-fit uncertainty. |
| qlearning_tac2023 | [result,runDir]=demo_qlearning_tac2023(outputRoot) | Control System Toolbox; full matrix Q equation, original data initialization variant |
| pinn_infinite_horizon2025 | [result,runDir]=run_pinn_reproduction(mode,outputDirectory) | Deep Learning Toolbox; reduced/smoke/quartic; invokes actual neural training. Five independent tests now cover HJB, derivatives and terminal continuation; saved full training diagnostics remain separate. |
| safe_pinn_icml2025 | [result,runDir]=demo_safe_pinn(outputRoot,iterations) | Deep Learning Toolbox; invokes reduced neural training. Reduced and author-checkpoint rollouts both retain safety/budget violations; conditional calibration is reported separately. |
| robust_koopman2026 | [result,runDir]=demo_robust_koopman(options) | Base MATLAB; defaults to runs/robust_koopman2026; 8 recorded tests; sample-fit error bounds fail on 25.55% of held-out points, so no robust certificate is asserted. |
| bias_pi_automatica2026 | [result,runDir]=demo_bias_pi(outputDirectory,cfg) | Defaults to local-multistart pendulum with discounted bootstrap; cfg.example='arm' selects arm. Omitted output directory creates a new runs/ folder. Base MATLAB learner; arm LQR comparison uses Control System Toolbox. |

The native functions remain directly callable after adding their own method folder. The unified entry does not change their data layouts, cost half factors, checkpoint formats, model knowledge, or output locations. See registry/reproductions.json and each full-text card. No default method is chosen, preventing an accidental training run from a bare discovery call.

`demo_safe_pinn` saves a completed evaluation to `result.mat`, `metrics.json` and `training.csv` before asserting held-out improvement and terminal accuracy. If either check fails, it prints the saved directory and throws the original assertion; no new `[result,runDir]` values are returned. Load `result.mat` from the printed directory to inspect it. Files being present does not establish acceptance.

During training, after `dlfeval` returns the batch loss and gradient, a guarded block checks their finiteness, performs the Adam update and checks its proposed parameters and moments. A failure in this block saves `training-failure.mat` containing `failureState`, prints the directory and rethrows the original error. The saved network, Adam moments and history describe the last numerically finite completed state; failed-batch diagnostics and iteration counters are separate. This does not return a completed `result` or provide automatic continuation. See the [Safe-PINN guide](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/safe_pinn_icml2025/README.md) for loading examples.

The safe-PINN author weights are an external asset. `[net,parity]=load_author_boat(weightFile)` loads a converted MATLAB file and checks independent reference values/gradients; raw `.pth` files, author weights and conversion tools are not bundled. `result=evaluate_boat_model(net,outputDirectory,comparisonFile)` requires a saved `demo_safe_pinn` result with `result.heldoutInputs` and `result.testInitial`. It reuses those candidates and chooses budgets with the supplied network. Use `fullfile(runDir,'result.mat')` from a new run or an existing compatible result, and a fresh `tempname` output directory for every evaluation. `audit=calibrate_boat(net,outputDirectory)` instead draws a separate threshold-selection and conditional-audit sample; create its new directory before calling. Both paths require Deep Learning Toolbox. The [Safe-PINN guide](https://github.com/tanjunkai2001/adp-matlab/blob/main/reproductions/safe_pinn_icml2025/README.md) gives the two runnable workflows and separates candidate, executed-trajectory and conditional-audit counts. `demo_reproductions('safe_pinn_icml2025',...)` calls the reduced trainer.

## Preserved CT integral-PI baseline

These signatures describe only the two-state LQ example. They are not universal interfaces for the standalone papers or planned nonlinear/game/constrained modules.

| Function | Contract |
|---|---|
| `[phi,dphi]=adp.basis.quadratic2(x)` | Column x of length 2; phi is 3×1 and dphi is 3×2. phi=[x1²,2x1x2,x2²]'. |
| `plant=adp.models.doubleIntegrator()` | Simulator truth, dimensions and quadratic cost. The learner is not passed this struct; the analytic comparison belongs to the example. |
| `trajectory=adp.sim.rollout(plant,K,config)` | Frozen continuous feedback, explicit ODE tolerances/output times, input channels and integrated cost. Rejects unsupported execution modes. |
| `batch=adp.sim.collectBatch(plant,K,config)` | Independent initial states, one fixed policy, retained raw trajectories, Phi/y, target/behavior policy stamps, `inputMatrix`, `costContract` and integration provenance. |
| `[value,diagnostics]=adp.learn.fitValue(batch,options)` | SVD least squares; explicit rank/condition rejection, residuals and symmetric P. |
| `learning=adp.learn.integralPI(collector,B,R,config)` | On-policy evaluation then known-B greedy improvement; final P/K refer to the same evaluated policy. |
| `runDir=adp.io.saveRun(result,outputRoot,runId)` | Named result/config/summary; rejects an existing run directory. See function help for optional arguments. |
| `manifest=adp.io.sealRun(runDir,sourceRoot)` | SHA-256 of run artifacts and source .m files, with no overwrite. Requires standard MATLAB JVM. |
| `report=adp.io.verifyRun(runDir,sourceRoot)` | Checks manifest schema, required artifacts, record paths/bytes/hash and inventory; does not recompute numerical results or authenticate the unsigned manifest. |

`collector(K)` is the learner's data interface. In this example it closes over the simulator, but the learner itself cannot access A through its arguments. It knows B/R and requires a matching declared cost/input-channel contract. When raw trajectories are attached, it checks recorded input channels, endpoints, costs and regression consistency; without them, it can only check the declared batch interface. This is a modular information contract, not protection against a deliberately dishonest collector.

For the integral identity, data rows are `Phi(i,:)=phi(x_start)'-phi(x_end)'` and `y(i)=integral(stageCost)`. With w=[P11;P12;P22], the equation is `Phi*w=y`. The value fit's least-squares residual has the opposite sign to `V(end)-V(start)+integral(cost)`; norms agree, signed labels must retain the convention.

`relativeRankTolerance` applies to the largest singular value of the unscaled regression matrix. `conditionLimit` controls rejection. `diagnostics.accepted=true` means these numerical fit checks passed; it does not assert that arbitrary supplied data satisfy a Bellman identity. The current example tests residuals and the analytic reference independently. No implicit column scaling, regularization, pinv fallback or basis enlargement is performed.

`outputTimes` is the requested ODE output grid. It is not the controller sample time. All four input channels are equal in this example because there is no exploration, filtering, saturation or delay. An extension that changes any of these facts needs its own mathematical data contract and tests.

The analytic `P*`/`K*` is an independent check for this LQ problem. General nonlinear systems require a different admissibility/convergence argument; reusing this code does not transfer the LQ guarantee.

The baseline carries `integralSource=ode_augmented_state`, `quadratureRule=adaptive_ode45_augmented_cost_state` and an empty `integrationErrorBound` because no proved quadrature bound is supplied. Recorded-sample consistency does not certify between-sample behavior or a deliberately rewritten dataset. Final field names and rejection rules are documented in the function help and tested in tests/testNumericalContracts.m.

`costContract` declares `type=quadratic_no_half`, Q, R and `discountRate=0`; `inputMatrix` must equal the learner’s known B. The collector’s R must equal the greedy improvement R. Attached `stageCost` samples must agree with the declared quadratic cost. These checks prevent ordinary configuration mismatch; they do not recover unknown Q/B/R from data.

## Bias-PI native data functions

`bp_collect(dynamics,behavior,stateCost,x0,cfg)` records independent continuous windows. `data.x` is n×nodes×windows, `data.u` is m×nodes×windows, and t/q are 1×nodes×windows. Inputs saved in u are the actual behavior inputs.

`bp_regression(data,spec,W,cPrevious,gamma,mode)` returns A/y and integral diagnostics. Modes are `bias` for Eq43 and `discounted` for Eq48. `spec` supplies phi/psi/R/stateCost/checkX, without model callbacks. W is nActorBasis×nInput, policy is W'*psi and c is a column. `bp_solve(A,y,cfg)` returns coefficients and SVD/rank diagnostics. `bp_learn(data,spec,cfg)` reuses the fixed batch and returns full iteration history, coefficient stopping status and current/next policies.

`bp_pendulum_config` returns [cfg,spec]; `bp_arm_config(overrides)` returns [plant,spec,cfg]. Plant truth is used only for acquisition and evaluation. The paper's single-initial data experiment is selectable via cfg.collectionMode='single_trajectory' for pendulum or cfg.dataMode='paper_initial' for arm; consult the native config and RESULTS for the exact recorded variants.
