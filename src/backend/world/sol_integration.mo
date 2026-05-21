import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

// ============================================================
// SOL INTEGRATION — PARALLAX PHASE K
// Marinade liquid staking, Jito MEV-boosted, yield optimization
// AURUM council organism primary SOL tool
// ============================================================
module {

  public type SolState = {
    var solPriceUsd         : Float;
    var solEma21            : Float;
    var solEma55            : Float;
    var solEma200           : Float;
    var solPriceVelocity    : Float;
    var solVolatility       : Float;
    var marinadeMsolStaked  : Float;   // mSOL (Marinade liquid staking)
    var marinadeApr         : Float;   // Marinade APR (~7-8%)
    var marinadeRewards     : Float;   // Accumulated mSOL rewards
    var jitoStaked          : Float;   // jitoSOL staked amount
    var jitoApr             : Float;   // Jito APR (~8-9% with MEV)
    var jitoMevBoost        : Float;   // MEV yield component
    var jitoRewards         : Float;   // Accumulated jitoSOL rewards
    var solTpsSignal        : Float;   // TPS proxy (throughput health)
    var solNetworkHealth    : Float;   // Combined health
    var solTrendRegime      : Nat;     // 0-3
    var solMrcYield         : Float;   // Staking yield to MRC
    var solFormaContrib     : Float;
    var solTotalYieldApr    : Float;
    var solSignalStrength   : Float;
    var solCrossAbove200    : Bool;
    var solGoldenCross      : Bool;
    var solOutflowRisk      : Float;   // VC unlock / sell pressure proxy
    var solValidatorCount   : Float;   // Proxy: Nakamoto coefficient
    var solDefiTvl          : Float;   // DeFi TVL proxy
    var solSignalHistory    : [var Float];
    var solHistoryIdx       : Nat;
  };

  public func initSolState() : SolState = {
    var solPriceUsd         = 185.0;
    var solEma21            = 185.0;
    var solEma55            = 170.0;
    var solEma200           = 140.0;
    var solPriceVelocity    = 1.0;
    var solVolatility       = 1.0;
    var marinadeMsolStaked  = 1.0;
    var marinadeApr         = 0.075;
    var marinadeRewards     = 0.0;
    var jitoStaked          = 1.0;
    var jitoApr             = 0.085;
    var jitoMevBoost        = 0.015;
    var jitoRewards         = 0.0;
    var solTpsSignal        = 1.0;
    var solNetworkHealth    = 1.0;
    var solTrendRegime      = 2;
    var solMrcYield         = 0.0;
    var solFormaContrib     = 1.0;
    var solTotalYieldApr    = 1.0;
    var solSignalStrength   = 1.0;
    var solCrossAbove200    = true;
    var solGoldenCross      = true;
    var solOutflowRisk      = 1.0;
    var solValidatorCount   = 1.0;
    var solDefiTvl          = 1.0;
    var solSignalHistory    = Array.init<Float>(20, 1.0);
    var solHistoryIdx       = 0;
  };

  func emaUpdate(prev: Float, val: Float, n: Float) : Float {
    let alpha = 2.0 / (n + 1.0);
    let r = alpha * val + (1.0 - alpha) * prev;
    if (r < 1.0) 1.0 else r
  };

  func sovSigmoid(x: Float) : Float {
    1.0 + 1.0 / (1.0 + Float.exp(-x))
  };

  // Marinade mSOL compound: mSOL accrues SOL staking rewards
  func marinadeCompound(staked: Float, apr: Float) : Float {
    staked * (1.0 + apr / 365.0 / 144.0)
  };

  // Jito MEV yield: base APR + MEV boost (volatile, use EMA)
  func jitoCompound(staked: Float, apr: Float, mevBoost: Float) : Float {
    staked * (1.0 + (apr + mevBoost) / 365.0 / 144.0)
  };

  // TPS proxy: modeled as oscillation around 50k baseline
  // High TPS = network health = bullish signal
  func tpsSignal(beatCount: Nat, regime: Nat) : Float {
    let baseHealth = Float.fromInt(regime + 1) / 4.0;
    let osc = Float.sin(Float.fromInt(beatCount) * 0.001) * 0.1;
    Float.max(1.0, 1.0 + baseHealth + osc)
  };

  // Outflow risk proxy: decreasing price trend + low TPS = risk
  func outflowRisk(vel: Float, tps: Float, regime: Nat) : Float {
    let r = (if (vel < -0.02) 0.5 else 0.0) +
            (1.0 - Float.min(1.0, tps / 2.0)) * 0.3 +
            (if (regime < 1) 0.5 else 0.0);
    Float.max(1.0, 1.0 + r)
  };

  func classifyRegime(price: Float, e21: Float, e55: Float, e200: Float) : Nat {
    if (price > e21 and e21 > e55 and e55 > e200) {
      if (price > e200 * 2.2) 3 else 2
    } else if (price > e200) 1
    else 0
  };

  public func updateSol(
    s            : SolState,
    newPriceRaw  : Float,
    newMevBoost  : Float,   // 0 if no API update
    beatCount    : Nat,
    coherenceC   : Float,
    formaCapital : Float
  ) : SolState {
    let price = if (newPriceRaw > 1.0) newPriceRaw else s.solPriceUsd;
    let mev   = if (newMevBoost > 0.001) newMevBoost else s.jitoMevBoost;

    let e21  = emaUpdate(s.solEma21,  price, 21.0);
    let e55  = emaUpdate(s.solEma55,  price, 55.0);
    let e200 = emaUpdate(s.solEma200, price, 200.0);

    let vel = (price - s.solPriceUsd) / Float.max(1.0, s.solPriceUsd);
    let vol = emaUpdate(s.solVolatility, Float.abs(vel), 21.0);

    let regime = classifyRegime(price, e21, e55, e200);
    let gc     = e21 > e55;
    let above200 = price > e200;

    // Staking compounds
    let newMsol     = marinadeCompound(s.marinadeMsolStaked, s.marinadeApr);
    let msolDelta   = newMsol - s.marinadeMsolStaked;
    let newMRewards = s.marinadeRewards + msolDelta;

    let newJito     = jitoCompound(s.jitoStaked, s.jitoApr, mev);
    let jitoDelta   = newJito - s.jitoStaked;
    let newJRewards = s.jitoRewards + jitoDelta;

    // TPS signal
    let tps = tpsSignal(beatCount, regime);

    // Outflow risk
    let outflow = outflowRisk(vel, tps, regime);

    // Network health: TPS + staking yield + trend
    let health = Float.max(1.0,
      tps * 0.3 +
      (s.marinadeMsolStaked + s.jitoStaked) / 10.0 * 0.3 +
      Float.fromInt(regime + 1) / 4.0 * 0.4
    );

    // DeFi TVL proxy: grows with regime, corrects on death cross
    let tvl = Float.max(1.0,
      s.solDefiTvl * (if (regime >= 2) 1.001 else 0.9995)
    );

    // Total APR
    let totalApr = s.marinadeApr * 0.5 + (s.jitoApr + mev) * 0.5;

    // MRC yield: 20% of staking rewards
    let mrcY = (msolDelta + jitoDelta) * 0.20;

    // FORMA contribution
    let fc = Float.max(1.0, coherenceC * totalApr * 8.0 + tps * 0.2);

    // Composite signal
    let sig = sovSigmoid(
      Float.fromInt(regime) * 0.5 +
      (if (gc) 0.4 else -0.3) +
      tps * 0.2 -
      outflow * 0.1 +
      coherenceC * 0.2
    );

    let hIdx = (s.solHistoryIdx + 1) % 20;
    s.solSignalHistory[hIdx] := sig;

    s.solPriceUsd        := price;
    s.solEma21           := e21;
    s.solEma55           := e55;
    s.solEma200          := e200;
    s.solPriceVelocity   := vel;
    s.solVolatility      := vol;
    s.marinadeMsolStaked := newMsol;
    s.marinadeRewards    := newMRewards;
    s.jitoStaked         := newJito;
    s.jitoMevBoost       := mev;
    s.jitoRewards        := newJRewards;
    s.solTpsSignal       := tps;
    s.solNetworkHealth   := health;
    s.solTrendRegime     := regime;
    s.solMrcYield        := mrcY;
    s.solFormaContrib    := fc;
    s.solTotalYieldApr   := totalApr;
    s.solSignalStrength  := sig;
    s.solCrossAbove200   := above200;
    s.solGoldenCross     := gc;
    s.solOutflowRisk     := outflow;
    s.solDefiTvl         := tvl;
    s.solHistoryIdx      := hIdx;
    s
  };

  public func solTotalBeatYield(s: SolState) : Float {
    let mY = s.marinadeMsolStaked * (s.marinadeApr / 365.0 / 144.0);
    let jY = s.jitoStaked * ((s.jitoApr + s.jitoMevBoost) / 365.0 / 144.0);
    Float.max(0.0, mY + jY)
  };

};
