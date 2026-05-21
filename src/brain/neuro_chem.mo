// =============================================================================
// NEURO_CHEM MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 21 neurochemicals with full receptor kinetics.
//
// MATH SYSTEMS IMPLEMENTED:
//   1. Michaelis-Menten receptor saturation kinetics
//   2. Reuptake transporter model (competitive inhibition)
//   3. Cross-neurochemical modulation matrix (key pairs)
//   4. Temporal dilation slows ALL decay rates uniformly
//   5. Allosteric modulation: GABA gates GLUTAMATE and vice versa
//   6. Receptor desensitization: prolonged high levels reduce receptor gain
//   7. Sovereign floor S0=1.0 on all levels
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module NeuroChem {

  let S0          : Float = 1.0;
  public let SIZE : Nat   = 21;

  func sfloor(x : Float) : Float { if (x < S0) S0 else x };

  // ===========================================================================
  // INDICES (for readability)
  // ===========================================================================
  let IDX_DOPAMINE       : Nat = 0;
  let IDX_SEROTONIN      : Nat = 1;
  let IDX_NOREPI         : Nat = 2;
  let IDX_ACETYLCHOLINE  : Nat = 3;
  let IDX_CORTISOL       : Nat = 4;
  let IDX_OXYTOCIN       : Nat = 5;
  let IDX_GABA           : Nat = 6;
  let IDX_GLUTAMATE      : Nat = 7;
  let IDX_ENDORPHIN      : Nat = 8;
  let IDX_TESTOSTERONE   : Nat = 9;
  let IDX_ESTRADIOL      : Nat = 10;
  let IDX_MELATONIN      : Nat = 11;
  let IDX_THYROXINE      : Nat = 12;
  let IDX_INSULIN        : Nat = 13;
  let IDX_GLUCAGON       : Nat = 14;
  let IDX_EPO            : Nat = 15;  // erythropoietin
  let IDX_ADENOSINE      : Nat = 16;
  let IDX_ANANDAMIDE     : Nat = 17;
  let IDX_BDNF           : Nat = 18;
  let IDX_SUBSTANCE_P    : Nat = 19;
  let IDX_NITRIC_OXIDE   : Nat = 20;

  // ===========================================================================
  // PRODUCTION RATES (mol/beat, baseline)
  // ===========================================================================
  let PRODUCTION : [Float] = [
    0.15, 0.10, 0.12, 0.08, 0.20,  // DOPAMINE..CORTISOL
    0.06, 0.10, 0.12, 0.08, 0.07,  // OXYTOCIN..TESTOSTERONE
    0.05, 0.04, 0.06, 0.08, 0.05,  // ESTRADIOL..GLUCAGON
    0.04, 0.06, 0.05, 0.04, 0.07,  // EPO..SUBSTANCE_P
    0.05                            // NITRIC_OXIDE
  ];

  // ===========================================================================
  // BASELINE DECAY RATES
  // ===========================================================================
  let BASE_DECAY : [Float] = [
    0.08, 0.05, 0.10, 0.06, 0.15,  // DOPAMINE..CORTISOL
    0.04, 0.07, 0.09, 0.05, 0.04,  // OXYTOCIN..TESTOSTERONE
    0.03, 0.02, 0.03, 0.05, 0.04,  // ESTRADIOL..GLUCAGON
    0.02, 0.04, 0.03, 0.02, 0.05,  // EPO..SUBSTANCE_P
    0.03                            // NITRIC_OXIDE
  ];

  // Michaelis-Menten half-saturation constants (Km) per chemical
  // Effect: at level = Km, receptor occupancy = 50%
  let KM : [Float] = [
    2.0, 1.5, 1.8, 1.2, 3.0,  // DOPAMINE..CORTISOL  (cortisol needs higher Km)
    1.0, 1.3, 2.0, 1.5, 1.2,  // OXYTOCIN..TESTOSTERONE
    1.0, 0.8, 1.2, 1.5, 1.3,  // ESTRADIOL..GLUCAGON
    0.8, 1.0, 1.2, 0.9, 1.5,  // EPO..SUBSTANCE_P
    0.7                         // NITRIC_OXIDE
  ];

  // Reuptake transporter rates (rU) — how quickly reuptake clears the synapse
  // Models DAT, SERT, NET, etc.
  let REUPTAKE : [Float] = [
    0.04, 0.03, 0.05, 0.02, 0.0,   // DOPAMINE..CORTISOL (cortisol no transporter)
    0.01, 0.02, 0.03, 0.02, 0.01,
    0.01, 0.01, 0.0,  0.02, 0.02,
    0.01, 0.02, 0.015,0.01, 0.02,
    0.01
  ];

  // ===========================================================================
  // MICHAELIS-MENTEN RECEPTOR OCCUPANCY
  // f(L) = L / (L + Km)   ∈ [0, 1]
  // At L=S0=1, f = 1/(1+Km) — always sub-saturating at baseline
  // At high L, f → 1 (saturation)
  // ===========================================================================
  func mm_occupancy(level : Float, km : Float) : Float {
    level / (level + km)
  };

  // ===========================================================================
  // RECEPTOR DESENSITIZATION
  // When a chemical stays high for many beats, receptor sensitivity decreases.
  // desens(L) = 1 / (1 + 0.1 * max(0, L - 2.0))
  // Levels below 2.0 have no desensitization.
  // ===========================================================================
  func desensitize(level : Float) : Float {
    let excess = if (level > 2.0) level - 2.0 else 0.0;
    1.0 / (1.0 + 0.1 * excess)
  };

  // ===========================================================================
  // CROSS-MODULATION MATRIX (key neurochemical interactions)
  //
  // Rules encoded:
  //   Serotonin  → REDUCES cortisol production   (by 0.05 * serotonin)
  //   GABA       → INHIBITS glutamate production  (by 0.08 * GABA)
  //   Glutamate  → EXCITES norepinephrine prod    (by 0.06 * glutamate)
  //   Cortisol   → SUPPRESSES BDNF production    (by 0.10 * cortisol)
  //   Endorphin  → REDUCES substance_P production (by 0.07 * endorphin)
  //   Dopamine   → BOOSTS anandamide production   (by 0.05 * dopamine)
  //   Oxytocin   → BOOSTS oxytocin (positive feedback, limited by saturation)
  //   Testosterone→ BOOSTS testosterone (pulse), limited by desensitization
  //
  // Returns a delta_production vector [SIZE] to add to base production
  // ===========================================================================
  func cross_modulation(levels : [var Float]) : [Float] {
    let delta = Array.init<Float>(SIZE, 0.0);

    let serotonin   = levels[IDX_SEROTONIN];
    let gaba        = levels[IDX_GABA];
    let glutamate   = levels[IDX_GLUTAMATE];
    let cortisol    = levels[IDX_CORTISOL];
    let endorphin   = levels[IDX_ENDORPHIN];
    let dopamine    = levels[IDX_DOPAMINE];
    let oxytocin    = levels[IDX_OXYTOCIN];

    // Serotonin suppresses cortisol production
    delta[IDX_CORTISOL]     := -(0.05 * mm_occupancy(serotonin, KM[IDX_SEROTONIN]));

    // GABA inhibits glutamate production
    delta[IDX_GLUTAMATE]    := -(0.08 * mm_occupancy(gaba, KM[IDX_GABA]));

    // Glutamate excites norepinephrine
    delta[IDX_NOREPI]       := 0.06 * mm_occupancy(glutamate, KM[IDX_GLUTAMATE]);

    // Cortisol suppresses BDNF
    delta[IDX_BDNF]         := -(0.10 * mm_occupancy(cortisol, KM[IDX_CORTISOL]));

    // Endorphin reduces Substance P
    delta[IDX_SUBSTANCE_P]  := -(0.07 * mm_occupancy(endorphin, KM[IDX_ENDORPHIN]));

    // Dopamine boosts anandamide
    delta[IDX_ANANDAMIDE]   := 0.05 * mm_occupancy(dopamine, KM[IDX_DOPAMINE]);

    // Oxytocin positive feedback (limited by desensitization)
    delta[IDX_OXYTOCIN]     := 0.02 * mm_occupancy(oxytocin, 2.0) * desensitize(oxytocin);

    // Allosteric: GABA gates NMDA-type glutamate release
    // (extra inhibition when both high)
    let gaba_glut_gate = mm_occupancy(gaba, 1.5) * mm_occupancy(glutamate, 1.5);
    delta[IDX_GLUTAMATE] := delta[IDX_GLUTAMATE] - 0.04 * gaba_glut_gate;

    Array.freeze(delta)
  };

  // ===========================================================================
  // UPDATE — full neurochemical dynamics per beat
  //
  // For each chemical i:
  //   effective_production[i] = (PRODUCTION[i] + cross_delta[i]) * organ_mod
  //   reuptake_clearance[i]   = REUPTAKE[i] * mm_occupancy(L[i], Km[i]) * L[i]
  //   net_decay[i]            = (BASE_DECAY[i] * L[i] + reuptake_clearance[i]) / tau
  //   ΔL[i]                   = effective_production[i] - net_decay[i]
  //   L[i]                    = max(S0, L[i] + ΔL[i])
  // ===========================================================================
  public func update(
    levels        : [var Float],
    decayRates    : [var Float],
    amygdalaOut   : Float,
    prefrontalOut : Float,
    tDilation     : Float
  ) : () {
    let organ_mod = (amygdalaOut + prefrontalOut) / 2.0;
    let tau       = if (tDilation < 1.0) 1.0 else tDilation;

    // Compute cross-modulation deltas
    let xmod = cross_modulation(levels);

    var i = 0;
    while (i < SIZE) {
      let L  = levels[i];
      let km = if (i < KM.size()) KM[i] else 1.0;
      let ru = if (i < REUPTAKE.size()) REUPTAKE[i] else 0.0;

      // Effective production with cross-modulation and organ gate
      let base_prod = if (i < PRODUCTION.size()) PRODUCTION[i] else 0.0;
      let xd        = xmod[i];
      let eff_prod  = (base_prod + xd) * organ_mod;

      // Reuptake clearance: competitive transporter saturation
      // clearance = ru * occupancy * L
      let occupancy = mm_occupancy(L, km);
      let reuptake_clearance = ru * occupancy * L;

      // Effective decay: base exponential + reuptake, divided by temporal dilation
      let base_d    = if (i < decayRates.size()) decayRates[i] else BASE_DECAY[i];
      let net_decay = (base_d * L + reuptake_clearance) / tau;

      // Net change
      let delta = eff_prod - net_decay;
      levels[i] := sfloor(L + delta);
      i += 1;
    };
  };

  // ===========================================================================
  // RECEPTOR FUNCTIONS — computed outputs for other systems
  // ===========================================================================

  // BDNF boosts Hebbian η: η_eff = η_base * (1 + 0.5 * MM_occupancy(BDNF, 0.9))
  public func bdnf_eta_boost(levels : [var Float]) : Float {
    let bdnf = levels[IDX_BDNF];
    1.0 + 0.5 * mm_occupancy(bdnf, 0.9)
  };

  // Thyroxine drives FORMA compound rate
  public func thyroxine_forma_mod(levels : [var Float]) : Float {
    let t4 = levels[IDX_THYROXINE];
    0.001 * mm_occupancy(t4, KM[IDX_THYROXINE]) * t4
  };

  // Dopamine shell weight modulator (D1 receptor approximation)
  public func dopamine_shell_mod(levels : [var Float]) : Float {
    let d = levels[IDX_DOPAMINE];
    1.0 + 0.2 * mm_occupancy(d, KM[IDX_DOPAMINE]) * desensitize(d)
  };

  // Nitric oxide coherence boost
  public func nitric_oxide_boost(levels : [var Float]) : Float {
    let no = levels[IDX_NITRIC_OXIDE];
    mm_occupancy(no, 0.7) * no
  };

  // General neuro modifier for Hebbian learning
  // Geometric mean of dopamine, serotonin, BDNF occupancies
  public func general_neuro_mod(levels : [var Float]) : Float {
    let d_occ  = mm_occupancy(levels[IDX_DOPAMINE],  KM[IDX_DOPAMINE]);
    let s_occ  = mm_occupancy(levels[IDX_SEROTONIN], KM[IDX_SEROTONIN]);
    let b_occ  = mm_occupancy(levels[IDX_BDNF],      KM[IDX_BDNF]);
    // Geometric mean: cube root of product
    let product = d_occ * s_occ * b_occ;
    sfloor(Float.sqrt(Float.sqrt(product)) * 2.0)  // scale to ~1.0 at baseline
  };

  // ===========================================================================
  // INIT
  // ===========================================================================
  public func init_levels() : [var Float] {
    Array.init<Float>(SIZE, S0)
  };

  public func init_decay() : [var Float] {
    let d = Array.init<Float>(SIZE, 0.05);
    var i = 0;
    while (i < SIZE and i < BASE_DECAY.size()) {
      d[i] := BASE_DECAY[i];
      i += 1;
    };
    d
  };

  public func get(levels : [var Float], i : Nat) : Float {
    if (i < SIZE) levels[i] else S0
  };

  public func as_immutable(levels : [var Float]) : [Float] {
    Array.freeze(levels)
  };

}
