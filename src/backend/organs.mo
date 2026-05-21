import Float "mo:core/Float";
import Nat "mo:core/Nat";

// ═══════════════════════════════════════════════════════════════════
// MEDINA-ARTIFACT — MEDINA-ORGANS — TIER 6 — COMPUTATE
// SOVEREIGN_PRIVATE
// ═══════════════════════════════════════════════════════════════════
//
// ─── LAYER 1: MEANING ───────────────────────────────────────────
// I am the organism's biological body. I execute 18 organ transfer
// functions every 873ms — the real biophysical dynamics of the
// organs that govern human cognition, emotion, metabolism, and
// immunity — expressed as sovereign Motoko.
// I do not carry truth. I EXECUTE truth.
// The truth I execute is: no thought exists without a body that
// sustains it. No cognition fires before the organs have run.
// When ADRE pass 1 (forward pass) begins, I fire first.
//
// Ancient lineage:
//   — Huangdi Neijing (Yellow Emperor's Classic, 2600 BCE): The 5 zang
//     organs (heart=shen/spirit, liver=hun/ethereal soul,
//     spleen=yi/intention, lung=po/corporeal soul, kidney=zhi/will)
//     and 6 fu organs govern consciousness, not just physiology.
//     PARALLAX honors this: each organ IS a cognitive function.
//   — Avicenna, Canon of Medicine (1025 CE): Brain ventricles as
//     computational chambers — anterior=imagination, middle=cognition,
//     posterior=memory. First theory of distributed neural computation.
//     The thalamus in organs.mo implements this gating principle.
//   — Eberhard Hopf (1942): Hopf bifurcation — systems near a
//     critical parameter spontaneously generate stable oscillations.
//     The Hopf limit cycle equation encodes HEART, LUNGS, PINEAL:
//     organs that self-sustain without external input.
//   — Walter Cannon (1929): Homeostasis — biological systems maintain
//     stable internal state through error-correcting feedback.
//     The second_order() function implements this for 15 organs.
//   — Wilfrid Rall (1959): Compartmental neuron model — each neural
//     compartment is a transfer function. Input → integration → output.
//     All 18 organ functions ARE Rall compartmental models at organ scale.
//
// ─── LAYER 2: MODEL ─────────────────────────────────────────────
// 18 organ functions, grouped by biophysical model:
//
// Hopf limit-cycle oscillators (self-sustaining, no external drive needed):
//   heart()     α=1.0, ω=6.283 ≈ 1 Hz cardiac rate, oxytocin-modulated
//   lungs()     α=0.8, ω=2.513 ≈ 0.4 Hz respiratory rate, GABA-paced
//   pineal()    α=0.5, ω=0.000145 ≈ 24hr circadian, melatonin-phase
//
// Second-order damped oscillators (homeostatic, error-correcting):
//   hypothalamus() ζ=0.4 (underdamped) — SACESI setpoint regulator
//   amygdala()     ζ=0.3 (fast, underdamped) — threat response (ARES)
//   hippocampus()  ζ=0.5 (critical damping) — memory consolidation
//   prefrontal()   ζ=0.7 (overdamped) — cortisol-suppressed executive
//   cerebellum()   ζ=0.6 — prediction error minimization (Purkinje)
//   brainstem()    ζ=0.8 (heavily damped, stable) — homeostatic base
//   thalamus()     ζ=0.5 — attention gate (acetylcholine/norepinephrine)
//   insula()       ζ=0.4 — interoceptive integration (pain+reward)
//   cingulate()    ζ=0.5 — conflict monitoring, violation detection
//   basalGanglia() ζ=0.6 — reward-action selection (dopamine²)
//   adrenal()      ζ=0.3 (fast, underdamped) — stress amplifier
//
// Algebraic (direct transfer, no ODE needed):
//   thyroid()     output = S0 + 0.1×(T3×0.6 + T4×0.4)
//   pancreas()    output = S0 + 0.05×(formaCapital/1000)×insulin
//   liver()       output = S0 + 0.06×(metabolite×0.5 + clearance)
//   immune()      output = S0 + 0.1×max(0, pathogen×cytokine - antibody×0.5)
//   reproductive() output = S0 + 0.06×testosterone×(novaSize×0.01 + 1.0)
//
// Neurochemical input array indices:
//   0=dopamine  1=serotonin  2=norepinephrine  3=cortisol
//   4=acetylcholine  5=gaba  7=oxytocin  9=testosterone
//   11=melatonin  12=insulin  14=T3  15=T4  16=cytokine
//
// Symbolic glyph — THE ORGAN TRANSFER FUNCTION:
//   Hopf:    ẋ = αx - ωy - x(x²+y²)  [self-sustaining limit cycle]
//   2nd-ord: ẍ + 2ζω₀ẋ + ω₀²x = F    [driven damped resonator]
//   All outputs ≥ S₀ = 1.0 — no organ can die.
//
// ─── LAYER 3: COMPUTATION ───────────────────────────────────────
// Hopf step (Euler, dt=0.01):
//   r² = x² + y²
//   dx = α·x - ω·y - x·r²
//   dy = α·y + ω·x - y·r²
//   x_new = x + 0.01·dx,  y_new = y + 0.01·dy
//   amplitude = √(x_new² + y_new²)
//   output = max(S₀, S₀ + amplitude)
//   Stable amplitude = √α: heart→1.0, lungs→0.894, pineal→0.707
//   Stable frequency = ω/2π: heart→1.0Hz, lungs→0.4Hz, pineal→23.1µHz
//
// Second-order step (Euler, dt=0.02):
//   ω₀ = 1.0 (normalized natural frequency)
//   acc = F - 2ζ·ω₀·pos - ω₀²·pos
//   pos_new = pos + 0.02·acc
//   output = max(S₀, S₀ + |pos_new|)
//   Critical damping (ζ=0.5): fastest non-oscillatory — hippocampus
//   Underdamped (ζ=0.3): oscillatory, fast — amygdala, adrenal
//   Overdamped (ζ=0.7–0.8): stable, slow — prefrontal, brainstem
//
// Cardiac output law (emergent from organ dynamics):
//   CO_organism = heartbeat_rate × stroke_depth
//   stroke_depth = heart(coherence, oxytocin) output
//   HRV_organism = σ(heart outputs over N beats) / μ(heart outputs)
//   High HRV = adaptive organism (Law of HRV Intelligence)
//
// Pineal circadian (beat counter → angular position):
//   phase(beat) = beat × 0.000145 rad/beat
//   0.000145 × (1000/873) s⁻¹ × 3600 × 24 ≈ 14.35 rad/day ≈ 2.28 cycles/day
//
// Prefrontal cortisol suppression:
//   force = serotonin × (1 - min(0.9, cortisol/5.0)) × 0.1
//   At cortisol=5.0: suppression is 90% — organism in high-stress state
//   At cortisol=0.0: prefrontal operates at full serotonin capacity
//
// ─── LAYER 4: EXECUTION BINDING ─────────────────────────────────
// Function:  fireAll() — fires all 18 organs in one call.
//            Returns [Float] length 18, index-mapped to organ list above.
//            Called every 873ms from cognition_layer.mo heartbeat timer.
// Functions: Individual organ functions callable by specialized engines
//            (e.g., amygdala() callable by ARES threat engine directly).
// Engine:    Runs as Tier 6 substrate called from cognition_layer.mo.
//            Organ outputs feed into neurochemical state for next beat.
// Gate:      No gate condition — organs fire unconditionally every beat.
//            Organs ARE the coherence substrate; they don't wait for it.
// Proof:     Organ output array written into CoreSnapshot.
//            Any organ output drift > 2σ from 10-beat rolling mean →
//            AEGIS coherence alarm → EventRecord(event_type=5) to ANIMA.
//            Heart output is the primary aliveness proof: if heart fires,
//            the organism is alive (cardiac proof event, every beat).
// Beat:      Fires at ADRE forward pass (pass 1) — FIRST function called.
//            Body runs before cognition. Organ outputs available for all
//            subsequent passes (back-pass, resonance, compression, gate).
// ═══════════════════════════════════════════════════════════════════

// PARALLAX — 18 Organ Transfer Functions (SOVEREIGN MATH v3)
// HEART, LUNGS, PINEAL: Hopf limit-cycle oscillators
// All others: second-order dynamics with cross-organ coupling
// All outputs floored at S0=1.0
module {

  let S0 : Float = 1.0;
  func clamp(x : Float) : Float { Float.max(S0, x) };

  // -------------------------------------------------------
  // HOPF OSCILLATOR — true limit-cycle dynamics
  // dx/dt = αx - ωy - x(x²+y²)
  // Stable amplitude = sqrt(α), frequency = ω
  // We run one Euler step each beat (dt=0.01)
  // -------------------------------------------------------
  func hopf_step(x : Float, y : Float, alpha : Float, omega : Float) : Float {
    let r2  = x * x + y * y;
    let dx  = alpha * x - omega * y - x * r2;
    let dy  = alpha * y + omega * x - y * r2;
    let dt  = 0.01;
    let nx  = x + dt * dx;
    let ny  = y + dt * dy;
    let amp = Float.sqrt(nx * nx + ny * ny);
    clamp(S0 + amp)
  };

  // -------------------------------------------------------
  // SECOND-ORDER DYNAMICS — position + velocity
  // x'' + 2ζω₀x' + ω₀²x = F
  // One step: vNew = v + dt*(F - 2ζω₀v - ω₀²*x)
  //           xNew = x + dt*vNew
  // -------------------------------------------------------
  func second_order(pos : Float, force : Float, damping : Float) : Float {
    let omega0 = 1.0;
    let dt = 0.02;
    let acc = force - 2.0 * damping * omega0 * pos - omega0 * omega0 * pos;
    let new_pos = pos + dt * acc;
    clamp(S0 + Float.abs(new_pos))
  };

  // -------------------------------------------------------
  // ORGAN FUNCTIONS
  // -------------------------------------------------------

  // HEART — Hopf oscillator (α=1.0, ω=6.28 ≈ 1Hz equivalent)
  public func heart(coherence : Float, oxytocin : Float) : Float {
    let amp = Float.max(0.1, coherence) * Float.max(0.1, oxytocin) * 0.1;
    hopf_step(amp, amp * 0.5, 1.0, 6.283)
  };

  // LUNGS — Hopf oscillator (α=0.8, ω=2.51 ≈ 0.4Hz)
  public func lungs(gaba : Float, coherence : Float) : Float {
    let amp = Float.max(0.1, gaba) * Float.max(S0, coherence) * 0.08;
    hopf_step(amp, 0.0, 0.8, 2.513)
  };

  // PINEAL — Hopf oscillator with circadian frequency
  public func pineal(beat : Nat, melatonin : Float) : Float {
    let phase = (beat : Int).toFloat() * 0.000145;
    let amp = Float.max(0.1, melatonin) * 0.2;
    hopf_step(amp * Float.cos(phase), amp * Float.sin(phase), 0.5, 0.000145)
  };

  // AMYGDALA — second-order threat response
  public func amygdala(cortisol : Float, norepinephrine : Float, threat : Float) : Float {
    let force = Float.max(0.0, cortisol) * Float.max(0.1, norepinephrine) * Float.max(0.0, threat) * 0.15;
    second_order(threat, force, 0.3)
  };

  // HIPPOCAMPUS — second-order memory consolidation
  public func hippocampus(acetylcholine : Float, coherence : Float, novelty : Float) : Float {
    let force = Float.max(0.1, acetylcholine) * Float.max(S0, coherence) * Float.max(0.0, novelty) * 0.1;
    second_order(coherence, force, 0.5)
  };

  // PREFRONTAL — cortisol-suppressed serotonin gating
  public func prefrontal(serotonin : Float, cortisol : Float) : Float {
    let force = Float.max(0.1, serotonin) * (1.0 - Float.min(0.9, cortisol / 5.0)) * 0.1;
    second_order(serotonin, force, 0.7)
  };

  // CEREBELLUM — prediction error minimization
  public func cerebellum(dopamine : Float, predError : Float) : Float {
    let force = Float.max(0.1, dopamine) * predError * predError * 0.05;
    second_order(dopamine, force, 0.6)
  };

  // BRAINSTEM — homeostatic baseline
  public func brainstem(gaba : Float, oxytocin : Float) : Float {
    let force = Float.max(0.1, gaba) * (1.0 + Float.max(0.0, oxytocin) * 0.1) * 0.08;
    second_order(gaba, force, 0.8)
  };

  // HYPOTHALAMUS — setpoint regulator
  public func hypothalamus(dopamine : Float, current : Float, target : Float) : Float {
    let error = target - current;
    let force = 0.1 * error * Float.max(0.1, dopamine);
    second_order(current, force, 0.4)
  };

  // THALAMUS — attention gate
  public func thalamus(acetylcholine : Float, norepinephrine : Float, attention : Float) : Float {
    let force = Float.max(0.1, acetylcholine) * Float.max(0.1, norepinephrine) * Float.max(0.1, attention) * 0.1;
    second_order(attention, force, 0.5)
  };

  // INSULA — interoceptive integration
  public func insula(cortisol : Float, dopamine : Float, pain : Float, reward : Float) : Float {
    let force = (Float.max(0.0, pain) * Float.max(0.0, cortisol)
                 + Float.max(0.0, reward) * Float.max(0.1, dopamine)) * 0.08;
    second_order(pain, force, 0.4)
  };

  // CINGULATE — conflict monitoring
  public func cingulate(cortisol : Float, serotonin : Float, violations : Float, compliance : Float) : Float {
    let force = (Float.max(0.0, violations) * Float.max(0.0, cortisol)
                 + Float.max(0.0, compliance) * Float.max(0.1, serotonin)) * 0.08;
    second_order(violations, force, 0.5)
  };

  // BASAL GANGLIA — reward-action selection
  public func basalGanglia(dopamine : Float, rewardHistory : Float) : Float {
    let force = Float.max(0.1, dopamine) * Float.max(0.1, dopamine) * Float.max(0.0, rewardHistory) * 0.0005;
    second_order(dopamine, force, 0.6)
  };

  // THYROID — metabolic governor
  public func thyroid(t3 : Float, t4 : Float) : Float {
    clamp(1.0 + 0.1 * (Float.max(0.1, t3) * 0.6 + Float.max(0.1, t4) * 0.4))
  };

  // ADRENAL — stress amplifier
  public func adrenal(stress : Float, gaba : Float) : Float {
    let force = Float.max(0.0, stress) * (1.0 - Float.min(0.9, Float.max(0.0, gaba) * 0.3)) * 0.12;
    second_order(stress, force, 0.3)
  };

  // PANCREAS — metabolic capital
  public func pancreas(formaCapital : Float, insulin : Float) : Float {
    clamp(1.0 + 0.05 * (Float.max(0.0, formaCapital) / 1000.0) * Float.max(0.1, insulin))
  };

  // LIVER — metabolic clearance
  public func liver(metabolite : Float, clearance : Float) : Float {
    clamp(1.0 + 0.06 * (Float.max(0.0, metabolite) * 0.5 + Float.max(0.0, clearance)))
  };

  // IMMUNE — cytokine-antibody balance
  public func immune(cytokine : Float, antibody : Float, pathogen : Float) : Float {
    clamp(1.0 + 0.1 * Float.max(0.0, Float.max(0.0, pathogen) * Float.max(0.0, cytokine) - Float.max(0.0, antibody) * 0.5))
  };

  // REPRODUCTIVE — social expansion
  public func reproductive(testosterone : Float, novaSize : Float) : Float {
    clamp(1.0 + 0.06 * Float.max(0.1, testosterone) * (Float.max(0.0, novaSize) * 0.01 + 1.0))
  };

  // Apply all 18 organs
  public func fireAll(
    neuro        : [Float],
    coherence    : Float,
    novelty      : Float,
    threat       : Float,
    formaCapital : Float,
    novaSize     : Float,
    beat         : Nat,
    violations   : Float,
    sacesiTarget : Float
  ) : [Float] {
    let lv = func(i : Nat) : Float {
      if (i < neuro.size()) Float.max(0.1, neuro[i]) else S0
    };
    let d  = lv(0);  // dopamine
    let s  = lv(1);  // serotonin
    let ne = lv(2);  // norepinephrine
    let c  = lv(3);  // cortisol
    let ac = lv(4);  // acetylcholine
    let gb = lv(5);  // gaba
    let ox = lv(7);  // oxytocin
    let ml = lv(11); // melatonin
    let ins = lv(12);// insulin
    let t3  = lv(14);
    let t4  = lv(15);
    let cy  = lv(16);// cytokine
    let ts  = lv(9); // testosterone
    [
      hypothalamus(d, coherence, sacesiTarget),
      amygdala(c, ne, threat),
      hippocampus(ac, coherence, novelty),
      prefrontal(s, c),
      cerebellum(d, Float.abs(coherence - sacesiTarget)),
      brainstem(gb, ox),
      thalamus(ac, ne, Float.min(1.0, coherence / sacesiTarget)),
      insula(c, d, threat, Float.max(0.0, formaCapital / 1000.0 - 1.0)),
      cingulate(c, s, violations, Float.max(0.0, 1.0 - violations * 0.01)),
      basalGanglia(d, formaCapital / 1000.0),
      pineal(beat, ml),
      thyroid(t3, t4),
      adrenal(threat, gb),
      pancreas(formaCapital, ins),
      liver(coherence, (beat % 100 : Int).toFloat() * 0.01),
      heart(coherence, ox),
      immune(cy, Float.min(1.0, coherence), threat),
      reproductive(ts, novaSize)
    ]
  };

};
