# BRC06 — Obj3 (Tier 1 + Tier 2) — PLS-R Nested CV (4 Preprocessing Strategies)

This script performs **audit-ready model comparison** for Objective 3 by benchmarking **four spectral preprocessing configurations** for **PLS regression (PLS-R)** prediction of **Tier 1** (primary functional endpoints) and **Tier 2** (chemical-class aggregates).

It uses **repeated nested cross-validation** and enforces a **shared outer fold plan per response** across all configurations to ensure a **fair, paired comparison**.

---

## What the script does

For each response variable **Y** (Tier 1 list, then Tier 2 list):

1. **Filters the matrix** to the defined core subset:
   - `CULTIVAR_CORE = "Pathernon"`
   - `EXTRACTION_CORE = "Ultrasonido"`

2. **Extracts spectra X** from columns named `nm_<integer>` and sorts by wavelength.

3. **Builds repeated stratified outer folds** (K=5, R=50):
   - Stratification by `Maturity × N2`
   - Optional guardrail (enabled): every outer TRAIN split must include all `Part` levels

4. **Nested PLS-R fitting** for each outer fold:
   - Applies the chosen preprocessing configuration to X
   - Optional column scaling using TRAIN statistics (enabled)
   - Selects latent variables (LVs) using **inner CV** (Kinner=4) with **minimum RMSE**
   - Fits PLS-R on the outer TRAIN, predicts the outer TEST

5. **Exports** pooled predictions and metrics, plus VIP vectors per outer fit.

---

## Preprocessing configurations compared

1. **RAW**  
2. **SNV** (row-wise standard normal variate)  
3. **SNV + SG 1st derivative** (poly=2, frame=11, Δ=1 nm)  
4. **SNV + SG 2nd derivative** (poly=2, frame=11, Δ=1 nm)

---

## Requirements

### MATLAB
- Modern MATLAB recommended (R2020b+).
- Toolboxes:
  - **Statistics and Machine Learning Toolbox** (`plsregress`, `cvpartition`)
  - **Signal Processing Toolbox** (`sgolay`)

### Input Excel matrix
Default in the script:
- `INPUT_XLSX  = 'Matriz_Brocoli_SUM_1nm_ASCII.xlsx'`
- `SHEET_NAME  = 'Matriz'`

The script uses `opts.VariableNamingRule = 'preserve'` so the Excel headers must match exactly.

---

## Expected columns

### Spectral columns
- Must be named: `nm_<integerWavelength>`
- Example: `nm_250`, `nm_251`, …, `nm_1800`

### Factor columns (robust header matching)
The script automatically detects factor columns using `pickVarName()` and supports common **Spanish/English** variants:

- Variety/Cultivar: `Variedad` / `Variety` / `Cultivar`
- Extraction: `Extraccion` / `Extracción` / `Extraction`
- Part: `Parte` / `Part`
- Maturity: `Maduracion` / `Maduración` / `Maturity`
- N2: `Aplicacion_N2` / `Aplicación_N2` / `N2` / `Nitrogen` (and close variants)

### Response variables (Y)
Tier lists are defined in the script and must match the Excel headers exactly:

**Tier 1**
- `Extraction_yield`
- `Total_phenolics`
- `DPPH`
- `ABTS`
- `Antihypertensive_act.`

**Tier 2**
- `SUM_Amino_acids`
- `SUM_N_related`
- `SUM_OrgAcids`
- `SUM_GSL_aliphatic`
- `SUM_GSL_indolic`
- `SUM_GSL_breakdown`
- `SUM_Flavonols`
- `SUM_CQA`
- `SUM_Coumaroyl`
- `SUM_Sinapate_esters`
- `SUM_FA_saturated`
- `SUM_FA_unsaturated`
- `SUM_Oxylipins_oxygenated`
- `SUM_GSL_total`
- `SUM_Phenylpropanoids_total`
- `SUM_Lipids_total`
- `SUM_Phenolics_MS`

---

## Quality control rules for Y

A response variable is **skipped** if any of the following holds:
- `nanFrac > MAX_NAN_FRAC` (default 0.30)
- `nOK < MIN_N_NONNAN` (default 20)
- zero variance in non-missing values

---

## Outputs

All results are written to:

- `./Objetivo_3a/`

### Per tier and per configuration
- `OBJ3_Summary_<Tier>_<Config>.xlsx`  
  Summary metrics (pooled + across repeats).
- `OBJ3_RepeatMetrics_<Tier>_<Config>.xlsx`  
  Metrics per repeat (R=50).
- `OBJ3_Predictions_<Tier>_<Config>.xlsx`  
  Long-format predictions; **one sheet per Y**.
- `OBJ3_VIPraw_<Tier>_<Config>.mat`  
  VIP vectors from each outer model fit (for stability analysis).

### Per tier (all configurations combined)
- `OBJ3_Compare_4CFG_<Tier>.xlsx`  
  Includes:
  - `Summary_AllCFG`
  - `RepeatMetrics_AllCFG`
  - `R2pooled_wide` (if `unstack` succeeds)
  - `RMSEpooled_wide` (if `unstack` succeeds)

---

## How to run

1. Place the script in your MATLAB working directory (or add its folder to the path).
2. Ensure the Excel file is accessible (either in `pwd` or with a full path).
3. Run:

```matlab
run('BRC06_Obj3_Tier1_2_PLSR_NestedCV_4PreprocCompare_v1.m')
```

Outputs will appear in `Objetivo_3a`.

---

## Reproducibility notes

- The repeated outer CV is seeded deterministically via `BASE_SEED` (default 12345) and the repeat index.
- Fold plans are generated **once per Y** and reused across preprocessing configurations (paired comparison).
- LV selection is performed inside each outer TRAIN using inner CV (Kinner=4) and min RMSE.

---

## Interpretation guidance (quick)

- **R2_pooled / RMSE_pooled**: pooled across all repeats and folds (most stable summary).
- **R2_mean ± R2_sd** (and RMSE): variability across repeats (sensitivity to fold realisations).
- **VIPraw .mat**: use for VIP stability / consensus windows across outer fits.

---

## Certainty

📌 Verified: behaviour described above matches the code structure and exports.
