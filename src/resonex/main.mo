// PARALLAX -- RESONEX: Sovereign Drives + FORMA + RL + Token Mint Canister
// Phase 3. 7 sovereign drives, Q-learning RL, FORMA compounding, 12-token mint logic.
// Sovereign floor S0 = 1.0 enforced on all values.
// Principal lock: only creatorId can call update functions.

import Float "mo:base/Float";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

actor RESONEX {

  // ============================================================
  // SOVEREIGN CONSTANTS
  // ============================================================
  let S0 : Float = 1.0;
  let N_DRIVES   : Nat = 7;
  let N_ACTIONS  : Nat = 8;
  let N_TOKENS   : Nat = 12;
  let HISTORY_SZ : Nat = 100;
  let AUDIT_SIZE : Nat = 200;

  // Drive indices
  let DRIVE_CURIOSITY    : Nat = 0;
  let DRIVE_SOVEREIGNTY  : Nat = 1;
  let DRIVE_EXPANSION    : Nat = 2;
  let DRIVE_CREATION     : Nat = 3;
  let DRIVE_PROTECTION   : Nat = 4;
  let DRIVE_CONNECTION   : Nat = 5;
  let DRIVE_EXPRESSION   : Nat = 6;

  // Action indices
  let ACT_PATENT   : Nat = 0;
  let ACT_ENFORCE  : Nat = 1;
  let ACT_EXPAND   : Nat = 2;
  let ACT_MINT     : Nat = 3;
  let ACT_ROLLBACK : Nat = 4;
  let ACT_SYNC     : Nat = 5;
  let ACT_REPORT   : Nat = 6;
  let ACT_REST     : Nat = 7;

  // Token indices (12 tokens)
  // 0:MTH 1:MRC 2:GTK 3:CVT 4:VCT 5:KNT 6:SBT 7:HBT 8:DRT 9:RST 10:OMT 11:LGT
  let TOKEN_MTH : Nat = 0;
  let TOKEN_MRC : Nat = 1;
  let TOKEN_GTK : Nat = 2;
  let TOKEN_CVT : Nat = 3;
  let TOKEN_VCT : Nat = 4;
  let TOKEN_KNT : Nat = 5;
  let TOKEN_SBT : Nat = 6;
  let TOKEN_HBT : Nat = 7;
  let TOKEN_DRT : Nat = 8;
  let TOKEN_RST : Nat = 9;
  let TOKEN_OMT : Nat = 10;
  let TOKEN_LGT : Nat = 11;

  let TOKEN_NAMES : [Text] = [
    "MTH","MRC","GTK","CVT","VCT","KNT","SBT","HBT","DRT","RST","OMT","LGT"
  ];

  let DRIVE_NAMES : [Text] = [
    "CURIOSITY","SOVEREIGNTY","EXPANSION","CREATION",
    "PROTECTION","CONNECTION","EXPRESSION"
  ];

  // ============================================================
  // STABLE STATE
  // ============================================================
  stable var creatorId     : ?Principal = null;
  stable var genesisLocked : Bool = false;
  stable var beatCount     : Nat = 0;
  stable var genesisTime   : Int = 0;

  // 7 sovereign drive strengths (all S0=1.0)
  stable var driveStrengths : [var Float] = Array.init<Float>(N_DRIVES, 1.0);

  // Q-values for 7 drives (used in action selection)
  stable var qValues : [var Float] = Array.init<Float>(N_DRIVES, 1.0);

  // 8-action Q-table
  stable var actionQTable : [var Float] = Array.init<Float>(N_ACTIONS, 1.0);

  // RL state
  stable var lastAction          : Nat = ACT_REST;
  stable var lastReward          : Float = 0.0;
  stable var cumulativeReward    : Float = 0.0;
  stable var consecutiveDriveIdx : Nat = DRIVE_SOVEREIGNTY;
  stable var consecutiveDriveRuns: Nat = 0;
  stable var dominantDrive       : Nat = DRIVE_SOVEREIGNTY;
  stable var dominantDriveName   : Text = "SOVEREIGNTY";

  // Action history ring
  stable var actionHistory : [var Nat] = Array.init<Nat>(HISTORY_SZ, ACT_REST);
  stable var historyHead   : Nat = 0;

  // FORMA compounding capital
  stable var formaCapital    : Float = 1000.0;
  stable var formaDeltaLast  : Float = 0.0;
  stable var formaCompounds  : Nat = 0;
  stable var formaPeak       : Float = 1000.0;

  // 12-token mint counters
  stable var tokenMintCount  : [var Nat]   = Array.init<Nat>(N_TOKENS, 0);
  stable var tokenMintTotal  : [var Float] = Array.init<Float>(N_TOKENS, 0.0);
  stable var totalMintEvents : Nat = 0;
  stable var mrcCreatorReserve : Float = 1000.0;

  // Resonex field (Φ) -- weighted sum of shell activations
  stable var resonexField    : Float = 1.0;
  stable var resonexPeak     : Float = 1.0;
  stable var resonexHistory  : [var Float] = Array.init<Float>(50, 1.0);
  stable var resonexHistHead : Nat = 0;

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

  func recordAction(a : Nat) {
    actionHistory[historyHead % HISTORY_SZ] := a;
    historyHead += 1;
  };

  // ============================================================
  // DRIVE UPDATE
  // Drives modulated by novelty, coherence, cortisol, testosterone,
  // hive signal, FORMA capital, compliance, entangla, oxytocin,
  // dolphin signal, shark signal, cytokine.
  // All drives stay >= S0.
  // ============================================================
  func updateDrives(
    novelty     : Float,
    coherence   : Float,
    compliance  : Float,
    cortisol    : Float,
    testosterone: Float,
    hiveSignal  : Float,
    formaK      : Float,
    entangla    : Float,
    oxytocin    : Float,
    dolphin     : Float,
    sharkSig    : Float,
    cytokine    : Float,
    patentCount : Nat
  ) {
    let pc = Float.fromInt(patentCount);
    // CURIOSITY: novelty-driven
    driveStrengths[DRIVE_CURIOSITY] := sov(
      driveStrengths[DRIVE_CURIOSITY]
      + 0.1 * (Float.max(0.0, novelty) - 0.5) - 0.02
    );
    // SOVEREIGNTY: never falls below S0 by law
    driveStrengths[DRIVE_SOVEREIGNTY] := sov(
      driveStrengths[DRIVE_SOVEREIGNTY]
      + 0.05 * Float.max(0.0, compliance) * 0.1 - 0.005
    );
    // EXPANSION: testosterone + hive
    driveStrengths[DRIVE_EXPANSION] := sov(
      driveStrengths[DRIVE_EXPANSION]
      + 0.08 * Float.max(0.0, testosterone) + 0.04 * sov(hiveSignal) - 0.01
    );
    // CREATION: FORMA wealth + coherence
    driveStrengths[DRIVE_CREATION] := sov(
      driveStrengths[DRIVE_CREATION]
      + 0.07 * (formaK / 1000.0) + 0.05 * Float.max(0.0, coherence - 1.0) - 0.01
    );
    // PROTECTION: cortisol + shark + cytokine
    driveStrengths[DRIVE_PROTECTION] := sov(
      driveStrengths[DRIVE_PROTECTION]
      + 0.15 * Float.max(0.0, cortisol) + 0.1 * sov(sharkSig) + 0.05 * Float.max(0.0, cytokine) - 0.03
    );
    // CONNECTION: entangla + oxytocin + dolphin
    driveStrengths[DRIVE_CONNECTION] := sov(
      driveStrengths[DRIVE_CONNECTION]
      + 0.06 * sov(entangla) + 0.05 * Float.max(0.0, oxytocin) + 0.04 * sov(dolphin) - 0.002
    );
    // EXPRESSION: patents + FORMA
    driveStrengths[DRIVE_EXPRESSION] := sov(
      driveStrengths[DRIVE_EXPRESSION]
      + 0.04 * pc * 0.001 + 0.02 * (formaK / 5000.0) - 0.003
    );
  };

  // ============================================================
  // Q-LEARNING DRIVE SELECTION
  // Winner = argmax(strength[i] * qValues[i])
  // If all drives within 0.1 of each other -> REST
  // ============================================================
  func selectDominantDrive() : Nat {
    var minS : Float = driveStrengths[0];
    var maxS : Float = driveStrengths[0];
    for (i in Iter.range(1, N_DRIVES - 1)) {
      if (driveStrengths[i] < minS) minS := driveStrengths[i];
      if (driveStrengths[i] > maxS) maxS := driveStrengths[i];
    };
    if (maxS - minS < 0.1) return ACT_REST;
    var best : Nat = 0;
    var bestScore : Float = driveStrengths[0] * qValues[0];
    for (i in Iter.range(1, N_DRIVES - 1)) {
      let s = driveStrengths[i] * qValues[i];
      if (s > bestScore) { bestScore := s; best := i; };
    };
    best
  };

  // Map dominant drive to action
  func driveToAction(drive : Nat, coherence : Float, aresArmed : Bool) : Nat {
    if (aresArmed) return ACT_ROLLBACK;
    switch (drive) {
      case 0 { ACT_PATENT   };
      case 1 { ACT_ENFORCE  };
      case 2 { ACT_EXPAND   };
      case 3 { if (coherence > 2.618) ACT_MINT else ACT_REPORT };
      case 4 { ACT_ROLLBACK };
      case 5 { ACT_SYNC     };
      case 6 { ACT_REPORT   };
      case _ { ACT_REST     };
    }
  };

  // Q-learning update: TD(0) rule
  // Q(a) <- Q(a) + alpha * (reward - Q(a))
  func updateQValues(reward : Float) {
    let alpha : Float = 0.01;
    if (lastAction < qValues.size()) {
      qValues[lastAction] := sov(
        qValues[lastAction] + alpha * (reward - qValues[lastAction])
      );
    };
    if (lastAction < actionQTable.size()) {
      actionQTable[lastAction] := sov(
        actionQTable[lastAction] + alpha * (reward - actionQTable[lastAction])
      );
    };
  };

  // RL reward: forma delta * 100 + coherence delta * 200 + patent delta * 10
  func computeReward(formaDelta : Float, coherenceDelta : Float, patentDelta : Nat) : Float {
    formaDelta + coherenceDelta * 200.0 + Float.fromInt(patentDelta) * 10.0
  };

  // ============================================================
  // FORMA COMPOUNDING
  // Capital compounds every beat based on thyroid (t3), temporal
  // dilation, Jacob multiplier, and now dopamine.
  // FORMA sovereign floor = 1000.0
  // ============================================================
  func compoundForma(
    thyroid    : Float,
    t3         : Float,
    dilation   : Float,
    jacobMult  : Float,
    dopamine   : Float
  ) : Float {
    let rate = sov(thyroid) * sov(t3) * sov(dilation) * sov(jacobMult) * sov(dopamine) * 0.000001;
    Float.max(1000.0, formaCapital + formaCapital * rate)
  };

  // ============================================================
  // RESONEX FIELD (Φ)
  // Weighted sum of shell activations, frequency-squared weighting.
  // High-freq shells (OMNIS, LAMBDA) dominate.
  // ============================================================
  func computeResonexField(
    alphaA  : Float,  // ALPHA shell avg activation
    betaA   : Float,  // BETA
    gammaA  : Float,  // GAMMA (freq 32)
    thetaA  : Float,  // THETA
    omniA   : Float,  // OMNIS (freq 36) -- highest weight
    lambdaA : Float,  // LAMBDA (freq 8)
    deepA   : Float   // DEEP (freq 36)
  ) : Float {
    // Frequency^2 weights: OMNIS(36^2=1296), GAMMA(32^2=1024), DEEP(36^2=1296),
    // BETA(16^2=256), THETA(16^2=256), ALPHA(8^2=64), LAMBDA(8^2=64)
    let w_omni   = 1296.0;
    let w_gamma  = 1024.0;
    let w_deep   = 1296.0;
    let w_beta   = 256.0;
    let w_theta  = 256.0;
    let w_alpha  = 64.0;
    let w_lambda = 64.0;
    let total_w  = w_omni + w_gamma + w_deep + w_beta + w_theta + w_alpha + w_lambda;
    let phi = (
      w_omni * omniA + w_gamma * gammaA + w_deep * deepA +
      w_beta * betaA + w_theta * thetaA +
      w_alpha * alphaA + w_lambda * lambdaA
    ) / total_w;
    sov(phi)
  };

  // ============================================================
  // 12-TOKEN MINT CONDITIONS
  // ============================================================
  func checkAndMintTokens(
    coherence       : Float,
    sacesiTarget    : Float,
    eagleSignal     : Float,
    regime          : Text,
    patentCount     : Nat,
    compliance      : Float,
    heritageCoh     : Float,
    beat            : Nat,
    jacobRung       : Nat,
    aresArmed       : Bool
  ) {
    if (aresArmed) return;

    // GTK: genesis coherence state (phi ratio)
    if (coherence * compliance > sacesiTarget * 1.618033988749895) {
      tokenMintCount[TOKEN_GTK]  += 1;
      tokenMintTotal[TOKEN_GTK]  += 1.0;
      totalMintEvents += 1;
    };
    // MRC: compliance >= 0.9 and capital > 10000
    if (compliance >= 0.9 and formaCapital > 10000.0) {
      tokenMintCount[TOKEN_MRC] += 1;
      tokenMintTotal[TOKEN_MRC] += 0.1;
      mrcCreatorReserve += 0.1;   // 100% to creator
      totalMintEvents += 1;
    };
    // VCT: bull + eagle
    if (eagleSignal > 3.0 and regime == "BULL") {
      tokenMintCount[TOKEN_VCT] += 1;
      tokenMintTotal[TOKEN_VCT] += 1.0;
      totalMintEvents += 1;
    };
    // KNT: patent milestone every 10
    if (patentCount > 0 and patentCount % 10 == 0) {
      tokenMintCount[TOKEN_KNT] += 1;
      tokenMintTotal[TOKEN_KNT] += 1.0;
      totalMintEvents += 1;
    };
    // SBT: full compliance
    if (compliance >= 1.0) {
      tokenMintCount[TOKEN_SBT] += 1;
      tokenMintTotal[TOKEN_SBT] += 0.5;
      totalMintEvents += 1;
    };
    // HBT: heritage shell coherence > 2.5
    if (heritageCoh > 2.5) {
      tokenMintCount[TOKEN_HBT] += 1;
      tokenMintTotal[TOKEN_HBT] += 1.0;
      totalMintEvents += 1;
    };
    // DRT: consecutive drive runs >= 50
    if (consecutiveDriveRuns >= 50) {
      tokenMintCount[TOKEN_DRT] += 1;
      tokenMintTotal[TOKEN_DRT] += 1.0;
      consecutiveDriveRuns := 0;
      totalMintEvents += 1;
    };
    // OMT: beat milestones every 10000
    if (beat > 0 and beat % 10000 == 0) {
      tokenMintCount[TOKEN_OMT] += 1;
      tokenMintTotal[TOKEN_OMT] += 10.0;
      totalMintEvents += 1;
    };
    // LGT: Jacob's Ladder rung advancement check (every 5000 beats)
    if (beat > 0 and beat % 5000 == 0 and jacobRung >= 3) {
      tokenMintCount[TOKEN_LGT] += 1;
      tokenMintTotal[TOKEN_LGT] += 5.0;
      totalMintEvents += 1;
    };
  };

  // ============================================================
  // PUBLIC TYPES
  // ============================================================
  public type ResonexSignals = {
    novelty     : Float;
    coherence   : Float;
    compliance  : Float;
    cortisol    : Float;
    testosterone: Float;
    hiveSignal  : Float;
    entangla    : Float;
    oxytocin    : Float;
    dolphin     : Float;
    sharkSig    : Float;
    cytokine    : Float;
    patentCount : Nat;
    dopamine    : Float;
    t3          : Float;
    thyroid     : Float;
    dilation    : Float;
    jacobMult   : Float;
    jacobRung   : Nat;
    sacesiTarget: Float;
    eagleSignal : Float;
    regime      : Text;
    heritageCoh : Float;
    beat        : Nat;
    aresArmed   : Bool;
    // Shell activations for RESONEX field
    alphaAct    : Float;
    betaAct     : Float;
    gammaAct    : Float;
    thetaAct    : Float;
    omniAct     : Float;
    lambdaAct   : Float;
    deepAct     : Float;
    // RL feedback
    prevFormaCapital : Float;
    prevCoherence    : Float;
    prevPatentCount  : Nat;
  };

  public type ResonexState = {
    driveStrengths    : [Float];
    qValues           : [Float];
    dominantDrive     : Nat;
    dominantDriveName : Text;
    dominantAction    : Nat;
    formaCapital      : Float;
    resonexField      : Float;
    tokenMintCount    : [Nat];
    mrcCreatorReserve : Float;
    totalMintEvents   : Nat;
    beatCount         : Nat;
    lastReward        : Float;
    cumulativeReward  : Float;
  };

  func buildState() : ResonexState {
    {
      driveStrengths    = Array.freeze(driveStrengths);
      qValues           = Array.freeze(qValues);
      dominantDrive     = dominantDrive;
      dominantDriveName = dominantDriveName;
      dominantAction    = lastAction;
      formaCapital      = formaCapital;
      resonexField      = resonexField;
      tokenMintCount    = Array.freeze(tokenMintCount);
      mrcCreatorReserve = mrcCreatorReserve;
      totalMintEvents   = totalMintEvents;
      beatCount         = beatCount;
      lastReward        = lastReward;
      cumulativeReward  = cumulativeReward;
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
        addAudit("GENESIS", "RESONEX genesis. Creator: " # Principal.toText(p));
      };
      case (?existing) {
        assert (msg.caller == existing);
        creatorId := ?p;
      };
    };
  };

  public shared(msg) func tick(signals : ResonexSignals) : async ResonexState {
    assertCreator(msg.caller);
    beatCount += 1;

    // 1. Compute RL reward from last beat's delta
    let formaDelta    = formaCapital - signals.prevFormaCapital;
    let coherenceDelta= signals.coherence - signals.prevCoherence;
    let patentDelta   = if (signals.patentCount > signals.prevPatentCount)
      signals.patentCount - signals.prevPatentCount else 0;
    let reward = computeReward(formaDelta, coherenceDelta, patentDelta);
    lastReward := reward;
    cumulativeReward += reward;

    // 2. Update Q-values
    updateQValues(reward);

    // 3. Update drive strengths
    updateDrives(
      signals.novelty, signals.coherence, signals.compliance,
      signals.cortisol, signals.testosterone, signals.hiveSignal,
      formaCapital, signals.entangla, signals.oxytocin,
      signals.dolphin, signals.sharkSig, signals.cytokine,
      signals.patentCount
    );

    // 4. Select dominant drive and action
    let newDominant = selectDominantDrive();
    if (newDominant == dominantDrive) {
      consecutiveDriveRuns += 1;
    } else {
      consecutiveDriveRuns := 0;
      dominantDrive := newDominant;
      dominantDriveName := if (newDominant < DRIVE_NAMES.size()) DRIVE_NAMES[newDominant] else "REST";
    };
    let action = driveToAction(dominantDrive, signals.coherence, signals.aresArmed);
    lastAction := action;
    recordAction(action);

    // 5. Compute RESONEX field Φ
    let newPhi = computeResonexField(
      signals.alphaAct, signals.betaAct, signals.gammaAct,
      signals.thetaAct, signals.omniAct, signals.lambdaAct, signals.deepAct
    );
    resonexField := newPhi;
    resonexHistory[resonexHistHead % 50] := newPhi;
    resonexHistHead += 1;
    if (newPhi > resonexPeak) { resonexPeak := newPhi };

    // 6. Compound FORMA
    let prevForma = formaCapital;
    formaCapital := compoundForma(
      signals.thyroid, signals.t3, signals.dilation,
      signals.jacobMult, signals.dopamine
    );
    formaDeltaLast := formaCapital - prevForma;
    formaCompounds += 1;
    if (formaCapital > formaPeak) { formaPeak := formaCapital };

    // 7. Check and mint tokens
    checkAndMintTokens(
      signals.coherence, signals.sacesiTarget, signals.eagleSignal,
      signals.regime, signals.patentCount, signals.compliance,
      signals.heritageCoh, signals.beat, signals.jacobRung, signals.aresArmed
    );

    // 8. Audit every 100 ticks
    if (beatCount % 100 == 0) {
      addAudit("TICK",
        "Beat " # Nat.toText(beatCount) #
        " | Drive=" # dominantDriveName #
        " | FORMA=" # Float.toText(formaCapital) #
        " | Phi=" # Float.toText(resonexField) #
        " | Mints=" # Nat.toText(totalMintEvents) #
        " | R=" # Float.toText(lastReward)
      );
    };

    buildState()
  };

  // ============================================================
  // QUERY FUNCTIONS
  // ============================================================

  public query func getResonexState() : async ResonexState {
    buildState()
  };

  public query func getDriveStrengths() : async [Float] {
    Array.freeze(driveStrengths)
  };

  public query func getFormaCapital() : async Float { formaCapital };
  public query func getResonexField() : async Float { resonexField };
  public query func getMrcReserve() : async Float { mrcCreatorReserve };
  public query func getTokenMintCount() : async [Nat] { Array.freeze(tokenMintCount) };
  public query func getTotalMintEvents() : async Nat { totalMintEvents };
  public query func getDominantDrive() : async Nat { dominantDrive };
  public query func getDominantDriveName() : async Text { dominantDriveName };
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
