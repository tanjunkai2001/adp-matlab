# Contributing to ADP-MATLAB

Useful contributions include clearer explanations, reproducible bug reports, cross-version runs, and a complete numerical method. Use the existing [bug report or method proposal templates](https://github.com/tanjunkai2001/adp-matlab/issues/new/choose) when opening an issue. Start with a proposal when the change adds a new algorithm or changes a mathematical contract.

## Run the current example

Open the repository root in MATLAB and run:

```matlab
check_environment();
run_tests;
run_all_tests('list');
```

Run `run_all_tests` when your change affects shared behavior or a method implementation. The full suite needs Control System Toolbox and Deep Learning Toolbox. For prose-only edits, the repository and generated-document checks are sufficient:

```text
python3 tools/check_repository.py --source-only
python3 tools/build_project_docs.py --check
```

## Add one method

1. Copy [`templates/method-intake.md`](https://github.com/tanjunkai2001/adp-matlab/blob/main/templates/method-intake.md) and record the paper version, model, known quantities, time convention, cost, initialization and expected outcome.
2. Put direct MATLAB functions in `reproductions/<method-id>/`. Keep simulation truth out of learner inputs when the method is data-based. Reuse `src/+adp` only when the mathematical contract is the same.
3. Map each implemented equation to a function. State any smaller networks, changed costs, different initialization or modified experiment settings.
4. Add a native demo, README and `test*.m`. Use an independent equation or analytic comparator; do not create tests that only repeat the implementation.
5. Register the method in `registry/reproductions.json`, its paper in `registry/papers.json`, and its human-readable labels in `registry/method-display.json`. Register the algorithm in `registry/algorithms.json`. Demo and test discovery read the registry automatically.
6. Save a new run under `runs/`; record settings, source identity and results. Preserve failed runs when they explain a numerical limitation. Then update the method’s evidence and run `python3 tools/build_project_docs.py`.

The display file contains human-readable labels and copyable usage examples for existing functions. Entry points, dependencies, training flags and test counts belong to the method registry and validation record. Document a run variant in its method README before adding a matching website command; display examples do not define new MATLAB modes. Do not maintain an extra method list inside README or the project page.

## Prepare the pull request

Explain the problem, the resulting behavior and the actual validation. For a scientific implementation include the equation map, comparator, numerical scope and known mismatches. Keep an existing baseline available when changing its scientific meaning.

Do not commit `runs/`, paper PDFs, upstream source archives, personal paths, access tokens or author checkpoints. Small source-generated figures and their CSV data may live in `docs/assets/`. Larger experiment records belong in the versioned artifact bundle described in [ARTIFACTS](https://github.com/tanjunkai2001/adp-matlab/blob/main/docs/ARTIFACTS.md).

## Respect the source

Credit the paper and code sources. Confirm redistribution terms before copying third-party code or weights. A public download is not a software license. Contributions to this repository are provided under its [MIT License](https://github.com/tanjunkai2001/adp-matlab/blob/v0.5.2/LICENSE); preserve any applicable third-party notices.

Discuss technical disagreements with equations and reproducible examples. Review the implementation and evidence, not the contributor.
