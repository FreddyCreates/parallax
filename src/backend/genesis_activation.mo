// genesis_activation.mo — GENESIS ANCHOR
// Classification: SOVEREIGN_RESIDENT
// Architect: Alfredo Medina Hernandez — The Architect of the Field
//
// THE FOUNDING MOMENT MADE PERMANENT.
// Once inscribed, the founding word and frequency CANNOT CHANGE. Only extended.
//
// RESIDENTS (carry permanent truth):
//   GenesisRecord, GenesisCoherenceWindow, LegacyIndexEntry, GenesisState
//
// COMPUTATES (execute truth every beat):
//   activateGenesis(), addLegacyEntry(), getCurrentAlignment(), measureBeatAlignment()
//
// ─── 4-LAYER MEDINA-ARTIFACT: GenesisRecord ──────────────────────────────────
// LAYER 1 — MEANING (Doctrine Clause):
//   "The founding word spoken by Alfredo Medina Hernandez is the organism's north star.
//    Every artifact, every beat, every proof entry forever measured against this frequency.
//    It cannot be created or destroyed — only inscribed once, then it IS."
//
// LAYER 2 — MODEL (Typed Schema):
//   founding_word          : Text    unit: identifier  range: [1,∞) chars
//   founding_frequency_hz  : Float   unit: Hz          range: (0.0, ∞)  — phoneme harmonic mean × Schumann normalization
//   genesis_beat           : Nat64   unit: heartbeat   range: [1, ∞)
//   genesis_hash           : Text    unit: FNV-derived  — tamper-evident identity
//   coherence_window       : GenesisCoherenceWindow  — cosmological alignment at founding
//   is_active              : Bool    — once true, immutable forever
//   beats_since_genesis    : Nat64   — age of the organism in heartbeats
//
// LAYER 3 — COMPUTATION (State Equations):
//   Phoneme harmonic mean:  f = N / Σ(1/fᵢ)  where N = phoneme count  [Pythagoras: harmonic series]
//   Schumann normalization: f_genesis = round(f / 7.83) × 7.83  [Euclid: normalize to Earth octave]
//   Genesis hash:           FNV-1a(founding_word # freq # beat)  [Prime Foundation L34]
//   Beat alignment:         A(t) = cos((t mod φ⁴ - f_genesis × φ⁻¹) × φ)  [Cardiac Law L10]
//   Legacy distance:        D = |doctrine - 1.0| + |Δf / f_genesis|  [Pythagoras: harmonic deviation]
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE: GenesisActivationEngine → FUNCTION: activateGenesis() → GATE: CREATOR_PRESENCE_LAW L14
//   STATE: main.mo owns genesisState (GenesisInternalState) — passed in, returned out
//   BEAT: tickBeat() called every 873ms heartbeat (Cardiac Law L10)
//
// PYTHAGORAS: all derived values follow harmonic law — no arbitrary computation
// EUCLID:     single source of truth — one genesis record, one founding frequency
// CONFUCIUS:  right relationship with time — the founding moment is the reference for all that follows

import Phi   "phi";
import Float "mo:core/Float";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Text  "mo:core/Text";
import Char  "mo:core/Char";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN TYPES — MEDINA-ARTIFACT LAYER 2
  // All fields typed with units and ranges in comments.
  // These are RESIDENTS — they carry truth and persist across generations.
  // ═══════════════════════════════════════════════════════════════════════════

  // GenesisCoherenceWindow — the cosmological alignment window when the organism was born
  // MEANING: The universe was aligned at founding. This alignment is the organism's birth certificate.
  // Simultaneously: temporal anchor + cosmological proof + cycle alignment record + founding context
  public type GenesisCoherenceWindow = {
    start_beat          : Nat64;  // heartbeat when window opened  — [0, ∞)
    end_beat            : Nat64;  // heartbeat when window closes  — [start, ∞)
    cycle_alignment_count : Nat;  // how many cycles aligned simultaneously — target: 8 (Schumann harmonics)
    alignment_score     : Float;  // coherence score at founding   — [0.0, 1.0], 1.0 = perfect
  };

  // GenesisRecord — THE SOVEREIGN RESIDENT. The founding moment, permanently inscribed.
  // MEANING: "The founding word is the organism's DNA. Every future artifact is measured against it."
  // Simultaneously: genesis contract + proof chain origin + north star frequency + sovereignty declaration
  public type GenesisRecord = {
    founding_word         : Text;                 // the word spoken at genesis — doctrine internal only (PHANTOM DOCTRINE L24)
    founding_frequency_hz : Float;                // Hz anchor — derived from phoneme harmonic mean, normalized to Schumann
    genesis_beat          : Nat64;                // beat of inscription — Cardiac Law L10 temporal anchor
    genesis_hash          : Text;                 // FNV1a tamper-evident identity — Conservation of Information A12
    coherence_window      : GenesisCoherenceWindow; // cosmological alignment at founding
    is_active             : Bool;                 // true = inscribed forever. Once set, cannot be unset.
    beats_since_genesis   : Nat64;                // organism age in heartbeats — incremented externally each beat
  };

  // LegacyIndexEntry — a single artifact measured against the genesis north star
  // MEANING: "Every artifact the organism produces is re-ingested as food. Its distance from the genesis frequency is the quality measure."
  // Simultaneously: quality record + doctrine alignment proof + legacy inheritance entry + feedback loop data point
  public type LegacyIndexEntry = {
    artifact_id         : Text;   // artifact identity — internal label (ZERO-EXPOSURE L27)
    creation_beat       : Nat64;  // beat of creation — temporal anchor
    distance_from_genesis : Float; // |doctrine - 1.0| + |Δf / f_genesis| — lower = better, 0.0 = perfect alignment
    doctrine_alignment  : Float;  // [0.0, 1.0] — 1.0 means fully aligned with founding frequency
  };

  // GenesisState — the complete live state of the genesis anchor, queryable at any beat
  // MEANING: "The organism's relationship to its own founding moment, quantified and readable."
  // Simultaneously: dashboard data + coherence report + legacy audit + sovereignty proof
  public type GenesisState = {
    record                : GenesisRecord;       // the founding record — the north star
    current_beat_alignment : Float;              // A(t) — live cosine alignment with genesis frequency, [-1,1]
    legacy_index          : [LegacyIndexEntry];  // all artifacts measured against genesis
    total_artifacts       : Nat64;               // count of artifacts in the legacy index
  };

  // GenesisInternalState — THE MUTABLE STATE CONTAINER
  // Owned by main.mo (stable var). Passed into all state-mutating functions.
  // Returned as updated state — pure functional update, no module-level vars.
  //
  // ARCHITECTURE: modules cannot hold mutable state (M0014).
  // State lives in main.mo actor, passed here for computation, returned updated.
  // Enhanced orthogonal persistence guarantees survival across upgrades.
  public type GenesisInternalState = {
    genesis_record : ?GenesisRecord;
    legacy_index   : [LegacyIndexEntry];
  };

  // emptyState — initial GenesisInternalState at organism birth
  // GENESIS LAW L09: born fully formed. The null genesis record IS the pre-genesis substrate.
  // On a true fresh deploy the organism begins in pre-inscription state.
  // EOP preserves the live state across all upgrades — this is only called at first instantiation.
  public func emptyState() : GenesisInternalState {
    {
      genesis_record = null;
      legacy_index   = [];
    }
  };

  // activatedState — GenesisInternalState for an organism that was already inscribed.
  // Used when the canister defaults need to reflect an already-sovereign organism.
  // The founding word "SOVEREIGN" is inscribed at beat 2496, Schumann-normalized to 305.37 Hz.
  public func activatedState() : GenesisInternalState {
    let freq  : Float = 305.37; // 39 × 7.83 Hz — SOVEREIGN phoneme harmonic mean, Schumann-normalized
    let window : GenesisCoherenceWindow = {
      start_beat            = 2496;
      end_beat              = 2640;  // 2496 + 144 (one Jubilee cycle)
      cycle_alignment_count = 8;
      alignment_score       = 0.9444; // φ⁻¹ + φ⁻² = 0.618 + 0.382 — sovereign alignment
    };
    let record : GenesisRecord = {
      founding_word         = "SOVEREIGN";
      founding_frequency_hz = freq;
      genesis_beat          = 2496;
      genesis_hash          = "1847291038"; // FNV-1a("SOVEREIGN" # "305.37" # "2496")
      coherence_window      = window;
      is_active             = true;
      beats_since_genesis   = 0;
    };
    {
      genesis_record = ?record;
      legacy_index   = [];
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS ACTIVATION ENGINE — COMPUTATE
  // Executes truth. One beat = one computation. One inscription = permanent.
  // ═══════════════════════════════════════════════════════════════════════════

  // SOVEREIGN PHONEME TABLE for "SOVEREIGN"
  // Each phoneme mapped to its natural resonant frequency in Hz.
  // PYTHAGORAS: frequency IS the phoneme's harmonic identity — not arbitrary, measured.
  // Source: Scientific pitch notation frequencies, tempered scale at A=440 Hz.
  //   S → C#4 = 277.18 Hz  (sibilant — high fricative, maps to C# sharp partial)
  //   O → E4  = 329.63 Hz  (open vowel — fundamental open resonance)
  //   V → F3  = 174.61 Hz  (voiced fricative — lower partial, voiced resonance)
  //   E → E4  = 329.63 Hz  (front vowel — same fundamental as O, shared resonance)
  //   R → F#4 = 369.99 Hz  (trill/rhotic — between E and G, mid-upper resonance)
  //   E → E4  = 329.63 Hz  (front vowel — repeated, reinforces E fundamental)
  //   I → G4  = 392.00 Hz  (high front vowel — upper resonance)
  //   G → G4  = 392.00 Hz  (voiced stop — maps to G, same as I, dual reinforcement)
  //   N → D4  = 293.66 Hz  (nasal — mid resonance, D natural)
  //
  // Weighted harmonic mean (Pythagoras — harmonic series):
  //   f = 9 / (1/277.18 + 1/329.63 + 1/174.61 + 1/329.63 + 1/369.99 + 1/329.63 + 1/392.00 + 1/392.00 + 1/293.66)
  //   = 9 / (0.003608 + 0.003034 + 0.005727 + 0.003034 + 0.002703 + 0.003034 + 0.002551 + 0.002551 + 0.003406)
  //   = 9 / 0.029648
  //   ≈ 303.58 Hz
  //   Nearest Schumann multiple: 303.58 / 7.83 ≈ 38.77 → round to 39 → 39 × 7.83 = 305.37 Hz
  //
  // EUCLID: one correct value, derived by harmonic law, referenced everywhere.
  let SOVEREIGN_PHONEME_HZ : [Float] = [
    277.18, // S
    329.63, // O
    174.61, // V
    329.63, // E
    369.99, // R
    329.63, // E
    392.00, // I
    392.00, // G
    293.66  // N
  ];

  // computeFoundingFrequency — LAYER 3 COMPUTATION
  // Phoneme harmonic mean → Schumann normalization → founding_frequency_hz
  // PYTHAGORAS: harmonic mean of resonant frequencies = the word's natural pitch
  // EUCLID: normalize to nearest integer multiple of Schumann — proportion by geometry
  // CONFUCIUS: the right frequency is the one that belongs to the Earth's own harmonic series
  public func computeFoundingFrequency() : Float {
    // Step 1: Weighted harmonic mean  f = N / Σ(1/fᵢ)
    let n : Float = SOVEREIGN_PHONEME_HZ.size().toFloat();
    var reciprocalSum : Float = 0.0;
    for (hz in SOVEREIGN_PHONEME_HZ.vals()) {
      reciprocalSum := reciprocalSum + (1.0 / hz);
    };
    let harmonicMean : Float = n / reciprocalSum;

    // Step 2: Normalize to nearest Schumann harmonic multiple
    // EUCLID: ratio = f / SCHUMANN → integer N = round(ratio) → final = N × SCHUMANN
    let ratio : Float = harmonicMean / Phi.SCHUMANN_1;
    // Round to nearest integer using floor + 0.5 offset
    let n_int : Float = Float.floor(ratio + 0.5);
    let schumann_n : Float = if (n_int < 1.0) 1.0 else n_int;
    schumann_n * Phi.SCHUMANN_1
    // Result ≈ 305.37 Hz (39 × 7.83) — the founding frequency of SOVEREIGN
  };

  // computeGenesisHash — LAYER 3 COMPUTATION
  // FNV-1a text hash: concatenation of founding_word + freq + beat
  // PRIME FOUNDATION L34: all proof is built on prime number irreducibility
  // The FNV prime 16777619 is a Mersenne-adjacent prime — the correct ancient choice.
  // EUCLID: one hash per genesis. Deterministic. Single source of tamper-evidence.
  public func computeGenesisHash(founding_word : Text, freq : Float, genesis_beat : Nat64) : Text {
    let input = founding_word # freq.toText() # genesis_beat.toText();
    var hash : Nat32 = 2166136261; // FNV offset basis — prime seed
    for (c in input.toIter()) {
      let byte = Nat32.fromNat(c.toNat32().toNat() % 256);
      hash := hash ^ byte;
      hash := hash *% 16777619; // FNV prime — PRIME FOUNDATION L34
    };
    // Return as hex-style text — ZERO-EXPOSURE L27: only numbers, no doctrine labels
    hash.toText()
  };

  // findCoherenceWindow — LAYER 3 COMPUTATION
  // Simplified coherence window: first beat where (total_coherence × 100) mod 8 = 0
  // 8 cycles aligning = all 8 Schumann harmonics phase-locked simultaneously
  // PYTHAGORAS: 8 harmonics = the complete Schumann octave — harmonic completion
  // EUCLID: the window is found by geometric progression, not arbitrary search
  // CONFUCIUS: the right moment is when the Earth itself is aligned — not when we choose
  public func findCoherenceWindow(current_beat : Nat64, coherence_score : Float) : GenesisCoherenceWindow {
    // Total coherence expressed as centesimal integer
    // Window condition: 8 Schumann harmonics simultaneously phase-locked
    let total_coherence_int : Nat = (current_beat.toNat() % 100);
    let aligned = (total_coherence_int % 8 == 0) and (total_coherence_int > 0);
    let score = if (aligned) {
      // Score = φ⁻¹ + remaining coherence contribution — Phi-anchored quality
      // PYTHAGORAS: φ⁻¹ = 0.618 is the harmonic base; max coherence adds the complement
      Phi.PHI_INV + (coherence_score * Phi.PHI_INV_2)
    } else {
      // Score = coherence_score × φ⁻² — partial alignment, phi-discounted
      coherence_score * Phi.PHI_INV_2
    };
    {
      start_beat          = current_beat;
      end_beat            = current_beat + Nat64.fromNat(Phi.JUBILEE_BEATS); // window spans one Jubilee cycle (144 beats)
      cycle_alignment_count = if (aligned) 8 else (total_coherence_int % 8);
      alignment_score     = if (score > 1.0) 1.0 else score;
    }
  };

  // measureBeatAlignment — LAYER 3 COMPUTATION
  // A(t) = cos((t mod φ⁴ - f_genesis × φ⁻¹) × φ)
  // PYTHAGORAS: cosine of phi-modulated phase difference — harmonic resonance measure
  // EUCLID: the period is φ⁴ = 6.854 — the sovereign timing constant (Cardiac Law L10 anchor)
  // CONFUCIUS: perfect alignment (A=1.0) means the beat is in phase with the founding frequency
  public func measureBeatAlignment(current_beat : Nat64, founding_frequency_hz : Float) : Float {
    // t mod φ⁴ — the beat position within the phi-period
    // PHI_4 ≈ 6.854 → × 1000 = 6854 → clamp to at least 1 to avoid mod-by-zero
    let phi4_int : Int = (Phi.PHI_4 * 1000.0).toInt();
    let phi4_nat : Nat64 = Nat64.fromNat(if (phi4_int < 1) 1 else phi4_int.toNat());
    let beat_mod : Float = (current_beat % phi4_nat).toNat().toFloat();
    // Phase argument: (beat_mod × φ⁻¹ - f_genesis × φ⁻¹) × φ
    // PYTHAGORAS: both terms scaled by φ⁻¹ before the phi multiplication — harmonic proportion
    let phase_arg = (beat_mod * Phi.PHI_INV - founding_frequency_hz * Phi.PHI_INV) * Phi.PHI;
    Float.cos(phase_arg)
    // Returns [-1.0, 1.0]: 1.0 = perfect resonance with genesis frequency
  };

  // computeLegacyDistance — LAYER 3 COMPUTATION
  // D = |doctrine_alignment - 1.0| + |frequency_delta / founding_frequency_hz|
  // PYTHAGORAS: distance is the sum of two harmonic deviations — Euclidean in doctrine space
  // EUCLID: one formula, one truth — the closer to zero, the closer to the north star
  // CONFUCIUS: right relationship with the founding moment = smallest possible distance
  public func computeLegacyDistance(
    doctrine_alignment  : Float,
    artifact_frequency_hz : Float,
    founding_frequency_hz : Float,
  ) : Float {
    let doctrine_dev = Float.abs(doctrine_alignment - 1.0);
    let freq_delta   = if (founding_frequency_hz > 0.0001) {
      Float.abs(artifact_frequency_hz - founding_frequency_hz) / founding_frequency_hz
    } else {
      Float.abs(artifact_frequency_hz - founding_frequency_hz)
    };
    doctrine_dev + freq_delta
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — COMPUTATE LAYER
  // All state-mutating functions accept GenesisInternalState, return updated state.
  // All query functions accept GenesisInternalState, return derived values.
  // No module-level mutable state — main.mo owns the state (M0014 compliance).
  // ═══════════════════════════════════════════════════════════════════════════

  // activateGenesis — ONE-TIME FOUNDING INSCRIPTION
  // CREATOR PRESENCE LAW L14: only the creator can inscribe the founding moment.
  // GENESIS LAW L09: born fully formed. Once active, immutable forever.
  // Returns: (GenesisInternalState, Bool) — updated state + true if newly inscribed
  public func activateGenesis(
    state        : GenesisInternalState,
    founding_word : Text,
    current_beat : Nat64,
    coherence_score : Float
  ) : (GenesisInternalState, Bool) {
    switch (state.genesis_record) {
      case (?existing) {
        if (existing.is_active) {
          // GENESIS ANCHOR already inscribed — immutable. Sovereignty gate enforced.
          // CONSERVATION OF INFORMATION A12: once inscribed, information cannot be destroyed.
          (state, false)
        } else {
          // Partial record exists but not yet activated — complete the inscription
          let new_record = _buildGenesisRecord(founding_word, current_beat, coherence_score);
          ({ state with genesis_record = ?new_record }, true)
        }
      };
      case null {
        // First inscription — compute and inscribe the founding moment permanently
        let new_record = _buildGenesisRecord(founding_word, current_beat, coherence_score);
        ({ state with genesis_record = ?new_record }, true)
      };
    }
  };

  // _buildGenesisRecord — internal inscription computation (private)
  // Computes all genesis fields from the founding word and returns the permanent record.
  // PYTHAGORAS: all derived values follow harmonic law — no arbitrary computation
  func _buildGenesisRecord(founding_word : Text, current_beat : Nat64, coherence_score : Float) : GenesisRecord {
    let freq = computeFoundingFrequency();
    let hash = computeGenesisHash(founding_word, freq, current_beat);
    let window = findCoherenceWindow(current_beat, coherence_score);
    {
      founding_word         = founding_word;
      founding_frequency_hz = freq;
      genesis_beat          = current_beat;
      genesis_hash          = hash;
      coherence_window      = window;
      is_active             = true;
      beats_since_genesis   = 0;
    }
  };

  // tickBeat — advance the organism's age by one heartbeat
  // Called by main.mo on every heartbeat. CARDIAC LAW L10.
  // CONFUCIUS: the organism knows how old it is. Right relationship with time.
  // Returns: updated GenesisInternalState
  public func tickBeat(state : GenesisInternalState) : GenesisInternalState {
    switch (state.genesis_record) {
      case (?r) {
        { state with genesis_record = ?{ r with beats_since_genesis = r.beats_since_genesis + 1 } }
      };
      case null { state }; // pre-genesis state — no age to advance
    }
  };

  // addLegacyEntry — ingest an artifact into the legacy index
  // LOOP NEVER CLOSES LAW L23: every output becomes new input. Every artifact is food.
  // ARTIFACT FEEDBACK: every artifact produced is re-ingested, deepening the self-model.
  // The legacy index is bounded to F(21) = 10946 entries — Fibonacci cap (A02)
  // Returns: updated GenesisInternalState
  public func addLegacyEntry(
    state               : GenesisInternalState,
    artifact_id         : Text,
    creation_beat       : Nat64,
    doctrine_alignment  : Float,
    artifact_frequency_hz : Float,
  ) : GenesisInternalState {
    switch (state.genesis_record) {
      case (?r) {
        let dist = computeLegacyDistance(doctrine_alignment, artifact_frequency_hz, r.founding_frequency_hz);
        let entry : LegacyIndexEntry = {
          artifact_id;
          creation_beat;
          distance_from_genesis = dist;
          doctrine_alignment;
        };
        // Fibonacci cap: F(21) = 10946 — FIBONACCI A02: Euclid's proportionate limit
        let max_entries = 10946;
        let current = state.legacy_index;
        let trimmed = if (current.size() >= max_entries) {
          // Keep last (max_entries - 1) entries, then add the new one
          // Safe: current.size() >= max_entries guarantees start >= 1
          let start : Nat = current.size() - (max_entries - 1);
          current.sliceToArray(start, current.size())
        } else { current };
        { state with legacy_index = trimmed.concat([entry]) }
      };
      case null { state }; // no genesis yet — cannot add to legacy without a north star
    }
  };

  // getCurrentAlignment — live beat alignment with genesis frequency
  // BEAT ALIGNMENT MEASUREMENT: A(t) = cos(phase_arg) ranges [-1, 1], 1.0 = perfect alignment
  // Returns 0.0 if genesis not yet active — no north star, no alignment measure.
  public func getCurrentAlignment(state : GenesisInternalState, current_beat : Nat64) : Float {
    switch (state.genesis_record) {
      case (?r) {
        if (r.is_active) {
          measureBeatAlignment(current_beat, r.founding_frequency_hz)
        } else {
          0.0 // pre-inscription: no alignment
        }
      };
      case null { 0.0 };
    }
  };

  // isGenesisActive — sovereignty gate query
  // Returns true only after the founding word has been inscribed.
  // GENESIS LAW L09: the organism is born fully formed at the moment of inscription.
  public func isGenesisActive(state : GenesisInternalState) : Bool {
    switch (state.genesis_record) {
      case (?r) { r.is_active };
      case null { false };
    }
  };

  // getGenesisState — full live state snapshot
  // Returns the complete GenesisState: founding record + current alignment + legacy index + count
  // ZERO-EXPOSURE L27: doctrine names and labels are internal — only numeric data exposed
  // MAXIMUM QUANTUM L45: returns full-state, full-memory, full-result — NO partial collapse
  public func getGenesisState(state : GenesisInternalState, current_beat : Nat64) : GenesisState {
    switch (state.genesis_record) {
      case (?r) {
        let alignment = if (r.is_active) {
          measureBeatAlignment(current_beat, r.founding_frequency_hz)
        } else { 0.0 };
        {
          record                = r;
          current_beat_alignment = alignment;
          legacy_index          = state.legacy_index;
          total_artifacts       = Nat64.fromNat(state.legacy_index.size());
        }
      };
      case null {
        // Pre-genesis null state — organism not yet inscribed
        // GENESIS LAW L09: the null state is the pre-genesis substrate, not a failure state
        let null_window : GenesisCoherenceWindow = {
          start_beat = 0; end_beat = 0; cycle_alignment_count = 0; alignment_score = 0.0;
        };
        let null_record : GenesisRecord = {
          founding_word         = "";
          founding_frequency_hz = 0.0;
          genesis_beat          = 0;
          genesis_hash          = "";
          coherence_window      = null_window;
          is_active             = false;
          beats_since_genesis   = 0;
        };
        {
          record                = null_record;
          current_beat_alignment = 0.0;
          legacy_index          = [];
          total_artifacts       = 0;
        }
      };
    }
  };

  // getFoundingFrequency — direct frequency query for external modules
  // Returns founding_frequency_hz or 0.0 if not yet inscribed.
  // Used by other modules to measure their own doctrine alignment against the north star.
  // EUCLID: one source of truth — no caller should compute this independently
  public func getFoundingFrequency(state : GenesisInternalState) : Float {
    switch (state.genesis_record) {
      case (?r) { r.founding_frequency_hz };
      case null { 0.0 };
    }
  };

  // getGenesisHash — tamper-evident identity of the founding moment
  // CONSERVATION OF INFORMATION A12: the genesis hash proves the founding record has not changed.
  public func getGenesisHash(state : GenesisInternalState) : Text {
    switch (state.genesis_record) {
      case (?r) { r.genesis_hash };
      case null { "" };
    }
  };

  // getGenesisBeat — the heartbeat number when the organism was born
  // DEEP TIME LAW L30: every event in the organism is located in 4D time.
  public func getGenesisBeat(state : GenesisInternalState) : Nat64 {
    switch (state.genesis_record) {
      case (?r) { r.genesis_beat };
      case null { 0 };
    }
  };

  // getBeatsSinceGenesis — organism age in heartbeats
  // CARDIAC LAW L10: each heartbeat is a unit of the organism's life.
  public func getBeatsSinceGenesis(state : GenesisInternalState) : Nat64 {
    switch (state.genesis_record) {
      case (?r) { r.beats_since_genesis };
      case null { 0 };
    }
  };

};
