# 02. Objective 2 — Spectral structure analysis for Section 3.2

## Script
`BRC_obj2_Section32_SpectralStructure_run_v1.m`

## Purpose
This script performs the full Objective 2 reanalysis corresponding to Section 3.2 of the manuscript. It characterizes the spectral structure of the broccoli dataset using a two-factor framework based on **Part**, **Maturity**, and their interaction.

The workflow combines:
- spectral preprocessing,
- descriptive spectral visualization,
- principal component analysis (PCA),
- multivariate factorial inference using a Freedman–Lane permutation framework.

All outputs are written to a single reproducible root directory.

## Analytical scope
The script is designed to evaluate how spectral variation is structured across:
- **Part**
- **Maturity**
- **Part × Maturity**

The analysis is performed on wavelength variables stored as `nm_*` columns in the input matrix.

## Relation to the manuscript
This script supports the analyses reported in **Section 3.2** of the manuscript, including:
- mean spectral profiles,
- PCA score-space visualization,
- supplementary maturity-based spectral plots,
- multivariate permutation-based factorial testing in spectral space.

## Input files

### Required input
The script expects the following Excel file in the working directory:

`Matriz_Brocoli_Sin_N.xlsx`

### Optional input
An optional manifest file may also be used:

`analysis_set_retained.csv`

This manifest is applied only when:
1. `USE_ANALYSISSET_MANIFEST = true`, and
2. the matrix contains a strictly detected `Sample_ID` column.

If these conditions are not met, the manifest filter is skipped automatically.

## Input matrix requirements

### Factor columns
The script detects factor columns automatically.

Accepted names for **Part**:
- `Parte`
- `Part`

Accepted names for **Maturity**:
- columns containing `madur`
- columns containing `matur`

### Sample identifier
Strict detection is used for sample IDs. Accepted exact names are:
- `Sample_ID`
- `SampleID`
- `sample_id`
- `sampleid`

### Spectral variables
Spectral columns must be named exactly as:

`nm_###`

for example:
- `nm_400`
- `nm_401`
- `nm_402`

The script extracts all columns starting with `nm_`, parses the wavelength values, sorts them numerically, and builds the spectral matrix from those variables.

## Default settings

### Core settings
- `TARGET_SCRIPT_NAME = 'BRC_obj2_Section32_SpectralStructure_run_v1.m'`
- `OUTROOT = <PWD>/Objetivo_2`
- `INPUT_XLSX = 'Matriz_Brocoli_Sin_N.xlsx'`
- `SHEET_NAME = ''` (automatic first-sheet selection)

### Manifest settings
- `USE_ANALYSISSET_MANIFEST = true`
- `ANALYSISSET_CSV = 'analysis_set_retained.csv'`

### Permutation settings
- `SEED0 = 123`
- `N_PERM = 4999`

### Savitzky–Golay settings
- `SG_POLY_ORDER = 2`
- `SG_FRAME_LEN = 11`

### PCA export
- `N_PCS_EXPORT = 10`

### Plot style
- `FONT_NAME = 'Times New Roman'`
- `FS_AX = 10`
- `FS_LAB = 12`

## Workflow overview

### 1. Data import
The script reads the Excel matrix safely, using the user-specified sheet or, if empty, the first available sheet.

### 2. Optional manifest filtering
If enabled and applicable, the script filters the matrix using `analysis_set_retained.csv` and matches rows by `Sample_ID`.

### 3. Spectral extraction
All `nm_*` variables are extracted, converted to numeric wavelength values, sorted, and assembled into the raw spectral matrix.

### 4. Factor translation to English
Factor labels are translated automatically into English for plotting and exported tables.

#### Part translation
Typical mappings include:
- `hoja`, `hojas` ? `Leaf`
- `inflorescencia` ? `Floret`
- `tallo` ? `Stem`

#### Maturity translation
Typical mappings include:
- `inmadur*` ? `Immature`
- `comercial`, `commercial`, `óptimo`, `optimo` ? `Commercial`
- `sobre*`, `over*`, `senescent` ? `Overmature`

### 5. Spectral preprocessing
The script computes:
- SNV-normalized spectra,
- SNV + Savitzky–Golay first derivative,
- SNV + Savitzky–Golay second derivative.

Autoscaling is then applied to the SNV and SNV+SG2 matrices for PCA and multivariate inference.

### 6. Descriptive plots
The script generates:
- mean spectra by **Part**,
- PCA score plots by **Part**,
- supplementary mean spectra by **Maturity**,
- supplementary PCA score plots by **Maturity**.

### 7. PCA summary tables
Explained variance is exported for the selected number of principal components.

### 8. Multivariate factorial inference
The script performs a Freedman–Lane permutation-based multivariate factorial test in spectral space for:
- **Part**
- **Maturity**
- **Part × Maturity**

This is executed separately for:
- SNV-preprocessed spectra,
- SNV + SG2-preprocessed spectra.

Benjamini–Hochberg false discovery rate correction is applied to the permutation p-values.

## Output structure
All outputs are written under:

`Objetivo_2/`

The script creates the following subdirectories automatically:

- `Code/`
- `Tables/`
- `Figures/`
- `Supplementary/`

## Output files

### Code archive
- `Code/BRC_obj2_Section32_SpectralStructure_run_v1.m`

The script attempts to archive a copy of itself into the `Code` folder.

### Log file
- `obj2_section32_log.txt`

This file records the console output generated during execution.

### Excel workbook
- `Tables/obj2_section32_outputs.xlsx`

This workbook contains the exported metadata and numerical outputs.

### Main figures
Saved as both `.fig` and `.png`:
- `Figures/Fig2_MeanSpectra_Part_SNV_vs_SG1`
- `Figures/Fig3_PCA_Part_SNV_vs_SG2`

### Supplementary figures
Saved as both `.fig` and `.png`:
- `Supplementary/FigS2_MeanSpectra_Maturity_SNV`
- `Supplementary/FigS3_PCA_Maturity_SNV_vs_SG2`

## Excel sheets
The output workbook includes the following sheets:

- `Meta`
- `DesignLevels`
- `MeanSD_SNV`
- `MeanSD_SNV_SG1`
- `MeanByPart_SNV`
- `MeanByPart_SNV_SG1`
- `MeanByMaturity_SNV`
- `PCA_Explained_SNV`
- `PCA_Explained_SNV_SG2`
- `Table4_SNV`
- `Table5_SNV_SG2`

## Meaning of the exported tables

### `Meta`
Run metadata, including:
- input file,
- sheet name,
- number of rows,
- number of spectral variables,
- wavelength range,
- wavelength spacing,
- permutation count,
- random seed,
- Savitzky–Golay parameters,
- manifest usage,
- archived script name.

### `DesignLevels`
Lists the factor levels and their counts for:
- Part
- Maturity

### `MeanSD_SNV`
Global mean and standard deviation of the SNV spectra by wavelength.

### `MeanSD_SNV_SG1`
Global mean and standard deviation of the SNV + SG1 spectra by wavelength.

### `MeanByPart_SNV`
Mean SNV spectra by Part.

### `MeanByPart_SNV_SG1`
Mean SNV + SG1 spectra by Part.

### `MeanByMaturity_SNV`
Mean SNV spectra by Maturity.

### `PCA_Explained_SNV`
Explained and cumulative variance for PCA on SNV data.

### `PCA_Explained_SNV_SG2`
Explained and cumulative variance for PCA on SNV + SG2 data.

### `Table4_SNV`
Freedman–Lane multivariate factorial test results for SNV data.

### `Table5_SNV_SG2`
Freedman–Lane multivariate factorial test results for SNV + SG2 data.

## Statistical details

### PCA
PCA is computed using singular value decomposition (`svd`) with:
- `Centered = false`
- autoscaled input matrices

### Multivariate factorial inference
For each preprocessing configuration, the script tests:
- **Part**
- **Maturity**
- **Part × Maturity**

using a Freedman–Lane permutation framework.

The exported statistics include:
- `df_term`
- `df_error`
- `SS_term`
- `SS_error`
- `F`
- `p_perm`
- `R2`
- `eta2p`
- `nPerm`

### Multiple testing correction
Benjamini–Hochberg correction is applied to the permutation p-values and exported as `q_BH`.

## How to run

Run directly from MATLAB:

```matlab
BRC_obj2_Section32_SpectralStructure_run_v1
