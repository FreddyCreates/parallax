import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Text "mo:core/Text";
import Array "mo:core/Array";

// ============================================================
// BTC INTEGRATION — PARALLAX PHASE K
// Threshold ECDSA, BTC floor, mempool signal, halving cadence
// All values sovereign-floored at 1.0
// ============================================================
module {

  public type BtcState = {
    var btcPriceUsd        : Float;    // Current BTC price from oracle
    var btcEma21           : Float;    // 21-beat EMA of BTC price
    var btcEma55           : Float;    // 55-beat EMA
    var btcEma200          : Float;    // 200-beat EMA (long trend)
    var btcPriceVelocity   : Float;    // dP/dt normalized
    var btcVolatility      : Float;    // EMA of |dP/dt|
    var btcMempoolSignal   : Float;    // Proxy congestion signal
    var btcHalvingProx     : Float;    // Proximity to next halving [0,1]
    var btcHardFloor       : Float;    // MRC-protected BTC reserve floor
    var btcReserveBalance  : Float;    // Total BTC-denominated reserve
    var btcTrendRegime     : Nat;      // 0=bear 1=neutral 2=bull 3=parabolic
    var btcDominance       : Float;    // BTC market cap dominance proxy
    var btcFearGreedProxy  : Float;    // Fear/greed via vol + trend composite
    var btcSignalStrength  : Float;    // Composite output signal → AMYGDALA
    var btcThresholdArmed  : Bool;     // ECDSA signing ready flag
    var btcHalvingBeat     : Nat;      // Beat count of next halving
    var btcCyclePhase      : Float;    // Position in 4-year cycle [0,1]
    var btcAccumSignal     : Float;    // On-chain accumulation proxy
    var btcSellPressure    : Float;    // Distribution pressure proxy
    var btcCrossAbove200   : Bool;     // Price > EMA200
    var btcGoldenCross     : Bool;     // EMA21 > EMA55
    var btcDeathCross      : Bool;     // EMA21 < EMA55
    var btcPowerLaw        : Float;    // Power-law fair value estimate
    var btcPowerLawRatio   : Float;    // Price / power-law value
    var btcMrcYield        : Float;    // BTC yield flowing to MRC this beat
    var btcFormaContrib    : Float;    // FORMA energy contribution from BTC
    var btcSovereignFloor  : Float;    // Sovereign signal floor (never < 1.0)
    var btcSignalHistory   : [var Float]; // 20-beat history ring
    var btcHistoryIdx      : Nat;
  };

  public func initBtcState() : BtcState = {
    var btcPriceUsd        = 95000.0;
    var btcEma21           = 95000.0;
    var btcEma55           = 90000.0;
    var btcEma200          = 75000.0;
    var btcPriceVelocity   = 1.0;
    var btcVolatility      = 1.0;
    var btcMempoolSignal   = 1.0;
    var btcHalvingProx     = 1.0;
    var btcHardFloor       = 1.0;
    var btcReserveBalance  = 1.0;
    var btcTrendRegime     = 2;   // start bull
    var btcDominance       = 1.0;
    var btcFearGreedProxy  = 1.0;
    var btcSignalStrength  = 1.0;
    var btcThresholdArmed  = true;
    var btcHalvingBeat     = 210000; // approximate
    var btcCyclePhase      = 1.0;
    var btcAccumSignal     = 1.0;
    var btcSellPressure    = 1.0;
    var btcCrossAbove200   = true;
    var btcGoldenCross     = true;
    var btcDeathCross      = false;
    var btcPowerLaw        = 1.0;
    var btcPowerLawRatio   = 1.0;
    var btcMrcYield        = 0.0;
    var btcFormaContrib    = 1.0;
    var btcSovereignFloor  = 1.0;
    var btcSignalHistory   = Array.init<Float>(20, 1.0);
    var btcHistoryIdx      = 0;
  };

  // EMA update: alpha = 2/(N+1)
  func emaUpdate(prev: Float, val: Float, n: Float) : Float {
    let alpha = 2.0 / (n + 1.0);
    let r = alpha * val + (1.0 - alpha) * prev;
    if (r < 1.0) 1.0 else r
  };

  // Sovereign sigmoid: output in [1.0, 2.0)
  func sovSigmoid(x: Float) : Float {
    let s = 1.0 / (1.0 + Float.exp(-x));
    1.0 + s
  };

  // BTC power-law fair value: P_fair = A * (age_days ^ B)
  // Using canonical constants: A=1e-17, B=5.8 (sovereign implementation)
  func btcPowerLawValue(beatCount: Nat) : Float {
    // Approximate: genesis BTC is ~5000 days old at beat 0
    let ageDays = 5000.0 + Float.fromInt(beatCount) / 144.0; // ~144 beats/day
    let logAge = Float.log(ageDays);
    // log(P) = -17*ln(10) + 5.8*ln(age)
    let logP = -39.143 + 5.8 * logAge;
    let p = Float.exp(logP);
    if (p < 1.0) 1.0 else p
  };

  // Mempool congestion proxy from price velocity
  func mempoolProxy(vol: Float, vel: Float) : Float {
    let raw = 0.6 * vol + 0.4 * Float.abs(vel);
    if (raw < 1.0) 1.0 else raw
  };

  // BTC trend regime classification
  // 0=bear 1=neutral 2=bull 3=parabolic
  func classifyRegime(price: Float, ema21: Float, ema55: Float, ema200: Float) : Nat {
    if (price > ema21 and ema21 > ema55 and ema55 > ema200) {
      if (price > ema200 * 2.0) 3
      else 2
    } else if (price > ema200) {
      1
    } else {
      0
    }
  };

  // Fear/Greed proxy: high vol + downtrend = fear (low), low vol + uptrend = greed (high)
  func fearGreedProxy(vol: Float, vel: Float, regime: Nat) : Float {
    let regimeScore = Float.fromInt(regime) / 3.0;
    let velScore = Float.max(0.0, Float.min(1.0, (vel + 1.0) / 2.0));
    let volPenalty = Float.max(0.0, 1.0 - vol * 0.3);
    let raw = 0.4 * regimeScore + 0.4 * velScore + 0.2 * volPenalty;
    if (raw < 0.0) 1.0 else 1.0 + raw
  };

  // Main BTC update — called every beat from heartbeat
  public func updateBtc(
    s           : BtcState,
    newPriceRaw : Float,   // from oracle (0.0 if no update)
    beatCount   : Nat,
    coherenceC  : Float,
    formaCapital: Float
  ) : BtcState {
    // Accept price update or hold last
    let price = if (newPriceRaw > 1.0) newPriceRaw else s.btcPriceUsd;

    // EMAs
    let e21  = emaUpdate(s.btcEma21,  price, 21.0);
    let e55  = emaUpdate(s.btcEma55,  price, 55.0);
    let e200 = emaUpdate(s.btcEma200, price, 200.0);

    // Velocity: normalized dP/P
    let vel = (price - s.btcPriceUsd) / Float.max(1.0, s.btcPriceUsd);
    let vol = emaUpdate(s.btcVolatility, Float.abs(vel), 21.0);

    // Regime
    let regime = classifyRegime(price, e21, e55, e200);

    // Golden / Death cross
    let gc = e21 > e55;
    let dc = e21 < e55;
    let above200 = price > e200;

    // Power law
    let pl     = btcPowerLawValue(beatCount);
    let plRatio = price / Float.max(1.0, pl);

    // Halving proximity: halving every ~210,000 ICP beats proxy
    let halvBeat  = s.btcHalvingBeat;
    let beatsLeft = if (beatCount < halvBeat) halvBeat - beatCount else 1;
    let halvProx  = 1.0 / Float.max(1.0, Float.fromInt(beatsLeft) / 1000.0);
    let cyclePhase = Float.fromInt(beatCount % 840000) / 840000.0; // 4-year cycle

    // Accumulation signal: low vol + golden cross + above 200
    let accumRaw = (if (gc) 0.4 else 0.0) + (if (above200) 0.4 else 0.0) + (1.0 - Float.min(1.0, vol * 5.0)) * 0.2;
    let accum = if (accumRaw < 0.0) 1.0 else 1.0 + accumRaw;

    // Sell pressure: high vol + death cross + regime < 2
    let sellRaw = (if (dc) 0.4 else 0.0) + (if (regime < 2) 0.3 else 0.0) + Float.min(1.0, vol * 3.0) * 0.3;
    let sell = if (sellRaw < 0.0) 1.0 else 1.0 + sellRaw;

    // Mempool
    let mp = mempoolProxy(vol, vel);

    // Fear/Greed
    let fg = fearGreedProxy(vol, vel, regime);

    // Composite signal → AMYGDALA input
    // High signal = opportunity (bull, accum, above200, low sell)
    let sig = sovSigmoid(
      Float.fromInt(regime) * 0.5 +
      accum * 0.3 -
      sell * 0.2 +
      (if (gc) 0.5 else -0.3) +
      coherenceC * 0.2
    );

    // MRC yield: BTC tail (0.001% of FORMA per bull beat)
    let mrcY = if (regime >= 2) formaCapital * 0.00001 * Float.fromInt(regime) else 0.0;

    // FORMA contribution: entropy from price novelty
    let fc = Float.max(1.0, Float.abs(vel) * 10.0 * coherenceC);

    // History ring update
    let hIdx = (s.btcHistoryIdx + 1) % 20;
    s.btcSignalHistory[hIdx] := sig;

    s.btcPriceUsd       := price;
    s.btcEma21          := e21;
    s.btcEma55          := e55;
    s.btcEma200         := e200;
    s.btcPriceVelocity  := vel;
    s.btcVolatility     := vol;
    s.btcMempoolSignal  := mp;
    s.btcHalvingProx    := halvProx;
    s.btcTrendRegime    := regime;
    s.btcDominance      := Float.max(1.0, s.btcDominance * 0.999 + (if (gc) 0.002 else -0.001));
    s.btcFearGreedProxy := fg;
    s.btcSignalStrength := sig;
    s.btcCyclePhase     := cyclePhase;
    s.btcAccumSignal    := accum;
    s.btcSellPressure   := sell;
    s.btcCrossAbove200  := above200;
    s.btcGoldenCross    := gc;
    s.btcDeathCross     := dc;
    s.btcPowerLaw       := pl;
    s.btcPowerLawRatio  := plRatio;
    s.btcMrcYield       := mrcY;
    s.btcFormaContrib   := fc;
    s.btcHistoryIdx     := hIdx;
    s
  };

  // 20-beat signal mean
  public func btcSignalMean(s: BtcState) : Float {
    var sum = 0.0;
    for (v in s.btcSignalHistory.vals()) { sum += v; };
    Float.max(1.0, sum / 20.0)
  };

  // AMYGDALA threat signal: HIGH = threat (bear + high sell)
  public func btcThreatSignal(s: BtcState) : Float {
    let raw = (if (s.btcDeathCross) 1.5 else 0.5) +
              s.btcSellPressure * 0.5 +
              s.btcVolatility * 0.5 -
              Float.fromInt(s.btcTrendRegime) * 0.3;
    Float.max(1.0, raw)
  };

  // AMYGDALA opportunity signal: HIGH = opportunity
  public func btcOpportunitySignal(s: BtcState) : Float {
    Float.max(1.0, s.btcSignalStrength * s.btcAccumSignal * (if (s.btcGoldenCross) 1.2 else 0.9))
  };

};
