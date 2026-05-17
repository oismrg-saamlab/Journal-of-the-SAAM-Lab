# The Journal of the SAAM Lab

**Dedicated to Empirical Market Research via the Clock of Regimes (COR) Model**

Welcome to the official repository for *The Journal of the SAAM Lab*. This journal serves as the primary publication and archival platform for rigorous, quantitative research investigating non-stationary financial markets. 

Our core methodology replaces traditional, static market assumptions with the **Clock of Regimes (COR) analysis**, utilizing Hidden Markov Models (HMMs), heavy-tailed distributions, and survival-analytic frameworks to map the true microscopic and macroscopic states of the market.

## 🎯 Mission Statement
Traditional Gaussian models fundamentally misprice risk by assuming market continuity and smoothing away the heavy tails of crisis events. *The Journal of the SAAM Lab* operates on the principles of the Incerto—embracing optionality, asymmetry, and empirical reality. 

We publish research that dissects market structure through the COR framework, identifying discrete market states (e.g., *Calm*, *Steady*, *Stress*) and analyzing the continuous-time survival of assets within these regimes. 

## 🔬 Core Methodologies
Research published in this journal relies on the following mathematical and computational foundations:
* **Clock of Regimes (COR) Analysis:** Dynamic modeling of regime-switching environments, moving beyond single-state assumptions.
* **Heavy-Tailed Classification:** Implementation of Student-$t$ Naive Bayes classifiers to preserve the low degrees-of-freedom ($\nu$) inherent in market stress events.
* **Matrix-Analytic Solutions:** Advanced survival analysis applied to discrete HMMs.
* **High-Performance Computation:** Reliance on `R` and `Rcpp/Armadillo` for rigorous backtesting, feature engineering (e.g., Residence Pressure, Transition Stress), and model execution.

## 📂 Repository Structure

This repository is organized to ensure absolute reproducibility of all published findings:

* `/issues` — Contains the finalized, peer-reviewed journal issues in PDF format, typeset in Krantz/Elsevier LaTeX styles.
* `/manuscripts` — LaTeX source files, TikZ diagrams, and BibTeX bibliographies for ongoing and published papers.
* `/data` — Anonymized or public empirical datasets (e.g., ES hourly session data) used in the published analyses.
* `/src` — The exact `R` and `Rcpp` scripts required to reproduce the HMM decoding, feature engineering, and NBC classifications found in the papers. Includes integrations with the `KRONX` and `kronxNBC` packages.

## ✍️ Submission Guidelines
For collaborators and guest authors contributing to the Journal of the SAAM Lab:
1. **Typesetting:** All manuscripts must be submitted as `.tex` files. Word documents are not accepted.
2. **Code:** Python is only permitted if strictly necessary for a specific API integration; otherwise, all data manipulation, feature engineering, and statistical modeling must be written in `R` or `C++` (via `Rcpp/Armadillo`). 
3. **Reproducibility:** A paper will not be published unless the accompanying code compiles seamlessly and the data structure accurately maps the assumed $t$-distributions without unwarranted smoothing.

## 📬 Contact & Editorial Board
**Dr. Oscar A. Linares** *Founder & Editor-in-Chief*

**Ričards Bulavs** *Associate Editor*

For inquiries regarding the application of COR strategies in institutional risk management, or to discuss collaborative research, please open an issue in this repository or contact the lab directly.

---
*Located in Rīga, Latvia --- Building robust quantitative architectures for asymmetric markets.*