import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

// PARALLAX — 21 Neurochemical Dynamics (SOVEREIGN MATH v3)
// Michaelis-Menten receptor saturation
// Reuptake transporter competitive clearance
// Full 21-chemical cross-modulation matrix
// Receptor desensitization for chronically high levels
module {

  public let DOPAMINE       : Nat = 0;
  public let SEROTONIN      : Nat = 1;
  public let NOREPINEPHRINE : Nat = 2;
  public let CORTISOL       : Nat = 3;
  public let ACETYLCHOLINE  : Nat = 4;
  public let GABA           : Nat = 5;
  public let GLUTAMATE      : Nat = 6;
  public let OXYTOCIN       : Nat = 7;
  public let ENDORPHIN      : Nat = 8;
  public let TESTOSTERONE   : Nat = 9;
  public let ESTROGEN       : Nat = 10;
  public let MELATONIN      : Nat = 11;
  public let INSULIN_ANALOG : Nat = 12;
  public let ADRENALINE     : Nat = 13;
  public let T3_ANALOG      : Nat = 14;
  public let T4_ANALOG      : Nat = 15;
  public let CYTOKINE       : Nat = 16;
  public let PROSTAGLANDIN  : Nat = 17;
  public let VASOPRESSIN    : Nat = 18;
  public let NPY_ANALOG     : Nat = 19;
  public let VIP_ANALOG     : Nat = 20;

  let S0 : Float = 1.0;

  // Michaelis-Menten receptor occupancy: L/(L+Km)
  // Models saturation — doubling ligand != doubling effect
  func mm_occupancy(level : Float, km : Float) : Float {
    let L = Float.max(0.0, level);
    L / (L + Float.max(0.001, km))
  };

  // Reuptake transporter clearance: competitive inhibition model
  // clearance = ru * occupancy * L
  func reuptake_clear(level : Float, ru : Float, km : Float) : Float {
    let occ = mm_occupancy(level, km);
    Float.max(0.0, ru * occ * Float.max(0.0, level))
  };

  // Receptor desensitization: reduces effect when level chronically > threshold
  func desensitize(level : Float, threshold : Float) : Float {
    if (level > threshold) {
      1.0 / (1.0 + 0.1 * (level - threshold))
    } else {
      1.0
    }
  };

  // Update a single neurochemical with Michaelis-Menten decay
  public func updateLevel(level : Float, production : Float, decay : Float) : Float {
    // Classic: next = level + prod - level*decay
    // Upgraded: use MM saturation on decay so high levels clear faster
    let L = Float.max(0.0, level);
    let km_decay = 2.0;  // half-max concentration for decay enzyme
    let vmax_decay = decay * 3.0;  // max decay rate at saturation
    let actual_decay = vmax_decay * mm_occupancy(L, km_decay);
    Float.max(0.1, L + Float.max(0.0, production) - actual_decay)
  };

  public type NcSignals = {
    reward       : Float;
    novelty      : Float;
    threat       : Float;
    coherence    : Float;
    compliance   : Float;
    formaCapital : Float;
    novaSize     : Float;
    beat         : Nat;
    miningRate   : Float;
  };

  // Km values for reuptake transporters (DAT, SERT, NET analogs)
  let KM_DAT  : Float = 0.5;  // dopamine transporter
  let KM_SERT : Float = 0.8;  // serotonin transporter
  let KM_NET  : Float = 0.3;  // norepinephrine transporter
  let RU_DAT  : Float = 0.04; // reuptake rate constant
  let RU_SERT : Float = 0.03;
  let RU_NET  : Float = 0.05;

  // Compute all 21 production values with cross-modulation
  public func computeProductions(levels : [Float], s : NcSignals) : [Float] {
    let lv = func(i : Nat) : Float {
      if (i < levels.size()) Float.max(0.0, levels[i]) else S0
    };
    let da  = lv(DOPAMINE);       // dopamine
    let ser = lv(SEROTONIN);      // serotonin
    let ne  = lv(NOREPINEPHRINE); // norepinephrine
    let cor = lv(CORTISOL);       // cortisol
    let _ach = lv(ACETYLCHOLINE);  // acetylcholine
    let gab = lv(GABA);           // GABA
    let _glu = lv(GLUTAMATE);      // glutamate
    let oxy = lv(OXYTOCIN);       // oxytocin
    let _end = lv(ENDORPHIN);      // endorphin
    let bdnf_idx = 8;             // proxy for BDNF via endorphin slot
    let _bdnf = Float.max(S0, lv(bdnf_idx));

    // GABA-glutamate allosteric gate: high GABA suppresses glutamate production
    let gaba_gate = 1.0 / (1.0 + 0.2 * gab);
    // Cortisol suppresses BDNF/endorphin
    let cort_suppress = Float.max(0.1, 1.0 - Float.min(0.8, cor * 0.1));
    // Desensitization: receptors down-regulate under chronic high levels
    let da_sens   = desensitize(da,  3.0);
    let ser_sens  = desensitize(ser, 3.0);
    let cor_sens  = desensitize(cor, 4.0);

    [
      /* DOPAMINE       */ (0.1 * Float.max(0.0, s.reward) + 0.05 * Float.max(0.0, s.novelty)) * da_sens
                          - reuptake_clear(da, RU_DAT, KM_DAT),
      /* SEROTONIN      */ (0.08 * Float.max(0.0, s.compliance) + 0.03 * Float.max(S0, s.coherence)) * ser_sens
                          - reuptake_clear(ser, RU_SERT, KM_SERT),
      /* NOREPINEPHRINE */ (0.12 * Float.max(0.0, s.threat) + 0.04 * Float.max(0.0, s.novelty))
                          - reuptake_clear(ne, RU_NET, KM_NET),
      /* CORTISOL       */ Float.min(5.0, 0.15 * (1.0 - Float.min(1.0, s.compliance)) + 0.1 * Float.max(0.0, 1.5 - s.coherence)) * cor_sens,
      /* ACETYLCHOLINE  */ 0.09 * Float.max(0.0, s.novelty) + 0.06 * Float.max(S0, s.coherence),
      /* GABA           */ 0.07 * Float.max(S0, s.coherence) + 0.05 * mm_occupancy(ser, 1.0),
      /* GLUTAMATE      */ (0.1 * Float.max(S0, s.coherence) + 0.04 * Float.max(0.0, s.threat)) * gaba_gate,
      /* OXYTOCIN       */ 0.06 * s.novaSize * 0.01 + 0.05 * Float.max(S0, s.coherence),
      /* ENDORPHIN      */ (0.05 * Float.max(0.0, s.reward) + 0.03 * (s.formaCapital / 1000.0)) * cort_suppress,
      /* TESTOSTERONE   */ 0.08 * Float.max(0.0, s.threat) + 0.06 * Float.max(0.0, s.novelty),
      /* ESTROGEN       */ 0.04 * s.novaSize * 0.01 + 0.05 * Float.max(S0, s.coherence),
      /* MELATONIN      */ 0.06 * Float.max(0.0, 1.0 - Float.abs(Float.sin((s.beat : Int).toFloat() * 0.000145))),
      /* INSULIN_ANALOG */ 0.05 * s.formaCapital * 0.001,
      /* ADRENALINE     */ 0.2 * mm_occupancy(cor, 1.5) * Float.max(0.0, s.threat),
      /* T3_ANALOG      */ 0.03 * Float.max(S0, s.coherence),
      /* T4_ANALOG      */ 0.02 * Float.max(S0, s.coherence) + 0.01 * lv(T3_ANALOG),
      /* CYTOKINE       */ 0.1 * Float.max(0.0, s.threat) * (1.0 - Float.min(0.9, oxy * 0.1)),
      /* PROSTAGLANDIN  */ 0.08 * Float.max(0.0, s.novelty),
      /* VASOPRESSIN    */ 0.04 * s.formaCapital * 0.0001,
      /* NPY_ANALOG     */ 0.06 * Float.max(0.0, s.miningRate) * 0.1,
      /* VIP_ANALOG     */ 0.03 * Float.max(S0, s.coherence)
    ]
  };

  // Michaelis-Menten decay rates (Km values for enzymatic clearance)
  public let DECAY_RATES : [Float] = [
    0.020, 0.015, 0.025, 0.030, 0.020,
    0.018, 0.022, 0.012, 0.010, 0.020,
    0.012, 0.015, 0.018, 0.040, 0.010,
    0.008, 0.025, 0.030, 0.012, 0.015,
    0.010
  ];

  // Update all 21 levels with MM kinetics
  public func updateAll(levels : [var Float], signals : NcSignals) {
    let prods = computeProductions(Array.tabulate<Float>(levels.size(), func i { levels[i] }), signals);
    for (i in levels.keys()) {
      let decay = if (i < DECAY_RATES.size()) DECAY_RATES[i] else 0.02;
      let prod  = if (i < prods.size()) prods[i] else 0.0;
      levels[i] := updateLevel(levels[i], prod, decay);
    };
    // Cortisol ceiling
    if (3 < levels.size()) {
      levels[3] := Float.min(5.0, levels[3]);
    };
  };

};
