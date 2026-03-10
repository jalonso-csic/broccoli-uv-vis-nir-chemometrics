# broccoli-uv-vis-nir-chemometrics

Reproducible MATLAB pipelines for UV-VIS-NIR reflectance spectroscopy preprocessing, modelling, interpretability, and decision support in broccoli by-product datasets.

## Overview

This repository contains MATLAB workflows developed for chemometric analysis of broccoli by-product datasets acquired by UV-VIS-NIR reflectance spectroscopy across the 250-1800 nm range. The code is organised by analytical objective and covers univariate factorial inference, spectral structure analysis, nested cross-validation PLS regression, VIP stability assessment, and within-domain prioritisation.

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
