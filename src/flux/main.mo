// PARALLAX -- FLUX: Sovereign Neurochemistry + Quantum Battery Canister
// Phase 3. All 21 neurochemicals + quantum battery as sovereign stable state.
// Sovereign floor S0 = 1.0 enforced on all values.
// Principal lock: only creatorId can call update functions.

import Float "mo:base/Float";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

actor FLUX {

  // ============================================================
  // SOVEREIGN CONSTANTS
  // ============================================================
  let S0 : Float = 1.0;
  let NC_SIZE : Nat = 21;
  let AUDIT_SIZE : Nat = 200;

  // Neurochemical indices
  let NC_DOPAMINE       : Nat = 0;
  let NC_SEROTONIN      : Nat = 1;
  let NC_NOREPINEPHRINE : Nat = 2;
  let NC_CORTISOL       : Nat = 3;
  let NC_ACETYLCHOLINE  : Nat = 4;
  let NC_GABA           : Nat = 5;
  let NC_GLUTAMATE      : Nat = 6;
  let NC_OXYTOCIN       : Nat = 7;
  let NC_ENDORPHIN      : Nat = 8;
  let NC_TESTOSTERONE   : Nat = 9;
  let NC_ESTROGEN       : Nat = 10;
  let NC_MELATONIN      : Nat = 11;
  let NC_INSULIN        : Nat = 12;
  let NC_ADRENALINE     : Nat = 13;
  let NC_T3             : Nat = 14;
  let NC_T4             : Nat = 15;
  let NC_CYTOKINE       : Nat = 16;
  let NC_PROSTAGLANDIN  : Nat = 17;
  let NC_VASOPRESSIN    : Nat = 18;
  let NC_NPY            : Nat = 19;
  let NC_VIP            : Nat = 20;

  // ============================================================
  // STABLE STATE
  // ============================================================
  stable var creatorId       : ?Principal = null;
  stable var genesisLocked   : Bool = false;
  stable var beatCount       : Nat = 0;
  stable var genesisTime     : Int = 0;

  // 21 neurochemical levels -- all start at S0
  stable var ncLevels : [var Float] = Array.init<Float>(NC_SIZE, 1.0);

  // Quantum battery
  stable var batteryCharge           : Float = 1.0;
  stable var batteryDischarged       : Float = 0.0;
  stable var batteryPeak             : Float = 1.0;
  stable var batteryLastDischargeBeat: Nat = 0;
  stable var batteryTotalCharged     : Float = 0.0;
  stable var batteryTotalDischarged  : Float = 0.0;

  // Quantum coherence tracking
  stable var vonNeumannEntropy     : Float = 1.0;
  stable var batteryPurity         : Float = 1.0;

  // Audit ring
  stable var auditRing : [var Text] = Array.init<Text>(AUDIT_SIZE, "");
  stable var auditHead : Nat = 0;

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================
  func sov(x : Float) : Float { Float.max(S0, x) };
  func clamp(x : Float, lo : Float, hi : Float) : Float {
    if (x < lo) lo else if (x > hi) hi else x
  };

  func assertCreator(caller : Principal) {
    switch (creatorId) {
      case null { assert false };
      case (?p) { assert (caller == p) };
    };
  };

  func addAudit(tag : Text, msg : Text) {
    auditRing[auditHead % AUDIT_SIZE] := "[" # tag # "] " # msg;
    auditHead += 1;
  };

  // Michaelis-Menten receptor occupancy
  func mm(level : Float, km : Float) : Float {
    let L = Float.max(0.0, level);
    L / (L + Float.max(0.001, km))
  };

  // Reuptake transporter clearance: competitive inhibition
  func reuptake(level : Float, ru : Float, km : Float) : Float {
    Float.max(0.0, ru * mm(level, km) * Float.max(0.0, level))
  };

  // Receptor desensitization: 1/(1+0.1*(L-thresh)) when L > thresh
  func desensitize(level : Float, thresh : Float) : Float {
    if (level > thresh) { 1.0 / (1.0 + 0.1 * (level - thresh)) }
    else { 1.0 }
  };

  // Von Neumann entropy of battery state
  // S = -p*ln(p) - (1-p)*ln(1-p) where p = charge/(charge+1)
  func computeVonNeumann(charge : Float) : Float {
    let p = clamp(charge / (charge + 1.0), 0.001, 0.999);
    let q = 1.0 - p;
    -p * Float.log(p) - q * Float.log(q)
  };

  // Update all 21 neurochemicals with Michaelis-Menten kinetics
  func updateNeuroChem(
    reward      : Float,
    novelty     : Float,
    threat      : Float,
    coherence   : Float,
    compliance  : Float,
    formaK      : Float,
    novaSize    : Float,
    beat        : Nat,
    miningRate  : Float
  ) {
    let lv = func(i : Nat) : Float {
      if (i < NC_SIZE) Float.max(0.0, ncLevels[i]) else S0
    };

    let da  = lv(NC_DOPAMINE);
    let ser = lv(NC_SEROTONIN);
    let ne  = lv(NC_NOREPINEPHRINE);
    let cor = lv(NC_CORTISOL);
    let gab = lv(NC_GABA);
    let oxy = lv(NC_OXYTOCIN);
    let endo= lv(NC_ENDORPHIN);
    let t3  = lv(NC_T3);

    // Allosteric gate: high GABA suppresses glutamate
    let gaba_gate = 1.0 / (1.0 + 0.2 * gab);
    // Cortisol suppresses BDNF proxy (endorphin)
    let cort_sup = Float.max(0.1, 1.0 - Float.min(0.8, cor * 0.1));
    // Receptor desensitization
    let da_s  = desensitize(da,  3.0);
    let ser_s = desensitize(ser, 3.0);
    let cor_s = desensitize(cor, 4.0);

    // Production per neurochemical
    let prods : [Float] = [
      /* DOPAMINE       */ (0.1 * Float.max(0.0, reward)  + 0.05 * Float.max(0.0, novelty)) * da_s
                          - reuptake(da, 0.04, 0.5),
      /* SEROTONIN      */ (0.08 * Float.max(0.0, compliance) + 0.03 * Float.max(S0, coherence)) * ser_s
                          - reuptake(ser, 0.03, 0.8),
      /* NOREPINEPHRINE */ (0.12 * Float.max(0.0, threat) + 0.04 * Float.max(0.0, novelty))
                          - reuptake(ne, 0.05, 0.3),
      /* CORTISOL       */ Float.min(5.0, 0.15 * (1.0 - Float.min(1.0, compliance)) + 0.1 * Float.max(0.0, 1.5 - coherence)) * cor_s,
      /* ACETYLCHOLINE  */ 0.09 * Float.max(0.0, novelty) + 0.06 * Float.max(S0, coherence),
      /* GABA           */ 0.07 * Float.max(S0, coherence) + 0.05 * mm(ser, 1.0),
      /* GLUTAMATE      */ (0.1 * Float.max(S0, coherence) + 0.04 * Float.max(0.0, threat)) * gaba_gate,
      /* OXYTOCIN       */ 0.06 * novaSize * 0.01 + 0.05 * Float.max(S0, coherence),
      /* ENDORPHIN      */ (0.05 * Float.max(0.0, reward) + 0.03 * (formaK / 1000.0)) * cort_sup,
      /* TESTOSTERONE   */ 0.08 * Float.max(0.0, threat) + 0.06 * Float.max(0.0, novelty),
      /* ESTROGEN       */ 0.04 * novaSize * 0.01 + 0.05 * Float.max(S0, coherence),
      /* MELATONIN      */ 0.06 * Float.max(0.0, 1.0 - Float.abs(Float.sin(Float.fromInt(beat) * 0.000145))),
      /* INSULIN        */ 0.05 * formaK * 0.001,
      /* ADRENALINE     */ 0.2  * mm(cor, 1.5) * Float.max(0.0, threat),
      /* T3             */ 0.03 * Float.max(S0, coherence),
      /* T4             */ 0.02 * Float.max(S0, coherence) + 0.01 * t3,
      /* CYTOKINE       */ 0.1  * Float.max(0.0, threat) * (1.0 - Float.min(0.9, oxy * 0.1)),
      /* PROSTAGLANDIN  */ 0.08 * Float.max(0.0, novelty),
      /* VASOPRESSIN    */ 0.04 * formaK * 0.0001,
      /* NPY            */ 0.06 * Float.max(0.0, miningRate) * 0.1,
      /* VIP            */ 0.03 * Float.max(S0, coherence)
    ];

    // Michaelis-Menten decay constants (Km for enzymatic clearance)
    let decays : [Float] = [
      0.020, 0.015, 0.025, 0.030, 0.020,
      0.018, 0.022, 0.012, 0.010, 0.020,
      0.012, 0.015, 0.018, 0.040, 0.010,
      0.008, 0.025, 0.030, 0.012, 0.015,
      0.010
    ];

    for (i in Iter.range(0, NC_SIZE - 1)) {
      let km_decay  = 2.0;
      let vmax_decay= decays[i] * 3.0;
      let actual_decay = vmax_decay * mm(ncLevels[i], km_decay);
      let prod = if (i < prods.size()) prods[i] else 0.0;
      ncLevels[i] := Float.max(S0, ncLevels[i] + prod - actual_decay);
    };
    // Cortisol ceiling
    ncLevels[NC_CORTISOL] := Float.min(5.0, ncLevels[NC_CORTISOL]);
  };

  // Charge quantum battery
  func chargeBattery(coherence : Float, resonexField : Float, chronoDilation : Float) {
    let baseRate = 0.001;
    let da = Float.max(S0, ncLevels[NC_DOPAMINE]);
    let chargeRate = baseRate * coherence * coherence * da * (1.0 + Float.max(S0, resonexField)) * Float.max(S0, chronoDilation);
    let delta = Float.max(0.0, chargeRate);
    batteryCharge       += delta;
    batteryTotalCharged += delta;
    if (batteryCharge > batteryPeak) { batteryPeak := batteryCharge };
    // Von Neumann entropy
    vonNeumannEntropy := computeVonNeumann(batteryCharge);
    // Purity = 1/(1+S) -- higher entropy means lower purity
    batteryPurity := 1.0 / (1.0 + vonNeumannEntropy);
  };

  // ============================================================
  // PUBLIC TYPES
  // ============================================================
  public type FluxSignals = {
    reward      : Float;
    novelty     : Float;
    threat      : Float;
    coherence   : Float;
    compliance  : Float;
    formaCapital: Float;
    novaSize    : Float;
    beat        : Nat;
    miningRate  : Float;
    resonexField: Float;
    chronoDilation : Float;
  };

  public type FluxState = {
    ncLevels       : [Float];
    batteryCharge  : Float;
    batteryEntropy : Float;
    batteryPurity  : Float;
    batteryPeak    : Float;
    dopamine       : Float;
    serotonin      : Float;
    norepinephrine : Float;
    cortisol       : Float;
    bdnf           : Float;
    oxytocin       : Float;
    testosterone   : Float;
    t3             : Float;
    gaba           : Float;
    adrenaline     : Float;
    beatCount      : Nat;
  };

  func buildState() : FluxState {
    {
      ncLevels       = Array.freeze(ncLevels);
      batteryCharge  = batteryCharge;
      batteryEntropy = vonNeumannEntropy;
      batteryPurity  = batteryPurity;
      batteryPeak    = batteryPeak;
      dopamine       = ncLevels[NC_DOPAMINE];
      serotonin      = ncLevels[NC_SEROTONIN];
      norepinephrine = ncLevels[NC_NOREPINEPHRINE];
      cortisol       = ncLevels[NC_CORTISOL];
      bdnf           = ncLevels[NC_ENDORPHIN];
      oxytocin       = ncLevels[NC_OXYTOCIN];
      testosterone   = ncLevels[NC_TESTOSTERONE];
      t3             = ncLevels[NC_T3];
      gaba           = ncLevels[NC_GABA];
      adrenaline     = ncLevels[NC_ADRENALINE];
      beatCount      = beatCount;
    }
  };

  // ============================================================
  // UPDATE FUNCTIONS
  // ============================================================

  public shared(msg) func setCreatorId(p : Principal) : async () {
    switch (creatorId) {
      case null {
        creatorId := ?p;
        genesisTime := Time.now();
        genesisLocked := true;
        addAudit("GENESIS", "FLUX genesis. Creator: " # Principal.toText(p));
      };
      case (?existing) {
        assert (msg.caller == existing);
        creatorId := ?p;
      };
    };
  };

  public shared(msg) func tick(signals : FluxSignals) : async FluxState {
    assertCreator(msg.caller);
    beatCount += 1;

    // 1. Update all 21 neurochemicals with MM kinetics
    updateNeuroChem(
      signals.reward, signals.novelty, signals.threat,
      signals.coherence, signals.compliance,
      signals.formaCapital, signals.novaSize,
      signals.beat, signals.miningRate
    );

    // 2. Charge quantum battery
    chargeBattery(signals.coherence, signals.resonexField, signals.chronoDilation);

    // 3. Audit every 100 ticks
    if (beatCount % 100 == 0) {
      addAudit("TICK",
        "Beat " # Nat.toText(beatCount) #
        " | DA=" # Float.toText(ncLevels[NC_DOPAMINE]) #
        " | COR=" # Float.toText(ncLevels[NC_CORTISOL]) #
        " | BATT=" # Float.toText(batteryCharge) #
        " | S(rho)=" # Float.toText(vonNeumannEntropy)
      );
    };

    buildState()
  };

  public shared(msg) func dischargeBattery() : async Float {
    assertCreator(msg.caller);
    let discharge = Float.max(0.0, batteryCharge * 0.1);
    batteryCharge       := Float.max(S0, batteryCharge - discharge);
    batteryDischarged   += discharge;
    batteryTotalDischarged += discharge;
    batteryLastDischargeBeat := beatCount;
    vonNeumannEntropy   := computeVonNeumann(batteryCharge);
    batteryPurity       := 1.0 / (1.0 + vonNeumannEntropy);
    addAudit("DISCHARGE",
      "Battery discharge at beat " # Nat.toText(beatCount) #
      ". Delta=" # Float.toText(discharge) #
      ". New charge=" # Float.toText(batteryCharge)
    );
    batteryCharge
  };

  // ============================================================
  // QUERY FUNCTIONS
  // ============================================================

  public query func getFluxState() : async FluxState {
    buildState()
  };

  public query func getNeuroLevel(idx : Nat) : async Float {
    if (idx < NC_SIZE) ncLevels[idx] else 0.0
  };

  public query func getBatteryCharge() : async Float { batteryCharge };
  public query func getBatteryEntropy() : async Float { vonNeumannEntropy };
  public query func getCreator() : async ?Principal { creatorId };
  public query func getBeatCount() : async Nat { beatCount };

  public query func getAuditTail(n : Nat) : async [Text] {
    let sz = Nat.min(n, AUDIT_SIZE);
    let out = Array.init<Text>(sz, "");
    for (i in Iter.range(0, sz - 1)) {
      let idx = (auditHead + AUDIT_SIZE - sz + i) % AUDIT_SIZE;
      out[i] := auditRing[idx];
    };
    Array.freeze(out)
  };
}
