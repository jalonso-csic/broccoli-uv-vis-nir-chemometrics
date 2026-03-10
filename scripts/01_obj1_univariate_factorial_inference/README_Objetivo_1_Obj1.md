# Objective 1 (Obj1) — Univariate factorial inference pack (Type III ANOVA)

**Manuscript mapping:** Section **3.1** + first Supplementary block (**Fig. 1**, **Fig. S1/S2**, **Tables S1–S3**)

This Objective 1 (Obj1) pack provides an **audit‑ready** univariate factorial inference workflow for **functional endpoints** and **chemical descriptors** in the broccoli dataset. It runs **Type III ANOVA** per response under the fixed factorial model (**Part**, **Maturity**, **N₂**, and all **two‑way interactions**), computes **partial eta‑squared (ηp²)** effect sizes, and exports publication‑ready tables and figures.

> **Implementation:** Obj1 is executed via two MATLAB functions:
> 1) Tier 1–2 endpoints (functional + class aggregates)  
> 2) Tier 3 metabolites (supplementary pack)

---

## 1) What Obj1 produces (deliverables)

- **Fig. 1** — ηp² heatmap across all factorial terms for **Tier 1–2 endpoints**
- **Table S1** — wide ηp² matrix (endpoints × terms) for Tier 1–2
- **Table S2** — BH–FDR adjusted **q‑values** corresponding to Table S1
- **Fig. S1/S2** — compact ηp² heatmap for **Top‑N** metabolite variables (Tier 3)
- **Table S3** — **Top‑K metabolites per factorial term** (ranked by ηp²)
- **Supplementary Excel** — full metabolite‑level ANOVA outputs (incl. p and q)

---

## 2) Input requirements

A single Excel workbook is required (default name used in the scripts):

- **Data matrix sheet** (default: `Matriz`)
  - Must contain factor columns and response columns.
- **Tier 1** sheet
  - Varname + label (primary functional endpoints).
- **Tier 2** sheet
  - SUM_* varname + English label (chemical‑class aggregates).
- **Tier 3** sheet
  - Varname + label (metabolite‑level variables).

### Required factor columns (name variants accepted)

- **Part:** `Parte` or `Part`
- **Maturity:** `Maduracion` / `Maduración` / `Maturity`
- **N₂:** `Aplicacion_N2` / `Aplicación_N2` / `N2` (and close variants)

---

## 3) Output structure (single root)

All outputs are written under a **single root** folder located where you run MATLAB:

```text
<PWD>/Objetivo_1/
  results/
    Obj1-FactorialDrivers_Tier1_Tier2/
      Obj1-FactorialDrivers_Tier1_Tier2.xlsx
      figures/
        Obj1-Fig1_eta2p_heatmap_Tier1_Tier2.fig
        Obj1-Fig1_eta2p_heatmap_Tier1_Tier2.png
      logs/
        Obj1-Tier12_run_config.txt
    Obj1-Tier3_SupplementaryPack/
      Obj1-Tier3_SupplementaryPack.xlsx
      figures/
        Obj1-FigS2_Tier3_eta2p_heatmap_top30.fig
        Obj1-FigS2_Tier3_eta2p_heatmap_top30.png
      logs/
        Obj1-Tier3_run_config.txt
```

> **Numbering note:** the metabolite heatmap file may be labelled `FigS2` even if cited as **Fig. S1** in the manuscript. Align manuscript numbering later during editorial passes; do not treat filenames as the numbering authority.

---

## 4) How to run (MATLAB)

### 4.1 Tier 1–2 endpoints (functional endpoints + chemical‑class aggregates)

Run:
```matlab
BRC01_Obj1_FactorialDrivers_Tier1_Tier2_recover_v6();
```

Ensure output root is unified (inside the script):
```matlab
OUTROOT = fullfile(pwd, "Objetivo_1");
```

### 4.2 Tier 3 metabolites (supplementary pack)

Run:
```matlab
BRC03_Obj1_Tier3_SupplementaryPack_v1();
```

Also set:
```matlab
OUTROOT = fullfile(pwd, "Objetivo_1");
```

> If you maintain a wrapper function that calls both scripts, keep it as the public entry point and treat the two scripts as internal modules.

---

## 5) Methods implemented (audit notes)

### 5.1 Usability screening (per response variable)

Complete‑case evaluated per endpoint (`isfinite` only). Retain if all criteria are met:

- `N_nonmissing ≥ MIN_N_NONMISS` (default 20)
- `missing_frac ≤ MAX_MISSING_FR` (default 0.30)
- `variance > MIN_VARIANCE` (default 0; strict)

### 5.2 Fixed factorial model (Type III ANOVA)

For each retained response `y`:

```text
y ~ Part + Maturity + N2 + Part×Maturity + Part×N2 + Maturity×N2
```

Type III SS (`sstype = 3`) is used. Partial eta‑squared:

```text
ηp² = SS_term / (SS_term + SS_error)
```

### 5.3 Multiple testing correction (BH–FDR)

- **Tier 1–2:** BH–FDR **within Tier 1 and within Tier 2 separately**, across all tests (endpoints × 6 terms).
- **Tier 3:** BH–FDR across all tests in Tier 3 (metabolites × 6 terms).

Only finite p‑values are used (NaNs excluded before computing *m*).

---

## 6) Outputs (tables) and what they correspond to

### Tier 1–2 Excel (`Obj1-FactorialDrivers_Tier1_Tier2.xlsx`)

- `Tier1_candidates`, `Tier2_candidates`: screening diagnostics (n, missing_frac, variance, retain)
- `Retained_endpoints`: final endpoint list used for Fig. 1
- `ANOVA_Tidy`: long ANOVA outputs (SS, DF, MS, F, p, ηp²)
- `ANOVA_Wide_eta2p`: wide ηp² matrix (**Table S1 backbone**)
- `ANOVA_Wide_q`: wide q‑value matrix (**Table S2 backbone**)

### Tier 3 Excel (`Obj1-Tier3_SupplementaryPack.xlsx`)

- `Metabolite_dictionary`: varname, label, `Family_auto` (ordering aid only)
- `Usability_screen`, `Retained_metabolites`: screening diagnostics
- `ANOVA_Tidy`: full metabolite‑level ANOVA outputs
- `ANOVA_Wide_eta2p`, `ANOVA_Wide_q`: metabolite matrices (ηp² and q)
- `S3_Top10_byTerm`: **Top‑K per term** (**Table S3**)

---

## 7) Troubleshooting

- **Missing variables error:** verify Tier 1/2/3 listed varnames exist as columns in the data matrix sheet.
- **Factor column not found:** rename factors to an accepted variant (see Section 2).
- **Few retained metabolites:** inspect `Usability_screen` to check whether exclusions are due to missingness or **zero variance**.
- **Heatmap labels too long:** edit `getAbbreviation()` rules or shorten the Tier 3 label field.

---

## 8) Repo hygiene (recommended)

- Keep paths **relative** (avoid local drive letters).
- Do not commit large intermediate outputs unless you want to ship example results.
- For figures, keep **`.fig` + `.png`** as the canonical pair (PDF optional).

