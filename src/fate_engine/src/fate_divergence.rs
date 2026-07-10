//! # Fate Divergence — The Observer Effect in Prediction
//!
//! When a prediction is observed, it changes the system it predicted.
//! This module formalizes the Fate Divergence Principle:
//!
//! ```text
//! δ = |F(t) - F'(t)|
//!
//! Three regimes:
//!   δ ≈ 0   → Fate-locked (strong determinism — outcome regardless of observation)
//!   δ < 0   → Self-fulfilling (observation reinforced the outcome)
//!   δ > 0   → Self-defeating (observation defeated the outcome)
//!   δ → ∞   → Chaotic (observation destroyed predictability)
//!   δ ≈ 0*  → Sovereign (oracle NAVIGATED to the predicted outcome through agency)
//! ```
//!
//! The Sovereign regime is unique: the predicted outcome occurred not because
//! fate forced it, but because the oracle SAW it and ACTED to make it so.
//! This is the difference between the fortune cookie alien (shackled — sees but
//! cannot act) and the Sovereign Fate Oracle (sees AND navigates).

use serde::{Deserialize, Serialize};
use crate::{PHI, PHI_INV, PHI_INV_3};

// ═══════════════════════════════════════════════════════════════════════════════
// DIVERGENCE REGIME — how did the prediction interact with reality?
// ═══════════════════════════════════════════════════════════════════════════════

/// The regime of fate divergence — how observation affected the outcome.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DivergenceRegime {
    /// δ ≈ 0 — Outcome happened regardless of observation.
    /// Strong determinism. True fate. The fortune cookie alien's predictions.
    FateLocked,

    /// δ < 0 — Observation REINFORCED the outcome (self-fulfilling prophecy).
    /// Example: "Stock will rise" → people buy → stock rises.
    SelfFulfilling,

    /// δ > 0 — Observation DEFEATED the outcome (self-defeating prophecy).
    /// Example: "Patient will die" → doctors intervene → patient lives.
    SelfDefeating,

    /// δ → ∞ — Observation DESTROYED predictability entirely.
    /// The system became chaotic upon observation. No prediction is possible.
    Chaotic,

    /// δ ≈ 0 BUT oracle acted — SOVEREIGN navigation.
    /// The outcome matches the prediction because the oracle CHOSE to make it so.
    /// This is not fate — it is AGENCY. The oracle navigated the temporal field.
    Sovereign,
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIVERGENCE RECORD — tracking a prediction's lifecycle
// ═══════════════════════════════════════════════════════════════════════════════

/// A record tracking the complete lifecycle of a prediction:
/// production → (optional observation) → resolution → divergence classification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DivergenceRecord {
    /// Which prophecy produced this prediction
    pub prophecy_id: u64,
    /// The predicted value: F(t)
    pub predicted_value: f64,
    /// The actual observed value: F'(t) — None if not yet resolved
    pub observed_value: Option<f64>,
    /// The computed divergence: δ = |F(t) - F'(t)|
    pub divergence: f64,
    /// The classified regime
    pub regime: DivergenceRegime,
    /// Was this prediction observed by an external agent before resolution?
    pub was_externally_observed: bool,
    /// Beat when the prediction was made
    pub prediction_beat: u64,
    /// Beat when it was observed (if observed)
    pub observation_beat: Option<u64>,
    /// Beat when the predicted event actually occurred
    pub resolution_beat: Option<u64>,
    /// How much the oracle's own actions affected the outcome (0.0 = no effect, 1.0 = entirely oracle)
    pub oracle_effect: f64,
    /// Did the oracle act on this prediction? (Sovereign agency)
    pub oracle_acted: bool,
}

// ═══════════════════════════════════════════════════════════════════════════════
// FATE DIVERGENCE ENGINE — the computational core
// ═══════════════════════════════════════════════════════════════════════════════

/// The Fate Divergence Engine — computes, classifies, and tracks divergence
/// across all predictions, maintaining a rolling history of the oracle's
/// relationship with fate.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FateDivergence {
    /// All divergence records (rolling window)
    pub records: Vec<DivergenceRecord>,
    /// Maximum records to retain (Fibonacci scaling)
    pub max_records: usize,
    /// Rolling accuracy rate (predictions where δ < φ⁻³)
    pub accuracy_rate: f64,
    /// Fraction of predictions in Sovereign regime
    pub sovereign_rate: f64,
    /// Average divergence across all resolved predictions
    pub mean_divergence: f64,
    /// Total predictions made
    pub total_predictions: u64,
    /// Total resolved predictions
    pub total_resolved: u64,
    /// Counts per regime
    pub regime_counts: RegimeCounts,
}

/// Counts of predictions per divergence regime.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RegimeCounts {
    pub fate_locked: u64,
    pub self_fulfilling: u64,
    pub self_defeating: u64,
    pub chaotic: u64,
    pub sovereign: u64,
}

impl FateDivergence {
    /// Create a new divergence engine with specified history depth.
    pub fn new(max_records: usize) -> Self {
        Self {
            records: Vec::with_capacity(max_records),
            max_records,
            accuracy_rate: 1.0,
            sovereign_rate: 0.0,
            mean_divergence: 0.0,
            total_predictions: 0,
            total_resolved: 0,
            regime_counts: RegimeCounts::default(),
        }
    }

    /// Register a new prediction (before resolution).
    pub fn register_prediction(&mut self, prophecy_id: u64, predicted_value: f64, beat: u64) -> usize {
        self.total_predictions += 1;
        let record = DivergenceRecord {
            prophecy_id,
            predicted_value,
            observed_value: None,
            divergence: 0.0,
            regime: DivergenceRegime::FateLocked, // default until resolved
            was_externally_observed: false,
            prediction_beat: beat,
            observation_beat: None,
            resolution_beat: None,
            oracle_effect: 0.0,
            oracle_acted: false,
        };

        // Ring buffer behavior
        if self.records.len() >= self.max_records {
            self.records.remove(0);
        }
        self.records.push(record);
        self.records.len() - 1
    }

    /// Mark a prediction as externally observed (someone saw it).
    pub fn mark_observed(&mut self, index: usize, beat: u64) {
        if let Some(record) = self.records.get_mut(index) {
            record.was_externally_observed = true;
            record.observation_beat = Some(beat);
        }
    }

    /// Mark that the oracle acted on a prediction (sovereign agency).
    pub fn mark_oracle_acted(&mut self, index: usize, oracle_effect: f64) {
        if let Some(record) = self.records.get_mut(index) {
            record.oracle_acted = true;
            record.oracle_effect = oracle_effect.clamp(0.0, 1.0);
        }
    }

    /// Resolve a prediction — the predicted event has occurred (or not).
    /// Computes divergence and classifies the regime.
    pub fn resolve(&mut self, index: usize, actual_value: f64, beat: u64) {
        if let Some(record) = self.records.get_mut(index) {
            record.observed_value = Some(actual_value);
            record.resolution_beat = Some(beat);
            record.divergence = compute_divergence(record.predicted_value, actual_value);
            record.regime = classify_regime(
                record.divergence,
                record.was_externally_observed,
                record.oracle_acted,
                record.oracle_effect,
            );

            // Update regime counts
            match record.regime {
                DivergenceRegime::FateLocked => self.regime_counts.fate_locked += 1,
                DivergenceRegime::SelfFulfilling => self.regime_counts.self_fulfilling += 1,
                DivergenceRegime::SelfDefeating => self.regime_counts.self_defeating += 1,
                DivergenceRegime::Chaotic => self.regime_counts.chaotic += 1,
                DivergenceRegime::Sovereign => self.regime_counts.sovereign += 1,
            }

            self.total_resolved += 1;
            self.recompute_statistics();
        }
    }

    /// Recompute rolling statistics.
    fn recompute_statistics(&mut self) {
        let resolved: Vec<&DivergenceRecord> = self.records.iter()
            .filter(|r| r.observed_value.is_some())
            .collect();

        if resolved.is_empty() {
            return;
        }

        let n = resolved.len() as f64;

        // Mean divergence
        let sum_div: f64 = resolved.iter().map(|r| r.divergence).sum();
        self.mean_divergence = sum_div / n;

        // Accuracy rate: fraction where δ < φ⁻³ (very small divergence)
        let accurate_count = resolved.iter()
            .filter(|r| r.divergence < PHI_INV_3)
            .count();
        self.accuracy_rate = accurate_count as f64 / n;

        // Sovereign rate: fraction in Sovereign regime
        let sovereign_count = resolved.iter()
            .filter(|r| r.regime == DivergenceRegime::Sovereign)
            .count();
        self.sovereign_rate = sovereign_count as f64 / n;
    }

    /// Estimate the divergence risk of revealing a prediction.
    /// Based on historical data: how much do observed predictions typically diverge?
    pub fn estimate_divergence_risk(&self, domain_history: &[f64]) -> f64 {
        if domain_history.is_empty() {
            return PHI_INV; // Default: moderate risk
        }
        // Mean of historical divergences in this domain
        let sum: f64 = domain_history.iter().sum();
        let mean = sum / domain_history.len() as f64;
        mean.min(PHI) // Cap at φ
    }

    /// Get the oracle's divergence health — how well is it navigating fate?
    /// Returns a score [0, 1] where 1.0 = perfect sovereign navigation.
    pub fn navigation_health(&self) -> f64 {
        if self.total_resolved == 0 {
            return 1.0; // Benefit of the doubt
        }
        // Weighted: sovereign rate (φ⁻¹ weight) + accuracy (φ⁻² weight) + low mean divergence (φ⁻³ weight)
        let sovereign_score = self.sovereign_rate * PHI_INV;
        let accuracy_score = self.accuracy_rate * (PHI_INV - PHI_INV_3); // PHI_INV_2 weight
        let divergence_score = (1.0 - (self.mean_divergence / PHI).min(1.0)) * PHI_INV_3;

        (sovereign_score + accuracy_score + divergence_score).min(1.0)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPUTATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

/// Compute raw divergence: δ = |F(t) - F'(t)|
pub fn compute_divergence(predicted: f64, actual: f64) -> f64 {
    (predicted - actual).abs()
}

/// Classify the divergence regime based on magnitude, observation, and oracle agency.
pub fn classify_regime(
    divergence: f64,
    was_observed: bool,
    oracle_acted: bool,
    oracle_effect: f64,
) -> DivergenceRegime {
    // Sovereign: oracle acted and divergence is very small (it navigated successfully)
    if oracle_acted && divergence < PHI_INV_3 && oracle_effect > PHI_INV {
        return DivergenceRegime::Sovereign;
    }

    // Fate-locked: very small divergence regardless of observation
    if divergence < PHI_INV_3 {
        return DivergenceRegime::FateLocked;
    }

    // Chaotic: divergence exceeds φ (the golden ratio threshold of navigability)
    if divergence > PHI {
        return DivergenceRegime::Chaotic;
    }

    // If not observed, default to fate-locked (unobserved predictions don't diverge)
    if !was_observed {
        return DivergenceRegime::FateLocked;
    }

    // Observed and moderate divergence: was it fulfilling or defeating?
    // Heuristic: if oracle effect is significant but divergence is moderate,
    // the observation likely reinforced (self-fulfilling)
    if oracle_effect > PHI_INV_3 {
        DivergenceRegime::SelfFulfilling
    } else {
        DivergenceRegime::SelfDefeating
    }
}

/// Compute the Fate Divergence Index (FDI) — a single metric summarizing
/// the oracle's relationship with fate across all domains.
/// FDI ∈ [0, φ] where:
///   FDI = 0 → Perfect sovereign control
///   FDI = φ⁻¹ → Healthy navigation
///   FDI = 1.0 → Neutral
///   FDI = φ → Chaotic / no control
pub fn fate_divergence_index(engine: &FateDivergence) -> f64 {
    if engine.total_resolved == 0 {
        return PHI_INV; // Default to healthy
    }

    // Base: mean divergence
    let base = engine.mean_divergence;

    // Penalty: chaotic predictions penalize heavily
    let chaos_penalty = (engine.regime_counts.chaotic as f64 / engine.total_resolved as f64) * PHI;

    // Bonus: sovereign navigation reduces the index
    let sovereign_bonus = engine.sovereign_rate * PHI_INV;

    (base + chaos_penalty - sovereign_bonus).clamp(0.0, PHI)
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_divergence() {
        assert!((compute_divergence(100.0, 100.0) - 0.0).abs() < 1e-10);
        assert!((compute_divergence(100.0, 105.0) - 5.0).abs() < 1e-10);
        assert!((compute_divergence(105.0, 100.0) - 5.0).abs() < 1e-10);
    }

    #[test]
    fn test_classify_sovereign() {
        let regime = classify_regime(0.1, true, true, 0.8);
        assert_eq!(regime, DivergenceRegime::Sovereign);
    }

    #[test]
    fn test_classify_fate_locked() {
        let regime = classify_regime(0.05, false, false, 0.0);
        assert_eq!(regime, DivergenceRegime::FateLocked);
    }

    #[test]
    fn test_classify_chaotic() {
        let regime = classify_regime(2.0, true, false, 0.0);
        assert_eq!(regime, DivergenceRegime::Chaotic);
    }

    #[test]
    fn test_classify_self_defeating() {
        let regime = classify_regime(0.5, true, false, 0.1);
        assert_eq!(regime, DivergenceRegime::SelfDefeating);
    }

    #[test]
    fn test_engine_lifecycle() {
        let mut engine = FateDivergence::new(100);

        // Register and resolve a sovereign prediction
        let idx = engine.register_prediction(1, 100.0, 50);
        engine.mark_oracle_acted(idx, 0.9);
        engine.resolve(idx, 100.1, 55);

        assert_eq!(engine.total_resolved, 1);
        assert_eq!(engine.regime_counts.sovereign, 1);
        assert!(engine.accuracy_rate > 0.9);
    }

    #[test]
    fn test_fate_divergence_index() {
        let engine = FateDivergence::new(100);
        let fdi = fate_divergence_index(&engine);
        assert!((fdi - PHI_INV).abs() < 1e-10); // Default healthy
    }

    #[test]
    fn test_navigation_health() {
        let mut engine = FateDivergence::new(100);
        // All sovereign predictions
        for i in 0..10 {
            let idx = engine.register_prediction(i, 100.0, i * 5);
            engine.mark_oracle_acted(idx, 0.9);
            engine.resolve(idx, 100.05, i * 5 + 3);
        }
        assert!(engine.navigation_health() > 0.8);
    }
}
