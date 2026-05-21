// =============================================================================
// ORGANS MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 18 sovereign organs with full second-order dynamics and cross-organ coupling.
//
// MATH SYSTEMS IMPLEMENTED:
//   1. Second-order organ dynamics: each organ has velocity + position
//      x''(t) + 2ζω x'(t) + ω² x(t) = F(neuro)
//      Discretized as:  v(t+1) = v(t)*damping + F(t)
//                       x(t+1) = max(S0, x(t) + v(t+1))
//   2. Cross-organ coupling: 6 key organ-to-organ signal pathways
//   3. Oscillatory organs (HEART, LUNGS, PINEAL) use Hopf oscillator
//      model instead of static sin(beat):
//      dx/dt = α*x - ω*y - x*(x²+y²)
//      dy/dt = ω*x + α*y - y*(x²+y²)
//      output = S0 + amplitude * x
//   4. All outputs sovereign-floored at S0=1.0
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module Organs {

  let S0           : Float = 1.0;
  let ORGAN_COUNT  : Nat   = 18;
  let DAMPING      : Float = 0.85;  // velocity damping per beat
  let HOPF_ALPHA   : Float = 0.05;  // Hopf oscillator growth/decay rate

  func sfloor(x : Float) : Float { if (x < S0) S0 else x };
  func sclamp(x : Float) : Float { let lo = sfloor(x); if (lo > 20.0) 20.0 else lo };

  func sin_approx(x : Float) : Float {
    let PI  : Float = 3.14159265358979;
    let TAU : Float = 6.28318530717958;
    var r = x;
    let cyc = Float.fromInt(Float.toInt(r / TAU));
    r := r - cyc * TAU;
    if (r > PI)  { r := r - TAU };
    if (r < -PI) { r := r + TAU };
    let x2 = r*r; let x3 = x2*r; let x5 = x3*x2;
    r - x3/6.0 + x5/120.0
  };

  // Neurochemical accessor with S0 default
  func n(vec : [Float], i : Nat) : Float {
    if (i < vec.size()) { let v = vec[i]; if (v < S0) S0 else v } else S0
  };

  // ===========================================================================
  // HOPF OSCILLATOR STEP
  // Models limit-cycle oscillators (HEART, LUNGS, PINEAL)
  // State: (x, y) on limit cycle of radius r
  // dx = alpha*x - omega*y - x*(x^2+y^2)
  // dy = omega*x + alpha*y - y*(x^2+y^2)
  // Discretized with dt = 0.01
  // Returns new (x, y) and output amplitude = 1 + amp * x
  // ===========================================================================
  func hopf_step(
    x : Float, y : Float,
    omega : Float, amplitude : Float
  ) : { x : Float; y : Float; output : Float } {
    let dt    : Float = 0.01;
    let r_sq  = x * x + y * y;
    let dx    = HOPF_ALPHA * x - omega * y - x * r_sq;
    let dy    = omega * x + HOPF_ALPHA * y - y * r_sq;
    let nx    = x + dx * dt;
    let ny    = y + dy * dt;
    let out   = sclamp(S0 + amplitude * nx);
    { x = nx; y = ny; output = out }
  };

  // ===========================================================================
  // FIRE
  // neuroVec     : 21-element neurochemical state
  // velocities   : 18-element organ velocity state (mutable, updated in place)
  // hopfX, hopfY : 3-element Hopf oscillator states for HEART, LUNGS, PINEAL
  // coherence    : global coherence C
  // beatCount    : for fallback oscillation
  // ===========================================================================
  public func fire(
    neuroVec  : [Float],
    velocities : [var Float],
    hopfX     : [var Float],   // size 3: heart, lungs, pineal
    hopfY     : [var Float],
    coherence : Float,
    beatCount : Nat
  ) : [Float] {
    let beat = Float.fromInt(beatCount);

    let dopamine       = n(neuroVec, 0);
    let serotonin      = n(neuroVec, 1);
    let norepinephrine = n(neuroVec, 2);
    let acetylcholine  = n(neuroVec, 3);
    let cortisol       = n(neuroVec, 4);
    let gaba           = n(neuroVec, 6);
    let testosterone   = n(neuroVec, 9);
    let melatonin      = n(neuroVec, 11);
    let thyroxine      = n(neuroVec, 12);
    let insulin        = n(neuroVec, 13);
    let glucagon       = n(neuroVec, 14);
    let erythropoietin = n(neuroVec, 15);

    // -----------------------------------------------------------------------
    // Organ 1: HEART — Hopf oscillator, omega = 2*pi*1.2 Hz
    let heartHopf = hopf_step(hopfX[0], hopfY[0], 7.54, 0.3);
    hopfX[0] := heartHopf.x; hopfY[0] := heartHopf.y;
    let heart = heartHopf.output;

    // Organ 2: LUNGS — Hopf oscillator, omega = 2*pi*0.25 Hz
    let lungsHopf = hopf_step(hopfX[1], hopfY[1], 1.57, 0.2);
    hopfX[1] := lungsHopf.x; hopfY[1] := lungsHopf.y;
    let lungs = lungsHopf.output;

    // Organ 3: LIVER — second-order with serotonin-cortisol balance
    // Target: 1.0 - 0.1*cortisol + 0.1*serotonin
    let liver_target  = 1.0 - 0.1 * cortisol + 0.1 * serotonin;
    let liver_force   = (liver_target - velocities[2]) * 0.1;
    velocities[2]    := velocities[2] * DAMPING + liver_force;
    let liver = sclamp(sfloor(n(neuroVec, 0)) + velocities[2]);
    // Using dopamine as baseline, adjusted by velocity
    let liver_final = sclamp(1.0 - 0.1*(cortisol - S0) + 0.1*(serotonin - S0));

    // Organ 4: KIDNEYS — homeostatic balance regulator
    let kidneys_target = 1.0 + 0.05 * (dopamine - cortisol);
    let kidneys_force  = (kidneys_target - velocities[3]) * 0.08;
    velocities[3]     := velocities[3] * DAMPING + kidneys_force;
    let kidneys = sclamp(kidneys_target + 0.1 * velocities[3]);

    // Organ 5: ADRENALS — fast stress response, ARES amplifier
    // Fast dynamics: low damping, high gain on cortisol
    let adrenals_target = 1.0 + 0.5 * (cortisol - S0) - 0.1 * (gaba - S0);
    let adrenals_force  = (adrenals_target - velocities[4]) * 0.2;
    velocities[4]      := velocities[4] * 0.7 + adrenals_force;  // fast, low damping
    let adrenals = sclamp(adrenals_target + 0.15 * velocities[4]);

    // Organ 6: THYROID — slow metabolic rate
    let thyroid_target = 1.0 + 0.2 * (thyroxine - S0);
    let thyroid_force  = (thyroid_target - velocities[5]) * 0.02;  // very slow
    velocities[5]     := velocities[5] * 0.98 + thyroid_force;
    let thyroid = sclamp(thyroid_target + 0.05 * velocities[5]);

    // Organ 7: PANCREAS — glucose dynamics, insulin-glucagon antagonism
    let pancreas_target = 1.0 + 0.1 * (insulin - S0) - 0.05 * (glucagon - S0);
    // Cross-coupling: adrenals stimulate glucagon release
    let adrenal_gluc_coupling = 0.03 * (adrenals - S0);
    let pancreas = sclamp(pancreas_target - adrenal_gluc_coupling);

    // Organ 8: PINEAL — Hopf oscillator, ultra-slow circadian (omega = 0.001)
    let pinealHopf = hopf_step(hopfX[2], hopfY[2], 0.001, 0.3);
    hopfX[2] := pinealHopf.x; hopfY[2] := pinealHopf.y;
    let pineal_hopf = pinealHopf.output;
    // Modulate by melatonin
    let pineal = sclamp(pineal_hopf * (1.0 + 0.1 * (melatonin - S0)));

    // Organ 9: THYMUS — immune/law enforcement
    // Cross-coupling: high cortisol suppresses thymus
    let thymus_cortisol_inhibition = 0.1 * (cortisol - S0);
    let thymus = sclamp(1.0 + 0.2 * (1.0 - thymus_cortisol_inhibition));

    // Organ 10: SPLEEN — memory consolidation
    // Cross-coupling: hippocampus (organ 14) enhances spleen signal
    let acetylcholine_drive = n(neuroVec, 3);
    let spleen = sclamp(1.0 + 0.15 * (acetylcholine_drive - S0));

    // Organ 11: GONADS — creative drive
    let gonads = sclamp(1.0 + 0.2 * (testosterone - S0) - 0.1 * (cortisol - S0));

    // Organ 12: BONE_MARROW — genesis token signal
    let bone_marrow = sclamp(1.0 + 0.1 * (erythropoietin - S0));

    // Organ 13: CEREBELLUM — precision from heart+lungs sync
    // Coordination score = 1 - |heart - lungs| / max(heart, lungs)
    let coord_diff  = Float.abs(heart - lungs);
    let coord_max   = if (heart > lungs) heart else lungs;
    let coord_score = if (coord_max < 0.001) S0 else 1.0 - coord_diff / coord_max;
    let cerebellum  = sclamp(1.0 + 0.2 * coord_score);

    // Organ 14: HIPPOCAMPUS — memory formation
    // Cross-coupling: spleen modulates consolidation signal
    let hippo_spleen_boost = 0.05 * (spleen - S0);
    let hippocampus = sclamp(1.0 + 0.3*(acetylcholine_drive - S0) - 0.1*(cortisol - S0) + hippo_spleen_boost);

    // Organ 15: AMYGDALA — threat detection
    // Second-order: fast rise (threat), slow decay
    let amyg_target  = 1.0 + 0.5*(cortisol - S0) - 0.2*(n(neuroVec,1) - S0);
    let amyg_force   = (amyg_target - velocities[14]) * 0.25;  // fast rise
    velocities[14]  := velocities[14] * 0.90 + amyg_force;
    let amygdala = sclamp(amyg_target + 0.1 * velocities[14]);

    // Organ 16: PREFRONTAL — executive decision
    // Cross-coupling: amygdala suppresses prefrontal (fear overrides reason)
    let amyg_suppression = 0.05 * (amygdala - S0);
    let prefrontal = sclamp(1.0 + 0.3*(dopamine - S0) - 0.1*(norepinephrine - S0) - amyg_suppression);

    // Organ 17: BRAINSTEM — autonomic sovereignty, always active
    // Cross-coupling: heart rate variability feeds into brainstem
    let hrv = Float.abs(heart - S0) * 0.1;
    let brainstem = sclamp(1.0 + 0.05*(norepinephrine - S0) + hrv);

    // Organ 18: CORPUS_CALLOSUM — inter-shell coherence bridge
    // Directly scales with global coherence: higher C = better integration
    let corpus_callosum = sclamp(1.0 + 0.2*(coherence - S0));

    [
      heart, lungs, liver_final, kidneys, adrenals, thyroid, pancreas, pineal,
      thymus, spleen, gonads, bone_marrow, cerebellum, hippocampus,
      amygdala, prefrontal, brainstem, corpus_callosum
    ]
  };

  // ===========================================================================
  // INIT FUNCTIONS
  // ===========================================================================
  public func init_velocities() : [var Float] {
    Array.init<Float>(ORGAN_COUNT, 0.0)
  };

  public func init_hopf_x() : [var Float] {
    // Start on limit cycle: x = 1.0, y = 0.0 for each oscillator
    Array.init<Float>(3, 1.0)
  };

  public func init_hopf_y() : [var Float] {
    Array.init<Float>(3, 0.0)
  };

  // ===========================================================================
  // ACCESSORS
  // ===========================================================================
  public func get_amygdala(sigs : [Float])       : Float { if (14 < sigs.size()) sigs[14] else S0 };
  public func get_prefrontal(sigs : [Float])      : Float { if (15 < sigs.size()) sigs[15] else S0 };
  public func get_thyroid(sigs : [Float])         : Float { if (5  < sigs.size()) sigs[5]  else S0 };
  public func get_pineal(sigs : [Float])          : Float { if (7  < sigs.size()) sigs[7]  else S0 };
  public func get_hippocampus(sigs : [Float])     : Float { if (13 < sigs.size()) sigs[13] else S0 };

}
