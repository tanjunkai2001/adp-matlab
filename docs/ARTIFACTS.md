# Experiment artifacts

The GitHub source checkout contains MATLAB implementations, tests, method notes and compact validation records. Large MAT/FIG files, full training logs and legacy source snapshots are kept separately.

## Included in the source

| Record | Purpose |
|---|---|
| [Local test summary](validation/matlab-tests.json) and [per-test CSV](validation/matlab-tests.csv) | Actual test outcomes from the prepared source directory |
| [Source hashes](validation/matlab-source-hashes.json) | Identity of the active MATLAB files used in that run |
| [Baseline data](assets/data/baseline-summary.json) | Settings, metrics and CSV data for the README/project-page figure |
| [Paper implementation cards](fulltext) | Equation mappings, reading scope and differences from the papers |

## Editable figures and source data

| Bundle | Contents | Bytes |
|---|---|---:|
| [example-figures.zip](assets/example-figures.zip) | Three recorded examples: editable FIG/PDF/PNG/SVG, redraw script and CSV/JSON data | 2,914,418 |
| [adp-control-hero-source.zip](assets/adp-control-hero-source.zip) | Complete integral-PI figure: editable figure, redraw script and CSV/JSON data | 848,288 |

The bundles contain project-generated figures and data. Their SHA-256 values are recorded in [figure-bundles.json](assets/figure-bundles.json); the three example datasets are identified in [figure-data.json](assets/data/figure-data.json). The source checkout and baseline tests run without unpacking these figure bundles.

## Historical bundle

The maintainer preserves a complete local v0.4.1 bundle, `adp-matlab-reference-v0.4.1.zip` (303,178,754 bytes), SHA-256 `703e32aa23eff3f015a08e11cc1f0c5446de4a56d6d130aff1333b91190989a0`. It includes earlier numerical results and negative outcomes. It has not been uploaded as a public release asset in this preparation step.

Historical links in the public-source notes lead to this inventory instead of an absent local MAT file. Their original relative targets are listed in [historical-link-map.json](../registry/historical-link-map.json). Obtain the corresponding approved release artifact when it becomes available; no fabricated download URL is supplied.

Before attaching a public data bundle, copy the selected numerical records from the frozen archive, remove machine-specific/access-session logs, retain negative outcomes and configurations, and generate a new artifact manifest. Do not edit the frozen original bundle.

## External materials

Publisher PDFs, institutional-library downloads, upstream source archives and author checkpoints are separate materials. They are not included in the GitHub source or the project-page preview download. The paper cards link publisher or author pages for access. See [THIRD_PARTY](../THIRD_PARTY.md) for provenance.

## New experiment outputs

Use a new directory under `runs/`. Keep the exact configuration, data, source version, comparisons and outcome. Include only a compact figure and its source data in Git when useful; larger records belong in the release artifact package.
