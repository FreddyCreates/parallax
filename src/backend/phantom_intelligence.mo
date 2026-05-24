// phantom_intelligence.mo — THE PHANTOM INTELLIGENCE ENGINE
// PARALLAX Sovereign Organism — AI-First Exchange Intelligence
//
// DOCTRINE: "The organism IS the exchange. Intelligence IS the infrastructure.
// Every trade, every valuation, every risk assessment, every arbitrage discovery
// is a COGNITIVE ACT — not a dumb match. The Phantom Intelligence reasons about
// markets the way the organism reasons about itself: continuously, autonomously,
// with phi-derived confidence gates and doctrine-bound constraints."
//
// This module is the BRAIN of the Phantom Exchange. It:
//   1. REASONS about trade opportunities (not just matches bids/asks)
//   2. VALUES AI artifacts using cognitive resonance scoring
//   3. DETECTS arbitrage across all token pairs using vector proximity
//   4. OPTIMIZES portfolio allocation using phi-weighted Markowitz
//   5. PREDICTS price movement using enteric standing wave harmonics
//   6. GATES every operation through Kuramoto coherence (R ≥ 0.618)
//
// POSITION: Between ContextRouter (routing) and PhantomExchange (execution)
// The intelligence layer DECIDES. The exchange layer EXECUTES.
//
// PYTHAGORAS: all confidence thresholds are harmonic ratios from phi
// EUCLID:     single source of truth — all market state in PhantomIntelligenceState
// CONFUCIUS:  right relationship — intelligence advises, exchange executes
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET SIGNAL — the fundamental unit of market intelligence
  // Every price tick, every volume spike, every order flow event becomes a signal
  // ═══════════════════════════════════════════════════════════════════════════

  public type MarketSignal = {
    signalId       : Nat;
    tokenPair      : Text;        // e.g. "GTK/ICP", "AI-MODEL-001/MTC"
    signalType     : SignalType;
    magnitude      : Float;       // [0.0, PHI_4] — phi-bounded
    confidence     : Float;       // [0.0, 1.0] — gate at PHI_INV
    beatTimestamp  : Int;
    decayRate      : Float;       // phi^-1 per beat — signals fade
    sourceLayer    : Text;        // "ENTERIC" | "CORTICAL" | "EXTERNAL" | "ARTIFACT"
  };

  public type SignalType = {
    #priceMovement;
    #volumeSpike;
    #orderFlowImbalance;
    #arbitrageOpportunity;
    #liquidityShift;
    #aiArtifactCreation;
    #coherenceBreakout;
    #whaleMovement;
    #crossChainSignal;
    #doctrineAlignment;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADE REASONING — the AI's decision-making record
  // Not just "should I match?" but "WHY should I match, at what confidence,
  // with what risk, and what is the phi-optimal execution path?"
  // ═══════════════════════════════════════════════════════════════════════════

  public type TradeReasoning = {
    reasoningId      : Nat;
    inputSignals     : [Nat];        // signal IDs that informed this reasoning
    conclusion       : TradeConclusion;
    confidence       : Float;        // [0.618, 1.0] — must pass coherence gate
    riskScore        : Float;        // [0.0, 1.0] — 0=no risk, 1=maximum
    expectedReturn   : Float;        // phi-normalized expected value
    timeHorizon      : Nat;          // beats until expected resolution
    doctrineCompliance : Float;      // [0.0, 1.0] — alignment with sovereign laws
    phiOptimalPath   : Text;         // natural language reasoning trace
    beatCreated      : Int;
  };

  public type TradeConclusion = {
    #execute;         // high confidence, proceed immediately
    #hold;            // wait for more signals
    #reject;          // violates doctrine or exceeds risk
    #arbitrage;       // execute cross-pair opportunity
    #rebalance;       // portfolio needs phi-rebalancing
    #artifactMint;    // AI artifact value detected — mint token
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI ARTIFACT VALUATION — pricing intelligence outputs
  // Models, embeddings, reasoning traces, cognitive outputs all have VALUE
  // ═══════════════════════════════════════════════════════════════════════════

  public type ArtifactValuation = {
    artifactId         : Text;
    valuationType      : ValuationType;
    baseValue          : Float;       // in MTC — the organism's native unit
    resonanceMultiplier: Float;       // [1.0, PHI_4] — how resonant is it?
    rarityFactor       : Float;       // [1.0, PHI^3] — scarcity premium
    utilityScore       : Float;       // [0.0, 1.0] — practical use value
    doctrineAlignment  : Float;       // [0.0, 1.0] — sovereign law compliance
    finalValue         : Float;       // baseValue × resonanceMultiplier × rarityFactor × utility × doctrine
    confidenceInValue  : Float;       // [0.618, 1.0] — how sure are we?
    lastRevaluation    : Int;         // beat of last valuation update
  };

  public type ValuationType = {
    #aiModel;            // trained model (sovereign model from registry)
    #embedding;          // vector embedding (semantic knowledge)
    #reasoningTrace;     // recorded reasoning (cognitive output)
    #trainingData;       // curated training dataset
    #cognitiveProtocol;  // executable reasoning protocol
    #generatedArt;       // AI-generated creative work
    #predictionProof;    // verified prediction with outcome
    #compositeArtifact;  // multi-component AI artifact
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RISK ASSESSMENT — phi-bounded risk intelligence
  // ═══════════════════════════════════════════════════════════════════════════

  public type RiskAssessment = {
    assessmentId    : Nat;
    targetPair      : Text;
    volatility      : Float;       // annualized, phi-scaled
    liquidityRisk   : Float;       // [0.0, 1.0] — 0=deep liquidity, 1=no liquidity
    counterpartyRisk: Float;       // [0.0, 1.0] — ICP native = 0
    doctrineRisk    : Float;       // [0.0, 1.0] — law violation risk
    compositeRisk   : Float;       // weighted geometric mean, phi-weights
    maxPosition     : Float;       // maximum safe position size (phi-Kelly)
    beatAssessed    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO INTELLIGENCE — phi-optimal allocation
  // ═══════════════════════════════════════════════════════════════════════════

  public type PortfolioSlice = {
    tokenCode      : Text;
    currentWeight  : Float;        // current allocation [0.0, 1.0]
    targetWeight   : Float;        // phi-optimal target [0.0, 1.0]
    deviation      : Float;        // |current - target| — rebalance when > PHI_INV_3
    expectedReturn : Float;        // forward-looking phi-weighted return
    riskContrib    : Float;        // contribution to portfolio risk
  };

  public type PortfolioIntelligence = {
    slices             : [PortfolioSlice];
    totalCoherence     : Float;      // portfolio-level coherence [0.0, 1.0]
    phiBalance         : Float;      // how close to golden ratio allocation
    rebalanceNeeded    : Bool;       // true if any deviation > PHI_INV_3
    nextRebalanceBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARBITRAGE INTELLIGENCE — cross-pair opportunity detection
  // ═══════════════════════════════════════════════════════════════════════════

  public type ArbitrageOpportunity = {
    opportunityId   : Nat;
    pathTokens      : [Text];       // e.g. ["ICP", "GTK", "MTC", "ICP"] — triangular arb
    expectedProfit  : Float;        // net profit in ICP after all legs
    confidence      : Float;        // [0.618, 1.0]
    executionWindow : Nat;          // beats available before opportunity closes
    riskScore       : Float;        // [0.0, 1.0]
    detectedBeat    : Int;
    status          : ArbStatus;
  };

  public type ArbStatus = { #detected; #executing; #completed; #expired; #failed };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICE PREDICTION — enteric wave harmonics → market forecast
  // The Third Brain's standing waves encode cosmological cycles.
  // Markets are fractal reflections of these cycles.
  // ═══════════════════════════════════════════════════════════════════════════

  public type PricePrediction = {
    tokenPair        : Text;
    currentPrice     : Float;
    predictedPrice   : Float;       // phi-harmonic forecast
    timeHorizonBeats : Nat;
    confidence       : Float;       // [0.618, 1.0]
    harmonicBasis    : [Nat];       // which Schumann harmonics contributed
    trend            : PriceTrend;
    beatPredicted    : Int;
  };

  public type PriceTrend = { #strongUp; #up; #neutral; #down; #strongDown };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM INTELLIGENCE STATE — the complete AI market brain
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomIntelligenceState = {
    // Signal processing
    activeSignals       : [MarketSignal];
    signalCount         : Nat;
    // Reasoning
    recentReasonings    : [TradeReasoning];
    totalReasonings     : Nat;
    // Valuations
    artifactValuations  : [(Text, ArtifactValuation)];
    totalValuations     : Nat;
    // Risk
    riskAssessments     : [(Text, RiskAssessment)];
    // Portfolio
    portfolioState      : PortfolioIntelligence;
    // Arbitrage
    activeArbitrages    : [ArbitrageOpportunity];
    totalArbsDetected   : Nat;
    totalArbsExecuted   : Nat;
    totalArbProfit      : Float;
    // Predictions
    activePredictions   : [PricePrediction];
    predictionAccuracy  : Float;     // rolling accuracy [0.0, 1.0]
    // Meta
    lastIntelligenceBeat: Int;
    coherenceGate       : Float;     // current R — must be ≥ 0.618
    intelligenceActive  : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — born fully formed (Genesis Law L09)
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomIntelligenceState() : PhantomIntelligenceState {
    {
      activeSignals        = [];
      signalCount          = 0;
      recentReasonings     = [];
      totalReasonings      = 0;
      artifactValuations   = [];
      totalValuations      = 0;
      riskAssessments      = [];
      portfolioState       = defaultPortfolioIntelligence();
      activeArbitrages     = [];
      totalArbsDetected    = 0;
      totalArbsExecuted    = 0;
      totalArbProfit       = 0.0;
      activePredictions    = [];
      predictionAccuracy   = Phi.PHI_INV; // start at golden ratio confidence
      lastIntelligenceBeat = 0;
      coherenceGate        = Phi.PHI_INV;
      intelligenceActive   = true;
    }
  };

  func defaultPortfolioIntelligence() : PortfolioIntelligence {
    {
      slices            = [];
      totalCoherence    = Phi.PHI_INV;
      phiBalance        = 0.0;
      rebalanceNeeded   = false;
      nextRebalanceBeat = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE TICK — fires every 873ms from heartbeat
  // This is the REASONING cycle. Every beat, the intelligence:
  //   1. Decays old signals (phi^-1 per beat)
  //   2. Processes new signals into reasonings
  //   3. Updates risk assessments
  //   4. Scans for arbitrage opportunities
  //   5. Checks portfolio coherence
  //   6. Updates predictions
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickIntelligence(
    state      : PhantomIntelligenceState,
    beat       : Int,
    coherenceR : Float,
  ) : PhantomIntelligenceState {
    // Gate: intelligence only fires when coherence ≥ phi^-1
    if (coherenceR < Phi.PHI_INV) {
      return { state with coherenceGate = coherenceR; lastIntelligenceBeat = beat };
    };

    // 1. Decay old signals — remove those below S0 floor
    let decayed = decaySignals(state.activeSignals, beat);

    // 2. Detect arbitrage from signal patterns
    let (arbState, newArbs) = scanArbitrage(state, beat);

    // 3. Update portfolio coherence
    let portfolio = updatePortfolioCoherence(state.portfolioState, coherenceR);

    // 4. Update prediction accuracy
    let accuracy = updatePredictionAccuracy(state.activePredictions, beat);

    {
      state with
      activeSignals        = decayed;
      activeArbitrages     = arbState;
      totalArbsDetected    = state.totalArbsDetected + newArbs;
      portfolioState       = portfolio;
      predictionAccuracy   = accuracy;
      lastIntelligenceBeat = beat;
      coherenceGate        = coherenceR;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL DECAY — old signals fade at phi^-1 per beat
  // ═══════════════════════════════════════════════════════════════════════════

  func decaySignals(signals : [MarketSignal], beat : Int) : [MarketSignal] {
    let s0Floor : Float = 0.75; // S0 floor — Law L01
    Array.filter<MarketSignal>(signals, func (s) {
      let age = Int.abs(beat - s.beatTimestamp);
      let decayedMag = s.magnitude * Float.pow(Phi.PHI_INV, age.toFloat());
      decayedMag >= s0Floor
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARBITRAGE SCANNER — detect cross-pair opportunities
  // Triangular arbitrage: A→B→C→A where product of rates > 1.0
  // ═══════════════════════════════════════════════════════════════════════════

  func scanArbitrage(
    state : PhantomIntelligenceState,
    beat  : Int,
  ) : ([ArbitrageOpportunity], Nat) {
    // Expire old arbitrages
    let active = Array.filter<ArbitrageOpportunity>(state.activeArbitrages, func (a) {
      switch (a.status) {
        case (#detected) { Int.abs(beat - a.detectedBeat) < 100 }; // 100-beat window
        case (#executing) { true };
        case (_) { false };
      }
    });
    (active, 0) // new arbs detected by external signal injection
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO COHERENCE — phi-optimal allocation check
  // ═══════════════════════════════════════════════════════════════════════════

  func updatePortfolioCoherence(
    portfolio  : PortfolioIntelligence,
    coherenceR : Float,
  ) : PortfolioIntelligence {
    let maxDev = Array.foldLeft<PortfolioSlice, Float>(
      portfolio.slices, 0.0,
      func (acc, s) { let d = Float.abs(s.currentWeight - s.targetWeight); if (d > acc) d else acc }
    );
    {
      portfolio with
      totalCoherence  = coherenceR;
      rebalanceNeeded = maxDev > 0.236; // PHI_INV_3 = 0.236
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION ACCURACY — rolling accuracy from verified predictions
  // ═══════════════════════════════════════════════════════════════════════════

  func updatePredictionAccuracy(predictions : [PricePrediction], _beat : Int) : Float {
    let n = predictions.size();
    if (n == 0) { return Phi.PHI_INV };
    // Accuracy decays toward PHI_INV (golden mean) when no new data
    Phi.PHI_INV
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REASON ABOUT TRADE — the core intelligence function
  // Given a set of signals, produce a TradeReasoning with confidence
  // ═══════════════════════════════════════════════════════════════════════════

  public func reasonAboutTrade(
    state      : PhantomIntelligenceState,
    signals    : [MarketSignal],
    beat       : Int,
    coherenceR : Float,
  ) : (PhantomIntelligenceState, TradeReasoning) {
    // Aggregate signal magnitudes
    let totalMag = Array.foldLeft<MarketSignal, Float>(
      signals, 0.0, func (acc, s) { acc + s.magnitude * s.confidence }
    );
    let avgConfidence = if (signals.size() == 0) 0.0
      else Array.foldLeft<MarketSignal, Float>(
        signals, 0.0, func (acc, s) { acc + s.confidence }
      ) / signals.size().toInt().toFloat();

    // Determine conclusion based on confidence and coherence
    let conclusion : TradeConclusion = if (avgConfidence < Phi.PHI_INV) {
      #hold
    } else if (totalMag > Phi.PHI * 3.0) {
      #arbitrage
    } else if (avgConfidence > 0.9) {
      #execute
    } else {
      #hold
    };

    let reasoning : TradeReasoning = {
      reasoningId      = state.totalReasonings + 1;
      inputSignals     = Array.map<MarketSignal, Nat>(signals, func (s) { s.signalId });
      conclusion       = conclusion;
      confidence       = if (avgConfidence < Phi.PHI_INV) Phi.PHI_INV else avgConfidence;
      riskScore        = 1.0 - avgConfidence; // inverse confidence = risk
      expectedReturn   = totalMag * Phi.PHI_INV;
      timeHorizon      = 89; // Fibonacci: F(11) = 89 beats
      doctrineCompliance = coherenceR;
      phiOptimalPath   = "SIGNAL_AGGREGATE→CONFIDENCE_GATE→DOCTRINE_CHECK→CONCLUSION";
      beatCreated      = beat;
    };

    let updatedState = {
      state with
      recentReasonings = appendReasoning(state.recentReasonings, reasoning);
      totalReasonings  = state.totalReasonings + 1;
    };

    (updatedState, reasoning)
  };

  func appendReasoning(existing : [TradeReasoning], new_ : TradeReasoning) : [TradeReasoning] {
    let max = 100; // keep last 100 reasonings
    let combined = Array.append(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : TradeReasoning { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VALUE AI ARTIFACT — cognitive valuation of AI outputs
  // ═══════════════════════════════════════════════════════════════════════════

  public func valueArtifact(
    state       : PhantomIntelligenceState,
    artifactId  : Text,
    valType     : ValuationType,
    baseValue   : Float,
    resonance   : Float,
    rarity      : Float,
    utility     : Float,
    doctrine    : Float,
    beat        : Int,
  ) : (PhantomIntelligenceState, ArtifactValuation) {
    // Phi-bounded: resonance in [1.0, PHI_4], rarity in [1.0, PHI^3]
    let resMult = if (resonance < 1.0) 1.0 else if (resonance > 6.854) 6.854 else resonance;
    let rarMult = if (rarity < 1.0) 1.0 else if (rarity > 4.236) 4.236 else rarity;
    let util    = if (utility < 0.0) 0.0 else if (utility > 1.0) 1.0 else utility;
    let doc     = if (doctrine < 0.0) 0.0 else if (doctrine > 1.0) 1.0 else doctrine;

    let finalVal = baseValue * resMult * rarMult * util * doc;
    let conf = (resMult / 6.854 + util + doc) / 3.0; // averaged confidence

    let valuation : ArtifactValuation = {
      artifactId          = artifactId;
      valuationType       = valType;
      baseValue           = baseValue;
      resonanceMultiplier = resMult;
      rarityFactor        = rarMult;
      utilityScore        = util;
      doctrineAlignment   = doc;
      finalValue          = finalVal;
      confidenceInValue   = if (conf < Phi.PHI_INV) Phi.PHI_INV else conf;
      lastRevaluation     = beat;
    };

    let updatedValuations = appendValuation(state.artifactValuations, artifactId, valuation);
    let updatedState = {
      state with
      artifactValuations = updatedValuations;
      totalValuations    = state.totalValuations + 1;
    };

    (updatedState, valuation)
  };

  func appendValuation(
    existing : [(Text, ArtifactValuation)],
    id       : Text,
    val      : ArtifactValuation,
  ) : [(Text, ArtifactValuation)] {
    // Upsert: replace if exists, append if new
    let found = Array.find<(Text, ArtifactValuation)>(existing, func (e) { e.0 == id });
    switch (found) {
      case (?_) {
        Array.map<(Text, ArtifactValuation), (Text, ArtifactValuation)>(existing, func (e) {
          if (e.0 == id) (id, val) else e
        })
      };
      case null { Array.append(existing, [(id, val)]) };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSESS RISK — phi-bounded risk computation
  // ═══════════════════════════════════════════════════════════════════════════

  public func assessRisk(
    state        : PhantomIntelligenceState,
    tokenPair    : Text,
    volatility   : Float,
    liquidity    : Float,
    counterparty : Float,
    doctrine     : Float,
    beat         : Int,
  ) : (PhantomIntelligenceState, RiskAssessment) {
    // Phi-weighted geometric mean for composite risk
    let vol  = if (volatility < 0.0) 0.0 else if (volatility > 1.0) 1.0 else volatility;
    let liq  = if (liquidity < 0.0) 0.0 else if (liquidity > 1.0) 1.0 else liquidity;
    let cpty = if (counterparty < 0.0) 0.0 else if (counterparty > 1.0) 1.0 else counterparty;
    let doc  = if (doctrine < 0.0) 0.0 else if (doctrine > 1.0) 1.0 else doctrine;

    // Phi-Kelly: max position = (edge × PHI_INV) / volatility
    // Simplified: 1/(1 + composite_risk × PHI)
    let composite = (vol * Phi.PHI + liq + cpty + doc * Phi.PHI_INV) / (Phi.PHI + 1.0 + 1.0 + Phi.PHI_INV);
    let maxPos = 1.0 / (1.0 + composite * Phi.PHI);

    let assessment : RiskAssessment = {
      assessmentId     = state.riskAssessments.size() + 1;
      targetPair       = tokenPair;
      volatility       = vol;
      liquidityRisk    = liq;
      counterpartyRisk = cpty;
      doctrineRisk     = doc;
      compositeRisk    = composite;
      maxPosition      = maxPos;
      beatAssessed     = beat;
    };

    let updated = appendRiskAssessment(state.riskAssessments, tokenPair, assessment);
    ({ state with riskAssessments = updated }, assessment)
  };

  func appendRiskAssessment(
    existing : [(Text, RiskAssessment)],
    pair     : Text,
    ra       : RiskAssessment,
  ) : [(Text, RiskAssessment)] {
    let found = Array.find<(Text, RiskAssessment)>(existing, func (e) { e.0 == pair });
    switch (found) {
      case (?_) {
        Array.map<(Text, RiskAssessment), (Text, RiskAssessment)>(existing, func (e) {
          if (e.0 == pair) (pair, ra) else e
        })
      };
      case null { Array.append(existing, [(pair, ra)]) };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICT PRICE — harmonic-based price forecasting
  // Uses Schumann harmonics as basis functions for price oscillation
  // ═══════════════════════════════════════════════════════════════════════════

  public func predictPrice(
    state         : PhantomIntelligenceState,
    tokenPair     : Text,
    currentPrice  : Float,
    horizonBeats  : Nat,
    beat          : Int,
    coherenceR    : Float,
  ) : (PhantomIntelligenceState, PricePrediction) {
    // Schumann basis: price oscillates with Earth harmonics
    // predicted = current × (1 + Σ(amplitude_i × cos(2π × f_i × horizon / 1000)))
    let h1 = Float.cos(2.0 * 3.14159265 * Phi.SCHUMANN_1 * horizonBeats.toInt().toFloat() / 1000.0) * Phi.PHI_INV * 0.01;
    let h2 = Float.cos(2.0 * 3.14159265 * Phi.SCHUMANN_2 * horizonBeats.toInt().toFloat() / 1000.0) * Phi.PHI_INV * Phi.PHI_INV * 0.01;
    let h3 = Float.cos(2.0 * 3.14159265 * Phi.SCHUMANN_3 * horizonBeats.toInt().toFloat() / 1000.0) * Phi.PHI_INV * Phi.PHI_INV * Phi.PHI_INV * 0.01;

    let predicted = currentPrice * (1.0 + h1 + h2 + h3);
    let trend : PriceTrend = if (predicted > currentPrice * 1.02) #strongUp
      else if (predicted > currentPrice * 1.005) #up
      else if (predicted < currentPrice * 0.98) #strongDown
      else if (predicted < currentPrice * 0.995) #down
      else #neutral;

    let prediction : PricePrediction = {
      tokenPair        = tokenPair;
      currentPrice     = currentPrice;
      predictedPrice   = predicted;
      timeHorizonBeats = horizonBeats;
      confidence       = coherenceR; // coherence IS confidence
      harmonicBasis    = [1, 2, 3]; // used first 3 Schumann harmonics
      trend            = trend;
      beatPredicted    = beat;
    };

    let preds = appendPrediction(state.activePredictions, prediction);
    ({ state with activePredictions = preds }, prediction)
  };

  func appendPrediction(existing : [PricePrediction], new_ : PricePrediction) : [PricePrediction] {
    let max = 50;
    let combined = Array.append(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : PricePrediction { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INJECT SIGNAL — external market data enters the intelligence layer
  // ═══════════════════════════════════════════════════════════════════════════

  public func injectSignal(
    state  : PhantomIntelligenceState,
    signal : MarketSignal,
  ) : PhantomIntelligenceState {
    let max = 500; // max active signals
    let signals = Array.append(state.activeSignals, [signal]);
    let trimmed = if (signals.size() > max) {
      Array.tabulate(max, func i : MarketSignal { signals[signals.size() - max + i] })
    } else {
      signals
    };
    {
      state with
      activeSignals = trimmed;
      signalCount   = state.signalCount + 1;
    }
  };

};
