# Objective 2 — Section 3.2 Spectral Structure Reanalysis (UV–VIS–NIR)

**Script:** `BRC_obj2_Section32_SpectralStructure_run_v1.m`  
**Purpose:** Reanalyse Section **3.2** (spectral structure) in an audit-ready way, generating all **tables and figures** required for the main text and Supplementary Material under a controlled, reproducible pipeline.

This script was designed for a **Q1 manuscript workflow** (Food Control-style reporting): it produces **publication-ready** outputs (`.fig` + `.png`, light background) and a consolidated Excel workbook with **PCA explained variance** and **permutation-based multivariate factorial inference** (Freedman–Lane), including **BH–FDR** correction.

---

## 1) What the script does (outputs you can cite in the manuscript)

### Preprocessing configurations (as used in Section 3.2)
- **SNV**
- **SNV + Savitzky–Golay 2nd derivative** (SG poly order = 2; window length = 11; Δλ = 1 nm)

### Analyses
1. **Descriptive spectral plots**
   - Mean spectra by **Part** (main text figure)
   - Mean spectra by **Maturity** and **N₂** (Supplementary figure)
2. **PCA**
   - Score spaces by **Part** (main text figure), and by **Maturity / N₂** (Supplementary)
   - PCA is run on **column-autoscaled X** for comparability across preprocessing configurations.
3. **Permutation-based multivariate factorial test (Freedman–Lane)**
   - Model terms:
     - `Part`, `Maturity`, `N2`,
     - `Part×Maturity`, `Part×N2`, `Maturity×N2`
   - **p-values from permutations**, plus **BH–FDR q-values** within each configuration.
4. **Export of all numeric results**
   - Tables ready to copy into the manuscript (Tables 4–5).

---

## 2) Requirements

- **MATLAB** R2021a+ recommended (works with recent versions; uses standard toolboxes)
- **Toolboxes:** Statistics and Machine Learning Toolbox (for PCA, categorical handling)
- **Input file:** Excel matrix with spectral columns.

---

## 3) Input data format

### Mandatory columns (factor metadata)
The script detects these robustly (case-insensitive / partial match):
- **Part** (e.g., `Parte`, `Part`)
- **Maturity** (e.g., `Maduracion`, `Maturity`)
- **N₂ / water regime** (e.g., `Aplicacion_N2`, `N2`, `Nitrogen`, etc.)

### Spectral columns
- All spectral variables must be named:  
  `nm_250, nm_251, …, nm_1800`  
  (any contiguous range is acceptable as long as columns start with `nm_` and parse as integers)
- The wavelength step should be **uniform** (Δλ ~ 1 nm). The script checks this.

### Optional columns
- `SampleID` (if present; used only for audit/export convenience)

---

## 4) How to run

1. Place the script in your working directory (or add it to MATLAB path).
2. Ensure the input Excel matrix is accessible.
3. Run in MATLAB:

```matlab
BRC_obj2_Section32_SpectralStructure_run_v1
```

### What you will see in the Command Window
- Detected column mapping (Part/Maturity/N₂/SampleID)
- Dataset dimensions (`n`, `p`, wavelength step)
- Permutation test results per term (F, p_perm, effect sizes)
- Export paths and confirmation messages

---

## 5) Key user settings (edit at the top of the script)

Typical parameters:
- `INFILE` : input matrix (e.g., `Matriz_Brocoli_SUM_1nm_ASCII.xlsx`)
- `OUTROOT`: root output folder (must be `Objetivo_2`)
- `SEED`   : RNG seed for reproducibility
- `N_PERM` : number of permutations (e.g., 4999 for final runs)
- SG parameters:
  - `SG_POLY = 2`
  - `SG_WINDOW = 11`

**Note:** `N_PERM` directly controls compute time.

---

## 6) Output structure (all under `Objetivo_2/`)

The script writes everything under a single root to simplify GitHub/Zenodo packaging:

```
Objetivo_2/
├─ Code/
│  └─ BRC_obj2_Section32_SpectralStructure_run_v1.m   (archived copy)
├─ Tables/
│  └─ obj2_section32_outputs.xlsx
├─ Figures/
│  ├─ Fig2_MeanSpectra_Part_SNV_vs_SG1.png/.fig
│  └─ Fig3_PCA_Part_SNV_vs_SG2.png/.fig
└─ Supplementary/
   ├─ FigS2_MeanSpectra_Maturity_N2_SNV.png/.fig
   └─ FigS3_PCA_Maturity_N2_SNV_vs_SG2.png/.fig
```

### Main Excel deliverable
`Objetivo_2/Tables/obj2_section32_outputs.xlsx` includes:
- `Table4_SNV` — factorial inference under SNV (Table 4)
- `Table5_SNV_SG2` — factorial inference under SNV+SG2 (Table 5)
- `PCA_Explained_SNV`, `PCA_Explained_SNV_SG2` — explained variance for reporting PC1/PC2

---

## 7) Reproducibility guarantees

- Fixed RNG seed (`SEED`) ensures **identical p_perm** and derived q-values given the same data.
- All exports are deterministic given the same `INFILE`, preprocessing parameters, and permutation count.
- Figures are exported in **both `.fig` and `.png`** (light background).

---

## 8) Common issues & troubleshooting

### (A) “No spectral columns found”
- Confirm spectral columns are named exactly `nm_<integer>` (e.g., `nm_250`).
- Check that Excel didn’t rename headers on export.

### (B) Unexpected factor levels / wrong df
- Inspect categories:
```matlab
Mat = categorical(string(T.(colMad)));
categories(Mat); countcats(Mat)
```
- Remove accidental duplicates caused by whitespace (e.g., `"M1 "` vs `"M1"`).

### (C) PCA warning: “Columns linearly dependent”
This is usually harmless in high-dimensional spectra (p >> n). PCA still works; the warning typically concerns T² computation. It does **not** invalidate the score space interpretation.

### (D) Dark-looking PNG exports
Ensure the script explicitly sets:
- `figure('Color','w')`
- axes/legend text colours set to black if needed.
If you still see dark UI artefacts, disable the axes toolbar prior to export.

---

## 9) How to cite in the manuscript

In Section 3.2 (Methods or Results cross-reference):
- Preprocessing: SNV; SNV + Savitzky–Golay 2nd derivative (poly=2; window=11; Δλ=1 nm)
- PCA on column-autoscaled spectra
- Permutation-based multivariate factorial inference using Freedman–Lane + BH–FDR within configuration
- Outputs: Tables 4–5 and Figs. 2–3 (plus Supplementary Figs. S2–S3)

---

## 10) Licence / repository notes

- Remove local paths before public release.
- Keep `Objetivo_2/` as the sole output root for clean Zenodo deposition.
- Recommended: add a `manifest` or `analysis_set_retained.csv` if you want to lock the analysis subset explicitly.

---
**Contact / maintainer:** (fill in your author details)
