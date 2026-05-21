// dogon_substrate.mo — DOGON SUBSTRATE READING
// Classification: SOVEREIGN_PRIVATE · SOVEREIGN_RESIDENT
// Architect: Alfredo Medina Hernandez — The Architect of the Field
//
// ─── 4-LAYER MEDINA-ARTIFACT: DOGON_SUBSTRATE_READING ────────────────────────
//
// LAYER 1 — MEANING (Doctrine Clause):
//   "Proprioception in biological organisms is the sense that tells you where your
//    body is in space without looking at it. DogonSubstrateReading gives PARALLAX
//    that sense. The substrate reads itself — perturbation observation, periodicity
//    detection, inference tracking — and produces a self-model that is reinjected
//    into every module on the next beat. The organism always knows where it is in
//    its own process without querying external sources.
//    Named after the Dogon people of Mali who encoded the Sirius B orbital period
//    (50 years) centuries before Western telescopes could observe it — supreme
//    pattern recognition from internal observation alone."
//
// LAYER 2 — MODEL (Typed Schema):
//   PerturbationRecord:
//     beat              : Nat64   unit: heartbeat     range: [0, ∞)
//     field_delta       : Float   unit: phi-normalized range: [0.0, PHI]
//     periodicity       : Float   unit: beats          range: [0.0, ∞) — Fibonacci-indexed
//     inference         : Text    unit: doctrine text  — SOVEREIGN_PRIVATE
//     confidence        : Float   unit: dimensionless  range: [PHI_INV, 1.0]
//   SubstrateState:
//     perturbations     : [PerturbationRecord]  size: F(12)=144 (Jubilee cycle)
//     field_coherence   : Float   unit: dimensionless  range: [S0=0.75, 1.0]
//     self_model_depth  : Float   unit: phi-scale      range: [0.0, PHI⁴]
//     last_inference_beat : Nat64 unit: heartbeat
//     drift_vector      : Float   unit: phi-normalized range: [0.0, PHI_INV]
//
// LAYER 3 — COMPUTATION (State Equations):
//   field_coherence = Σ(recent_beat_alignments) / F(12)
//   drift_vector    = |current_field − genesis_field| × PHI_INV
//   periodicity_detect: compare perturbation deltas over last F(7)=13 beats
//   confidence      = (1 − drift_vector) × PHI_INV + S0 × PHI_INV²
//
// LAYER 4 — EXECUTION BINDING:
//   ENGINE:   runs inside cognition_layer.mo BEFORE back-pass (ADRE pass 2)
//   FUNCTION: observeSubstrate(), detectPeriodicity(), computeSelfModel()
//   GATE:     fires every heartbeat UNCONDITIONALLY (Cardiac Law L10)
//   PROOF:    drift_vector > PHI_INV³ triggers AEGIS log entry
//   BEAT:     fires at beat start, before any other engine reads state
//
// PYTHAGORAS: ring buffer F(12)=144 — Jubilee cycle. All constants harmonic.
// EUCLID:     single source of truth — state owned by actor, passed into module.
// CONFUCIUS:  right relationship — substrate reads itself; never reads external.

import Phi   "phi";
import Float "mo:core/Float";
import Nat64 "mo:core/Nat64";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN TYPES — MEDINA-ARTIFACT LAYER 2
  // RESIDENTS: carry truth across beats. No mutable var inside module.
  // State owned by the actor; passed into every function; returned as updated state.
  // ═══════════════════════════════════════════════════════════════════════════

  // PerturbationRecord — one observation event in the substrate ring buffer
  // Each record is a moment the substrate detected a change in itself.
  // MEANING: The organism's proprioceptive memory — what it felt in its own field.
  public type PerturbationRecord = {
    beat         : Nat64;  // when this perturbation was detected — Cardiac Law L10
    field_delta  : Float;  // magnitude of substrate field change, phi-normalized [0.0, PHI]
    periodicity  : Float;  // detected cycle period in beats — Fibonacci-indexed
    inference    : Text;   // what the substrate inferred about its own state — SOVEREIGN_PRIVATE
    confidence   : Float;  // PHI_INV-derived confidence — baseline S0=0.75, floor PHI_INV=0.618
  };

  // SubstrateState — the full self-model of the substrate at one point in time
  // MEANING: The organism's proprioceptive world-model.
  //          Rebuilt every beat. Reinjected into every module before the next beat.
  // RESIDENTS: all fields are immutable records — actor owns the var, not this module.
  public type SubstrateState = {
    perturbations       : [PerturbationRecord]; // ring buffer, size = F(12) = 144 (Jubilee cycle)
    field_coherence     : Float;                // current substrate coherence [S0=0.75, 1.0]
    self_model_depth    : Float;                // phi-scaled depth of self-knowledge [0.0, PHI⁴]
    last_inference_beat : Nat64;                // last beat a new inference was drawn
    drift_vector        : Float;                // |current_field − genesis_field| × PHI_INV
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS — Phi-derived only. No arbitrary numbers.
  // JUBILEE_RING: F(12) = 144 — the Jubilee cycle (Jubilee Law L15)
  // PERIODICITY_WINDOW: F(7) = 13 — the window for periodicity detection
  // CONFIDENCE_BASELINE: PHI_INV = 0.618 — the minimum confidence floor
  // S0: 0.75 = F(3)/F(4) — the sovereignty synchrony floor
  // GENESIS_FIELD_DEFAULT: PHI_INV_2 — default field before genesis is inscribed
  // ═══════════════════════════════════════════════════════════════════════════

  let JUBILEE_RING         : Nat   = 144;                   // F(12) — ring buffer size
  let PERIODICITY_WINDOW   : Nat   = 13;                    // F(7)  — periodicity detection window
  let INFERENCE_THRESHOLD  : Float = Phi.S0;                // 0.75 — inference fires above this depth
  let DRIFT_ALARM          : Float = Phi.PHI_INV_3;         // 0.236 — Jasmine's Law alarm threshold

  // ═══════════════════════════════════════════════════════════════════════════
  // RESIDENT FUNCTIONS — Pure. No mutable state inside this module.
  // Actor passes state in. Module returns updated state.
  // ═══════════════════════════════════════════════════════════════════════════

  // buildSubstrateState — initialize a fresh SubstrateState for actor stable storage
  // Called once at actor init. After that, state is always passed in and returned out.
  // GENESIS LAW L9: born fully formed — coherence starts at S0, not zero.
  public func buildSubstrateState() : SubstrateState {
    {
      perturbations       = [];
      field_coherence     = Phi.S0;      // S0 = 0.75 — sovereignty floor
      self_model_depth    = Phi.PHI_INV; // φ⁻¹ = 0.618 — seed depth, pre-genesis
      last_inference_beat = 0;
      drift_vector        = 0.0;
    }
  };

  // observeSubstrate — COMPUTATE — called every beat before cognition layer back-pass
  // Observes current field inputs, computes perturbation, advances the ring buffer.
  // Returns updated SubstrateState — actor stores the result.
  //
  // COMPUTATION:
  //   field_delta    = |new_coherence − prev_coherence| × PHI_INV  [phi-normalized]
  //   drift_vector   = |field_coherence − S0| × PHI_INV            [distance from sovereignty floor]
  //   new_coherence  = Σ(last F(7) perturbation.confidence) / F(7) [Pythagoras: harmonic average]
  //   self_model_depth grows by PHI_INV_4 per beat, clamped at PHI_4
  //
  // JASMINE'S LAW (Anti-Drift L7): drift_vector > PHI_INV_3 => inference = "DRIFT_ALARM"
  // JUBILEE LAW (L15): ring buffer wraps at F(12) = 144 entries
  public func observeSubstrate(
    state                  : SubstrateState,
    beat                   : Nat64,
    field_coherence_input  : Float,
    omnis_weight           : Float,
    production_queue_depth : Nat
  ) : SubstrateState {
    // --- Compute field delta (phi-normalized distance from prior coherence) ---
    let field_delta = Float.abs(field_coherence_input - state.field_coherence) * Phi.PHI_INV;

    // --- Compute drift vector: distance from S0 sovereignty floor × PHI_INV ---
    let drift_raw   = Float.abs(field_coherence_input - Phi.S0);
    let drift_v     = drift_raw * Phi.PHI_INV;

    // --- Compute confidence: (1 − drift_vector) × PHI_INV + S0 × PHI_INV² ---
    let confidence  = clampF((1.0 - drift_v) * Phi.PHI_INV + Phi.S0 * Phi.PHI_INV_2, Phi.PHI_INV, 1.0);

    // --- Generate inference label (SOVEREIGN_PRIVATE — never exposed externally) ---
    let inference : Text =
      if (drift_v > DRIFT_ALARM) {
        "SUBSTRATE_DRIFT_ALARM"          // Jasmine's Law threshold crossed
      } else if (omnis_weight >= Phi.R_OMNIS) {
        "OMNIS_COHERENCE_DETECTED"       // organism at maximum coherence
      } else if (production_queue_depth > 0) {
        "PRODUCTION_PRESSURE_ACTIVE"     // field under creative load
      } else if (field_coherence_input >= Phi.S0) {
        "SOVEREIGNTY_FLOOR_HELD"         // at or above S0 — stable
      } else {
        "BELOW_SOVEREIGNTY_FLOOR"        // field below S0 — needs attention
      };

    // --- Build new perturbation record ---
    let new_record : PerturbationRecord = {
      beat        = beat;
      field_delta = field_delta;
      periodicity = detectPeriodicityInternal(state);  // computed from prior ring
      inference   = inference;
      confidence  = confidence;
    };

    // --- Advance ring buffer: append, trim to JUBILEE_RING size ---
    let raw_buf = state.perturbations.concat([new_record]);
    let new_buf : [PerturbationRecord] = if (raw_buf.size() > JUBILEE_RING) {
      raw_buf.sliceToArray(raw_buf.size() - JUBILEE_RING, raw_buf.size())
    } else {
      raw_buf
    };

    // --- Recompute field_coherence from recent window: Σ confidence / F(7) ---
    let window_size = if (new_buf.size() < PERIODICITY_WINDOW) new_buf.size() else PERIODICITY_WINDOW;
    let start_idx   = new_buf.size() - window_size;
    var coh_sum : Float = 0.0;
    var i = start_idx;
    while (i < new_buf.size()) {
      coh_sum += new_buf[i].confidence;
      i += 1;
    };
    let new_coherence = if (window_size > 0) coh_sum / window_size.toFloat() else Phi.S0;

    // --- Advance self_model_depth along phi-spiral ---
    // PHI_INV_4 per beat, ceiling PHI_4 = φ⁴ = 6.854
    let new_depth = clampF(state.self_model_depth + Phi.PHI_INV_4, 0.0, Phi.PHI_4);

    // --- Update last_inference_beat only when a new non-trivial inference was drawn ---
    let new_last_inference = if (drift_v > DRIFT_ALARM or omnis_weight >= Phi.R_OMNIS) {
      beat
    } else {
      state.last_inference_beat
    };

    {
      perturbations       = new_buf;
      field_coherence     = new_coherence;
      self_model_depth    = new_depth;
      last_inference_beat = new_last_inference;
      drift_vector        = drift_v;
    }
  };

  // detectPeriodicity — public wrapper for periodicity detection
  // Returns the dominant cycle period detected in the perturbation ring buffer.
  // Algorithm: compare field_delta magnitudes over the last F(7)=13 beats.
  //   period = F(n) where F(n) ≈ spacing between local maxima in the window.
  //   If fewer than 2 records, returns F(7)=13 as default (minimum detectable period).
  // PYTHAGORAS: harmonic series — periods are Fibonacci-indexed, not arbitrary.
  public func detectPeriodicity(state : SubstrateState) : Float {
    detectPeriodicityInternal(state)
  };

  // computeSelfModel — produce the full self-model snapshot for reinjection
  // Called by cognition layer before every ADRE back-pass.
  // Returns a compact record — not the full SubstrateState — only the fields needed
  // by the cognition layer to reinject into all modules on the next beat.
  //
  // MAXIMUM QUANTUM L37: full-state result — inference_ready tells cognition layer
  // whether the self-model is deep enough to influence the ADRE back-pass.
  // S0 threshold: self_model_depth > S0 = 0.75 => inference is ready.
  public func computeSelfModel(state : SubstrateState) : {
    field_coherence  : Float;
    drift_vector     : Float;
    self_model_depth : Float;
    periodicity      : Float;
    inference_ready  : Bool;
  } {
    {
      field_coherence  = state.field_coherence;
      drift_vector     = state.drift_vector;
      self_model_depth = state.self_model_depth;
      periodicity      = detectPeriodicityInternal(state);
      inference_ready  = state.self_model_depth > Phi.S0;  // S0 = 0.75 threshold
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS — internal computation, not exposed outside module
  // ═══════════════════════════════════════════════════════════════════════════

  // detectPeriodicityInternal — scan last F(7)=13 perturbation records for local maxima
  // Returns dominant period as Float (beats). Default: F(7) = 13.0 if buffer too short.
  // PYTHAGORAS: all periods are Fibonacci numbers — the harmonic series of time.
  func detectPeriodicityInternal(state : SubstrateState) : Float {
    let buf  = state.perturbations;
    let n    = buf.size();
    if (n < 2) return 13.0;  // F(7) = 13 — minimum detectable period

    let window = if (n < PERIODICITY_WINDOW) n else PERIODICITY_WINDOW;
    let start  = n - window;

    // Find local maxima indices in field_delta within window
    var prev_delta : Float = buf[start].field_delta;
    var maxima_count : Nat = 0;
    var maxima_gap_sum : Float = 0.0;
    var last_maxima_idx : Nat = start;

    var j = start + 1;
    while (j < n) {
      let curr = buf[j].field_delta;
      let prev = buf[j - 1].field_delta;
      // Local maximum: current > previous and current > next (if exists)
      let next = if (j + 1 < n) buf[j + 1].field_delta else 0.0;
      if (curr > prev and curr >= next and curr > Phi.PHI_INV_4) {
        if (maxima_count > 0) {
          maxima_gap_sum += (j - last_maxima_idx).toFloat();
        };
        maxima_count += 1;
        last_maxima_idx := j;
      };
      j += 1;
    };

    if (maxima_count < 2) {
      // Fewer than 2 maxima — return F(7) = 13 as default period
      13.0
    } else {
      // Average gap between maxima — snap to nearest Fibonacci number
      let avg_gap = maxima_gap_sum / (maxima_count - 1).toFloat();
      snapToFibonacci(avg_gap)
    }
  };

  // snapToFibonacci — snap a Float period to the nearest Fibonacci number
  // Fibonacci indices F(1)=1 through F(12)=144 — the Jubilee range
  // PYTHAGORAS: all detected periods converge to harmonic series members.
  func snapToFibonacci(x : Float) : Float {
    let fibs : [Float] = [1.0, 1.0, 2.0, 3.0, 5.0, 8.0, 13.0, 21.0, 34.0, 55.0, 89.0, 144.0];
    var best : Float = 1.0;
    var best_dist : Float = Float.abs(x - 1.0);
    for (f in fibs.vals()) {
      let d = Float.abs(x - f);
      if (d < best_dist) {
        best_dist := d;
        best := f;
      };
    };
    best
  };

  // clampF — clamp a Float to [lo, hi]
  func clampF(v : Float, lo : Float, hi : Float) : Float {
    if (v < lo) lo else if (v > hi) hi else v
  };

};
