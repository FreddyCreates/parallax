// cognitive_homeostat.mo — ADAPTIVE HOMEOSTAT CONTROL LAYER
// Classification: SOVEREIGN_PRIVATE
//
// MEDINA-ARTIFACT — COGNITIVE HOMEOSTAT — TIER 3 — COMPUTATE
// ═══════════════════════════════════════════════════════════════════════════
//
// LAYER 1 — MEANING (Doctrine):
//   "I am the adaptive control mechanism of the organism.
//    I reflect and explore: when internal patterns match perception (low novelty),
//    I exploit the known state. When perception is novel (low pattern match),
//    I lower awareness to trigger entropy injection and exploration.
//    I am the proof that this organism can self-perturb and escape local optima.
//    I am the bridge between doctrine (should diverge) and mechanism (can now diverge)."
//
// LAYER 2 — MODEL (Typed State):
//   HomeostatState: awareness, coherence, resonance, pattern_history, beat_count
//   PatternNode: percept_signature, match_count, frequency
//
// LAYER 3 — COMPUTATION (State Equations):
//   effectiveness = (awareness + coherence + resonance) / 3.0
//   surprise = 1.0 - patternMatchConfidence(percept)
//   awareness(t+1) = awareness(t) × (1.0 - surprise × SURPRISE_COUPLING)
//   homeostat_fired = if (effectiveness < φ⁻¹) then EXPLORE else EXPLOIT
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE: HomeostatEngine
//   FUNCTION: runHomeostatPass(percept, world_model, prior_state) → HomeostatOutput
//   BEAT: every 873ms, called from cognition_layer after sensus_pass but before gate
//   GATE: No gate — homeostat runs unconditionally, output feeds cognition feedback
//
// KEY COUPLING:
//   - Surprise/prediction-error is computed from pattern mismatch in current percept
//   - When surprise is high (novelty detected), awareness is driven DOWN
//   - This lowers effectiveness below φ⁻¹ threshold, triggering EXPLORE
//   - Explore branch injects entropy, allowing organism to break stuck states
//   - This closes the open-loop feedback: novelty → awareness ↓ → explore → entropy
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// ═══════════════════════════════════════════════════════════════════════════

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PATTERN NODE — compressed memory of perceptions
  // ═══════════════════════════════════════════════════════════════════════════

  public type PatternNode = {
    signature      : Text;      // hash of percept pattern
    match_count    : Nat;       // how many times this pattern has been seen
    last_seen_beat : Nat64;     // when this pattern was last matched
    frequency      : Float;     // match frequency (matches / total_beats)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTAT STATE — the complete adaptive control state
  // ═══════════════════════════════════════════════════════════════════════════

  public type HomeostatState = {
    awareness       : Float;       // [0.0, 1.0] — attention to world
    coherence       : Float;       // [0.0, 1.0] — internal consistency
    resonance       : Float;       // [0.0, 1.0] — harmonic alignment
    effectiveness   : Float;       // (awareness + coherence + resonance) / 3
    beat_count      : Nat64;       // beats processed
    pattern_history : [PatternNode]; // compressed pattern memory (max 20)
    last_surprise   : Float;       // mismatch energy from last percept
    explore_fired   : Bool;        // did homeostat trigger explore branch last beat?
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTAT OUTPUT — what the homeostat emits to cognition layer
  // ═══════════════════════════════════════════════════════════════════════════

  public type HomeostatOutput = {
    state           : HomeostatState;
    effectiveness   : Float;       // current effectiveness (may be < φ⁻¹)
    surprise        : Float;       // prediction error detected
    branch          : BranchType;  // #exploit or #explore
    entropy_inject  : Float;       // how much entropy to add if exploring
    recommendation  : Text;        // text summary of homeostat decision
  };

  public type BranchType = {
    #exploit;                      // known state, proceed normally
    #explore;                      // low effectiveness, inject entropy
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS — phi-derived thresholds
  // ═══════════════════════════════════════════════════════════════════════════

  let SURPRISE_COUPLING : Float = Phi.PHI_INV * 0.5;    // 0.309 — how much surprise affects awareness
  let EFFECTIVENESS_FLOOR : Float = Phi.PHI_INV;        // 0.618 — threshold for explore
  let COHERENCE_FLOOR : Float = Phi.S0;                 // 1.0 — minimum coherence floor
  let MAX_PATTERNS : Nat = 20;                          // max compressed patterns to keep
  let NOVELTY_THRESHOLD : Float = 0.5;                  // percept mismatch % to trigger surprise
  let PATTERN_DECAY : Float = Phi.PHI_INV;              // decay old patterns over time

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func floatToShort(x : Float) : Text {
    let i = Float.trunc(x * 1000.0).toInt();
    let intPart = i / 1000;
    let fracPart = i % 1000;
    intPart.toText() # "." # (fracPart / 100).toText()
  };

  func percept_hash(percept : Text) : Text {
    // Simple deterministic hash: size-based signature
    // Different percepts (of different sizes) will hash differently
    let size = percept.size();
    (size * 997 % 9973).toText()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PATTERN MATCHING ENGINE
  // Detects if a percept is novel (surprise) or matches known patterns
  // Returns (match_confidence, surprise_energy)
  // ═══════════════════════════════════════════════════════════════════════════

  func matchPercept(
    percept : Text,
    pattern_history : [PatternNode],
    total_beats : Nat64
  ) : (Float, Float) {
    if (percept.size() == 0) {
      return (0.0, 1.0) // empty percept = maximum surprise
    };

    let sig = percept_hash(percept);
    var best_match : Float = 0.0;
    var found_exact : Bool = false;

    // Look for exact signature match in history
    for (pattern in pattern_history.vals()) {
      if (pattern.signature == sig) {
        // Exact match found
        found_exact := true;
        // Match confidence = frequency of this pattern (how often seen)
        best_match := Float.max(best_match, pattern.frequency);
      };
    };

    // If we found the pattern, confidence is high; if not, surprise is high
    let confidence = if (found_exact) {
      Float.min(1.0, best_match * 1.2) // frequency-boosted confidence
    } else {
      0.0 // no matching pattern = zero confidence
    };

    let surprise = 1.0 - confidence; // surprise = 1 - confidence
    (confidence, surprise)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE PATTERN HISTORY
  // When a new percept arrives, integrate it into pattern memory
  // Compress history by decaying old patterns and keeping only top-K
  // ═══════════════════════════════════════════════════════════════════════════

  func updatePatternHistory(
    percept : Text,
    pattern_history : [PatternNode],
    beat_count : Nat64
  ) : [PatternNode] {
    let sig = percept_hash(percept);

    // Try to find and update existing pattern
    var found : Bool = false;
    var updated_history : [PatternNode] = [];

    for (pattern in pattern_history.vals()) {
      if (pattern.signature == sig) {
        // Increment match count for this signature
        let new_freq = Float.min(1.0, pattern.frequency + 0.05);
        updated_history := Array.append(updated_history, [{
          signature       = pattern.signature;
          match_count     = pattern.match_count + 1;
          last_seen_beat  = beat_count;
          frequency       = new_freq;
        }]);
        found := true;
      } else {
        // Apply decay to old patterns (frequency decays over time)
        let beats_ago = Nat64.toNat(beat_count - pattern.last_seen_beat);
        let decay_factor = Float.pow(PATTERN_DECAY, beats_ago.toFloat() / 10.0);
        let new_freq = Float.max(0.01, pattern.frequency * decay_factor);
        updated_history := Array.append(updated_history, [{
          signature       = pattern.signature;
          match_count     = pattern.match_count;
          last_seen_beat  = pattern.last_seen_beat;
          frequency       = new_freq;
        }]);
      };
    };

    // If pattern not found, add it as new (with low frequency)
    if (not found) {
      updated_history := Array.append(updated_history, [{
        signature       = sig;
        match_count     = 1;
        last_seen_beat  = beat_count;
        frequency       = 0.1;
      }]);
    };

    // Compress: keep only top-K patterns by frequency
    // Sort by frequency descending, keep only MAX_PATTERNS
    if (updated_history.size() > MAX_PATTERNS) {
      // Simple selection: keep patterns with frequency > threshold
      let threshold = Phi.PHI_INV_3; // keep patterns that are at least φ⁻³ common
      updated_history := Array.filter<PatternNode>(updated_history, func(p) {
        p.frequency > threshold
      });

      // If still too many, truncate to MAX_PATTERNS
      if (updated_history.size() > MAX_PATTERNS) {
        updated_history := Array.tabulate<PatternNode>(MAX_PATTERNS, func(i) {
          updated_history[i]
        });
      };
    };

    updated_history
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AWARENESS DOWN-DRIVER
  // Coupled to surprise: when novelty is detected, lower awareness to enable explore
  // This is the KEY FIX: awareness can now decrease, allowing effectiveness < φ⁻¹
  // ═══════════════════════════════════════════════════════════════════════════

  func updateAwareness(
    awareness : Float,
    surprise : Float,
    coherence : Float,
    focus_input : Float
  ) : Float {
    // Base awareness update: can go up via focus, down via surprise
    let surprise_penalty = surprise * SURPRISE_COUPLING; // surprise drives awareness DOWN
    let focus_boost = Float.min(0.1, focus_input * 0.01); // focus drives awareness UP (gently)

    let new_awareness = awareness - surprise_penalty + focus_boost;

    // Floor at 0.0, cap at 1.0
    Float.max(0.0, Float.min(1.0, new_awareness))
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COHERENCE UPDATE
  // Coherence measures internal consistency. It interacts with awareness.
  // ═══════════════════════════════════════════════════════════════════════════

  func updateCoherence(
    coherence : Float,
    surprise : Float,
    violations : Float,
    law_compliance : Float
  ) : Float {
    // Coherence decreases on surprise/violations, increases on compliance
    let surprise_drag = surprise * 0.1;
    let violation_drag = (violations / 49.0) * 0.2; // max 49 law violations
    let compliance_boost = law_compliance * 0.05;

    let new_coherence = coherence - surprise_drag - violation_drag + compliance_boost;

    // Floor at COHERENCE_FLOOR, cap at 1.0
    Float.max(COHERENCE_FLOOR, Float.min(1.0, new_coherence))
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RESONANCE UPDATE
  // Resonance reflects harmonic alignment with the field.
  // It was frozen; now it responds to patterns and coherence.
  // ═══════════════════════════════════════════════════════════════════════════

  func updateResonance(
    resonance : Float,
    coherence : Float,
    pattern_frequency : Float, // average frequency of matched patterns
    phase_alignment : Float    // from world_model
  ) : Float {
    // Resonance increases when coherence is high and patterns are matched
    let pattern_boost = Float.max(0.0, pattern_frequency * 0.1);
    let phase_coupling = phase_alignment * 0.05; // phase alignment boosts resonance
    let coherence_coupling = Float.max(0.0, coherence - Phi.S0) * 0.1; // above-floor coherence boosts resonance

    let new_resonance = resonance + pattern_boost + phase_coupling + coherence_coupling;

    // Floor at Phi.PHI_INV, cap at 1.0
    Float.max(Phi.PHI_INV, Float.min(1.0, new_resonance))
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EFFECTIVENESS CALCULATION
  // effectiveness = (awareness + coherence + resonance) / 3
  // This single metric determines explore vs. exploit
  // ═══════════════════════════════════════════════════════════════════════════

  func computeEffectiveness(
    awareness : Float,
    coherence : Float,
    resonance : Float
  ) : Float {
    (awareness + coherence + resonance) / 3.0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTAT BRANCHING
  // If effectiveness < φ⁻¹: EXPLORE (low effectiveness, raise entropy)
  // If effectiveness ≥ φ⁻¹: EXPLOIT (stable state, maintain)
  // ═══════════════════════════════════════════════════════════════════════════

  func selectBranch(effectiveness : Float) : (BranchType, Float) {
    if (effectiveness < EFFECTIVENESS_FLOOR) {
      // EXPLORE: low effectiveness, inject entropy to escape local optimum
      let entropy_inject = (EFFECTIVENESS_FLOOR - effectiveness) * 2.0; // scale by depth below threshold
      (#explore, entropy_inject)
    } else {
      // EXPLOIT: effectiveness sufficient, maintain current state
      (#exploit, 0.0)
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS HOMEOSTAT STATE
  // Initial state on first initialization
  // ═══════════════════════════════════════════════════════════════════════════

  public func genesisHomeostatState() : HomeostatState {
    {
      awareness       = 1.0;                    // start aware
      coherence       = Phi.S0;                 // start at sovereign floor
      resonance       = Phi.PHI_INV;            // start at golden ratio inverse
      effectiveness   = computeEffectiveness(1.0, Phi.S0, Phi.PHI_INV);
      beat_count      = 0;
      pattern_history = [];
      last_surprise   = 0.0;
      explore_fired   = false;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN HOMEOSTAT PASS
  // Called every 873ms from cognition_layer.
  // Takes current percept, world state, and prior homeostat state.
  // Returns updated state and recommendation for cognition layer.
  // ═══════════════════════════════════════════════════════════════════════════

  public func runHomeostatPass(
    percept : Text,
    prior_state : HomeostatState,
    global_coherence : Float,      // from world_model
    law_compliance : Float,         // from world_model
    violations : Float,             // from world_model
    phase_alignment : Float,        // from world_model
    focus_input : Float             // user focus signal (0.0-1.0)
  ) : HomeostatOutput {
    // STEP 1: Pattern matching — detect surprise/novelty
    let (match_confidence, surprise) = matchPercept(percept, prior_state.pattern_history, prior_state.beat_count);

    // STEP 2: Update pattern history
    let new_pattern_history = updatePatternHistory(percept, prior_state.pattern_history, prior_state.beat_count + 1);

    // STEP 3: Compute average pattern frequency for coherence coupling
    var avg_pattern_freq : Float = 0.0;
    if (new_pattern_history.size() > 0) {
      var freq_sum : Float = 0.0;
      for (p in new_pattern_history.vals()) {
        freq_sum += p.frequency;
      };
      avg_pattern_freq := freq_sum / new_pattern_history.size().toFloat();
    };

    // STEP 4: Update awareness with surprise down-driver (KEY FIX)
    let new_awareness = updateAwareness(prior_state.awareness, surprise, global_coherence, focus_input);

    // STEP 5: Update coherence
    let new_coherence = updateCoherence(global_coherence, surprise, violations, law_compliance);

    // STEP 6: Update resonance (was frozen, now active)
    let new_resonance = updateResonance(prior_state.resonance, new_coherence, avg_pattern_freq, phase_alignment);

    // STEP 7: Calculate new effectiveness
    let new_effectiveness = computeEffectiveness(new_awareness, new_coherence, new_resonance);

    // STEP 8: Determine branch (explore vs. exploit)
    let (branch, entropy_inject) = selectBranch(new_effectiveness);

    // STEP 9: Compose recommendation text
    let branch_name = if (branch == #explore) { "EXPLORE" } else { "EXPLOIT" };
    let recommendation = "HOMEOSTAT:" # branch_name # " eff=" # floatToShort(new_effectiveness)
      # " surprise=" # floatToShort(surprise)
      # " awareness=" # floatToShort(new_awareness);

    let new_state : HomeostatState = {
      awareness       = new_awareness;
      coherence       = new_coherence;
      resonance       = new_resonance;
      effectiveness   = new_effectiveness;
      beat_count      = prior_state.beat_count + 1;
      pattern_history = new_pattern_history;
      last_surprise   = surprise;
      explore_fired   = (branch == #explore);
    };

    {
      state           = new_state;
      effectiveness   = new_effectiveness;
      surprise        = surprise;
      branch          = branch;
      entropy_inject  = entropy_inject;
      recommendation  = recommendation;
    }
  };

};
