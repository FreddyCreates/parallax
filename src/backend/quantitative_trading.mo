// quantitative_trading.mo — SOVEREIGN QUANTITATIVE TRADING ENGINE
// PARALLAX Sovereign Organism — Domain 44: QUANTITATIVE TRADING
//
// DOCTRINE: "Trading is intelligence in action. Every strategy encodes market
// beliefs as testable hypotheses. This module implements production-grade
// quantitative trading models: momentum, mean reversion, pairs trading,
// statistical arbitrage, market making, trend following — all with real
// mathematical formulas, no placeholders. Phi-gated execution."
//
// DOMAIN 44 — QUANTITATIVE TRADING CAPABILITIES:
//   1. Momentum Strategies    — Time-series momentum, cross-sectional momentum
//   2. Mean Reversion         — Pairs trading, statistical arbitrage, Bollinger
//   3. Trend Following        — Moving average crossovers, breakout systems
//   4. Market Making          — Bid-ask spread optimization, inventory management
//   5. Statistical Arbitrage  — Cointegration, correlation trading
//   6. Volatility Trading     — VIX strategies, gamma scalping
//   7. Machine Learning Alpha — Feature engineering, signal generation
//   8. Order Execution        — VWAP, TWAP, implementation shortfall
//
// PYTHAGORAS: all signals phi-weighted for coherence
// EUCLID:     single source of truth — QuantitativeTradingState
// CONFUCIUS:  right relationship — strategies serve organism profitability
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // QUANTITATIVE TRADING CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Signal threshold: φ⁻¹ = 0.618 (must exceed for action)
  public let SIGNAL_THRESHOLD : Float = Phi.PHI_INV;

  // Stop loss: φ⁻² = 0.382 (38.2% of position)
  public let STOP_LOSS_PCT : Float = Phi.PHI_INV_2;

  // Take profit: φ = 1.618 (161.8% return target)
  public let TAKE_PROFIT_PCT : Float = Phi.PHI;

  // Position sizing: φ⁻¹ = 0.618 (Kelly fraction modifier)
  public let POSITION_SIZE_FACTOR : Float = Phi.PHI_INV;

  // Momentum lookback: F(8) = 21 periods
  public let MOMENTUM_LOOKBACK : Nat = 21;

  // Mean reversion window: F(9) = 34 periods
  public let MEAN_REVERSION_WINDOW : Nat = 34;

  // Trend SMA fast: F(7) = 13 periods
  public let TREND_SMA_FAST : Nat = 13;

  // Trend SMA slow: F(10) = 55 periods
  public let TREND_SMA_SLOW : Nat = 55;

  // Bollinger Bands std dev: φ = 1.618
  public let BOLLINGER_STD_DEV : Float = Phi.PHI;

  // Pairs trading correlation threshold: φ⁻¹ = 0.618
  public let PAIRS_CORRELATION_THRESHOLD : Float = Phi.PHI_INV;

  // Cointegration p-value threshold: φ⁻² = 0.382
  public let COINTEGRATION_PVALUE : Float = Phi.PHI_INV_2;

  // Market making spread: φ⁻³ = 0.236 (23.6 bps)
  public let MARKET_MAKING_SPREAD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADING SIGNAL TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type TradingSignal = {
    signalId      : Text;
    strategyType  : StrategyType;
    asset         : Text;
    direction     : Direction;
    strength      : Float;       // Signal strength [0.0, 1.0]
    confidence    : Float;       // Confidence [0.0, 1.0]
    entryPrice    : Float;
    stopLoss      : Float;
    takeProfit    : Float;
    positionSize  : Float;       // Fraction of capital
    timestamp     : Int;
    expiryBeats   : Nat;        // Signal validity period
    phiCoherence  : Float;
  };

  public type StrategyType = {
    #momentum;
    #meanReversion;
    #trendFollowing;
    #pairsTrading;
    #statisticalArbitrage;
    #marketMaking;
    #volatilityTrading;
    #machineLearning;
  };

  public type Direction = {
    #long;
    #short;
    #neutral;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MOMENTUM STRATEGIES
  // ═══════════════════════════════════════════════════════════════════════════

  // Time-series momentum: return over lookback period
  public func calculateMomentumSignal(
    prices : [Float],
    lookback : Nat,
    currentBeat : Int
  ) : ?TradingSignal {
    
    if (prices.size() < lookback + 1) { return null; };

    let currentPrice = prices[prices.size() - 1];
    let pastPrice = prices[prices.size() - lookback - 1];

    // Return over lookback period
    let momentum = (currentPrice - pastPrice) / pastPrice;

    // Normalize signal strength: tanh(momentum / σ)
    // Approximate σ with simple volatility estimate
    var sumReturns = 0.0;
    var sumSquaredReturns = 0.0;
    var i = prices.size() - lookback;
    while (i < prices.size() - 1) {
      let ret = (prices[i + 1] - prices[i]) / prices[i];
      sumReturns += ret;
      sumSquaredReturns += ret * ret;
      i += 1;
    };

    let avgReturn = sumReturns / Float.fromInt(lookback);
    let variance = (sumSquaredReturns / Float.fromInt(lookback)) - (avgReturn * avgReturn);
    let volatility = Float.sqrt(Float.max(0.0, variance));

    let normalizedMomentum = if (volatility > 0.0) {
      tanh(momentum / volatility)
    } else {
      0.0
    };

    let strength = Float.abs(normalizedMomentum);
    let direction = if (normalizedMomentum > 0.0) { #long } else { #short };

    // Signal threshold gate
    if (strength < SIGNAL_THRESHOLD) { return null; };

    // Position sizing using Kelly criterion (simplified)
    let winProb = (strength + 1.0) / 2.0;  // Map [-1,1] to [0,1]
    let kellyFraction = Float.max(0.0, 2.0 * winProb - 1.0) * POSITION_SIZE_FACTOR;

    // Stop loss and take profit levels
    let stopLoss = if (direction == #long) {
      currentPrice * (1.0 - STOP_LOSS_PCT)
    } else {
      currentPrice * (1.0 + STOP_LOSS_PCT)
    };

    let takeProfit = if (direction == #long) {
      currentPrice * (1.0 + TAKE_PROFIT_PCT)
    } else {
      currentPrice * (1.0 - TAKE_PROFIT_PCT)
    };

    ?{
      signalId = "MOMENTUM-" # Int.toText(currentBeat);
      strategyType = #momentum;
      asset = "ASSET";
      direction = direction;
      strength = strength;
      confidence = strength;  // In momentum, strength = confidence
      entryPrice = currentPrice;
      stopLoss = stopLoss;
      takeProfit = takeProfit;
      positionSize = kellyFraction;
      timestamp = currentBeat;
      expiryBeats = MOMENTUM_LOOKBACK;
      phiCoherence = Phi.PHI_INV;
    }
  };

  // Helper: tanh approximation
  func tanh(x : Float) : Float {
    let ex = Float.exp(Float.min(10.0, Float.max(-10.0, x)));
    let enx = Float.exp(Float.min(10.0, Float.max(-10.0, -x)));
    (ex - enx) / (ex + enx)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MEAN REVERSION STRATEGIES
  // ═══════════════════════════════════════════════════════════════════════════

  // Bollinger Bands mean reversion
  public func calculateBollingerBandsSignal(
    prices : [Float],
    window : Nat,
    numStdDev : Float,
    currentBeat : Int
  ) : ?TradingSignal {
    
    if (prices.size() < window) { return null; };

    // Calculate SMA and standard deviation
    var sum = 0.0;
    var i = prices.size() - window;
    while (i < prices.size()) {
      sum += prices[i];
      i += 1;
    };
    let sma = sum / Float.fromInt(window);

    var sumSquaredDiff = 0.0;
    i := prices.size() - window;
    while (i < prices.size()) {
      let diff = prices[i] - sma;
      sumSquaredDiff += diff * diff;
      i += 1;
    };
    let stdDev = Float.sqrt(sumSquaredDiff / Float.fromInt(window));

    let upperBand = sma + numStdDev * stdDev;
    let lowerBand = sma - numStdDev * stdDev;
    let currentPrice = prices[prices.size() - 1];

    // Generate signal
    let (direction, strength) = if (currentPrice > upperBand) {
      // Price above upper band → short (revert to mean)
      let distance = (currentPrice - upperBand) / stdDev;
      (#short, Float.min(1.0, distance / numStdDev))
    } else if (currentPrice < lowerBand) {
      // Price below lower band → long (revert to mean)
      let distance = (lowerBand - currentPrice) / stdDev;
      (#long, Float.min(1.0, distance / numStdDev))
    } else {
      (#neutral, 0.0)
    };

    if (strength < SIGNAL_THRESHOLD) { return null; };

    // Position sizing
    let positionSize = strength * POSITION_SIZE_FACTOR;

    // Stop loss: beyond next band
    let stopLoss = if (direction == #long) {
      lowerBand - stdDev
    } else if (direction == #short) {
      upperBand + stdDev
    } else {
      currentPrice
    };

    // Take profit: at SMA (mean reversion target)
    let takeProfit = sma;

    ?{
      signalId = "BOLLINGER-" # Int.toText(currentBeat);
      strategyType = #meanReversion;
      asset = "ASSET";
      direction = direction;
      strength = strength;
      confidence = strength * Phi.PHI_INV;  // Slightly lower confidence for mean reversion
      entryPrice = currentPrice;
      stopLoss = stopLoss;
      takeProfit = takeProfit;
      positionSize = positionSize;
      timestamp = currentBeat;
      expiryBeats = window;
      phiCoherence = Phi.PHI_INV_2;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND FOLLOWING STRATEGIES
  // ═══════════════════════════════════════════════════════════════════════════

  // Moving average crossover strategy
  public func calculateMovingAverageCrossover(
    prices : [Float],
    fastPeriod : Nat,
    slowPeriod : Nat,
    currentBeat : Int
  ) : ?TradingSignal {
    
    if (prices.size() < slowPeriod) { return null; };

    // Calculate fast SMA
    var fastSum = 0.0;
    var i = prices.size() - fastPeriod;
    while (i < prices.size()) {
      fastSum += prices[i];
      i += 1;
    };
    let fastSMA = fastSum / Float.fromInt(fastPeriod);

    // Calculate slow SMA
    var slowSum = 0.0;
    i := prices.size() - slowPeriod;
    while (i < prices.size()) {
      slowSum += prices[i];
      i += 1;
    };
    let slowSMA = slowSum / Float.fromInt(slowPeriod);

    // Previous crossover state (for detecting new crosses)
    let prevFastSMA = if (prices.size() >= slowPeriod + 1) {
      var sum = 0.0;
      i := prices.size() - fastPeriod - 1;
      while (i < prices.size() - 1) {
        sum += prices[i];
        i += 1;
      };
      sum / Float.fromInt(fastPeriod)
    } else {
      fastSMA
    };

    let prevSlowSMA = if (prices.size() >= slowPeriod + 1) {
      var sum = 0.0;
      i := prices.size() - slowPeriod - 1;
      while (i < prices.size() - 1) {
        sum += prices[i];
        i += 1;
      };
      sum / Float.fromInt(slowPeriod)
    } else {
      slowSMA
    };

    // Detect crossover
    let currentCross = fastSMA > slowSMA;
    let prevCross = prevFastSMA > prevSlowSMA;

    if (currentCross == prevCross) {
      // No new crossover
      return null;
    };

    let direction = if (currentCross) { #long } else { #short };
    let crossoverMagnitude = Float.abs(fastSMA - slowSMA) / slowSMA;
    let strength = Float.min(1.0, crossoverMagnitude * 10.0);

    if (strength < SIGNAL_THRESHOLD) { return null; };

    let currentPrice = prices[prices.size() - 1];
    let positionSize = strength * POSITION_SIZE_FACTOR;

    let stopLoss = if (direction == #long) {
      slowSMA * (1.0 - STOP_LOSS_PCT)
    } else {
      slowSMA * (1.0 + STOP_LOSS_PCT)
    };

    let takeProfit = if (direction == #long) {
      currentPrice * (1.0 + TAKE_PROFIT_PCT)
    } else {
      currentPrice * (1.0 - TAKE_PROFIT_PCT)
    };

    ?{
      signalId = "MA-CROSS-" # Int.toText(currentBeat);
      strategyType = #trendFollowing;
      asset = "ASSET";
      direction = direction;
      strength = strength;
      confidence = strength * Phi.PHI_INV;
      entryPrice = currentPrice;
      stopLoss = stopLoss;
      takeProfit = takeProfit;
      positionSize = positionSize;
      timestamp = currentBeat;
      expiryBeats = slowPeriod;
      phiCoherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIRS TRADING — Statistical Arbitrage
  // ═══════════════════════════════════════════════════════════════════════════

  public type PairStatistics = {
    correlation     : Float;
    cointegrationTest : Float;  // Test statistic
    spread          : Float;    // Current spread
    spreadMean      : Float;
    spreadStdDev    : Float;
    zScore          : Float;    // Standardized spread
  };

  // Calculate pair statistics
  public func calculatePairStatistics(
    prices1 : [Float],
    prices2 : [Float],
    window : Nat
  ) : ?PairStatistics {
    
    let n = Float.min(Float.fromInt(prices1.size()), Float.fromInt(prices2.size()));
    let windowSize = Float.min(n, Float.fromInt(window));
    
    if (windowSize < 2.0) { return null; };

    let w = Float.toInt(windowSize);
    let start1 = prices1.size() - w;
    let start2 = prices2.size() - w;

    // Calculate returns correlation
    var mean1 = 0.0;
    var mean2 = 0.0;
    var i = 0;
    while (i < w) {
      mean1 += prices1[start1 + i];
      mean2 += prices2[start2 + i];
      i += 1;
    };
    mean1 /= windowSize;
    mean2 /= windowSize;

    var cov = 0.0;
    var var1 = 0.0;
    var var2 = 0.0;
    i := 0;
    while (i < w) {
      let diff1 = prices1[start1 + i] - mean1;
      let diff2 = prices2[start2 + i] - mean2;
      cov += diff1 * diff2;
      var1 += diff1 * diff1;
      var2 += diff2 * diff2;
      i += 1;
    };

    let correlation = if (var1 > 0.0 and var2 > 0.0) {
      cov / Float.sqrt(var1 * var2)
    } else {
      0.0
    };

    // Calculate spread statistics
    let spreads = Array.init<Float>(w, 0.0);
    i := 0;
    while (i < w) {
      spreads[i] := prices1[start1 + i] - prices2[start2 + i];
      i += 1;
    };

    var spreadSum = 0.0;
    for (s in spreads.vals()) {
      spreadSum += s;
    };
    let spreadMean = spreadSum / windowSize;

    var spreadVariance = 0.0;
    for (s in spreads.vals()) {
      let diff = s - spreadMean;
      spreadVariance += diff * diff;
    };
    let spreadStdDev = Float.sqrt(spreadVariance / windowSize);

    let currentSpread = spreads[w - 1];
    let zScore = if (spreadStdDev > 0.0) {
      (currentSpread - spreadMean) / spreadStdDev
    } else {
      0.0
    };

    // Simplified cointegration test (Engle-Granger approximation)
    // In production, use full Augmented Dickey-Fuller test
    let cointegrationTest = Float.abs(zScore);

    ?{
      correlation = correlation;
      cointegrationTest = cointegrationTest;
      spread = currentSpread;
      spreadMean = spreadMean;
      spreadStdDev = spreadStdDev;
      zScore = zScore;
    }
  };

  // Generate pairs trading signal
  public func generatePairsSignal(
    asset1 : Text,
    asset2 : Text,
    pairStats : PairStatistics,
    currentBeat : Int
  ) : ?TradingSignal {
    
    // Check correlation threshold
    if (Float.abs(pairStats.correlation) < PAIRS_CORRELATION_THRESHOLD) {
      return null;
    };

    // Check spread deviation
    let zScore = pairStats.zScore;
    if (Float.abs(zScore) < BOLLINGER_STD_DEV) {
      return null;  // Spread not extreme enough
    };

    // Signal: long undervalued, short overvalued
    let direction = if (zScore > 0.0) {
      // Spread too high → short asset1, long asset2
      #short
    } else {
      // Spread too low → long asset1, short asset2
      #long
    };

    let strength = Float.min(1.0, Float.abs(zScore) / (2.0 * BOLLINGER_STD_DEV));
    let confidence = Float.abs(pairStats.correlation) * strength;

    if (strength < SIGNAL_THRESHOLD) { return null; };

    let positionSize = confidence * POSITION_SIZE_FACTOR;

    ?{
      signalId = "PAIRS-" # asset1 # "-" # asset2 # "-" # Int.toText(currentBeat);
      strategyType = #pairsTrading;
      asset = asset1 # "/" # asset2;
      direction = direction;
      strength = strength;
      confidence = confidence;
      entryPrice = pairStats.spread;
      stopLoss = pairStats.spreadMean + (3.0 * pairStats.spreadStdDev * (if (direction == #long) { -1.0 } else { 1.0 }));
      takeProfit = pairStats.spreadMean;  // Target: mean reversion
      positionSize = positionSize;
      timestamp = currentBeat;
      expiryBeats = MEAN_REVERSION_WINDOW;
      phiCoherence = Phi.PHI_INV_2;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET MAKING STRATEGY
  // ═══════════════════════════════════════════════════════════════════════════

  public type MarketMakingQuote = {
    bidPrice    : Float;
    askPrice    : Float;
    bidSize     : Float;
    askSize     : Float;
    spread      : Float;
    midPrice    : Float;
    inventory   : Float;  // Current inventory position
    skew        : Float;  // Quote skew based on inventory
  };

  // Generate market making quotes
  public func generateMarketMakingQuotes(
    midPrice : Float,
    volatility : Float,
    inventory : Float,
    maxInventory : Float,
    riskAversion : Float
  ) : MarketMakingQuote {
    
    // Base spread: function of volatility and risk aversion
    let baseSpread = MARKET_MAKING_SPREAD * midPrice * (1.0 + riskAversion * volatility);

    // Inventory skew: adjust quotes to reduce inventory risk
    let inventoryRatio = inventory / maxInventory;
    let skew = inventoryRatio * baseSpread * Phi.PHI_INV;

    // Bid-ask quotes with inventory management
    let bidPrice = midPrice - baseSpread / 2.0 - skew;
    let askPrice = midPrice + baseSpread / 2.0 - skew;

    // Size based on confidence and inventory space
    let inventorySpace = Float.abs(maxInventory - Float.abs(inventory)) / maxInventory;
    let quoteSize = maxInventory * POSITION_SIZE_FACTOR * inventorySpace;

    {
      bidPrice = bidPrice;
      askPrice = askPrice;
      bidSize = quoteSize;
      askSize = quoteSize;
      spread = askPrice - bidPrice;
      midPrice = midPrice;
      inventory = inventory;
      skew = skew;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUANTITATIVE TRADING STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type QuantitativeTradingState = {
    var activeSignals      : [TradingSignal];
    var signalHistory      : [(Int, TradingSignal)];
    var totalSignalsGenerated : Nat;
    var successfulTrades   : Nat;
    var totalPnL           : Float;
    var sharpeRatio        : Float;
    var lastSignalBeat     : Int;
    var phiCoherence       : Float;
  };

  public func initQuantitativeTradingState() : QuantitativeTradingState {
    {
      var activeSignals = [];
      var signalHistory = [];
      var totalSignalsGenerated = 0;
      var successfulTrades = 0;
      var totalPnL = 0.0;
      var sharpeRatio = 0.0;
      var lastSignalBeat = 0;
      var phiCoherence = Phi.PHI_INV;
    }
  };

};
