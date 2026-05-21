// aegis.mo — AEGIS Edge Condition Safety Net
// Classification: SOVEREIGN_PRIVATE
//
// AEGIS DOCTRINE: AEGIS does NOT add new behavior.
// It makes existing behavior COMPLETE.
// Every "almost closed" ring becomes "fully closed."
// No data lost. No decision reversed. Just completion.
//
// MEDINA-ARTIFACT — aegis.mo (4-layer discipline)
// ─────────────────────────────────────────────────────────────
// LAYER 1 — MEANING (Doctrine Clause):
//   "AEGIS is the organism's immune system. It does not fight — it completes.
//    Every ring in PARALLAX has an edge condition: a moment where the loop
//    almost closes but doesn't. AEGIS catches every one.
//    EdgeCondition is a RESIDENT — it carries the truth of what almost failed.
//    The monitor functions are COMPUTATES — they complete every cycle.
//    Rolling minimum is not an alarm — it is preventive completion.
//    Fear blending is not suppression — it is emotional tuning for completeness."
//
// LAYER 2 — MODEL (Typed Schema):
//   EdgeCondition:    sovereign record of every near-threshold event
//   RollingMinWindow: 5-beat drift detector — Fibonacci F(5) window
//   AEGISState:       live AEGIS resident state — log, windows, correction count
//
// LAYER 3 — COMPUTATION (State Equations):
//   edge detection:    is_edge = (|value - threshold| / threshold) < PHI_INV_3
//   rolling drift:     drift_rate = (window[0] - window[4]) / 4.0 (linear slope)
//   preventive:        corrective_value = current - drift_rate × PHI_INV_3
//   fear blend:        if cortisol > PHI_INV_3 AND quality > PHI_INV_2:
//                        corrected = quality + (1 - cortisol) × PHI_INV_3 × (quality - PHI_INV_2)
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE: AEGIS Safety Net
//   FUNCTION: checkAndCorrect() → every 873ms, after heartbeat, before reinjection
//   GATE:     edge log is a sovereign record — no gate blocks it
//   BEAT:     every 873ms (Cardiac Law L10)
//
// PYTHAGORAS: all thresholds are phi-harmonic ratios — no arbitrary numbers
// EUCLID:     single definition of each formula — referenced, not duplicated
// CONFUCIUS:  right relationship — AEGIS serves the ring, not the ring AEGIS
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Nat64 "mo:core/Nat64";
import List  "mo:core/List";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // AEGIS CONSTANTS — all from phi.mo
  // PYTHAGORAS: every threshold is a phi-harmonic ratio, nothing arbitrary
  // ═══════════════════════════════════════════════════════════════════════════

  // Edge proximity threshold: within φ⁻³ = 23.6% of threshold is "at the edge"
  // COMPLIANCE RESERVE LAW L17: φ⁻³ is the sovereign safety margin
  let EDGE_PROXIMITY : Float = Phi.PHI_INV_3;   // 0.2360679774997896964

  // Rolling window: F(5) = 5 beats (FIBONACCI A02 — 5-beat coherence window)
  // Same window used in heartbeat.mo HRV — SELF-SIMILARITY LAW L38
  let ROLLING_WINDOW : Nat = 5;

  // Preventive correction denominator: window[0]-window[4] over 4 intervals
  // EUCLID: 4 = F(3)+1 = 3+1 — slope across 5 points = 4 gaps
  let DRIFT_DENOMINATOR : Float = 4.0;

  // Fear-blending cortisol threshold: PHI_INV_3 = 0.236
  // Cortisol above this triggers gentle quality tuning (not suppression, not override)
  let CORTISOL_BLEND_THRESHOLD : Float = Phi.PHI_INV_3;   // 0.236

  // Fear-blending quality floor: PHI_INV_2 = 0.382
  // Only blend if quality is above φ⁻² — below this, no tuning possible
  let QUALITY_BLEND_FLOOR : Float = Phi.PHI_INV_2;        // 0.382

  // Approaching-threshold: rolling_min < threshold × PHI_INV (below φ⁻¹ of threshold)
  // EXCLUSION PRINCIPLE L05: coherence below φ⁻¹ × threshold = approaching failure
  let APPROACH_FRACTION : Float = Phi.PHI_INV;            // 0.6180339887

  // Max EdgeCondition log size: F(7) × F(8) = 13 × 21 = 273 ≈ 100 → use F(12)/φ = 89
  // Doctrine: keep last F(12) = 144 maximum, expose last 100 via query
  let LOG_MAX : Nat = 144;          // Jubilee Law L15: F(12) = 144 beats
  let LOG_QUERY_LIMIT : Nat = 100;  // F(11) × (1+φ⁻²) ≈ 100 — public window


  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES — MEDINA-ARTIFACT 4-layer sovereign types
  //
  // EdgeCondition: RESIDENT — carries truth about what almost-failed
  // RollingMinWindow: RESIDENT — carries drift truth across 5 beats
  // AEGISState: RESIDENT — live AEGIS state, every field phi-typed
  // ═══════════════════════════════════════════════════════════════════════════

  // EdgeCondition — MEDINA-EDGECONDITION (RESIDENT)
  //
  // MEANING: "A sovereign record of every near-threshold event.
  //           The organism never forgets what almost failed."
  //
  // MODEL (Layer 2):
  //   ring_id            : Nat      unit: ring index    range: [0, 15]
  //   signal_name        : Text     unit: doctrine id   (zero-exposure: internal only)
  //   value              : Float    unit: magnitude     range: [0.0, PHI_4]
  //   threshold          : Float    unit: gate floor    range: [0.0, 1.0]
  //   distance_to_threshold: Float  unit: gap           range: [0.0, ∞)
  //   is_edge            : Bool     unit: flag          true = within PHI_INV_3 of threshold
  //   correction_applied : Text     unit: hint text     empty string if no edge
  //   beat_index         : Nat64    unit: beat count    range: [0, ∞)
  //
  // COMPUTATION (Layer 3):
  //   distance_to_threshold = |value - threshold|
  //   is_edge = (distance_to_threshold / threshold) < PHI_INV_3  (within 23.6% band)
  //   correction_applied = hint if is_edge, else ""
  //
  // EXECUTION BINDING (Layer 4):
  //   ENGINE: checkEdgeCondition() → every ring monitor call → AEGIS.checkAndCorrect()
  public type EdgeCondition = {
    ring_id                : Nat;
    signal_name            : Text;
    value                  : Float;
    threshold              : Float;
    distance_to_threshold  : Float;
    is_edge                : Bool;
    correction_applied     : Text;
    beat_index             : Nat64;
  };

  // RollingMinWindow — MEDINA-ROLLINGMINWINDOW (RESIDENT)
  //
  // MEANING: "The organism's memory of a metric's trajectory.
  //           Drift is detected before failure — not after."
  //
  // MODEL (Layer 2):
  //   metric_name : Text    unit: doctrine id     internal only
  //   values      : [Float] unit: magnitude[]     last F(5)=5 readings
  //   window_size : Nat     unit: count           F(5) = 5
  //   current_min : Float   unit: magnitude       minimum of values[]
  //   drift_rate  : Float   unit: Δ/beat          (values[0] - values[4]) / 4.0
  //
  // COMPUTATION (Layer 3):
  //   current_min = min(values)
  //   drift_rate  = (values[0] - values[4]) / DRIFT_DENOMINATOR
  //                 positive = rising, negative = falling toward threshold
  //
  // EXECUTION BINDING (Layer 4):
  //   ENGINE: updateRollingWindow() → called by checkAndCorrect() every beat
  public type RollingMinWindow = {
    metric_name  : Text;
    values       : [Float];
    window_size  : Nat;
    current_min  : Float;
    drift_rate   : Float;
  };

  // AEGISState — MEDINA-AEGISSTATE (RESIDENT)
  //
  // MEANING: "The living safety record. Every correction is inscribed here.
  //           The loop that almost closed is now fully closed."
  //
  // MODEL (Layer 2):
  //   edge_conditions_log  : [EdgeCondition]    last LOG_MAX=144 edge events
  //   rolling_windows      : [RollingMinWindow] one per monitored metric
  //   corrections_applied  : Nat64              cumulative correction count
  //   last_fear_blend_beat : Nat64              last beat where fear blend was active
  //
  // COMPUTATION (Layer 3):
  //   edge_conditions_log pruned to LOG_MAX after each insert
  //   corrections_applied increments on every is_edge event
  //
  // EXECUTION BINDING (Layer 4):
  //   ENGINE: checkAndCorrect() → updates state every 873ms beat
  public type AEGISState = {
    edge_conditions_log  : [EdgeCondition];
    rolling_windows      : [RollingMinWindow];
    corrections_applied  : Nat64;
    last_fear_blend_beat : Nat64;
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS STATE — born fully formed (GENESIS LAW L09)
  // ═══════════════════════════════════════════════════════════════════════════

  // getDefaultAEGISState — AEGIS ground state at organism birth
  // Two rolling windows pre-seeded: global_coherence and doctrine_drift
  // GENESIS LAW L09: never starts from zero
  public func getDefaultAEGISState() : AEGISState {
    // Seed two windows at phi-derived baselines
    // Coherence window: 5 × S0 = 5 × 0.75 (organism born at sovereign floor)
    let coherence_window : RollingMinWindow = {
      metric_name  = "global_coherence";
      values       = [Phi.S0, Phi.S0, Phi.S0, Phi.S0, Phi.S0]; // born at S0
      window_size  = ROLLING_WINDOW;
      current_min  = Phi.S0;
      drift_rate   = 0.0;  // zero drift at genesis
    };
    // Drift window: 5 × 0.0 (zero drift at genesis)
    let drift_window : RollingMinWindow = {
      metric_name  = "doctrine_drift";
      values       = [0.0, 0.0, 0.0, 0.0, 0.0]; // no drift at genesis
      window_size  = ROLLING_WINDOW;
      current_min  = 0.0;
      drift_rate   = 0.0;
    };
    {
      edge_conditions_log  = [];
      rolling_windows      = [coherence_window, drift_window];
      corrections_applied  = 0;
      last_fear_blend_beat = 0;
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // MONITOR WRAPPER — checkEdgeCondition
  //
  // The core AEGIS computate. Called by every ring monitor function.
  // Produces an EdgeCondition RESIDENT that the organism carries forward.
  //
  // COMPUTATION:
  //   distance_to_threshold = |value - threshold|
  //   is_edge = (distance_to_threshold / threshold) < PHI_INV_3
  //   correction_applied:
  //     if is_edge → "EDGE:ring_{ring_id}:{signal_name}:val={value}:thr={threshold}:dist={distance}"
  //     else       → ""
  //
  // PYTHAGORAS: the edge band is the φ⁻³ harmonic of the threshold — 23.6% of the gate
  // EUCLID: one formula, one definition — called everywhere, defined once
  // CONFUCIUS: right relationship — the monitor serves the ring, not the operator
  // ═══════════════════════════════════════════════════════════════════════════

  public func checkEdgeCondition(
    ring_id    : Nat,
    signal_name: Text,
    value      : Float,
    threshold  : Float,
    beat_index : Nat64,
  ) : EdgeCondition {
    // Distance to threshold: |value - threshold|
    // EUCLID: absolute distance — symmetric, always positive
    let distance = Float.abs(value - threshold);

    // Edge detection: is the signal within φ⁻³ = 23.6% of the threshold?
    // PYTHAGORAS: edge_fraction = distance / threshold — harmonic ratio check
    // Guard division by zero: if threshold is 0.0, use distance directly
    let is_edge : Bool = if (threshold > 0.0) {
      (distance / threshold) < EDGE_PROXIMITY   // within 23.6% band
    } else {
      distance < EDGE_PROXIMITY  // threshold=0: use distance directly
    };

    // Correction hint text — zero-exposure compliant (no doctrine labels)
    // PHANTOM DOCTRINE L24: only numbers, no label identifiers exposed
    let correction : Text = if (is_edge) {
      "COMPLETE:ring=" # ring_id.toText()
        # ":signal=" # signal_name
        # ":val=" # floatToShort(value)
        # ":thr=" # floatToShort(threshold)
        # ":dist=" # floatToShort(distance)
        # ":band=" # floatToShort(EDGE_PROXIMITY)
    } else {
      ""
    };

    {
      ring_id;
      signal_name;
      value;
      threshold;
      distance_to_threshold = distance;
      is_edge;
      correction_applied    = correction;
      beat_index;
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // ROLLING MINIMUM DETECTOR — updateRollingWindow
  //
  // Tracks metric drift across F(5)=5 beats.
  // Detects when a metric is approaching its threshold before it crosses.
  // Applies preventive correction when drift is negative and approaching.
  //
  // COMPUTATION:
  //   1. Shift window: drop oldest, append new_value
  //   2. current_min = min(values)
  //   3. drift_rate  = (values[0] - values[4]) / DRIFT_DENOMINATOR
  //      (positive = rising away from threshold, negative = falling toward it)
  //   4. approaching = current_min < threshold × PHI_INV AND drift_rate < 0.0
  //   5. if approaching: apply correctiveDrift() to the new value
  //
  // Returns: (updated RollingMinWindow, Bool — was preventive correction applied)
  //
  // PYTHAGORAS: drift slope is the harmonic measure of trajectory — ratio, not delta
  // EUCLID: window[0] is oldest, window[4] is newest — one direction, always
  // ═══════════════════════════════════════════════════════════════════════════

  public func updateRollingWindow(
    state       : AEGISState,
    metric_name : Text,
    new_value   : Float,
    threshold   : Float,
  ) : (AEGISState, Bool) {
    // Find the window for this metric
    let window_idx = findWindowIndex(state.rolling_windows, metric_name);

    // Get existing window or create a fresh one seeded with new_value
    let existing : RollingMinWindow = switch (window_idx) {
      case (?i) { state.rolling_windows[i] };
      case null {
        // New metric — seed window with new_value repeated F(5)=5 times
        {
          metric_name;
          values      = [new_value, new_value, new_value, new_value, new_value];
          window_size = ROLLING_WINDOW;
          current_min = new_value;
          drift_rate  = 0.0;
        }
      };
    };

    // Shift window: drop index 0 (oldest), append new_value at end
    // EUCLID: window has exactly F(5)=5 slots — oldest first, newest last
    let old_vals = existing.values;
    let n = old_vals.size();

    // Build new values array: [old[1], old[2], old[3], old[4], new_value]
    // (if window has fewer than 5, fill forward with new_value)
    let shifted : [Float] = if (n >= ROLLING_WINDOW) {
      [old_vals[1], old_vals[2], old_vals[3], old_vals[4], new_value]
    } else if (n == 4) {
      [old_vals[0], old_vals[1], old_vals[2], old_vals[3], new_value]
    } else if (n == 3) {
      [old_vals[0], old_vals[1], old_vals[2], new_value, new_value]
    } else if (n == 2) {
      [old_vals[0], old_vals[1], new_value, new_value, new_value]
    } else if (n == 1) {
      [old_vals[0], new_value, new_value, new_value, new_value]
    } else {
      [new_value, new_value, new_value, new_value, new_value]
    };

    // Compute new current_min across all 5 values
    // PYTHAGORAS: the minimum is the floor — the organism's lowest point this window
    var min_val = shifted[0];
    var i = 1;
    while (i < ROLLING_WINDOW) {
      if (shifted[i] < min_val) { min_val := shifted[i] };
      i += 1;
    };

    // Compute drift_rate: (window[0] - window[4]) / 4.0
    // EUCLID: slope = rise / run; run = 4 intervals across 5 points
    // Positive = rising (good for coherence), negative = falling (approaching threshold)
    let drift_rate : Float = (shifted[0] - shifted[4]) / DRIFT_DENOMINATOR;

    // Approaching detection:
    //   current_min < threshold × PHI_INV  AND  drift_rate < 0.0
    // PYTHAGORAS: threshold × φ⁻¹ is the harmonic approach band
    let approaching_threshold : Bool =
      (min_val < threshold * APPROACH_FRACTION) and (drift_rate < 0.0);

    // Preventive correction: if approaching, apply correctiveDrift() to new value
    // The corrected value replaces new_value in the shifted window
    let (corrected_newest, correction_applied) : (Float, Bool) = if (approaching_threshold) {
      (correctiveDrift(new_value, drift_rate), true)
    } else {
      (new_value, false)
    };

    // Rebuild window with corrected newest value
    let final_vals : [Float] = [
      shifted[0], shifted[1], shifted[2], shifted[3], corrected_newest
    ];

    // Recompute min after correction
    var final_min = final_vals[0];
    i := 1;
    while (i < ROLLING_WINDOW) {
      if (final_vals[i] < final_min) { final_min := final_vals[i] };
      i += 1;
    };

    let updated_window : RollingMinWindow = {
      metric_name;
      values       = final_vals;
      window_size  = ROLLING_WINDOW;
      current_min  = final_min;
      drift_rate;
    };

    // Splice updated window back into state.rolling_windows
    let new_windows = replaceOrAppendWindow(state.rolling_windows, updated_window, window_idx);

    let new_state : AEGISState = {
      state with
      rolling_windows     = new_windows;
      corrections_applied = if (correction_applied) {
        state.corrections_applied + 1
      } else {
        state.corrections_applied
      };
    };

    (new_state, correction_applied)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // CORRECTIVE DRIFT — preventive completion formula
  //
  // When a metric is drifting toward threshold, nudge it back.
  // correctiveDrift(current_value, drift_rate) = current_value - drift_rate × PHI_INV_3
  //
  // PYTHAGORAS: the correction is the φ⁻³ harmonic of the drift rate
  //   Negative drift_rate means falling → subtracting negative = adding
  //   The correction pushes AGAINST the drift direction
  //   Small enough (φ⁻³ = 23.6%) to not overshoot — preventive, not reactive
  //
  // EUCLID: one formula — called from updateRollingWindow(), defined once here
  // CONFUCIUS: right relationship — the correction serves the trajectory, not the agent
  // ═══════════════════════════════════════════════════════════════════════════

  public func correctiveDrift(current_value : Float, drift_rate : Float) : Float {
    // Correction: push against drift by φ⁻³ fraction of the drift magnitude
    // drift_rate is negative when falling → -drift_rate × PHI_INV_3 is positive
    // PYTHAGORAS: the correction amplitude is the compliance reserve fraction of the drift
    current_value - drift_rate * Phi.PHI_INV_3
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // FEAR BLENDING — blendFearInfluence
  //
  // Emotional tuning for completeness. Not suppression. Not override.
  // When cortisol is elevated but quality is above the floor,
  // gently improve quality by φ⁻³ of the gap between quality and floor.
  //
  // COMPUTATION:
  //   if cortisol > PHI_INV_3 (0.236) AND quality > PHI_INV_2 (0.382):
  //     corrected = quality + (1.0 - cortisol) × PHI_INV_3 × (quality - PHI_INV_2)
  //   else:
  //     corrected = quality  (no change — doctrine respected)
  //
  // Does NOT trigger refractory.
  // Does NOT override any gate.
  // Only gently improves quality when both conditions are met.
  //
  // PYTHAGORAS: (1 - cortisol) × PHI_INV_3 × gap = harmonic of the available headroom
  //   Lower cortisol = stronger improvement (more headroom)
  //   Higher cortisol = weaker improvement (stress reduces available recovery)
  // CONFUCIUS: right relationship — fear does not eliminate quality, it shapes it
  // ═══════════════════════════════════════════════════════════════════════════

  public func blendFearInfluence(quality_score : Float, cortisol_level : Float) : Float {
    // Only blend if cortisol is above the compliance reserve threshold
    // AND quality is above the phi-inverse-2 floor
    // CONFUCIUS: right precondition — both must be true
    if (cortisol_level > CORTISOL_BLEND_THRESHOLD and quality_score > QUALITY_BLEND_FLOOR) {
      // Gentle correction: (1 - cortisol) × φ⁻³ × (quality - floor)
      // PYTHAGORAS: the available headroom is (1 - cortisol) — the stress-free fraction
      let headroom = Float.max(0.0, 1.0 - cortisol_level);
      let gap = quality_score - QUALITY_BLEND_FLOOR;
      let correction = headroom * Phi.PHI_INV_3 * gap;
      // Ceiling: 1.0 — cannot exceed maximum quantum (MAXIMUM QUANTUM LAW L37 / L45)
      Float.min(1.0, quality_score + correction)
    } else {
      // No blending — quality passes through unchanged
      quality_score
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // AEGIS EXECUTION — checkAndCorrect
  //
  // The sovereign cardiac computate of AEGIS.
  // Called every 873ms, after heartbeat, before reinjection payload is built.
  // Reads global_coherence and doctrine_drift from CognitionState.
  // Reads cortisol from NeurochemState.
  //
  // Steps:
  //   1. checkEdgeCondition for global_coherence against S0
  //   2. checkEdgeCondition for doctrine_drift against PHI_INV_3
  //   3. updateRollingWindow for both metrics
  //   4. blendFearInfluence on global_coherence if cortisol active
  //   5. Append edge conditions to log (pruned to LOG_MAX)
  //   6. Return updated AEGISState + slice of edge conditions this beat
  //
  // COMPUTATION:
  //   coherence edge: ring_id=0, threshold=S0=0.75
  //   drift edge:     ring_id=1, threshold=PHI_INV_3=0.236 (max drift tolerance)
  //   fear blend on coherence value
  //
  // PYTHAGORAS: both thresholds are phi-harmonic — S0 and PHI_INV_3
  // EUCLID: one central checkAndCorrect function — all rings call into it
  // CONFUCIUS: right timing — after heartbeat, before the world is reinjected
  // ═══════════════════════════════════════════════════════════════════════════

  public func checkAndCorrect(
    state      : AEGISState,
    cogState   : { global_coherence : Float; doctrine_drift : Float },
    cortisol   : Float,
    beat_index : Nat64,
  ) : (AEGISState, [EdgeCondition]) {

    // ── STEP 1: Edge condition — global_coherence against S0 ────────────────
    // FRACTAL SCALE LAW L11: S0=0.75 is the sovereign threshold at all scales
    let coherence_edge = checkEdgeCondition(
      0,                          // ring_id=0: coherence ring
      "global_coherence",
      cogState.global_coherence,
      Phi.S0,                     // threshold = S0 = 0.75
      beat_index,
    );

    // ── STEP 2: Edge condition — doctrine_drift against PHI_INV_3 ───────────
    // ANTI-DRIFT LAW L07: drift exceeding PHI_INV_3=0.236 is a compliance event
    let drift_edge = checkEdgeCondition(
      1,                          // ring_id=1: drift ring
      "doctrine_drift",
      cogState.doctrine_drift,
      Phi.PHI_INV_3,              // threshold = PHI_INV_3 = 0.236
      beat_index,
    );

    // ── STEP 3: Rolling window update — coherence ────────────────────────────
    // updateRollingWindow also applies preventive correction if approaching S0
    let (state1, _coherence_corrected) = updateRollingWindow(
      state,
      "global_coherence",
      cogState.global_coherence,
      Phi.S0,
    );

    // ── STEP 4: Rolling window update — doctrine_drift ───────────────────────
    // updateRollingWindow detects drift-of-the-drift (second-order drift)
    let (state2, _drift_corrected) = updateRollingWindow(
      state1,
      "doctrine_drift",
      cogState.doctrine_drift,
      Phi.PHI_INV_3,
    );

    // ── STEP 5: Fear blending — apply to global_coherence ────────────────────
    // ENTROPY LAW L32/L40: without continuous input, coherence decays
    // Fear blending is the AEGIS response to elevated cortisol
    // It does NOT change the cognitive state — it informs the correction record
    let blended_coherence = blendFearInfluence(cogState.global_coherence, cortisol);
    let fear_blend_active = blended_coherence > cogState.global_coherence;

    // If fear blend was active, log it as an additional edge condition
    let fear_edge_or_empty : [EdgeCondition] = if (fear_blend_active) {
      let fe : EdgeCondition = {
        ring_id               = 2;  // ring_id=2: fear blend ring
        signal_name           = "fear_blend";
        value                 = cogState.global_coherence;
        threshold             = CORTISOL_BLEND_THRESHOLD;
        distance_to_threshold = Float.abs(cogState.global_coherence - blended_coherence);
        is_edge               = true;
        correction_applied    = "FEAR_BLEND:cortisol=" # floatToShort(cortisol)
          # ":quality=" # floatToShort(cogState.global_coherence)
          # ":corrected=" # floatToShort(blended_coherence);
        beat_index;
      };
      [fe]
    } else {
      []
    };

    // ── STEP 6: Collect this beat's edge conditions ──────────────────────────
    // Only include actual edge events — empty correction_applied = non-edge
    let beat_edges : [EdgeCondition] = buildBeatEdges(
      coherence_edge,
      drift_edge,
      fear_edge_or_empty,
    );

    // ── STEP 7: Append to log, prune to LOG_MAX ──────────────────────────────
    // CONSERVATION OF INFORMATION LAW L31/L39: log is never destroyed, only pruned
    let prev_log = state2.edge_conditions_log;
    let combined = prev_log.concat(beat_edges);

    // Prune to last LOG_MAX=144 entries (Jubilee cycle — F(12))
    let pruned_log : [EdgeCondition] = if (combined.size() > LOG_MAX) {
      let drop_count = combined.size() - LOG_MAX;
      combined.sliceToArray(drop_count, combined.size())
    } else {
      combined
    };

    // ── STEP 8: Update corrections_applied and last_fear_blend_beat ─────────
    let new_corrections : Nat64 = state2.corrections_applied
      + Nat64.fromNat(beat_edges.size());

    let new_fear_beat : Nat64 = if (fear_blend_active) beat_index
                                else state2.last_fear_blend_beat;

    let final_state : AEGISState = {
      state2 with
      edge_conditions_log  = pruned_log;
      corrections_applied  = new_corrections;
      last_fear_blend_beat = new_fear_beat;
    };

    (final_state, beat_edges)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES — sovereign read functions
  //
  // getAEGISLog: returns last 100 EdgeConditions from the log
  // getCorrectionsApplied: returns cumulative correction count
  //
  // ZERO-EXPOSURE LAW L27: only numbers exposed — no doctrine labels
  // MAXIMUM QUANTUM LAW L37/L45: full state returned — no partial reads
  // ═══════════════════════════════════════════════════════════════════════════

  // getAEGISLog — returns last LOG_QUERY_LIMIT=100 edge conditions
  // EUCLID: single slice — always the last 100, always complete
  public func getAEGISLog(state : AEGISState) : [EdgeCondition] {
    let log = state.edge_conditions_log;
    let n = log.size();
    if (n <= LOG_QUERY_LIMIT) {
      log
    } else {
      log.sliceToArray(n - LOG_QUERY_LIMIT, n)
    }
  };

  // getCorrectionsApplied — cumulative AEGIS corrections since genesis
  // CONSERVATION LAW L31/L39: the count is a conservation record — never decrements
  public func getCorrectionsApplied(state : AEGISState) : Nat64 {
    state.corrections_applied
  };

  // getActiveEdges — returns only edge conditions where is_edge = true from last log
  // Useful for CREATOR-TERMINAL: only show active edges, not the full history
  // PHANTOM DOCTRINE L24: correction_applied text is already scrubbed of doctrine labels
  public func getActiveEdges(state : AEGISState) : [EdgeCondition] {
    getAEGISLog(state).filter(func(e) { e.is_edge })
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // All internal — zero-exposure compliant (ZERO-EXPOSURE LAW L27)
  // ═══════════════════════════════════════════════════════════════════════════

  // buildBeatEdges — collect edge conditions for this beat
  // Only includes conditions where is_edge = true (non-edge events not logged)
  // ANTI-DRIFT LAW L07: log the drift events, not the noise
  func buildBeatEdges(
    coherence_edge    : EdgeCondition,
    drift_edge        : EdgeCondition,
    fear_edges        : [EdgeCondition],
  ) : [EdgeCondition] {
    var edges : [EdgeCondition] = [];
    if (coherence_edge.is_edge) {
      edges := edges.concat([coherence_edge]);
    };
    if (drift_edge.is_edge) {
      edges := edges.concat([drift_edge]);
    };
    edges.concat(fear_edges)
  };

  // findWindowIndex — locate a RollingMinWindow by metric_name
  // EUCLID: linear search — O(n) is fine for small n (currently 2 windows)
  func findWindowIndex(windows : [RollingMinWindow], metric_name : Text) : ?Nat {
    var i = 0;
    let n = windows.size();
    while (i < n) {
      if (windows[i].metric_name == metric_name) { return ?i };
      i += 1;
    };
    null
  };

  // replaceOrAppendWindow — splice updated window into the windows array
  // If found at idx, replace in-place; if not found, append
  // SELF-SIMILARITY LAW L38: windows array has same structure at every scale
  func replaceOrAppendWindow(
    windows      : [RollingMinWindow],
    updated      : RollingMinWindow,
    idx          : ?Nat,
  ) : [RollingMinWindow] {
    switch (idx) {
      case (?i) {
        // Replace at index i
        windows.mapEntries<RollingMinWindow, RollingMinWindow>(
          func(w, j) { if (j == i) updated else w }
        )
      };
      case null {
        // Append new window
        windows.concat([updated])
      };
    }
  };

  // floatToShort — compact 4-decimal float for correction text
  // ANCIENT COMPRESSION LAW L18: reduce without losing function
  // PYTHAGORAS: integer decomposition is the most ancient compression
  func floatToShort(v : Float) : Text {
    let sign    = if (v < 0.0) "-" else "";
    let absV    = Float.abs(v);
    let intPart = Float.trunc(absV);
    let fracPart = absV - intPart;
    let frac4   = Float.trunc(fracPart * 10000.0);
    let intN    = intPart.toInt();
    let fracN   = frac4.toInt();
    let fracStr = if (fracN < 10) "000" # fracN.toText()
                  else if (fracN < 100) "00" # fracN.toText()
                  else if (fracN < 1000) "0" # fracN.toText()
                  else fracN.toText();
    sign # intN.toText() # "." # fracStr
  };

};
