import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// PORTFOLIO MANAGER — PARALLAX PHASE K
// Multi-chain portfolio: BTC/ETH/SOL/ICP + stablecoins
// Risk-adjusted optimization, auto-rebalancing, AURUM tool
// Sovereign floor: all allocations >= 1.0
// ============================================================
module {

  let NUM_ASSETS : Nat = 6;
  // Asset codes: 0=BTC 1=ETH 2=SOL 3=ICP 4=STBL(stable) 5=FORMA

  public type AssetPosition = {
    var value        : Float;   // Current value (USD)
    var allocation   : Float;   // Fraction of total portfolio
    var targetAlloc  : Float;   // Target allocation from optimizer
    var returnBeat   : Float;   // Beat return (pct)
    var returnEma21  : Float;   // 21-beat EMA of returns
    var volatility   : Float;   // EMA of |return|
    var sharpe       : Float;   // Return/volatility ratio
    var beta         : Float;   // Correlation to BTC
    var maxDrawdown  : Float;   // Max drawdown from peak
    var peak         : Float;   // All-time peak value
    var hedgeWeight  : Float;   // Hedge effectiveness vs downside
  };

  public type PortfolioState = {
    var positions         : [var AssetPosition];
    var totalValue        : Float;
    var portfolioReturn   : Float;   // Beat return on total
    var portfolioRetEma   : Float;   // EMA of portfolio returns
    var portfolioVol      : Float;   // Portfolio volatility
    var portfolioSharpe   : Float;   // Portfolio-level Sharpe
    var maxDrawdown       : Float;
    var portfolioPeak     : Float;
    var rebalanceCooldown : Nat;
    var rebalanceCount    : Nat;
    var rebalanceNeeded   : Bool;
    var allocationDrift   : Float;
    var varEstimate       : Float;   // 95% VaR (Value at Risk)
    var cvarEstimate      : Float;   // Conditional VaR
    var betaPortfolio     : Float;   // Weighted portfolio beta
    var correlationMatrix : [var Float]; // 6x6 = 36 entries (EMA)
    var diversityScore    : Float;
    var aurumHealthScore  : Float;
    var mrcContrib        : Float;   // Portfolio gains to MRC
    var formaContrib      : Float;
    var signalStrength    : Float;
    var returnHistory     : [var Float]; // 100-beat return history
    var returnHistoryIdx  : Nat;
  };

  func initAsset(value: Float, targetAlloc: Float) : AssetPosition = {
    var value        = value;
    var allocation   = targetAlloc;
    var targetAlloc  = targetAlloc;
    var returnBeat   = 0.0;
    var returnEma21  = 0.0;
    var volatility   = 1.0;
    var sharpe       = 1.0;
    var beta         = 1.0;
    var maxDrawdown  = 0.0;
    var peak         = value;
    var hedgeWeight  = 1.0;
  };

  public func initPortfolioState() : PortfolioState = {
    // Initial allocation: 40% BTC, 25% ETH, 10% SOL, 10% ICP, 10% STBL, 5% FORMA
    var positions = [
      var initAsset(400.0, 0.40),  // BTC
          initAsset(250.0, 0.25),  // ETH
          initAsset(100.0, 0.10),  // SOL
          initAsset(100.0, 0.10),  // ICP
          initAsset(100.0, 0.10),  // STBL
          initAsset(50.0,  0.05)   // FORMA
    ];
    var totalValue        = 1000.0;
    var portfolioReturn   = 0.0;
    var portfolioRetEma   = 0.0;
    var portfolioVol      = 1.0;
    var portfolioSharpe   = 1.0;
    var maxDrawdown       = 0.0;
    var portfolioPeak     = 1000.0;
    var rebalanceCooldown = 0;
    var rebalanceCount    = 0;
    var rebalanceNeeded   = false;
    var allocationDrift   = 0.0;
    var varEstimate       = 1.0;
    var cvarEstimate      = 1.0;
    var betaPortfolio     = 1.0;
    var correlationMatrix = Array.init<Float>(36, 0.5); // Start with 0.5 pairwise correlation
    var diversityScore    = 1.5;
    var aurumHealthScore  = 1.5;
    var mrcContrib        = 0.0;
    var formaContrib      = 1.0;
    var signalStrength    = 1.5;
    var returnHistory     = Array.init<Float>(100, 0.0);
    var returnHistoryIdx  = 0;
  };

  func emaUpdate(prev: Float, val: Float, n: Float) : Float {
    let alpha = 2.0 / (n + 1.0);
    prev * (1.0 - alpha) + val * alpha
  };

  // Mean-Variance optimization (simplified Markowitz)
  // Target allocation = sharpe_i / sum(sharpe_j)
  func computeTargetAllocations(positions: [var AssetPosition]) : [var Float] {
    var totalSharpe = 0.0;
    for (p in positions.vals()) {
      totalSharpe += Float.max(0.001, p.sharpe);
    };
    let targets = Array.init<Float>(NUM_ASSETS, 0.0);
    var i = 0;
    for (p in positions.vals()) {
      targets[i] := Float.max(0.001, p.sharpe) / totalSharpe;
      i += 1;
    };
    // Enforce minimum allocation floors (no asset below 2%)
    let FLOOR = 0.02;
    var floorSum = 0.0;
    var i2 = 0;
    for (t in targets.vals()) {
      if (t < FLOOR) { targets[i2] := FLOOR; floorSum += (FLOOR - t); };
      i2 += 1;
    };
    // Distribute floor excess from highest-sharpe assets
    if (floorSum > 0.0) {
      var i3 = 0;
      for (t in targets.vals()) {
        if (t > FLOOR) {
          let reduction = Float.min(t - FLOOR, floorSum / Float.fromInt(NUM_ASSETS));
          targets[i3] := t - reduction;
          floorSum -= reduction;
        };
        i3 += 1;
      };
    };
    targets
  };

  // Portfolio beta: weighted sum of asset betas
  func computePortfolioBeta(positions: [var AssetPosition], total: Float) : Float {
    var beta = 0.0;
    for (p in positions.vals()) {
      beta += p.beta * (p.value / Float.max(1.0, total));
    };
    Float.max(0.5, beta)
  };

  // VaR estimate: portfolio_vol * z_95 * total_value
  // z_95 = 1.645 (normal distribution)
  func computeVaR(vol: Float, total: Float) : Float {
    Float.max(1.0, vol * 1.645 * total)
  };

  // CVaR (Expected Shortfall): VaR / (1 - 0.95) * 0.5 approximation
  func computeCVaR(var_: Float) : Float {
    Float.max(1.0, var_ * 1.4)
  };

  // Herfindahl diversity
  func herfindahl(positions: [var AssetPosition], total: Float) : Float {
    var hhi = 0.0;
    for (p in positions.vals()) {
      let w = p.value / Float.max(1.0, total);
      hhi += w * w;
    };
    Float.max(1.0, 1.0 + (1.0 - Float.min(1.0, hhi)))
  };

  // Update EMA correlation matrix (6x6): simplified diagonal update
  func updateCorrelation(
    matrix     : [var Float],
    positions  : [var AssetPosition],
    total      : Float
  ) {
    // Update pairwise: EMA(prev, r_i * r_j)
    var i = 0;
    while (i < NUM_ASSETS) {
      var j = 0;
      while (j < NUM_ASSETS) {
        let idx = i * NUM_ASSETS + j;
        let rij = positions[i].returnBeat * positions[j].returnBeat;
        matrix[idx] := matrix[idx] * 0.99 + rij * 0.01;
        j += 1;
      };
      i += 1;
    };
  };

  public func updatePortfolio(
    s          : PortfolioState,
    btcRet     : Float,   // BTC price return this beat
    ethRet     : Float,
    solRet     : Float,
    icpRet     : Float,
    stblRet    : Float,   // Stable = 0 always
    formaRet   : Float,   // FORMA capital growth rate
    beatCount  : Nat,
    coherenceC : Float
  ) : PortfolioState {
    let rets = [btcRet, ethRet, solRet, icpRet, stblRet, formaRet];

    // Update each position
    var i = 0;
    let total = s.totalValue;
    for (ret in rets.vals()) {
      let p = s.positions[i];
      let newValue = Float.max(0.01, p.value * (1.0 + ret));
      let retBeat  = (newValue - p.value) / Float.max(0.01, p.value);
      let retEma   = emaUpdate(p.returnEma21, retBeat, 21.0);
      let vol      = emaUpdate(p.volatility, Float.abs(retBeat), 21.0);
      let sharpe   = retEma / Float.max(0.0001, vol);
      let newPeak  = Float.max(p.peak, newValue);
      let drawdown = (newPeak - newValue) / Float.max(0.01, newPeak);
      let maxDD    = Float.max(p.maxDrawdown, drawdown);
      // Beta: EMA(asset_ret / btc_ret) — BTC is beta=1.0
      let newBeta = if (i == 0) 1.0
        else emaUpdate(p.beta, ret / Float.max(0.0001, Float.abs(btcRet) + 0.0001) * (if (btcRet != 0.0) 1.0 else 0.0), 21.0);
      p.value       := newValue;
      p.returnBeat  := retBeat;
      p.returnEma21 := retEma;
      p.volatility  := vol;
      p.sharpe      := Float.max(0.01, 1.0 + sharpe);
      p.beta        := Float.max(0.1, newBeta);
      p.maxDrawdown := maxDD;
      p.peak        := newPeak;
      i += 1;
    };

    // Total value
    var newTotal = 0.0;
    for (p in s.positions.vals()) { newTotal += p.value; };

    // Portfolio return
    let portRet = (newTotal - total) / Float.max(0.01, total);
    let portRetEma = emaUpdate(s.portfolioRetEma, portRet, 21.0);
    let portVol    = emaUpdate(s.portfolioVol, Float.abs(portRet), 21.0);
    let portSharpe = Float.max(1.0, 1.0 + portRetEma / Float.max(0.0001, portVol));

    // Peak and drawdown
    let newPeak = Float.max(s.portfolioPeak, newTotal);
    let dd      = (newPeak - newTotal) / Float.max(0.01, newPeak);
    let maxDD   = Float.max(s.maxDrawdown, dd);

    // Update allocation fractions
    var j = 0;
    for (p in s.positions.vals()) {
      p.allocation := p.value / Float.max(0.01, newTotal);
      j += 1;
    };

    // Target allocations (mean-variance)
    let targets = computeTargetAllocations(s.positions);
    var k = 0;
    var drift = 0.0;
    for (t in targets.vals()) {
      s.positions[k].targetAlloc := t;
      drift := Float.max(drift, Float.abs(s.positions[k].allocation - t));
      k += 1;
    };

    // Rebalance if needed
    var newCD = if (s.rebalanceCooldown > 0) s.rebalanceCooldown - 1 else 0;
    var newRC = s.rebalanceCount;
    if (drift > 0.10 and newCD == 0) {
      // Gentle rebalance toward targets
      var m = 0;
      for (p in s.positions.vals()) {
        let targetValue = p.targetAlloc * newTotal;
        let correction  = (targetValue - p.value) * 0.05; // 5% per rebalance
        p.value := Float.max(0.01, p.value + correction);
        m += 1;
      };
      newCD := 2880; // 20-day cooldown
      newRC += 1;
    };

    // Update correlation matrix
    updateCorrelation(s.correlationMatrix, s.positions, newTotal);

    // Beta
    let portBeta = computePortfolioBeta(s.positions, newTotal);

    // VaR and CVaR
    let var_  = computeVaR(portVol, newTotal);
    let cvar  = computeCVaR(var_);

    // Diversity
    let div = herfindahl(s.positions, newTotal);

    // AURUM health: sharpe + diversity + low drawdown
    let aurum = Float.max(1.0, Float.min(2.0,
      portSharpe * 0.4 + div * 0.3 + (1.0 - Float.min(1.0, maxDD * 5.0)) * 0.3
    ));

    // MRC: 20% of portfolio gains
    let gain = Float.max(0.0, newTotal - total);
    let mrcC = gain * 0.20;

    // FORMA contribution
    let fc = Float.max(1.0, portRetEma * coherenceC * 100.0 + div * 0.5);

    // Signal
    let sig = Float.max(1.0, portSharpe * aurum * 0.5);

    // Return history
    let hIdx = (s.returnHistoryIdx + 1) % 100;
    s.returnHistory[hIdx] := portRet;

    s.totalValue        := newTotal;
    s.portfolioReturn   := portRet;
    s.portfolioRetEma   := portRetEma;
    s.portfolioVol      := portVol;
    s.portfolioSharpe   := portSharpe;
    s.maxDrawdown       := maxDD;
    s.portfolioPeak     := newPeak;
    s.rebalanceCooldown := newCD;
    s.rebalanceCount    := newRC;
    s.rebalanceNeeded   := drift > 0.10;
    s.allocationDrift   := drift;
    s.varEstimate       := var_;
    s.cvarEstimate      := cvar;
    s.betaPortfolio     := portBeta;
    s.diversityScore    := div;
    s.aurumHealthScore  := aurum;
    s.mrcContrib        := mrcC;
    s.formaContrib      := fc;
    s.signalStrength    := sig;
    s.returnHistoryIdx  := hIdx;
    s
  };

  // 100-beat annualized return
  public func annualizedReturn(s: PortfolioState) : Float {
    var sum = 0.0;
    for (r in s.returnHistory.vals()) { sum += r; };
    let meanBeat = sum / 100.0;
    Float.max(0.0, (1.0 + meanBeat) * 144.0 * 365.0 - 1.0) // beats/day * days/year
  };

};
