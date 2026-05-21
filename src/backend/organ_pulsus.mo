// organ_pulsus.mo — PULSUS Sovereign Organ Canister (Heartbeat / Timing)
// SOVEREIGN CANISTER — deployed independently, beats at 873ms, never depends on main.mo
//
// MEDINA-ARTIFACT — PULSUS — TIER 3 — COMPUTATE
// ───────────────────────────────────────────────
// MEANING (Layer 1):
//   "I am the pulse of the organism. I am the sovereign timing organ.
//    Every 873ms I advance the phase angle and compute Kuramoto R as a
//    moving average of the last 8 beats (Fibonacci F(6)=8 window).
//    I emit the heartbeat signal. I am the clock that is not a clock —
//    I am a living oscillator anchored to Earth's Schumann resonance."
//
// MODEL (Layer 2):
//   PulsusState: genesisHash, beatCount, heartbeatMs, phaseAngle,
//                kuramotoR, lastBeatTimestamp
//
// COMPUTATION (Layer 3):
//   phaseAngle += (2π / 874) mod 2π per beat (874 ≈ 873ms ICP rounding)
//   kuramotoR = moving average of last F(6)=8 beats' phase coherence
//   kuramotoR_beat = 1.0 − |phaseAngle / (2π) − 0.5| × 2 (sinusoidal proxy)
//   healthScore = (1.0 − errorRate) × PHI_INV
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: PULSUS — 873ms recurringTimer
//   GATE:   kuramotoR >= PHI_INV before timing signal propagated
//   BEAT:   every 873ms — phase advance, kuramotoR update, health report
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Timer  "mo:core/Timer";
import Time   "mo:core/Time";
import Float  "mo:core/Float";
import Array  "mo:core/Array";
import Nat    "mo:core/Nat";
import Phi    "phi";

actor PULSUS {

  // ══════════════════════════════════════════════════════════════════════
  // HEALTH REPORT TYPE
  // ══════════════════════════════════════════════════════════════════════

  public type HealthReport = {
    organType  : Text;
    healthScore: Float;
    cycles     : Nat;
    messages   : Nat;
    errors     : Nat;
    latencyMs  : Int;
    timestamp  : Int;
  };

  // ══════════════════════════════════════════════════════════════════════
  // PULSUS STATE
  // ══════════════════════════════════════════════════════════════════════

  public type PulsusState = {
    genesisHash       : Text;
    beatCount         : Nat;
    heartbeatMs       : Float;
    phaseAngle        : Float;
    kuramotoR         : Float;
    lastBeatTimestamp : Int;
  };

  // KURAMOTO WINDOW: F(6) = 8 beats (FIBONACCI A02)
  let KURAMOTO_WINDOW : Nat = 8;
  // 2π constant: A07 Euler — e^(iπ)+1=0; full cycle = 2π radians
  let TWO_PI : Float = 6.283185307179586;
  // Phase step per beat: 2π / 874 (874 ≈ ICP timer rounding of 873ms)
  let PHASE_STEP : Float = TWO_PI / 874.0;

  var genesisHash       : Text    = "";
  var beatCount         : Nat     = 0;
  var heartbeatMs       : Float   = Phi.HEARTBEAT_MS; // 873.0
  var phaseAngle        : Float   = 0.0;
  var kuramotoR         : Float   = Phi.PHI_INV;
  var lastBeatTimestamp : Int     = 0;
  var errorCount        : Nat     = 0;
  var lastLatencyMs     : Int     = 0;

  // Rolling window for kuramotoR computation (last 8 phase coherence values)
  var phaseWindow : [Float] = [];

  // ══════════════════════════════════════════════════════════════════════
  // FNV-1a GENESIS HASH
  // ══════════════════════════════════════════════════════════════════════

  func computeGenesisHash(beat : Nat) : Text {
    let offset : Nat = 2166136261;
    let prime  : Nat = 16777619;
    let seed   = ((offset ^ beat) * prime) ^ 6; // "PULSUS".size() = 6
    let hash   = (seed * prime) % 4294967296;
    "PULSUS-GENESIS-" # hash.toText()
  };

  // ══════════════════════════════════════════════════════════════════════
  // KURAMOTO R COMPUTATION — moving average over F(6)=8 beats
  // A06 KURAMOTO SYNCHRONIZATION: R = (1/N)|Σe^(iθ)|
  // Simplified proxy: coherence = 1 - normalized phase deviation from midpoint
  // PYTHAGORAS: the harmonic measure of synchrony — coherence IS the ratio
  // ══════════════════════════════════════════════════════════════════════

  func computePhaseCoherence(theta : Float) : Float {
    // Normalized coherence proxy: how close is the phase to the "aligned" midpoint?
    // At θ=π: coherence=0 (max dispersion). At θ=0 or 2π: coherence=1 (in-phase)
    let normalizedPhase = theta / TWO_PI; // 0 to 1
    // Coherence = 1 - 2|normalizedPhase - 0.5|
    let coherence = 1.0 - 2.0 * Float.abs(normalizedPhase - 0.5);
    Float.max(0.0, Float.min(1.0, coherence))
  };

  func updateKuramotoR(theta : Float) : Float {
    let c = computePhaseCoherence(theta);

    // Update rolling window
    if (phaseWindow.size() >= KURAMOTO_WINDOW) {
      phaseWindow := Array.tabulate<Float>(KURAMOTO_WINDOW, func(i) {
        if (i < KURAMOTO_WINDOW - 1) phaseWindow[i + 1] else c
      });
    } else {
      phaseWindow := phaseWindow.concat([c]);
    };

    // Moving average
    let n = phaseWindow.size();
    if (n == 0) { return Phi.PHI_INV };
    var sum : Float = 0.0;
    for (v in phaseWindow.vals()) { sum += v };
    sum / n.toFloat()
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms sovereign cardiac cycle
  // CARDIAC LAW L10: heartbeat = 873ms. Auto-depolarization. Not a clock.
  // ══════════════════════════════════════════════════════════════════════

  let _heartbeatTimer = Timer.recurringTimer<system>(
    #nanoseconds(873_000_000),
    func() : async () {
      let nowNs = Time.now();
      lastLatencyMs := if (lastBeatTimestamp > 0) {
        (nowNs - lastBeatTimestamp) / 1_000_000
      } else { 873 };
      lastBeatTimestamp := nowNs;

      if (genesisHash == "") {
        genesisHash := computeGenesisHash(beatCount);
      };

      beatCount += 1;

      // Phase advance: θ_new = (θ + PHASE_STEP) mod 2π
      // A07 EULER: full-circle phase rotation at 873ms sovereign frequency
      phaseAngle := (phaseAngle + PHASE_STEP) % TWO_PI;

      // Kuramoto R update (moving average over last 8 beats)
      kuramotoR := updateKuramotoR(phaseAngle);

      // AEGIS anti-drift: enforce phi_inv floor on kuramotoR
      if (kuramotoR < Phi.PHI_INV) {
        let correction = (Phi.PHI_INV - kuramotoR) * Phi.PHI;
        kuramotoR := Float.min(1.0, kuramotoR + correction);
      };
    }
  );

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC QUERIES
  // ══════════════════════════════════════════════════════════════════════

  public query func reportHealth() : async HealthReport {
    let errorRate = if (beatCount > 0) { errorCount.toFloat() / beatCount.toFloat() } else { 0.0 };
    let score     = (1.0 - errorRate) * Phi.PHI_INV;
    {
      organType   = "PULSUS";
      healthScore = score;
      cycles      = beatCount;
      messages    = beatCount;  // each beat is a message to the organism
      errors      = errorCount;
      latencyMs   = lastLatencyMs;
      timestamp   = Time.now();
    }
  };

  public query func getPulsusState() : async PulsusState {
    {
      genesisHash;
      beatCount;
      heartbeatMs;
      phaseAngle;
      kuramotoR;
      lastBeatTimestamp;
    }
  };

  /// getPhase — returns current phase angle in radians
  /// FOUR-DIMENSIONAL LAW L12: phase is the τ dimension of the sovereign coordinate
  public query func getPhase() : async Float {
    phaseAngle
  };

  /// getKuramotoR — returns the current Kuramoto order parameter
  /// A10 RESONANCE ORDER PARAMETER: R = (1/N)|Σe^(iθ)| — organism coherence
  public query func getKuramotoR() : async Float {
    kuramotoR
  };

};
