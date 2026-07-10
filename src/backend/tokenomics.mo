// tokenomics.mo — Measurement & Benchmarking Framework (Section 15)
// Classification: SOVEREIGN_CORE
//
// On-chain implementation of the Tokenomics measurement layer.
// Provides canister-callable functions for:
//   1. Token Value Function (TV)
//   2. Cognitive Return Per Token (CRPT)
//   3. Salience Scoring & Budget Allocation
//   4. Compression Efficiency (CE/CEF)
//   5. Benchmark Scoring & Tokenomic Gain
//   6. Runtime Measurement Loop State
//
// MEDINA-ARTIFACT (4 layers):
//
// LAYER 1 — MEANING:
//   "Every token emitted by this organism is measured. Not by length,
//    but by cognitive value contributed. The system does not optimize for
//    fewer tokens — it optimizes for higher-value tokens."
//
// LAYER 2 — MODEL: TokenValueScore, CRPTResult, SalienceScore, CompressionResult, BenchmarkScore
//
// LAYER 3 — COMPUTATION:
//   TV(t) = w_d*D + w_a*A + w_r*R + w_c*C + w_m*M - w_n*N
//   CRPT = CR / (PromptTokens + OutputTokens)
//   S_i = α*U + β*R + γ*M + δ*T + ε*N - ζ*K
//   B_i = B_total * (S_i / ΣS)
//   CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
//   TokenomicGain = Score_B/Tokens_B - Score_A/Tokens_A
//
// LAYER 4 — EXECUTION:
//   MODULE: Tokenomics
//   FUNCTIONS: computeTokenValue, computeCRPT, scoreSalience, allocateBudget,
//              computeCompression, computeBenchmarkScore, computeTokenomicGain
//
// PYTHAGORAS: all default weights are phi-derived harmonics
// EUCLID:     all constants imported from phi.mo — single source of truth
// CONFUCIUS:  right relationship — measures what matters, penalizes what doesn't

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Task classification for benchmark and budget allocation.
  public type TaskClass = {
    #InvoiceExecution;
    #Estimating;
    #CashflowDecision;
    #ProposalGeneration;
    #ResearchSynthesis;
    #ArchitectureDesign;
    #RedTeamReview;
    #MemoryConsolidation;
  };

  /// Risk level determines budget multiplier.
  public type TaskRisk = {
    #Low;
    #Medium;
    #High;
    #Critical;
  };

  /// Weights for Token Value Function (phi-derived defaults).
  public type TokenValueWeights = {
    wDecision : Float;
    wAction : Float;
    wRisk : Float;
    wCompression : Float;
    wMemory : Float;
    wNoise : Float;
  };

  /// Result of Token Value computation.
  public type TokenValueResult = {
    decisionQuality : Float;
    actionUsefulness : Float;
    riskReduction : Float;
    compressionContribution : Float;
    memoryReuseValue : Float;
    noiseWaste : Float;
    tokenValue : Float;
  };

  /// Cognitive Return scored across five categories [0, 5] each.
  public type CognitiveReturnScore = {
    decisionQuality : Float;
    actionability : Float;
    riskControl : Float;
    reuseValue : Float;
    learningGain : Float;
  };

  /// CRPT measurement result.
  public type CRPTResult = {
    cognitiveReturn : Float;
    promptTokens : Nat;
    outputTokens : Nat;
    totalTokens : Nat;
    crpt : Float;
  };

  /// Input for salience scoring.
  public type SalienceItem = {
    itemId : Text;
    label : Text;
    urgency : Float;
    risk : Float;
    missionRelevance : Float;
    timeSensitivity : Float;
    novelty : Float;
    knownContext : Float;
  };

  /// Weights for salience equation (Greek letter coefficients).
  public type SalienceWeights = {
    alpha : Float;
    beta : Float;
    gamma : Float;
    delta : Float;
    epsilon : Float;
    zeta : Float;
  };

  /// Result of salience scoring with allocated budget.
  public type SalienceResult = {
    itemId : Text;
    label : Text;
    salienceScore : Float;
    allocatedBudget : Nat;
  };

  /// Compression efficiency measurement.
  public type CompressionResult = {
    informationRetained : Float;
    actionClarity : Float;
    riskPreserved : Float;
    outputTokens : Nat;
    ce : Float;
    cef : Float;
  };

  /// Benchmark score for a single task.
  public type BenchmarkScore = {
    taskClass : TaskClass;
    decisionQuality : Float;
    actionability : Float;
    riskControl : Float;
    reuseValue : Float;
    accuracy : Float;
    waste : Float;
    tokensUsed : Nat;
  };

  /// Tokenomic gain comparison result.
  public type TokenomicGainResult = {
    scoreA : Float;
    tokensA : Nat;
    scoreB : Float;
    tokensB : Nat;
    sptA : Float;
    sptB : Float;
    tokenomicGain : Float;
    isSuperior : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT WEIGHTS (phi-derived)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default Token Value weights — phi harmonics.
  public func defaultTokenValueWeights() : TokenValueWeights {
    {
      wDecision = Phi.PHI_INV;
      wAction = Phi.PHI_INV;
      wRisk = Phi.PHI_INV_2;
      wCompression = Phi.PHI_INV_3;
      wMemory = Phi.PHI_INV_3;
      wNoise = Phi.PHI_INV;
    }
  };

  /// Default salience weights — phi harmonics.
  public func defaultSalienceWeights() : SalienceWeights {
    {
      alpha = Phi.PHI_INV;
      beta = Phi.PHI_INV;
      gamma = Phi.PHI_INV_2;
      delta = Phi.PHI_INV_2;
      epsilon = Phi.PHI_INV_3;
      zeta = Phi.PHI_INV;
    }
  };

  /// Risk-based budget multiplier.
  public func riskMultiplier(risk : TaskRisk) : Float {
    switch (risk) {
      case (#Low) { Phi.PHI_INV_3 };       // 0.236 — tight
      case (#Medium) { Phi.PHI_INV };       // 0.618 — moderate
      case (#High) { 1.0 };                 // full
      case (#Critical) { Phi.PHI };         // 1.618 — expanded
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.1 TOKEN VALUE FUNCTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compute Token Value: TV(t) = w_d*D + w_a*A + w_r*R + w_c*C + w_m*M - w_n*N
  public func computeTokenValue(
    decisionQuality : Float,
    actionUsefulness : Float,
    riskReduction : Float,
    compressionContribution : Float,
    memoryReuseValue : Float,
    noiseWaste : Float,
    weights : TokenValueWeights,
  ) : TokenValueResult {
    let tv : Float =
      weights.wDecision * decisionQuality +
      weights.wAction * actionUsefulness +
      weights.wRisk * riskReduction +
      weights.wCompression * compressionContribution +
      weights.wMemory * memoryReuseValue -
      weights.wNoise * noiseWaste;

    {
      decisionQuality;
      actionUsefulness;
      riskReduction;
      compressionContribution;
      memoryReuseValue;
      noiseWaste;
      tokenValue = tv;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.2 COGNITIVE RETURN PER TOKEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total cognitive return from a score.
  public func cognitiveReturnTotal(score : CognitiveReturnScore) : Float {
    score.decisionQuality +
    score.actionability +
    score.riskControl +
    score.reuseValue +
    score.learningGain
  };

  /// Compute CRPT = CR / (PromptTokens + OutputTokens)
  public func computeCRPT(
    score : CognitiveReturnScore,
    promptTokens : Nat,
    outputTokens : Nat,
  ) : CRPTResult {
    let totalTokens = promptTokens + outputTokens;
    let cr = cognitiveReturnTotal(score);
    let crpt : Float = if (totalTokens > 0) {
      cr / Float.fromInt(totalTokens)
    } else { 0.0 };

    {
      cognitiveReturn = cr;
      promptTokens;
      outputTokens;
      totalTokens;
      crpt;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.3 SALIENCE SCORING & BUDGET ALLOCATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score a single salience item: S_i = α*U + β*R + γ*M + δ*T + ε*N - ζ*K
  public func scoreSalience(item : SalienceItem, weights : SalienceWeights) : Float {
    weights.alpha * item.urgency +
    weights.beta * item.risk +
    weights.gamma * item.missionRelevance +
    weights.delta * item.timeSensitivity +
    weights.epsilon * item.novelty -
    weights.zeta * item.knownContext
  };

  /// Allocate budget proportionally: B_i = B_total * (S_i / ΣS)
  public func allocateBudget(
    items : [SalienceItem],
    totalBudget : Nat,
    weights : SalienceWeights,
  ) : [SalienceResult] {
    if (items.size() == 0) { return [] };

    // Score all items (floor at 0)
    let scores = Array.map<SalienceItem, Float>(items, func(item) {
      let s = scoreSalience(item, weights);
      if (s > 0.0) { s } else { 0.0 }
    });

    // Total salience
    var totalSalience : Float = 0.0;
    for (s in scores.vals()) { totalSalience += s };

    // Allocate
    Array.tabulate<SalienceResult>(items.size(), func(i) {
      let budget : Nat = if (totalSalience > 0.0) {
        Int.abs(Float.toInt(Float.fromInt(totalBudget) * (scores[i] / totalSalience)))
      } else { 0 };

      {
        itemId = items[i].itemId;
        label = items[i].label;
        salienceScore = scores[i];
        allocatedBudget = budget;
      }
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.4 COMPRESSION EFFICIENCY
  // ═══════════════════════════════════════════════════════════════════════════

  /// CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
  public func computeCompression(
    informationRetained : Float,
    actionClarity : Float,
    riskPreserved : Float,
    outputTokens : Nat,
  ) : CompressionResult {
    let tokensFloat = Float.fromInt(outputTokens);
    let meaningPreserved = (informationRetained + actionClarity + riskPreserved) / 3.0;
    let ce : Float = if (outputTokens > 0) { meaningPreserved / tokensFloat } else { 0.0 };
    let cef : Float = if (outputTokens > 0) {
      (informationRetained + actionClarity + riskPreserved) / tokensFloat
    } else { 0.0 };

    {
      informationRetained;
      actionClarity;
      riskPreserved;
      outputTokens;
      ce;
      cef;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.5 BENCHMARK SCORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score = DQ + ACT + RISK + REUSE + ACCURACY - WASTE
  public func computeBenchmarkScore(s : BenchmarkScore) : Float {
    s.decisionQuality + s.actionability + s.riskControl +
    s.reuseValue + s.accuracy - s.waste
  };

  /// Score per token for a benchmark.
  public func benchmarkScorePerToken(s : BenchmarkScore) : Float {
    if (s.tokensUsed == 0) { return 0.0 };
    computeBenchmarkScore(s) / Float.fromInt(s.tokensUsed)
  };

  /// TokenomicGain = SPT_B - SPT_A — positive means tokenomic system wins.
  public func computeTokenomicGain(
    scoreA : BenchmarkScore,
    scoreB : BenchmarkScore,
  ) : TokenomicGainResult {
    let sptA = benchmarkScorePerToken(scoreA);
    let sptB = benchmarkScorePerToken(scoreB);
    let gain = sptB - sptA;

    {
      scoreA = computeBenchmarkScore(scoreA);
      tokensA = scoreA.tokensUsed;
      scoreB = computeBenchmarkScore(scoreB);
      tokensB = scoreB.tokensUsed;
      sptA;
      sptB;
      tokenomicGain = gain;
      isSuperior = (gain > 0.0);
    }
  };
}
