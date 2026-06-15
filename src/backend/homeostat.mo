// homeostat.mo — EXPLORE/EXPLOIT HOMEOSTAT & AWARENESS DOWN-DRIVER
// ANIMUS Adaptive Mechanism for Divergence (Divergence Experiment Charter)
//
// DOCTRINE: "The organism self-perturbs when it hits local optima.
//           Effectiveness tracks (awareness + coherence + resonance) / 3.
//           When effectiveness < φ⁻¹ (0.618), the explore arm fires and entropy injects.
//           Surprise/prediction-error drives awareness DOWN on mismatch,
//           enabling the homeostat to close the open loop."
//
// MEDINA-ARTIFACT (4 layers):
//
// LAYER 1 — MEANING (Doctrine Clause):
//   "I am the adaptive mechanism. When patterns fail to predict percepts,
//    my awareness contracts. When awareness contracts enough, effectiveness drops
//    below the golden ratio. That unlocks exploration. I am the bridge between
//    law and code — I close the loop that makes divergence possible.
//    Without me, the organism converges to low-entropy local optima forever.
//    With me, it self-perturbs, explores, escapes."
//
// LAYER 2 — MODEL (Typed Schema): HomeostasisState, PerceptRecord, EffectivenessMetrics
//
// LAYER 3 — COMPUTATION (State Equations):
//   effectiveness = (awareness + coherence + resonance) / 3
//   surprise = |percept - predicted_pattern|
//   awareness_delta = -min(0.1, surprise × 0.1)  ← down-driver on mismatch
//   explore_triggered = (effectiveness < φ⁻¹) ∧ (coherence ≥ φ⁻¹)
//   entropy_injected = explore_triggered → entropy += Φ⁻¹
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE: HomeostasisEngine
//   FUNCTION: procesPercept() — sensory input with pattern matching
//   FUNCTION: tickHomeostat() — every 873ms, compute effectiveness and gates
//   GATE: explore_triggered → entropy injection via phantom_entropy
//   BEAT: integrated into main.mo heartbeat at 873ms
//
// PYTHAGORAS: every threshold is φ-derived (golden ratio)
// EUCLID:     single source of truth — awareness is persistent state
// CONFUCIUS:  right relationship — awareness down-driver couples perception to cognition

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PERCEPT RECORD — sensory input for pattern matching
  // ═══════════════════════════════════════════════════════════════════════════

  public type PerceptRecord = {
    timestamp     : Int;
    value         : Float;           // magnitude of percept
    pattern_id    : Text;            // identifier for expected pattern
    matched       : Bool;            // does it match previous pattern?
    prediction    : Float;           // predicted value from learned pattern
    surprise      : Float;           // |percept - prediction|
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EFFECTIVENESS METRICS — the health of the homeostat
  // ═══════════════════════════════════════════════════════════════════════════

  public type EffectivenessMetrics = {
    awareness     : Float;           // [PHI_INV, 1.0] — contract on surprise
    coherence     : Float;           // [PHI_INV, 1.0] — from global field
    resonance     : Float;           // [PHI_INV, 1.0] — pattern alignment stability
    effectiveness : Float;           // (awareness + coherence + resonance) / 3
    explore_ready : Bool;            // effectiveness < φ⁻¹?
    entropy_target: Float;           // target entropy when explore fires
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTASIS STATE — persistent state across beats
  // ═══════════════════════════════════════════════════════════════════════════

  public type HomeostasisState = {
    awareness              : Float;           // core state: [PHI_INV, 1.0]
    resonance              : Float;           // pattern alignment: [PHI_INV, 1.0]
    percept_history        : [PerceptRecord]; // recent perceptions (max 89 = F(11))
    pattern_library        : [(Text, Float)]; // learned patterns: (pattern_id, avg_value)
    explore_count          : Nat;             // times explore branch fired
    exploit_count          : Nat;             // times exploit branch executed
    entropy_injected_total : Float;           // cumulative entropy added
    last_mismatch_beat     : Nat;             // beat when last pattern mismatch occurred
    surprise_history       : [Float];         // recent surprise values for learning
    beat_count             : Nat;             // for gating
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultHomeostasisState() : HomeostasisState {
    {
      awareness              = 1.0;                   // start high
      resonance              = Phi.PHI_INV;           // 0.618 baseline
      percept_history        = [];
      pattern_library        = [];
      explore_count          = 0;
      exploit_count          = 0;
      entropy_injected_total = 0.0;
      last_mismatch_beat     = 0;
      surprise_history       = [];
      beat_count             = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE COMPUTATION — effectiveness and explore/exploit logic
  // ═══════════════════════════════════════════════════════════════════════════

  /// computeEffectiveness — the central metric of the homeostat
  /// effectiveness = (awareness + coherence + resonance) / 3
  /// If effectiveness < φ⁻¹, explore arm should fire.
  public func computeEffectiveness(
    awareness: Float,
    coherence: Float,
    resonance: Float
  ) : Float {
    // Clamp all inputs to valid range
    let a_clamped = Float.max(Phi.PHI_INV, Float.min(1.0, awareness));
    let c_clamped = Float.max(Phi.PHI_INV, Float.min(1.0, coherence));
    let r_clamped = Float.max(Phi.PHI_INV, Float.min(1.0, resonance));
    (a_clamped + c_clamped + r_clamped) / 3.0
  };

  /// checkExploreReadiness — detect if explore/exploit threshold is crossed
  /// Returns (explore_triggered, entropy_target)
  /// explore_triggered: effectiveness < φ⁻¹ AND coherence ≥ φ⁻¹ (gating)
  /// entropy_target: target entropy to inject (φ⁻¹ = 0.618 baseline)
  public func checkExploreReadiness(effectiveness: Float, coherence: Float) : (Bool, Float) {
    let explore_threshold = Phi.PHI_INV;  // 0.618...
    let coherence_gate = Phi.PHI_INV;     // must maintain minimum coherence to explore safely
    
    let explore_triggered = (effectiveness < explore_threshold) and (coherence >= coherence_gate);
    let entropy_target = if (explore_triggered) { 
      Phi.PHI_INV        // 0.618 — the explorer's entropy injection level
    } else { 
      0.0
    };
    
    (explore_triggered, entropy_target)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SURPRISE/PREDICTION-ERROR COUPLING — awareness down-driver
  // ═══════════════════════════════════════════════════════════════════════════

  /// procesPercept — integrate sensory input and detect pattern mismatches
  /// Returns updated HomeostasisState with awareness adjustment
  public func procesPercept(
    state: HomeostasisState,
    percept_value: Float,
    pattern_id: Text,
    coherence: Float,
    beat: Nat
  ) : HomeostasisState {
    // Step 1: Look up learned pattern for this ID
    let predicted_value = lookupPattern(state.pattern_library, pattern_id);
    
    // Step 2: Compute surprise (prediction error)
    let surprise = Float.abs(percept_value - predicted_value);
    
    // Step 3: Determine if pattern matched (surprise below threshold)
    let pattern_matched = surprise < Phi.PHI_INV_2;  // 0.382
    
    // Step 4: Update resonance based on match quality
    let resonance_delta = if (pattern_matched) {
      // Match: strengthen resonance (move toward 1.0)
      Phi.PHI_INV_3 * 0.01  // +0.00236
    } else {
      // Mismatch: weaken resonance (move toward PHI_INV)
      -Phi.PHI_INV_3 * 0.02  // -0.00472
    };
    let new_resonance = Float.max(Phi.PHI_INV, Float.min(1.0, state.resonance + resonance_delta));
    
    // Step 5: CRITICAL — drive awareness DOWN on mismatch (prediction error coupling)
    // The surprise/prediction-error term provides the missing actuator.
    // When surprise is high, awareness contracts, pulling effectiveness below threshold.
    let awareness_delta = if (not pattern_matched) {
      // Mismatch detected: contract awareness
      -Float.min(0.1, surprise * 0.1)
    } else {
      // Match: maintain or slightly increase awareness (focus)
      Float.max(0.0, Phi.PHI_INV_3 * 0.001)
    };
    let new_awareness = Float.max(Phi.PHI_INV, Float.min(1.0, state.awareness + awareness_delta));
    
    // Step 6: Update pattern library if we've learned something
    let updated_library = if (state.percept_history.size() > 10) {
      updatePatternLibrary(state.pattern_library, pattern_id, percept_value)
    } else {
      state.pattern_library
    };
    
    // Step 7: Maintain percept history (max 89 records = F(11))
    let new_percept = {
      timestamp = 0;  // would be Time.now() in actual use
      value = percept_value;
      pattern_id = pattern_id;
      matched = pattern_matched;
      prediction = predicted_value;
      surprise = surprise;
    };
    let updated_history = appendPercept(state.percept_history, new_percept, 89);
    
    // Step 8: Track surprise for learning
    let updated_surprise_history = appendFloat(state.surprise_history, surprise, 34);  // F(9)
    
    // Step 9: Record mismatch beat
    let last_mismatch = if (not pattern_matched) { beat } else { state.last_mismatch_beat };
    
    {
      state with
      awareness = new_awareness;
      resonance = new_resonance;
      percept_history = updated_history;
      pattern_library = updated_library;
      surprise_history = updated_surprise_history;
      last_mismatch_beat = last_mismatch;
      beat_count = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTASIS TICK — every 873ms heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  /// tickHomeostat — update homeostat state and check explore/exploit gate
  /// Returns (updated_state, explore_triggered, entropy_to_inject)
  public func tickHomeostat(
    state: HomeostasisState,
    global_coherence: Float,
    beat: Nat
  ) : (HomeostasisState, Bool, Float) {
    // Compute effectiveness with current metrics
    let effectiveness = computeEffectiveness(
      state.awareness,
      global_coherence,
      state.resonance
    );
    
    // Check if explore condition is met
    let (explore_triggered, entropy_target) = checkExploreReadiness(effectiveness, global_coherence);
    
    // Update counters
    let new_explore_count = if (explore_triggered) { state.explore_count + 1 } else { state.explore_count };
    let new_exploit_count = if (not explore_triggered) { state.exploit_count + 1 } else { state.exploit_count };
    let new_entropy_total = state.entropy_injected_total + entropy_target;
    
    // Slowly restore awareness toward 1.0 between mismatches (learning recovery)
    // But only if we haven't had a recent mismatch
    let beats_since_mismatch = beat - state.last_mismatch_beat;
    let awareness_recovery = if (beats_since_mismatch > 10 and state.awareness < 1.0) {
      // Recover: move toward 1.0 slowly
      Phi.PHI_INV_3 * 0.001
    } else {
      0.0
    };
    let recovered_awareness = Float.min(1.0, state.awareness + awareness_recovery);
    
    let updated_state = {
      state with
      awareness = recovered_awareness;
      explore_count = new_explore_count;
      exploit_count = new_exploit_count;
      entropy_injected_total = new_entropy_total;
      beat_count = beat;
    };
    
    (updated_state, explore_triggered, entropy_target)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // METRICS SNAPSHOT — for external reporting
  // ═══════════════════════════════════════════════════════════════════════════

  /// getMetrics — snapshot of current effectiveness metrics
  public func getMetrics(
    state: HomeostasisState,
    coherence: Float
  ) : EffectivenessMetrics {
    let effectiveness = computeEffectiveness(state.awareness, coherence, state.resonance);
    let (explore_ready, entropy_target) = checkExploreReadiness(effectiveness, coherence);
    {
      awareness = state.awareness;
      coherence = coherence;
      resonance = state.resonance;
      effectiveness = effectiveness;
      explore_ready = explore_ready;
      entropy_target = entropy_target;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// lookupPattern — retrieve learned pattern value, or sensible default
  func lookupPattern(library: [(Text, Float)], pattern_id: Text) : Float {
    for ((pid, val) in library.vals()) {
      if (pid == pattern_id) return val;
    };
    1.0  // default: expect high value
  };

  /// updatePatternLibrary — learn or update pattern average
  func updatePatternLibrary(
    library: [(Text, Float)],
    pattern_id: Text,
    value: Float
  ) : [(Text, Float)] {
    var found = false;
    let updated = Array.map<(Text, Float), (Text, Float)>(
      library,
      func(entry: (Text, Float)) : (Text, Float) {
        let (pid, old_val) = entry;
        if (pid == pattern_id) {
          found := true;
          // Running average: (old_val + value) / 2
          (pid, (old_val + value) / 2.0)
        } else {
          entry
        }
      }
    );
    
    if (found) {
      updated
    } else {
      // Add new pattern
      Array.append(library, [(pattern_id, value)])
    }
  };

  /// appendPercept — add to percept history, maintain max size
  func appendPercept(
    history: [PerceptRecord],
    percept: PerceptRecord,
    max_size: Nat
  ) : [PerceptRecord] {
    let new_history = Array.append(history, [percept]);
    if (new_history.size() > max_size) {
      Array.subArray(new_history, new_history.size() - max_size, max_size)
    } else {
      new_history
    }
  };

  /// appendFloat — add to float history, maintain max size
  func appendFloat(
    history: [Float],
    value: Float,
    max_size: Nat
  ) : [Float] {
    let new_history = Array.append(history, [value]);
    if (new_history.size() > max_size) {
      Array.subArray(new_history, new_history.size() - max_size, max_size)
    } else {
      new_history
    }
  };

};
