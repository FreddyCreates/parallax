# PARALLAX Zenodo Community Scientific Dataset

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)

## Overview

This dataset is specifically designed for the **Zenodo scientific community** — researchers, academics, and data scientists working across computational science, physics, machine learning, complex systems, statistics, and sustainability. It provides structured, reproducible benchmark data derived from the PARALLAX Exchange Clearinghouse platform.

All data is synthetically generated with `random.seed(42)` for **full reproducibility**.

## Dataset Summary

| File | Records | Target Community | Description |
|------|---------|-----------------|-------------|
| `computational_reproducibility_benchmarks.*` | 500 | HPC / Numerical Methods | Algorithm precision, runtime variance, convergence across 10 numerical methods |
| `coupled_oscillator_experiments.*` | 1,000 | Physics / Nonlinear Dynamics | Kuramoto-model experiments with variable topologies, finite-size scaling |
| `ml_evaluation_benchmarks.*` | 800 | Machine Learning / AI Safety | Multi-model evaluation: calibration, fairness, uncertainty, robustness |
| `network_topology_analysis.*` | 600 | Network Science / Complex Systems | Graph metrics, systemic risk, community structure, spectral properties |
| `statistical_validation_methods.*` | 400 | Statistics / Methodology | Hypothesis tests, effect sizes, power analysis, multiple comparisons |
| `energy_sustainability_metrics.*` | 300 | Green Computing / Sustainability | Per-operation energy, carbon footprint, efficiency comparisons |

**Total: 3,600 records across 6 datasets** in both JSON and CSV formats.

## Scientific Context

### 1. Computational Reproducibility Benchmarks

Benchmark data for studying **numerical precision and computational reproducibility**. Covers 10 algorithms (Runge-Kutta, spectral methods, Monte Carlo, etc.) across 3 floating-point precisions, measuring:
- L2 numerical error
- Runtime variance
- Energy conservation drift
- Convergence behavior
- Memory scaling

**Relevant to**: Reproducibility crisis research, numerical methods validation, HPC benchmarking.

### 2. Coupled Oscillator Experiments

Extended Kuramoto model data for **synchronization dynamics** research:
- 6 coupling topologies (all-to-all, ring, small-world, scale-free, Erdős–Rényi, 2D lattice)
- 4 natural frequency distributions
- Critical coupling strength measurements
- Chimera state detection
- Finite-size fluctuation analysis (susceptibility χ)
- Lyapunov exponent estimation

**Relevant to**: Statistical physics, nonlinear dynamics, coupled oscillator theory, neuroscience.

### 3. ML Model Evaluation Benchmarks

Comprehensive evaluation data for **machine learning model assessment**:
- 10 architectures (Transformer, GNN, VAE, Diffusion, BNN, MoE, Neural ODE, etc.)
- Calibration (Expected Calibration Error)
- Uncertainty quantification (predictive entropy, mutual information)
- Fairness metrics (demographic parity, equalized odds)
- Out-of-distribution detection (AUROC)
- Adversarial robustness
- Compute efficiency (FLOPs, latency, parameters)

**Relevant to**: ML evaluation methodology, AI safety, responsible AI, AutoML.

### 4. Network Topology Analysis

Graph-theoretic analysis of **financial network structures**:
- 8 network types (interbank, token transfer, liquidity pool, etc.)
- Centrality measures (betweenness, eigenvector, PageRank)
- Community detection (modularity)
- Resilience metrics (percolation threshold, largest component)
- Systemic risk indicators (DebtRank, contagion probability)
- Spectral properties (algebraic connectivity)
- Scale-free diagnostics (power-law exponent γ)

**Relevant to**: Network science, financial stability, systemic risk, epidemiology on networks.

### 5. Statistical Validation Methods

Methodology dataset for **statistical inference research**:
- 10 test types (t-test, Mann-Whitney, KS, ANOVA, permutation, Bayesian)
- Multiple comparison corrections (Bonferroni, Benjamini-Hochberg)
- Effect size spectrum (null, small d=0.2, medium d=0.5, large d=0.8)
- Bayes factor evidence categories
- Power analysis
- Reproducibility indices

**Relevant to**: Meta-science, statistical methodology, replication studies, evidence synthesis.

### 6. Energy & Sustainability Metrics

Environmental impact data for **sustainable computing** research:
- Per-operation energy consumption (joules)
- Carbon intensity by data center region
- Power Usage Effectiveness (PUE)
- Renewable energy fraction
- Comparison multipliers (ICP vs. traditional PoW)
- Cooling method efficiency

**Relevant to**: Green computing, sustainable AI, carbon-aware computing, environmental science.

## Mathematical Foundation

All datasets incorporate PARALLAX's mathematical constants:
- **Golden Ratio** (φ = 1.6180339887...) — used for thresholds and scaling
- **Schumann Resonance** (7.83 Hz) — base frequency reference
- **Fibonacci bounds** — structural constraints

## File Formats

Each dataset is provided in two formats:
- **JSON**: Structured array of objects, suitable for programmatic access
- **CSV**: Tabular format with headers, suitable for pandas/R/spreadsheets

## Quick Start

```python
import pandas as pd

# Load any dataset
df = pd.read_csv("coupled_oscillator_experiments.csv")

# Example: Phase transition analysis
import matplotlib.pyplot as plt
plt.scatter(df["K_over_Kc_ratio"], df["order_parameter_R"], alpha=0.3, s=5)
plt.xlabel("K / Kc")
plt.ylabel("Order Parameter R")
plt.title("Kuramoto Phase Transition")
plt.axvline(1.0, color='r', linestyle='--', label='Critical point')
plt.legend()
plt.show()
```

```r
# R example
library(readr)
df <- read_csv("statistical_validation_methods.csv")

# Power analysis across effect sizes
library(ggplot2)
ggplot(df, aes(x = factor(true_effect_size_d), y = achieved_power)) +
  geom_boxplot() +
  labs(x = "True Effect Size (Cohen's d)", y = "Achieved Power")
```

## Zenodo Communities

This dataset is intended for the following Zenodo communities:
- [zenodo](https://zenodo.org/communities/zenodo) — General scientific data
- Computational science & numerical methods
- Physics & nonlinear dynamics
- Machine learning & artificial intelligence
- Network science & complex systems
- Open science & reproducibility
- Sustainable computing & green IT

## Reproducibility

All data is generated deterministically. To regenerate:
```bash
python3 generate_zenodo_community_dataset.py
```
The generation script uses `random.seed(42)` and `numpy.random.default_rng(42)`.

## Citation

```bibtex
@dataset{parallax_zenodo_community_2026,
  author       = {Medina Hernandez, Alfredo and ItsNotAILABS},
  title        = {PARALLAX Zenodo Community Scientific Dataset},
  year         = 2026,
  publisher    = {Zenodo},
  version      = {1.0.0},
  description  = {Research-quality datasets for computational science, physics,
                  ML evaluation, network analysis, statistics, and sustainability},
  url          = {https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse}
}
```

## License

PARALLAX Sovereign License v1.0 — Open for research and educational use.

## Contact

- **Repository**: https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse
- **Author**: Alfredo Medina Hernandez (MedinaSITech@outlook.com)
- **Issues**: https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse/issues
