// resident_trader.mo — THE RESIDENT TRADING AGENT
// PARALLAX Sovereign Organism — Supreme Trading Intelligence Orchestrator
//
// PYTHAGORAS: decision weight = phi-rank per engine; consensus threshold = φ⁻¹
// EUCLID:     single resident agent — all trading intelligence converges here
// CONFUCIUS:  right relationship — the resident reasons, engines provide, platforms execute
//
// THE SOVEREIGN RESIDENT LAW (LEX_RESIDENS_MERCATOR):
//   The Resident Trader is the supreme trading decision-maker.
//   It aggregates signals from ALL sovereign engines:
//     - Monte Carlo simulations (probabilistic futures)
//     - Behavioral Economics (market psychology)
//     - ALOHA I Protocols (harmonic arbitrage)
//     - 9 Animal Intelligence engines (biological patterns)
//     - 9 AI Engines (machine learning)
//     - EMA/Technical engines (momentum/trend)
//     - Phantom Intelligence (on-chain reasoning)
//   
//   It synthesizes a SINGLE coherent trading decision per beat.
//   It manages risk according to the Kelly Criterion (half-Kelly conservative).
//   It logs every decision for post-hoc analysis and continuous improvement.
//   It NEVER trades live until demo profitability is proven (LEX_PRUDENTIA).
//
// Architecture:
//   PERCEPTION  — Gather all engine outputs
//   REASONING   — Weight and synthesize signals
//   DECISION    — Generate trade signal or hold
//   EXECUTION   — Route to platform via trading_bridge
//   REFLECTION  — Log outcome, update beliefs
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Int   "mo:core/Int";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // RESIDENT TRADER CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  // Consensus threshold: φ⁻¹ = 0.618 (61.8% of engines must agree)
  public let CONSENSUS_THRESHOLD : Float = Phi.PHI_INV;

  // Conviction minimum: φ⁻² = 0.382 (minimum signal strength to act)
  public let CONVICTION_MINIMUM : Float = Phi.PHI_INV_2;

  // Maximum concurrent strategies: F(6) = 8
  public let MAX_STRATEGIES : Nat = 8;

  // Memory depth: F(12) = 144 decisions remembered
  public let MEMORY_DEPTH : Nat = 144;

  // Reflection interval: F(7) = 13 beats
  public let REFLECTION_INTERVAL : Nat = 13;

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE SIGNAL TYPES — inputs from all sovereign engines
  // ═══════════════════════════════════════════════════════════════════════════

  public type EngineVote = {
    engineName     : Text;          // source engine identifier
    engineType     : EngineClass;   // classification
    direction      : Float;         // [-1, +1] — short to long
    confidence     : Float;         // [0, 1] — signal strength
    timeHorizon    : Nat;           // beats until expected outcome
    reasoning      : Text;          // brief explanation
    weight         : Float;         // phi-derived engine weight
  };

  public type EngineClass = {
    #monteCarlo;        // probabilistic simulation
    #behavioral;        // market psychology
    #alohaProtocol;     // harmonic arbitrage
    #animalIntel;       // biological pattern
    #aiEngine;          // machine learning
    #technical;         // EMA/momentum/trend
    #phantomIntel;      // on-chain reasoning
    #fundamental;       // value-based
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DECISION TYPES — the resident's output
  // ═══════════════════════════════════════════════════════════════════════════

  public type TradingDecision = {
    decisionId       : Text;
    beat             : Int;
    symbol           : Text;         // asset to trade
    action           : DecisionAction;
    direction        : Float;        // [-1, +1] net direction
    conviction       : Float;        // [0, 1] decision strength
    positionSize     : Float;        // fraction of equity
    entryPrice       : Float;        // target entry
    stopLoss         : Float;        // risk management
    takeProfit       : Float;        // profit target
    riskRewardRatio  : Float;        // reward/risk
    consensusScore   : Float;        // engine agreement level
    enginesConsulted : Nat;          // how many engines voted
    enginesAgreeing  : Nat;          // how many agreed with decision
    reasoning        : Text;         // composite reasoning
    kellyFraction    : Float;        // Kelly-optimal size
    regime           : MarketRegime;
  };

  public type DecisionAction = {
    #enterLong;
    #enterShort;
    #exitPosition;
    #addToPosition;
    #reducePosition;
    #hold;               // no action — conviction too low
    #hedgeExposure;
  };

  public type MarketRegime = {
    #trending;           // strong directional move
    #ranging;            // sideways, mean-reverting
    #breakout;           // regime transition
    #volatile;           // high uncertainty
    #quiet;              // low volatility compression
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STRATEGY TYPES — managed by the resident
  // ═══════════════════════════════════════════════════════════════════════════

  public type Strategy = {
    strategyId      : Text;
    name            : Text;
    latinName       : Text;         // sovereign Latin identity
    description     : Text;
    regime          : MarketRegime; // optimal market regime
    primaryEngine   : EngineClass;  // which engine drives this strategy
    winRate         : Float;        // historical win rate
    avgReturn       : Float;        // average return per trade
    maxDrawdown     : Float;        // worst drawdown observed
    sharpeRatio     : Float;        // risk-adjusted performance
    tradeCount      : Nat;          // total trades taken
    isActive        : Bool;         // currently deployed
    allocationPct   : Float;        // capital allocation (% of equity)
    lastTradeBeat   : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RESIDENT TRADER STATE — the complete agent state
  // ═══════════════════════════════════════════════════════════════════════════

  public type ResidentTraderState = {
    // Core identity
    agentName          : Text;
    latinName          : Text;

    // Current perception (latest engine votes)
    currentVotes       : [EngineVote];
    voteConsensus      : Float;       // current consensus level
    netDirection       : Float;       // weighted aggregate direction

    // Active strategies
    strategies         : [Strategy];
    activeStrategyCount: Nat;

    // Decision history
    decisionHistory    : [TradingDecision];
    lastDecision       : TradingDecision;

    // Performance
    totalDecisions     : Nat;
    decisionsActedOn   : Nat;         // non-hold decisions
    successRate        : Float;       // correct direction rate
    avgConviction      : Float;       // average conviction when acting
    portfolioHeat      : Float;       // current risk exposure [0, 1]

    // Market state assessment
    currentRegime      : MarketRegime;
    regimeConfidence   : Float;
    volatilityEstimate : Float;

    // Operational
    residentPhase      : Text;        // "dormant" | "observing" | "reasoning" | "decisive" | "reflecting"
    lastTickBeat       : Int;
    beatsActive        : Nat;
    reflectionDue      : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  func defaultDecision() : TradingDecision {
    {
      decisionId = "GENESIS";
      beat = 0;
      symbol = "NONE";
      action = #hold;
      direction = 0.0;
      conviction = 0.0;
      positionSize = 0.0;
      entryPrice = 0.0;
      stopLoss = 0.0;
      takeProfit = 0.0;
      riskRewardRatio = 0.0;
      consensusScore = 0.0;
      enginesConsulted = 0;
      enginesAgreeing = 0;
      reasoning = "GENESIS — awaiting first market data";
      kellyFraction = 0.0;
      regime = #quiet;
    };
  };

  public func defaultResidentTraderState() : ResidentTraderState {
    {
      agentName           = "MERCATOR RESIDENS";
      latinName           = "Mercator Residens Supremus";

      currentVotes        = [];
      voteConsensus       = 0.0;
      netDirection        = 0.0;

      strategies          = defaultStrategies();
      activeStrategyCount = 0;

      decisionHistory     = [];
      lastDecision        = defaultDecision();

      totalDecisions      = 0;
      decisionsActedOn    = 0;
      successRate         = 0.0;
      avgConviction       = 0.0;
      portfolioHeat       = 0.0;

      currentRegime       = #quiet;
      regimeConfidence    = 0.5;
      volatilityEstimate  = 0.02;

      residentPhase       = "dormant";
      lastTickBeat        = 0;
      beatsActive         = 0;
      reflectionDue       = false;
    };
  };

  func defaultStrategies() : [Strategy] {
    [
      {
        strategyId = "STR-MOMENTUM";
        name = "Phi Momentum";
        latinName = "Impetus Aureus";
        description = "Trend-following via EMA crossovers and momentum cascade detection";
        regime = #trending;
        primaryEngine = #technical;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.15; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-MEAN-REV";
        name = "Contrarian Reversion";
        latinName = "Reversio Contraria";
        description = "Mean-reversion on extreme sentiment via behavioral economics";
        regime = #ranging;
        primaryEngine = #behavioral;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.15; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-BREAKOUT";
        name = "Regime Breakout";
        latinName = "Eruptio Regiminis";
        description = "Regime transition detection via Monte Carlo + HMM";
        regime = #breakout;
        primaryEngine = #monteCarlo;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.12; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-ARB";
        name = "Harmonic Arbitrage";
        latinName = "Arbitrium Harmonicum";
        description = "Cross-timeframe arbitrage via ALOHA I temporal resonance";
        regime = #ranging;
        primaryEngine = #alohaProtocol;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.12; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-PREDATOR";
        name = "Predatory Sensing";
        latinName = "Sensus Praedatoris";
        description = "Shark + Eagle biological intelligence for deviation capture";
        regime = #volatile;
        primaryEngine = #animalIntel;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.10; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-NEURAL";
        name = "Neural Forecast";
        latinName = "Praedictio Neuralis";
        description = "AI prediction engine forward inference + validation";
        regime = #trending;
        primaryEngine = #aiEngine;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.12; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-SWARM";
        name = "Swarm Consensus";
        latinName = "Consensus Examinis";
        description = "Multi-engine swarm agreement for high-conviction entries";
        regime = #trending;
        primaryEngine = #alohaProtocol;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.12; lastTradeBeat = 0;
      },
      {
        strategyId = "STR-TAIL";
        name = "Tail Risk Harvest";
        latinName = "Messis Caudae Risici";
        description = "Options-like asymmetric payoff from MC tail risk simulation";
        regime = #volatile;
        primaryEngine = #monteCarlo;
        winRate = 0.0; avgReturn = 0.0; maxDrawdown = 0.0; sharpeRatio = 0.0;
        tradeCount = 0; isActive = true; allocationPct = 0.12; lastTradeBeat = 0;
      }
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERCEPTION — Collect and weight engine votes
  // ═══════════════════════════════════════════════════════════════════════════

  // Phi-ranked engine weights (sum = 1.0)
  public func engineWeight(cls : EngineClass) : Float {
    switch (cls) {
      case (#monteCarlo)    0.18;  // highest: probabilistic foundation
      case (#behavioral)    0.16;  // psychology drives markets
      case (#alohaProtocol) 0.15;  // harmonic intelligence
      case (#technical)     0.14;  // trend/momentum signals
      case (#aiEngine)      0.13;  // ML predictions
      case (#animalIntel)   0.10;  // biological patterns
      case (#phantomIntel)  0.08;  // on-chain data
      case (#fundamental)   0.06;  // value assessment
    };
  };

  // Compute weighted consensus from engine votes
  public func computeConsensus(votes : [EngineVote]) : (Float, Float) {
    // Returns (netDirection, consensusScore)
    if (votes.size() == 0) return (0.0, 0.0);

    var weightedSum : Float = 0.0;
    var totalWeight : Float = 0.0;
    var agreeLong : Float = 0.0;
    var agreeShort : Float = 0.0;

    for (vote in votes.vals()) {
      let w = vote.weight * vote.confidence;
      weightedSum += vote.direction * w;
      totalWeight += w;
      if (vote.direction > 0.0) { agreeLong += w }
      else if (vote.direction < 0.0) { agreeShort += w };
    };

    let netDir = if (totalWeight > 0.0) weightedSum / totalWeight else 0.0;
    let dominant = Float.max(agreeLong, agreeShort);
    let consensus = if (totalWeight > 0.0) dominant / totalWeight else 0.0;

    (netDir, consensus);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REASONING — Synthesize signals into decision
  // ═══════════════════════════════════════════════════════════════════════════

  // Classify market regime from engine signals
  public func classifyRegime(volatility : Float, trendStr : Float, consensus : Float) : MarketRegime {
    if (volatility > 0.04 and consensus < 0.5) #volatile
    else if (trendStr > 0.6 and consensus > 0.6) #trending
    else if (volatility < 0.01) #quiet
    else if (trendStr > 0.4 and volatility > 0.025) #breakout
    else #ranging;
  };

  // Generate trading decision from aggregated signals
  public func generateDecision(
    state : ResidentTraderState,
    beat : Int,
    symbol : Text,
    currentPrice : Float,
    volatility : Float
  ) : TradingDecision {
    let (netDir, consensus) = computeConsensus(state.currentVotes);
    let conviction = consensus * Float.abs(netDir);

    // Determine action
    let action : DecisionAction = if (conviction < CONVICTION_MINIMUM) {
      #hold;
    } else if (netDir > 0.3 and consensus >= CONSENSUS_THRESHOLD) {
      #enterLong;
    } else if (netDir < -0.3 and consensus >= CONSENSUS_THRESHOLD) {
      #enterShort;
    } else if (state.portfolioHeat > 0.7 and Float.abs(netDir) < 0.2) {
      #reducePosition;
    } else {
      #hold;
    };

    // Risk management
    let stopDistance = currentPrice * volatility * 2.0; // 2x volatility stop
    let sl = if (netDir > 0.0) currentPrice - stopDistance else currentPrice + stopDistance;
    let tp = if (netDir > 0.0) currentPrice + stopDistance * Phi.PHI else currentPrice - stopDistance * Phi.PHI;
    let rrr = if (stopDistance > 0.0) (Float.abs(tp - currentPrice)) / stopDistance else 0.0;

    // Position sizing (half-Kelly)
    let kelly = if (state.successRate > 0.0 and volatility > 0.0) {
      let b = 1.5; // estimated reward/risk
      let p = state.successRate;
      let q = 1.0 - p;
      Float.max(0.0, (p * b - q) / b) * 0.5;
    } else {
      0.02; // default 2% until calibrated
    };

    let posSize = Float.min(kelly, Phi.PHI_INV_2) * conviction;

    let enginesAgreed = Array.filter<EngineVote>(
      state.currentVotes,
      func(v : EngineVote) : Bool {
        (netDir > 0.0 and v.direction > 0.0) or (netDir < 0.0 and v.direction < 0.0)
      }
    ).size();

    {
      decisionId       = "DEC-" # Int.toText(beat);
      beat             = beat;
      symbol           = symbol;
      action           = action;
      direction        = netDir;
      conviction       = conviction;
      positionSize     = posSize;
      entryPrice       = currentPrice;
      stopLoss         = sl;
      takeProfit       = tp;
      riskRewardRatio  = rrr;
      consensusScore   = consensus;
      enginesConsulted = state.currentVotes.size();
      enginesAgreeing  = enginesAgreed;
      reasoning        = generateReasoning(action, consensus, netDir, conviction);
      kellyFraction    = kelly;
      regime           = state.currentRegime;
    };
  };

  func generateReasoning(action : DecisionAction, consensus : Float, dir : Float, conv : Float) : Text {
    switch (action) {
      case (#hold) "HOLD: Conviction " # Float.toText(conv) # " below threshold. Consensus: " # Float.toText(consensus);
      case (#enterLong) "LONG: Consensus " # Float.toText(consensus) # " direction " # Float.toText(dir) # " conviction " # Float.toText(conv);
      case (#enterShort) "SHORT: Consensus " # Float.toText(consensus) # " direction " # Float.toText(dir) # " conviction " # Float.toText(conv);
      case (#reducePosition) "REDUCE: Portfolio heat high, consensus weakening";
      case (#exitPosition) "EXIT: Signals reversed or target reached";
      case (#addToPosition) "ADD: Strong continuation signal";
      case (#hedgeExposure) "HEDGE: Volatility spike with unclear direction";
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — Advance the Resident Trader one beat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickResidentTrader(
    state : ResidentTraderState,
    beat : Int,
    coherence : Float,
    votes : [EngineVote],
    currentPrice : Float,
    volatility : Float,
    symbol : Text
  ) : ResidentTraderState {
    // Gate: coherence must be above φ⁻¹ for decisive action
    if (coherence < Phi.PHI_INV) {
      return { state with residentPhase = "observing"; lastTickBeat = beat; beatsActive = state.beatsActive + 1 };
    };

    // Update perception
    let (netDir, consensus) = computeConsensus(votes);
    let regime = classifyRegime(volatility, Float.abs(netDir), consensus);

    // Generate decision
    let updatedState : ResidentTraderState = {
      state with
      currentVotes = votes;
      voteConsensus = consensus;
      netDirection = netDir;
      currentRegime = regime;
      regimeConfidence = consensus;
      volatilityEstimate = volatility;
    };

    let decision = generateDecision(updatedState, beat, symbol, currentPrice, volatility);

    // Update history (keep last MEMORY_DEPTH)
    let newHistory = if (state.decisionHistory.size() >= MEMORY_DEPTH) {
      // Drop oldest, add newest
      let sz = state.decisionHistory.size();
      let slice = Array.tabulate<TradingDecision>(sz - 1, func(i : Nat) : TradingDecision { state.decisionHistory[i + 1] });
      Array.append(slice, [decision]);
    } else {
      Array.append(state.decisionHistory, [decision]);
    };

    let acted = switch (decision.action) { case (#hold) false; case (_) true };
    let newActedOn = if (acted) state.decisionsActedOn + 1 else state.decisionsActedOn;

    // Reflection check
    let reflDue = (state.beatsActive + 1) % REFLECTION_INTERVAL == 0;

    let phase = switch (decision.action) {
      case (#hold) "observing";
      case (_) "decisive";
    };

    {
      agentName           = state.agentName;
      latinName           = state.latinName;
      currentVotes        = votes;
      voteConsensus       = consensus;
      netDirection        = netDir;
      strategies          = state.strategies;
      activeStrategyCount = Array.filter<Strategy>(state.strategies, func(s : Strategy) : Bool { s.isActive }).size();
      decisionHistory     = newHistory;
      lastDecision        = decision;
      totalDecisions      = state.totalDecisions + 1;
      decisionsActedOn    = newActedOn;
      successRate         = state.successRate;
      avgConviction       = if (state.totalDecisions > 0)
                              (state.avgConviction * Float.fromInt(state.totalDecisions) + decision.conviction) / Float.fromInt(state.totalDecisions + 1)
                            else decision.conviction;
      portfolioHeat       = state.portfolioHeat;
      currentRegime       = regime;
      regimeConfidence    = consensus;
      volatilityEstimate  = volatility;
      residentPhase       = phase;
      lastTickBeat        = beat;
      beatsActive         = state.beatsActive + 1;
      reflectionDue       = reflDue;
    };
  };
};
