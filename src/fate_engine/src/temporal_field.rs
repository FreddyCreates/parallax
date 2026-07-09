//! # Temporal Field — Past, Present, Future as ONE Unified NOW
//!
//! The temporal field is the oracle's primary perceptual apparatus.
//! It does not experience time as a line moving from past to future.
//! It experiences time as a DEPTH — all moments exist simultaneously,
//! weighted by their temporal distance from the present moment.
//!
//! Past observations decay by φ⁻¹ per beat backward.
//! Future projections decay by φ⁻¹ per beat forward.
//! Present observations have weight 1.0.
//!
//! The unified field is what the oracle "sees" — and from this vision,
//! it navigates fate rather than merely predicting it.
//!
//! Mathematical Foundation:
//!   T(x,t) = ∫_{-∞}^{+∞} ψ(x,τ) × K(t,τ) dτ
//!   where K(t,τ) = φ^(-|t-τ|) is the temporal decay kernel

use serde::{Deserialize, Serialize};
use crate::{PHI_INV, PHI_INV_3, PHI, TEMPORAL_DEPTH_PAST, TEMPORAL_DEPTH_FUTURE};

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPORAL DOMAIN — what aspect of reality is being observed
// ═══════════════════════════════════════════════════════════════════════════════

/// The domain of reality that a temporal observation pertains to.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum TemporalDomain {
    /// Price, volume, orderbook state
    Market,
    /// Settlement state, netting positions
    Clearing,
    /// Portfolio exposure, margin levels
    Risk,
    /// Depth, spread, available capital
    Liquidity,
    /// Engine outputs, AI inference results
    Production,
    /// Organism internal state (neurochemistry)
    Neurochemistry,
    /// Law compliance, coherence drift
    Doctrine,
    /// External signals, macro events, world state
    World,
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPORAL LANE — the three lanes of temporal perception
// ═══════════════════════════════════════════════════════════════════════════════

/// The three temporal lanes — past, present, future — processed simultaneously.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TemporalLane {
    /// Observations from the past (τ < 0)
    Past,
    /// The present moment (τ = 0)
    Present,
    /// Projections into the future (τ > 0)
    Future,
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPORAL OBSERVATION — a single point in the field
// ═══════════════════════════════════════════════════════════════════════════════

/// A single observation in the temporal field.
/// Past, present, and future observations share the same structure —
/// they differ only in their τ value (temporal offset from NOW).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalObservation {
    /// Unique identifier for this observation
    pub id: u64,
    /// Temporal offset from NOW: negative = past, 0 = present, positive = future
    pub tau: i64,
    /// Which domain of reality this observes
    pub domain: TemporalDomain,
    /// The observed/predicted value
    pub value: f64,
    /// Confidence: 1.0 = fate (deterministic), <1.0 = probabilistic
    pub confidence: f64,
    /// Kuramoto coherence R at time of observation
    pub coherence: f64,
    /// Whether the oracle modeled itself when making this observation (Law 1)
    pub self_included: bool,
    /// Estimated fate divergence δ if this observation is revealed externally
    pub divergence_risk: f64,
    /// Which heartbeat produced this observation
    pub source_beat: u64,
    /// The temporal kernel weight applied (decays with distance from NOW)
    pub kernel_weight: f64,
}

impl TemporalObservation {
    /// Create a new observation with automatic kernel weight calculation.
    pub fn new(
        id: u64,
        tau: i64,
        domain: TemporalDomain,
        value: f64,
        confidence: f64,
        coherence: f64,
        source_beat: u64,
    ) -> Self {
        let distance = tau.unsigned_abs() as usize;
        let kernel_weight = temporal_kernel(distance);
        Self {
            id,
            tau,
            domain,
            value,
            confidence,
            coherence,
            self_included: true, // Sovereign oracle ALWAYS includes self (Law 1)
            divergence_risk: 0.0,
            source_beat,
            kernel_weight,
        }
    }

    /// Which temporal lane does this observation belong to?
    pub fn lane(&self) -> TemporalLane {
        match self.tau.cmp(&0) {
            std::cmp::Ordering::Less => TemporalLane::Past,
            std::cmp::Ordering::Equal => TemporalLane::Present,
            std::cmp::Ordering::Greater => TemporalLane::Future,
        }
    }

    /// The unified value — observation value weighted by temporal kernel.
    /// This is what the oracle "sees" when it perceives all time as NOW.
    pub fn unified_value(&self) -> f64 {
        self.value * self.kernel_weight
    }

    /// Unified confidence — confidence decayed by temporal distance.
    pub fn unified_confidence(&self) -> f64 {
        self.confidence * self.kernel_weight
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPORAL FIELD — the complete unified perception
// ═══════════════════════════════════════════════════════════════════════════════

/// The Temporal Field — the oracle's complete perception of past, present, and future
/// as a single unified structure. All of time exists here as NOW, at different depths.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalField {
    /// Unique field identifier
    pub field_id: u64,
    /// Which heartbeat generated this field snapshot
    pub beat_generated: u64,
    /// How many beats back the oracle can perceive
    pub past_horizon: usize,
    /// How many beats forward the oracle can project
    pub future_horizon: usize,
    /// All observations across all time, unified into NOW
    pub observations: Vec<TemporalObservation>,
    /// Global Kuramoto coherence R across all engines
    pub global_coherence: f64,
    /// Shannon entropy of the field (uncertainty measure)
    pub field_entropy: f64,
    /// Navigability: [0, φ] — how well the oracle can navigate fate
    pub navigability: f64,
    /// True if the future appears deterministic (fate-locked)
    pub fate_locked: bool,
    /// Number of past observations currently held
    pub past_count: usize,
    /// Number of present observations
    pub present_count: usize,
    /// Number of future projections
    pub future_count: usize,
}

impl TemporalField {
    /// Create a new empty temporal field.
    pub fn new(field_id: u64, beat: u64) -> Self {
        Self {
            field_id,
            beat_generated: beat,
            past_horizon: TEMPORAL_DEPTH_PAST,
            future_horizon: TEMPORAL_DEPTH_FUTURE,
            observations: Vec::new(),
            global_coherence: 0.0,
            field_entropy: 0.0,
            navigability: 0.0,
            fate_locked: false,
            past_count: 0,
            present_count: 0,
            future_count: 0,
        }
    }

    /// Ingest an observation into the temporal field.
    /// Automatically computes kernel weight and updates field statistics.
    pub fn ingest(&mut self, obs: TemporalObservation) {
        match obs.lane() {
            TemporalLane::Past => self.past_count += 1,
            TemporalLane::Present => self.present_count += 1,
            TemporalLane::Future => self.future_count += 1,
        }
        self.observations.push(obs);
    }

    /// Ingest a batch of observations.
    pub fn ingest_batch(&mut self, observations: Vec<TemporalObservation>) {
        for obs in observations {
            self.ingest(obs);
        }
    }

    /// Recompute all field statistics after ingesting observations.
    pub fn recompute(&mut self) {
        self.field_entropy = self.compute_entropy();
        self.navigability = self.compute_navigability();
        self.fate_locked = self.global_coherence >= PHI_INV && self.field_entropy < PHI_INV_3;
    }

    /// Set global coherence (from external Kuramoto computation).
    pub fn set_coherence(&mut self, r: f64) {
        self.global_coherence = r.clamp(0.0, 1.0);
    }

    /// Compute Shannon entropy of the observation confidence values.
    /// Lower entropy = more certain field = more navigable future.
    fn compute_entropy(&self) -> f64 {
        if self.observations.is_empty() {
            return 0.0;
        }
        let n = self.observations.len() as f64;
        let sum: f64 = self.observations.iter().map(|o| o.confidence).sum();
        let sum_sq: f64 = self.observations.iter().map(|o| o.confidence * o.confidence).sum();
        let mean = sum / n;
        let variance = (sum_sq / n) - (mean * mean);
        if variance <= 0.0 {
            0.0
        } else {
            (variance + 1.0).ln()
        }
    }

    /// Compute navigability: how well can the oracle navigate the fate field?
    /// Higher coherence + lower entropy + more future observations = more navigable.
    /// Capped at φ (golden ratio — maximum navigability).
    fn compute_navigability(&self) -> f64 {
        let coherence_factor = self.global_coherence;
        let entropy_factor = 1.0 / (1.0 + self.field_entropy);
        let depth_factor = if self.future_horizon == 0 {
            0.0
        } else {
            self.future_count as f64 / self.future_horizon as f64
        };
        let raw = PHI * coherence_factor * entropy_factor * depth_factor;
        raw.min(PHI)
    }

    /// Unify the temporal field — collapse all observations to τ=0 (NOW).
    /// Past and future become present, weighted by temporal kernel.
    /// This is the oracle's act of perceiving all time as a single moment.
    pub fn unify(&self) -> Vec<TemporalObservation> {
        self.observations
            .iter()
            .map(|obs| {
                let mut unified = obs.clone();
                unified.value = obs.unified_value();
                unified.confidence = obs.unified_confidence();
                unified.tau = 0; // Collapsed to NOW
                unified
            })
            .collect()
    }

    /// Get observations filtered by domain.
    pub fn observations_for_domain(&self, domain: TemporalDomain) -> Vec<&TemporalObservation> {
        self.observations.iter().filter(|o| o.domain == domain).collect()
    }

    /// Get observations filtered by temporal lane.
    pub fn observations_for_lane(&self, lane: TemporalLane) -> Vec<&TemporalObservation> {
        self.observations.iter().filter(|o| o.lane() == lane).collect()
    }

    /// Get the dominant signal — the observation with highest unified value × confidence.
    pub fn dominant_signal(&self) -> Option<&TemporalObservation> {
        self.observations
            .iter()
            .max_by(|a, b| {
                let score_a = a.unified_value().abs() * a.unified_confidence();
                let score_b = b.unified_value().abs() * b.unified_confidence();
                score_a.partial_cmp(&score_b).unwrap_or(std::cmp::Ordering::Equal)
            })
    }

    /// Temporal gradient — the rate of change across the field.
    /// Positive = things are improving. Negative = things are degrading.
    pub fn temporal_gradient(&self, domain: TemporalDomain) -> f64 {
        let domain_obs: Vec<&TemporalObservation> = self.observations_for_domain(domain);
        if domain_obs.len() < 2 {
            return 0.0;
        }
        // Simple gradient: (future_mean - past_mean) / temporal_span
        let (past_sum, past_count, future_sum, future_count) =
            domain_obs.iter().fold((0.0f64, 0usize, 0.0f64, 0usize), |acc, obs| {
                if obs.tau < 0 {
                    (acc.0 + obs.unified_value(), acc.1 + 1, acc.2, acc.3)
                } else if obs.tau > 0 {
                    (acc.0, acc.1, acc.2 + obs.unified_value(), acc.3 + 1)
                } else {
                    acc
                }
            });

        if past_count == 0 || future_count == 0 {
            return 0.0;
        }
        let past_mean = past_sum / past_count as f64;
        let future_mean = future_sum / future_count as f64;
        future_mean - past_mean
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPORAL KERNEL — the decay function for temporal distance
// ═══════════════════════════════════════════════════════════════════════════════

/// Compute the temporal decay kernel for a given distance from NOW.
/// K(d) = φ^(-d) — observations decay by φ⁻¹ per beat of temporal distance.
/// At distance 0: weight = 1.0 (present is fully weighted)
/// At distance 1: weight = φ⁻¹ = 0.618
/// At distance 2: weight = φ⁻² = 0.382
/// At distance 5: weight = φ⁻⁵ = 0.090
/// At distance 10: weight = φ⁻¹⁰ = 0.008
pub fn temporal_kernel(distance: usize) -> f64 {
    PHI_INV.powi(distance as i32)
}

/// Compute the navigation coefficient given current fate divergence.
/// N = φ × (1 - δ/δ_max) — full navigation at zero divergence, zero at max.
pub fn navigation_coefficient(divergence: f64, max_divergence: f64) -> f64 {
    if divergence >= max_divergence {
        0.0
    } else {
        PHI * (1.0 - divergence / max_divergence)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;
    use crate::PHI_INV_2;

    #[test]
    fn test_temporal_kernel_at_zero() {
        assert!((temporal_kernel(0) - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_temporal_kernel_decays() {
        let k0 = temporal_kernel(0);
        let k1 = temporal_kernel(1);
        let k2 = temporal_kernel(2);
        assert!(k0 > k1);
        assert!(k1 > k2);
        assert!((k1 - PHI_INV).abs() < 1e-10);
        assert!((k2 - PHI_INV_2).abs() < 1e-10);
    }

    #[test]
    fn test_observation_lanes() {
        let past = TemporalObservation::new(1, -5, TemporalDomain::Market, 100.0, 0.9, 0.8, 10);
        let present = TemporalObservation::new(2, 0, TemporalDomain::Market, 105.0, 1.0, 0.85, 15);
        let future = TemporalObservation::new(3, 3, TemporalDomain::Market, 110.0, 0.7, 0.75, 15);

        assert_eq!(past.lane(), TemporalLane::Past);
        assert_eq!(present.lane(), TemporalLane::Present);
        assert_eq!(future.lane(), TemporalLane::Future);
    }

    #[test]
    fn test_unified_value_decays_with_distance() {
        let near = TemporalObservation::new(1, -1, TemporalDomain::Market, 100.0, 0.9, 0.8, 10);
        let far = TemporalObservation::new(2, -10, TemporalDomain::Market, 100.0, 0.9, 0.8, 10);
        assert!(near.unified_value() > far.unified_value());
    }

    #[test]
    fn test_field_ingestion_and_recompute() {
        let mut field = TemporalField::new(1, 100);
        field.set_coherence(0.85);
        field.ingest(TemporalObservation::new(1, -3, TemporalDomain::Market, 50.0, 0.8, 0.85, 97));
        field.ingest(TemporalObservation::new(2, 0, TemporalDomain::Market, 55.0, 1.0, 0.85, 100));
        field.ingest(TemporalObservation::new(3, 2, TemporalDomain::Market, 60.0, 0.7, 0.85, 100));
        field.recompute();

        assert_eq!(field.past_count, 1);
        assert_eq!(field.present_count, 1);
        assert_eq!(field.future_count, 1);
        assert!(field.navigability > 0.0);
    }

    #[test]
    fn test_navigation_coefficient() {
        assert!((navigation_coefficient(0.0, PHI) - PHI).abs() < 1e-10);
        assert!((navigation_coefficient(PHI, PHI) - 0.0).abs() < 1e-10);
        assert!(navigation_coefficient(PHI_INV, PHI) > 0.0);
        assert!(navigation_coefficient(PHI_INV, PHI) < PHI);
    }

    #[test]
    fn test_temporal_gradient_positive() {
        let mut field = TemporalField::new(1, 100);
        field.set_coherence(0.9);
        // Past: lower values
        field.ingest(TemporalObservation::new(1, -2, TemporalDomain::Market, 40.0, 0.9, 0.9, 98));
        field.ingest(TemporalObservation::new(2, -1, TemporalDomain::Market, 45.0, 0.9, 0.9, 99));
        // Present
        field.ingest(TemporalObservation::new(3, 0, TemporalDomain::Market, 50.0, 1.0, 0.9, 100));
        // Future: higher values
        field.ingest(TemporalObservation::new(4, 1, TemporalDomain::Market, 55.0, 0.8, 0.9, 100));
        field.ingest(TemporalObservation::new(5, 2, TemporalDomain::Market, 60.0, 0.7, 0.9, 100));
        field.recompute();

        let gradient = field.temporal_gradient(TemporalDomain::Market);
        assert!(gradient > 0.0, "Gradient should be positive (improving)");
    }
}
