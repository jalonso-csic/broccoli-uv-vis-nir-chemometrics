# broccoli-uv-vis-nir-chemometrics

Reproducible MATLAB pipelines for UV-VIS-NIR reflectance spectroscopy preprocessing, modelling, interpretability, and decision support in broccoli by-product datasets.

## Overview

This repository contains MATLAB workflows developed for chemometric analysis of broccoli by-product datasets acquired by UV-VIS-NIR reflectance spectroscopy across the 250-1800 nm range. The code is organised by analytical objective and covers univariate factorial inference, spectral structure analysis, nested cross-validation partial least squares regression, VIP stability assessment, and within-domain prioritisation.

The repository is structured to support reproducibility, auditability, and transparent manuscript-to-code traceability.

## Repository structure

```text
broccoli-uv-vis-nir-chemometrics/
├── README.md
├── LICENSE
├── data/
│   └── Matriz_Brocoli_Sin_N.xlsx
└── scripts/
    ├── 01_obj1_univariate_factorial_inference/
    │   ├── BRC00_Obj1_FullSupplementPack_v1.m
    │   └── README.md
    ├── 02_obj2_spectral_structure/
    │   ├── BRC_obj2_Section32_SpectralStructure_run_v1.m
    │   └── README.md
    ├── 03a_obj3_plsr_4preproc_comparison/
    │   ├── BRC06_Obj3_Tier1_2_PLSR_NestedCV_4PreprocCompare_v1.m
    │   └── README.md
    ├── 03b_obj3_tier3_screening_sg1_vs_sg2/
    │   ├── BRC06c_obj3_Tier3_PLSR_NestedCV_SNV_SG1st_vs_SG2nd_v1.m
    │   └── README.md
    ├── 04_obj4_vip_stability_and_band_export/
    │   ├── BRC07_obj4_VIPStability_SelectedTiers_FigsAndBands_SNV_SG2nd_v1.m
    │   └── README.md
    └── 05_obj5_within_domain_prioritisation/
        ├── BRC10_obj5_Prioritisation_v1.m
        └── README.md
```

## Data

The repository includes one curated input matrix:

- `data/Matriz_Brocoli_Sin_N.xlsx`

This matrix is the main input used by the objective-specific scripts. It contains:
- factor columns describing the experimental structure,
- spectral variables named as `nm_*`,
- Tier 1, Tier 2, and Tier 3 response variables used across the workflows.

## Objectives

### Objective 1

Univariate factorial inference for Tier 1, Tier 2, and Tier 3 variables using Type III analysis of variance, partial effect sizes, and false discovery rate correction.

### Objective 2

Spectral structure analysis, including mean spectral profiles, principal component analysis, and permutation-based multivariate factorial inference in spectral space.

### Objective 3a

Repeated nested cross-validation partial least squares regression comparison across four preprocessing configurations for Tier 1 and Tier 2 endpoints.

### Objective 3b

Tier 3 screening using repeated nested cross-validation partial least squares regression under selected preprocessing strategies.

### Objective 4

VIP stability analysis and operational band export based on raw VIP outputs generated in Objective 3.

### Objective 5

Within-domain prioritisation and decision support across Part x Maturity combinations using robust standardisation, percentile profiling, composite scoring, and redundancy auditing.

## Requirements

The scripts were developed for MATLAB and rely on standard MATLAB functionality together with toolbox features used in chemometric and statistical workflows.

Depending on the script, required functionality may include:
- `readtable`, `writetable`, `writecell`
- `pca`
- `plsregress`
- `cvpartition`
- `dummyvar`
- `anovan`
- `sgolay`
- standard figure export functions

A working MATLAB installation with the relevant Statistics and Machine Learning Toolbox functionality is recommended.

## How to use

Each objective is self-contained in its own folder under `scripts/`. The recommended workflow is:

1. Clone or download the repository with the `data/` folder intact.
2. Open MATLAB in the repository root or in the relevant objective folder.
3. Review the user-editable parameters at the top of the target script.
4. Run the script for the desired objective.

Examples:

```matlab
BRC00_Obj1_FullSupplementPack_v1
```

```matlab
BRC06_Obj3_Tier1_2_PLSR_NestedCV_4PreprocCompare_v1
```

Detailed script-specific instructions are provided in the `README.md` file inside each objective folder.

## Outputs

The scripts write objective-specific outputs to local output folders such as:

- `Objetivo_1`
- `Objetivo_2`
- `Objetivo_3a`
- `Objetivo_3b`
- `Objetivo_4`
- `Objetivo_5`

Depending on the workflow, outputs may include:
- Excel workbooks,
- MAT files,
- PNG figures,
- FIG files,
- log files,
- ranking summaries,
- stable-band exports,
- prediction books,
- raw VIP exports.

Generated outputs are not intended to be version-controlled in this repository unless explicitly curated for release.

## Reproducibility notes

This repository is organised to preserve clear links between:
- the input matrix,
- the MATLAB scripts,
- the objective-specific outputs,
- and the manuscript workflows they support.

Several scripts preserve original variable names from the input matrix and assume specific header conventions. Users should therefore avoid renaming columns unless the corresponding script logic is updated accordingly.

Some workflows depend on outputs generated by earlier objectives. In particular:
- Objective 4 depends on raw VIP exports generated in Objective 3.

## License

This repository is distributed under the MIT License. See `LICENSE` for details.

## Citation

If you use this repository, please cite the associated manuscript and the corresponding repository release record, if available.

## Contact

Jesús Alonso
