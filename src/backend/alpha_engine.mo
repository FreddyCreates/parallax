// alpha_engine.mo — PARALLAX alpha generation and signal discovery core
// Technical indicators and signal generation for sovereign alpha research.

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  public type PriceBar = {
    timestamp : Int;
    open : Float;
    high : Float;
    low : Float;
    close : Float;
    volume : Float;
    sentiment : Float;
  };

  public type SignalDirection = { #bullish; #bearish; #neutral };

  public type Signal = {
    name : Text;
    direction : SignalDirection;
    score : Float;
    confidence : Float;
    trigger : Float;
    rationale : Text;
  };

  public type MACDResult = {
    macd : Float;
    signal : Float;
    histogram : Float;
  };

  public type StochasticResult = {
    k : Float;
    d : Float;
  };

  public type BollingerBands = {
    middle : Float;
    upper : Float;
    lower : Float;
    bandwidth : Float;
  };

  public type KeltnerChannel = {
    middle : Float;
    upper : Float;
    lower : Float;
  };

  public type IndicatorSnapshot = {
    rsi : Float;
    macd : MACDResult;
    stochastic : StochasticResult;
    smaFast : Float;
    smaSlow : Float;
    emaFast : Float;
    emaSlow : Float;
    adx : Float;
    parabolicSar : Float;
    bollinger : BollingerBands;
    atr : Float;
    keltner : KeltnerChannel;
    obv : Float;
    cmf : Float;
    vwap : Float;
    phiWave : Float;
    phiCompression : Float;
  };

  public type AlphaReport = {
    indicators : IndicatorSnapshot;
    signals : [Signal];
  };

  func clamp(x : Float, lo : Float, hi : Float) : Float {
    Float.max(lo, Float.min(hi, x))
  };

  func last(values : [Float]) : Float {
    if (values.size() == 0) { 0.0 } else { values[values.size() - 1] }
  };

  func average(values : [Float]) : Float {
    if (values.size() == 0) { return 0.0 };
    var total = 0.0;
    for (value in values.vals()) { total += value };
    total / values.size().toFloat()
  };

  func window(values : [Float], period : Nat) : [Float] {
    if (values.size() == 0) { return [] };
    let use = Nat.min(period, values.size());
    let start = values.size() - use;
    Array.tabulate<Float>(use, func(i) { values[start + i] })
  };

  func standardDeviation(values : [Float]) : Float {
    if (values.size() <= 1) { return 0.0 };
    let mu = average(values);
    var variance = 0.0;
    for (value in values.vals()) {
      let delta = value - mu;
      variance += delta * delta;
    };
    Float.sqrt(variance / values.size().toFloat())
  };

  func highest(values : [Float], period : Nat) : Float {
    let use = window(values, period);
    if (use.size() == 0) { return 0.0 };
    var best = use[0];
    for (value in use.vals()) { if (value > best) { best := value } };
    best
  };

  func lowest(values : [Float], period : Nat) : Float {
    let use = window(values, period);
    if (use.size() == 0) { return 0.0 };
    var best = use[0];
    for (value in use.vals()) { if (value < best) { best := value } };
    best
  };

  func emaSeries(values : [Float], period : Nat) : [Float] {
    if (values.size() == 0) { return [] };
    let alpha = 2.0 / (period.toFloat() + 1.0);
    var prev = values[0];
    var result : [Float] = [prev];
    var i = 1;
    while (i < values.size()) {
      let current = prev + alpha * (values[i] - prev);
      result := result.concat([current]);
      prev := current;
      i += 1;
    };
    result
  };

  func trueRangeBar(current : PriceBar, prevClose : Float) : Float {
    let intrabar = current.high - current.low;
    let gapUp = Float.abs(current.high - prevClose);
    let gapDown = Float.abs(current.low - prevClose);
    Float.max(intrabar, Float.max(gapUp, gapDown))
  };

  public func closes(bars : [PriceBar]) : [Float] {
    Array.map<PriceBar, Float>(bars, func(bar) { bar.close })
  };

  public func volumes(bars : [PriceBar]) : [Float] {
    Array.map<PriceBar, Float>(bars, func(bar) { bar.volume })
  };

  public func sma(values : [Float], period : Nat) : Float {
    average(window(values, period))
  };

  public func ema(values : [Float], period : Nat) : Float {
    last(emaSeries(values, period))
  };

  public func rsi(values : [Float], period : Nat) : Float {
    if (values.size() <= 1) { return 50.0 };
    let use = Nat.min(period, values.size() - 1);
    var gains = 0.0;
    var losses = 0.0;
    var i = values.size() - use;
    while (i < values.size()) {
      let delta = values[i] - values[i - 1];
      if (delta >= 0.0) { gains += delta } else { losses += Float.abs(delta) };
      i += 1;
    };
    if (losses == 0.0) { return 100.0 };
    let rs = gains / Float.max(0.000001, losses);
    100.0 - (100.0 / (1.0 + rs))
  };

  public func macd(values : [Float], fastPeriod : Nat, slowPeriod : Nat, signalPeriod : Nat) : MACDResult {
    if (values.size() == 0) {
      return { macd = 0.0; signal = 0.0; histogram = 0.0 };
    };
    let fast = emaSeries(values, fastPeriod);
    let slow = emaSeries(values, slowPeriod);
    let length = Nat.min(fast.size(), slow.size());
    let line = Array.tabulate<Float>(length, func(i) { fast[i] - slow[i] });
    let signalSeries = emaSeries(line, signalPeriod);
    let macdValue = last(line);
    let signalValue = last(signalSeries);
    { macd = macdValue; signal = signalValue; histogram = macdValue - signalValue }
  };

  public func stochastic(bars : [PriceBar], kPeriod : Nat, dPeriod : Nat) : StochasticResult {
    if (bars.size() == 0) { return { k = 50.0; d = 50.0 } };
    var kValues : [Float] = [];
    let start = if (bars.size() > dPeriod) { bars.size() - dPeriod } else { 0 };
    var i = start;
    while (i < bars.size()) {
      let use = Nat.min(kPeriod, i + 1);
      let slice = Array.tabulate<PriceBar>(use, func(offset) { bars[i + 1 - use + offset] });
      let highs = Array.map<PriceBar, Float>(slice, func(bar) { bar.high });
      let lows = Array.map<PriceBar, Float>(slice, func(bar) { bar.low });
      let high = highest(highs, highs.size());
      let low = lowest(lows, lows.size());
      let close = bars[i].close;
      let k = if (high == low) { 50.0 } else { ((close - low) / (high - low)) * 100.0 };
      kValues := kValues.concat([k]);
      i += 1;
    };
    { k = last(kValues); d = average(kValues) }
  };

  public func adx(bars : [PriceBar], period : Nat) : Float {
    if (bars.size() <= 1) { return 0.0 };
    var trSeries : [Float] = [];
    var plusSeries : [Float] = [];
    var minusSeries : [Float] = [];
    var i = 1;
    while (i < bars.size()) {
      let current = bars[i];
      let prev = bars[i - 1];
      let upMove = current.high - prev.high;
      let downMove = prev.low - current.low;
      let plusDm = if (upMove > downMove and upMove > 0.0) { upMove } else { 0.0 };
      let minusDm = if (downMove > upMove and downMove > 0.0) { downMove } else { 0.0 };
      trSeries := trSeries.concat([trueRangeBar(current, prev.close)]);
      plusSeries := plusSeries.concat([plusDm]);
      minusSeries := minusSeries.concat([minusDm]);
      i += 1;
    };
    let tr = average(window(trSeries, period));
    if (tr == 0.0) { return 0.0 };
    let plusDi = average(window(plusSeries, period)) / tr * 100.0;
    let minusDi = average(window(minusSeries, period)) / tr * 100.0;
    let dx = Float.abs(plusDi - minusDi) / Float.max(0.000001, plusDi + minusDi) * 100.0;
    clamp(dx, 0.0, 100.0)
  };

  public func parabolicSar(bars : [PriceBar]) : Float {
    if (bars.size() == 0) { return 0.0 };
    if (bars.size() == 1) { return bars[0].low };
    var sar = bars[0].low;
    var extreme = bars[0].high;
    var accel = 0.02;
    var rising = bars[1].close >= bars[0].close;
    var i = 1;
    while (i < bars.size()) {
      sar += accel * (extreme - sar);
      let bar = bars[i];
      if (rising) {
        if (bar.low < sar) {
          rising := false;
          sar := extreme;
          extreme := bar.low;
          accel := 0.02;
        } else if (bar.high > extreme) {
          extreme := bar.high;
          accel := Float.min(0.2, accel + 0.02);
        };
      } else {
        if (bar.high > sar) {
          rising := true;
          sar := extreme;
          extreme := bar.high;
          accel := 0.02;
        } else if (bar.low < extreme) {
          extreme := bar.low;
          accel := Float.min(0.2, accel + 0.02);
        };
      };
      i += 1;
    };
    sar
  };

  public func bollingerBands(values : [Float], period : Nat, stdevMult : Float) : BollingerBands {
    let use = window(values, period);
    let middle = average(use);
    let sigma = standardDeviation(use);
    let upper = middle + stdevMult * sigma;
    let lower = middle - stdevMult * sigma;
    let bandwidth = if (middle == 0.0) { 0.0 } else { (upper - lower) / middle };
    { middle; upper; lower; bandwidth }
  };

  public func atr(bars : [PriceBar], period : Nat) : Float {
    if (bars.size() <= 1) { return 0.0 };
    var trSeries : [Float] = [];
    var i = 1;
    while (i < bars.size()) {
      trSeries := trSeries.concat([trueRangeBar(bars[i], bars[i - 1].close)]);
      i += 1;
    };
    average(window(trSeries, period))
  };

  public func keltnerChannel(bars : [PriceBar], emaPeriod : Nat, atrPeriod : Nat, multiplier : Float) : KeltnerChannel {
    let mid = ema(closes(bars), emaPeriod);
    let rng = atr(bars, atrPeriod);
    { middle = mid; upper = mid + multiplier * rng; lower = mid - multiplier * rng }
  };

  public func obv(bars : [PriceBar]) : Float {
    if (bars.size() == 0) { return 0.0 };
    var total = 0.0;
    var i = 1;
    while (i < bars.size()) {
      if (bars[i].close > bars[i - 1].close) {
        total += bars[i].volume;
      } else if (bars[i].close < bars[i - 1].close) {
        total -= bars[i].volume;
      };
      i += 1;
    };
    total
  };

  public func cmf(bars : [PriceBar], period : Nat) : Float {
    if (bars.size() == 0) { return 0.0 };
    let use = if (bars.size() > period) {
      Array.tabulate<PriceBar>(period, func(i) { bars[bars.size() - period + i] })
    } else {
      bars
    };
    var mfv = 0.0;
    var vol = 0.0;
    for (bar in use.vals()) {
      let denom = Float.max(0.000001, bar.high - bar.low);
      let mfm = ((bar.close - bar.low) - (bar.high - bar.close)) / denom;
      mfv += mfm * bar.volume;
      vol += bar.volume;
    };
    if (vol == 0.0) { 0.0 } else { mfv / vol }
  };

  public func vwap(bars : [PriceBar], period : Nat) : Float {
    if (bars.size() == 0) { return 0.0 };
    let use = if (bars.size() > period) {
      Array.tabulate<PriceBar>(period, func(i) { bars[bars.size() - period + i] })
    } else {
      bars
    };
    var numerator = 0.0;
    var denominator = 0.0;
    for (bar in use.vals()) {
      let typical = (bar.high + bar.low + bar.close) / 3.0;
      numerator += typical * bar.volume;
      denominator += bar.volume;
    };
    if (denominator == 0.0) { last(closes(use)) } else { numerator / denominator }
  };

  public func phiWave(values : [Float]) : Float {
    let short = ema(values, 13);
    let mid = ema(values, 21);
    let long = ema(values, 34);
    let numerator = (short - mid) + Phi.PHI_INV * (mid - long);
    numerator / Float.max(0.000001, long)
  };

  public func phiCompression(bars : [PriceBar]) : Float {
    let bb = bollingerBands(closes(bars), 20, 2.0);
    let range = atr(bars, 14);
    let base = Float.max(0.000001, bb.middle);
    clamp((range / base) / Float.max(0.000001, bb.bandwidth + Phi.PHI_INV_3), 0.0, Phi.PHI_4)
  };

  public func indicatorSnapshot(bars : [PriceBar]) : IndicatorSnapshot {
    let closeSeries = closes(bars);
    {
      rsi = rsi(closeSeries, 14);
      macd = macd(closeSeries, 12, 26, 9);
      stochastic = stochastic(bars, 14, 3);
      smaFast = sma(closeSeries, 20);
      smaSlow = sma(closeSeries, 50);
      emaFast = ema(closeSeries, 12);
      emaSlow = ema(closeSeries, 26);
      adx = adx(bars, 14);
      parabolicSar = parabolicSar(bars);
      bollinger = bollingerBands(closeSeries, 20, 2.0);
      atr = atr(bars, 14);
      keltner = keltnerChannel(bars, 20, 14, 2.0);
      obv = obv(bars);
      cmf = cmf(bars, 20);
      vwap = vwap(bars, 20);
      phiWave = phiWave(closeSeries);
      phiCompression = phiCompression(bars);
    }
  };

  func mkSignal(name : Text, direction : SignalDirection, score : Float, confidence : Float, trigger : Float, rationale : Text) : Signal {
    { name; direction; score; confidence = clamp(confidence, 0.0, 1.0); trigger; rationale }
  };

  func appendSignal(signals : [Signal], candidate : ?Signal) : [Signal] {
    switch (candidate) {
      case null { signals };
      case (?signal) { signals.concat([signal]) };
    }
  };

  public func detectHeadAndShoulders(bars : [PriceBar]) : ?Signal {
    let values = closes(bars);
    if (values.size() < 7) { return null };
    let n = values.size();
    let left = values[n - 6];
    let trough1 = values[n - 5];
    let head = values[n - 4];
    let trough2 = values[n - 3];
    let right = values[n - 2];
    let close = values[n - 1];
    let neckline = (trough1 + trough2) / 2.0;
    let symmetry = 1.0 - Float.abs(left - right) / Float.max(0.000001, Float.max(left, right));
    if (head > left and head > right and close < neckline and symmetry > Phi.PHI_INV_2) {
      ?mkSignal("head_shoulders", #bearish, (head - neckline) / Float.max(0.000001, neckline), symmetry, neckline, "Pattern breakdown below neckline")
    } else if (head < left and head < right and close > neckline and symmetry > Phi.PHI_INV_2) {
      ?mkSignal("inverse_head_shoulders", #bullish, (close - neckline) / Float.max(0.000001, neckline), symmetry, neckline, "Inverse pattern breakout above neckline")
    } else {
      null
    }
  };

  public func detectTriangle(bars : [PriceBar]) : ?Signal {
    if (bars.size() < 8) { return null };
    let use = Array.tabulate<PriceBar>(8, func(i) { bars[bars.size() - 8 + i] });
    let highs = Array.map<PriceBar, Float>(use, func(bar) { bar.high });
    let lows = Array.map<PriceBar, Float>(use, func(bar) { bar.low });
    let upperSlope = highs[highs.size() - 1] - highs[0];
    let lowerSlope = lows[lows.size() - 1] - lows[0];
    let lastClose = use[use.size() - 1].close;
    let rangeCompression = 1.0 - ((highs[highs.size() - 1] - lows[lows.size() - 1]) / Float.max(0.000001, highs[0] - lows[0]));
    if (upperSlope < 0.0 and lowerSlope > 0.0 and lastClose > highs[highs.size() - 2]) {
      ?mkSignal("triangle_breakout", #bullish, rangeCompression, clamp(rangeCompression + Phi.PHI_INV_3, 0.0, 1.0), highs[highs.size() - 2], "Symmetrical triangle resolved upward")
    } else if (upperSlope < 0.0 and lowerSlope > 0.0 and lastClose < lows[lows.size() - 2]) {
      ?mkSignal("triangle_breakdown", #bearish, rangeCompression, clamp(rangeCompression + Phi.PHI_INV_3, 0.0, 1.0), lows[lows.size() - 2], "Symmetrical triangle resolved downward")
    } else {
      null
    }
  };

  public func detectFlag(bars : [PriceBar]) : ?Signal {
    if (bars.size() < 10) { return null };
    let recent = Array.tabulate<PriceBar>(10, func(i) { bars[bars.size() - 10 + i] });
    let poleStart = recent[0].close;
    let poleEnd = recent[4].close;
    let consolidation = recent[9].close - recent[5].close;
    let impulse = (poleEnd - poleStart) / Float.max(0.000001, poleStart);
    if (impulse > Phi.PHI_INV_3 and Float.abs(consolidation) < Float.abs(impulse) * recent[5].close * 0.5 and recent[9].close > recent[8].high) {
      ?mkSignal("bull_flag", #bullish, impulse, clamp(Phi.PHI_INV + impulse, 0.0, 1.0), recent[8].high, "Impulse trend resumed after flag consolidation")
    } else if (impulse < -Phi.PHI_INV_3 and Float.abs(consolidation) < Float.abs(impulse) * recent[5].close * 0.5 and recent[9].close < recent[8].low) {
      ?mkSignal("bear_flag", #bearish, Float.abs(impulse), clamp(Phi.PHI_INV + Float.abs(impulse), 0.0, 1.0), recent[8].low, "Downtrend resumed after flag consolidation")
    } else {
      null
    }
  };

  public func statisticalArbitrageSignal(bars : [PriceBar], reference : [Float]) : ?Signal {
    let values = closes(bars);
    if (values.size() < 10 or reference.size() < 10) { return null };
    let n = Nat.min(values.size(), reference.size());
    var spread : [Float] = [];
    var i = 0;
    while (i < n) {
      let beta = values[i] / Float.max(0.000001, reference[i]);
      spread := spread.concat([values[i] - beta * reference[i]]);
      i += 1;
    };
    let recent = window(spread, 20);
    let mu = average(recent);
    let sigma = Float.max(0.000001, standardDeviation(recent));
    let z = (last(recent) - mu) / sigma;
    if (z > 1.0) {
      ?mkSignal("stat_arb", #bearish, Float.abs(z), clamp(Float.abs(z) / Phi.PHI, 0.0, 1.0), z, "Spread above mean — short rich leg")
    } else if (z < -1.0) {
      ?mkSignal("stat_arb", #bullish, Float.abs(z), clamp(Float.abs(z) / Phi.PHI, 0.0, 1.0), z, "Spread below mean — buy cheap leg")
    } else {
      null
    }
  };

  public func meanReversionSignal(bars : [PriceBar]) : ?Signal {
    let values = closes(bars);
    if (values.size() < 20) { return null };
    let bb = bollingerBands(values, 20, 2.0);
    let lastClose = last(values);
    let r = rsi(values, 14);
    if (lastClose < bb.lower and r < 35.0) {
      ?mkSignal("mean_reversion", #bullish, (bb.lower - lastClose) / Float.max(0.000001, bb.middle), clamp((35.0 - r) / 35.0 + Phi.PHI_INV_3, 0.0, 1.0), bb.lower, "Oversold close outside lower Bollinger band")
    } else if (lastClose > bb.upper and r > 65.0) {
      ?mkSignal("mean_reversion", #bearish, (lastClose - bb.upper) / Float.max(0.000001, bb.middle), clamp((r - 65.0) / 35.0 + Phi.PHI_INV_3, 0.0, 1.0), bb.upper, "Overbought close outside upper Bollinger band")
    } else {
      null
    }
  };

  public func momentumSignal(bars : [PriceBar]) : ?Signal {
    let values = closes(bars);
    if (values.size() < 26) { return null };
    let macdValue = macd(values, 12, 26, 9);
    let fast = sma(values, 20);
    let slow = sma(values, 50);
    let strength = adx(bars, 14);
    if (macdValue.histogram > 0.0 and fast > slow and strength > 20.0) {
      ?mkSignal("momentum", #bullish, macdValue.histogram, clamp(strength / 50.0, 0.0, 1.0), fast - slow, "MACD and trend alignment confirm upside momentum")
    } else if (macdValue.histogram < 0.0 and fast < slow and strength > 20.0) {
      ?mkSignal("momentum", #bearish, Float.abs(macdValue.histogram), clamp(strength / 50.0, 0.0, 1.0), slow - fast, "MACD and trend alignment confirm downside momentum")
    } else {
      null
    }
  };

  public func sentimentSignal(bars : [PriceBar]) : ?Signal {
    if (bars.size() < 3) { return null };
    let use = if (bars.size() > 5) { Array.tabulate<PriceBar>(5, func(i) { bars[bars.size() - 5 + i] }) } else { bars };
    let avgSentiment = average(Array.map<PriceBar, Float>(use, func(bar) { bar.sentiment }));
    let priceImpulse = (use[use.size() - 1].close - use[0].close) / Float.max(0.000001, use[0].close);
    if (avgSentiment > Phi.PHI_INV_2 and priceImpulse >= 0.0) {
      ?mkSignal("sentiment", #bullish, avgSentiment, clamp(avgSentiment, 0.0, 1.0), avgSentiment, "Constructive sentiment confirms price action")
    } else if (avgSentiment < -Phi.PHI_INV_2 and priceImpulse <= 0.0) {
      ?mkSignal("sentiment", #bearish, Float.abs(avgSentiment), clamp(Float.abs(avgSentiment), 0.0, 1.0), avgSentiment, "Negative sentiment confirms price weakness")
    } else {
      null
    }
  };

  public func phiSignal(bars : [PriceBar]) : ?Signal {
    let values = closes(bars);
    if (values.size() < 34) { return null };
    let wave = phiWave(values);
    let compression = phiCompression(bars);
    if (wave > 0.0 and compression < 1.0) {
      ?mkSignal("phi_resonance", #bullish, wave, clamp(1.0 - compression / Phi.PHI, 0.0, 1.0), compression, "Phi-wave expansion with non-chaotic compression")
    } else if (wave < 0.0 and compression < 1.0) {
      ?mkSignal("phi_resonance", #bearish, Float.abs(wave), clamp(1.0 - compression / Phi.PHI, 0.0, 1.0), compression, "Negative phi-wave resonance with orderly compression")
    } else {
      null
    }
  };

  public func generateSignals(bars : [PriceBar], reference : [Float]) : [Signal] {
    var signals : [Signal] = [];
    signals := appendSignal(signals, detectHeadAndShoulders(bars));
    signals := appendSignal(signals, detectTriangle(bars));
    signals := appendSignal(signals, detectFlag(bars));
    signals := appendSignal(signals, statisticalArbitrageSignal(bars, reference));
    signals := appendSignal(signals, meanReversionSignal(bars));
    signals := appendSignal(signals, momentumSignal(bars));
    signals := appendSignal(signals, sentimentSignal(bars));
    signals := appendSignal(signals, phiSignal(bars));
    signals
  };

  public func alphaReport(bars : [PriceBar], reference : [Float]) : AlphaReport {
    {
      indicators = indicatorSnapshot(bars);
      signals = generateSignals(bars, reference);
    }
  };
}
