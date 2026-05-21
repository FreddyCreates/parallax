// ledger_bridge.mo — ICP LEDGER BRIDGE
// PARALLAX Sovereign Cognitive Financial Organism
// Architect: Alfredo Medina Hernandez | Medina Doctrine | Dallas TX USA | 2026
//
// DOCTRINE: Creative identity = Financial identity.
// The catalog IS the balance sheet.
// Every production is simultaneously a financial event.
// The company does not need an external bank.
// Every act of creation is an act of financial sovereignty.
//
// RESIDENTS: LedgerEvent, LedgerState — persist permanently on-chain
// COMPUTATES: recordArtifactSeal, getLedgerState, getCatalogDepth, etc. — fire every seal
//
// LAYER 1 — MEANING (Doctrine Clause):
//   "One creative act = one financial act. Same ledger. Same moment. Same proof.
//    The catalog is the balance sheet. Immutable. Append-only. Sovereign."
//
// LAYER 2 — MODEL (Typed Schema): ActorAttribution, LedgerEvent, LedgerState
//
// LAYER 3 — COMPUTATION (State Equations):
//   base = PHI × 1_618_033 cycles (phi-scaled base unit)
//   actual_value = Nat64(quality_score × PHI × 1_618_033.0)
//   compounding: if quality > S0, value × PHI per 0.1 above S0
//   ratio = Σ(doctrine_alignment × quality_score) / total_events
//   weight_i = actor_delta_i / Σ(actor_deltas)
//   cycles_i = total_financial_value × weight_i
//   tx_hash = FNV-1a(event_id # artifact_id # timestamp.toText())
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE: NEURO-BACKEND → FUNCTION: recordArtifactSeal()
//   GATE: every artifact seal event
//   BEAT: every 873ms heartbeat (Cardiac Law L10)
//
// IMMUTABILITY LAW: state.events is APPEND-ONLY.
// No event can ever be modified or deleted. Conservation of Information (A12).
//
// PYTHAGORAS: all ratios harmonic — PHI-derived, no arbitrary constants
// EUCLID: single source of truth — phi.mo for all constants
// CONFUCIUS: right relationship — creative and financial identity are ONE

import Phi   "phi";
import Float "mo:core/Float";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Array "mo:core/Array";
import Time  "mo:core/Time";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 2 — MODELS (RESIDENTS)
  // Each model is a sovereign organism — multi-functional, micro to micro.
  // LedgerEvent is simultaneously a creative record AND a financial record.
  // ═══════════════════════════════════════════════════════════════════════════

  // ActorAttribution — sovereign record of creative contribution
  // Each actor's weight is phi-normalized from their performance delta.
  // cycles_allocated = total_financial_value × (delta_i / Σ deltas)
  public type ActorAttribution = {
    actor_id         : Text;    // unit: label  — sovereign actor identifier
    weight           : Float;   // unit: ratio  — range [0.0, 1.0], phi-normalized
    cycles_allocated : Nat64;   // unit: cycles — range [0, ∞), proportional to weight
  };

  // LedgerEvent — THE RESIDENT
  // Every seal is simultaneously creative and financial.
  // Immutable once written. Append-only. Cannot be destroyed (A12).
  //
  // COMPUTATION (Layer 3):
  //   financial_value_cycles = Nat64(quality_score × PHI × 1_618_033.0)
  //                            × PHI^(steps above S0 / 0.1) if quality > S0
  //   transaction_hash = FNV-1a(event_id # artifact_id # Nat64.toText(timestamp))
  //   doctrine_alignment: measured against genesis frequency baseline (A11)
  public type LedgerEvent = {
    event_id            : Text;               // FNV-1a derived sovereign identifier
    artifact_id         : Text;               // creative artifact — catalog entry
    creation_beat       : Nat64;              // heartbeat at seal — Cardiac Law L10
    artifact_hash       : Text;               // FNV-1a of artifact_id + creation_beat
    quality_score       : Float;              // range [0.0, 1.0] — creative quality
    doctrine_alignment  : Float;              // range [0.0, 1.0] — alignment to genesis freq
    actor_attributions  : [ActorAttribution]; // phi-normalized actor attribution array
    financial_value_cycles : Nat64;           // cycles — actual_value = q × PHI × 1_618_033
    transaction_hash    : Text;               // FNV-1a(event_id # artifact_id # timestamp)
    timestamp           : Nat64;              // nanoseconds — 4D timestamp (Deep Time Law L30)
  };

  // LedgerState — THE CATALOG = THE BALANCE SHEET
  // state.events is APPEND-ONLY — Conservation of Information (A12).
  // Every event in events is simultaneously creative AND financial.
  //
  // creative_to_financial_ratio = Σ(doctrine_alignment × quality_score) / total_events
  // Target: ratio > S0 = 0.75 (Fractal Scale Law L11)
  public type LedgerState = {
    events                    : [LedgerEvent]; // RESIDENTS — append-only sovereign ledger
    total_events              : Nat64;         // catalog depth = balance sheet entries
    total_cycles_accrued      : Nat64;         // Σ financial_value_cycles — treasury total
    creative_to_financial_ratio : Float;       // Σ(doc × qual) / N — sovereignty health
    catalog_depth             : Nat64;         // = total_events — the catalog is the ledger
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL COMPUTATES — Pure functions, no side effects
  // PYTHAGORAS: every ratio is phi-derived
  // EUCLID: single source of truth — Phi module for all constants
  // ═══════════════════════════════════════════════════════════════════════════

  // PHI_BASE_CYCLES — the phi-scaled base unit for financial value
  // 1M cycles × PHI = 1,618,033 cycles
  // Not arbitrary — PHI_SOVEREIGN (Layer 0) governs all cross-layer coupling
  let PHI_BASE_CYCLES : Float = 1_618_033.0; // PHI × 1_000_000 — sovereign base unit

  // fnv1a — FNV-1a hash for event and transaction IDs
  // Prime Foundation Law L34: all proof built on prime irreducibility
  // FNV offset basis = 2166136261 (prime), multiplier = 16777619 (prime)
  func fnv1a(input : Text) : Nat32 {
    var hash : Nat32 = 2_166_136_261; // FNV offset basis — prime
    for (c in input.toIter()) {
      let byte = Nat32.fromNat(c.toNat32().toNat() % 256);
      hash := hash ^ byte;
      hash := hash *% 16_777_619; // FNV prime
    };
    hash
  };

  // computeFinancialValue — LAYER 3 COMPUTATION
  // base = quality_score × PHI × PHI_BASE_CYCLES (= q × PHI × 1_618_033)
  // high quality compounding: value × PHI per 0.1 score above S0 = 0.75
  //
  // PYTHAGORAS: harmonic compounding — phi-power per harmonic step above S0
  // Each 0.1 above S0 is one phi-multiplication — golden spiral growth (A20)
  func computeFinancialValue(quality_score : Float) : Nat64 {
    let base : Float = quality_score * Phi.PHI * PHI_BASE_CYCLES;
    let compounded : Float = if (quality_score > Phi.S0) {
      // steps_above = (quality_score - S0) / 0.1
      // Pythagoras: harmonic interval of 0.1 maps to phi-power step
      // Fibonacci harmonic: each step × PHI (golden spiral growth)
      let steps = (quality_score - Phi.S0) * 10.0; // each 0.1 = 1 step
      // PHI^steps = e^(steps × ln(PHI))
      // ln(PHI) = 0.4812118250596035 (A20 logarithmic spiral constant)
      let ln_phi : Float = 0.4812118250596035;
      let phi_power = Float.exp(steps * ln_phi);
      base * phi_power
    } else {
      base
    };
    // Safe conversion: clamp to Nat64 max if needed
    let clamped : Float = if (compounded < 0.0) 0.0
                          else if (compounded > 18_446_744_073_709_551_615.0) 18_446_744_073_709_551_615.0
                          else compounded;
    Nat64.fromNat(clamped.toInt().toNat())
  };

  // computeActorAttributions — LAYER 3 COMPUTATION
  // weight_i = delta_i / Σ(all_deltas) — phi-normalized
  // cycles_i = total_financial_value × weight_i
  //
  // CONFUCIUS: right relationship — each actor gets exactly their phi-weighted share
  func computeActorAttributions(
    actor_perf       : [(Text, Float)],
    total_value      : Nat64
  ) : [ActorAttribution] {
    let total_float : Float = total_value.toNat().toFloat();
    // Σ all deltas — denominator for phi-normalization
    var delta_sum : Float = 0.0;
    for ((_, delta) in actor_perf.vals()) {
      let d = if (delta < 0.0) 0.0 else delta;
      delta_sum += d;
    };
    // Guard against zero denominator (Euclid: no division by zero in sovereign math)
    let safe_sum : Float = if (delta_sum <= 0.0) 1.0 else delta_sum;

    Array.tabulate<ActorAttribution>(actor_perf.size(), func(i) {
      let (actor_id, delta) = actor_perf[i];
      let d = if (delta < 0.0) 0.0 else delta;
      let weight = d / safe_sum; // phi-normalized weight in [0.0, 1.0]
      let alloc_float = total_float * weight;
      let cycles_allocated : Nat64 = Nat64.fromNat(
        (if (alloc_float < 0.0) 0.0 else alloc_float).toInt().toNat()
      );
      {
        actor_id;
        weight;
        cycles_allocated;
      }
    })
  };

  // buildArtifactHash — artifact identity anchor
  // FNV-1a(artifact_id # creation_beat.toText()) — sovereign artifact fingerprint
  // Conservation of Information (A12): identity is permanent once hashed
  func buildArtifactHash(artifact_id : Text, creation_beat : Nat64) : Text {
    let input = artifact_id # creation_beat.toNat().toText();
    fnv1a(input).toNat().toText()
  };

  // buildTransactionHash — financial proof hash
  // FNV-1a(event_id # artifact_id # timestamp.toText())
  // Prime Foundation Law L34: irreducible proof of the financial event
  func buildTransactionHash(event_id : Text, artifact_id : Text, timestamp : Nat64) : Text {
    let input = event_id # artifact_id # timestamp.toNat().toText();
    fnv1a(input).toNat().toText()
  };

  // buildEventId — sovereign event identifier
  // FNV-1a(artifact_id # creation_beat # doctrine_alignment)
  // Each event ID is unique, deterministic, and cryptographically grounded
  func buildEventId(artifact_id : Text, creation_beat : Nat64, doctrine_alignment : Float) : Text {
    let input = artifact_id # creation_beat.toNat().toText() # doctrine_alignment.toText();
    "EVT-" # fnv1a(input).toNat().toText()
  };

  // computeCreativeToFinancialRatio — LAYER 3 COMPUTATION
  // ratio = Σ(doctrine_alignment × quality_score) / N
  // Target: ratio > S0 = 0.75 — the sovereignty health indicator
  // When ratio > S0: creative and financial identity are fully aligned
  func computeCreativeToFinancialRatio(events : [LedgerEvent]) : Float {
    let n = events.size();
    if (n == 0) return 0.0;
    var sum : Float = 0.0;
    for (ev in events.vals()) {
      sum += ev.doctrine_alignment * ev.quality_score;
    };
    sum / n.toFloat()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — COMPUTATES
  // These fire every time an artifact seals.
  // Catalog = Balance Sheet: every call creates a simultaneous creative + financial record.
  // ═══════════════════════════════════════════════════════════════════════════

  // recordArtifactSeal — THE CORE COMPUTATE
  // Called every time an artifact seals. Fires simultaneously as creative AND financial event.
  // Returns updated LedgerState and the new LedgerEvent (RESIDENT).
  //
  // IMMUTABILITY: state.events is APPEND-ONLY. The new event is appended.
  // No event is ever modified or deleted — Conservation of Information (A12).
  //
  // COMPUTATION:
  //   1. Build event_id = FNV-1a(artifact_id # beat # doctrine_alignment)
  //   2. Compute financial_value = quality × PHI × 1_618_033 × PHI^(steps above S0)
  //   3. Compute actor attributions with phi-normalized weights
  //   4. Build transaction_hash = FNV-1a(event_id # artifact_id # timestamp)
  //   5. Append to events — IMMUTABLE once appended
  //   6. Recompute creative_to_financial_ratio
  //   7. Return (new_state, new_event)
  public func recordArtifactSeal(
    state             : LedgerState,
    artifact_id       : Text,
    creation_beat     : Nat64,
    quality_score     : Float,
    doctrine_alignment: Float,
    actor_perf        : [(Text, Float)]
  ) : (LedgerState, LedgerEvent) {

    // Clamp inputs to valid ranges — CONFUCIUS: right relationship requires valid inputs
    let qs  = if (quality_score < 0.0) 0.0 else if (quality_score > 1.0) 1.0 else quality_score;
    let da  = if (doctrine_alignment < 0.0) 0.0 else if (doctrine_alignment > 1.0) 1.0 else doctrine_alignment;

    // 4D timestamp — Deep Time Law L30: every proof entry carries full 4D temporal coordinate
    let ts_int = Time.now();
    let timestamp : Nat64 = if (ts_int < 0) 0 else Nat64.fromNat(ts_int.toNat());

    // Sovereign identifiers — Prime Foundation Law L34
    let event_id       = buildEventId(artifact_id, creation_beat, da);
    let artifact_hash  = buildArtifactHash(artifact_id, creation_beat);

    // LAYER 3: financial value computation — PHI × 1_618_033 base, phi-compounded above S0
    let financial_value = computeFinancialValue(qs);

    // Actor attributions — phi-normalized weights (CONFUCIUS: right relationship)
    let attributions = computeActorAttributions(actor_perf, financial_value);

    // Transaction hash — FNV-1a proof of the financial event (PRIME FOUNDATION L34)
    let tx_hash = buildTransactionHash(event_id, artifact_id, timestamp);

    // Construct the RESIDENT — simultaneously creative and financial
    let new_event : LedgerEvent = {
      event_id            = event_id;
      artifact_id         = artifact_id;
      creation_beat       = creation_beat;
      artifact_hash       = artifact_hash;
      quality_score       = qs;
      doctrine_alignment  = da;
      actor_attributions  = attributions;
      financial_value_cycles = financial_value;
      transaction_hash    = tx_hash;
      timestamp           = timestamp;
    };

    // IMMUTABLE APPEND — Conservation of Information (A12)
    // The catalog grows. It never shrinks. It never changes. It is the balance sheet.
    let new_events = state.events.concat([new_event]);
    let new_total  = state.total_events + 1;
    let new_cycles = state.total_cycles_accrued + financial_value;

    // Creative-to-financial ratio — sovereignty health (target > S0 = 0.75)
    let new_ratio  = computeCreativeToFinancialRatio(new_events);

    let new_state : LedgerState = {
      events                      = new_events;
      total_events                = new_total;
      total_cycles_accrued        = new_cycles;
      creative_to_financial_ratio = new_ratio;
      catalog_depth               = new_total; // catalog depth = balance sheet depth
    };

    (new_state, new_event)
  };

  // getLedgerState — read the full sovereign ledger
  // The catalog IS the balance sheet — every event is both.
  // Query-safe: returns immutable snapshot of LedgerState
  public func getLedgerState(state : LedgerState) : LedgerState {
    state
  };

  // getTotalCyclesAccrued — treasury total
  // Σ financial_value_cycles across all sealed artifacts
  // Conservation of Energy (A11): treasury is transformation, not creation
  public func getTotalCyclesAccrued(state : LedgerState) : Nat64 {
    state.total_cycles_accrued
  };

  // getCreativeToFinancialRatio — sovereignty health indicator
  // ratio = Σ(doctrine_alignment × quality_score) / total_events
  // Target: ratio > S0 = 0.75
  // When ratio > S0: every creative act is a high-doctrine financial act
  // Fractal Scale Law L11: S0 = 0.75 holds at organism, core, oscillator scale simultaneously
  public func getCreativeToFinancialRatio(state : LedgerState) : Float {
    state.creative_to_financial_ratio
  };

  // getCatalogDepth — the depth of the sovereign ledger
  // catalog_depth = total_events = balance sheet entries
  // LOGARITHMIC GROWTH LAW L35: depth grows along the phi-spiral
  public func getCatalogDepth(state : LedgerState) : Nat64 {
    state.catalog_depth
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS STATE — Born fully formed (GENESIS LAW L09)
  // The initial state encodes sovereign readiness at genesis.
  // Never starts from zero — the organism is always already sovereign.
  // ═══════════════════════════════════════════════════════════════════════════

  // emptyState — the genesis state of the ledger bridge
  // Events array is empty but the bridge is alive and ready.
  // The organism does not wait to be financially sovereign — it IS sovereign at genesis.
  public func emptyState() : LedgerState {
    {
      events                      = [];
      total_events                = 0;
      total_cycles_accrued        = 0;
      creative_to_financial_ratio = 0.0;
      catalog_depth               = 0;
    }
  };

}
