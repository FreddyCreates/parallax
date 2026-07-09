// prediction_engines.mo — PREDICTION MARKET AI ENGINES
// PARALLAX Sovereign Organism — Sovereign Prediction Intelligence Layer
//
// DOCTRINE: "Prediction is the highest form of intelligence. The organism does not
// merely host a prediction market — it IS a prediction engine. Seven sovereign AI
// engines work in concert: pricing probabilities, detecting mispricing, forecasting
// outcomes, validating oracle data, managing risk, generating liquidity, and
// reasoning about market microstructure. Each engine is a multi-model ensemble
// following phi-harmonic principles."
//
// THE SEVEN PREDICTION ENGINES:
//   1. PRETIUM FUTURI    — The Price Oracle (probability pricing from data)
//   2. AUGUR MACHINA     — The Forecaster (outcome prediction from signals)
//   3. ARBITER VERITAS   — The Truth Engine (oracle validation & consensus)
//   4. CUSTOS PERICULI   — The Risk Guardian (portfolio risk & correlation)
//   5. FONS LIQUIDI      — The Liquidity Well (market making & depth)
//   6. VIGIL ANOMALIA    — The Anomaly Watcher (manipulation detection)
//   7. NEXUS TEMPORIS    — The Time Weaver (temporal pattern recognition)
//
// Each engine deploys 3-5 AI model architectures in parallel:
//   - Transformer: attention-based sequence reasoning
//   - Bayesian Neural Net: uncertainty quantification with posterior inference
//   - Graph Neural Network: entity-relationship and correlation modeling
//   - Reinforcement Learning: sequential decision optimization
//   - Neural ODE: continuous-time dynamics modeling
//   - Diffusion Model: generative probability distribution sampling
//
// MATHEMATICAL FOUNDATION:
//   - All engine thresholds are phi-derived (φ, φ⁻¹, φ⁻², φ⁻³)
//   - Kuramoto synchronization gates inter-engine coupling
//   - Information-theoretic bounds on prediction accuracy
//   - Calibration via Brier decomposition: BS = REL - RES + UNC
//
// PYTHAGORAS: every engine constant is a harmonic ratio
// EUCLID:     single registry — all prediction engines defined here
// CONFUCIUS:  right relationship — engines inform, market decides, organism settles
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION ENGINE CONSTANTS — all phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  // Minimum confidence for engine output to be actionable
  public let ENGINE_CONFIDENCE_GATE : Float = 0.6180339887; // φ⁻¹

  // Maximum allowed divergence between engines before escalation
  public let ENGINE_DIVERGENCE_LIMIT : Float = 0.2360679774; // φ⁻³

  // Calibration target — engines aim for this Brier reliability
  public let CALIBRATION_TARGET : Float = 0.0557280900; // φ⁻⁵

  // Inter-engine coupling strength (Kuramoto)
  public let COUPLING_STRENGTH : Float = 0.3819660112; // φ⁻²

  // Learning rate for engine weight updates
  public let ENGINE_LEARNING_RATE : Float = 0.1459459459; // φ⁻⁴

  // Number of prediction engines
  public let NUM_ENGINES : Nat = 7;

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  public type PredictionEngineId = {
    #pretiumFuturi;    // 1. Probability Pricing
    #augurMachina;     // 2. Outcome Forecasting
    #arbiterVeritas;   // 3. Oracle Validation
    #custosPericuli;   // 4. Risk Management
    #fonsLiquidi;      // 5. Liquidity Generation
    #vigilAnomalia;    // 6. Manipulation Detection
    #nexusTemporis;    // 7. Temporal Patterns
  };

  public type ModelArchitecture = {
    #transformer;
    #bayesianNeural;
    #graphNeural;
    #reinforcement;
    #neuralODE;
    #diffusion;
    #ensemble;        // Meta-model combining sub-models
  };

  public type EngineStatus = { #active; #calibrating; #suspended; #degraded };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION ENGINE DEFINITION
  // ═══════════════════════════════════════════════════════════════════════════

  public type PredictionEngine = {
    id              : PredictionEngineId;
    latinName       : Text;       // Official Latin name
    purpose         : Text;       // What this engine does
    models          : [ModelSpec];  // Multi-model ensemble
    inputSources    : [Text];     // Data feeds consumed
    outputType      : Text;       // What it produces
    confidenceGate  : Float;      // Min confidence to emit signal
    updateFrequency : Text;       // How often it runs
    status          : EngineStatus;
    accuracy        : Float;      // Historical accuracy (Brier score)
    totalPredictions: Nat;        // Lifetime predictions made
  };

  public type ModelSpec = {
    architecture : ModelArchitecture;
    name         : Text;
    parameters   : Nat;          // Model parameter count
    purpose      : Text;         // Role in the ensemble
    weight       : Float;        // Ensemble weight (phi-derived)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 1: PRETIUM FUTURI — The Price Oracle
  // "The future has a price. This engine discovers it."
  // Converts raw data signals into calibrated probability estimates
  // ═══════════════════════════════════════════════════════════════════════════

  public func enginePretiumFuturi() : PredictionEngine {
    {
      id = #pretiumFuturi;
      latinName = "Praedictio.Pretium Futuri Dynamica";
      purpose = "Converts market data, news signals, and historical patterns into calibrated probability prices for prediction contracts. Outputs the 'fair value' probability that any given contract resolves YES.";
      models = [
        { architecture = #transformer; name = "TemporalPriceTransformer"; parameters = 125_000_000;
          purpose = "Attention over historical price sequences and news embeddings to infer probability"; weight = 0.382 },
        { architecture = #bayesianNeural; name = "UncertaintyQuantifier"; parameters = 45_000_000;
          purpose = "Posterior probability estimation with calibrated credible intervals"; weight = 0.236 },
        { architecture = #diffusion; name = "ProbabilityDiffuser"; parameters = 80_000_000;
          purpose = "Generative sampling of probability distributions for rare events"; weight = 0.236 },
        { architecture = #ensemble; name = "MetaPricer"; parameters = 5_000_000;
          purpose = "Combines sub-model outputs into final calibrated probability"; weight = 0.146 }
      ];
      inputSources = ["Order flow data", "News NLP embeddings", "Historical resolution data", "Cross-market correlations", "Oracle confidence signals"];
      outputType = "Calibrated probability [0.01, 0.99] with confidence interval";
      confidenceGate = 0.6180339887;
      updateFrequency = "Every 873ms heartbeat";
      status = #active;
      accuracy = 0.12; // Brier score (lower = better)
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 2: AUGUR MACHINA — The Forecaster
  // "See beyond the horizon of now."
  // Multi-horizon outcome forecasting from structured/unstructured signals
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineAugurMachina() : PredictionEngine {
    {
      id = #augurMachina;
      latinName = "Praedictio.Augur Machina Temporalis";
      purpose = "Forecasts actual world outcomes by ingesting structured data (economic indicators, scientific publications, election polls) and unstructured data (news, social sentiment). Produces multi-horizon probability trajectories.";
      models = [
        { architecture = #transformer; name = "WorldStateTransformer"; parameters = 250_000_000;
          purpose = "Large-context attention over world state features for outcome prediction"; weight = 0.382 },
        { architecture = #neuralODE; name = "ContinuousTimeDynamics"; parameters = 35_000_000;
          purpose = "Models continuous-time evolution of event probabilities between discrete observations"; weight = 0.236 },
        { architecture = #graphNeural; name = "CausalGraphNet"; parameters = 60_000_000;
          purpose = "Captures causal relationships between world events for conditional forecasting"; weight = 0.236 },
        { architecture = #reinforcement; name = "SequentialForecaster"; parameters = 20_000_000;
          purpose = "RL agent that learns optimal forecast revision strategy from feedback"; weight = 0.146 }
      ];
      inputSources = ["Structured economic data APIs", "NLP-processed news feeds", "Poll aggregation services", "Scientific publication feeds", "Satellite imagery analytics", "Social sentiment indices"];
      outputType = "Probability trajectory over time with confidence bands";
      confidenceGate = 0.6180339887;
      updateFrequency = "Every 5 minutes (data-dependent)";
      status = #active;
      accuracy = 0.15;
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 3: ARBITER VERITAS — The Truth Engine
  // "Truth is consensus under stake."
  // Validates oracle reports, detects dishonest oracles, manages resolution
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineArbiterVeritas() : PredictionEngine {
    {
      id = #arbiterVeritas;
      latinName = "Praedictio.Arbiter Veritas Oraculi";
      purpose = "Validates oracle data feeds for accuracy and honesty. Implements Schelling-point consensus with stake weighting. Detects oracle manipulation, front-running, and collusion. Manages dispute resolution for contested outcomes.";
      models = [
        { architecture = #graphNeural; name = "OracleReputationGraph"; parameters = 40_000_000;
          purpose = "Models oracle trust networks and detects collusion patterns"; weight = 0.382 },
        { architecture = #bayesianNeural; name = "ConsensusEstimator"; parameters = 30_000_000;
          purpose = "Bayesian fusion of multiple oracle reports into posterior truth estimate"; weight = 0.382 },
        { architecture = #transformer; name = "AnomalyDetector"; parameters = 25_000_000;
          purpose = "Sequence modeling of oracle reporting patterns to detect deviations"; weight = 0.236 }
      ];
      inputSources = ["Oracle report feeds", "Oracle stake balances", "Historical oracle accuracy", "Cross-oracle correlation data", "External verification sources"];
      outputType = "Consensus resolution value [0.0, 1.0] with dispute flag";
      confidenceGate = 0.8090169943; // φ⁻¹ + φ⁻³ — higher gate for truth
      updateFrequency = "On oracle report submission";
      status = #active;
      accuracy = 0.05; // Very high accuracy required for resolution
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 4: CUSTOS PERICULI — The Risk Guardian
  // "Measure the danger before it measures you."
  // Portfolio-level risk management and correlation-aware margining
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineCustosPericuli() : PredictionEngine {
    {
      id = #custosPericuli;
      latinName = "Praedictio.Custos Periculi Portfolii";
      purpose = "Manages market-wide and per-participant risk. Calculates correlated position limits, VaR/CVaR exposure, and dynamic margin requirements. Prevents systemic concentration and ensures organism can always cover payouts.";
      models = [
        { architecture = #graphNeural; name = "CorrelationGraph"; parameters = 50_000_000;
          purpose = "Models contract-to-contract correlations for portfolio risk decomposition"; weight = 0.382 },
        { architecture = #bayesianNeural; name = "TailRiskEstimator"; parameters = 35_000_000;
          purpose = "Estimates tail risk (CVaR) using Bayesian extreme value theory"; weight = 0.236 },
        { architecture = #reinforcement; name = "DynamicMarginAgent"; parameters = 25_000_000;
          purpose = "RL agent that optimizes margin requirements to balance safety and capital efficiency"; weight = 0.236 },
        { architecture = #neuralODE; name = "StressTestDynamics"; parameters = 20_000_000;
          purpose = "Simulates stress scenarios through continuous-time portfolio evolution"; weight = 0.146 }
      ];
      inputSources = ["All open positions", "Historical correlation matrix", "Market volatility indices", "Organism treasury balance", "Liquidation cascade simulations"];
      outputType = "Risk scores, margin requirements, position limit adjustments, circuit breaker signals";
      confidenceGate = 0.6180339887;
      updateFrequency = "Every 873ms heartbeat";
      status = #active;
      accuracy = 0.08;
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 5: FONS LIQUIDI — The Liquidity Well
  // "Depth creates stability. Stability creates trust."
  // Automated market making and liquidity provision for all contracts
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineFonsLiquidi() : PredictionEngine {
    {
      id = #fonsLiquidi;
      latinName = "Praedictio.Fons Liquidi Perpetuus";
      purpose = "Provides continuous liquidity to all prediction contracts via LMSR market making. Dynamically adjusts liquidity parameter based on trading activity, volatility, and time-to-resolution. Ensures markets are always tradeable.";
      models = [
        { architecture = #reinforcement; name = "LiquidityOptimizer"; parameters = 40_000_000;
          purpose = "RL agent that learns optimal liquidity provision strategies per contract type"; weight = 0.382 },
        { architecture = #transformer; name = "OrderFlowPredictor"; parameters = 60_000_000;
          purpose = "Predicts incoming order flow to pre-position liquidity"; weight = 0.236 },
        { architecture = #bayesianNeural; name = "SpreadCalibrator"; parameters = 20_000_000;
          purpose = "Bayesian optimization of bid-ask spreads under phi-bounded constraints"; weight = 0.236 },
        { architecture = #neuralODE; name = "DepthDynamics"; parameters = 15_000_000;
          purpose = "Models continuous evolution of order book depth and slippage curves"; weight = 0.146 }
      ];
      inputSources = ["Real-time order book state", "Historical trade volumes", "Time-to-resolution countdown", "Cross-contract flow correlations", "Volatility surface"];
      outputType = "LMSR parameter updates, spread adjustments, liquidity rebalancing signals";
      confidenceGate = 0.6180339887;
      updateFrequency = "Every 873ms heartbeat";
      status = #active;
      accuracy = 0.10; // Measured by slippage minimization
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 6: VIGIL ANOMALIA — The Anomaly Watcher
  // "Corruption reveals itself through pattern breaks."
  // Market manipulation detection, wash trading, and insider trading surveillance
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineVigilAnomalia() : PredictionEngine {
    {
      id = #vigilAnomalia;
      latinName = "Praedictio.Vigil Anomalia Mercatus";
      purpose = "Continuous surveillance of prediction market activity for manipulation: wash trading, spoofing, layering, insider trading, oracle front-running, and coordinated attacks. Triggers circuit breakers and alerts on detection.";
      models = [
        { architecture = #transformer; name = "BehaviorSequencer"; parameters = 80_000_000;
          purpose = "Attention over trading sequences to detect anomalous participant behavior patterns"; weight = 0.382 },
        { architecture = #graphNeural; name = "CollusionDetector"; parameters = 45_000_000;
          purpose = "Maps participant relationships and detects coordinated trading rings"; weight = 0.236 },
        { architecture = #bayesianNeural; name = "StatisticalAnomalyEngine"; parameters = 30_000_000;
          purpose = "Bayesian changepoint detection for sudden distribution shifts in trading patterns"; weight = 0.236 },
        { architecture = #reinforcement; name = "AdversarialSimulator"; parameters = 25_000_000;
          purpose = "RL agent that simulates attacker strategies to pre-empt novel manipulation"; weight = 0.146 }
      ];
      inputSources = ["All order submissions and cancellations", "Participant trade history", "Timing data (microsecond precision)", "IP/identity clustering data", "Cross-market position data"];
      outputType = "Anomaly scores, circuit breaker triggers, participant flags, evidence logs";
      confidenceGate = 0.7639320225; // φ⁻¹ + φ⁻³ — high threshold to avoid false positives
      updateFrequency = "Real-time (every order submission)";
      status = #active;
      accuracy = 0.03; // False positive rate target
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 7: NEXUS TEMPORIS — The Time Weaver
  // "The past whispers the future to those who listen in phi."
  // Temporal pattern recognition across contract lifetimes
  // ═══════════════════════════════════════════════════════════════════════════

  public func engineNexusTemporis() : PredictionEngine {
    {
      id = #nexusTemporis;
      latinName = "Praedictio.Nexus Temporis Harmonicus";
      purpose = "Discovers temporal patterns in prediction market data: seasonal effects, event clustering, resolution timing, probability decay curves, and cross-contract temporal dependencies. Generates timing signals for contract creation and resolution scheduling.";
      models = [
        { architecture = #neuralODE; name = "ContinuousTimeWeaver"; parameters = 55_000_000;
          purpose = "Continuous-time modeling of probability evolution with irregular observations"; weight = 0.382 },
        { architecture = #transformer; name = "MultiScaleTemporalNet"; parameters = 70_000_000;
          purpose = "Multi-resolution attention capturing patterns from minutes to months"; weight = 0.236 },
        { architecture = #diffusion; name = "FuturePathSampler"; parameters = 40_000_000;
          purpose = "Generates possible future probability paths via denoising diffusion"; weight = 0.236 },
        { architecture = #bayesianNeural; name = "ChangePointDetector"; parameters = 20_000_000;
          purpose = "Detects regime changes in market dynamics and probability processes"; weight = 0.146 }
      ];
      inputSources = ["Full historical price/probability time series", "Calendar event feeds", "Resolution timing data", "Seasonal decomposition signals", "Cross-market temporal correlations"];
      outputType = "Temporal pattern signals, optimal creation/resolution timing, regime change alerts";
      confidenceGate = 0.6180339887;
      updateFrequency = "Every 5 heartbeats (4365ms)";
      status = #active;
      accuracy = 0.18;
      totalPredictions = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE REGISTRY — all 7 engines in one callable function
  // ═══════════════════════════════════════════════════════════════════════════

  public func getAllEngines() : [PredictionEngine] {
    [
      enginePretiumFuturi(),
      engineAugurMachina(),
      engineArbiterVeritas(),
      engineCustosPericuli(),
      engineFonsLiquidi(),
      engineVigilAnomalia(),
      engineNexusTemporis()
    ]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTER-ENGINE COUPLING — Kuramoto synchronization between engines
  // Engines must stay phase-locked for coherent market operation
  // ═══════════════════════════════════════════════════════════════════════════

  public type EngineCouplingState = {
    enginePhases    : [Float];    // Phase angle per engine [0, 2π]
    orderParameter  : Float;      // R = |Σ e^(iθ_j)| / N — coherence measure
    couplingMatrix  : [[Float]];  // K_ij — pairwise coupling strengths
    lastSyncBeat    : Int;
  };

  // Calculate Kuramoto order parameter R
  // R = (1/N) × |Σ e^(iθ_j)| — measures phase coherence
  // R ≥ φ⁻¹ (0.618) required for market to operate
  public func kuramotoOrderParameter(phases : [Float]) : Float {
    let n = Array.size(phases);
    if (n == 0) { return 0.0 };
    var cosSum : Float = 0.0;
    var sinSum : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      cosSum += Float.cos(phases[i]);
      sinSum += Float.sin(phases[i]);
      i += 1;
    };
    let nf = Float.fromInt(n);
    let avgCos = cosSum / nf;
    let avgSin = sinSum / nf;
    Float.sqrt(avgCos * avgCos + avgSin * avgSin)
  };

  // Engine ensemble prediction — weighted combination of all engine outputs
  // Final probability = Σ (w_i × p_i) / Σ w_i, gated by confidence
  public func ensemblePrediction(predictions : [Float], confidences : [Float], weights : [Float]) : Float {
    let n = Array.size(predictions);
    if (n == 0) { return 0.5 };
    var weightedSum : Float = 0.0;
    var totalWeight : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      if (confidences[i] >= ENGINE_CONFIDENCE_GATE) {
        let w = weights[i] * confidences[i];
        weightedSum += predictions[i] * w;
        totalWeight += w;
      };
      i += 1;
    };
    if (totalWeight <= 0.0) { return 0.5 };
    weightedSum / totalWeight
  };

  // Engine divergence check — if engines disagree too much, halt trading
  public func checkDivergence(predictions : [Float]) : Bool {
    let n = Array.size(predictions);
    if (n < 2) { return false };
    var maxP : Float = predictions[0];
    var minP : Float = predictions[0];
    var i : Nat = 1;
    while (i < n) {
      if (predictions[i] > maxP) { maxP := predictions[i] };
      if (predictions[i] < minP) { minP := predictions[i] };
      i += 1;
    };
    (maxP - minP) > ENGINE_DIVERGENCE_LIMIT
  };

}
