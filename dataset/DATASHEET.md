# Datasheet for PARALLAX Exchange Clearinghouse Dataset

_Following the "Datasheets for Datasets" framework (Gebru et al., 2021)._

## Motivation

**Purpose:** This dataset was created to support reproducible research on AI-native decentralized exchange infrastructure, specifically multi-model orchestration, clearinghouse netting, phase synchronization, and adversarial market detection.

**Creators:** Alfredo Medina Hernandez / ItsNotAILABS, PARALLAX Sovereign Organism.

**Funding:** Self-funded independent research.

## Composition

**Instances:** The dataset contains 10 distinct data files covering:
- 1,000 clearinghouse netting cycles
- 5,000 Kuramoto coherence time-series measurements
- 500 multi-model ensemble orchestration runs (21 model profiles)
- 200 AI artifact tokenization evaluations
- 2,000 heartbeat settlement timing measurements
- 2,400 production engine performance records (24 engines × 100 epochs)
- 300 cross-chain bridge operations
- Mathematical reference tables (phi powers, Fibonacci, Schumann)
- 10 provenance chains with cryptographic receipts
- 500 adversarial market detection samples

**Data Types:** Numerical (float, int), categorical (enum strings), boolean, and cryptographic hashes (hex strings).

**Labels:** The adversarial detection dataset includes ground-truth behavioral labels (normal, wash_trading, spoofing, layering, front_running, pump_dump).

**Confidential Data:** None. All data is synthetically generated.

**Offensive Content:** None.

## Collection Process

**Generation Method:** All data is synthetically generated using deterministic simulation with `random.seed(42)` for full reproducibility.

**Mechanisms:**
- Kuramoto model: Standard coupled oscillator differential equations
- Clearinghouse: Bilateral/multilateral netting algorithm simulation
- Tokenization: Golden-ratio-weighted composite scoring
- Adversarial: Feature-engineered with behavior-specific distribution parameters

**Time Period:** Generated June 2026.

**Ethical Review:** Not applicable (synthetic data, no human subjects).

## Preprocessing

**Processing Applied:**
- All floating-point values are rounded to appropriate precision (4-15 decimal places)
- Hashes are truncated to standard lengths (16 or 64 hex characters)
- Timestamps are in milliseconds (heartbeat-relative) or nanoseconds

**Raw Data:** The generation script serves as the canonical source. No raw collection instrument exists as data is purely simulated.

## Uses

**Intended Uses:**
- Academic research on DeFi clearing and settlement
- ML model development for market manipulation detection
- Study of synchronization dynamics in distributed AI systems
- Benchmarking multi-model orchestration strategies
- Validating phi-derived parameter systems

**Not Recommended:**
- This is simulated data — do NOT use for actual financial decisions
- Do NOT treat adversarial detection labels as validated against real markets
- Not suitable as training data for production trading systems without real market calibration

## Distribution

**License:** PARALLAX Sovereign License v1.0
**Platform:** Zenodo (DOI-assigned archival repository)
**Format:** JSON + CSV (dual format for all tabular data)
**Access:** Open access

## Maintenance

**Maintainer:** ItsNotAILABS / Alfredo Medina Hernandez
**Updates:** Dataset versions will be released alongside major PARALLAX protocol updates
**Contact:** MedinaSITech@outlook.com / GitHub Issues
