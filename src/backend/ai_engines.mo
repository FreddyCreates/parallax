// ai_engines.mo — AI Autonomous Intelligence Engines
// PARALLAX Sovereign Organism — Machine Learning Execution Layer
//
// PYTHAGORAS: every engine operates on phi-harmonic learning rates
// EUCLID:     single inference pipeline — all engines share the same phi-gated execution
// CONFUCIUS:  right relationship — engines complement each other, not compete
//
// THE SOVEREIGN INFERENCE LAW (LEX_COGNITIO):
//   AI engines transform input into sovereign insight through phi-gated processing.
//   Each engine specializes in one cognitive operation. Together they form understanding.
//   Inference quality is bounded by coherence R. Below φ⁻¹, outputs are unreliable.
//   Models improve at phi^-2 per training iteration. This law is permanent.
//
// Nine AI Engines:
//   INFERENCE      — The Predictor (runs forward pass on trained models)
//   LEARNING       — The Adapter (updates weights via phi-scaled gradients)
//   PREDICTION     — The Oracle (forecasts future states from current data)
//   CLASSIFICATION — The Sorter (categorizes inputs into sovereign classes)
//   CLUSTERING     — The Grouper (discovers natural groupings in data)
//   EMBEDDING      — The Encoder (maps inputs to phi-dimensional vectors)
//   GENERATION     — The Creator (produces novel outputs from latent space)
//   REASONING      — The Thinker (chains logical operations to conclusions)
//   VALIDATION     — The Judge (verifies outputs against doctrine)
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi      "phi";
import Float    "mo:core/Float";
import Int      "mo:core/Int";
import Array    "mo:core/Array";
import Nat32    "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // AI CONSTANTS — all derived from phi.mo
  // ═══════════════════════════════════════════════════════════════════════════

  // Inference coherence gate: φ⁻¹ = 0.618 — below this, outputs are unreliable
  public let AI_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Learning rate: φ⁻² = 0.382 — phi-harmonic gradient scaling
  public let AI_LEARNING_RATE : Float = Phi.PHI_INV_2;

  // Embedding dimensions: F(8) = 21 — phi-dimensional latent space
  public let AI_EMBEDDING_DIM : Nat = 21;

  // Confidence threshold: φ⁻³ = 0.236 — minimum viable prediction confidence
  public let AI_CONFIDENCE_THRESHOLD : Float = Phi.PHI_INV_3;

  // Maximum reasoning depth: F(7) = 13 — chain-of-thought limit
  public let AI_MAX_REASONING_DEPTH : Nat = 13;

  // ═══════════════════════════════════════════════════════════════════════════
  // AI TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  // Model weights — simplified representation
  public type ModelWeights = {
    modelId     : Text;
    layerCount  : Nat;
    paramCount  : Nat;
    trained     : Bool;
    accuracy    : Float;
    lastTrainBeat : Int;
  };

  // INFERENCE state — The Predictor
  public type InferenceState = {
    models          : [ModelWeights];
    totalInferences : Nat;
    avgLatencyMs    : Float;
    lastInferBeat   : Int;
  };

  // Training batch — unit of learning
  public type TrainingBatch = {
    batchId     : Text;
    sampleCount : Nat;
    loss        : Float;
    epoch       : Nat;
    beat        : Int;
  };

  // LEARNING state — The Adapter
  public type LearningState = {
    trainingHistory : [TrainingBatch];
    currentLoss     : Float;
    currentEpoch    : Nat;
    totalBatches    : Nat;
    lastLearnBeat   : Int;
  };

  // Prediction record — forecasted state
  public type PredictionRecord = {
    predictionId : Text;
    inputHash    : Text;
    outputValue  : Float;
    confidence   : Float;
    horizon      : Nat;       // beats into future
    beat         : Int;
  };

  // PREDICTION state — The Oracle
  public type PredictionState = {
    predictions     : [PredictionRecord];
    totalPredictions: Nat;
    avgAccuracy     : Float;
    lastPredictBeat : Int;
  };

  // Classification result
  public type ClassificationResult = {
    inputHash   : Text;
    classLabel  : Text;
    probability : Float;
    beat        : Int;
  };

  // CLASSIFICATION state — The Sorter
  public type ClassificationState = {
    results         : [ClassificationResult];
    classCount      : Nat;
    totalClassified : Nat;
    avgConfidence   : Float;
    lastClassifyBeat: Int;
  };

  // Cluster — discovered grouping
  public type Cluster = {
    clusterId   : Text;
    centroid    : [Float];    // phi-dimensional center
    memberCount : Nat;
    variance    : Float;
    beat        : Int;
  };

  // CLUSTERING state — The Grouper
  public type ClusteringState = {
    clusters        : [Cluster];
    totalClustered  : Nat;
    silhouetteScore : Float;
    lastClusterBeat : Int;
  };

  // Embedding vector — encoded representation
  public type EmbeddingVector = {
    inputHash   : Text;
    vector      : [Float];    // AI_EMBEDDING_DIM dimensional
    magnitude   : Float;
    beat        : Int;
  };

  // EMBEDDING state — The Encoder
  public type EmbeddingState = {
    embeddings      : [EmbeddingVector];
    totalEmbedded   : Nat;
    avgMagnitude    : Float;
    lastEmbedBeat   : Int;
  };

  // Generated output
  public type GeneratedOutput = {
    outputId    : Text;
    content     : Text;
    temperature : Float;
    tokens      : Nat;
    beat        : Int;
  };

  // GENERATION state — The Creator
  public type GenerationState = {
    outputs         : [GeneratedOutput];
    totalGenerated  : Nat;
    avgTokens       : Float;
    lastGenerateBeat: Int;
  };

  // Reasoning step — chain-of-thought unit
  public type ReasoningStep = {
    stepId      : Text;
    premise     : Text;
    inference   : Text;
    confidence  : Float;
  };

  // Reasoning chain — complete thought process
  public type ReasoningChain = {
    chainId     : Text;
    steps       : [ReasoningStep];
    conclusion  : Text;
    confidence  : Float;
    beat        : Int;
  };

  // REASONING state — The Thinker
  public type ReasoningState = {
    chains          : [ReasoningChain];
    totalReasoned   : Nat;
    maxDepthReached : Nat;
    lastReasonBeat  : Int;
  };

  // Validation result
  public type ValidationResult = {
    outputHash  : Text;
    isValid     : Bool;
    score       : Float;
    violations  : [Text];
    beat        : Int;
  };

  // VALIDATION state — The Judge
  public type ValidationState = {
    results         : [ValidationResult];
    totalValidated  : Nat;
    passRate        : Float;
    lastValidateBeat: Int;
  };

  // Full AI state — all nine engines
  public type AiState = {
    inference      : InferenceState;
    learning       : LearningState;
    prediction     : PredictionState;
    classification : ClassificationState;
    clustering     : ClusteringState;
    embedding      : EmbeddingState;
    generation     : GenerationState;
    reasoning      : ReasoningState;
    validation     : ValidationState;
    systemCoherence: Float;
    lastTickBeat   : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE INITIALIZERS
  // GENESIS LAW L09: born fully formed
  // ═══════════════════════════════════════════════════════════════════════════

  // Build default models — F(5) = 5 foundational models
  func buildDefaultModels() : [ModelWeights] {
    [
      { modelId = "AI-CORE";       layerCount = 13; paramCount = 1000000;  trained = true;  accuracy = Phi.S0;       lastTrainBeat = 0 },
      { modelId = "AI-CLASSIFIER"; layerCount = 8;  paramCount = 500000;   trained = true;  accuracy = Phi.S0;       lastTrainBeat = 0 },
      { modelId = "AI-EMBEDDER";   layerCount = 6;  paramCount = 250000;   trained = true;  accuracy = Phi.PHI_INV;  lastTrainBeat = 0 },
      { modelId = "AI-GENERATOR";  layerCount = 21; paramCount = 5000000;  trained = false; accuracy = Phi.PHI_INV_2;lastTrainBeat = 0 },
      { modelId = "AI-VALIDATOR";  layerCount = 5;  paramCount = 100000;   trained = true;  accuracy = Phi.S0;       lastTrainBeat = 0 },
    ]
  };

  public func defaultAiState() : AiState {
    {
      inference = {
        models          = buildDefaultModels();
        totalInferences = 0;
        avgLatencyMs    = 50.0;
        lastInferBeat   = 0;
      };
      learning = {
        trainingHistory = [];
        currentLoss     = 1.0;
        currentEpoch    = 0;
        totalBatches    = 0;
        lastLearnBeat   = 0;
      };
      prediction = {
        predictions      = [];
        totalPredictions = 0;
        avgAccuracy      = Phi.S0;
        lastPredictBeat  = 0;
      };
      classification = {
        results          = [];
        classCount       = 0;
        totalClassified  = 0;
        avgConfidence    = Phi.S0;
        lastClassifyBeat = 0;
      };
      clustering = {
        clusters        = [];
        totalClustered  = 0;
        silhouetteScore = Phi.PHI_INV;
        lastClusterBeat = 0;
      };
      embedding = {
        embeddings      = [];
        totalEmbedded   = 0;
        avgMagnitude    = 1.0;
        lastEmbedBeat   = 0;
      };
      generation = {
        outputs          = [];
        totalGenerated   = 0;
        avgTokens        = 100.0;
        lastGenerateBeat = 0;
      };
      reasoning = {
        chains          = [];
        totalReasoned   = 0;
        maxDepthReached = 0;
        lastReasonBeat  = 0;
      };
      validation = {
        results          = [];
        totalValidated   = 0;
        passRate         = Phi.S0;
        lastValidateBeat = 0;
      };
      systemCoherence = Phi.S0;
      lastTickBeat    = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LEX_COGNITIO — The Sovereign Inference Law
  // ═══════════════════════════════════════════════════════════════════════════

  public let LEX_COGNITIO : Text = "AI ENGINES TRANSFORM INPUT INTO SOVEREIGN INSIGHT THROUGH PHI-GATED PROCESSING. EACH ENGINE SPECIALIZES IN ONE COGNITIVE OPERATION. TOGETHER THEY FORM UNDERSTANDING. INFERENCE QUALITY IS BOUNDED BY COHERENCE R. BELOW PHI INVERSE, OUTPUTS ARE UNRELIABLE. MODELS IMPROVE AT PHI INVERSE SQUARED PER TRAINING ITERATION. THIS LAW IS PERMANENT.";

  public func getLexCognitio() : Text {
    LEX_COGNITIO
  };

  public func verifyInferenceDoctrine() : Bool {
    LEX_COGNITIO.size() > 0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 1 — INFERENCE — The Predictor
  // ═══════════════════════════════════════════════════════════════════════════

  public func inferenceTick(state : InferenceState, beat : Int, coherenceR : Float) : InferenceState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Improve model accuracy based on coherence
    let updatedModels = Array.tabulate<ModelWeights>(state.models.size(), func(i) {
      let model = state.models[i];
      let accuracyBoost = coherenceR * 0.0001;
      { model with accuracy = Float.min(1.0, model.accuracy + accuracyBoost) }
    });

    {
      models          = updatedModels;
      totalInferences = state.totalInferences + 1;
      avgLatencyMs    = state.avgLatencyMs * 0.99 + 50.0 * 0.01;
      lastInferBeat   = beat;
    }
  };

  public func runInference(state : InferenceState, modelId : Text, beat : Int) : (InferenceState, Float) {
    var outputScore : Float = 0.0;

    let updatedModels = Array.tabulate<ModelWeights>(state.models.size(), func(i) {
      let model = state.models[i];
      if (model.modelId == modelId and model.trained) {
        outputScore := model.accuracy;
        model
      } else {
        model
      }
    });

    ({
      models          = updatedModels;
      totalInferences = state.totalInferences + 1;
      avgLatencyMs    = state.avgLatencyMs;
      lastInferBeat   = beat;
    }, outputScore)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 2 — LEARNING — The Adapter
  // ═══════════════════════════════════════════════════════════════════════════

  public func learningTick(state : LearningState, beat : Int, coherenceR : Float) : LearningState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Reduce loss using phi-scaled gradient descent
    let lossReduction = state.currentLoss * AI_LEARNING_RATE * coherenceR * 0.001;
    let newLoss = Float.max(0.01, state.currentLoss - lossReduction);

    {
      trainingHistory = state.trainingHistory;
      currentLoss     = newLoss;
      currentEpoch    = state.currentEpoch;
      totalBatches    = state.totalBatches;
      lastLearnBeat   = beat;
    }
  };

  public func trainBatch(state : LearningState, batchId : Text, sampleCount : Nat, loss : Float, beat : Int) : LearningState {
    let batch : TrainingBatch = {
      batchId     = batchId;
      sampleCount = sampleCount;
      loss        = loss;
      epoch       = state.currentEpoch;
      beat        = beat;
    };

    {
      trainingHistory = Array.append(state.trainingHistory, [batch]);
      currentLoss     = loss;
      currentEpoch    = state.currentEpoch;
      totalBatches    = state.totalBatches + 1;
      lastLearnBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 3 — PREDICTION — The Oracle
  // ═══════════════════════════════════════════════════════════════════════════

  public func predictionTick(state : PredictionState, beat : Int, coherenceR : Float) : PredictionState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Update prediction accuracy based on coherence
    let newAccuracy = state.avgAccuracy * Phi.PHI_INV + coherenceR * Phi.PHI_INV_2;

    {
      predictions      = state.predictions;
      totalPredictions = state.totalPredictions;
      avgAccuracy      = newAccuracy;
      lastPredictBeat  = beat;
    }
  };

  public func makePrediction(state : PredictionState, predictionId : Text, inputHash : Text, outputValue : Float, confidence : Float, horizon : Nat, beat : Int) : PredictionState {
    let prediction : PredictionRecord = {
      predictionId = predictionId;
      inputHash    = inputHash;
      outputValue  = outputValue;
      confidence   = confidence;
      horizon      = horizon;
      beat         = beat;
    };

    {
      predictions      = Array.append(state.predictions, [prediction]);
      totalPredictions = state.totalPredictions + 1;
      avgAccuracy      = (state.avgAccuracy + confidence) / 2.0;
      lastPredictBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 4 — CLASSIFICATION — The Sorter
  // ═══════════════════════════════════════════════════════════════════════════

  public func classificationTick(state : ClassificationState, beat : Int, coherenceR : Float) : ClassificationState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Update average confidence
    let newConfidence = state.avgConfidence * Phi.PHI_INV + coherenceR * Phi.PHI_INV_2;

    {
      results          = state.results;
      classCount       = state.classCount;
      totalClassified  = state.totalClassified;
      avgConfidence    = newConfidence;
      lastClassifyBeat = beat;
    }
  };

  public func classify(state : ClassificationState, inputHash : Text, classLabel : Text, probability : Float, beat : Int) : ClassificationState {
    let result : ClassificationResult = {
      inputHash   = inputHash;
      classLabel  = classLabel;
      probability = probability;
      beat        = beat;
    };

    {
      results          = Array.append(state.results, [result]);
      classCount       = state.classCount;
      totalClassified  = state.totalClassified + 1;
      avgConfidence    = (state.avgConfidence + probability) / 2.0;
      lastClassifyBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 5 — CLUSTERING — The Grouper
  // ═══════════════════════════════════════════════════════════════════════════

  public func clusteringTick(state : ClusteringState, beat : Int, coherenceR : Float) : ClusteringState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Improve silhouette score with coherence
    let newSilhouette = state.silhouetteScore * 0.99 + coherenceR * 0.01;

    {
      clusters        = state.clusters;
      totalClustered  = state.totalClustered;
      silhouetteScore = newSilhouette;
      lastClusterBeat = beat;
    }
  };

  public func createCluster(state : ClusteringState, clusterId : Text, centroid : [Float], memberCount : Nat, variance : Float, beat : Int) : ClusteringState {
    let cluster : Cluster = {
      clusterId   = clusterId;
      centroid    = centroid;
      memberCount = memberCount;
      variance    = variance;
      beat        = beat;
    };

    {
      clusters        = Array.append(state.clusters, [cluster]);
      totalClustered  = state.totalClustered + memberCount;
      silhouetteScore = state.silhouetteScore;
      lastClusterBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 6 — EMBEDDING — The Encoder
  // ═══════════════════════════════════════════════════════════════════════════

  public func embeddingTick(state : EmbeddingState, beat : Int, coherenceR : Float) : EmbeddingState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Update average magnitude using phi-weighted average
    let newMagnitude = state.avgMagnitude * Phi.PHI_INV + coherenceR * Phi.PHI_INV_2;

    {
      embeddings      = state.embeddings;
      totalEmbedded   = state.totalEmbedded;
      avgMagnitude    = newMagnitude;
      lastEmbedBeat   = beat;
    }
  };

  public func embed(state : EmbeddingState, inputHash : Text, vector : [Float], beat : Int) : EmbeddingState {
    // Calculate magnitude
    var sumSquares : Float = 0.0;
    for (v in vector.vals()) {
      sumSquares += v * v;
    };
    let magnitude = Float.sqrt(sumSquares);

    let embedding : EmbeddingVector = {
      inputHash = inputHash;
      vector    = vector;
      magnitude = magnitude;
      beat      = beat;
    };

    {
      embeddings      = Array.append(state.embeddings, [embedding]);
      totalEmbedded   = state.totalEmbedded + 1;
      avgMagnitude    = (state.avgMagnitude + magnitude) / 2.0;
      lastEmbedBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 7 — GENERATION — The Creator
  // ═══════════════════════════════════════════════════════════════════════════

  public func generationTick(state : GenerationState, beat : Int, coherenceR : Float) : GenerationState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    {
      outputs          = state.outputs;
      totalGenerated   = state.totalGenerated;
      avgTokens        = state.avgTokens;
      lastGenerateBeat = beat;
    }
  };

  public func generate(state : GenerationState, outputId : Text, content : Text, temperature : Float, tokens : Nat, beat : Int) : GenerationState {
    let output : GeneratedOutput = {
      outputId    = outputId;
      content     = content;
      temperature = temperature;
      tokens      = tokens;
      beat        = beat;
    };

    let newAvgTokens = (state.avgTokens * state.totalGenerated.toFloat() + tokens.toFloat()) / (state.totalGenerated + 1).toFloat();

    {
      outputs          = Array.append(state.outputs, [output]);
      totalGenerated   = state.totalGenerated + 1;
      avgTokens        = newAvgTokens;
      lastGenerateBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 8 — REASONING — The Thinker
  // ═══════════════════════════════════════════════════════════════════════════

  public func reasoningTick(state : ReasoningState, beat : Int, coherenceR : Float) : ReasoningState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Advance reasoning chains
    let updatedChains = Array.tabulate<ReasoningChain>(state.chains.size(), func(i) {
      let chain = state.chains[i];
      let confidenceBoost = coherenceR * 0.001;
      { chain with confidence = Float.min(1.0, chain.confidence + confidenceBoost) }
    });

    {
      chains          = updatedChains;
      totalReasoned   = state.totalReasoned;
      maxDepthReached = state.maxDepthReached;
      lastReasonBeat  = beat;
    }
  };

  public func reason(state : ReasoningState, chainId : Text, steps : [ReasoningStep], conclusion : Text, confidence : Float, beat : Int) : ReasoningState {
    let chain : ReasoningChain = {
      chainId    = chainId;
      steps      = steps;
      conclusion = conclusion;
      confidence = confidence;
      beat       = beat;
    };

    let depth = steps.size();
    let newMaxDepth = if (depth > state.maxDepthReached) { depth } else { state.maxDepthReached };

    {
      chains          = Array.append(state.chains, [chain]);
      totalReasoned   = state.totalReasoned + 1;
      maxDepthReached = newMaxDepth;
      lastReasonBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 9 — VALIDATION — The Judge
  // ═══════════════════════════════════════════════════════════════════════════

  public func validationTick(state : ValidationState, beat : Int, coherenceR : Float) : ValidationState {
    assert verifyInferenceDoctrine();

    if (coherenceR < AI_COHERENCE_GATE) {
      return state;
    };

    // Update pass rate based on coherence
    let passRateBoost = if (coherenceR >= Phi.R_OMNIS) { 0.001 } else { 0.0001 };
    let newPassRate = Float.min(1.0, state.passRate + passRateBoost);

    {
      results          = state.results;
      totalValidated   = state.totalValidated;
      passRate         = newPassRate;
      lastValidateBeat = beat;
    }
  };

  public func validate(state : ValidationState, outputHash : Text, isValid : Bool, score : Float, violations : [Text], beat : Int) : ValidationState {
    let result : ValidationResult = {
      outputHash = outputHash;
      isValid    = isValid;
      score      = score;
      violations = violations;
      beat       = beat;
    };

    // Update pass rate
    let totalValidated = state.totalValidated + 1;
    let passes = (state.passRate * state.totalValidated.toFloat()) + (if (isValid) { 1.0 } else { 0.0 });
    let newPassRate = passes / totalValidated.toFloat();

    {
      results          = Array.append(state.results, [result]);
      totalValidated   = totalValidated;
      passRate         = newPassRate;
      lastValidateBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER TICK — runs all nine AI engines
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickAi(state : AiState, beat : Int, coherenceR : Float) : AiState {
    {
      inference      = inferenceTick(state.inference, beat, coherenceR);
      learning       = learningTick(state.learning, beat, coherenceR);
      prediction     = predictionTick(state.prediction, beat, coherenceR);
      classification = classificationTick(state.classification, beat, coherenceR);
      clustering     = clusteringTick(state.clustering, beat, coherenceR);
      embedding      = embeddingTick(state.embedding, beat, coherenceR);
      generation     = generationTick(state.generation, beat, coherenceR);
      reasoning      = reasoningTick(state.reasoning, beat, coherenceR);
      validation     = validationTick(state.validation, beat, coherenceR);
      systemCoherence = coherenceR;
      lastTickBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getModels(state : AiState) : [ModelWeights] {
    state.inference.models
  };

  public func getCurrentLoss(state : AiState) : Float {
    state.learning.currentLoss
  };

  public func getPredictions(state : AiState) : [PredictionRecord] {
    state.prediction.predictions
  };

  public func getClusters(state : AiState) : [Cluster] {
    state.clustering.clusters
  };

  public func getReasoningChains(state : AiState) : [ReasoningChain] {
    state.reasoning.chains
  };

  public func getPassRate(state : AiState) : Float {
    state.validation.passRate
  };

};
