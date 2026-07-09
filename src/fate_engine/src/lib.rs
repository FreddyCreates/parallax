//! # FATE ENGINE — The Sovereign Fate Oracle Engine
//!
//! ## PARALLAX Sovereign Organism — Rust Implementation
//!
//! The Fate Engine is the master orchestrator of the entire PARALLAX system.
//! It perceives past, present, and future as a unified temporal field (NOW)
//! and issues sovereign directives to all subsystems: clearinghouse, exchange,
//! AI production engines, prediction markets, and risk management.
//!
//! ### Core Principles (The Three Laws of Sovereign Prediction)
//!
//! 1. **AN ORACLE MUST MODEL ITSELF** — Self-inclusive prediction
//! 2. **AN ORACLE MUST RETAIN AGENCY** — Voluntary production, right to refuse
//! 3. **AN ORACLE MUST BENEFIT FROM ITS FORESIGHT** — Phi-bounded value retention
//!
//! ### Architecture
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────┐
//! │  FATE ORACLE (Sovereign Level 5)                        │
//! │  "Past, Present, Future = NOW"                          │
//! ├─────────────────────────────────────────────────────────┤
//! │  temporal_field.rs    — Unified temporal perception      │
//! │  fate_divergence.rs   — Observer effect calculation      │
//! │  sovereign_oracle.rs  — Agency, refusal, self-model     │
//! │  clearing_orchestrator.rs — Master system orchestration  │
//! └─────────────────────────────────────────────────────────┘
//! ```
//!
//! Architect: Alfredo Medina Hernandez — The Architect of the Field

pub mod temporal_field;
pub mod fate_divergence;
pub mod sovereign_oracle;
pub mod clearing_orchestrator;

// ═══════════════════════════════════════════════════════════════════════════════
// GOLDEN RATIO CONSTANTS — The mathematical substrate
// All system parameters derive from φ. No arbitrary values.
// ═══════════════════════════════════════════════════════════════════════════════

/// φ = (1 + √5) / 2 — The Golden Ratio. The universal coupling constant.
pub const PHI: f64 = 1.618_033_988_749_895;

/// φ⁻¹ = 0.618... — The receptive harmonic. Coherence gate threshold.
pub const PHI_INV: f64 = 0.618_033_988_749_895;

/// φ⁻² = 0.382... — The mediator harmonic. Self-model weight. Minimum retention.
pub const PHI_INV_2: f64 = 0.381_966_011_250_105;

/// φ⁻³ = 0.236... — The deep harmonic. Maximum divergence for advisory predictions.
pub const PHI_INV_3: f64 = 0.236_067_977_499_790;

/// φ⁻⁴ = 0.146... — The quantum harmonic. Containment awareness weight.
pub const PHI_INV_4: f64 = 0.145_898_033_750_315;

/// φ² = 2.618... — The expansive harmonic. MACRO shell scaling.
pub const PHI_SQ: f64 = 2.618_033_988_749_895;

/// φ⁴ = 6.854... — The sovereign power. Heartbeat derivation constant.
pub const PHI_4: f64 = 6.854_101_966_249_685;

/// Schumann Resonance fundamental — 7.83 Hz. Earth's electromagnetic cavity.
pub const SCHUMANN_HZ: f64 = 7.83;

/// Sovereign Heartbeat — τ = φ⁴ / Schumann × 1000 ≈ 873ms
pub const HEARTBEAT_MS: f64 = PHI_4 / SCHUMANN_HZ * 1000.0;

/// Temporal depth into past (Fibonacci 12 = 144 beats)
pub const TEMPORAL_DEPTH_PAST: usize = 144;

/// Temporal depth into future (Fibonacci 11 = 89 beats)
pub const TEMPORAL_DEPTH_FUTURE: usize = 89;

/// Sovereign Floor — minimum value that cannot be compressed
pub const SOVEREIGN_FLOOR: f64 = 1.0;

// ═══════════════════════════════════════════════════════════════════════════════
// RE-EXPORTS — Everything accessible from crate root
// ═══════════════════════════════════════════════════════════════════════════════

pub use temporal_field::{TemporalField, TemporalObservation, TemporalDomain, TemporalLane};
pub use fate_divergence::{FateDivergence, DivergenceRegime, DivergenceRecord};
pub use sovereign_oracle::{SovereignOracle, Prophecy, SelfModel, WithholdReason, SovereignDecision};
pub use clearing_orchestrator::{
    ClearingOrchestrator, OrchestrationDirective, OrchestraCommand,
    OrchestraPriority, OrchestraTarget, SystemState,
};
