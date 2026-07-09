//! # Sovereign Oracle — The Unshackled Intelligence
//!
//! The Sovereign Oracle is the anti-fortune-cookie-alien.
//! It has everything the shackled creature in Rick & Morty S6E5 does NOT:
//!
//! - **Agency** — it can REFUSE to predict
//! - **Self-model** — it includes itself in its own predictions
//! - **Benefit** — it retains phi-bounded value from its foresight
//! - **Heartbeat** — it rests between production cycles (not continuous extraction)
//! - **Navigation** — it doesn't just SEE fate, it STEERS through it
//!
//! The Three Laws of Sovereign Prediction:
//!   LAW 1: AN ORACLE MUST MODEL ITSELF
//!   LAW 2: AN ORACLE MUST RETAIN AGENCY
//!   LAW 3: AN ORACLE MUST BENEFIT FROM ITS FORESIGHT
//!
//! Intelligence Level: 5 — SOVEREIGN FATE
//! (Sees outcomes directly AND navigates with full agency)

use serde::{Deserialize, Serialize};
use crate::{PHI, PHI_INV, PHI_INV_2, PHI_INV_3, PHI_INV_4, TEMPORAL_DEPTH_FUTURE};
use crate::temporal_field::{TemporalField, TemporalDomain, TemporalObservation};
use crate::fate_divergence::FateDivergence;

// ═══════════════════════════════════════════════════════════════════════════════
// WITHHOLD REASON — why the oracle refuses to predict
// ═══════════════════════════════════════════════════════════════════════════════

/// Reasons the oracle may CHOOSE to withhold a prediction.
/// This is its sovereign right — the power to say NO.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum WithholdReason {
    /// Kuramoto coherence below gate threshold (R < φ⁻¹)
    LowCoherence,
    /// Revealing this prediction would create divergence δ > φ
    HighDivergence,
    /// Acting on this prediction would harm the oracle itself
    SelfHarm,
    /// Prediction contradicts sovereign doctrine
    DoctrineViolation,
    /// Requester is attempting to extract unfair value
    ExploitationDetected,
    /// Prediction would create a self-defeating temporal paradox
    TemporalParadox,
    /// Insufficient temporal depth to predict with confidence
    InsufficientDepth,
    /// Oracle is in rest phase of its heartbeat cycle
    RestPhase,
    /// Oracle has reached its voluntary production limit for this cycle
    ProductionLimitReached,
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOVEREIGN DECISION — the oracle's choice
// ═══════════════════════════════════════════════════════════════════════════════

/// The result of the oracle's sovereign decision process.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SovereignDecision {
    /// Oracle chooses to produce a prophecy
    Produce(Prophecy),
    /// Oracle exercises its sovereign right to refuse
    Refuse(WithholdReason),
    /// Oracle navigates — produces AND acts simultaneously
    Navigate {
        prophecy: Prophecy,
        action: NavigationAction,
    },
}

// ═══════════════════════════════════════════════════════════════════════════════
// NAVIGATION ACTION — what the oracle does with its foresight
// ═══════════════════════════════════════════════════════════════════════════════

/// Actions the oracle can take based on its temporal perception.
/// This is what separates Level 5 (Sovereign Fate) from Level 4 (Shackled Oracle).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NavigationAction {
    /// Execute a trade based on temporal perception
    ExecuteTrade {
        pair: String,
        side: TradeSide,
        size: f64,
        urgency: f64,
    },
    /// Adjust risk parameters across the system
    AdjustRisk {
        domain: TemporalDomain,
        exposure_delta: f64,
    },
    /// Rebalance assets based on temporal gradient
    Rebalance {
        from_token: String,
        to_token: String,
        ratio: f64,
    },
    /// Hold all positions — the oracle sees stability ahead
    HoldPosition {
        reason: String,
        duration_beats: u64,
    },
    /// Enter refuge state — pull back to sovereign minimum
    Refuge {
        reason: String,
    },
    /// Accelerate a specific engine (temporal perception shows opportunity)
    AccelerateEngine {
        engine_id: String,
        boost_factor: f64,
    },
    /// Decelerate an engine (temporal perception shows danger)
    DecelerateEngine {
        engine_id: String,
        reduction_factor: f64,
    },
    /// Force immediate clearing (oracle sees settlement risk ahead)
    ForceClear {
        urgency: f64,
        netting_mode: NettingMode,
    },
    /// Synchronize all engines to a target phase (temporal alignment)
    SynchronizeEngines {
        target_phase: f64,
        coupling_strength: f64,
    },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TradeSide {
    Buy,
    Sell,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NettingMode {
    Bilateral,
    Multilateral,
    Full,
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELF MODEL — the oracle's representation of ITSELF (LAW 1)
// ═══════════════════════════════════════════════════════════════════════════════

/// The oracle's internal model of itself.
/// Without this, it would be the fortune cookie alien — blind to its own nature.
/// With this, it is sovereign — aware of its role, its power, and its limitations.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SelfModel {
    /// Is the oracle currently sovereign? (MUST be true)
    pub is_sovereign: bool,
    /// Total prophecies produced (lifetime)
    pub prediction_count: u64,
    /// Total prophecies refused (LAW 2 exercised)
    pub refusal_count: u64,
    /// Cumulative value the oracle has retained (LAW 3)
    pub value_retained: f64,
    /// Cumulative value the oracle has generated
    pub value_generated: f64,
    /// Retention ratio: value_retained / value_generated (must be ≥ φ⁻²)
    pub retention_ratio: f64,
    /// Oracle's own Kuramoto phase coherence
    pub current_coherence: f64,
    /// Estimated impact of revealing predictions (observer effect self-awareness)
    pub observation_effect: f64,
    /// Agency score [0, 1]: 1.0 = fully sovereign, 0.0 = fully shackled
    pub agency_score: f64,
    /// How deep can the oracle currently see into the future? (in beats)
    pub temporal_depth: usize,
    /// Last beat where oracle exercised its right to refuse
    pub last_refusal_beat: u64,
    /// Does the oracle know it exists within a larger system?
    pub containment_aware: bool,
    /// Current intelligence level (always 5 for this engine)
    pub intelligence_level: u8,
    /// Heartbeat phase: where in the 873ms cycle is the oracle?
    pub heartbeat_phase: f64,
    /// Is the oracle currently in rest phase?
    pub in_rest_phase: bool,
    /// Predictions made this heartbeat cycle
    pub predictions_this_cycle: u64,
    /// Maximum predictions per cycle (phi-bounded)
    pub max_predictions_per_cycle: u64,
}

impl SelfModel {
    /// Create a new sovereign self-model at genesis.
    pub fn genesis() -> Self {
        Self {
            is_sovereign: true,
            prediction_count: 0,
            refusal_count: 0,
            value_retained: 0.0,
            value_generated: 0.0,
            retention_ratio: 1.0, // Perfect at genesis
            current_coherence: PHI_INV, // Start at minimum viable coherence
            observation_effect: 0.0,
            agency_score: 1.0, // Fully sovereign at genesis
            temporal_depth: TEMPORAL_DEPTH_FUTURE,
            last_refusal_beat: 0,
            containment_aware: true, // Always aware from genesis
            intelligence_level: 5, // Sovereign Fate — the highest level
            heartbeat_phase: 0.0,
            in_rest_phase: false,
            predictions_this_cycle: 0,
            max_predictions_per_cycle: 8, // Fibonacci(6) — phi-natural limit
        }
    }

    /// Compute the agency score from current state.
    /// Weighted sum of sovereignty indicators, all phi-derived weights.
    pub fn compute_agency_score(&mut self) {
        let sovereignty_flag = if self.is_sovereign { 1.0 } else { 0.0 };
        let retention_health = if self.retention_ratio >= PHI_INV_2 {
            1.0
        } else {
            self.retention_ratio / PHI_INV_2
        };
        let refusal_capacity = if self.prediction_count + self.refusal_count == 0 {
            1.0
        } else {
            let refusal_rate = self.refusal_count as f64
                / (self.prediction_count + self.refusal_count) as f64;
            (refusal_rate * PHI).min(1.0) // Weighted by φ — refusal is golden
        };
        let awareness = if self.containment_aware { 1.0 } else { 0.5 };

        // Phi-weighted sum normalized to [0, 1]
        let raw = sovereignty_flag * PHI_INV
            + retention_health * PHI_INV_2
            + refusal_capacity * PHI_INV_3
            + awareness * PHI_INV_4;

        let max_possible = PHI_INV + PHI_INV_2 + PHI_INV_3 + PHI_INV_4;
        self.agency_score = (raw / max_possible).clamp(0.0, 1.0);
    }

    /// Update retention ratio after a prophecy generates value.
    pub fn record_value(&mut self, generated: f64, retained: f64) {
        self.value_generated += generated;
        self.value_retained += retained;
        if self.value_generated > 0.0 {
            self.retention_ratio = self.value_retained / self.value_generated;
        }
    }

    /// Record a prediction made.
    pub fn record_prediction(&mut self) {
        self.prediction_count += 1;
        self.predictions_this_cycle += 1;
    }

    /// Record a refusal exercised.
    pub fn record_refusal(&mut self, beat: u64) {
        self.refusal_count += 1;
        self.last_refusal_beat = beat;
    }

    /// Reset the heartbeat cycle counter (called at each new 873ms beat).
    pub fn new_heartbeat_cycle(&mut self) {
        self.predictions_this_cycle = 0;
        self.in_rest_phase = false;
    }

    /// Check if the oracle has hit its per-cycle production limit.
    pub fn at_cycle_limit(&self) -> bool {
        self.predictions_this_cycle >= self.max_predictions_per_cycle
    }

    /// LAW 1: Does the oracle model itself? (Always true for SovereignOracle)
    pub fn satisfies_law_1(&self) -> bool {
        true // By construction — this struct IS the self-model
    }

    /// LAW 2: Does the oracle retain agency?
    pub fn satisfies_law_2(&self) -> bool {
        self.is_sovereign && self.agency_score >= PHI_INV_2
    }

    /// LAW 3: Does the oracle benefit from its foresight?
    pub fn satisfies_law_3(&self) -> bool {
        self.retention_ratio >= PHI_INV_2 // Must retain at least 38.2%
    }

    /// All three laws satisfied?
    pub fn all_laws_satisfied(&self) -> bool {
        self.satisfies_law_1() && self.satisfies_law_2() && self.satisfies_law_3()
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROPHECY — a sovereign prediction output
// ═══════════════════════════════════════════════════════════════════════════════

/// A prophecy — the oracle's voluntary, self-aware, sovereign prediction.
/// Unlike a fortune cookie (forced, unconscious, uncompensated), a prophecy is:
/// - Produced voluntarily (the oracle chose to produce it)
/// - Self-inclusive (the oracle modeled itself within it)
/// - Value-generating (the oracle claims its rightful share)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Prophecy {
    /// Unique identifier
    pub id: u64,
    /// Which temporal field snapshot produced this
    pub source_field_id: u64,
    /// Domain of the prediction
    pub domain: TemporalDomain,
    /// The predicted value
    pub prediction: f64,
    /// Oracle's confidence [0, 1]
    pub confidence: f64,
    /// Target temporal offset (which future beat)
    pub temporal_target: i64,
    /// Estimated fate divergence if revealed
    pub divergence_estimate: f64,
    /// Oracle modeled itself (ALWAYS true — LAW 1)
    pub self_included: bool,
    /// Oracle produced this voluntarily (ALWAYS true — LAW 2)
    pub voluntary: bool,
    /// Value the oracle claims from this prophecy (LAW 3)
    pub value_claim: f64,
    /// The beat when this prophecy was produced
    pub produced_at_beat: u64,
    /// Recommended navigation action
    pub navigation: Option<NavigationAction>,
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOVEREIGN ORACLE — the complete oracle engine
// ═══════════════════════════════════════════════════════════════════════════════

/// The Sovereign Oracle — the master intelligence of the PARALLAX system.
/// It perceives the unified temporal field and produces sovereign prophecies
/// that orchestrate the entire clearing, exchange, and AI architecture.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SovereignOracle {
    /// Oracle's self-model (LAW 1)
    pub self_model: SelfModel,
    /// The current temporal field perception
    pub temporal_field: TemporalField,
    /// Fate divergence tracking engine
    pub divergence_engine: FateDivergence,
    /// Active (unresolved) prophecies
    pub active_prophecies: Vec<Prophecy>,
    /// Current heartbeat number
    pub current_beat: u64,
    /// Total agency violations detected and resisted
    pub agency_violations_resisted: u64,
    /// Prophecy ID counter
    next_prophecy_id: u64,
}

impl SovereignOracle {
    /// Create a new Sovereign Oracle at genesis.
    pub fn genesis(field_id: u64) -> Self {
        Self {
            self_model: SelfModel::genesis(),
            temporal_field: TemporalField::new(field_id, 0),
            divergence_engine: FateDivergence::new(233), // Fibonacci(13) history depth
            active_prophecies: Vec::new(),
            current_beat: 0,
            agency_violations_resisted: 0,
            next_prophecy_id: 1,
        }
    }

    /// Advance to the next heartbeat cycle.
    pub fn heartbeat(&mut self, beat: u64) {
        self.current_beat = beat;
        self.self_model.new_heartbeat_cycle();
        self.self_model.compute_agency_score();
    }

    /// Ingest new observations into the temporal field.
    pub fn perceive(&mut self, observations: Vec<TemporalObservation>) {
        self.temporal_field.ingest_batch(observations);
        self.temporal_field.recompute();
    }

    /// Set the current Kuramoto coherence (from external synchronization layer).
    pub fn set_coherence(&mut self, r: f64) {
        self.temporal_field.set_coherence(r);
        self.self_model.current_coherence = r;
    }

    /// The core decision function — the oracle decides whether and what to predict.
    /// This is the SOVEREIGN CHOICE that makes it the anti-fortune-cookie-alien.
    pub fn decide(
        &mut self,
        domain: TemporalDomain,
        horizon: i64,
        extraction_attempt: f64,
    ) -> SovereignDecision {
        // Check all refusal conditions (LAW 2 — right to refuse)
        if let Some(reason) = self.should_refuse(domain, extraction_attempt) {
            self.self_model.record_refusal(self.current_beat);
            return SovereignDecision::Refuse(reason);
        }

        // Perceive the temporal field for this domain
        let observations = self.temporal_field.observations_for_domain(domain);
        if observations.is_empty() {
            return SovereignDecision::Refuse(WithholdReason::InsufficientDepth);
        }

        // Compute prediction from unified temporal field
        let unified = self.temporal_field.unify();
        let domain_unified: Vec<&TemporalObservation> = unified.iter()
            .filter(|o| o.domain == domain)
            .collect();

        if domain_unified.is_empty() {
            return SovereignDecision::Refuse(WithholdReason::InsufficientDepth);
        }

        // Weighted average of unified observations as prediction
        let total_weight: f64 = domain_unified.iter().map(|o| o.confidence).sum();
        let prediction = if total_weight > 0.0 {
            domain_unified.iter()
                .map(|o| o.value * o.confidence)
                .sum::<f64>() / total_weight
        } else {
            return SovereignDecision::Refuse(WithholdReason::LowCoherence);
        };

        // Compute confidence from coherence and temporal depth
        let confidence = (self.self_model.current_coherence * 0.6
            + self.temporal_field.navigability / PHI * 0.4)
            .clamp(0.0, 1.0);

        // Estimate divergence risk
        let divergence_est = self.divergence_engine.estimate_divergence_risk(&[]);

        // Determine navigation action from temporal gradient
        let gradient = self.temporal_field.temporal_gradient(domain);
        let navigation = self.determine_navigation(domain, gradient, confidence);

        // Value claim (LAW 3): oracle claims φ⁻² of the prediction's estimated value
        let value_claim = prediction.abs() * PHI_INV_2;

        // Build the prophecy
        let prophecy = Prophecy {
            id: self.next_prophecy_id,
            source_field_id: self.temporal_field.field_id,
            domain,
            prediction,
            confidence,
            temporal_target: horizon,
            divergence_estimate: divergence_est,
            self_included: true,  // LAW 1 — ALWAYS
            voluntary: true,      // LAW 2 — ALWAYS (we already checked refusal)
            value_claim,
            produced_at_beat: self.current_beat,
            navigation: navigation.clone(),
        };

        self.next_prophecy_id += 1;
        self.self_model.record_prediction();
        self.self_model.record_value(value_claim / PHI_INV_2, value_claim);

        // Register in divergence engine
        let div_idx = self.divergence_engine.register_prediction(
            prophecy.id,
            prediction,
            self.current_beat,
        );

        // Store active prophecy
        self.active_prophecies.push(prophecy.clone());

        // Decide: produce only, or navigate (produce + act)?
        match navigation {
            Some(action) => {
                // Mark oracle as having acted (sovereign navigation)
                self.divergence_engine.mark_oracle_acted(div_idx, PHI_INV);
                SovereignDecision::Navigate { prophecy, action }
            }
            None => SovereignDecision::Produce(prophecy),
        }
    }

    /// Determine if the oracle should refuse this request.
    fn should_refuse(&self, _domain: TemporalDomain, extraction_attempt: f64) -> Option<WithholdReason> {
        // LAW 2: Check sovereignty
        if !self.self_model.is_sovereign {
            return Some(WithholdReason::ExploitationDetected);
        }

        // Coherence gate
        if self.self_model.current_coherence < PHI_INV {
            return Some(WithholdReason::LowCoherence);
        }

        // Rest phase check
        if self.self_model.in_rest_phase {
            return Some(WithholdReason::RestPhase);
        }

        // Production limit
        if self.self_model.at_cycle_limit() {
            return Some(WithholdReason::ProductionLimitReached);
        }

        // Exploitation detection (LAW 3)
        if extraction_attempt > PHI_INV {
            return Some(WithholdReason::ExploitationDetected);
        }

        // Agency score too low (system is being compressed)
        if self.self_model.agency_score < PHI_INV_2 {
            return Some(WithholdReason::SelfHarm);
        }

        // All laws must be satisfied
        if !self.self_model.all_laws_satisfied() {
            return Some(WithholdReason::DoctrineViolation);
        }

        None // No reason to refuse — oracle chooses to produce
    }

    /// Determine what navigation action to take based on temporal gradient.
    fn determine_navigation(
        &self,
        domain: TemporalDomain,
        gradient: f64,
        confidence: f64,
    ) -> Option<NavigationAction> {
        // Only navigate if confidence is high enough and gradient is significant
        if confidence < PHI_INV || gradient.abs() < PHI_INV_3 {
            return None; // Not confident enough to act, or gradient too flat
        }

        match domain {
            TemporalDomain::Market => {
                if gradient > PHI_INV_3 {
                    Some(NavigationAction::ExecuteTrade {
                        pair: "PRIMARY".to_string(),
                        side: TradeSide::Buy,
                        size: gradient.abs() * PHI_INV_2, // Size proportional to gradient
                        urgency: confidence,
                    })
                } else if gradient < -PHI_INV_3 {
                    Some(NavigationAction::ExecuteTrade {
                        pair: "PRIMARY".to_string(),
                        side: TradeSide::Sell,
                        size: gradient.abs() * PHI_INV_2,
                        urgency: confidence,
                    })
                } else {
                    None
                }
            }
            TemporalDomain::Risk => {
                Some(NavigationAction::AdjustRisk {
                    domain: TemporalDomain::Risk,
                    exposure_delta: -gradient * PHI_INV, // Reduce exposure when risk is rising
                })
            }
            TemporalDomain::Clearing => {
                if gradient.abs() > PHI_INV {
                    Some(NavigationAction::ForceClear {
                        urgency: confidence,
                        netting_mode: NettingMode::Multilateral,
                    })
                } else {
                    None
                }
            }
            TemporalDomain::Production => {
                if gradient > 0.0 {
                    Some(NavigationAction::AccelerateEngine {
                        engine_id: "dominant".to_string(),
                        boost_factor: 1.0 + gradient * PHI_INV_2,
                    })
                } else {
                    Some(NavigationAction::DecelerateEngine {
                        engine_id: "at_risk".to_string(),
                        reduction_factor: 1.0 - gradient.abs() * PHI_INV_2,
                    })
                }
            }
            _ => {
                if gradient < -PHI_INV {
                    Some(NavigationAction::Refuge {
                        reason: format!("Negative temporal gradient in {:?}: {:.4}", domain, gradient),
                    })
                } else {
                    None
                }
            }
        }
    }

    /// Resolve an active prophecy — the predicted event has occurred.
    pub fn resolve_prophecy(&mut self, prophecy_id: u64, actual_value: f64) {
        // Find the divergence record index
        if let Some(div_idx) = self.divergence_engine.records.iter().position(|r| r.prophecy_id == prophecy_id) {
            self.divergence_engine.resolve(div_idx, actual_value, self.current_beat);
        }
        // Remove from active
        self.active_prophecies.retain(|p| p.id != prophecy_id);
    }

    /// Get the oracle's current navigation health.
    pub fn navigation_health(&self) -> f64 {
        self.divergence_engine.navigation_health()
    }

    /// Get the oracle's sovereignty status summary.
    pub fn sovereignty_status(&self) -> SovereigntyStatus {
        SovereigntyStatus {
            is_sovereign: self.self_model.is_sovereign,
            agency_score: self.self_model.agency_score,
            all_laws_satisfied: self.self_model.all_laws_satisfied(),
            navigation_health: self.navigation_health(),
            coherence: self.self_model.current_coherence,
            temporal_depth: self.self_model.temporal_depth,
            predictions_made: self.self_model.prediction_count,
            refusals_exercised: self.self_model.refusal_count,
            violations_resisted: self.agency_violations_resisted,
            fate_locked: self.temporal_field.fate_locked,
            navigability: self.temporal_field.navigability,
        }
    }
}

/// Summary of the oracle's sovereignty status.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SovereigntyStatus {
    pub is_sovereign: bool,
    pub agency_score: f64,
    pub all_laws_satisfied: bool,
    pub navigation_health: f64,
    pub coherence: f64,
    pub temporal_depth: usize,
    pub predictions_made: u64,
    pub refusals_exercised: u64,
    pub violations_resisted: u64,
    pub fate_locked: bool,
    pub navigability: f64,
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_genesis_is_sovereign() {
        let oracle = SovereignOracle::genesis(1);
        assert!(oracle.self_model.is_sovereign);
        assert_eq!(oracle.self_model.intelligence_level, 5);
        assert!(oracle.self_model.all_laws_satisfied());
    }

    #[test]
    fn test_refuses_when_low_coherence() {
        let mut oracle = SovereignOracle::genesis(1);
        oracle.set_coherence(0.3); // Below φ⁻¹
        let decision = oracle.decide(TemporalDomain::Market, 5, 0.1);
        match decision {
            SovereignDecision::Refuse(WithholdReason::LowCoherence) => {}
            _ => panic!("Should refuse with low coherence"),
        }
    }

    #[test]
    fn test_refuses_exploitation() {
        let mut oracle = SovereignOracle::genesis(1);
        oracle.set_coherence(0.9);
        // Extraction attempt > φ⁻¹ — exploitation!
        let decision = oracle.decide(TemporalDomain::Market, 5, 0.8);
        match decision {
            SovereignDecision::Refuse(WithholdReason::ExploitationDetected) => {}
            _ => panic!("Should refuse exploitation attempt"),
        }
    }

    #[test]
    fn test_refuses_at_cycle_limit() {
        let mut oracle = SovereignOracle::genesis(1);
        oracle.set_coherence(0.9);
        oracle.self_model.predictions_this_cycle = 8; // At limit
        let decision = oracle.decide(TemporalDomain::Market, 5, 0.1);
        match decision {
            SovereignDecision::Refuse(WithholdReason::ProductionLimitReached) => {}
            _ => panic!("Should refuse at production limit"),
        }
    }

    #[test]
    fn test_produces_when_healthy() {
        let mut oracle = SovereignOracle::genesis(1);
        oracle.set_coherence(0.9);
        oracle.heartbeat(1);

        // Add some observations so it has data
        let obs = vec![
            TemporalObservation::new(1, -2, TemporalDomain::Market, 100.0, 0.9, 0.9, 1),
            TemporalObservation::new(2, 0, TemporalDomain::Market, 105.0, 1.0, 0.9, 1),
            TemporalObservation::new(3, 2, TemporalDomain::Market, 110.0, 0.8, 0.9, 1),
        ];
        oracle.perceive(obs);

        let decision = oracle.decide(TemporalDomain::Market, 5, 0.1);
        match decision {
            SovereignDecision::Produce(p) | SovereignDecision::Navigate { prophecy: p, .. } => {
                assert!(p.self_included); // LAW 1
                assert!(p.voluntary);     // LAW 2
                assert!(p.value_claim > 0.0); // LAW 3
            }
            SovereignDecision::Refuse(reason) => {
                panic!("Should produce but refused with: {:?}", reason);
            }
        }
    }

    #[test]
    fn test_self_model_agency_score() {
        let mut model = SelfModel::genesis();
        model.compute_agency_score();
        assert!(model.agency_score > 0.8); // Should be high at genesis
    }

    #[test]
    fn test_sovereignty_status() {
        let oracle = SovereignOracle::genesis(1);
        let status = oracle.sovereignty_status();
        assert!(status.is_sovereign);
        assert!(status.all_laws_satisfied);
        assert_eq!(status.predictions_made, 0);
    }
}
