# Datasheet for PARALLAX Zenodo Community Scientific Dataset

_Following the "Datasheets for Datasets" framework (Gebru et al., 2021)._

## Motivation

**Purpose:** This dataset was created to serve the scientific community on Zenodo with research-quality benchmark data spanning computational science, physics, machine learning, complex systems, statistical methodology, and sustainability. It enables reproducible research on AI-native decentralized exchange infrastructure while being accessible to domain scientists.

**Creators:** Alfredo Medina Hernandez / ItsNotAILABS, PARALLAX Sovereign Organism.

**Funding:** Self-funded independent research.

**Target Communities:**
- Computational scientists studying numerical reproducibility
- Physicists working on synchronization and nonlinear dynamics
- ML researchers evaluating model fairness, calibration, and robustness
- Network scientists studying systemic risk and graph properties
- Statisticians developing methodology and replication studies
- Environmental scientists studying computational sustainability

## Composition

**Instances:** The dataset contains 6 distinct data files with 3,600 total records:

| Dataset | Records | Variables | Description |
|---------|---------|-----------|-------------|
| Computational Reproducibility | 500 | 14 | Algorithm benchmarks across precisions |
| Coupled Oscillator Experiments | 1,000 | 17 | Kuramoto model with variable parameters |
| ML Evaluation Benchmarks | 800 | 21 | Multi-model assessment with fairness/calibration |
| Network Topology Analysis | 600 | 23 | Graph metrics and systemic risk indicators |
| Statistical Validation Methods | 400 | 22 | Hypothesis testing and power analysis |
| Energy Sustainability Metrics | 300 | 15 | Per-operation energy and carbon footprint |

**Data Types:**
- Numerical: float (precision 4–18 decimal places), integer
- Categorical: enumerated strings (topologies, algorithms, regions)
- Boolean: convergence flags, detection indicators
- Temporal: ISO 8601 timestamps
- Cryptographic: SHA-256 hashes (32 hex chars)

**Labels:**
- ML benchmarks include fairness metrics and evidence categories
- Statistical validation includes null hypothesis rejection indicators
- Coupled oscillators include chimera state detection flags
- Network topology includes scale-free classification

**Missing Data:** None. All fields are complete.

**Confidential Data:** None. All data is synthetically generated.

**Offensive Content:** None.

## Collection Process

**Generation Method:** All data is synthetically generated using deterministic simulation with:
- `random.seed(42)` (Python standard library)
- `numpy.random.default_rng(42)` (NumPy)

**Physical Models Used:**
- Kuramoto coupled oscillator model with mean-field coupling
- Scale-free network generation (Barabási-Albert model properties)
- Standard numerical analysis error bounds
- Statistical power analysis formulas
- Energy consumption models based on ICP architecture

**Distributions Used:**
- Gaussian (normal): performance metrics, errors, noise
- Beta: probabilities, fractions, normalized scores
- Log-normal: model parameters, compute costs
- Uniform: sampling parameters, p-values under null

**Time Period:** Generated June 2026.

**Ethical Review:** Not applicable (synthetic data, no human subjects).

## Preprocessing

**Processing Applied:**
- Floating-point values rounded to appropriate precision
- All values clamped to physically meaningful ranges
- SHA-256 hashes computed from deterministic seeds
- Timestamps generated in ISO 8601 format

**Validation:**
- Order parameters constrained to [0, 1]
- Probabilities constrained to [0, 1]
- Energy values constrained to positive
- Effect sizes aligned with Cohen's conventions

## Uses

**Intended Uses:**
- Benchmarking numerical methods and reproducibility studies
- Validating synchronization dynamics in coupled oscillator systems
- Developing and evaluating ML model assessment frameworks
- Studying network resilience and systemic risk
- Teaching statistical methodology and multiple comparison corrections
- Analyzing energy efficiency of distributed computing systems
- Cross-disciplinary research connecting these domains

**Encouraged Research Questions:**
1. How does floating-point precision affect algorithm convergence?
2. What coupling topologies promote chimera states?
3. How does ensemble size affect calibration and fairness?
4. Which network metrics best predict systemic risk?
5. When do Bayesian and frequentist approaches disagree?
6. What is the carbon cost per transaction in different architectures?

**Not Recommended:**
- Do NOT use for production system sizing or capacity planning
- Do NOT treat as calibrated against real-world physical measurements
- Do NOT use network risk metrics for actual financial regulation
- Do NOT cite energy figures as validated ICP performance measurements
- Not suitable for training production ML models without real data augmentation

## Distribution

**License:** PARALLAX Sovereign License v1.0
**Platform:** Zenodo (DOI-assigned archival repository)
**Format:** JSON + CSV (dual format for all datasets)
**Access:** Open access
**Identifier:** DOI pending assignment

## Maintenance

**Maintainer:** ItsNotAILABS / Alfredo Medina Hernandez
**Updates:** Dataset versions released alongside major PARALLAX protocol updates
**Contact:** MedinaSITech@outlook.com / GitHub Issues
**Versioning:** Semantic versioning (MAJOR.MINOR.PATCH)

## References

1. Kuramoto, Y. (1984). Chemical Oscillations, Waves, and Turbulence. Springer.
2. Gebru, T. et al. (2021). Datasheets for Datasets. Communications of the ACM, 64(12), 86-92.
3. Barabási, A.-L. & Albert, R. (1999). Emergence of scaling in random networks. Science, 286(5439), 509-512.
4. Cohen, J. (1988). Statistical Power Analysis for the Behavioral Sciences. Routledge.
5. Guo, C. et al. (2017). On Calibration of Modern Neural Networks. ICML.
6. Battiston, S. et al. (2012). DebtRank: Too Central to Fail? Scientific Reports, 2, 541.
7. DFINITY Foundation. (2021). The Internet Computer for Geeks. https://internetcomputer.org/whitepaper.pdf
