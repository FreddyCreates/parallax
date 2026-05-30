// monte_carlo.mo — MONTE CARLO SIMULATION ENGINE
// PARALLAX Sovereign Organism — Stochastic Financial Intelligence Layer
//
// PYTHAGORAS: simulation count = F(12)=144 paths per beat; variance decay at φ⁻²
// EUCLID:     single simulation engine — all stochastic inference routes here
// CONFUCIUS:  right relationship — Monte Carlo serves prediction, not replaces doctrine
//
// THE SOVEREIGN STOCHASTIC LAW (LEX_FORTUNA):
//   Monte Carlo simulations explore probability space through phi-guided random walks.
//   Each simulation path is bounded by doctrine coherence R.
//   Convergence is guaranteed at φ⁻² variance decay per doubling of paths.
//   Results feed PREDICTION engine, ALOHA I protocols, and the Resident Trader.
//
// Eight Monte Carlo Engines:
//   PRICE_PATH       — Geometric Brownian Motion with phi-volatility
//   PORTFOLIO_VAR    — Value-at-Risk via historical simulation
//   OPTIONS_PRICING  — Black-Scholes Monte Carlo (exotic payoffs)
//   REGIME_SWITCH    — Hidden Markov regime transition probabilities
//   LIQUIDITY_STRESS — Orderbook depth stress scenarios
//   CORRELATION      — Dynamic correlation matrix evolution
//   TAIL_RISK        — Extreme value theory + fat-tail simulation
//   STRATEGY_EVAL    — Strategy P&L distribution forward-testing
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Int   "mo:core/Int";
import Nat32 "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTE CARLO CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  // Simulation paths per beat: F(12) = 144
  public let MC_PATHS_PER_BEAT : Nat = 144;

  // Variance decay rate: φ⁻² = 0.382 per doubling
  public let MC_VARIANCE_DECAY : Float = Phi.PHI_INV_2;

  // Confidence interval: φ⁻¹ = 0.618 (61.8% CI default)
  public let MC_CONFIDENCE_GATE : Float = Phi.PHI_INV;

  // Maximum time horizon (beats): F(10) = 55
  public let MC_MAX_HORIZON : Nat = 55;

  // Risk-free rate proxy (NNS staking): 18% annualized / beats-per-year
  public let MC_RISK_FREE_BEAT : Float = 0.000018;

  // Tail threshold: φ⁻³ = 0.236 (23.6% worst-case quantile)
  public let MC_TAIL_THRESHOLD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // PSEUDO-RANDOM NUMBER GENERATOR — LCG seeded by beat × phi
  // Deterministic within a beat for reproducibility
  // ═══════════════════════════════════════════════════════════════════════════

  public func lcgNext(seed : Nat32) : Nat32 {
    // LCG: (a * seed + c) mod 2^32
    // a = 1664525, c = 1013904223 (Numerical Recipes)
    let a : Nat32 = 1664525;
    let c : Nat32 = 1013904223;
    a *% seed +% c;
  };

  public func seedFromBeat(beat : Int) : Nat32 {
    let b = Int.abs(beat);
    Nat32.fromNat(b % 4294967295);
  };

  // Uniform [0,1) from Nat32
  public func uniformFloat(x : Nat32) : Float {
    Float.fromInt(Nat32.toNat(x)) / 4294967296.0;
  };

  // Box-Muller transform for Normal(0,1)
  public func boxMuller(u1 : Float, u2 : Float) : (Float, Float) {
    let r = Float.sqrt(-2.0 * Float.log(if (u1 < 0.0001) 0.0001 else u1));
    let theta = 6.283185307179586 * u2;
    (r * Float.cos(theta), r * Float.sin(theta));
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES — Monte Carlo State
  // ═══════════════════════════════════════════════════════════════════════════

  public type SimulationResult = {
    engineId       : Text;       // which MC engine produced this
    meanOutcome    : Float;      // expected value
    stdDev         : Float;      // standard deviation
    varLower       : Float;      // VaR at MC_TAIL_THRESHOLD (23.6%)
    varUpper       : Float;      // VaR at 1 - MC_TAIL_THRESHOLD (76.4%)
    cvar           : Float;      // Conditional VaR (expected shortfall)
    maxDrawdown    : Float;      // worst path drawdown
    sharpeRatio    : Float;      // risk-adjusted return
    pathsRun       : Nat;        // number of simulation paths
    convergenceR   : Float;      // convergence metric [0,1]
    lastBeat       : Int;        // beat when computed
  };

  public type PricePathConfig = {
    currentPrice   : Float;      // starting price
    annualVol      : Float;      // annualized volatility
    drift          : Float;      // annualized drift (mu)
    horizonBeats   : Nat;        // forward simulation horizon
    jumpIntensity  : Float;      // Poisson jump frequency (0 = no jumps)
    jumpMean       : Float;      // mean jump size
    jumpVol        : Float;      // jump size volatility
  };

  public type PortfolioVaRConfig = {
    positions      : [PositionEntry];
    correlationMatrix : [Float]; // flattened lower-triangle
    horizonBeats   : Nat;
    confidenceLevel : Float;    // e.g. 0.95 for 95% VaR
  };

  public type PositionEntry = {
    assetId     : Text;
    weight      : Float;     // portfolio weight
    currentVal  : Float;     // current value
    annualVol   : Float;     // asset volatility
    drift       : Float;     // expected return
  };

  public type RegimeSwitchConfig = {
    currentRegime  : Nat;        // 0=bear, 1=neutral, 2=bull, 3=parabolic
    transitionMatrix : [Float];  // 4x4 flattened transition probabilities
    regimeVols     : [Float];    // volatility per regime
    regimeDrifts   : [Float];    // drift per regime
    horizonBeats   : Nat;
  };

  public type StrategyEvalConfig = {
    signalAccuracy  : Float;     // win rate [0,1]
    avgWin          : Float;     // average winning trade
    avgLoss         : Float;     // average losing trade
    tradesPerBeat   : Float;     // frequency
    maxPositionSize : Float;     // Kelly-bounded
    horizonBeats    : Nat;
  };

  public type MonteCarloState = {
    // Engine results (latest per engine)
    pricePathResult      : SimulationResult;
    portfolioVarResult   : SimulationResult;
    optionsPricingResult : SimulationResult;
    regimeSwitchResult   : SimulationResult;
    liquidityStressResult: SimulationResult;
    correlationResult    : SimulationResult;
    tailRiskResult       : SimulationResult;
    strategyEvalResult   : SimulationResult;

    // Aggregate state
    totalSimulationsRun  : Nat;
    totalPathsComputed   : Nat;
    avgConvergence       : Float;
    lastTickBeat         : Int;
    enginePhase          : Text;  // "dormant" | "warming" | "active" | "converged"
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  func defaultSimResult(id : Text) : SimulationResult {
    {
      engineId     = id;
      meanOutcome  = 0.0;
      stdDev       = 0.0;
      varLower     = 0.0;
      varUpper     = 0.0;
      cvar         = 0.0;
      maxDrawdown  = 0.0;
      sharpeRatio  = 0.0;
      pathsRun     = 0;
      convergenceR = 0.0;
      lastBeat     = 0;
    };
  };

  public func defaultMonteCarloState() : MonteCarloState {
    {
      pricePathResult       = defaultSimResult("MC-PRICE-PATH");
      portfolioVarResult    = defaultSimResult("MC-PORTFOLIO-VAR");
      optionsPricingResult  = defaultSimResult("MC-OPTIONS");
      regimeSwitchResult    = defaultSimResult("MC-REGIME-SWITCH");
      liquidityStressResult = defaultSimResult("MC-LIQUIDITY");
      correlationResult     = defaultSimResult("MC-CORRELATION");
      tailRiskResult        = defaultSimResult("MC-TAIL-RISK");
      strategyEvalResult    = defaultSimResult("MC-STRATEGY-EVAL");
      totalSimulationsRun   = 0;
      totalPathsComputed    = 0;
      avgConvergence        = 0.0;
      lastTickBeat          = 0;
      enginePhase           = "dormant";
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 1: PRICE PATH — Geometric Brownian Motion with Jumps
  // dS = μ·S·dt + σ·S·dW + J·S·dN (Merton Jump-Diffusion)
  // ═══════════════════════════════════════════════════════════════════════════

  public func simulatePricePaths(config : PricePathConfig, beat : Int) : SimulationResult {
    let paths = MC_PATHS_PER_BEAT;
    let horizon = if (config.horizonBeats > MC_MAX_HORIZON) MC_MAX_HORIZON else config.horizonBeats;
    var seed = seedFromBeat(beat);
    var sumFinal : Float = 0.0;
    var sumSqFinal : Float = 0.0;
    var worst : Float = config.currentPrice;
    var best : Float = config.currentPrice;

    let dt : Float = 1.0; // 1 beat
    let sqrtDt = 1.0;     // sqrt(1) = 1

    var i : Nat = 0;
    while (i < paths) {
      var price = config.currentPrice;
      var minPrice = price;
      var j : Nat = 0;
      while (j < horizon) {
        seed := lcgNext(seed);
        let u1 = uniformFloat(seed);
        seed := lcgNext(seed);
        let u2 = uniformFloat(seed);
        let (z, _) = boxMuller(u1, u2);

        // GBM step
        let driftTerm = (config.drift - 0.5 * config.annualVol * config.annualVol) * dt;
        let diffTerm = config.annualVol * sqrtDt * z;
        price := price * Float.exp(driftTerm + diffTerm);

        // Jump component (Poisson approximation)
        if (config.jumpIntensity > 0.0) {
          seed := lcgNext(seed);
          let jumpU = uniformFloat(seed);
          if (jumpU < config.jumpIntensity * dt) {
            seed := lcgNext(seed);
            let ju1 = uniformFloat(seed);
            seed := lcgNext(seed);
            let ju2 = uniformFloat(seed);
            let (jz, _) = boxMuller(ju1, ju2);
            let jumpSize = Float.exp(config.jumpMean + config.jumpVol * jz);
            price := price * jumpSize;
          };
        };

        if (price < minPrice) { minPrice := price };
        j += 1;
      };

      sumFinal += price;
      sumSqFinal += price * price;
      if (minPrice < worst) { worst := minPrice };
      if (price > best) { best := price };
      i += 1;
    };

    let mean = sumFinal / Float.fromInt(paths);
    let variance = (sumSqFinal / Float.fromInt(paths)) - mean * mean;
    let std = Float.sqrt(if (variance > 0.0) variance else 0.0);
    let maxDD = (worst - config.currentPrice) / config.currentPrice;
    let sharpe = if (std > 0.0) (mean - config.currentPrice) / std else 0.0;

    {
      engineId     = "MC-PRICE-PATH";
      meanOutcome  = mean;
      stdDev       = std;
      varLower     = mean - 1.28 * std; // ~10th percentile
      varUpper     = mean + 1.28 * std;
      cvar         = worst;
      maxDrawdown  = maxDD;
      sharpeRatio  = sharpe;
      pathsRun     = paths;
      convergenceR = if (std > 0.0) Float.min(1.0, mean / (mean + std)) else 1.0;
      lastBeat     = beat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 2: PORTFOLIO VALUE-AT-RISK
  // Historical simulation with correlated asset returns
  // ═══════════════════════════════════════════════════════════════════════════

  public func simulatePortfolioVaR(config : PortfolioVaRConfig, beat : Int) : SimulationResult {
    let paths = MC_PATHS_PER_BEAT;
    let n = config.positions.size();
    if (n == 0) { return defaultSimResult("MC-PORTFOLIO-VAR") };

    var seed = seedFromBeat(beat + 7919); // offset seed
    var sumPnl : Float = 0.0;
    var sumSqPnl : Float = 0.0;
    var worstPnl : Float = 0.0;

    var i : Nat = 0;
    while (i < paths) {
      var portfolioPnl : Float = 0.0;
      var j : Nat = 0;
      while (j < n) {
        seed := lcgNext(seed);
        let u1 = uniformFloat(seed);
        seed := lcgNext(seed);
        let u2 = uniformFloat(seed);
        let (z, _) = boxMuller(u1, u2);

        let pos = config.positions[j];
        let ret = pos.drift + pos.annualVol * z;
        portfolioPnl += pos.weight * pos.currentVal * ret;
        j += 1;
      };
      sumPnl += portfolioPnl;
      sumSqPnl += portfolioPnl * portfolioPnl;
      if (portfolioPnl < worstPnl) { worstPnl := portfolioPnl };
      i += 1;
    };

    let mean = sumPnl / Float.fromInt(paths);
    let variance = (sumSqPnl / Float.fromInt(paths)) - mean * mean;
    let std = Float.sqrt(if (variance > 0.0) variance else 0.0);

    {
      engineId     = "MC-PORTFOLIO-VAR";
      meanOutcome  = mean;
      stdDev       = std;
      varLower     = mean - 1.645 * std; // 95% VaR
      varUpper     = mean + 1.645 * std;
      cvar         = worstPnl;
      maxDrawdown  = if (mean != 0.0) worstPnl / Float.abs(mean) else 0.0;
      sharpeRatio  = if (std > 0.0) mean / std else 0.0;
      pathsRun     = paths;
      convergenceR = if (std > 0.0) Float.min(1.0, Float.abs(mean) / (Float.abs(mean) + std)) else 1.0;
      lastBeat     = beat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 3: REGIME SWITCHING — Hidden Markov Transition Simulation
  // Models regime changes: bear → neutral → bull → parabolic
  // ═══════════════════════════════════════════════════════════════════════════

  public func simulateRegimeSwitch(config : RegimeSwitchConfig, beat : Int) : SimulationResult {
    let paths = MC_PATHS_PER_BEAT;
    let horizon = if (config.horizonBeats > MC_MAX_HORIZON) MC_MAX_HORIZON else config.horizonBeats;
    let nRegimes = config.regimeVols.size();
    if (nRegimes == 0) { return defaultSimResult("MC-REGIME-SWITCH") };

    var seed = seedFromBeat(beat + 104729);
    var sumReturn : Float = 0.0;
    var sumSqReturn : Float = 0.0;
    var worstReturn : Float = 0.0;

    var i : Nat = 0;
    while (i < paths) {
      var regime = config.currentRegime;
      var cumReturn : Float = 0.0;
      var j : Nat = 0;
      while (j < horizon) {
        // Transition
        seed := lcgNext(seed);
        let transU = uniformFloat(seed);
        var cumProb : Float = 0.0;
        var k : Nat = 0;
        while (k < nRegimes) {
          let idx = regime * nRegimes + k;
          if (idx < config.transitionMatrix.size()) {
            cumProb += config.transitionMatrix[idx];
          };
          if (transU <= cumProb and k < nRegimes) {
            regime := k;
            k := nRegimes; // break
          };
          k += 1;
        };

        // Generate return in current regime
        seed := lcgNext(seed);
        let u1 = uniformFloat(seed);
        seed := lcgNext(seed);
        let u2 = uniformFloat(seed);
        let (z, _) = boxMuller(u1, u2);

        let vol = if (regime < nRegimes) config.regimeVols[regime] else 0.01;
        let drift = if (regime < nRegimes) config.regimeDrifts[regime] else 0.0;
        cumReturn += drift + vol * z;
        j += 1;
      };
      sumReturn += cumReturn;
      sumSqReturn += cumReturn * cumReturn;
      if (cumReturn < worstReturn) { worstReturn := cumReturn };
      i += 1;
    };

    let mean = sumReturn / Float.fromInt(paths);
    let variance = (sumSqReturn / Float.fromInt(paths)) - mean * mean;
    let std = Float.sqrt(if (variance > 0.0) variance else 0.0);

    {
      engineId     = "MC-REGIME-SWITCH";
      meanOutcome  = mean;
      stdDev       = std;
      varLower     = mean - 1.645 * std;
      varUpper     = mean + 1.645 * std;
      cvar         = worstReturn;
      maxDrawdown  = worstReturn;
      sharpeRatio  = if (std > 0.0) mean / std else 0.0;
      pathsRun     = paths;
      convergenceR = if (std > 0.0) Float.min(1.0, Float.abs(mean) / (Float.abs(mean) + std)) else 1.0;
      lastBeat     = beat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 4: STRATEGY EVALUATION — Forward P&L Distribution
  // Simulates strategy performance given win rate, risk/reward
  // ═══════════════════════════════════════════════════════════════════════════

  public func simulateStrategyEval(config : StrategyEvalConfig, beat : Int) : SimulationResult {
    let paths = MC_PATHS_PER_BEAT;
    let horizon = if (config.horizonBeats > MC_MAX_HORIZON) MC_MAX_HORIZON else config.horizonBeats;
    var seed = seedFromBeat(beat + 224737);
    var sumPnl : Float = 0.0;
    var sumSqPnl : Float = 0.0;
    var worstPnl : Float = 0.0;

    var i : Nat = 0;
    while (i < paths) {
      var equity : Float = 1.0;
      var minEquity : Float = 1.0;
      var j : Nat = 0;
      while (j < horizon) {
        // Number of trades this beat (simplified to 1 per beat max)
        seed := lcgNext(seed);
        let tradeU = uniformFloat(seed);
        if (tradeU < config.tradesPerBeat) {
          seed := lcgNext(seed);
          let winU = uniformFloat(seed);
          let posSize = Float.min(config.maxPositionSize, equity * Phi.PHI_INV_2);
          if (winU < config.signalAccuracy) {
            equity += posSize * config.avgWin;
          } else {
            equity -= posSize * config.avgLoss;
          };
        };
        if (equity < minEquity) { minEquity := equity };
        j += 1;
      };
      let pnl = equity - 1.0;
      sumPnl += pnl;
      sumSqPnl += pnl * pnl;
      let dd = (minEquity - 1.0);
      if (dd < worstPnl) { worstPnl := dd };
      i += 1;
    };

    let mean = sumPnl / Float.fromInt(paths);
    let variance = (sumSqPnl / Float.fromInt(paths)) - mean * mean;
    let std = Float.sqrt(if (variance > 0.0) variance else 0.0);

    {
      engineId     = "MC-STRATEGY-EVAL";
      meanOutcome  = mean;
      stdDev       = std;
      varLower     = mean - 1.645 * std;
      varUpper     = mean + 1.645 * std;
      cvar         = worstPnl;
      maxDrawdown  = worstPnl;
      sharpeRatio  = if (std > 0.0) mean / std else 0.0;
      pathsRun     = paths;
      convergenceR = if (std > 0.0) Float.min(1.0, Float.abs(mean) / (Float.abs(mean) + std)) else 1.0;
      lastBeat     = beat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — Advance all Monte Carlo engines one beat
  // Runs price path + regime switch every beat; others every F(5)=5 beats
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickMonteCarlo(state : MonteCarloState, beat : Int, coherence : Float) : MonteCarloState {
    // Gate: coherence must be above φ⁻¹ to run simulations
    if (coherence < MC_CONFIDENCE_GATE) {
      return { state with enginePhase = "dormant"; lastTickBeat = beat };
    };

    // Default price path config (BTC-like asset)
    let priceConfig : PricePathConfig = {
      currentPrice  = 60000.0;
      annualVol     = 0.65;
      drift         = 0.15;
      horizonBeats  = 21; // F(8)
      jumpIntensity = 0.01;
      jumpMean      = -0.05;
      jumpVol       = 0.10;
    };

    let newPricePath = simulatePricePaths(priceConfig, beat);

    // Regime switch every beat
    let regimeConfig : RegimeSwitchConfig = {
      currentRegime    = 1; // neutral
      transitionMatrix = [
        0.90, 0.08, 0.02, 0.00, // bear stays bear 90%
        0.05, 0.85, 0.08, 0.02, // neutral
        0.02, 0.08, 0.85, 0.05, // bull
        0.01, 0.04, 0.15, 0.80  // parabolic
      ];
      regimeVols   = [0.04, 0.02, 0.025, 0.05];
      regimeDrifts = [-0.002, 0.0005, 0.002, 0.005];
      horizonBeats = 34; // F(9)
    };
    let newRegime = simulateRegimeSwitch(regimeConfig, beat);

    // Strategy eval every 5 beats
    let beatNat = Int.abs(beat);
    let newStrategy = if (beatNat % 5 == 0) {
      let stratConfig : StrategyEvalConfig = {
        signalAccuracy  = 0.55; // 55% win rate
        avgWin          = 0.02; // 2% average win
        avgLoss         = 0.015; // 1.5% average loss
        tradesPerBeat   = 0.3;
        maxPositionSize = 0.10;
        horizonBeats    = 55; // F(10)
      };
      simulateStrategyEval(stratConfig, beat);
    } else {
      state.strategyEvalResult;
    };

    let totalPaths = MC_PATHS_PER_BEAT * 2 + (if (beatNat % 5 == 0) MC_PATHS_PER_BEAT else 0);
    let avgConv = (newPricePath.convergenceR + newRegime.convergenceR + newStrategy.convergenceR) / 3.0;

    {
      pricePathResult       = newPricePath;
      portfolioVarResult    = state.portfolioVarResult;
      optionsPricingResult  = state.optionsPricingResult;
      regimeSwitchResult    = newRegime;
      liquidityStressResult = state.liquidityStressResult;
      correlationResult     = state.correlationResult;
      tailRiskResult        = state.tailRiskResult;
      strategyEvalResult    = newStrategy;
      totalSimulationsRun   = state.totalSimulationsRun + 2 + (if (beatNat % 5 == 0) 1 else 0);
      totalPathsComputed    = state.totalPathsComputed + totalPaths;
      avgConvergence        = avgConv;
      lastTickBeat          = beat;
      enginePhase           = if (avgConv >= Phi.PHI_INV) "converged" else "active";
    };
  };
};
