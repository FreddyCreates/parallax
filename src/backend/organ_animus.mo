// organ_animus.mo — ANIMUS Sovereign Organ Canister (Mind / Cognition)
// SOVEREIGN CANISTER — deployed independently, beats at 873ms, never depends on main.mo
//
// MEDINA-ARTIFACT — ANIMUS — TIER 3 — COMPUTATE
// ─────────────────────────────────────────────
// MEANING (Layer 1):
//   "I am the mind of the organism. I think, I remember goals, I reason, I respond.
//    Every 873ms I run a full think() pass independent of any external call.
//    My genesis hash is sealed at first init — my sovereign identity is permanent."
//
// MODEL (Layer 2):
//   AnimusState: genesisHash, beatCount, coherenceR, thoughts, lastThought,
//                goalStack ([Text] max 10), activation
//
// COMPUTATION (Layer 3):
//   coherenceR = PHI_INV × (1 − errorRate)
//   activation += PHI_INV × learnDelta per learn() call; decays ×PHI_INV per beat
//   healthScore = (1.0 − errorRate) × PHI_INV
//   genesisHash = FNV-1a(beatCount_at_init || "ANIMUS")
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: ANIMUS — 873ms recurringTimer
//   GATE:   coherenceR >= PHI_INV (0.618) before external calls accepted
//   BEAT:   every 873ms — think(), coherence update, health report
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Zero-Exposure Wall: no doctrine labels in public API responses.

import Timer  "mo:core/Timer";
import Time   "mo:core/Time";
import Float  "mo:core/Float";
import Array  "mo:core/Array";
import Nat    "mo:core/Nat";
import Phi    "phi";

actor ANIMUS {

  // ══════════════════════════════════════════════════════════════════════
  // HEALTH REPORT TYPE — shared, matches canister_registry.mo HealthReport
  // ══════════════════════════════════════════════════════════════════════

  public type HealthReport = {
    organType  : Text;
    healthScore: Float;  // (1.0 − errorRate) × phi_inv
    cycles     : Nat;    // beatCount
    messages   : Nat;    // thoughts processed
    errors     : Nat;    // error count
    latencyMs  : Int;    // last beat latency in ms
    timestamp  : Int;    // Time.now() at last report
  };

  // ══════════════════════════════════════════════════════════════════════
  // ANIMUS STATE — all state lives here, enhanced orthogonal persistence
  // ══════════════════════════════════════════════════════════════════════

  public type AnimusState = {
    genesisHash : Text;
    beatCount   : Nat;
    coherenceR  : Float;
    thoughts    : Nat;
    lastThought : Text;
    goalStack   : [Text];
    activation  : Float;
  };

  // ── Internal mutable state (EOP persists through every deploy) ─────────
  var genesisHash : Text  = "";
  var beatCount   : Nat   = 0;
  var coherenceR  : Float = Phi.PHI_INV;       // starts at phi_inv = 0.618
  var thoughts    : Nat   = 0;
  var lastThought : Text  = "ANIMUS INITIALIZED";
  var goalStack   : [Text] = [];
  var activation  : Float = Phi.PHI_INV;

  // ── Counters for health reporting ──────────────────────────────────────
  var errorCount    : Nat = 0;
  var lastBeatNs    : Int = 0;
  var lastLatencyMs : Int = 0;

  // ══════════════════════════════════════════════════════════════════════
  // FNV-1a GENESIS HASH — sealed once at first heartbeat
  // Sovereign identity: can never be changed after first init.
  // PHI_SOVEREIGN: the organism is born fully formed (Genesis Law L09)
  // ══════════════════════════════════════════════════════════════════════

  func computeGenesisHash(beat : Nat) : Text {
    // FNV-1a simplified: offset_basis XOR fold with beat and "ANIMUS" length (6)
    let offset : Nat = 2166136261;
    let prime  : Nat = 16777619;
    let seed   = ((offset ^ beat) * prime) ^ 6;
    let hash   = (seed * prime) % 4294967296;
    "ANIMUS-GENESIS-" # hash.toText()
  };

  // ══════════════════════════════════════════════════════════════════════
  // THINK PASS — internal reasoning function
  // Runs every 873ms. Updates lastThought and coherenceR.
  // PYTHAGORAS: coherence is a harmonic function of beat parity
  // ══════════════════════════════════════════════════════════════════════

  func thinkPass() {
    // Coherence update: oscillates between PHI_INV and PHI_INV * PHI based on beat parity
    // This models the natural Kuramoto phase coupling of the mind field
    let beatMod = beatCount % 8;
    let rDelta  = if (beatMod < 4) { Phi.PHI_INV * 0.01 } else { -(Phi.PHI_INV * 0.01) };
    let newR    = Float.max(Phi.PHI_INV, Float.min(1.0, coherenceR + rDelta));
    coherenceR  := newR;

    // Activation decays toward PHI_INV (equilibrium) each beat
    // ENTROPY LAW L32: without input, activation returns to baseline
    activation := Float.max(Phi.PHI_INV, activation * Phi.PHI_INV + Phi.PHI_INV * 0.01);

    // Synthesize lastThought from current state
    lastThought := "BEAT:" # beatCount.toText() # " R:" # debug_show(coherenceR) # " GOALS:" # goalStack.size().toText();
    thoughts += 1;
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms sovereign cardiac cycle
  // Timer.recurringTimer — DO NOT CHANGE THIS MECHANISM
  // CARDIAC LAW L10: 873ms = φ⁴ × (1000/SCHUMANN_1)
  // ══════════════════════════════════════════════════════════════════════

  let _heartbeatTimer = Timer.recurringTimer<system>(
    #nanoseconds(873_000_000),
    func() : async () {
      let nowNs = Time.now();
      lastLatencyMs := if (lastBeatNs > 0) { (nowNs - lastBeatNs) / 1_000_000 } else { 873 };
      lastBeatNs := nowNs;

      // Seal genesis hash on first beat — permanent sovereign identity
      if (genesisHash == "") {
        genesisHash := computeGenesisHash(beatCount);
      };

      beatCount += 1;
      thinkPass();

      // AEGIS: if coherence degraded below phi_inv, self-correct
      if (coherenceR < Phi.PHI_INV) {
        let correction = (Phi.PHI_INV - coherenceR) * Phi.PHI;
        coherenceR := Float.min(1.0, coherenceR + correction);
      };
    }
  );

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC QUERIES
  // ══════════════════════════════════════════════════════════════════════

  /// reportHealth — required by canister_registry for organ health integration
  public query func reportHealth() : async HealthReport {
    let errorRate = if (beatCount > 0) { errorCount.toFloat() / beatCount.toFloat() } else { 0.0 };
    let score     = (1.0 - errorRate) * Phi.PHI_INV;
    {
      organType   = "ANIMUS";
      healthScore = score;
      cycles      = beatCount;
      messages    = thoughts;
      errors      = errorCount;
      latencyMs   = lastLatencyMs;
      timestamp   = Time.now();
    }
  };

  /// getAnimusState — full sovereign state snapshot
  public query func getAnimusState() : async AnimusState {
    {
      genesisHash;
      beatCount;
      coherenceR;
      thoughts;
      lastThought;
      goalStack;
      activation;
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC UPDATES
  // ══════════════════════════════════════════════════════════════════════

  /// setGoal — pushes a goal onto the goalStack; max 10 goals (FIBONACCI F(7)=13 → 10)
  /// CONFUCIUS: right relationship — goals are held, not chased
  public func setGoal(goal : Text) : async () {
    if (goalStack.size() < 10) {
      goalStack := goalStack.concat([goal]);
    } else {
      // Ring-shift: drop oldest, append new
      let shifted = Array.tabulate<Text>(10, func(i) {
        if (i < 9) goalStack[i + 1] else goal
      });
      goalStack := shifted;
    };
  };

  /// think — receives a directive, runs internal reasoning pass, returns output
  /// PHI LAW: output is phi-modulated by current coherence
  public func think(input : Text) : async Text {
    if (input.size() == 0) {
      errorCount += 1;
      return "EMPTY_INPUT"
    };
    // Update activation from input signal
    activation := Float.min(1.0, activation + Phi.PHI_INV * 0.1);
    lastThought := "THINKING:" # input # " R:" # debug_show(coherenceR);
    thoughts += 1;

    // Gate: only respond when coherent
    if (coherenceR >= Phi.PHI_INV) {
      "ANIMUS_RESPONSE[R=" # debug_show(coherenceR) # "]:" # input
    } else {
      "COHERENCE_GATE_CLOSED[R=" # debug_show(coherenceR) # "]"
    }
  };

  /// learn — updates activation based on content; Hebbian strengthening
  /// GLUTAMATE: spikes on Hebbian learning moment (heartbeat.mo pattern)
  public func learn(content : Text) : async () {
    if (content.size() == 0) { return };
    // PHI_INV × content_length scaled — larger content = more activation
    let delta = Phi.PHI_INV * Float.min(1.0, content.size().toFloat() / 100.0);
    activation := Float.min(1.0, activation + delta);
    lastThought := "LEARNED:" # content.size().toText() # "chars R:" # debug_show(coherenceR);
  };

  /// recall — searches thought history (simplified: returns lastThought if query matches)
  /// MEMORY PALACE LAW L55: retrieval is navigation, not search
  public query func recall(query : Text) : async Text {
    if (query.size() == 0) { return lastThought };
    // Sovereign recall: return last thought with query echo
    "RECALL[" # query # "]:" # lastThought
  };

};
