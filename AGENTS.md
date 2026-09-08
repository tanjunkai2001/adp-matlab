# MATLAB ADP repository conventions

Read README.md, CONTEXT.md, and the relevant method's mathematical contract before editing.

- Use Chinese for explanations; keep MATLAB identifiers precise and English. Preserve existing research baselines. Write corrected scientific variants to a separate version/run.
- Keep functions explicit about configuration and state. Use src/+adp namespaces for shared library functions. Keep paper implementations as small explicit functions in their owned reproductions/<paper>/ folder; do not force unlike mathematical contracts into shared wrappers/classes. Only add required parent folders, and avoid base-workspace/global state in new library code.
- Separate dynamics, stage cost, features, learning, execution and reporting when each carries distinct behavior. Avoid empty interfaces or classes that merely forward arguments.
- Declare CT/DT, affine/nonaffine, discount/horizon, coordinate system, feature dimensions, cost scaling, and learner knowledge. Never expose simulator truth to a supposedly model-free learner by accident.
- Validate analytical feature gradients numerically. Test meaningful invariants: Bellman identities, analytic LQR, rank failure, timing and execution behavior. Match checks to the change.
- Make ODE right-hand sides free of hidden history updates and logging. Continuous adaptation belongs in integrated state; sampled adaptation runs once per declared sample/event.
- Keep target/behavior policy and nominal/filtered/applied input distinct. Changing the execution chain requires rechecking learning identities and certificates.
- Use S=load(...) and named saved variables. Give runs unique directories; do not overwrite results. Save exact config, environment, raw data, diagnostics and source hashes.
- Report failures and unmet rank/feasibility conditions. Do not relabel cached artifacts or skipped experiments as reproduction.
- For a new method, fill templates/method-intake.md and read docs/METHOD_CONTRACTS.zh-CN.md. Distinguish ODE, Ito diffusion, CTMC, physical noise, policy entropy and artificial PDE regularization. Declare V/Q/q/actor-only and initialization; do not require a fictitious critic.
- Mark planned modules as planned. Testing, simulation, artifact validation, paper reproduction and hardware evidence are different outcomes.
- Do not import third-party source into distributable code until its applicable license has been checked. Store source URLs, versions and checksums in registry/.

Repository skills are in .agents/skills/. Use only the skills and references relevant to the requested work. The user's explicit instructions govern task scope.

For the current version, preserve the 43-test baseline and its historical evidence. Use demo_reproductions() and run_all_tests('list') for read-only entry/test discovery. run_all_tests runs local tests, including the Safe PINN demo with zero training updates for a persistence regression; do not launch full PINN retraining merely to check shared documentation. Method demos may still perform non-neural identification/PI/rollouts. Record actual discovered counts rather than copying old totals. Update pending/failed status only from completed evidence, and do not treat a reduced safe-PINN failure as a successful safety result. Changes to root MATLAB files alter the source inventory of future baseline seals; do not rewrite old manifests to make them match.

Use registry/reproductions.json as the single method/dependency inventory; adp_catalog feeds both discovery functions. Put new experiment output in runs/, never in versioned historical evidence/. Current PINN unit tests perform two single Adam updates; a passing test suite does not retrain the saved paper experiments. Keep SOURCE_MANIFEST metadata and historical FILE_MANIFEST records distinct.
