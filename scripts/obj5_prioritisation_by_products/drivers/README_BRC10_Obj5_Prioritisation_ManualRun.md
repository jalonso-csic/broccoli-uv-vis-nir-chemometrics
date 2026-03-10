# BRC10_Obj5_Prioritisation_ManualRun.m

## Purpose (Objective 5 — within-domain prioritisation)

This MATLAB script implements **Objective 5**: a **within-domain decision-support prioritisation** of experimental combinations in the **Pathernon × Ultrasonido (UAE)** core subset.  
It ranks combinations using a **composite score built from percentile ranks (0–1)** computed on robust group summaries, and produces **figures (.fig + .png)** plus an **Excel compilation** for reporting and audit.

> Note: **`Extraction_yield` is intentionally excluded** from all logic in this script.

---

## What the script does (high-level)

1. **Loads the master matrix**
   - File: `Matriz_Brocoli_SUM_1nm_ASCII.xlsx`
   - Sheet: `Matriz`
   - Preserves original variable names (`VariableNamingRule = 'preserve'`).

2. **Detects factor columns robustly**
   - Tries common Spanish/English header variants for:
     - Cultivar (`Variedad` / `Variety` / `Cultivar`)
     - Extraction (`Extraccion` / `Extracción` / `Extraction`)
     - Part (`Parte` / `Part`)
     - Maturity (`Maduracion` / `Maduración` / `Maturity`)
     - N₂ application (`Aplicacion_N2` / `Aplicación_N2` / `N2` / `Nitrogen`)

3. **Filters the core domain**
   - Keeps only rows where:
     - `Cultivar == "Pathernon"`
     - `Extraction == "Ultrasonido"`

4. **Builds an indolic marker index (Tier-3 derived)**
   - Creates `Indolic_marker_index_T3` **only if missing**, as:
     - `Glucobrassicin + Methoxyglucobrassicin_1 + Methoxyglucobrassicin_2`
   - Requires those three columns to exist if the index is requested.

5. **Translates factor levels to English labels**
   - Part → `Leaf`, `Inflorescence`, `Stem`
   - Maturity → `Bud`, `Commercial`, `Over-mature`
   - N₂ → `Yes` / `No`
   - Combination label: `Part | Maturity | N2`

6. **Computes robust summaries per combination**
   - Robust Z-score per row (median + MAD; IQR fallback).
   - Groups by `Part | Maturity | N2`.
   - Computes **group medians** for:
     - Raw values (non-redundant criteria)
     - Robust Z values (non-redundant criteria)

7. **Computes composite prioritisation scores**
   - **Score_Z (audit):** weighted average of group-median robust Z
   - **Score_PCTL (primary ranking):** weighted average of **percentile ranks** of group-median robust Z, per criterion (0–1)

8. **Generates figures**
   - **Figure 1:** Criterion profile heatmaps split by N₂ (No vs Yes), showing percentile ranks (0–1)
   - **Figure 2:** Horizontal bar ranking using composite percentile score
   - **Figure 3:** Redundancy audit (Spearman correlation heatmap on full criteria set)

9. **Exports Excel**
   - Single workbook with ranking tables + redundancy matrix + settings.

---

## Criteria used

### Full set (for redundancy audit)
`CRIT_FULL` includes:
- `Total_phenolics`
- `DPPH`
- `ABTS`
- `Antihypertensive_act.`
- `SUM_GSL_indolic`
- `SUM_Amino_acids`
- `SUM_GSL_total`
- `Indolic_marker_index_T3` (computed if needed)

### Non-redundant set (for prioritisation score)
`CRIT_NONRED` includes:
- `Total_phenolics`
- `DPPH`
- `ABTS`
- `Antihypertensive_act.`
- `SUM_GSL_indolic`
- `SUM_Amino_acids`

Weights are **equal by default** (`WEIGHTS = ones(...)`), and normalised internally.

---

## Inputs required

### Excel matrix
- `Matriz_Brocoli_SUM_1nm_ASCII.xlsx`
- Sheet: `Matriz`

### Required factor columns (headers can vary)
The script searches for these factors using multiple candidate names:
- Cultivar: `Variedad` / `Variety` / `Cultivar`
- Extraction: `Extraccion` / `Extracción` / `Extraction`
- Part: `Parte` / `Part`
- Maturity: `Maduracion` / `Maduración` / `Maturity`
- N₂: `Aplicacion_N2` / `Aplicación_N2` / `N2` / `Nitrogen`

### Required response columns (at least the non-redundant set)
Must include the columns listed in `CRIT_NONRED`.  
If `Indolic_marker_index_T3` is not already present and is needed, the script requires:
- `Glucobrassicin`
- `Methoxyglucobrassicin_1`
- `Methoxyglucobrassicin_2`

---

## Outputs (written to `./Objetivo_5/`)

### Figures (.fig + .png)
- `Fig_obj5_CriterionProfile_ByN2_PCTL_Ordered.fig`
- `Fig_obj5_CriterionProfile_ByN2_PCTL_Ordered.png`
- `Fig_obj5_Ranking_CompositePCTL.fig`
- `Fig_obj5_Ranking_CompositePCTL.png`
- `Fig_S_obj5_RedundancyAudit.fig`
- `Fig_S_obj5_RedundancyAudit.png`

> PNG export uses `exportgraphics(..., 'Resolution', 300)` inside `saveBoth()`.

### Excel workbook
- `obj5_Prioritisation_Summary.xlsx`
  - `Ranking_All`: full ranking table
  - `Top_<N>`: top-N subset (N is automatically capped at available rows)
  - `Redundancy_Rho`: Spearman correlation matrix of `CRIT_FULL`
  - `Settings`: cultivar, extraction, and generating script name

---

## Key parameters to edit

In the **USER PARAMETERS** section:
- `CULTIVAR_CORE` (default `"Pathernon"`)
- `EXTRACTION_CORE` (default `"Ultrasonido"`)
- `TOPN_PROFILE` (default `15`)
- `RHO_THRESHOLD` (default `0.85`; used in the redundancy audit title)
- `CRIT_FULL`, `CRIT_NONRED`, `WEIGHTS`

---

## How to run

1. Place the script in your working folder (recommended: ASCII path).
2. Ensure `Matriz_Brocoli_SUM_1nm_ASCII.xlsx` is in the same folder (or update `INPUT_XLSX`).
3. Run:

```matlab
run('BRC10_Obj5_Prioritisation_ManualRun.m')
```

All outputs will be created in:
- `./Objetivo_5/`

---

## Implementation notes (audit-friendly)

- **Robust standardisation:** `robustZ()` uses median + MAD (with IQR fallback) to reduce sensitivity to outliers.
- **Grouping:** combinations are built from translated factor labels: `Part | Maturity | N2`.
- **Ranking score:** the primary score is **percentile-based** (0–1), improving comparability across criteria with different units.
- **Redundancy audit:** Spearman correlation on robust Z values across the full criteria set (`CRIT_FULL`).
- **Reproducibility:** no stochastic modelling is used; results are deterministic given the same input matrix.

---

## Troubleshooting

- **“Missing required factor columns”**
  - Check the headers in the Excel sheet and ensure cultivar/extraction/part/maturity/N₂ columns exist.
- **“Core subset is empty”**
  - Confirm the exact text values for cultivar and extraction match `CULTIVAR_CORE` / `EXTRACTION_CORE`.
- **“Tier-3 indolic compounds not found…”**
  - Ensure the three indolic Tier-3 columns are present if `Indolic_marker_index_T3` is used.
