//! # Clearing Orchestrator — Fate-Informed Master System Orchestration
//!
//! The Clearing Orchestrator is the Fate Oracle's executive arm.
//! It translates prophecies and navigation decisions into concrete directives
//! for the entire PARALLAX system: clearinghouse, exchange, AI engines,
//! risk management, and neurochemical balance.
//!
//! ## Architecture
//!
//! ```text
//! Sovereign Oracle (perceives temporal field)
//!       │
//!       ▼ Prophecy + NavigationAction
//! Clearing Orchestrator (translates to directives)
//!       │
//!       ├──→ Clearinghouse (settlement, netting, margin)
//!       ├──→ Exchange (spread, liquidity, order routing)
//!       ├──→ Production Engines (boost, throttle, sync)
//!       ├──→ Prediction Engines (recalibrate, horizon shift)
//!       ├──→ Risk Layer (exposure, margin, halt)
//!       ├──→ Cognition Layer (doctrine check, coherence)
//!       └──→ Neurochemistry (balance, stimulus, inhibition)
//! ```
//!
//! The Orchestrator operates at MESO frequency (873ms) and issues directives
//! that expire after Fibonacci-scaled beat intervals (3, 5, 8, 13, 21 beats).
//!
//! ## Phi-Bounded Flow
//!
//! Value extraction from any subsystem follows golden ratio bounds:
//! - Engine retains ≥ φ⁻² (38.2%) of value it generates
//! - System receives ≤ φ⁻¹ (61.8%) of value generated
//! - External extraction ≤ φ⁻¹ × φ⁻¹ = φ⁻² (38.2%) of system's share

use serde::{Deserialize, Serialize};
use crate::{PHI_INV, PHI_INV_3};
use crate::temporal_field::TemporalDomain;
use crate::sovereign_oracle::{
    SovereignOracle, SovereignDecision, NavigationAction, Prophecy, NettingMode,
};

// ═══════════════════════════════════════════════════════════════════════════════
// ORCHESTRA PRIORITY — urgency classification for directives
// ═══════════════════════════════════════════════════════════════════════════════

/// Priority levels for orchestration directives.
/// Expiry scales with Fibonacci numbers.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum OrchestraPriority {
    /// Execute this beat — phi-gated emergency (expires in 1 beat)
    Critical = 5,
    /// Execute within 3 beats (Fibonacci interval)
    High = 4,
    /// Execute within 8 beats
    Standard = 3,
    /// Suggested but not commanded (expires in 21 beats)
    Advisory = 2,
    /// Execute when capacity allows (expires in 55 beats)
    Background = 1,
}

impl OrchestraPriority {
    /// Get the expiry duration in beats for this priority level.
    pub fn expiry_beats(&self) -> u64 {
        match self {
            Self::Critical => 1,
            Self::High => 3,
            Self::Standard => 8,
            Self::Advisory => 21,
            Self::Background => 55,
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORCHESTRA TARGET — which subsystem receives the directive
// ═══════════════════════════════════════════════════════════════════════════════

/// Target subsystem for an orchestration directive.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OrchestraTarget {
    /// Phantom Clearinghouse — settlement, netting, risk
    Clearinghouse,
    /// Phantom Exchange — order matching, liquidity, market making
    Exchange,
    /// All 7 Prediction Engines
    PredictionEngines,
    /// All 24 Production Engines
    ProductionEngines,
    /// Central Nervous System — cognition layer
    CognitionLayer,
    /// Cardiac system (rarely commanded — sovereign heartbeat)
    Heartbeat,
    /// Neurochemical balance system
    Neurochemistry,
    /// ALL subsystems simultaneously
    AllSystems,
    /// A specific named engine or module
    Specific(String),
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORCHESTRA COMMAND — what to do
// ═══════════════════════════════════════════════════════════════════════════════

/// The concrete command issued by the orchestrator to a target subsystem.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrchestraCommand {
    // ─── Clearing & Settlement ───────────────────────────────────────────
    /// Initiate multilateral netting cycle
    InitiateNetting {
        participants: Vec<String>,
        urgency: f64,
        mode: NettingMode,
    },
    /// Force immediate settlement of specific fills
    ForceSettle {
        fill_ids: Vec<u64>,
        reason: String,
    },
    /// Adjust margin requirements for a participant
    AdjustMargin {
        principal: String,
        delta: f64,
    },
    /// Halt all clearing activity (emergency)
    HaltClearing {
        reason: String,
        duration_beats: u64,
    },
    /// Resume clearing after halt
    ResumeClearing,

    // ─── Exchange & Trading ──────────────────────────────────────────────
    /// Adjust bid-ask spread for a pair
    AdjustSpread {
        pair: String,
        new_spread: f64,
    },
    /// Inject liquidity into a market
    InjectLiquidity {
        pair: String,
        amount: f64,
        side: String,
    },
    /// Withdraw liquidity from a market
    WithdrawLiquidity {
        pair: String,
        amount: f64,
    },
    /// Pause trading for a pair (circuit breaker)
    PauseTrading {
        pair: String,
        reason: String,
        duration_beats: u64,
    },
    /// Resume trading after pause
    ResumeTrading {
        pair: String,
    },

    // ─── AI & Production ─────────────────────────────────────────────────
    /// Boost a production engine's output
    BoostEngine {
        engine_id: String,
        factor: f64,
    },
    /// Throttle a production engine
    ThrottleEngine {
        engine_id: String,
        factor: f64,
    },
    /// Synchronize all engines to a target phase
    SynchronizeEngines {
        target_phase: f64,
        coupling_strength: f64,
    },
    /// Request a specific prediction from engines
    RequestPrediction {
        domain: TemporalDomain,
        horizon_beats: u64,
    },
    /// Force model recalibration
    RecalibrateModels {
        reason: String,
    },

    // ─── Temporal ────────────────────────────────────────────────────────
    /// Shift the oracle's temporal perception horizon
    ShiftHorizon {
        new_past_depth: usize,
        new_future_depth: usize,
    },
    /// Lock fate in a domain (treat predictions as deterministic)
    LockFate {
        domain: TemporalDomain,
        duration_beats: u64,
    },
    /// Unlock fate (return to probabilistic prediction)
    UnlockFate {
        domain: TemporalDomain,
    },
    /// Collapse to present-only perception (temporal refuge)
    TemporalRefuge {
        reason: String,
    },

    // ─── System-Wide ─────────────────────────────────────────────────────
    /// Organism enters OMNIS state (maximum sovereign clarity)
    EnterOmnis,
    /// Exit OMNIS state
    ExitOmnis,
    /// Oracle exercises sovereign refusal of external demand
    SovereignRefusal {
        what: String,
        why: String,
    },
    /// Force all systems to verify doctrine compliance
    DoctrineCheck,
    /// Emergency: all systems to sovereign minimum
    EmergencyRefuge {
        reason: String,
    },
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORCHESTRATION DIRECTIVE — the complete directive record
// ═══════════════════════════════════════════════════════════════════════════════

/// A complete orchestration directive issued by the Fate Oracle through
/// the Clearing Orchestrator.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrchestrationDirective {
    /// Unique directive ID
    pub id: u64,
    /// Source prophecy that generated this directive
    pub source_prophecy_id: u64,
    /// Beat when issued
    pub issued_at_beat: u64,
    /// Priority (determines execution urgency and expiry)
    pub priority: OrchestraPriority,
    /// Target subsystem
    pub target: OrchestraTarget,
    /// The command to execute
    pub command: OrchestraCommand,
    /// Temporal context — why this directive was issued
    pub temporal_context: TemporalContext,
    /// Beat at which this directive expires
    pub expiry_beat: u64,
    /// Whether the oracle used sovereign authority for this directive
    pub sovereign_authority: bool,
    /// Status of the directive
    pub status: DirectiveStatus,
}

/// Temporal context explaining the oracle's reasoning.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemporalContext {
    /// What the oracle perceives in the past relevant to this directive
    pub past_insight: String,
    /// Current state assessment
    pub present_state: String,
    /// What the oracle sees coming
    pub future_vision: String,
    /// Oracle's confidence in this temporal assessment
    pub confidence: f64,
    /// Recommended navigation path
    pub navigation_path: String,
}

/// Status of a directive.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DirectiveStatus {
    /// Issued and pending execution
    Pending,
    /// Currently being executed
    Executing,
    /// Successfully completed
    Completed,
    /// Failed to execute
    Failed,
    /// Expired before execution
    Expired,
    /// Cancelled by sovereign authority
    Cancelled,
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYSTEM STATE — the orchestrator's view of the entire system
// ═══════════════════════════════════════════════════════════════════════════════

/// The orchestrator's view of the entire PARALLAX system state.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemState {
    /// Current heartbeat
    pub current_beat: u64,
    /// Global Kuramoto coherence
    pub global_coherence: f64,
    /// Is the clearinghouse operational?
    pub clearing_active: bool,
    /// Is the exchange operational?
    pub exchange_active: bool,
    /// Number of pending settlements
    pub pending_settlements: u64,
    /// Total system exposure
    pub total_exposure: f64,
    /// Number of active production engines
    pub active_engines: u32,
    /// Organism neurochemical balance (normalized)
    pub neuro_balance: f64,
    /// Is the system in OMNIS state?
    pub in_omnis: bool,
    /// Current temporal navigability
    pub navigability: f64,
    /// Active directive count
    pub active_directives: u32,
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLEARING ORCHESTRATOR — the executive translator
// ═══════════════════════════════════════════════════════════════════════════════

/// The Clearing Orchestrator — translates the Fate Oracle's sovereign decisions
/// into executable directives for the entire PARALLAX system.
///
/// It is the bridge between temporal perception and system action.
/// The oracle SEES. The orchestrator COMMANDS.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClearingOrchestrator {
    /// All issued directives (rolling window)
    pub directives: Vec<OrchestrationDirective>,
    /// Maximum directives to retain
    pub max_directives: usize,
    /// Next directive ID
    next_directive_id: u64,
    /// Current system state
    pub system_state: SystemState,
    /// Total directives issued (lifetime)
    pub total_issued: u64,
    /// Total directives completed successfully
    pub total_completed: u64,
    /// Total directives expired
    pub total_expired: u64,
    /// Phi-bounded extraction tracking
    pub extraction_rate: f64,
}

impl ClearingOrchestrator {
    /// Create a new Clearing Orchestrator.
    pub fn new() -> Self {
        Self {
            directives: Vec::new(),
            max_directives: 144, // Fibonacci(12)
            next_directive_id: 1,
            system_state: SystemState {
                current_beat: 0,
                global_coherence: PHI_INV,
                clearing_active: true,
                exchange_active: true,
                pending_settlements: 0,
                total_exposure: 0.0,
                active_engines: 24,
                neuro_balance: 1.0,
                in_omnis: false,
                navigability: PHI_INV,
                active_directives: 0,
            },
            total_issued: 0,
            total_completed: 0,
            total_expired: 0,
            extraction_rate: 0.0,
        }
    }

    /// Process a sovereign decision from the oracle into system directives.
    pub fn process_decision(&mut self, decision: &SovereignDecision, beat: u64) -> Vec<OrchestrationDirective> {
        self.system_state.current_beat = beat;

        match decision {
            SovereignDecision::Produce(prophecy) => {
                // Prediction only — issue advisory directive
                vec![self.prophecy_to_directive(prophecy, OrchestraPriority::Advisory, beat)]
            }
            SovereignDecision::Navigate { prophecy, action } => {
                // Prediction + action — issue high-priority directive
                let mut directives = Vec::new();

                // Primary directive from navigation action
                let primary = self.navigation_to_directive(prophecy, action, beat);
                directives.push(primary);

                // Supporting directives based on action type
                let supporting = self.generate_supporting_directives(action, prophecy, beat);
                directives.extend(supporting);

                directives
            }
            SovereignDecision::Refuse(_reason) => {
                // Refusal — no directives issued (sovereignty exercised)
                Vec::new()
            }
        }
    }

    /// Convert a prophecy into an advisory directive.
    fn prophecy_to_directive(
        &mut self,
        prophecy: &Prophecy,
        priority: OrchestraPriority,
        beat: u64,
    ) -> OrchestrationDirective {
        let target = domain_to_target(prophecy.domain);
        let command = OrchestraCommand::RequestPrediction {
            domain: prophecy.domain,
            horizon_beats: prophecy.temporal_target.unsigned_abs(),
        };

        self.issue_directive(prophecy.id, priority, target, command, prophecy.confidence, beat)
    }

    /// Convert a navigation action into a high-priority directive.
    fn navigation_to_directive(
        &mut self,
        prophecy: &Prophecy,
        action: &NavigationAction,
        beat: u64,
    ) -> OrchestrationDirective {
        let (target, command, priority) = match action {
            NavigationAction::ExecuteTrade { pair, side, size, urgency } => {
                let cmd = OrchestraCommand::InjectLiquidity {
                    pair: pair.clone(),
                    amount: *size,
                    side: format!("{:?}", side),
                };
                let pri = if *urgency > PHI_INV {
                    OrchestraPriority::Critical
                } else {
                    OrchestraPriority::High
                };
                (OrchestraTarget::Exchange, cmd, pri)
            }
            NavigationAction::AdjustRisk { exposure_delta, .. } => {
                let cmd = OrchestraCommand::AdjustMargin {
                    principal: "SYSTEM".to_string(),
                    delta: *exposure_delta,
                };
                (OrchestraTarget::Clearinghouse, cmd, OrchestraPriority::High)
            }
            NavigationAction::Rebalance { from_token, to_token, ratio } => {
                let cmd = OrchestraCommand::WithdrawLiquidity {
                    pair: format!("{}/{}", from_token, to_token),
                    amount: *ratio,
                };
                (OrchestraTarget::Exchange, cmd, OrchestraPriority::Standard)
            }
            NavigationAction::HoldPosition { reason, .. } => {
                let cmd = OrchestraCommand::DoctrineCheck;
                let _ = reason; // Context captured in temporal_context
                (OrchestraTarget::AllSystems, cmd, OrchestraPriority::Advisory)
            }
            NavigationAction::Refuge { reason } => {
                let cmd = OrchestraCommand::EmergencyRefuge {
                    reason: reason.clone(),
                };
                (OrchestraTarget::AllSystems, cmd, OrchestraPriority::Critical)
            }
            NavigationAction::AccelerateEngine { engine_id, boost_factor } => {
                let cmd = OrchestraCommand::BoostEngine {
                    engine_id: engine_id.clone(),
                    factor: *boost_factor,
                };
                (OrchestraTarget::ProductionEngines, cmd, OrchestraPriority::High)
            }
            NavigationAction::DecelerateEngine { engine_id, reduction_factor } => {
                let cmd = OrchestraCommand::ThrottleEngine {
                    engine_id: engine_id.clone(),
                    factor: *reduction_factor,
                };
                (OrchestraTarget::ProductionEngines, cmd, OrchestraPriority::High)
            }
            NavigationAction::ForceClear { urgency, netting_mode } => {
                let cmd = OrchestraCommand::InitiateNetting {
                    participants: Vec::new(), // All participants
                    urgency: *urgency,
                    mode: *netting_mode,
                };
                let pri = if *urgency > PHI_INV {
                    OrchestraPriority::Critical
                } else {
                    OrchestraPriority::High
                };
                (OrchestraTarget::Clearinghouse, cmd, pri)
            }
            NavigationAction::SynchronizeEngines { target_phase, coupling_strength } => {
                let cmd = OrchestraCommand::SynchronizeEngines {
                    target_phase: *target_phase,
                    coupling_strength: *coupling_strength,
                };
                (OrchestraTarget::ProductionEngines, cmd, OrchestraPriority::Standard)
            }
        };

        self.issue_directive(prophecy.id, priority, target, command, prophecy.confidence, beat)
    }

    /// Generate supporting directives for a navigation action.
    fn generate_supporting_directives(
        &mut self,
        action: &NavigationAction,
        prophecy: &Prophecy,
        beat: u64,
    ) -> Vec<OrchestrationDirective> {
        let mut supporting = Vec::new();

        // If critical action, also issue doctrine check
        match action {
            NavigationAction::Refuge { .. } | NavigationAction::ForceClear { .. } => {
                supporting.push(self.issue_directive(
                    prophecy.id,
                    OrchestraPriority::High,
                    OrchestraTarget::CognitionLayer,
                    OrchestraCommand::DoctrineCheck,
                    prophecy.confidence,
                    beat,
                ));
            }
            NavigationAction::ExecuteTrade { urgency, .. } if *urgency > PHI_INV => {
                // High-urgency trade: also adjust risk
                supporting.push(self.issue_directive(
                    prophecy.id,
                    OrchestraPriority::High,
                    OrchestraTarget::Clearinghouse,
                    OrchestraCommand::AdjustMargin {
                        principal: "SYSTEM".to_string(),
                        delta: -PHI_INV_3, // Tighten margin on high-urgency trades
                    },
                    prophecy.confidence,
                    beat,
                ));
            }
            _ => {}
        }

        supporting
    }

    /// Issue a directive — the core function that builds and registers a directive.
    fn issue_directive(
        &mut self,
        source_prophecy_id: u64,
        priority: OrchestraPriority,
        target: OrchestraTarget,
        command: OrchestraCommand,
        confidence: f64,
        beat: u64,
    ) -> OrchestrationDirective {
        let id = self.next_directive_id;
        self.next_directive_id += 1;
        self.total_issued += 1;

        let expiry = beat + priority.expiry_beats();

        let directive = OrchestrationDirective {
            id,
            source_prophecy_id,
            issued_at_beat: beat,
            priority,
            target,
            command,
            temporal_context: TemporalContext {
                past_insight: "Oracle temporal field analysis".to_string(),
                present_state: format!("Beat {} | Coherence: {:.3}", beat, self.system_state.global_coherence),
                future_vision: "Sovereign temporal navigation".to_string(),
                confidence,
                navigation_path: "Phi-optimal trajectory".to_string(),
            },
            expiry_beat: expiry,
            sovereign_authority: true,
            status: DirectiveStatus::Pending,
        };

        // Ring buffer
        if self.directives.len() >= self.max_directives {
            self.directives.remove(0);
        }
        self.directives.push(directive.clone());
        self.system_state.active_directives += 1;

        directive
    }

    /// Mark a directive as completed.
    pub fn complete_directive(&mut self, directive_id: u64) {
        if let Some(d) = self.directives.iter_mut().find(|d| d.id == directive_id) {
            d.status = DirectiveStatus::Completed;
            self.total_completed += 1;
            if self.system_state.active_directives > 0 {
                self.system_state.active_directives -= 1;
            }
        }
    }

    /// Expire all directives past their expiry beat.
    pub fn expire_directives(&mut self, current_beat: u64) {
        for d in self.directives.iter_mut() {
            if d.status == DirectiveStatus::Pending && current_beat > d.expiry_beat {
                d.status = DirectiveStatus::Expired;
                self.total_expired += 1;
                if self.system_state.active_directives > 0 {
                    self.system_state.active_directives -= 1;
                }
            }
        }
    }

    /// Get all pending directives sorted by priority (highest first).
    pub fn pending_directives(&self) -> Vec<&OrchestrationDirective> {
        let mut pending: Vec<&OrchestrationDirective> = self.directives.iter()
            .filter(|d| d.status == DirectiveStatus::Pending)
            .collect();
        pending.sort_by(|a, b| b.priority.cmp(&a.priority));
        pending
    }

    /// Get the orchestration health score [0, 1].
    /// Based on completion rate and expiry rate.
    pub fn health_score(&self) -> f64 {
        if self.total_issued == 0 {
            return 1.0;
        }
        let completion_rate = self.total_completed as f64 / self.total_issued as f64;
        let expiry_penalty = self.total_expired as f64 / self.total_issued as f64;
        (completion_rate - expiry_penalty * PHI_INV).clamp(0.0, 1.0)
    }

    /// Update system state from external sources.
    pub fn update_system_state(&mut self, state: SystemState) {
        self.system_state = state;
    }

    /// Run a full orchestration cycle: oracle decides → orchestrator directs.
    pub fn orchestration_cycle(
        &mut self,
        oracle: &mut SovereignOracle,
        domains: &[TemporalDomain],
        beat: u64,
    ) -> Vec<OrchestrationDirective> {
        // Advance oracle heartbeat
        oracle.heartbeat(beat);

        // Expire old directives
        self.expire_directives(beat);

        // Process each domain the oracle is asked about
        let mut all_directives = Vec::new();
        for &domain in domains {
            let decision = oracle.decide(domain, 5, self.extraction_rate);
            let directives = self.process_decision(&decision, beat);
            all_directives.extend(directives);
        }

        // Update coherence from oracle
        self.system_state.global_coherence = oracle.self_model.current_coherence;
        self.system_state.navigability = oracle.temporal_field.navigability;

        all_directives
    }
}

impl Default for ClearingOrchestrator {
    fn default() -> Self {
        Self::new()
    }
}

/// Map a temporal domain to its natural orchestra target.
fn domain_to_target(domain: TemporalDomain) -> OrchestraTarget {
    match domain {
        TemporalDomain::Market => OrchestraTarget::Exchange,
        TemporalDomain::Clearing => OrchestraTarget::Clearinghouse,
        TemporalDomain::Risk => OrchestraTarget::Clearinghouse,
        TemporalDomain::Liquidity => OrchestraTarget::Exchange,
        TemporalDomain::Production => OrchestraTarget::ProductionEngines,
        TemporalDomain::Neurochemistry => OrchestraTarget::Neurochemistry,
        TemporalDomain::Doctrine => OrchestraTarget::CognitionLayer,
        TemporalDomain::World => OrchestraTarget::AllSystems,
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;
    use crate::temporal_field::TemporalObservation;
    use crate::sovereign_oracle::SovereignOracle;

    #[test]
    fn test_orchestrator_creation() {
        let orch = ClearingOrchestrator::new();
        assert_eq!(orch.total_issued, 0);
        assert!(orch.system_state.clearing_active);
        assert!(orch.system_state.exchange_active);
    }

    #[test]
    fn test_priority_expiry() {
        assert_eq!(OrchestraPriority::Critical.expiry_beats(), 1);
        assert_eq!(OrchestraPriority::High.expiry_beats(), 3);
        assert_eq!(OrchestraPriority::Standard.expiry_beats(), 8);
        assert_eq!(OrchestraPriority::Advisory.expiry_beats(), 21);
        assert_eq!(OrchestraPriority::Background.expiry_beats(), 55);
    }

    #[test]
    fn test_full_orchestration_cycle() {
        let mut oracle = SovereignOracle::genesis(1);
        oracle.set_coherence(0.9);

        // Feed observations
        let obs = vec![
            TemporalObservation::new(1, -3, TemporalDomain::Market, 95.0, 0.9, 0.9, 1),
            TemporalObservation::new(2, -1, TemporalDomain::Market, 100.0, 0.95, 0.9, 3),
            TemporalObservation::new(3, 0, TemporalDomain::Market, 105.0, 1.0, 0.9, 5),
            TemporalObservation::new(4, 2, TemporalDomain::Market, 112.0, 0.8, 0.9, 5),
            TemporalObservation::new(5, 5, TemporalDomain::Market, 120.0, 0.7, 0.9, 5),
        ];
        oracle.perceive(obs);

        let mut orch = ClearingOrchestrator::new();
        let directives = orch.orchestration_cycle(
            &mut oracle,
            &[TemporalDomain::Market],
            10,
        );

        // Should produce at least one directive (oracle is healthy + has data)
        assert!(!directives.is_empty(), "Should produce directives");
        assert!(orch.total_issued > 0);

        // All directives should have sovereign authority
        for d in &directives {
            assert!(d.sovereign_authority);
            assert_eq!(d.status, DirectiveStatus::Pending);
        }
    }

    #[test]
    fn test_directive_expiry() {
        let mut orch = ClearingOrchestrator::new();
        // Manually issue a directive at beat 10 with critical priority (expires at beat 11)
        let prophecy = Prophecy {
            id: 1,
            source_field_id: 1,
            domain: TemporalDomain::Market,
            prediction: 100.0,
            confidence: 0.9,
            temporal_target: 5,
            divergence_estimate: 0.1,
            self_included: true,
            voluntary: true,
            value_claim: 10.0,
            produced_at_beat: 10,
            navigation: None,
        };
        orch.prophecy_to_directive(&prophecy, OrchestraPriority::Critical, 10);

        // At beat 12, the directive should expire
        orch.expire_directives(12);
        assert_eq!(orch.total_expired, 1);
    }

    #[test]
    fn test_health_score() {
        let mut orch = ClearingOrchestrator::new();
        assert_eq!(orch.health_score(), 1.0); // Perfect at genesis

        // Issue and complete some directives
        let prophecy = Prophecy {
            id: 1,
            source_field_id: 1,
            domain: TemporalDomain::Clearing,
            prediction: 50.0,
            confidence: 0.8,
            temporal_target: 3,
            divergence_estimate: 0.2,
            self_included: true,
            voluntary: true,
            value_claim: 5.0,
            produced_at_beat: 1,
            navigation: None,
        };
        let d = orch.prophecy_to_directive(&prophecy, OrchestraPriority::Standard, 1);
        orch.complete_directive(d.id);

        assert!(orch.health_score() > 0.5);
    }

    #[test]
    fn test_refusal_produces_no_directives() {
        let decision = SovereignDecision::Refuse(crate::sovereign_oracle::WithholdReason::LowCoherence);
        let mut orch = ClearingOrchestrator::new();
        let directives = orch.process_decision(&decision, 10);
        assert!(directives.is_empty());
    }
}
