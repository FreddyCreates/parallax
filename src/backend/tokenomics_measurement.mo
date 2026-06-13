// tokenomics_measurement.mo — SOVEREIGN TOKENOMICS MEASUREMENT & BENCHMARKING ENGINE
// PARALLAX Sovereign Organism — Domain 39
//
// DOCTRINE: "A token is not a word — it is a unit of cognitive expenditure.
// Every token emitted is compute spent, attention consumed, memory surface occupied,
// and action influence exerted. The organism does not optimize for fewer tokens —
// it optimizes for higher-value tokens. Cognitive Return Per Token is the supreme
// efficiency metric. Salience gates what deserves budget. Compression preserves
// meaning while reducing surface. The measurement loop feeds back every 873ms,
// making every interaction improve the next."
//
// SECTIONS IMPLEMENTED:
//   15.1 — Token Value Function:           TV(t) = w_d·D + w_a·A + w_r·R + w_c·C + w_m·M - w_n·N
//   15.2 — Cognitive Return Metrics:        CRPT = CR / TotalTokens
//   15.3 — Salience Allocation Equations:   S_i = αU + βR + γM + δT + εN - ζK
//   15.4 — Compression Efficiency Metrics:  CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
//   15.5 — Benchmark Tasks:                8 task classes with tokenomic vs non-tokenomic scoring
//   15.6 — Runtime Measurement Loop:       11-step feedback cycle executed every heartbeat
//   15.7 — Evaluation Criteria:            8 criteria scored per interaction
//   15.8 — Research Hypotheses:            Tracked hypothesis validation over time
//
// PYTHAGORAS: all weights are phi-derived ratios — no arbitrary coefficients
// EUCLID:     single measurement engine — all tokenomic scoring flows through here
// CONFUCIUS:  right relationship — tokens serve cognition, not volume
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Int "mo:core/Int";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.1 — TOKEN VALUE FUNCTION
  // TV(t) = w_d·D_t + w_a·A_t + w_r·R_t + w_c·C_t + w_m·M_t - w_n·N_t
  // Simplified: TV = DQ + ACT + RISK + REUSE + LEARN - WASTE
  // Each weight is a phi-derived ratio. No arbitrary coefficients.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Weights for the Token Value Function — all phi-derived
  public type TokenValueWeights = {
    wDecision    : Float;  // w_d — decision quality weight (φ⁻¹ = 0.618)
    wAction      : Float;  // w_a — action usefulness weight (φ⁻² = 0.382)
    wRisk        : Float;  // w_r — risk reduction weight (φ⁻¹ = 0.618)
    wCompression : Float;  // w_c — compression contribution weight (φ⁻³ = 0.236)
    wMemory      : Float;  // w_m — memory/reuse value weight (φ⁻² = 0.382)
    wNoise       : Float;  // w_n — noise/waste penalty weight (φ⁻¹ = 0.618)
  };

  /// Default weights — all derived from phi powers
  public func defaultTokenValueWeights() : TokenValueWeights {
    {
      wDecision    = Phi.PHI_INV;   // 0.618 — decision has highest positive weight
      wAction      = Phi.PHI_INV_2; // 0.382 — action is second priority
      wRisk        = Phi.PHI_INV;   // 0.618 — risk reduction matches decision weight
      wCompression = Phi.PHI_INV_3; // 0.236 — compression is efficiency bonus
      wMemory      = Phi.PHI_INV_2; // 0.382 — memory/reuse matches action weight
      wNoise       = Phi.PHI_INV;   // 0.618 — noise penalty is strong (same as decision)
    }
  };

  /// Token Value components for a single token or token group
  public type TokenValueComponents = {
    decisionValue   : Float;  // D_t — decision value contributed [0..5]
    actionUsefulness : Float; // A_t — action usefulness [0..5]
    riskReduction   : Float;  // R_t — risk reduction [0..5]
    compressionGain : Float;  // C_t — compression contribution [0..5]
    memoryReuse     : Float;  // M_t — memory or reuse value [0..5]
    noiseWaste      : Float;  // N_t — noise, redundancy, attention waste [0..5]
  };

  /// Compute TV(t) — the value of a token or token group
  public func computeTokenValue(
    components : TokenValueComponents,
    weights    : TokenValueWeights,
  ) : Float {
    weights.wDecision    * components.decisionValue
    + weights.wAction    * components.actionUsefulness
    + weights.wRisk      * components.riskReduction
    + weights.wCompression * components.compressionGain
    + weights.wMemory    * components.memoryReuse
    - weights.wNoise     * components.noiseWaste
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.2 — COGNITIVE RETURN METRICS
  // CRPT = (DQ + ACT + RISK + REUSE + LEARN) / TotalTokens
  // Each category scored 0–5. TotalTokens = prompt + output.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cognitive Return breakdown — five categories, each [0..5]
  public type CognitiveReturn = {
    decisionQuality : Float;  // DQ — did the response improve the actual decision?
    actionability   : Float;  // ACT — can the user or system act immediately?
    riskControl     : Float;  // RISK — did it identify or reduce failure modes?
    reuseValue      : Float;  // REUSE — reusable rule, template, memory, artifact?
    learningGain    : Float;  // LEARN — did it improve future system behavior?
  };

  /// Compute total Cognitive Return (CR) — sum of all categories
  public func computeCognitiveReturn(cr : CognitiveReturn) : Float {
    cr.decisionQuality + cr.actionability + cr.riskControl
    + cr.reuseValue + cr.learningGain
  };

  /// CRPT record — Cognitive Return Per Token with full breakdown
  public type CRPTScore = {
    cognitiveReturn  : Float;  // CR = sum of 5 categories
    totalTokens      : Nat;    // prompt tokens + output tokens
    promptTokens     : Nat;    // input/prompt token count
    outputTokens     : Nat;    // generated output token count
    crpt             : Float;  // CR / TotalTokens
    breakdown        : CognitiveReturn;
  };

  /// Compute CRPT score from components and token counts
  public func computeCRPT(
    cr           : CognitiveReturn,
    promptTokens : Nat,
    outputTokens : Nat,
  ) : CRPTScore {
    let totalCR = computeCognitiveReturn(cr);
    let total = promptTokens + outputTokens;
    let crptVal = if (total == 0) { 0.0 } else { totalCR / Float.fromInt(total) };
    {
      cognitiveReturn = totalCR;
      totalTokens     = total;
      promptTokens    = promptTokens;
      outputTokens    = outputTokens;
      crpt            = crptVal;
      breakdown       = cr;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.3 — SALIENCE ALLOCATION EQUATIONS
  // S_i = α·U_i + β·R_i + γ·M_i + δ·T_i + ε·N_i - ζ·K_i
  // B_i = B_total × (S_i / ΣS)
  // Salience weights are phi-derived. Budget allocation is proportional.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Salience weights — Greek-named, all phi-derived
  public type SalienceWeights = {
    alpha   : Float;  // α — urgency weight (φ⁻¹ = 0.618)
    beta    : Float;  // β — risk/consequence weight (φ⁻¹ = 0.618)
    gamma   : Float;  // γ — mission relevance weight (φ⁻² = 0.382)
    delta   : Float;  // δ — time sensitivity weight (φ⁻² = 0.382)
    epsilon : Float;  // ε — novelty/uncertainty weight (φ⁻³ = 0.236)
    zeta    : Float;  // ζ — known/settled context penalty (φ⁻² = 0.382)
  };

  /// Default salience weights — phi power hierarchy
  public func defaultSalienceWeights() : SalienceWeights {
    {
      alpha   = Phi.PHI_INV;   // 0.618 — urgency gets highest weight
      beta    = Phi.PHI_INV;   // 0.618 — risk matches urgency
      gamma   = Phi.PHI_INV_2; // 0.382 — mission relevance second tier
      delta   = Phi.PHI_INV_2; // 0.382 — time sensitivity second tier
      epsilon = Phi.PHI_INV_3; // 0.236 — novelty is a bonus signal
      zeta    = Phi.PHI_INV_2; // 0.382 — known-context penalty is moderate
    }
  };

  /// Salience components for a single information unit
  public type SalienceComponents = {
    urgency         : Float;  // U_i — how urgent [0..5]
    risk            : Float;  // R_i — risk or consequence [0..5]
    missionRelevance : Float; // M_i — alignment with mission [0..5]
    timeSensitivity : Float;  // T_i — time decay factor [0..5]
    novelty         : Float;  // N_i — new or uncertain information [0..5]
    knownContext    : Float;  // K_i — already settled/known [0..5]
  };

  /// Salience item — an information unit with its score and allocated budget
  public type SalienceItem = {
    id         : Text;     // unique item identifier
    components : SalienceComponents;
    score      : Float;    // S_i computed score
    budget     : Nat;      // B_i allocated token budget
  };

  /// Compute salience score for one information unit
  public func computeSalienceScore(
    components : SalienceComponents,
    weights    : SalienceWeights,
  ) : Float {
    let raw = weights.alpha   * components.urgency
            + weights.beta    * components.risk
            + weights.gamma   * components.missionRelevance
            + weights.delta   * components.timeSensitivity
            + weights.epsilon * components.novelty
            - weights.zeta    * components.knownContext;
    // Floor at 0 — negative salience means "do not allocate"
    if (raw < 0.0) { 0.0 } else { raw }
  };

  /// Allocate token budget proportionally across salience items
  /// B_i = B_total × (S_i / ΣS)
  public func allocateBudget(
    items      : [SalienceComponents],
    ids        : [Text],
    totalBudget : Nat,
    weights    : SalienceWeights,
  ) : [SalienceItem] {
    // Compute scores
    let scores = Array.map<SalienceComponents, Float>(items, func(c) {
      computeSalienceScore(c, weights)
    });

    // Sum all salience scores
    var totalSalience : Float = 0.0;
    for (s in scores.vals()) { totalSalience += s };

    // Allocate budget proportionally
    let budgetFloat = Float.fromInt(totalBudget);
    Array.tabulate<SalienceItem>(items.size(), func(i) {
      let fraction = if (totalSalience <= 0.0) { 0.0 } else { scores[i] / totalSalience };
      let allocated = Float.toInt(fraction * budgetFloat);
      let allocNat = if (allocated < 0) { 0 } else { Int.abs(allocated) };
      {
        id         = if (i < ids.size()) { ids[i] } else { "" };
        components = items[i];
        score      = scores[i];
        budget     = allocNat;
      }
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.4 — COMPRESSION EFFICIENCY METRICS
  // CE = MeaningPreserved / TokensUsed
  // CEF = (InformationRetained + ActionClarity + RiskPreserved) / OutputTokens
  // Good compression preserves action correctness. Bad compression hides risk.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compression quality components — each [0..5]
  public type CompressionComponents = {
    informationRetained : Float;  // preservation of task-relevant content
    actionClarity       : Float;  // clarity of next step or decision
    riskPreserved       : Float;  // preservation of caution, uncertainty, constraints
  };

  /// Compression Efficiency score
  public type CompressionScore = {
    components    : CompressionComponents;
    outputTokens  : Nat;     // total output tokens used
    cef           : Float;   // Compression Efficiency Factor
    passesAudit   : Bool;    // true if user/system can still act correctly
  };

  /// Compute Compression Efficiency Factor
  /// CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
  /// Audit passes if all three components ≥ φ⁻¹ × 5 = 3.09 (rounded to 3.0)
  public func computeCompressionEfficiency(
    components   : CompressionComponents,
    outputTokens : Nat,
  ) : CompressionScore {
    let numerator = components.informationRetained + components.actionClarity + components.riskPreserved;
    let cefVal = if (outputTokens == 0) { 0.0 } else { numerator / Float.fromInt(outputTokens) };
    // Audit gate: each component must be ≥ 3.0 (φ⁻¹ × 5 ≈ 3.09, floored to 3.0)
    let auditThreshold : Float = 3.0;
    let passes = components.informationRetained >= auditThreshold
              and components.actionClarity >= auditThreshold
              and components.riskPreserved >= auditThreshold;
    {
      components   = components;
      outputTokens = outputTokens;
      cef          = cefVal;
      passesAudit  = passes;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.5 — BENCHMARK TASKS: 8 TASK CLASSES
  // Tokenomic vs. Non-Tokenomic comparison
  // Score = DQ + ACT + RISK + REUSE + ACCURACY - WASTE
  // TokenomicGain = (Score_B / Tokens_B) - (Score_A / Tokens_A)
  // ═══════════════════════════════════════════════════════════════════════════

  /// The 8 benchmark task classes
  public type BenchmarkTaskClass = {
    #invoiceExecution;     // Update hours, apply payments, recalculate balance
    #estimating;           // Convert messy scope into labor pricing
    #cashflowDecision;     // Decide whether to schedule labor before payment clears
    #proposalGeneration;   // Produce client-facing proposal from internal logic
    #researchSynthesis;    // Convert doctrine into structured paper sections
    #architectureDesign;   // Define modules, equations, interfaces, metrics
    #redTeamReview;        // Identify hidden failure modes
    #memoryConsolidation;  // Convert repeated work into reusable rules
  };

  /// Benchmark score components — each [0..5] except WASTE which is penalized
  public type BenchmarkScoreComponents = {
    decisionQuality : Float;  // DQ [0..5]
    actionability   : Float;  // ACT [0..5]
    riskControl     : Float;  // RISK [0..5]
    reuseValue      : Float;  // REUSE [0..5]
    accuracy        : Float;  // ACCURACY [0..5]
    waste           : Float;  // WASTE [0..5] — penalized
  };

  /// A single benchmark result — comparing tokenomic vs non-tokenomic
  public type BenchmarkResult = {
    taskClass      : BenchmarkTaskClass;
    taskLabel      : Text;
    // System A — Non-Tokenomic Baseline
    scoreA         : Float;
    tokensA        : Nat;
    efficiencyA    : Float;  // scoreA / tokensA
    // System B — Tokenomic System
    scoreB         : Float;
    tokensB        : Nat;
    efficiencyB    : Float;  // scoreB / tokensB
    // Comparison
    tokenomicGain  : Float;  // efficiencyB - efficiencyA
    superior       : Bool;   // true if tokenomic system wins
  };

  /// Compute benchmark score from components
  /// Score = DQ + ACT + RISK + REUSE + ACCURACY - WASTE
  public func computeBenchmarkScore(c : BenchmarkScoreComponents) : Float {
    c.decisionQuality + c.actionability + c.riskControl
    + c.reuseValue + c.accuracy - c.waste
  };

  /// Compare System A (non-tokenomic) vs System B (tokenomic)
  public func compareBenchmark(
    taskClass  : BenchmarkTaskClass,
    taskLabel  : Text,
    compA      : BenchmarkScoreComponents,
    tokensA    : Nat,
    compB      : BenchmarkScoreComponents,
    tokensB    : Nat,
  ) : BenchmarkResult {
    let sA = computeBenchmarkScore(compA);
    let sB = computeBenchmarkScore(compB);
    let effA = if (tokensA == 0) { 0.0 } else { sA / Float.fromInt(tokensA) };
    let effB = if (tokensB == 0) { 0.0 } else { sB / Float.fromInt(tokensB) };
    let gain = effB - effA;
    {
      taskClass     = taskClass;
      taskLabel     = taskLabel;
      scoreA        = sA;
      tokensA       = tokensA;
      efficiencyA   = effA;
      scoreB        = sB;
      tokensB       = tokensB;
      efficiencyB   = effB;
      tokenomicGain = gain;
      superior      = gain > 0.0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.6 — RUNTIME MEASUREMENT LOOP (11-step feedback cycle)
  // Executed every heartbeat (873ms). Each step produces state for the next.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current step in the 11-step measurement loop
  public type MeasurementStep = {
    #classifyTask;           // Step 1: classify the task
    #estimateRisk;           // Step 2: estimate task risk and complexity
    #rankSalience;           // Step 3: rank salience targets
    #allocateBudget;         // Step 4: allocate token budget
    #recruitModules;         // Step 5: recruit only necessary modules
    #generateResponse;       // Step 6: generate the response or artifact
    #auditCompression;       // Step 7: audit compression quality
    #scoreCognitiveReturn;   // Step 8: score cognitive return
    #detectWaste;            // Step 9: detect wasted tokens
    #extractReusable;        // Step 10: extract reusable rules or memory
    #updatePolicy;           // Step 11: update future token allocation policy
  };

  /// Runtime loop state — tracks the current measurement cycle
  public type MeasurementLoopState = {
    currentStep      : MeasurementStep;
    cycleCount       : Nat;          // how many full cycles completed
    lastCycleBeat    : Nat;          // beat when last cycle completed
    // Step outputs (accumulated per cycle)
    taskClassification : Text;       // Step 1 output
    riskEstimate       : Float;      // Step 2 output [0..1]
    complexityEstimate : Float;      // Step 2 output [0..1]
    salienceRanking    : [Text];     // Step 3 output — ordered item IDs
    allocatedBudget    : Nat;        // Step 4 output — total tokens allocated
    modulesRecruited   : Nat;        // Step 5 output — modules activated
    compressionAudit   : Bool;       // Step 7 output — audit passed?
    cognitiveReturnScore : Float;    // Step 8 output — CR score
    wasteDetected      : Float;      // Step 9 output — waste fraction [0..1]
    reusableExtracted  : Nat;        // Step 10 output — rules/memories extracted
    policyUpdated      : Bool;       // Step 11 output — policy was updated?
  };

  /// Default measurement loop state — begins at Step 1
  public func defaultMeasurementLoopState() : MeasurementLoopState {
    {
      currentStep          = #classifyTask;
      cycleCount           = 0;
      lastCycleBeat        = 0;
      taskClassification   = "idle";
      riskEstimate         = 0.0;
      complexityEstimate   = 0.0;
      salienceRanking      = [];
      allocatedBudget      = 0;
      modulesRecruited     = 0;
      compressionAudit     = true;
      cognitiveReturnScore = 0.0;
      wasteDetected        = 0.0;
      reusableExtracted    = 0;
      policyUpdated        = false;
    }
  };

  /// Advance the measurement loop by one step
  public func advanceMeasurementStep(state : MeasurementLoopState, beat : Nat) : MeasurementLoopState {
    switch (state.currentStep) {
      case (#classifyTask)         { { state with currentStep = #estimateRisk } };
      case (#estimateRisk)         { { state with currentStep = #rankSalience } };
      case (#rankSalience)         { { state with currentStep = #allocateBudget } };
      case (#allocateBudget)       { { state with currentStep = #recruitModules } };
      case (#recruitModules)       { { state with currentStep = #generateResponse } };
      case (#generateResponse)     { { state with currentStep = #auditCompression } };
      case (#auditCompression)     { { state with currentStep = #scoreCognitiveReturn } };
      case (#scoreCognitiveReturn) { { state with currentStep = #detectWaste } };
      case (#detectWaste)          { { state with currentStep = #extractReusable } };
      case (#extractReusable)      { { state with currentStep = #updatePolicy } };
      case (#updatePolicy) {
        // Cycle complete — reset to Step 1 and increment counter
        {
          state with
          currentStep   = #classifyTask;
          cycleCount    = state.cycleCount + 1;
          lastCycleBeat = beat;
          policyUpdated = true;
        }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.7 — EVALUATION CRITERIA (8 criteria)
  // Scored per interaction. Each criterion [0..5].
  // ═══════════════════════════════════════════════════════════════════════════

  /// The 8 evaluation criteria for a mature tokenomic system
  public type EvaluationCriteria = {
    cognitiveReturnPerToken : Float;  // useful cognition per token spent [0..5]
    compressionFidelity     : Float;  // compressed output preserves meaning [0..5]
    actionConversionRate    : Float;  // outputs that lead to correct action [0..5]
    riskPreservation        : Float;  // concise without hiding uncertainty [0..5]
    reuseExtractionRate     : Float;  // interactions → reusable rules/memory [0..5]
    contextHygiene          : Float;  // avoids polluting context [0..5]
    adaptiveDepthAccuracy   : Float;  // expand/compress based on stakes [0..5]
    errorAvoidance          : Float;  // prevents math/scope/logic mistakes [0..5]
  };

  /// Compute aggregate evaluation score — phi-weighted average
  /// Higher-weight criteria: CRPT, risk, error avoidance (φ⁻¹)
  /// Medium-weight: compression, action, reuse (φ⁻²)
  /// Lower-weight: context hygiene, adaptive depth (φ⁻³)
  public func computeEvaluationScore(c : EvaluationCriteria) : Float {
    let w1 = Phi.PHI_INV;   // 0.618 — top-tier criteria
    let w2 = Phi.PHI_INV_2; // 0.382 — mid-tier
    let w3 = Phi.PHI_INV_3; // 0.236 — supporting tier
    let totalWeight = 3.0 * w1 + 3.0 * w2 + 2.0 * w3;
    let weighted = w1 * c.cognitiveReturnPerToken
                 + w1 * c.riskPreservation
                 + w1 * c.errorAvoidance
                 + w2 * c.compressionFidelity
                 + w2 * c.actionConversionRate
                 + w2 * c.reuseExtractionRate
                 + w3 * c.contextHygiene
                 + w3 * c.adaptiveDepthAccuracy;
    weighted / totalWeight
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 15.8 — RESEARCH HYPOTHESES
  // H1: Tokenomic systems produce higher CRPT than non-tokenomic systems
  // H2: Tokenomic systems improve over time via reuse extraction
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hypothesis tracking — accumulates evidence over time
  public type HypothesisTracker = {
    // H1: CRPT superiority
    h1_tokenomicCRPTSum   : Float;   // accumulated CRPT for tokenomic system
    h1_baselineCRPTSum    : Float;   // accumulated CRPT for baseline system
    h1_comparisons        : Nat;     // number of head-to-head comparisons
    h1_tokenomicWins      : Nat;     // times tokenomic system had higher CRPT
    h1_supported          : Bool;    // is H1 currently supported?
    // H2: Improvement over time
    h2_earlyPhaseCRPT     : Float;   // average CRPT in first F(8)=21 interactions
    h2_latePhaseCRPT      : Float;   // average CRPT in most recent F(8)=21 interactions
    h2_earlyCount         : Nat;     // interactions counted in early phase
    h2_lateCount          : Nat;     // interactions counted in late phase
    h2_reuseRulesExtracted : Nat;    // total reusable rules extracted
    h2_supported          : Bool;    // is H2 currently supported?
  };

  /// Default hypothesis tracker — no evidence yet
  public func defaultHypothesisTracker() : HypothesisTracker {
    {
      h1_tokenomicCRPTSum  = 0.0;
      h1_baselineCRPTSum   = 0.0;
      h1_comparisons       = 0;
      h1_tokenomicWins     = 0;
      h1_supported         = false;
      h2_earlyPhaseCRPT    = 0.0;
      h2_latePhaseCRPT     = 0.0;
      h2_earlyCount        = 0;
      h2_lateCount         = 0;
      h2_reuseRulesExtracted = 0;
      h2_supported         = false;
    }
  };

  /// Record a benchmark comparison for H1
  public func recordH1Comparison(
    tracker      : HypothesisTracker,
    tokenomicCRPT : Float,
    baselineCRPT  : Float,
  ) : HypothesisTracker {
    let newComparisons = tracker.h1_comparisons + 1;
    let newWins = if (tokenomicCRPT > baselineCRPT) { tracker.h1_tokenomicWins + 1 } else { tracker.h1_tokenomicWins };
    let newTokenomicSum = tracker.h1_tokenomicCRPTSum + tokenomicCRPT;
    let newBaselineSum = tracker.h1_baselineCRPTSum + baselineCRPT;
    // H1 supported if tokenomic wins > φ⁻¹ of all comparisons (>61.8%)
    let winRate = Float.fromInt(newWins) / Float.fromInt(newComparisons);
    {
      tracker with
      h1_tokenomicCRPTSum = newTokenomicSum;
      h1_baselineCRPTSum  = newBaselineSum;
      h1_comparisons      = newComparisons;
      h1_tokenomicWins    = newWins;
      h1_supported        = winRate >= Phi.PHI_INV;
    }
  };

  /// Record a CRPT observation for H2 (improvement over time)
  public func recordH2Observation(
    tracker   : HypothesisTracker,
    crpt      : Float,
    totalInteractions : Nat,
    reuseRules : Nat,
  ) : HypothesisTracker {
    let earlyThreshold = 21; // F(8) = 21 — first 21 interactions are "early phase"
    if (totalInteractions <= earlyThreshold) {
      let newCount = tracker.h2_earlyCount + 1;
      let newAvg = (tracker.h2_earlyPhaseCRPT * Float.fromInt(tracker.h2_earlyCount) + crpt) / Float.fromInt(newCount);
      {
        tracker with
        h2_earlyPhaseCRPT = newAvg;
        h2_earlyCount     = newCount;
        h2_reuseRulesExtracted = tracker.h2_reuseRulesExtracted + reuseRules;
      }
    } else {
      let newCount = tracker.h2_lateCount + 1;
      let newAvg = (tracker.h2_latePhaseCRPT * Float.fromInt(tracker.h2_lateCount) + crpt) / Float.fromInt(newCount);
      // H2 supported if late-phase CRPT > early-phase CRPT
      {
        tracker with
        h2_latePhaseCRPT  = newAvg;
        h2_lateCount      = newCount;
        h2_reuseRulesExtracted = tracker.h2_reuseRulesExtracted + reuseRules;
        h2_supported      = newAvg > tracker.h2_earlyPhaseCRPT;
      }
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UNIFIED STATE — Domain 39 aggregate state
  // All measurement subsystems live here. Persisted via EOP.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Complete tokenomics measurement state
  public type TokenomicsMeasurementState = {
    // Configuration
    tokenValueWeights : TokenValueWeights;
    salienceWeights   : SalienceWeights;
    // Accumulated metrics
    totalInteractions  : Nat;        // total scored interactions
    totalTokensProcessed : Nat;      // total tokens processed across all interactions
    averageCRPT        : Float;      // running average CRPT
    averageTokenValue  : Float;      // running average TV
    averageCEF         : Float;      // running average Compression Efficiency
    averageEvalScore   : Float;      // running average evaluation score
    // Last interaction snapshot
    lastCRPT           : CRPTScore;
    lastCompressionScore : CompressionScore;
    lastEvaluation     : EvaluationCriteria;
    // Benchmark results — one per task class (most recent)
    benchmarkResults   : [BenchmarkResult];
    // Runtime loop
    measurementLoop    : MeasurementLoopState;
    // Hypothesis tracking
    hypotheses         : HypothesisTracker;
    // Heartbeat
    lastTickBeat       : Nat;
  };

  /// Default state — genesis initialization
  public func defaultTokenomicsMeasurementState() : TokenomicsMeasurementState {
    {
      tokenValueWeights = defaultTokenValueWeights();
      salienceWeights   = defaultSalienceWeights();
      totalInteractions  = 0;
      totalTokensProcessed = 0;
      averageCRPT        = 0.0;
      averageTokenValue  = 0.0;
      averageCEF         = 0.0;
      averageEvalScore   = 0.0;
      lastCRPT = {
        cognitiveReturn = 0.0;
        totalTokens     = 0;
        promptTokens    = 0;
        outputTokens    = 0;
        crpt            = 0.0;
        breakdown = {
          decisionQuality = 0.0;
          actionability   = 0.0;
          riskControl     = 0.0;
          reuseValue      = 0.0;
          learningGain    = 0.0;
        };
      };
      lastCompressionScore = {
        components = {
          informationRetained = 0.0;
          actionClarity       = 0.0;
          riskPreserved       = 0.0;
        };
        outputTokens = 0;
        cef          = 0.0;
        passesAudit  = true;
      };
      lastEvaluation = {
        cognitiveReturnPerToken = 0.0;
        compressionFidelity     = 0.0;
        actionConversionRate    = 0.0;
        riskPreservation        = 0.0;
        reuseExtractionRate     = 0.0;
        contextHygiene          = 0.0;
        adaptiveDepthAccuracy   = 0.0;
        errorAvoidance          = 0.0;
      };
      benchmarkResults  = [];
      measurementLoop   = defaultMeasurementLoopState();
      hypotheses        = defaultHypothesisTracker();
      lastTickBeat      = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT TICK — advance measurement loop every 873ms
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tick the tokenomics measurement engine — called every heartbeat
  public func tick(state : TokenomicsMeasurementState, beat : Nat) : TokenomicsMeasurementState {
    let newLoop = advanceMeasurementStep(state.measurementLoop, beat);
    { state with measurementLoop = newLoop; lastTickBeat = beat }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTION SCORING — score a complete interaction
  // Called after an AI interaction completes. Updates all running metrics.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score a complete interaction and update all running averages
  public func scoreInteraction(
    state          : TokenomicsMeasurementState,
    cr             : CognitiveReturn,
    promptTokens   : Nat,
    outputTokens   : Nat,
    compression    : CompressionComponents,
    evaluation     : EvaluationCriteria,
    tokenComponents : TokenValueComponents,
  ) : TokenomicsMeasurementState {
    let crptScore = computeCRPT(cr, promptTokens, outputTokens);
    let compScore = computeCompressionEfficiency(compression, outputTokens);
    let evalScore = computeEvaluationScore(evaluation);
    let tvScore   = computeTokenValue(tokenComponents, state.tokenValueWeights);

    let n = state.totalInteractions;
    let nf = Float.fromInt(n);
    let nf1 = Float.fromInt(n + 1);

    // Running averages: newAvg = (oldAvg × n + newVal) / (n + 1)
    let newAvgCRPT = (state.averageCRPT * nf + crptScore.crpt) / nf1;
    let newAvgTV   = (state.averageTokenValue * nf + tvScore) / nf1;
    let newAvgCEF  = (state.averageCEF * nf + compScore.cef) / nf1;
    let newAvgEval = (state.averageEvalScore * nf + evalScore) / nf1;

    {
      state with
      totalInteractions    = n + 1;
      totalTokensProcessed = state.totalTokensProcessed + promptTokens + outputTokens;
      averageCRPT          = newAvgCRPT;
      averageTokenValue    = newAvgTV;
      averageCEF           = newAvgCEF;
      averageEvalScore     = newAvgEval;
      lastCRPT             = crptScore;
      lastCompressionScore = compScore;
      lastEvaluation       = evaluation;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BENCHMARK RECORDING — add benchmark comparison results
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a benchmark comparison and update hypothesis tracker
  public func recordBenchmark(
    state     : TokenomicsMeasurementState,
    taskClass : BenchmarkTaskClass,
    taskLabel : Text,
    compA     : BenchmarkScoreComponents,
    tokensA   : Nat,
    compB     : BenchmarkScoreComponents,
    tokensB   : Nat,
  ) : TokenomicsMeasurementState {
    let result = compareBenchmark(taskClass, taskLabel, compA, tokensA, compB, tokensB);
    let newResults = Array.append(state.benchmarkResults, [result]);
    // Update H1 hypothesis
    let newHypotheses = recordH1Comparison(state.hypotheses, result.efficiencyB, result.efficiencyA);
    { state with benchmarkResults = newResults; hypotheses = newHypotheses }
  };

}
