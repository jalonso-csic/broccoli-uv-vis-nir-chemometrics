# BRC07 — Objective 4: VIP stability (SNV + SG 2nd derivative) — figures + stable bands export

This script implements **Objective 4**: a **VIP stability** analysis and reporting layer built on top of the **Obj3 VIPraw outputs** (nested CV PLS-R), focusing on a **selected set of Tier 1, Tier 2, and Tier 3S endpoints** under the **SNV + Savitzky–Golay 2nd derivative** preprocessing.

All outputs are written to **`./Objetivo_4/`**.

---

## What the script does

1. **Locates the Obj3 output folder** (`OBJ3DIR`)
   - Uses `OBJ3DIR_MANUAL` if provided.
   - Otherwise tries common relative paths or prompts via GUI.

2. **Orders endpoints within each tier** (Tier 1 / Tier 2 / Tier 3) using Obj3 summary files:
   - Tier 1 summary: `*OBJ3_Summary_Tier1*SG2nd*.xlsx`
   - Tier 2 summary: `*OBJ3_Summary_Tier2*SG2nd*.xlsx`
   - Tier 3S summary: `*OBJ3S_Summary_Tier3S*SG2nd*.xlsx`
   - Sorting metric (descending): `SORT_METRIC_COL` (default `R2_pooled`)

3. **Loads VIPraw MAT files** for SG2nd:
   - Tier 1: `*Tier1*SNV*SG2nd*.mat`
   - Tier 2: `*Tier2*SNV*SG2nd*.mat`
   - Tier 3S: `*Tier3S*SNV*SG2nd*.mat`

4. **Computes VIP stability**
   - Normalisation per model:
     - `VIP_norm = VIP ./ mean(VIP,2)` (so each model has mean VIP = 1)
   - Stability at wavelength λ:
     - `Stability(λ) = proportion of models with VIP_norm(λ) > 1`

5. **Generates outputs**
   - **Figure 1**: heatmap stability map (Tier 1 at top → Tier 3 at bottom)
   - **Figure 2**: line stability profiles for selected Tier 3S indoles
   - **Excel**: stable nm list + stable contiguous regions + endpoint counts

---

## Inputs required

### Obj3 outputs (produced previously)
You must have already run the Obj3 scripts that produce:

- Summary workbooks (`OBJ3_Summary_...xlsx`, `OBJ3S_Summary_...xlsx`)
- VIPraw MAT files (`OBJ3_VIPraw_...SG2nd.mat`, `OBJ3S_VIPraw_...SG2nd.mat`)

If your Obj3 outputs are **not** in a folder named `OBJ3_OUT`, set:

```matlab
OBJ3DIR_MANUAL = "C:\path\to\your\Obj3\outputs";
```

---

## Key parameters

### Endpoint selection
Edit these lists as needed:

- `Tier1_All`
- `Tier2_Sel`
- `Tier3_Sel`

Matching is robust to punctuation differences (`.` vs `_`) via `matlab.lang.makeValidName`.

### Stability and regions
- `STAB_THR` (default `0.70`)
- `MIN_BANDS` (default `25` contiguous bands)

A **stable region** is defined as:
- `stability >= STAB_THR` and
- contiguous run length `>= MIN_BANDS`

---

## Outputs (written to `./Objetivo_4/`)

### Figures
- `Fig_OBJ4_VIPStability_Combined_T1_T2sel_T3sel_SNV_SG2nd.fig`
- `Fig_OBJ4_VIPStability_Combined_T1_T2sel_T3sel_SNV_SG2nd.png` (400 dpi)
- `Fig_OBJ4_VIPStability_Tier3SelLines_SNV_SG2nd.fig`
- `Fig_OBJ4_VIPStability_Tier3SelLines_SNV_SG2nd.png` (400 dpi)

### Excel
- `OBJ4_StableBands_SelectedEndpoints_SNV_SG2nd.xlsx`
  - `StableRegions`: start/end nm, width, band count, mean/max stability, mean/max VIP
  - `StableBands_nm`: nm-level stability + mean VIP
  - `Counts`: number of stable nm, number of regions, maximum stability per endpoint

---

## How to run

1. Ensure Obj3 outputs exist (SG2nd VIPraw and summaries).
2. Optionally set `OBJ3DIR_MANUAL`.
3. Run:

```matlab
run('BRC07_obj4_VIPStability_SelectedTiers_FigsAndBands_SNV_SG2nd_v1.m')
```

Results are written to `Objetivo_4`.

---

## Notes on reproducibility

📌 The script saves figures as **.fig and .png** and exports an Excel band list suitable for operational interpretation or supplementary material.
