# BRC06c — Obj3 Tier 3 screening — PLS-R nested CV (SNV+SG 1st vs 2nd)

This script runs **Objective 3 (Tier 3 screening)** using **repeated nested CV PLS regression (PLS‑R)** to benchmark **two spectral preprocessing strategies**:

- **SNV + Savitzky–Golay 1st derivative** (poly=2, frame=11, Δ=1 nm)
- **SNV + Savitzky–Golay 2nd derivative** (poly=2, frame=11, Δ=1 nm)

All outputs are written to **`./Objetivo_3b/`**.

---

## What the script does

1. **Loads the Excel matrix** with headers preserved.
2. **Detects factor columns** robustly (Spanish/English variants).
3. **Filters the core subset**:
   - `CULTIVAR_CORE = "Pathernon"`
   - `EXTRACTION_CORE = "Ultrasonido"`
4. **Extracts spectra X** from columns named `nm_<integerWavelength>`.
5. **Defines Tier3S automatically**:
   - all **numeric** variables that are **not**:
     - spectral (`nm_*`)
     - factor columns
     - Tier 1 variables
     - Tier 2 variables
   - then applies **Y QC** (min n, max NaN fraction, non-zero variance)
   - optional exclusion via `EXCLUDE_REGEX`
6. For each Tier3S endpoint, runs **nested CV PLS‑R** under both preprocessing configurations and exports metrics (and optionally predictions/VIP).

---

## Validation design

- Outer CV: **K=5**, repeated **R=50**
- Stratification: **Maturity × N2**
- Guardrail (enabled): every outer TRAIN must contain all **Part** levels
- Inner CV: **Kinner=4**, LV selection by **min RMSE**
- LV cap: **min(15, nTrain−2, p)**

---

## Requirements

- MATLAB with:
  - Statistics and Machine Learning Toolbox (`plsregress`, `cvpartition`)
  - Signal Processing Toolbox (`sgolay`)

Default input:
- `INPUT_XLSX = Matriz_Brocoli_SUM_1nm_ASCII.xlsx`
- `SHEET_NAME = Matriz`

---

## Outputs (in `Objetivo_3b/`)

Tier3S definition:
- `OBJ3S_Tier3S_Included.xlsx`
- `OBJ3S_Tier3S_Skipped.xlsx`

Per config (`SNV_SG1st`, `SNV_SG2nd`):
- `OBJ3S_Summary_Tier3S_<Config>.xlsx`
- `OBJ3S_RepeatMetrics_Tier3S_<Config>.xlsx`
- `OBJ3S_Predictions_Tier3S_<Config>.xlsx` *(only if `WRITE_PREDICTIONS=true`)*
- `OBJ3S_VIPraw_Tier3S_<Config>.mat` *(only if `SAVE_VIPRAW=true`)*

Runtime controls:
- `WRITE_PREDICTIONS` (default **false**)
- `SAVE_VIPRAW` (default **true**)

---

## How to run

```matlab
run('BRC06c_obj3_Tier3_PLSR_NestedCV_SNV_SG1st_vs_SG2nd_v1.m')
```

---

## Certainty

📌 Verified: README matches the script parameters and exported filenames.
