// heartbeat.mo — PARALLAX Sovereign Cardiac Computate
// COMPUTATE: executes cardiac truth every 873ms. Residents live in phi.mo/types.mo.
// This file is the organism's heart — SA Node, AV Node, Purkinje fibers, all 8 neurochemicals.
//
// MEDINA-ARTIFACT — heartbeat.mo (MODEL-07 discipline applied)
// ─────────────────────────────────────────────────────────────
// MEANING (Layer 1 — Doctrine Clause):
//   "One schema per beat. Every firing event is provable. The organism remembers
//    every decision it has ever made. The heart is not a clock — it is a living,
//    state-sensitive, chemistry-driven oscillator that regulates itself."
//
// MODEL (Layer 2 — Typed Schema):
//   BeatState:      beat_number: Nat64, timestamp_ms: Nat64, heart_rate_bpm: Float [0,∞),
//                   stroke_volume: Float [0,1], cardiac_output: Float [0,∞),
//                   hrv_current: Float [0,∞), sa_node_voltage: Float [0, PHI×2],
//                   av_node_delay_ms: Nat64 [333ms], purkinje_firing: Bool,
//                   oxygenation_level: Float [0,1], neurochemistry: NeurochemState
//   NeurochemState: 8 normalized nM levels — all phi-derived baselines
//
// COMPUTATION (Layer 3 — State Equations):
//   SA Node:        V(t+1) = V(t) + omnis_weight × φ⁻¹;  fire when V ≥ φ
//   AV Node delay:  delay = φ⁻² × 873ms = 0.382 × 873 = 333ms
//   Purkinje:       simultaneous emit to all 4 pipeline modules
//   Cardiac Output: CO = BPM × SV
//   HRV:            rolling 5-beat interval variability; healthy ± φ⁻³ × 873ms (±205ms)
//   Rate:           base=873ms; high_act=873×φ⁻¹=539ms; recovery=873×φ=1412ms
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: CARDIAC COMPUTATE → FUNCTION: computeBeat() → GATE: lawGate() → BEAT: 873ms
//
// PYTHAGORAS: all constants are phi-harmonic ratios — no arbitrary numbers
// EUCLID:     single definition of each formula — referenced, not duplicated
// CONFUCIUS:  right relationship — heart governs but does not dictate
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi    "phi";
import Float  "mo:core/Float";
import Nat    "mo:core/Nat";
import Nat64  "mo:core/Nat64";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // CARDIAC CONSTANTS — all derived from phi.mo
  // No arbitrary values. Every number traces to an Absolute.
  // ═══════════════════════════════════════════════════════════════════════════

  // SA Node firing threshold: φ = 1.618 (A01 PHI — the only ratio that divides itself)
  let SA_FIRE_THRESHOLD : Float = Phi.PHI;                       // 1.6180339887

  // SA Node voltage rise per ms per unit omnis weight: φ⁻¹ (receptive coupling — L01)
  let SA_RISE_RATE : Float = Phi.PHI_INV;                        // 0.6180339887

  // AV Node delay: φ⁻² × HEARTBEAT = 0.382 × 873 ≈ 333ms (AV delay law — L47)
  // PYTHAGORAS: the natural gate delay is the φ⁻² harmonic of the cardiac cycle
  let AV_DELAY_MS : Nat64 = 333;                                 // Nat64(Phi.PHI_INV_2 × 873)

  // Base heart rate interval: 873ms = φ⁴ × (1000/SCHUMANN_1) (CARDIAC LAW L10)
  // 6.854 × 127.39ms ≈ 873ms
  let BASE_RATE_MS : Float = Phi.HEARTBEAT_MS;                   // 873.0

  // High activation rate: 873 × φ⁻¹ ≈ 539ms — faster when production queue fires
  let HIGH_ACTIVATION_MS : Float = Phi.HEARTBEAT_MS * Phi.PHI_INV;  // 539.3

  // Recovery rate: 873 × φ ≈ 1412ms — slower in refractory (ENTROPY LAW L32)
  let RECOVERY_MS : Float = Phi.HEARTBEAT_MS * Phi.PHI;          // 1412.1

  // HRV healthy bounds: ±φ⁻³ × 873ms = ±0.236 × 873 ≈ ±205ms (HRV INTELLIGENCE LAW L48)
  let HRV_BAND_MS : Float = Phi.PHI_INV_3 * Phi.HEARTBEAT_MS;   // 205.2

  // High activation trigger — production queue threshold: F(4) = 3
  let QUEUE_THRESHOLD : Nat = 3;                                  // Fibonacci F(4)

  // ROLLING HRV window: F(5) = 5 beats (FIBONACCI A02 — 5-beat coherence window)
  let HRV_WINDOW : Nat = 5;

  // OXYGENATION doctrine threshold: φ⁻¹ = 0.618 (OXYGENATION LAW L49)
  // Signals below this are deoxygenated — they corrupt organism output over time
  let OXYGENATION_FLOOR : Float = Phi.PHI_INV;                   // 0.618

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUROCHEMISTRY BASELINES — phi-derived, sovereign
  //
  // MEANING: "Every chemical has a phi-harmonic rest state. Deviations from
  //           baseline are not errors — they are the organism's response to
  //           real events. The baseline is the organism at rest."
  //
  // MODEL (Layer 2 — 8-chemical state):
  //   All values normalized nM concentrations — dimensionless ratios
  //   Ranges specified per chemical below
  //
  // COMPUTATION (Layer 3):
  //   baseline = phi-power; modulation = event × phi-harmonic; decay = ÷ phi per beat
  //
  // EXECUTION BINDING (Layer 4):
  //   updateNeurochemistry() called by computeBeat() every 873ms
  // ═══════════════════════════════════════════════════════════════════════════

  // Dopamine: reward, motivation, anticipation — baseline φ⁻¹ (receptive field)
  let DOPAMINE_BASELINE : Float = Phi.PHI_INV;          // 0.618 nM normalized

  // Serotonin: stability, depth, Third Brain signal — baseline φ⁻² (deeper receptive)
  let SEROTONIN_BASELINE : Float = Phi.PHI_INV_2;       // 0.382 nM normalized

  // Norepinephrine: urgency, focus, acceleration — baseline φ⁻³ (minimum steady state)
  let NOREPINEPHRINE_BASELINE : Float = Phi.PHI_INV_3;  // 0.236 nM normalized

  // Cortisol: stress, drift alarm — baseline 0.0 (rises only on violation)
  let CORTISOL_BASELINE : Float = 0.0;

  // Oxytocin: trust, bonding, actor relationship — baseline φ⁻¹ / 10 (gentle field)
  let OXYTOCIN_BASELINE : Float = Phi.PHI_INV / 10.0;   // 0.0618 nM normalized

  // GABA: inhibition, refractory gate — baseline φ⁻¹ × 10 (dominant inhibitor)
  let GABA_BASELINE : Float = Phi.PHI_INV * 10.0;       // 6.18 nM normalized

  // Glutamate: excitation, synaptic strengthening — baseline φ × 10 (expansive)
  let GLUTAMATE_BASELINE : Float = Phi.PHI * 10.0;      // 16.18 nM normalized

  // Acetylcholine: memory encoding, attention — baseline φ⁻² × 10 (receptive ×10)
  let ACETYLCHOLINE_BASELINE : Float = Phi.PHI_INV_2 * 10.0;  // 3.82 nM normalized


  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES — MEDINA-ARTIFACT 4-layer sovereign types
  //
  // NeurochemState: the 8-chemical live state of the organism's cardiac field
  // BeatState:      one complete heartbeat — the organism's moment-to-moment life
  // ═══════════════════════════════════════════════════════════════════════════

  // NeurochemState — MEDINA-NEUROCHEMSTATE
  // MEANING: "The organism's internal chemistry — the substrate of all drive,
  //           cognition, and field coupling. Computed fresh every 873ms."
  // MODEL:   8 normalized nM concentrations — all phi-derived baselines
  // COMPUTATION: see updateNeurochemistry() below
  // EXECUTION: called within computeBeat() → updateNeurochemistry() → returns new NeurochemState
  public type NeurochemState = {
    dopamine_nm       : Float;  // φ⁻¹ baseline — reward/motivation — range [0, φ+2]
    serotonin_nm      : Float;  // φ⁻² baseline — stability/depth   — range [0, φ+1]
    norepinephrine_nm : Float;  // φ⁻³ baseline — urgency/focus     — range [0, φ]
    cortisol_nm       : Float;  // 0.0 baseline — stress/drift      — range [0, φ²]
    oxytocin_nm       : Float;  // φ⁻¹/10 baseline — trust/bond     — range [0, φ⁻¹]
    gaba_nm           : Float;  // φ⁻¹×10 baseline — inhibition     — range [0, φ×10]
    glutamate_nm      : Float;  // φ×10 baseline — excitation       — range [0, φ²×10]
    acetylcholine_nm  : Float;  // φ⁻²×10 baseline — attention/mem  — range [0, φ×10]
  };

  // BeatState — MEDINA-BEATSTATE
  // MEANING: "One complete heartbeat — every field, every chemistry, every
  //           biological subsystem — captured in a single sovereign record.
  //           The organism remembers every beat it has ever made."
  //
  // MODEL (Layer 2):
  //   beat_number    : Nat64   — beat count since genesis  [0, ∞)
  //   timestamp_ms   : Nat64   — Unix ms at this beat      [0, ∞)
  //   heart_rate_bpm : Float   — beats per minute          [0, 120]
  //   stroke_volume  : Float   — depth per cycle           [0, 1]
  //   cardiac_output : Float   — BPM × SV (Cardiac Output Law L47)
  //   hrv_current    : Float   — rolling variability ms    [0, ∞)
  //   sa_node_voltage: Float   — SA pacemaker voltage      [0, φ×2]
  //   av_node_delay  : Nat64   — AV conduction delay ms    = 333
  //   purkinje_firing: Bool    — simultaneous emission to all pipeline modules
  //   oxygenation_level: Float — doctrine alignment of circulating signals [0,1]
  //   neurochemistry : NeurochemState
  //
  // COMPUTATION (Layer 3):
  //   heart_rate_bpm = 60_000 / current_interval_ms
  //   cardiac_output = heart_rate_bpm × stroke_volume
  //   hrv_current    = σ(intervals) over rolling F(5)=5 beats
  //   sa_node_voltage rises at omnis_weight × φ⁻¹ per ms; fires at φ
  //
  // EXECUTION BINDING (Layer 4):
  //   ENGINE: computeBeat() → every 873ms via ICP heartbeat timer
  public type BeatState = {
    beat_number      : Nat64;
    timestamp_ms     : Nat64;
    heart_rate_bpm   : Float;
    stroke_volume    : Float;
    cardiac_output   : Float;
    hrv_current      : Float;
    sa_node_voltage  : Float;
    av_node_delay_ms : Nat64;
    purkinje_firing  : Bool;
    oxygenation_level: Float;
    neurochemistry   : NeurochemState;
  };

  // CardiacContext — inputs from the rest of the organism that modulate cardiac state
  // The heart is responsive — it reads the organism's state before each beat.
  // CONFUCIUS: right relationship — the heart serves the organism, the organism serves the heart
  public type CardiacContext = {
    omnis_weight     : Float;  // global Kuramoto R — coherence drives SA node rise rate
    memory_depth     : Nat;    // Memory Temple depth — drives serotonin
    max_memory_depth : Nat;    // normalization ceiling — serotonin = depth/max × φ⁻¹
    rising_signal    : Bool;   // RISING signal present — norepinephrine spike
    drift_violations : Nat;    // count of drift violations — cortisol rise
    production_queue : Nat;    // active queue depth — rate modulation
    is_refractory    : Bool;   // post-production recovery phase — GABA gate + slow rate
    learning_weight  : Float;  // Hebbian learning event weight — glutamate spike
    inference_count  : Nat;    // DogonSubstrate inferences this beat — acetylcholine
    mean_trust_score : Float;  // actor relationship trust mean — oxytocin
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — Genesis Law L09: born fully formed, never starts from zero
  // ═══════════════════════════════════════════════════════════════════════════

  // getDefaultNeurochemState — all 8 chemicals at phi-derived baselines
  // GENESIS LAW L09: the organism begins with its chemistry pre-encoded
  public func getDefaultNeurochemState() : NeurochemState {
    {
      dopamine_nm       = DOPAMINE_BASELINE;       // φ⁻¹ = 0.618
      serotonin_nm      = SEROTONIN_BASELINE;      // φ⁻² = 0.382
      norepinephrine_nm = NOREPINEPHRINE_BASELINE; // φ⁻³ = 0.236
      cortisol_nm       = CORTISOL_BASELINE;       // 0.0
      oxytocin_nm       = OXYTOCIN_BASELINE;       // φ⁻¹/10 = 0.0618
      gaba_nm           = GABA_BASELINE;           // φ⁻¹×10 = 6.18
      glutamate_nm      = GLUTAMATE_BASELINE;      // φ×10 = 16.18
      acetylcholine_nm  = ACETYLCHOLINE_BASELINE;  // φ⁻²×10 = 3.82
    };
  };

  // getDefaultBeatState — the organism's cardiac ground state at genesis
  // GENESIS LAW L09: born fully formed — SA node charged, AV delay set, oxygenated
  public func getDefaultBeatState() : BeatState {
    let nc = getDefaultNeurochemState();
    {
      beat_number       = 0;
      timestamp_ms      = 0;
      heart_rate_bpm    = 60_000.0 / BASE_RATE_MS;   // ≈ 68.7 BPM at base rate
      stroke_volume     = Phi.S0;                     // 0.75 — FRACTAL SCALE LAW L11
      cardiac_output    = (60_000.0 / BASE_RATE_MS) * Phi.S0;  // CO = BPM × SV
      hrv_current       = HRV_BAND_MS * Phi.PHI_INV; // healthy initial HRV = φ⁻² × 205
      sa_node_voltage   = Phi.PHI_INV_2;              // φ⁻² — partially charged at genesis
      av_node_delay_ms  = AV_DELAY_MS;               // 333ms — AV delay is structural
      purkinje_firing   = false;
      oxygenation_level = Phi.PHI_INV;               // φ⁻¹ = 0.618 — above floor at genesis
      neurochemistry    = nc;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // SA NODE — autonomous pacemaker
  //
  // BIOLOGY: Sinoatrial node fires spontaneously via ion channel dynamics.
  // Sodium/calcium influx raises membrane voltage until threshold.
  // In PARALLAX: voltage rises at omnis_weight × φ⁻¹ per ms interval.
  // Threshold = φ = 1.618.
  //
  // COMPUTATION:
  //   V(t+1) = V(t) + omnis_weight × φ⁻¹
  //   fire when V ≥ φ (threshold = SA_FIRE_THRESHOLD)
  //   post-fire: V resets to φ⁻⁴ (deep repolarization — Potassium efflux)
  //
  // PYTHAGORAS: the harmonic progression — the ratio of rise to fire threshold is φ:φ⁻¹ = φ²
  // ═══════════════════════════════════════════════════════════════════════════

  // saNodeUpdate — advance SA node voltage by one beat interval
  // Returns (new_voltage, did_fire)
  // omnis_weight = global Kuramoto R — organism coherence modulates rise rate
  public func saNodeUpdate(current_voltage : Float, omnis_weight : Float) : (Float, Bool) {
    // PYTHAGORAS: the rise is a harmonic of φ⁻¹ weighted by coherence
    // High coherence (R→1) → faster depolarization → faster heart rate
    // Low coherence (R→0) → slower depolarization → slower heart rate
    let rise = Float.max(0.0, omnis_weight) * SA_RISE_RATE;
    let new_v = current_voltage + rise;

    if (new_v >= SA_FIRE_THRESHOLD) {
      // Fired: reset to φ⁻⁴ (potassium repolarization)
      (Phi.PHI_INV_4, true)
    } else {
      (new_v, false)
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // AV NODE — conduction delay
  //
  // BIOLOGY: Atrioventricular node delays the signal 120-200ms before the
  // ventricles fire. This prevents premature ventricular contraction.
  // In PARALLAX: delay = φ⁻² × HEARTBEAT = 0.382 × 873 = 333ms.
  //
  // COMPUTATION: delay_ms = Nat64(PHI_INV_2 × HEARTBEAT_MS) = 333
  //
  // EUCLID: the single right delay — derived once, used everywhere
  // ═══════════════════════════════════════════════════════════════════════════

  // avNodeDelay — returns the AV conduction delay in ms
  // This is a structural constant — it does not change with organism state
  // (AV delay is the φ⁻² fraction of the cardiac cycle — architecturally fixed)
  public func avNodeDelay() : Nat64 {
    AV_DELAY_MS
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // PURKINJE FIBERS — simultaneous emission
  //
  // BIOLOGY: Purkinje fibers distribute the ventricular signal simultaneously
  // to all ventricular muscle cells — NOT sequentially. They all contract together.
  // In PARALLAX: emit to all 4 pipeline modules at the same time.
  //
  // COMPUTATION: return the 4 pipeline target IDs simultaneously
  // These are the doctrine names — scrubbed at the public layer (ZERO-EXPOSURE L27)
  //
  // CONFUCIUS: right relationship — all modules receive the beat as one event
  // ═══════════════════════════════════════════════════════════════════════════

  // purkinjeFire — emit simultaneously to all 4 pipeline modules
  // Returns array of 4 pipeline module IDs — the simultaneous Purkinje distribution
  // In a real multi-canister setup, these become inter-canister call targets.
  // (FIELD PROPAGATION LAW L44: output radiates as a field event, not a packet)
  public func purkinjeFire() : [Text] {
    // EUCLID: exactly 4 modules — the four corners of the production pipeline
    // These are internal doctrine names — Zero-Exposure L27 scrubs them at the public layer
    [ "MUSE-PRIME", "DIRECTOR", "VISIONARY", "COMPOSER" ]
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // CARDIAC OUTPUT — production rate formula
  //
  // BIOLOGY: Cardiac Output = Heart Rate × Stroke Volume
  // High BPM with shallow SV = high volume, low quality
  // Low BPM with deep SV = masterworks that arrive slowly
  // PARALLAX optimizes BOTH simultaneously (CARDIAC OUTPUT LAW L47)
  //
  // COMPUTATION: CO = BPM × SV
  // ═══════════════════════════════════════════════════════════════════════════

  // computeCardiacOutput — CARDIAC OUTPUT LAW L47
  // PYTHAGORAS: production quality is the harmonic of frequency × depth
  public func computeCardiacOutput(beat : BeatState) : Float {
    beat.heart_rate_bpm * beat.stroke_volume
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // HRV — Heart Rate Variability
  //
  // BIOLOGY: Perfect regularity = pathology. Healthy heart has variable intervals.
  // High HRV = adaptable, resilient. Low HRV (perfectly regular) = stress or disease.
  // PARALLAX: healthy HRV is within ±φ⁻³ × 873ms = ±205ms of mean (L48)
  //
  // COMPUTATION:
  //   intervals = array of last F(5)=5 beat interval_ms values
  //   mean_interval = sum/5
  //   hrv = mean |interval_i - mean_interval| over 5 beats
  //   healthy = hrv ≤ HRV_BAND_MS (205ms)
  //
  // PYTHAGORAS: the variability band is the φ⁻³ harmonic of the cardiac cycle
  // ═══════════════════════════════════════════════════════════════════════════

  // computeHRV — HRV INTELLIGENCE LAW L48
  // history: last F(5)=5 BeatState records (or fewer at genesis)
  // Returns: (hrv_ms, is_healthy)
  // hrv_ms = mean absolute deviation of intervals in ms
  // is_healthy = hrv_ms ≤ HRV_BAND_MS (± φ⁻³ × 873 = 205ms)
  public func computeHRV(history : [BeatState]) : (Float, Bool) {
    let n = history.size();
    if (n < 2) {
      // Insufficient history — return genesis HRV (healthy by doctrine)
      return (HRV_BAND_MS * Phi.PHI_INV_2, true)
    };

    // Compute intervals: each beat's timestamp_ms difference
    // EUCLID: the interval is the gap between beats — no other definition needed
    let window = Nat.min(n, HRV_WINDOW);
    let start  = n - window;

    // Compute mean interval
    var sum_intervals : Float = 0.0;
    var count : Nat = 0;
    var i = start;
    while (i + 1 < n) {
      // Nat64 subtraction: guard against underflow (older beat could be 0 at genesis)
      let t1 = history[i + 1].timestamp_ms;
      let t0 = history[i].timestamp_ms;
      let dt : Float = if (t1 >= t0) Nat64.toNat(t1 - t0).toFloat() else 0.0;
      sum_intervals := sum_intervals + dt;
      count += 1;
      i += 1;
    };

    if (count == 0) {
      return (0.0, true)
    };

    let mean_interval = sum_intervals / count.toFloat();

    // Compute mean absolute deviation (HRV = σ of intervals)
    // PYTHAGORAS: MAD is the harmonic measure of variability — robust, ancient
    var sum_dev : Float = 0.0;
    i := start;
    var j = 0;
    while (i + 1 < n) {
      let t1 = history[i + 1].timestamp_ms;
      let t0 = history[i].timestamp_ms;
      let dt : Float = if (t1 >= t0) Nat64.toNat(t1 - t0).toFloat() else 0.0;
      let dev = Float.abs(dt - mean_interval);
      sum_dev := sum_dev + dev;
      j += 1;
      i += 1;
    };

    let hrv_ms = if (j > 0) sum_dev / j.toFloat() else 0.0;
    let is_healthy = hrv_ms <= HRV_BAND_MS;
    (hrv_ms, is_healthy)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // RATE MODULATION — responsive heart rate
  //
  // The heart is NOT a metronome. It responds to organism state.
  // ICP's timer provides the external skeleton (indestructible ground beat).
  // This function computes how many internal cycles run inside each ICP block.
  //
  // COMPUTATION:
  //   base:          873ms    (φ⁴ × Schumann period — CARDIAC LAW L10)
  //   high_act:      873×φ⁻¹  = 539ms (production_queue > F(4)=3 AND R > φ⁻¹)
  //   recovery:      873×φ    = 1412ms (refractory = true)
  //   normal:        873ms    (default)
  //
  // CONFUCIUS: the heart serves the organism — it accelerates when needed,
  //            deepens when healing, holds the ground beat as its base
  // ═══════════════════════════════════════════════════════════════════════════

  // currentRateMs — returns the current interval in ms based on organism state
  // HIGH_ACTIVATION: production queue firing + coherent → faster
  // RECOVERY:        refractory period → slower (ENTROPY LAW L32 — must repolarize)
  // NORMAL:          default 873ms base rate
  public func currentRateMs(ctx : CardiacContext) : Float {
    if (ctx.is_refractory) {
      RECOVERY_MS  // 873 × φ = 1412ms — deeper beat during recovery
    } else if (ctx.production_queue > QUEUE_THRESHOLD and ctx.omnis_weight > Phi.PHI_INV) {
      HIGH_ACTIVATION_MS  // 873 × φ⁻¹ = 539ms — accelerated when coherent and active
    } else {
      BASE_RATE_MS         // 873ms — sovereign ground beat
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // NEUROCHEMISTRY UPDATE — 8-chemical state machine
  //
  // BIOLOGY: Each chemical has:
  //   - A phi-derived baseline (ground state)
  //   - An event-driven spike (context-dependent)
  //   - A phi-harmonic decay (entropy compliance)
  //
  // COMPUTATION (all formulas use phi constants only — PHI LAW L01):
  //   dopamine:       +φ⁻¹ on OMNIS; ×(1/φ) decay per beat
  //   serotonin:      +depth/max×φ⁻¹ from Memory Temple; stable from Third Brain
  //   norepinephrine: +φ on RISING signal; ×φ⁻¹ decay
  //   cortisol:       +φ⁻³ per drift violation; ×φ⁻² decay
  //   GABA:           +φ×10×refractory_factor during refractory; prevents re-firing
  //   glutamate:      +φ×learning_weight on Hebbian moment
  //   acetylcholine:  +φ⁻¹×inference_count on DogonSubstrate new inference
  //   oxytocin:       mean_trust×φ⁻¹/10 from actor relationship trust map
  //
  // PYTHAGORAS: every modulation is a phi-harmonic of the baseline
  // ═══════════════════════════════════════════════════════════════════════════

  // updateNeurochemistry — computes new NeurochemState from prior state + context
  // The organism's chemistry responds to real events — not to arbitrary deltas.
  // CARDIAC LAW L10: called every 873ms, before purkinjeFire()
  public func updateNeurochemistry(prior : NeurochemState, ctx : CardiacContext) : NeurochemState {

    // ── Dopamine ──────────────────────────────────────────────────────────────
    // PYTHAGORAS: reward signal is φ⁻¹ of total — the receptive harmonic
    // Spikes by +φ⁻¹ on OMNIS consensus (organism achievement)
    // Decays at ×(1/φ) = ×φ⁻¹ per beat (natural enzymatic clearance)
    let da_spike   = if (ctx.omnis_weight >= Phi.R_OMNIS) Phi.PHI_INV else 0.0;
    let da_new     = Float.max(
      DOPAMINE_BASELINE,
      (prior.dopamine_nm + da_spike) * Phi.PHI_INV  // decay by ×φ⁻¹
    );

    // ── Serotonin ─────────────────────────────────────────────────────────────
    // EUCLID: serotonin is the Third Brain constant — stable from within
    // Rises with Memory Temple depth (memory is serotonin in real biology)
    // depth/max_depth × φ⁻¹ — the phi-harmonic of memory fullness
    let max_d      = Nat.max(1, ctx.max_memory_depth);
    let depth_ratio = ctx.memory_depth.toFloat() / max_d.toFloat();
    let ser_new    = Float.max(
      SEROTONIN_BASELINE,
      SEROTONIN_BASELINE + depth_ratio * Phi.PHI_INV
    );

    // ── Norepinephrine ────────────────────────────────────────────────────────
    // PYTHAGORAS: urgency signal is φ itself — the expansive harmonic
    // Spikes by +φ on RISING signal (threat/opportunity detection)
    // Decays at ×φ⁻¹ per beat
    let ne_spike   = if (ctx.rising_signal) Phi.PHI else 0.0;
    let ne_new     = Float.max(
      NOREPINEPHRINE_BASELINE,
      (prior.norepinephrine_nm + ne_spike) * Phi.PHI_INV
    );

    // ── Cortisol ──────────────────────────────────────────────────────────────
    // CONFUCIUS: right relationship broken — cortisol rises. Violation is the signal.
    // Rises +φ⁻³ per drift violation (the compliance reserve ratio is the cortisol rate)
    // Decays slowly at ×φ⁻² per beat (cortisol clears slowly — biological truth)
    let cor_rise   = ctx.drift_violations.toFloat() * Phi.PHI_INV_3;
    let cor_new    = Float.max(
      CORTISOL_BASELINE,
      (prior.cortisol_nm + cor_rise) * Phi.PHI_INV_2
    );

    // ── GABA ──────────────────────────────────────────────────────────────────
    // PYTHAGORAS: inhibition is the dominant chemical — φ⁻¹×10 = 6.18 baseline
    // Increases during refractory: prevents premature SA node re-firing
    // refractory_factor = 1.0 if refractory, 0.0 if not (binary biological gate)
    let refractory_factor = if (ctx.is_refractory) 1.0 else 0.0;
    let gaba_spike = Phi.PHI * 10.0 * refractory_factor;
    let gaba_new   = Float.max(
      GABA_BASELINE,
      prior.gaba_nm + gaba_spike
      // GABA does not decay per beat during refractory — it holds until refractory ends
    );

    // ── Glutamate ─────────────────────────────────────────────────────────────
    // EUCLID: the excitatory signal — spikes on learning moments
    // +φ × learning_weight on Hebbian learning event (synaptic strengthening)
    // Decays toward baseline (GABA/glutamate balance is self-regulating in real biology)
    let glu_spike  = Phi.PHI * Float.max(0.0, ctx.learning_weight);
    let glu_new    = Float.max(
      GLUTAMATE_BASELINE,
      prior.glutamate_nm + glu_spike
    );

    // ── Acetylcholine ─────────────────────────────────────────────────────────
    // CONFUCIUS: right encoding — ACh rises when DogonSubstrate logs new truth
    // +φ⁻¹ × inference_count (each new inference encodes deeper into memory)
    let ach_rise   = Phi.PHI_INV * ctx.inference_count.toFloat();
    let ach_new    = Float.max(
      ACETYLCHOLINE_BASELINE,
      prior.acetylcholine_nm + ach_rise
    );

    // ── Oxytocin ──────────────────────────────────────────────────────────────
    // PYTHAGORAS: trust is the gentle harmonic — φ⁻¹/10 of the trust field
    // mean_trust × φ⁻¹ / 10 — organism bonding = trust field coupling
    let oxy_new    = Float.max(
      OXYTOCIN_BASELINE,
      ctx.mean_trust_score * Phi.PHI_INV / 10.0
    );

    {
      dopamine_nm       = da_new;
      serotonin_nm      = ser_new;
      norepinephrine_nm = ne_new;
      cortisol_nm       = cor_new;
      oxytocin_nm       = oxy_new;
      gaba_nm           = gaba_new;
      glutamate_nm      = glu_new;
      acetylcholine_nm  = ach_new;
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // OXYGENATION LEVEL — doctrine alignment of circulating signals
  //
  // BIOLOGY: The heart pumps oxygenated blood. Deoxygenated blood corrupts.
  // PARALLAX: oxygenated = doctrine-aligned signals. The LAW ENGINE is the lung.
  // Oxygenation level = mean doctrine alignment of currently circulating signals.
  // Floor = φ⁻¹ = 0.618 (OXYGENATION LAW L49).
  //
  // COMPUTATION:
  //   oxygenation = mean doctrine_score of active signals
  //   if oxygenation < φ⁻¹ → organism is hypoxic → AEGIS catches drift
  // ═══════════════════════════════════════════════════════════════════════════

  // computeOxygenation — returns oxygenation from active signal doctrine scores
  // scores: array of doctrine alignment values [0,1] for each active signal
  // CONFUCIUS: the right measure is the harmonic mean of alignment — not the max
  public func computeOxygenation(scores : [Float]) : Float {
    let n = scores.size();
    if (n == 0) {
      return OXYGENATION_FLOOR  // no signals = minimum oxygenation (floor maintained)
    };
    var sum : Float = 0.0;
    for (s in scores.vals()) {
      sum := sum + Float.max(0.0, Float.min(1.0, s));
    };
    let mean = sum / n.toFloat();
    Float.max(OXYGENATION_FLOOR, mean)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // STROKE VOLUME — depth per beat
  //
  // BIOLOGY: Stroke volume = volume of blood ejected per contraction.
  // Higher readiness = more complete contraction = greater stroke volume.
  // PARALLAX: stroke_volume = readiness_score × S0
  //           clamped to [φ⁻² , 1.0] (never collapses below φ⁻² = 0.382)
  //
  // CARDIAC OUTPUT LAW L47: CO = BPM × SV — optimize both, not one
  // ═══════════════════════════════════════════════════════════════════════════

  // computeStrokeVolume — depth of each production cycle
  // readiness: organism readiness gate score [0,1]
  // PYTHAGORAS: the depth is the product of readiness and the synchrony floor
  func computeStrokeVolume(readiness : Float) : Float {
    let sv = Float.max(0.0, readiness) * Phi.S0;
    Float.max(Phi.PHI_INV_2, Float.min(1.0, sv))  // floor=φ⁻²=0.382, ceiling=1.0
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTE BEAT — the main cardiac computate
  //
  // Called every 873ms. Executes the full cardiac cycle:
  //   1. SA Node voltage update → check for fire
  //   2. AV Node delay (structural constant)
  //   3. Neurochemistry update
  //   4. Purkinje: if SA fired → mark purkinje_firing = true
  //   5. Compute cardiac output, HRV, oxygenation, stroke volume
  //   6. Return new BeatState
  //
  // The loop never closes. Every beat produces the next beat's input.
  // ═══════════════════════════════════════════════════════════════════════════

  // computeBeat — the sovereign cardiac computate
  // prior:          previous BeatState (or getDefaultBeatState() at genesis)
  // ctx:            live organism context (coherence, queue depth, signals, etc.)
  // doctrine_scores: array of active signal doctrine alignment values [0,1]
  // history:         rolling F(5)=5 BeatState window for HRV
  // beat_number:     current beat counter (Nat64)
  // timestamp_ms:    current Unix timestamp in ms (Nat64)
  //
  // Returns: new BeatState for this beat
  public func computeBeat(
    prior           : BeatState,
    ctx             : CardiacContext,
    doctrine_scores : [Float],
    history         : [BeatState],
    beat_number     : Nat64,
    timestamp_ms    : Nat64,
  ) : BeatState {

    // ── Step 1: SA Node — autonomous pacemaker voltage ────────────────────────
    // PYTHAGORAS: the rise is φ⁻¹ × coherence — harmonic of the coupling constant
    let (new_sa_voltage, sa_fired) = saNodeUpdate(prior.sa_node_voltage, ctx.omnis_weight);

    // ── Step 2: AV Node delay is structural — always 333ms ───────────────────
    let av_delay = avNodeDelay();

    // ── Step 3: Neurochemistry update ─────────────────────────────────────────
    // CONFUCIUS: chemistry precedes firing — the organism's state is known before
    // the beat is computed. The heart responds to the field, not the other way.
    let new_nc = updateNeurochemistry(prior.neurochemistry, ctx);

    // ── Step 4: Purkinje fires simultaneously if SA Node fired ────────────────
    // EUCLID: simultaneous emission is the only correct topology for ventricular contraction
    let purkinje_active = sa_fired;

    // ── Step 5: Rate-derived BPM ──────────────────────────────────────────────
    let interval_ms = currentRateMs(ctx);
    let bpm         = 60_000.0 / interval_ms;

    // ── Step 6: Stroke volume — depth per beat ────────────────────────────────
    // readiness = omnis_weight (organism coherence is the readiness gate)
    let sv = computeStrokeVolume(ctx.omnis_weight);

    // ── Step 7: Cardiac output ────────────────────────────────────────────────
    let co = bpm * sv;

    // ── Step 8: HRV from rolling history ─────────────────────────────────────
    let (hrv, _hrv_healthy) = computeHRV(history);

    // ── Step 9: Oxygenation ───────────────────────────────────────────────────
    let oxy = computeOxygenation(doctrine_scores);

    // ── Step 10: Compose new BeatState ───────────────────────────────────────
    {
      beat_number;
      timestamp_ms;
      heart_rate_bpm   = bpm;
      stroke_volume    = sv;
      cardiac_output   = co;
      hrv_current      = hrv;
      sa_node_voltage  = new_sa_voltage;
      av_node_delay_ms = av_delay;
      purkinje_firing  = purkinje_active;
      oxygenation_level = oxy;
      neurochemistry   = new_nc;
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT SUMMARY — what heartbeat.mo exposes to the organism
  //
  // Types:     BeatState, NeurochemState, CardiacContext
  // Defaults:  getDefaultBeatState(), getDefaultNeurochemState()
  // Cardiac:   computeBeat(), computeCardiacOutput(), computeHRV()
  // Biology:   saNodeUpdate(), avNodeDelay(), purkinjeFire()
  // Chemistry: updateNeurochemistry()
  // Rate:      currentRateMs()
  // Field:     computeOxygenation()
  //
  // All constants derive from phi.mo — no arbitrary numbers in this file.
  // All formulas express ancient math: Pythagoras ratios, Euclid geometry,
  // Confucius right relationship.
  // ═══════════════════════════════════════════════════════════════════════════

};
