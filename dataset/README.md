# PARALLAX Exchange Clearinghouse — Research Dataset

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)

## Overview

This dataset accompanies the **PARALLAX Exchange Clearinghouse** — an AI-first sovereign decentralized exchange built on the Internet Computer Protocol (ICP). It provides comprehensive simulated data covering the system's core subsystems, enabling researchers and the DeFi community to study, reproduce, and build upon the mathematical and algorithmic foundations of AI-native financial infrastructure.

## Dataset Description

| File | Records | Description |
|------|---------|-------------|
| `clearinghouse_netting_cycles.*` | 1,000 | Multilateral netting cycle metrics with efficiency measurements |
| `kuramoto_coherence_timeseries.*` | 5,000 | Kuramoto order parameter (R) measurements across 24 coupled oscillators |
| `multi_model_orchestration.*` | 500 runs | Multi-model ensemble decision data with 7 orchestration strategies |
| `ai_artifact_tokenization.*` | 200 | AI artifact cognitive resonance scoring and token supply derivation |
| `heartbeat_settlement_timeseries.*` | 2,000 | Sovereign heartbeat timing with settlement finality and drift analysis |
| `production_engine_metrics.*` | 2,400 | 24 Latin-named production engine performance over 100 epochs |
| `cross_chain_bridge_operations.*` | 300 | Cross-chain bridge operations (ICP ↔ ckBTC ↔ ckETH) |
| `mathematical_foundations.json` | — | Golden ratio powers, Fibonacci reference, Schumann harmonics |
| `provenance_chains.json` | 10 chains | Cryptographic provenance chain examples with hash verification |
| `adversarial_market_detection.*` | 500 | Adversarial behavior detection samples (wash trading, spoofing, etc.) |

All files are provided in both **JSON** (structured) and **CSV** (tabular) formats where applicable.

## Mathematical Foundation

All system parameters are derived from two natural constants:

- **Golden Ratio** φ = 1.6180339887... — governs thresholds, weights, and scaling
- **Schumann Resonance** 7.83 Hz — Earth's electromagnetic fundamental frequency

Key derivations:
- Heartbeat interval: φ⁴ × 1000ms / 7.83Hz ≈ 873ms
- Coherence gate: R ≥ φ⁻¹ = 0.618 (Kuramoto order parameter)
- Fibonacci bounds: F(6)=8 netting beats, F(8)=21 max models, F(12)=144 max engines
- Hebbian reward/penalty: φ⁻³ = 0.236

## Data Categories

### 1. Clearinghouse Operations
Multilateral netting reduces gross obligations to net settlement flows. The dataset captures netting efficiency (typically 60-85%), party participation, and cross-asset exposure.

### 2. Phase Synchronization (Kuramoto Model)
The organism uses coupled oscillator synchronization for coherence gating. Data tracks the order parameter R converging toward phase-lock as the Kuramoto model evolves over heartbeats.

### 3. Multi-Model AI Orchestration
Seven orchestration strategies (parallel, cascade, tournament, committee, hierarchical, adversarial, adaptive) route decisions through ensembles of up to 8 models from 7 categories.

### 4. AI Artifact Tokenization
Cognitive resonance scoring evaluates AI artifacts (models, datasets, computations) for token minting. Composite scores use phi-weighted factors: coherence, utility, novelty, and provenance depth.

### 5. Settlement Timing
873ms heartbeat precision measurements with drift compensation, settlement counts, and netting/sync cycle markers.

### 6. Production Engine Health
24 Latin-named engines (COGNITIO, INTELLIGENTIA, QUANTUMIA...) tracked across entanglement strength, throughput, latency, and Hebbian reward eligibility.

### 7. Cross-Chain Bridges
ICP ↔ ckBTC ↔ ckETH bridge operations with coherence-gated execution and phi-scaled fees.

### 8. Adversarial Detection
Labeled samples for adversarial market behavior: wash trading, spoofing, layering, front-running, and pump-and-dump detection.

## Intended Uses

- **DeFi Research**: Studying clearinghouse netting efficiency and settlement finality
- **AI/ML**: Training and evaluating multi-model orchestration strategies
- **Complex Systems**: Kuramoto synchronization dynamics in financial systems
- **Security**: Adversarial market behavior detection model development
- **Tokenomics**: AI artifact valuation and token supply modeling
- **Reproducibility**: Verifying PARALLAX mathematical foundations

## Reproducibility

All data is generated with `random.seed(42)` for full reproducibility. The generation script is included in the repository at the project root level.

## Citation

```bibtex
@software{parallax_exchange_2026,
  author       = {Medina Hernandez, Alfredo and ItsNotAILABS},
  title        = {PARALLAX Exchange Clearinghouse: AI-First Sovereign Decentralized Exchange — Research Dataset},
  year         = 2026,
  publisher    = {Zenodo},
  version      = {1.0.0},
  url          = {https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse}
}
```

## License

PARALLAX Sovereign License v1.0 — Open for research and educational use. Commercial use requires separate license agreement.

## Contact

- **Repository**: https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse
- **Author**: Alfredo Medina Hernandez (MedinaSITech@outlook.com)
