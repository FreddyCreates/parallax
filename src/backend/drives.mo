import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

// PARALLAX — 7 Sovereign Drives + 8-Action RL Engine
module {

  // Drive indices
  public let CURIOSITY   : Nat = 0;
  public let SOVEREIGNTY : Nat = 1;
  public let EXPANSION   : Nat = 2;
  public let CREATION    : Nat = 3;
  public let PROTECTION  : Nat = 4;
  public let CONNECTION  : Nat = 5;
  public let EXPRESSION  : Nat = 6;

  // Action indices
  public let ACTION_PATENT   : Nat = 0;
  public let ACTION_ENFORCE  : Nat = 1;
  public let ACTION_EXPAND   : Nat = 2;
  public let ACTION_MINT     : Nat = 3;
  public let ACTION_ROLLBACK : Nat = 4;
  public let ACTION_SYNC     : Nat = 5;
  public let ACTION_REPORT   : Nat = 6;
  public let ACTION_REST     : Nat = 7;

  public let DRIVE_NAMES : [Text] = [
    "CURIOSITY", "SOVEREIGNTY", "EXPANSION", "CREATION",
    "PROTECTION", "CONNECTION", "EXPRESSION"
  ];

  public type DriveSignals = {
    novelty      : Float;
    compliance   : Float;
    cortisol     : Float;
    testosterone : Float;
    hiveSignal   : Float;
    formaCapital : Float;
    coherence    : Float;
    patentCount  : Nat;
    beat         : Nat;
    entangla     : Float;
    oxytocin     : Float;
    dolphin      : Float;
    sharkSignal  : Float;
    cytokine     : Float;
  };

  // Update all 7 drive strengths in place
  public func updateStrengths(strengths : [var Float], s : DriveSignals) {
    // CURIOSITY
    strengths[0] := Float.max(1.0, strengths[0] + 0.1 * (Float.max(0.0, s.novelty) - 0.5) - 0.02);
    // SOVEREIGNTY — never goes below 1.0 (sovereign floor)
    strengths[1] := Float.max(1.0, strengths[1] + 0.05 * Float.max(0.0, s.compliance) * 0.1 - 0.005);
    // EXPANSION
    strengths[2] := Float.max(1.0, strengths[2] + 0.08 * Float.max(0.0, s.testosterone) + 0.04 * Float.max(1.0, s.hiveSignal) - 0.01);
    // CREATION
    strengths[3] := Float.max(1.0, strengths[3] + 0.07 * (s.formaCapital / 1000.0) + 0.05 * Float.max(0.0, s.coherence - 1.0) - 0.01);
    // PROTECTION
    strengths[4] := Float.max(1.0, strengths[4] + 0.15 * Float.max(0.0, s.cortisol) + 0.1 * Float.max(1.0, s.sharkSignal) + 0.05 * Float.max(0.0, s.cytokine) - 0.03);
    // CONNECTION
    strengths[5] := Float.max(1.0, strengths[5] + 0.06 * Float.max(1.0, s.entangla) + 0.05 * Float.max(0.0, s.oxytocin) + 0.04 * Float.max(1.0, s.dolphin) - 0.002);
    // EXPRESSION
    strengths[6] := Float.max(1.0, strengths[6] + 0.04 * (s.patentCount : Int).toFloat() * 0.001 + 0.02 * (s.formaCapital / 5000.0) - 0.003);
  };

  // Select dominant drive based on strength * Q-value
  // Returns drive index 0-6, or 7 (ACTION_REST) if all within 0.1
  public func selectDominant(strengths : [Float], qValues : [Float]) : Nat {
    let n = Nat.min(strengths.size(), qValues.size());
    if (n == 0) return 1; // default SOVEREIGNTY
    // Check if all within 0.1 of each other -> REST
    var minS : Float = strengths[0];
    var maxS : Float = strengths[0];
    var i0 : Nat = 1;
    while (i0 < n) {
      if (strengths[i0] < minS) minS := strengths[i0];
      if (strengths[i0] > maxS) maxS := strengths[i0];
      i0 += 1;
    };
    if (maxS - minS < 0.1) return ACTION_REST;
    // Winner = argmax(strength * qValue)
    var bestIdx : Nat = 0;
    var bestScore : Float = strengths[0] * qValues[0];
    var i1 : Nat = 1;
    while (i1 < n) {
      let score = strengths[i1] * qValues[i1];
      if (score > bestScore) {
        bestScore := score;
        bestIdx := i1;
      };
      i1 += 1;
    };
    bestIdx
  };

  // Q-learning update
  public func updateQValues(qValues : [var Float], lastAction : Nat, reward : Float) {
    if (lastAction < qValues.size()) {
      qValues[lastAction] := Float.max(1.0, qValues[lastAction] + 0.01 * (reward - qValues[lastAction]));
    };
  };

  // Compute RL reward signal
  public func computeReward(formaDelta : Float, patentDelta : Nat, coherenceDelta : Float) : Float {
    formaDelta + (patentDelta : Int).toFloat() * 10.0 + coherenceDelta * 100.0
  };

};
