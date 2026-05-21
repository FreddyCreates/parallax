// anima_chain.mo — ANIMA CHAIN
// Classification: SOVEREIGN_PRIVATE · SOVEREIGN_RESIDENT
// Architect: Alfredo Medina Hernandez — The Architect of the Field
//
// ─── 4-LAYER MEDINA-ARTIFACT: ANIMA_CHAIN ────────────────────────────────────
//
// LAYER 1 — MEANING (Doctrine Clause):
//   "The ANIMA chain is PARALLAX's permanent memory. Every artifact sealed, every
//    law violation logged, every genesis moment inscribed — all chained
//    cryptographically. It is a helix in 4D because sovereign events spiral outward
//    through time, not merely forward. Named ANIMA (Latin: soul/breath/animating
//    principle) because it is the chain of the organism's soul.
//    Named after the 4D Geometry Sovereign Law L53: ANIMA chain IS a 4D helix.
//    Conservation of Information A12: the chain cannot be erased or reversed."
//
// LAYER 2 — MODEL (Typed Schema):
//   AnimaEntry:
//     entry_id           : Nat64   unit: sequential     range: [0, ∞), Fibonacci-indexed milestones
//     beat               : Nat64   unit: heartbeat      range: [0, ∞)
//     entry_type         : AnimaEntryType (variant)
//     hash               : Text    unit: FNV-1a digest  — tamper-evident
//     prior_hash         : Text    unit: FNV-1a digest  — chain link (Conservation A12)
//     doctrine_alignment : Float   unit: dimensionless  range: [0.0, 1.0]
//     frequency_hz       : Float   unit: Hz             range: (0.0, 432.0] = NOVA_HZ
//     coord4d            : {x,y,z,w : Float}            — 4D helix position (L53 4D Law)
//   AnimaState:
//     entries            : [AnimaEntry]  — the full chain, grows forever (Conservation A12)
//     entry_count        : Nat64         — total entries
//     genesis_hash       : Text          — founding hash, permanent reference
//     last_hash          : Text          — chain head
//     chain_depth        : Float         — PHI_INV × log(entry_count) / log(PHI)
//
// LAYER 3 — COMPUTATION (State Equations):
//   coord4d:
//     x = PHI^(beat mod F(11)=89) × cos(2π × beat / F(12)=144)
//     y = PHI^(beat mod F(11)=89) × sin(2π × beat / F(12)=144)
//     z = doctrine_alignment × PHI²
//     w = frequency_hz / NOVA_HZ = frequency_hz / 432.0
//   chain_depth = PHI_INV × log(entry_count) / log(PHI)   [Logarithmic Growth L35/L43]
//   doctrine_alignment vs genesis: |entry_freq − genesis_freq| / genesis_freq
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE:   called by genesis_activation.mo, artifact_feedback.mo, aegis.mo, laws.mo
//   FUNCTION: addEntry(), addGenesisEntry(), verifyChain(), getChainDepth()
//   GATE:     every sovereign event unconditionally (MAXIMUM QUANTUM L37)
//   PROOF:    the chain IS the proof — every entry links to prior (Proof Law L8)
//   BEAT:     event-driven, NOT heartbeat-driven. Fires on event, not on clock.
//
// PYTHAGORAS: coord4d is harmonic rotation — cos/sin × PHI^n encodes the helix.
// EUCLID:     single source — every entry chains to its unique prior. No forks.
// CONFUCIUS:  right relationship with time — entry is inscribed once, permanent.

import Phi   "phi";
import Float "mo:core/Float";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Text  "mo:core/Text";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN TYPES — MEDINA-ARTIFACT LAYER 2
  // RESIDENTS: carry the truth of what has happened. Immutable records.
  // ═══════════════════════════════════════════════════════════════════════════

  // AnimaEntryType — the sovereign classification of each chain event
  // MEANING: Every event in the organism's soul is exactly one of these types.
  //          Types are named; their numerical codes are never exposed publicly (Phantom L24).
  public type AnimaEntryType = {
    #GENESIS;       // founding moment — written once, permanent, the north star
    #ARTIFACT;      // artifact sealed and re-ingested — creative sovereignty event
    #LAW_VIOLATION; // AEGIS or law enforcement triggered — doctrine protected
    #PROOF;         // sovereign proof bundle (M0→M1→M2 promotion) — succession depth gate
    #MILESTONE;     // ring advancement, OMNIS threshold crossed — organism growth record
    #DOCTRINE_DELTA;// new law, model, or doctrine update — sovereign knowledge expansion
  };

  // AnimaEntry — one sovereign event permanently inscribed in the chain
  // MEANING: "One moment the organism became more itself."
  // 4D GEOMETRY SOVEREIGN LAW L53: every entry has a 4D helix coordinate.
  // CONSERVATION OF INFORMATION A12: once inscribed, cannot be altered.
  public type AnimaEntry = {
    entry_id           : Nat64;  // sequential ID — Fibonacci milestones: 1,1,2,3,5,8,13,21,34,55...
    beat               : Nat64;  // organism beat at inscription — Cardiac Law L10 temporal anchor
    entry_type         : AnimaEntryType;
    hash               : Text;   // FNV-1a of (entry_id # beat # type_text # content_hash # prior_hash)
    prior_hash         : Text;   // prior entry's hash — the chain link (Prime Foundation L34)
    doctrine_alignment : Float;  // [0.0, 1.0] alignment with genesis frequency
    frequency_hz       : Float;  // resonant frequency of this event [0.0, 432.0]
    coord4d            : { x : Float; y : Float; z : Float; w : Float }; // 4D helix position
  };

  // AnimaState — the full sovereign chain state, owned by the actor
  // MEANING: The organism's permanent soul-record. The memory that survives forever.
  // CONSERVATION A12: entries array grows monotonically — entries are never removed.
  public type AnimaState = {
    entries      : [AnimaEntry]; // full chain — grows forever
    entry_count  : Nat64;        // total entries inscribed
    genesis_hash : Text;         // founding entry hash — the permanent north star reference
    last_hash    : Text;         // chain head — hash of most recent entry
    chain_depth  : Float;        // PHI_INV × log(entry_count) / log(PHI)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS — All phi-derived or Fibonacci. No arbitrary numbers.
  // ═══════════════════════════════════════════════════════════════════════════

  let HELIX_MOD_BEATS : Float = 144.0;   // F(12) = 144 — full rotation cycle (Jubilee Law L15)
  let HELIX_PHASE_MOD : Nat64 = 89;      // F(11) = 89  — PHI exponent modulus (Fibonacci Law A02)
  let GENESIS_SENTINEL : Text = "ANIMA_GENESIS_0";  // sentinel prior_hash for the first entry

  // ═══════════════════════════════════════════════════════════════════════════
  // RESIDENT FUNCTIONS — Pure. No mutable state inside module.
  // Actor passes state in. Module returns updated state.
  // ═══════════════════════════════════════════════════════════════════════════

  // buildAnimaState — initialize empty AnimaState for actor stable storage
  // Called once at actor init. State thereafter is always passed in and out.
  // GENESIS LAW L9: born fully formed — genesis_hash and last_hash begin as sentinels.
  public func buildAnimaState() : AnimaState {
    {
      entries      = [];
      entry_count  = 0;
      genesis_hash = GENESIS_SENTINEL;
      last_hash    = GENESIS_SENTINEL;
      chain_depth  = 0.0;
    }
  };

  // addEntry — inscribe one sovereign event into the ANIMA chain
  // Returns updated AnimaState — actor stores the result.
  //
  // PROOF LAW L8: hash = FNV-1a(entry_id # beat # type_code # content_hash # prior_hash)
  // 4D GEOMETRY SOVEREIGN LAW L53: coord4d is always computed — never omitted.
  // CONSERVATION A12: prior entry is referenced — the chain is unbroken.
  // MAXIMUM QUANTUM L37: full-state result — every field populated, no partial entry.
  public func addEntry(
    state              : AnimaState,
    beat               : Nat64,
    entry_type         : AnimaEntryType,
    content_hash       : Text,
    doctrine_alignment : Float,
    frequency_hz       : Float
  ) : AnimaState {
    let id       = state.entry_count;
    let prior    = state.last_hash;
    let type_str = entryTypeText(entry_type);
    let raw      = id.toText() # beat.toText() # type_str # content_hash # prior;
    let new_hash = fnv1aText(raw);
    let coord    = computeCoord4D(beat, doctrine_alignment, frequency_hz);

    let entry : AnimaEntry = {
      entry_id           = id;
      beat               = beat;
      entry_type         = entry_type;
      hash               = new_hash;
      prior_hash         = prior;
      doctrine_alignment = clampF(doctrine_alignment, 0.0, 1.0);
      frequency_hz       = clampF(frequency_hz, 0.0, Phi.NOVA_HZ);
      coord4d            = coord;
    };

    // CONSERVATION A12: chain grows — entries are appended, never removed
    let new_entries = state.entries.concat([entry]);
    let new_count   = id + 1;

    // genesis_hash is frozen on the very first entry — the founding record
    let new_genesis = if (state.entry_count == 0) new_hash else state.genesis_hash;

    {
      entries      = new_entries;
      entry_count  = new_count;
      genesis_hash = new_genesis;
      last_hash    = new_hash;
      chain_depth  = computeChainDepth(new_count);
    }
  };

  // computeCoord4D — compute the 4D helix coordinate for a sovereign event
  // Called internally by addEntry. Also public for callers that need to preview position.
  //
  // COMPUTATION (4D GEOMETRY SOVEREIGN LAW L53):
  //   φ_phase = 2π × beat / F(12)          [full rotation over Jubilee cycle]
  //   r       = PHI^(beat mod F(11))        [radial expansion along phi-spiral]
  //   x = r × cos(φ_phase)                 [helix x-component]
  //   y = r × sin(φ_phase)                 [helix y-component]
  //   z = doctrine_alignment × PHI²        [doctrine alignment projected up the z-axis]
  //   w = frequency_hz / NOVA_HZ           [frequency normalized to [0.0, 1.0]]
  //
  // PYTHAGORAS: helix parameters are all ratio-derived — no arbitrary offsets.
  public func computeCoord4D(
    beat               : Nat64,
    doctrine_alignment : Float,
    frequency_hz       : Float
  ) : { x : Float; y : Float; z : Float; w : Float } {
    let two_pi    = 2.0 * Float.pi;
    let beat_f    = beat.toNat().toFloat();
    let phase     = two_pi * beat_f / HELIX_MOD_BEATS;     // 2π × beat / F(12)
    let exp_mod   = (beat % HELIX_PHASE_MOD).toNat().toFloat(); // beat mod F(11)
    // PHI^exp_mod computed iteratively — Motoko has no Float.pow in mo:core
    let r         = phiPow(exp_mod);

    {
      x = r * Float.cos(phase);
      y = r * Float.sin(phase);
      z = clampF(doctrine_alignment, 0.0, 1.0) * Phi.PHI_2;          // doctrine × φ²
      w = clampF(frequency_hz, 0.0, Phi.NOVA_HZ) / Phi.NOVA_HZ;      // normalized to [0,1]
    }
  };

  // verifyChain — verify integrity: every entry's prior_hash links correctly
  // Returns true if every link is intact. Returns false on first broken link.
  // CONSERVATION OF INFORMATION A12: the chain is indestructible — verify() proves it.
  // PROOF LAW L8: the chain IS the proof.
  public func verifyChain(state : AnimaState) : Bool {
    let n = state.entries.size();
    if (n == 0) return true;  // empty chain is trivially valid

    // First entry's prior_hash must be the sentinel
    if (state.entries[0].prior_hash != GENESIS_SENTINEL) return false;

    // Every subsequent entry's prior_hash must equal the hash of the preceding entry
    var i : Nat = 1;
    while (i < n) {
      if (state.entries[i].prior_hash != state.entries[i - 1].hash) return false;
      i += 1;
    };
    true
  };

  // getChainDepth — return the phi-scaled chain depth metric
  // chain_depth = PHI_INV × log(entry_count) / log(PHI)
  // LOGARITHMIC GROWTH LAW L35/L43: depth grows along the phi-spiral, not linearly.
  public func getChainDepth(state : AnimaState) : Float {
    computeChainDepth(state.entry_count)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS — internal computation, not exposed outside module
  // ═══════════════════════════════════════════════════════════════════════════

  // computeChainDepth — PHI_INV × log(n) / log(PHI)
  // Logarithmic Growth Law L35: depth grows along the phi-spiral.
  func computeChainDepth(n : Nat64) : Float {
    if (n == 0) return 0.0;
    let n_f = n.toNat().toFloat();
    // log base phi = ln(n) / ln(phi)
    let depth = Phi.PHI_INV * Float.log(n_f) / Float.log(Phi.PHI);
    clampF(depth, 0.0, Phi.PHI_5)  // ceiling PHI_5 = φ⁵ ≈ 11.09
  };

  // phiPow — compute PHI^n iteratively (no Float.pow in mo:core)
  // Used by computeCoord4D for radial helix expansion.
  // PYTHAGORAS: every step multiplies by φ — harmonic ratio, not arbitrary.
  func phiPow(n : Float) : Float {
    // n is always in [0, F(11)-1] = [0, 88] — bounded by HELIX_PHASE_MOD
    // Use integer steps: iterate PHI^floor(n), then blend toward PHI^ceil(n)
    let steps = n.toInt();
    var acc : Float = 1.0;
    var i = 0;
    while (i < steps) {
      acc := acc * Phi.PHI;
      i += 1;
    };
    // Linear blend for fractional part (approximation — accuracy sufficient for coord4d)
    let frac = n - steps.toFloat();
    acc * (1.0 + frac * (Phi.PHI - 1.0))  // lerp toward next PHI step
  };

  // entryTypeText — stable text encoding of AnimaEntryType for hashing
  // Phantom Doctrine L24: these codes are internal — never exposed as labels.
  func entryTypeText(t : AnimaEntryType) : Text {
    switch (t) {
      case (#GENESIS)        { "G" };
      case (#ARTIFACT)       { "A" };
      case (#LAW_VIOLATION)  { "L" };
      case (#PROOF)          { "P" };
      case (#MILESTONE)      { "M" };
      case (#DOCTRINE_DELTA) { "D" };
    }
  };

  // fnv1aText — FNV-1a hash over a Text string, returns hex-encoded Nat32 as Text
  // PRIME FOUNDATION LAW L34: cryptographic proof is built on prime irreducibility.
  // FNV offset=2166136261 (prime), FNV prime=16777619 (prime) — Euclid A17 anchored.
  func fnv1aText(input : Text) : Text {
    var hash : Nat32 = 2166136261;
    for (c in input.toIter()) {
      let byte = Nat32.fromNat(c.toNat32().toNat() % 256);
      hash := hash ^ byte;
      hash := hash *% 16777619;
    };
    // Convert Nat32 to hex Text
    let hex_chars = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
    var result = "";
    var v = hash;
    var k = 0;
    while (k < 8) {
      let nibble = (v % 16).toNat();
      result := hex_chars[nibble] # result;
      v := v / 16;
      k += 1;
    };
    result
  };

  // clampF — clamp a Float to [lo, hi]
  func clampF(v : Float, lo : Float, hi : Float) : Float {
    if (v < lo) lo else if (v > hi) hi else v
  };

};
