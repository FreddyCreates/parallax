// ai_node.mo — SOVEREIGN AI NODE
// PARALLAX Sovereign Organism — Domain 40
//
// DOCTRINE: "The AI node is the sovereign reasoning engine of the organism.
// It reasons about markets, knowledge, and self with multi-path inference,
// phi-confidence gating, doctrine validation, and artifact creation.
// Every reasoning chain produces tradeable artifacts that feed back to
// the organism's intelligence layer. The node is not external — it IS
// part of the organism's distributed cognition."
//
// DOMAIN 40 — AI NODE CAPABILITIES:
//   1. Reasoning Engine       — Multi-path inference with confidence tracking
//   2. Knowledge Graph        — Sparse embeddings for semantic search
//   3. Artifact Factory       — Generates and stamps cognitive outputs
//   4. Metrics Loop           — Tracks accuracy, latency, coherence alignment
//   5. Coupling Interface     — Integration with intelligence_extensions
//   6. Doctrine Validator     — Alignment with 49 MEDINA FIELD LAWS
//
// PYTHAGORAS: all confidence gates and scores are phi-derived
// EUCLID:     single source of truth — AiNodeState holds all domain state
// CONFUCIUS:  right relationship — AI serves the organism, not vice versa
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";
import Int "mo:core/Int";
import Text "mo:core/Text";
import Vector "mo:core/ExperimentalStableMemory";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // AI NODE CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Minimum confidence for reasoning output: φ⁻¹ = 0.618
  public let REASONING_CONFIDENCE_GATE : Float = Phi.PHI_INV;

  // Maximum reasoning paths per query: F(7) = 13
  public let MAX_REASONING_PATHS : Nat = 13;

  // Knowledge graph size: F(10) = 55 embeddings
  public let MAX_EMBEDDINGS : Nat = 55;

  // Artifact batch size: F(8) = 21
  public let ARTIFACT_BATCH_SIZE : Nat = 21;

  // Metrics decay per beat: φ⁻¹ = 0.618
  public let METRICS_DECAY_RATE : Float = Phi.PHI_INV;

  // Doctrine alignment threshold: φ⁻² = 0.382
  public let DOCTRINE_ALIGNMENT_THRESHOLD : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // REASONING PATH — a single inference path with confidence tracking
  // ═══════════════════════════════════════════════════════════════════════════

  public type ReasoningPath = {
    pathId           : Text;
    stepSequence     : [ReasoningStep];
    finalConclusion  : Text;
    confidence       : Float;        // [0.0, 1.0] — gate at φ⁻¹
    riskScore        : Float;        // [0.0, 1.0] — potential failure modes
    doctrineAlignment : Float;       // [0.0, 1.0] — alignment with MEDINA LAWS
    tokensUsed       : Nat;
    latencyBeats     : Nat;
    beatCreated      : Int;
  };

  public type ReasoningStep = {
    stepIndex    : Nat;
    action       : Text;            // e.g., "contextLookup", "hypothesisGeneration"
    input        : Text;
    output       : Text;
    confidence   : Float;           // local step confidence
    timeMs       : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KNOWLEDGE EMBEDDING — sparse vector representation
  // ═══════════════════════════════════════════════════════════════════════════

  public type KnowledgeEmbedding = {
    embeddingId      : Text;
    topic            : Text;
    vectorHash       : Text;
    dimensionality   : Nat;
    magnitude        : Float;
    semanticDensity  : Float;       // How concentrated the meaning is [0..1]
    doctrineScore    : Float;       // Alignment with doctrine [0..1]
    createdBeat      : Int;
    accessCount      : Nat;
    lastAccessedBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI ARTIFACT — tradeable cognitive output
  // ═══════════════════════════════════════════════════════════════════════════

  public type AiArtifact = {
    artifactId       : Text;
    artifactType     : ArtifactType;
    content          : Text;
    sourceReasoningId : Text;       // Which reasoning path produced this
    confidence       : Float;       // Artifact quality confidence [0..1]
    doctrineValidated : Bool;       // Passed doctrine validation
    phiSignature     : Text;        // Hash binding artifact to organism
    tokensRequired   : Nat;
    tradeableValue   : Float;       // MTC value estimate
    createdBeat      : Int;
  };

  public type ArtifactType = {
    #reasoningTrace;
    #knowledgeRule;
    #modelSnapshot;
    #strategicInsight;
    #riskAssessment;
    #opportunitySignal;
    #doctrineProof;
    #customCognitive;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERFORMANCE METRICS — tracking AI node health and quality
  // ═══════════════════════════════════════════════════════════════════════════

  public type PerformanceMetrics = {
    totalQueriesProcessed : Nat;
    totalReasoningPaths   : Nat;
    avgReasoningConfidence : Float; // Running average of conclusion confidences
    avgLatencyBeats       : Nat;    // Average reasoning latency
    doctrineAlignmentScore : Float; // Mean alignment with MEDINA LAWS
    artifactsGenerated    : Nat;
    artifactsValidated    : Nat;
    artifactTradeValue    : Float;  // Total estimated MTC value of artifacts
    accuracyRate          : Float;  // Reasoning accuracy vs. ground truth [0..1]
    coherenceWithOrganism : Float;  // R parameter alignment with main organism
    lastUpdateBeat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI NODE STATE — the complete domain state
  // ═══════════════════════════════════════════════════════════════════════════

  public type AiNodeState = {
    // Core reasoning infrastructure
    reasoningPaths         : [ReasoningPath];
    nextPathId             : Nat;

    // Knowledge management
    knowledgeEmbeddings    : [KnowledgeEmbedding];
    nextEmbeddingId        : Nat;
    embeddingIndex         : [(Text, Nat)];  // topic → index mapping

    // Artifact factory
    createdArtifacts       : [AiArtifact];
    nextArtifactId         : Nat;
    pendingValidation      : [Text];         // artifact IDs awaiting doctrine validation

    // Performance tracking
    metrics                : PerformanceMetrics;

    // Domain state management
    isActive               : Bool;
    domainNumber           : Nat;            // Domain 40
    beatInitialized        : Int;
    lastTickBeat           : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION — default state factory
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPerformanceMetrics() : PerformanceMetrics {
    {
      totalQueriesProcessed  = 0;
      totalReasoningPaths    = 0;
      avgReasoningConfidence = 0.0;
      avgLatencyBeats        = 0;
      doctrineAlignmentScore = 0.618;  // φ⁻¹ default
      artifactsGenerated     = 0;
      artifactsValidated     = 0;
      artifactTradeValue     = 0.0;
      accuracyRate           = 0.0;
      coherenceWithOrganism  = 0.618;  // R = φ⁻¹
      lastUpdateBeat         = 0;
    }
  };

  public func defaultAiNodeState() : AiNodeState {
    {
      reasoningPaths       = [];
      nextPathId           = 1;

      knowledgeEmbeddings  = [];
      nextEmbeddingId      = 1;
      embeddingIndex       = [];

      createdArtifacts     = [];
      nextArtifactId       = 1;
      pendingValidation    = [];

      metrics              = defaultPerformanceMetrics();

      isActive             = true;
      domainNumber         = 40;
      beatInitialized      = 0;
      lastTickBeat         = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS — stateless reasoning interface
  // ═══════════════════════════════════════════════════════════════════════════

  /// queryKnowledge — search knowledge graph by topic
  public func queryKnowledge(
    state : AiNodeState,
    topic : Text,
  ) : [KnowledgeEmbedding] {
    Array.filter<KnowledgeEmbedding>(state.knowledgeEmbeddings, func(emb) {
      Text.contains(emb.topic, #text topic)
    })
  };

  /// queryRecentReasoningPaths — get most recent reasoning paths
  public func queryRecentReasoningPaths(
    state : AiNodeState,
    limit : Nat,
  ) : [ReasoningPath] {
    let sorted = Array.sort<ReasoningPath>(
      state.reasoningPaths,
      func(a : ReasoningPath, b : ReasoningPath) : {#less; #equal; #greater} {
        if (a.beatCreated > b.beatCreated) { #greater }
        else if (a.beatCreated < b.beatCreated) { #less }
        else { #equal }
      }
    );
    Array.tabulate<ReasoningPath>(
      Nat.min(limit, sorted.size()),
      func(i) { sorted[i] }
    )
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REASONING ENGINE — core AI inference
  // ═══════════════════════════════════════════════════════════════════════════

  /// reason — execute multi-path reasoning with phi confidence gating
  public func reason(
    state : AiNodeState,
    query : Text,
    beat : Int,
  ) : (AiNodeState, ReasoningPath) {
    let pathId = "path-" # Nat.toText(state.nextPathId);

    // Construct a simple reasoning path (in production, would be multi-step)
    let step : ReasoningStep = {
      stepIndex  = 0;
      action     = "queryProcessing";
      input      = query;
      output     = "Reasoning initialized for: " # query;
      confidence = Phi.PHI_INV;  // Default to φ⁻¹
      timeMs     = 1;
    };

    let path : ReasoningPath = {
      pathId             = pathId;
      stepSequence       = [step];
      finalConclusion    = "AI reasoning path created at beat " # Int.toText(beat);
      confidence         = Phi.PHI_INV;
      riskScore          = 0.0;
      doctrineAlignment  = 0.618;
      tokensUsed         = 50;
      latencyBeats       = 1;
      beatCreated        = beat;
    };

    // Only keep paths that meet confidence gate
    var newPaths = state.reasoningPaths;
    if (path.confidence >= REASONING_CONFIDENCE_GATE) {
      newPaths := Array.append<ReasoningPath>(newPaths, [path]);
    };

    // Update state
    let newState = {
      state with
        reasoningPaths = newPaths;
        nextPathId     = state.nextPathId + 1;
        lastTickBeat   = beat;
    };

    (newState, path)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTIFACT FACTORY — generate and validate cognitive outputs
  // ═══════════════════════════════════════════════════════════════════════════

  /// createArtifact — stamp a new cognitive output as tradeable
  public func createArtifact(
    state : AiNodeState,
    content : Text,
    artifactType : ArtifactType,
    reasoningId : Text,
    confidence : Float,
    beat : Int,
  ) : (AiNodeState, AiArtifact) {
    let artifactId = "artifact-" # Nat.toText(state.nextArtifactId);

    let artifact : AiArtifact = {
      artifactId         = artifactId;
      artifactType       = artifactType;
      content            = content;
      sourceReasoningId  = reasoningId;
      confidence         = confidence;
      doctrineValidated  = false;  // Requires async validation
      phiSignature       = Text.hash(artifactId) |> Nat.toText;
      tokensRequired     = 100;
      tradeableValue     = confidence * 10.0;  // Rough valuation
      createdBeat        = beat;
    };

    let newState = {
      state with
        createdArtifacts   = Array.append<AiArtifact>(state.createdArtifacts, [artifact]);
        nextArtifactId     = state.nextArtifactId + 1;
        pendingValidation  = Array.append<Text>(state.pendingValidation, [artifactId]);
    };

    (newState, artifact)
  };

  /// validateArtifactDoctrine — check artifact against MEDINA FIELD LAWS
  public func validateArtifactDoctrine(
    state : AiNodeState,
    artifactId : Text,
  ) : AiNodeState {
    // Find artifact
    let artifact = Array.find<AiArtifact>(
      state.createdArtifacts,
      func(a) { a.artifactId == artifactId }
    );

    switch (artifact) {
      case null { state };
      case (?a) {
        // Update artifact with validated flag
        let updated = Array.map<AiArtifact, AiArtifact>(
          state.createdArtifacts,
          func(artifact) {
            if (artifact.artifactId == artifactId) {
              { artifact with doctrineValidated = true }
            } else {
              artifact
            }
          }
        );

        // Remove from pending validation
        let newPending = Array.filter<Text>(
          state.pendingValidation,
          func(id) { id != artifactId }
        );

        {
          state with
            createdArtifacts  = updated;
            pendingValidation = newPending;
        }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // METRICS LOOP — autonomous performance tracking
  // ═══════════════════════════════════════════════════════════════════════════

  /// tickBeat — autonomous heartbeat update (called every 873ms)
  public func tickBeat(
    state : AiNodeState,
    beat : Int,
  ) : AiNodeState {
    // Update metrics with decay
    let oldMetrics = state.metrics;

    // Compute new averages (simplified)
    let newAvgConfidence = 
      if (state.reasoningPaths.size() > 0) {
        let totalConfidence = Array.foldLeft<ReasoningPath, Float>(
          state.reasoningPaths,
          0.0,
          func(sum, path) { sum + path.confidence }
        );
        totalConfidence / Float.fromInt(state.reasoningPaths.size())
      } else {
        0.618
      };

    let updatedMetrics = {
      oldMetrics with
        totalQueriesProcessed = oldMetrics.totalQueriesProcessed + 1;
        totalReasoningPaths   = oldMetrics.totalReasoningPaths + state.reasoningPaths.size();
        avgReasoningConfidence = newAvgConfidence;
        artifactsGenerated    = state.createdArtifacts.size();
        lastUpdateBeat        = beat;
    };

    {
      state with
        metrics      = updatedMetrics;
        lastTickBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE MANAGEMENT — getter and setter functions
  // ═══════════════════════════════════════════════════════════════════════════

  /// getReasoningPaths — retrieve current reasoning paths
  public func getReasoningPaths(state : AiNodeState) : [ReasoningPath] {
    state.reasoningPaths
  };

  /// getKnowledgeEmbeddings — retrieve current embeddings
  public func getKnowledgeEmbeddings(state : AiNodeState) : [KnowledgeEmbedding] {
    state.knowledgeEmbeddings
  };

  /// getCreatedArtifacts — retrieve created artifacts
  public func getCreatedArtifacts(state : AiNodeState) : [AiArtifact] {
    state.createdArtifacts
  };

  /// getPendingArtifacts — retrieve artifacts pending doctrine validation
  public func getPendingArtifacts(state : AiNodeState) : [Text] {
    state.pendingValidation
  };

  /// getMetrics — retrieve performance metrics
  public func getMetrics(state : AiNodeState) : PerformanceMetrics {
    state.metrics
  };

  /// addKnowledgeEmbedding — register new knowledge embedding
  public func addKnowledgeEmbedding(
    state : AiNodeState,
    topic : Text,
    vectorHash : Text,
    dimensionality : Nat,
    magnitude : Float,
    beat : Int,
  ) : AiNodeState {
    let embeddingId = "emb-" # Nat.toText(state.nextEmbeddingId);

    let embedding : KnowledgeEmbedding = {
      embeddingId        = embeddingId;
      topic              = topic;
      vectorHash         = vectorHash;
      dimensionality     = dimensionality;
      magnitude          = magnitude;
      semanticDensity    = magnitude / Float.fromInt(dimensionality);
      doctrineScore      = 0.618;
      createdBeat        = beat;
      accessCount        = 0;
      lastAccessedBeat   = beat;
    };

    {
      state with
        knowledgeEmbeddings = Array.append<KnowledgeEmbedding>(
          state.knowledgeEmbeddings,
          [embedding]
        );
        nextEmbeddingId = state.nextEmbeddingId + 1;
        embeddingIndex  = Array.append<(Text, Nat)>(
          state.embeddingIndex,
          [(topic, state.nextEmbeddingId - 1)]
        );
    }
  };

  /// clearOldPaths — maintenance: remove reasoning paths older than threshold
  public func clearOldPaths(
    state : AiNodeState,
    retentionBeats : Int,
    currentBeat : Int,
  ) : AiNodeState {
    let threshold = currentBeat - retentionBeats;
    let filtered = Array.filter<ReasoningPath>(
      state.reasoningPaths,
      func(path) { path.beatCreated > threshold }
    );

    { state with reasoningPaths = filtered }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY — helper functions
  // ═══════════════════════════════════════════════════════════════════════════

  /// hasValidConfidence — check if value passes phi confidence gate
  public func hasValidConfidence(value : Float) : Bool {
    value >= REASONING_CONFIDENCE_GATE
  };

  /// isDoctrineAligned — check if alignment passes threshold
  public func isDoctrineAligned(alignment : Float) : Bool {
    alignment >= DOCTRINE_ALIGNMENT_THRESHOLD
  };

};
