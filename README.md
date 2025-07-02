
# 📊 Analysis Reproduction: Srinivasan, Koyanagi et al., 2025

This repository provides the datasets and custom code used to perform the key quantitative analyses from **Srinivasan, Koyanagi et al., 2025**, including mixed-effects modeling, population vector similarity analyses, and regression with covariates.

---

## 📁 Source Data Summary

### `PV_all_data.mat`

| Variable | Description |
|----------|-------------|
| `ABNs`   | Cell array of deconvolved activity for adult-born neurons (ABNs). Rows = mice; columns = behavioral contexts. |
| `GNs`    | Cell array of deconvolved activity for granule neurons (GNs). Same structure as `ABNs`. |
| `lab`    | Cell array of context labels (e.g., A1–A7, postS, REM). |

---

### `Average_PV_REM.mat`

| Variable   | Description |
|------------|-------------|
| `ABNs`     | Matrix of average activity per ABN neuron across sessions. Size: `[neurons x sessions]`. |
| `GNs`      | Same structure as `ABNs`, but for GNs. |
| `nABNs`    | Vector specifying how many neurons belong to each ABN mouse. |
| `nGNs`     | Vector specifying how many neurons belong to each GN mouse. |

> ℹ️ **Example**: If `nABNs(1) = 42`, then rows `1:42` in the `ABNs` matrix correspond to mouse 1.

---

### `Average_PV_retrieval.mat`

Same structure as `Average_PV_REM.mat`, but includes **retrieval** data in place of the REM session.

---

### `Freezing_opto_data.xlsx`  
**Source for Extended Data Figure S8**

This file contains behavioral and optogenetic stimulation data from mice subjected to contextual and tone-based fear conditioning with either **targeted** or **yoked** optogenetic stimulation.

#### 📄 Sheet Overview

| Sheet     | Description           |
|-----------|-----------------------|
| `Sheet1`  | Main dataset used in the analysis |

#### 📊 Columns in `Sheet1`

| Column              | Description |
|---------------------|-------------|
| `Row`               | Mouse ID |
| `episodeLengthSec`  | Duration of the behavioral episode in seconds |
| `FreezingContext`   | Contextual freezing during **targeted** optogenetic stimulation |
| `YorkContext`       | Contextual freezing during **yoked** optogenetic stimulation |
| `FreezingTone`      | Tone-evoked freezing during **targeted** optogenetic stimulation |
| `YorkTone`          | Tone-evoked freezing during **yoked** optogenetic stimulation |
| `-175` to `175`     | Number of light pulses delivered at each **theta phase bin** (in degrees, from -175° to 175° in 10° steps) |

> 🔍 Phase-binned light stimulation is used to examine how stimulation timing within the theta cycle modulates freezing behavior.

---

#### Reproducing the Analysis (Extended Data Figure S8)

1. Navigate to the `R codes/` directory.
2. Open R and run:
   ```r
   setwd("/**your_path**/R codes")
   source("Main.R")
   ```
3. Ensure the following R packages are installed:
   - `ggplot2`
   - `glmnet`
   - `readxl`
   - `zoo`

The script will load the dataset, fit regression models, and generate figures for the freezing and stimulation-phase relationships.

---

## 🧪 Code Overview

### `Analysis_demo_Fig_1.m`

Main script to reproduce:
- **Figure 1**
- **Extended Data Figure 2**

| Functionality Included | Description |
|------------------------|-------------|
| Normalized activity plots | Box/distribution plots of neural activity by condition |
| Mixed-effects models       | Statistical comparisons across conditions and neuron types |
| PV similarity matrices     | Heatmaps of population vector correlations |
| Subsampling procedures     | Random downsampling to match group sizes |
| Covariate analysis         | Includes neuron count as a model covariate |
| Retrieval period modeling  | Includes a retrieval session in regression |

> 📎 Each analysis block is clearly commented within the script.

---

## ⚙️ Requirements

| Environment | Tools |
|-------------|-------|
| **MATLAB**  | R2021a or newer recommended |
| **R**       | R 4.0+ with listed packages |

---

## 📄 Citation

If you use this code or dataset, please cite:

**Srinivasan, Koyanagi et al., 2025**  
*Transient reactivation of small ensembles of adult-born neurons during REM sleep supports memory consolidation in mice*  
**Nature Communications**, Volume(Issue), Pages. DOI

**For question about the code**, contact Pablo Vergara (pablo.vergara.g@ug.uchile.cl) or open an issue in this github repo.
