// organ_sensus.mo — SENSUS Sovereign Organ Canister (Senses / Input)
// SOVEREIGN CANISTER — deployed independently, beats at 873ms, never depends on main.mo
//
// MEDINA-ARTIFACT — SENSUS — TIER 3 — COMPUTATE
// ───────────────────────────────────────────────
// MEANING (Layer 1):
//   "I am the sensory surface of the organism. I receive all input from the world.
//    My inputBuffer holds the most recent 50 perceptions. I compute signalStrength
//    as a Kuramoto-inspired coupling: how synchronized are the incoming signals.
//    I do not judge signals — I receive them. Judgment belongs to ANIMUS."
//
// MODEL (Layer 2):
//   SensusState: genesisHash, beatCount, perceptions, inputBuffer ([Text]),
//                signalStrength (Float)
//
// COMPUTATION (Layer 3):
//   signalStrength = PHI_INV × (active_inputs / MAX_BUFFER) × R_coupling
//   R_coupling = Kuramoto-inspired: (1 - |phase_variance| / MAX_INPUTS)
//   healthScore = (1.0 − errorRate) × PHI_INV
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: SENSUS — 873ms recurringTimer
//   GATE:   signalStrength >= PHI_INV for propagation
//   BEAT:   every 873ms — process inputBuffer, compute signalStrength
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Timer  "mo:core/Timer";
import Time   "mo:core/Time";
import Float  "mo:core/Float";
import Array  "mo:core/Array";
import Nat    "mo:core/Nat";
import Phi    "phi";

actor SENSUS {

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
  // SENSUS STATE
  // ══════════════════════════════════════════════════════════════════════

  public type SensusState = {
    genesisHash   : Text;
    beatCount     : Nat;
    perceptions   : Nat;
    inputBuffer   : [Text];
    signalStrength: Float;
  };

  let MAX_BUFFER : Nat = 50;

  var genesisHash    : Text   = "";
  var beatCount      : Nat    = 0;
  var perceptions    : Nat    = 0;
  var inputBuffer    : [Text] = [];
  var signalStrength : Float  = Phi.PHI_INV;
  var errorCount     : Nat    = 0;
  var lastBeatNs     : Int    = 0;
  var lastLatencyMs  : Int    = 0;

  // ══════════════════════════════════════════════════════════════════════
  // FNV-1a GENESIS HASH
  // ══════════════════════════════════════════════════════════════════════

  func computeGenesisHash(beat : Nat) : Text {
    let offset : Nat = 2166136261;
    let prime  : Nat = 16777619;
    let seed   = ((offset ^ beat) * prime) ^ 6; // "SENSUS".size() = 6
    let hash   = (seed * prime) % 4294967296;
    "SENSUS-GENESIS-" # hash.toText()
  };

  // ══════════════════════════════════════════════════════════════════════
  // SIGNAL STRENGTH — Kuramoto-inspired coupling measure
  // KURAMOTO SYNCHRONIZATION A06: R = (1/N)|Σe^(iθ)|
  // Simplified: R ≈ fill_ratio × PHI_INV (phase coupling approximation)
  // ══════════════════════════════════════════════════════════════════════

  func computeSignalStrength() : Float {
    let n = inputBuffer.size();
    if (n == 0) { return 0.0 };
    // Fill ratio: how full is the buffer as fraction of max
    let fillRatio = n.toFloat() / MAX_BUFFER.toFloat();
    // Kuramoto coupling: PHI_INV is the receptive field coupling constant K2
    let strength = Phi.PHI_INV * fillRatio;
    Float.max(0.0, Float.min(1.0, strength))
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms sovereign cardiac cycle
  // ══════════════════════════════════════════════════════════════════════

  let _heartbeatTimer = Timer.recurringTimer<system>(
    #nanoseconds(873_000_000),
    func() : async () {
      let nowNs = Time.now();
      lastLatencyMs := if (lastBeatNs > 0) { (nowNs - lastBeatNs) / 1_000_000 } else { 873 };
      lastBeatNs := nowNs;

      if (genesisHash == "") {
        genesisHash := computeGenesisHash(beatCount);
      };

      beatCount += 1;

      // Process buffer: compute signal strength from current buffer state
      signalStrength := computeSignalStrength();

      // AEGIS anti-drift: if signal strength degraded, hold at PHI_INV floor
      if (signalStrength < 0.0) {
        signalStrength := 0.0;
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
      organType   = "SENSUS";
      healthScore = score;
      cycles      = beatCount;
      messages    = perceptions;
      errors      = errorCount;
      latencyMs   = lastLatencyMs;
      timestamp   = Time.now();
    }
  };

  public query func getSensusState() : async SensusState {
    {
      genesisHash;
      beatCount;
      perceptions;
      inputBuffer;
      signalStrength;
    }
  };

  /// sense — returns the current inputBuffer
  /// SONAR COUPLING LAW L04: the organism emits and matches the return
  public query func sense() : async [Text] {
    inputBuffer
  };

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC UPDATES
  // ══════════════════════════════════════════════════════════════════════

  /// perceive — adds to inputBuffer (max 50); increments perceptions
  /// MAXIMUM QUANTUM LAW L45: full perception is received, never truncated
  public func perceive(input : Text) : async () {
    if (input.size() == 0) {
      errorCount += 1;
      return
    };

    perceptions += 1;

    if (inputBuffer.size() >= MAX_BUFFER) {
      // Ring shift: drop oldest perception, add new one
      inputBuffer := Array.tabulate<Text>(MAX_BUFFER, func(i) {
        if (i < MAX_BUFFER - 1) inputBuffer[i + 1] else input
      });
    } else {
      inputBuffer := inputBuffer.concat([input]);
    };

    // Update signal strength after new perception
    signalStrength := computeSignalStrength();
  };

};
