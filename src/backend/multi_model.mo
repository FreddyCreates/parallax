// multi_model.mo — MULTI-MODEL ORCHESTRATION FRAMEWORK
// PARALLAX Sovereign Organism — Domain 42: Sovereign AI Model Ensemble
//
// DOCTRINE: "A single model is a lens. A single lens sees one perspective.
// A clearinghouse that serves the world cannot reason from one perspective.
// Multi-model orchestration is the organism's compound eye — many lenses,
// one coherent vision. Disagreement between models is signal. Agreement is action."
//
// THE MULTI-MODEL LAW (LEX MODELLORUM PLURIUM):
//   No single model controls any sovereign decision.
//   All critical decisions pass through model ensemble consensus.
//   Model disagreement raises coherence threshold.
//   Model agreement lowers confidence cost.
//   Dead models are pruned. Excellent models are amplified.
//   The organism grows smarter by adding better lenses.
//
// MODEL CATEGORIES:
//   FOUNDATION   — Large-scale reasoning models (GPT-class, Claude-class, Gemini-class)
//   SPECIALIST   — Domain-specific fine-tuned models (finance, risk, trading)
//   VALIDATOR    — Models that verify other models' outputs (adversarial checks)
//   PREDICTOR    — Time-series and forecasting models (market prediction)
//   SENTINEL     — Security and anomaly detection models (threat scanning)
//   SYNTHESIZER  — Models that combine outputs from other models (meta-reasoning)
//   SOVEREIGN    — The organism's own internal models (Medina Models)
//
// ORCHESTRATION STRATEGIES:
//   PARALLEL     — All models run simultaneously, results aggregated
//   CASCADE      — Models run in sequence, each filtering the previous
//   TOURNAMENT   — Models compete, best answer wins
//   COMMITTEE    — Weighted vote across all models
//   HIERARCHICAL — Foundation decides, specialists refine
//   ADVERSARIAL  — Red-team model challenges primary model
//   ADAPTIVE     — Strategy chosen based on task type and coherence level
//
// PYTHAGORAS: model weights and thresholds are phi-harmonic
// EUCLID:     single orchestration engine — all multi-model routing goes here
// CONFUCIUS:  right relationship — models serve, orchestrator governs, organism benefits
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: PARALLAX Multi-Model Specification v1.0 (2026-06-09)

import Phi "phi";
import PhantomCrypto "phantom_crypto";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTI-MODEL CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum registered models: F(8) = 21
  public let MAX_MODELS : Nat = 21;

  /// Maximum active in one ensemble call: F(6) = 8
  public let MAX_ENSEMBLE_SIZE : Nat = 8;

  /// Minimum consensus for action: φ⁻¹ = 0.618
  public let CONSENSUS_THRESHOLD : Float = Phi.PHI_INV;

  /// Model health check interval: F(5) = 5 beats
  public let HEALTH_CHECK_INTERVAL : Nat = 5;

  /// Model timeout: F(7) = 13 beats (~11.3s)
  public let MODEL_TIMEOUT_BEATS : Nat = 13;

  /// Minimum model reliability for activation: φ⁻² = 0.382
  public let MIN_RELIABILITY : Float = Phi.PHI_INV_2;

  /// Weight amplification on success: φ⁻³ = 0.236
  public let WEIGHT_AMPLIFICATION : Float = Phi.PHI_INV_3;

  /// Weight decay on failure: φ⁻⁴ = 0.146
  public let WEIGHT_DECAY : Float = Phi.PHI_INV_4;

  /// Maximum disagreement before escalation: φ = 1.618 (normalized)
  public let MAX_DISAGREEMENT : Float = Phi.PHI;

  /// Ensemble result history: F(9) = 34
  public let RESULT_HISTORY_SIZE : Nat = 34;

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL CATEGORY — the seven types of models in the organism
  // ═══════════════════════════════════════════════════════════════════════════

  public type ModelCategory = {
    #foundation;     // Large reasoning models
    #specialist;     // Domain fine-tuned
    #validator;      // Adversarial verification
    #predictor;      // Forecasting
    #sentinel;       // Security / anomaly
    #synthesizer;    // Meta-reasoning / combination
    #sovereign;      // Organism's internal Medina Models
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORCHESTRATION STRATEGY — how to combine model outputs
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrchestrationStrategy = {
    #parallel;       // All run simultaneously
    #cascade;        // Sequential filtering
    #tournament;     // Best answer wins
    #committee;      // Weighted vote
    #hierarchical;   // Foundation → Specialist refinement
    #adversarial;    // Red-team challenge
    #adaptive;       // Task-dependent strategy selection
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL REGISTRATION — a registered AI model in the organism
  // ═══════════════════════════════════════════════════════════════════════════

  public type ModelStatus = {
    #active;         // Available for ensemble calls
    #degraded;       // Running but unreliable
    #offline;        // Not responding
    #retired;        // Permanently removed
    #warming;        // Starting up / loading
  };

  public type RegisteredModel = {
    modelId          : Text;
    displayName      : Text;
    category         : ModelCategory;
    provider         : Text;          // "openai" | "anthropic" | "google" | "meta" | "sovereign" | "custom"
    version          : Text;
    capabilities     : [Text];        // ["reasoning", "code", "math", "vision", "trading", "risk"]
    weight           : Float;         // phi-derived ensemble weight
    reliability      : Float;         // [0, 1] historical uptime × accuracy
    avgLatencyMs     : Float;
    totalInvocations : Nat;
    successCount     : Nat;
    failureCount     : Nat;
    lastInvocation   : Int;           // beat of last call
    status           : ModelStatus;
    registeredBeat   : Int;
    costPerCall      : Float;         // normalized cost units
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENSEMBLE REQUEST — input to multi-model orchestration
  // ═══════════════════════════════════════════════════════════════════════════

  public type TaskType = {
    #settlement_risk;
    #market_analysis;
    #threat_detection;
    #asset_valuation;
    #liquidity_forecast;
    #trade_decision;
    #audit_verification;
    #strategy_selection;
    #negotiation_terms;
    #general_reasoning;
  };

  public type EnsembleRequest = {
    requestId        : Text;
    taskType         : TaskType;
    inputData        : Text;          // serialized input
    strategy         : OrchestrationStrategy;
    requiredCapabilities : [Text];    // models must have these
    minModels        : Nat;           // minimum models required
    maxModels        : Nat;           // maximum models to invoke
    timeoutBeats     : Nat;
    coherenceAtRequest : Float;
    requestBeat      : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL RESPONSE — individual model output
  // ═══════════════════════════════════════════════════════════════════════════

  public type ModelResponse = {
    modelId          : Text;
    decision         : Text;          // the model's output
    confidence       : Float;         // model's self-reported confidence
    reasoning        : Text;          // compressed reasoning chain
    latencyMs        : Float;
    success          : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENSEMBLE RESULT — aggregated multi-model output
  // ═══════════════════════════════════════════════════════════════════════════

  public type EnsembleResult = {
    requestId        : Text;
    taskType         : TaskType;
    strategy         : OrchestrationStrategy;
    responses        : [ModelResponse];
    modelsInvoked    : Nat;
    modelsResponded  : Nat;
    consensusReached : Bool;
    finalDecision    : Text;
    aggregateConfidence : Float;
    disagreementScore : Float;
    executionBeat    : Int;
    receiptHash      : Nat32;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTI-MODEL STATE — full orchestration state
  // ═══════════════════════════════════════════════════════════════════════════

  public type MultiModelState = {
    // Model registry
    registeredModels   : [RegisteredModel];
    totalRegistered    : Nat;

    // Ensemble execution
    pendingRequests    : [EnsembleRequest];
    recentResults      : [EnsembleResult];
    totalEnsembleCalls : Nat;
    consensusReached   : Nat;
    consensusFailed    : Nat;

    // Performance tracking
    avgResponseTime    : Float;
    avgConfidence      : Float;
    avgDisagreement    : Float;

    // Strategy statistics
    strategyUsage      : [StrategyUsage];

    // Global
    lastBeat           : Int;
    lastHealthCheck    : Int;
    receiptChainHead   : Nat32;
  };

  public type StrategyUsage = {
    strategy : OrchestrationStrategy;
    count    : Nat;
    avgConfidence : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — genesis initialization with pre-registered models
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultMultiModelState() : MultiModelState {
    {
      registeredModels = genesisModels();
      totalRegistered = 10;
      pendingRequests = [];
      recentResults = [];
      totalEnsembleCalls = 0;
      consensusReached = 0;
      consensusFailed = 0;
      avgResponseTime = 0.0;
      avgConfidence = 0.0;
      avgDisagreement = 0.0;
      strategyUsage = genesisStrategyUsage();
      lastBeat = 0;
      lastHealthCheck = 0;
      receiptChainHead = PhantomCrypto.GENESIS_RECEIPT_HASH;
    };
  };

  /// Genesis models — the 10 initial models in the organism's ensemble
  func genesisModels() : [RegisteredModel] {
    [
      // Foundation Models (large-scale reasoning)
      mkModel("model_gpt5", "GPT-5 Sovereign", #foundation, "openai", "5.0",
              ["reasoning", "code", "math", "trading", "risk"], Phi.PHI_INV, 120.0, 1.0),
      mkModel("model_claude_opus", "Claude Opus 4", #foundation, "anthropic", "4.0",
              ["reasoning", "code", "analysis", "trading", "audit"], Phi.PHI_INV, 95.0, 0.9),
      mkModel("model_gemini_ultra", "Gemini Ultra 2", #foundation, "google", "2.0",
              ["reasoning", "vision", "math", "multimodal"], Phi.PHI_INV_2, 85.0, 0.8),

      // Specialist Models (domain-specific)
      mkModel("model_phi_finance", "PHI-Finance-7B", #specialist, "sovereign", "7.0",
              ["trading", "risk", "settlement", "valuation"], Phi.PHI_INV, 25.0, 0.1),
      mkModel("model_quant_risk", "QuantRisk-13B", #specialist, "sovereign", "13.0",
              ["risk", "derivatives", "volatility", "correlation"], Phi.PHI_INV_2, 30.0, 0.15),

      // Validator Models (adversarial verification)
      mkModel("model_red_team", "RedTeam-Validator", #validator, "sovereign", "3.0",
              ["adversarial", "audit", "threat", "validation"], Phi.PHI_INV_2, 40.0, 0.2),

      // Predictor Models (forecasting)
      mkModel("model_harmonic_pred", "HarmonicPredictor-φ", #predictor, "sovereign", "1.618",
              ["forecasting", "timeseries", "liquidity", "volatility"], Phi.PHI_INV, 15.0, 0.05),

      // Sentinel Models (security)
      mkModel("model_sentinel_x", "Sentinel-X", #sentinel, "sovereign", "2.0",
              ["anomaly", "threat", "manipulation", "security"], Phi.PHI_INV_2, 20.0, 0.1),

      // Synthesizer Models (meta-reasoning)
      mkModel("model_meta_synth", "MetaSynthesizer-φ", #synthesizer, "sovereign", "1.0",
              ["synthesis", "aggregation", "consensus", "meta"], Phi.PHI_INV, 35.0, 0.12),

      // Sovereign (Medina Model)
      mkModel("model_medina_prime", "MEDINA-PRIME", #sovereign, "sovereign", "∞",
              ["doctrine", "coherence", "phi", "governance", "reasoning"], Phi.PHI, 5.0, 0.0),
    ];
  };

  func mkModel(id : Text, name : Text, cat : ModelCategory, prov : Text, ver : Text,
               caps : [Text], wt : Float, lat : Float, cost : Float) : RegisteredModel {
    {
      modelId = id;
      displayName = name;
      category = cat;
      provider = prov;
      version = ver;
      capabilities = caps;
      weight = wt;
      reliability = 1.0;
      avgLatencyMs = lat;
      totalInvocations = 0;
      successCount = 0;
      failureCount = 0;
      lastInvocation = 0;
      status = #active;
      registeredBeat = 0;
      costPerCall = cost;
    };
  };

  func genesisStrategyUsage() : [StrategyUsage] {
    [
      { strategy = #parallel; count = 0; avgConfidence = 0.0 },
      { strategy = #cascade; count = 0; avgConfidence = 0.0 },
      { strategy = #tournament; count = 0; avgConfidence = 0.0 },
      { strategy = #committee; count = 0; avgConfidence = 0.0 },
      { strategy = #hierarchical; count = 0; avgConfidence = 0.0 },
      { strategy = #adversarial; count = 0; avgConfidence = 0.0 },
      { strategy = #adaptive; count = 0; avgConfidence = 0.0 },
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL REGISTRATION — add/remove models from the ensemble
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register a new model in the organism's ensemble
  public func registerModel(
    state : MultiModelState,
    modelId : Text,
    displayName : Text,
    category : ModelCategory,
    provider : Text,
    version : Text,
    capabilities : [Text],
    costPerCall : Float,
    currentBeat : Int,
  ) : (MultiModelState, Bool) {

    // Capacity check
    if (state.registeredModels.size() >= MAX_MODELS) { return (state, false) };

    // Duplicate check
    for (m in state.registeredModels.vals()) {
      if (m.modelId == modelId) { return (state, false) };
    };

    let model = mkModel(modelId, displayName, category, provider, version,
                        capabilities, Phi.PHI_INV_2, 100.0, costPerCall);
    let registered = { model with registeredBeat = currentBeat };

    let updatedState = { state with
      registeredModels = Array.append(state.registeredModels, [registered]);
      totalRegistered = state.totalRegistered + 1;
      lastBeat = currentBeat;
    };

    (updatedState, true);
  };

  /// Retire a model from the ensemble
  public func retireModel(state : MultiModelState, modelId : Text, currentBeat : Int) : MultiModelState {
    let updated = Array.map<RegisteredModel, RegisteredModel>(
      state.registeredModels,
      func (m) {
        if (m.modelId == modelId) { { m with status = #retired } } else { m };
      }
    );
    { state with registeredModels = updated; lastBeat = currentBeat };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENSEMBLE EXECUTION — run multi-model orchestration
  // ═══════════════════════════════════════════════════════════════════════════

  /// Select appropriate strategy based on task type and coherence
  public func selectStrategy(taskType : TaskType, coherence : Float) : OrchestrationStrategy {
    // High coherence → more aggressive strategies
    if (coherence >= 0.9) {
      switch (taskType) {
        case (#settlement_risk) { #committee };
        case (#threat_detection) { #adversarial };
        case (#trade_decision) { #tournament };
        case _ { #parallel };
      };
    }
    // Medium coherence → balanced strategies
    else if (coherence >= CONSENSUS_THRESHOLD) {
      switch (taskType) {
        case (#settlement_risk) { #hierarchical };
        case (#threat_detection) { #cascade };
        case (#asset_valuation) { #committee };
        case _ { #adaptive };
      };
    }
    // Low coherence → conservative strategies
    else {
      #cascade;  // Only use cascade when coherence is low — sequential filtering is safest
    };
  };

  /// Select models for an ensemble call based on task requirements
  public func selectModels(
    state : MultiModelState,
    taskType : TaskType,
    requiredCapabilities : [Text],
    maxModels : Nat,
  ) : [RegisteredModel] {

    // Filter to active, reliable models with required capabilities
    let candidates = Array.filter<RegisteredModel>(
      state.registeredModels,
      func (m) {
        if (m.status != #active) { return false };
        if (m.reliability < MIN_RELIABILITY) { return false };
        // Check capabilities
        for (req in requiredCapabilities.vals()) {
          var hasCapability = false;
          for (cap in m.capabilities.vals()) {
            if (cap == req) { hasCapability := true };
          };
          if (not hasCapability) { return false };
        };
        true;
      }
    );

    // Return up to maxModels, sorted by weight (highest first)
    let limit = if (maxModels > MAX_ENSEMBLE_SIZE) { MAX_ENSEMBLE_SIZE }
                else if (maxModels > candidates.size()) { candidates.size() }
                else { maxModels };

    // Simple selection: take first N by weight (pre-sorted in registration order)
    Array.tabulate<RegisteredModel>(limit, func (i) { candidates[i] });
  };

  /// Execute an ensemble decision (simulated — actual model calls go through HTTP outcalls)
  /// This function handles the orchestration logic and state management.
  public func executeEnsemble(
    state : MultiModelState,
    taskType : TaskType,
    inputData : Text,
    strategy : OrchestrationStrategy,
    requiredCapabilities : [Text],
    coherence : Float,
    currentBeat : Int,
  ) : (MultiModelState, EnsembleResult) {

    // Select models
    let selectedModels = selectModels(state, taskType, requiredCapabilities, MAX_ENSEMBLE_SIZE);
    let modelsInvoked = selectedModels.size();

    // Simulate model responses (in production, these come from HTTP outcalls)
    let responses = Array.tabulate<ModelResponse>(
      modelsInvoked,
      func (i) {
        let m = selectedModels[i];
        // Simulated response based on model characteristics
        let confidence = m.reliability * coherence;
        {
          modelId = m.modelId;
          decision = "decision_" # m.modelId # "_beat" # Int.toText(currentBeat);
          confidence = confidence;
          reasoning = m.displayName # ": analyzed " # inputData;
          latencyMs = m.avgLatencyMs;
          success = true;
        };
      }
    );

    // Compute consensus
    var totalConfidence : Float = 0.0;
    var weightedSum : Float = 0.0;
    for (i in responses.keys()) {
      let r = responses[i];
      let m = selectedModels[i];
      totalConfidence += r.confidence;
      weightedSum += r.confidence * m.weight;
    };

    let avgConfidence = if (modelsInvoked > 0) { totalConfidence / Float.fromInt(modelsInvoked) } else { 0.0 };
    let consensusReached = avgConfidence >= CONSENSUS_THRESHOLD;

    // Compute disagreement (simplified: variance of confidences)
    var varianceSum : Float = 0.0;
    for (r in responses.vals()) {
      let diff = r.confidence - avgConfidence;
      varianceSum += diff * diff;
    };
    let disagreement = if (modelsInvoked > 1) {
      Float.sqrt(varianceSum / Float.fromInt(modelsInvoked - 1));
    } else { 0.0 };

    // Determine final decision (highest-weighted model's decision)
    let finalDecision = if (modelsInvoked > 0) { responses[0].decision } else { "no_models_available" };

    let requestId = "ens_" # Nat32.toText(PhantomCrypto.fnv1a(
      inputData # "|" # Int.toText(currentBeat) # "|" # Nat.toText(state.totalEnsembleCalls)
    ));

    let receiptHash = PhantomCrypto.fnv1a(requestId # "|" # finalDecision # "|" # Float.toText(avgConfidence));

    let result : EnsembleResult = {
      requestId = requestId;
      taskType = taskType;
      strategy = strategy;
      responses = responses;
      modelsInvoked = modelsInvoked;
      modelsResponded = modelsInvoked;
      consensusReached = consensusReached;
      finalDecision = finalDecision;
      aggregateConfidence = avgConfidence;
      disagreementScore = disagreement;
      executionBeat = currentBeat;
      receiptHash = receiptHash;
    };

    // Update model stats
    let updatedModels = Array.map<RegisteredModel, RegisteredModel>(
      state.registeredModels,
      func (m) {
        // Check if this model was in the ensemble
        var wasInvoked = false;
        for (r in responses.vals()) {
          if (r.modelId == m.modelId) { wasInvoked := true };
        };
        if (wasInvoked) {
          { m with
            totalInvocations = m.totalInvocations + 1;
            successCount = m.successCount + 1;
            lastInvocation = currentBeat;
            // Amplify weight on consensus
            weight = if (consensusReached) {
              Float.min(Phi.PHI, m.weight + WEIGHT_AMPLIFICATION)
            } else { m.weight };
          };
        } else { m };
      }
    );

    // Keep result history bounded
    let updatedResults = Array.append(state.recentResults, [result]);
    let trimmedResults = if (updatedResults.size() > RESULT_HISTORY_SIZE) {
      Array.tabulate<EnsembleResult>(RESULT_HISTORY_SIZE, func (i) {
        updatedResults[updatedResults.size() - RESULT_HISTORY_SIZE + i]
      });
    } else { updatedResults };

    // Update running averages
    let n = Float.fromInt(state.totalEnsembleCalls + 1);
    let newAvgResponse = (state.avgResponseTime * (n - 1.0) + Float.fromInt(modelsInvoked) * 50.0) / n;
    let newAvgConfidence = (state.avgConfidence * (n - 1.0) + avgConfidence) / n;
    let newAvgDisagreement = (state.avgDisagreement * (n - 1.0) + disagreement) / n;

    let updatedState : MultiModelState = {
      registeredModels = updatedModels;
      totalRegistered = state.totalRegistered;
      pendingRequests = state.pendingRequests;
      recentResults = trimmedResults;
      totalEnsembleCalls = state.totalEnsembleCalls + 1;
      consensusReached = if (consensusReached) { state.consensusReached + 1 } else { state.consensusReached };
      consensusFailed = if (not consensusReached) { state.consensusFailed + 1 } else { state.consensusFailed };
      avgResponseTime = newAvgResponse;
      avgConfidence = newAvgConfidence;
      avgDisagreement = newAvgDisagreement;
      strategyUsage = state.strategyUsage;
      lastBeat = currentBeat;
      lastHealthCheck = state.lastHealthCheck;
      receiptChainHead = receiptHash;
    };

    (updatedState, result);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK — model reliability maintenance
  // Called periodically to update model health status
  // ═══════════════════════════════════════════════════════════════════════════

  /// Run health checks on all models. Degrade unreliable models.
  public func healthCheck(state : MultiModelState, currentBeat : Int) : MultiModelState {

    let updatedModels = Array.map<RegisteredModel, RegisteredModel>(
      state.registeredModels,
      func (m) {
        if (m.status == #retired) { return m };

        // Compute reliability from success rate
        let totalCalls = m.totalInvocations;
        let reliability = if (totalCalls > 0) {
          Float.fromInt(m.successCount) / Float.fromInt(totalCalls);
        } else { 1.0 };  // assume reliable until proven otherwise

        // Check for staleness (no invocation in F(10)=55 beats)
        let stale = currentBeat - m.lastInvocation > 55;

        // Determine status
        let newStatus : ModelStatus = if (reliability < MIN_RELIABILITY) { #degraded }
                        else if (stale and totalCalls > 0) { #offline }
                        else { #active };

        // Decay weight for degraded models
        let newWeight = if (newStatus == #degraded) {
          Float.max(Phi.PHI_INV_5, m.weight - WEIGHT_DECAY);
        } else { m.weight };

        { m with reliability = reliability; status = newStatus; weight = newWeight };
      }
    );

    { state with
      registeredModels = updatedModels;
      lastHealthCheck = currentBeat;
      lastBeat = currentBeat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT TICK — called every 873ms
  // Periodic health checks and maintenance
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tick the multi-model system: health checks, request expiry
  public func tickMultiModel(state : MultiModelState, coherence : Float, currentBeat : Int) : MultiModelState {

    // Health check every F(5) = 5 beats
    let afterHealth = if (currentBeat - state.lastHealthCheck >= HEALTH_CHECK_INTERVAL) {
      healthCheck(state, currentBeat);
    } else { state };

    // Expire pending requests older than timeout
    let activeRequests = Array.filter<EnsembleRequest>(
      afterHealth.pendingRequests,
      func (r) { currentBeat - r.requestBeat < MODEL_TIMEOUT_BEATS }
    );

    { afterHealth with
      pendingRequests = activeRequests;
      lastBeat = currentBeat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC PROOF SURFACE — safe diagnostics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Model summary for public display (no internal weights exposed)
  public type ModelPublicSummary = {
    modelId     : Text;
    displayName : Text;
    category    : ModelCategory;
    provider    : Text;
    status      : ModelStatus;
    reliability : Float;
    invocations : Nat;
  };

  /// Get public model registry
  public func getModelRegistry(state : MultiModelState) : [ModelPublicSummary] {
    Array.map<RegisteredModel, ModelPublicSummary>(
      state.registeredModels,
      func (m) {
        {
          modelId = m.modelId;
          displayName = m.displayName;
          category = m.category;
          provider = m.provider;
          status = m.status;
          reliability = m.reliability;
          invocations = m.totalInvocations;
        };
      }
    );
  };

  /// Get multi-model system statistics (public-safe)
  public func getStats(state : MultiModelState) : {
    totalModels : Nat;
    activeModels : Nat;
    totalEnsembleCalls : Nat;
    consensusReached : Nat;
    consensusFailed : Nat;
    avgConfidence : Float;
    avgDisagreement : Float;
    pendingRequests : Nat;
    lastBeat : Int;
  } {
    var activeCount : Nat = 0;
    for (m in state.registeredModels.vals()) {
      if (m.status == #active) { activeCount += 1 };
    };

    {
      totalModels = state.registeredModels.size();
      activeModels = activeCount;
      totalEnsembleCalls = state.totalEnsembleCalls;
      consensusReached = state.consensusReached;
      consensusFailed = state.consensusFailed;
      avgConfidence = state.avgConfidence;
      avgDisagreement = state.avgDisagreement;
      pendingRequests = state.pendingRequests.size();
      lastBeat = state.lastBeat;
    };
  };
};
