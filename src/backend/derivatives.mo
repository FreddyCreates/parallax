import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {
  public type OptionKind = { #call; #put };
  public type BinaryPayoff = { #cash; #asset };
  public type AsianAveraging = { #arithmetic; #geometric };
  public type BarrierType = { #upAndIn; #upAndOut; #downAndIn; #downAndOut };
  public type LookbackStyle = { #fixedStrike; #floatingStrike };
  public type RainbowPayoff = { #bestOfCall; #worstOfCall; #bestOfPut; #worstOfPut };
  public type CapFloorKind = { #cap; #floor };
  public type SwaptionKind = { #payer; #receiver };

  public type VanillaOptionSpec = {
    spot : Float;
    strike : Float;
    rate : Float;
    dividendYield : Float;
    volatility : Float;
    maturity : Float;
  };

  public type Black76Spec = {
    forward : Float;
    strike : Float;
    rate : Float;
    volatility : Float;
    maturity : Float;
  };

  public type MonteCarloConfig = {
    paths : Nat;
    timeSteps : Nat;
    antithetic : Bool;
  };

  public type AsianOptionSpec = {
    vanilla : VanillaOptionSpec;
    averagingSteps : Nat;
    averagingType : AsianAveraging;
  };

  public type BarrierOptionSpec = {
    vanilla : VanillaOptionSpec;
    barrier : Float;
    rebate : Float;
    barrierType : BarrierType;
    monitoringSteps : Nat;
  };

  public type BinaryOptionSpec = {
    vanilla : VanillaOptionSpec;
    payoffType : BinaryPayoff;
    cashPayoff : Float;
  };

  public type LookbackOptionSpec = {
    vanilla : VanillaOptionSpec;
    lookbackSteps : Nat;
    style : LookbackStyle;
  };

  public type CliquetOptionSpec = {
    spot : Float;
    rate : Float;
    dividendYield : Float;
    volatility : Float;
    maturity : Float;
    resetCount : Nat;
    localCap : Float;
    localFloor : Float;
    globalCap : Float;
    globalFloor : Float;
    notional : Float;
  };

  public type MultiAssetSpec = {
    spots : [Float];
    volatilities : [Float];
    dividendYields : [Float];
    correlation : [[Float]];
    rate : Float;
    maturity : Float;
  };

  public type BasketOptionSpec = {
    market : MultiAssetSpec;
    weights : [Float];
    strike : Float;
    kind : OptionKind;
  };

  public type SpreadOptionSpec = {
    spot1 : Float;
    spot2 : Float;
    vol1 : Float;
    vol2 : Float;
    dividendYield1 : Float;
    dividendYield2 : Float;
    correlation : Float;
    strike : Float;
    rate : Float;
    maturity : Float;
    kind : OptionKind;
  };

  public type RainbowOptionSpec = {
    market : MultiAssetSpec;
    strike : Float;
    payoffType : RainbowPayoff;
  };

  public type ZeroCouponBondSpec = {
    face : Float;
    yieldRate : Float;
    maturity : Float;
  };

  public type CouponBondSpec = {
    face : Float;
    couponRate : Float;
    yieldRate : Float;
    maturity : Float;
    paymentsPerYear : Nat;
  };

  public type DepositInstrument = {
    maturity : Float;
    simpleRate : Float;
  };

  public type CouponBondInstrument = {
    price : Float;
    face : Float;
    couponRate : Float;
    maturity : Float;
    paymentsPerYear : Nat;
  };

  public type CurveInstrument = {
    #deposit : DepositInstrument;
    #couponBond : CouponBondInstrument;
  };

  public type ZeroCurvePoint = {
    maturity : Float;
    discountFactor : Float;
    zeroRate : Float;
  };

  public type FRASpec = {
    notional : Float;
    strikeRate : Float;
    forwardRate : Float;
    discountRate : Float;
    start : Float;
    end_ : Float;
  };

  public type SwapCashflowSchedule = {
    paymentTimes : [Float];
    accrualFractions : [Float];
    forwardRates : [Float];
    discountFactors : [Float];
  };

  public type SwapSpec = {
    notional : Float;
    fixedRate : Float;
    schedule : SwapCashflowSchedule;
    payFixed : Bool;
  };

  public type CapFloorSpec = {
    notional : Float;
    strike : Float;
    forwardRates : [Float];
    volatilities : [Float];
    accrualFractions : [Float];
    paymentTimes : [Float];
    discountFactors : [Float];
    kind : CapFloorKind;
  };

  public type SwaptionSpec = {
    notional : Float;
    strike : Float;
    forwardSwapRate : Float;
    annuity : Float;
    rate : Float;
    volatility : Float;
    expiry : Float;
    kind : SwaptionKind;
  };

  public type VarianceSwapSpec = {
    logReturns : [Float];
    annualizationFactor : Float;
    strikeVariance : Float;
    notional : Float;
    maturity : Float;
    rate : Float;
  };

  public type VolatilitySwapSpec = {
    realizedVariance : Float;
    strikeVolatility : Float;
    notional : Float;
    maturity : Float;
    rate : Float;
    volOfVol : Float;
  };

  public type VixOptionQuote = {
    strike : Float;
    callPrice : Float;
    putPrice : Float;
  };

  public type VixSpec = {
    optionStrip : [VixOptionQuote];
    forward : Float;
    rate : Float;
    maturity : Float;
  };

  public type VolQuote = {
    maturity : Float;
    strike : Float;
    impliedVol : Float;
  };

  public type VolSurfaceRequest = {
    quotes : [VolQuote];
    maturities : [Float];
    strikes : [Float];
  };

  public type VolSurfaceNode = {
    maturity : Float;
    strike : Float;
    impliedVol : Float;
  };

  public type MertonSpec = {
    assetValue : Float;
    debtFace : Float;
    assetVolatility : Float;
    rate : Float;
    maturity : Float;
    recoveryRate : Float;
  };

  public type CDSSpec = {
    notional : Float;
    marketSpread : Float;
    paymentsPerYear : Nat;
    merton : MertonSpec;
  };

  public type Greeks = {
    delta : Float;
    gamma : Float;
    vega : Float;
    theta : Float;
    rho : Float;
  };

  public type VanillaOptionResult = {
    price : Float;
    intrinsicValue : Float;
    timeValue : Float;
    d1 : Float;
    d2 : Float;
    greeks : Greeks;
  };

  public type MonteCarloResult = {
    price : Float;
    standardError : Float;
    confidenceLow : Float;
    confidenceHigh : Float;
  };

  public type AmericanOptionResult = {
    price : Float;
    intrinsicValue : Float;
    earlyExercisePremium : Float;
    standardError : Float;
  };

  public type BondPriceResult = {
    price : Float;
    macaulayDuration : Float;
    modifiedDuration : Float;
  };

  public type YieldCurveResult = {
    points : [ZeroCurvePoint];
    bootstrapError : Float;
  };

  public type FRAResult = {
    value : Float;
    forwardDiscountFactor : Float;
    settlementAmount : Float;
  };

  public type SwapResult = {
    fixedLegPV : Float;
    floatingLegPV : Float;
    parRate : Float;
    netPresentValue : Float;
  };

  public type CapFloorResult = {
    price : Float;
    capletPrices : [Float];
    fairRate : Float;
  };

  public type SwaptionResult = {
    price : Float;
    intrinsicValue : Float;
  };

  public type VarianceSwapResult = {
    fairVariance : Float;
    price : Float;
  };

  public type VolatilitySwapResult = {
    fairVolatility : Float;
    convexityAdjustment : Float;
    price : Float;
  };

  public type VixResult = {
    variance : Float;
    vix : Float;
  };

  public type VolSurfaceResult = {
    nodes : [VolSurfaceNode];
  };

  public type MertonResult = {
    equityValue : Float;
    riskyDebtValue : Float;
    defaultProbability : Float;
    distanceToDefault : Float;
    creditSpread : Float;
  };

  public type CDSResult = {
    fairSpread : Float;
    markToMarket : Float;
    protectionLeg : Float;
    premiumLeg : Float;
    defaultProbability : Float;
  };

  let EPS : Float = 0.000000001;
  let CI95 : Float = 1.959963984540054;
  let HALTON_BASES : [Nat] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];

  func max0(x : Float) : Float { Float.max(0.0, x) };
  func sq(x : Float) : Float { x * x };
  func safeTime(t : Float) : Float { Float.max(EPS, t) };
  func safeVol(v : Float) : Float { Float.max(EPS, Float.abs(v)) };
  func discount(rate : Float, t : Float) : Float { Float.exp(-rate * Float.max(0.0, t)) };
  func intrinsic(kind : OptionKind, spot : Float, strike : Float) : Float {
    switch (kind) {
      case (#call) max0(spot - strike);
      case (#put) max0(strike - spot);
    }
  };
  func natMax(a : Nat, b : Nat) : Nat { if (a >= b) a else b };
  func natMin(a : Nat, b : Nat) : Nat { if (a <= b) a else b };
  func safeNatSub(a : Nat, b : Nat) : Nat {
    let delta = a.toInt() - b.toInt();
    if (delta <= 0) 0 else delta.toNat()
  };
  func boolToFloat(v : Bool) : Float { if (v) 1.0 else 0.0 };

  func ceilNat(x : Float) : Nat {
    let clipped = Float.max(0.0, x);
    let floored = Float.floor(clipped);
    let base : Int = Float.toInt(floored);
    if (clipped - floored > EPS) {
      (base + 1).toNat()
    } else {
      base.toNat()
    }
  };

  func normalPdf(x : Float) : Float {
    Float.exp(-0.5 * x * x) / Float.sqrt(2.0 * Float.pi)
  };

  func normalCdf(x : Float) : Float {
    let k = 1.0 / (1.0 + 0.2316419 * Float.abs(x));
    let poly = ((((1.330274429 * k - 1.821255978) * k + 1.781477937) * k - 0.356563782) * k + 0.319381530) * k;
    let approx = 1.0 - normalPdf(x) * poly;
    if (x >= 0.0) approx else 1.0 - approx
  };

  func inverseNormalCdf(p : Float) : Float {
    let q = Float.min(1.0 - EPS, Float.max(EPS, p));
    let a1 = -39.69683028665376;
    let a2 = 220.9460984245205;
    let a3 = -275.9285104469687;
    let a4 = 138.3577518672690;
    let a5 = -30.66479806614716;
    let a6 = 2.506628277459239;
    let b1 = -54.47609879822406;
    let b2 = 161.5858368580409;
    let b3 = -155.6989798598866;
    let b4 = 66.80131188771972;
    let b5 = -13.28068155288572;
    let c1 = -0.007784894002430293;
    let c2 = -0.3223964580411365;
    let c3 = -2.400758277161838;
    let c4 = -2.549732539343734;
    let c5 = 4.374664141464968;
    let c6 = 2.938163982698783;
    let d1 = 0.007784695709041462;
    let d2 = 0.3224671290700398;
    let d3 = 2.445134137142996;
    let d4 = 3.754408661907416;
    let pLow = 0.02425;
    let pHigh = 1.0 - pLow;
    if (q < pLow) {
      let r = Float.sqrt(-2.0 * Float.log(q));
      (((((c1 * r + c2) * r + c3) * r + c4) * r + c5) * r + c6) /
      ((((d1 * r + d2) * r + d3) * r + d4) * r + 1.0)
    } else if (q <= pHigh) {
      let r = q - 0.5;
      let s = r * r;
      (((((a1 * s + a2) * s + a3) * s + a4) * s + a5) * s + a6) * r /
      (((((b1 * s + b2) * s + b3) * s + b4) * s + b5) * s + 1.0)
    } else {
      let r = Float.sqrt(-2.0 * Float.log(1.0 - q));
      -(((((c1 * r + c2) * r + c3) * r + c4) * r + c5) * r + c6) /
      ((((d1 * r + d2) * r + d3) * r + d4) * r + 1.0)
    }
  };

  func halton(index : Nat, dimension : Nat) : Float {
    let base = HALTON_BASES[dimension % HALTON_BASES.size()];
    var f = 1.0;
    var r = 0.0;
    var i = index;
    while (i > 0) {
      f /= base.toFloat();
      r += f * (i % base).toFloat();
      i /= base;
    };
    r
  };

  func quasiNormal(pathIndex : Nat, dimension : Nat, antithetic : Bool) : Float {
    let effectiveIndex = if (antithetic) { pathIndex / 2 + 1 } else { pathIndex + 1 };
    let z = inverseNormalCdf(halton(effectiveIndex, dimension));
    if (antithetic and pathIndex % 2 == 1) -z else z
  };

  func blackScholesD1(spec : VanillaOptionSpec) : Float {
    let vt = safeVol(spec.volatility) * Float.sqrt(safeTime(spec.maturity));
    (Float.log(Float.max(EPS, spec.spot) / Float.max(EPS, spec.strike)) + (spec.rate - spec.dividendYield + 0.5 * sq(spec.volatility)) * safeTime(spec.maturity)) / vt
  };

  func blackScholesD2(spec : VanillaOptionSpec) : Float {
    blackScholesD1(spec) - safeVol(spec.volatility) * Float.sqrt(safeTime(spec.maturity))
  };

  func black76D1(spec : Black76Spec) : Float {
    let vt = safeVol(spec.volatility) * Float.sqrt(safeTime(spec.maturity));
    (Float.log(Float.max(EPS, spec.forward) / Float.max(EPS, spec.strike)) + 0.5 * sq(spec.volatility) * safeTime(spec.maturity)) / vt
  };

  func black76D2(spec : Black76Spec) : Float {
    black76D1(spec) - safeVol(spec.volatility) * Float.sqrt(safeTime(spec.maturity))
  };

  func makeMcResult(samples : [Float]) : MonteCarloResult {
    if (samples.size() == 0) {
      return {
        price = 0.0;
        standardError = 0.0;
        confidenceLow = 0.0;
        confidenceHigh = 0.0;
      };
    };
    let n = samples.size().toFloat();
    let mean = Array.foldLeft<Float, Float>(samples, 0.0, func(acc, x) { acc + x }) / n;
    let variance = if (samples.size() <= 1) {
      0.0
    } else {
      Array.foldLeft<Float, Float>(samples, 0.0, func(acc, x) { acc + sq(x - mean) }) / (n - 1.0)
    };
    let stderr = Float.sqrt(Float.max(0.0, variance / n));
    {
      price = mean;
      standardError = stderr;
      confidenceLow = mean - CI95 * stderr;
      confidenceHigh = mean + CI95 * stderr;
    }
  };

  func computeGreeksInternal(spec : VanillaOptionSpec, kind : OptionKind) : Greeks {
    if (spec.maturity <= EPS or spec.volatility <= EPS) {
      let forward = spec.spot * Float.exp((spec.rate - spec.dividendYield) * spec.maturity);
      let itmCall = forward > spec.strike;
      let delta = switch (kind) {
        case (#call) { discount(spec.dividendYield, spec.maturity) * boolToFloat(itmCall) };
        case (#put) { -discount(spec.dividendYield, spec.maturity) * boolToFloat(not itmCall) };
      };
      return { delta = delta; gamma = 0.0; vega = 0.0; theta = 0.0; rho = 0.0 };
    };
    let d1 = blackScholesD1(spec);
    let d2 = blackScholesD2(spec);
    let discQ = discount(spec.dividendYield, spec.maturity);
    let discR = discount(spec.rate, spec.maturity);
    let pdf = normalPdf(d1);
    let sqrtT = Float.sqrt(spec.maturity);
    let delta = switch (kind) {
      case (#call) { discQ * normalCdf(d1) };
      case (#put) { discQ * (normalCdf(d1) - 1.0) };
    };
    let gamma = discQ * pdf / (Float.max(EPS, spec.spot) * safeVol(spec.volatility) * sqrtT);
    let vega = spec.spot * discQ * pdf * sqrtT;
    let theta = switch (kind) {
      case (#call) {
        -(spec.spot * discQ * pdf * spec.volatility) / (2.0 * sqrtT)
        + spec.dividendYield * spec.spot * discQ * normalCdf(d1)
        - spec.rate * spec.strike * discR * normalCdf(d2)
      };
      case (#put) {
        -(spec.spot * discQ * pdf * spec.volatility) / (2.0 * sqrtT)
        - spec.dividendYield * spec.spot * discQ * normalCdf(-d1)
        + spec.rate * spec.strike * discR * normalCdf(-d2)
      };
    };
    let rho = switch (kind) {
      case (#call) { spec.strike * spec.maturity * discR * normalCdf(d2) };
      case (#put) { -spec.strike * spec.maturity * discR * normalCdf(-d2) };
    };
    { delta = delta; gamma = gamma; vega = vega; theta = theta; rho = rho }
  };

  public func computeGreeks(spec : VanillaOptionSpec, kind : OptionKind) : Greeks {
    computeGreeksInternal(spec, kind)
  };

  public func priceBlackScholes(spec : VanillaOptionSpec, kind : OptionKind) : VanillaOptionResult {
    let forward = spec.spot * Float.exp((spec.rate - spec.dividendYield) * spec.maturity);
    if (spec.maturity <= EPS or spec.volatility <= EPS) {
      let price = discount(spec.rate, spec.maturity) * intrinsic(kind, forward, spec.strike);
      let iv = intrinsic(kind, spec.spot, spec.strike);
      return {
        price = price;
        intrinsicValue = iv;
        timeValue = price - iv;
        d1 = 0.0;
        d2 = 0.0;
        greeks = computeGreeksInternal(spec, kind);
      };
    };
    let d1 = blackScholesD1(spec);
    let d2 = blackScholesD2(spec);
    let discQ = discount(spec.dividendYield, spec.maturity);
    let discR = discount(spec.rate, spec.maturity);
    let price = switch (kind) {
      case (#call) { spec.spot * discQ * normalCdf(d1) - spec.strike * discR * normalCdf(d2) };
      case (#put) { spec.strike * discR * normalCdf(-d2) - spec.spot * discQ * normalCdf(-d1) };
    };
    let iv = intrinsic(kind, spec.spot, spec.strike);
    {
      price = price;
      intrinsicValue = iv;
      timeValue = price - iv;
      d1 = d1;
      d2 = d2;
      greeks = computeGreeksInternal(spec, kind);
    }
  };

  public func priceBlack76(spec : Black76Spec, kind : OptionKind) : VanillaOptionResult {
    if (spec.maturity <= EPS or spec.volatility <= EPS) {
      let price = discount(spec.rate, spec.maturity) * intrinsic(kind, spec.forward, spec.strike);
      return {
        price = price;
        intrinsicValue = intrinsic(kind, spec.forward, spec.strike);
        timeValue = 0.0;
        d1 = 0.0;
        d2 = 0.0;
        greeks = { delta = 0.0; gamma = 0.0; vega = 0.0; theta = 0.0; rho = 0.0 };
      };
    };
    let d1 = black76D1(spec);
    let d2 = black76D2(spec);
    let discR = discount(spec.rate, spec.maturity);
    let price = switch (kind) {
      case (#call) { discR * (spec.forward * normalCdf(d1) - spec.strike * normalCdf(d2)) };
      case (#put) { discR * (spec.strike * normalCdf(-d2) - spec.forward * normalCdf(-d1)) };
    };
    let delta = switch (kind) {
      case (#call) { discR * normalCdf(d1) };
      case (#put) { discR * (normalCdf(d1) - 1.0) };
    };
    let gamma = discR * normalPdf(d1) / (Float.max(EPS, spec.forward) * safeVol(spec.volatility) * Float.sqrt(spec.maturity));
    let vega = discR * spec.forward * normalPdf(d1) * Float.sqrt(spec.maturity);
    let theta = -vega * spec.volatility / (2.0 * Float.max(EPS, spec.maturity)) - spec.rate * price;
    let rho = -spec.maturity * price;
    {
      price = price;
      intrinsicValue = intrinsic(kind, spec.forward, spec.strike);
      timeValue = price - intrinsic(kind, spec.forward, spec.strike);
      d1 = d1;
      d2 = d2;
      greeks = { delta = delta; gamma = gamma; vega = vega; theta = theta; rho = rho };
    }
  };

  func simulatePath(spec : VanillaOptionSpec, steps : Nat, pathIndex : Nat, antithetic : Bool) : [Float] {
    let n = natMax(steps, 1);
    let dt = spec.maturity / n.toFloat();
    let drift = (spec.rate - spec.dividendYield - 0.5 * sq(spec.volatility)) * dt;
    let diffusion = spec.volatility * Float.sqrt(dt);
    let path = Array.tabulate<Float>(n + 1, func(_i) { 0.0 }).toVarArray();
    path[0] := spec.spot;
    var step : Nat = 1;
    while (step <= n) {
      let z = quasiNormal(pathIndex, step, antithetic);
      path[step] := Float.max(EPS, path[step - 1] * Float.exp(drift + diffusion * z));
      step += 1;
    };
    Array.tabulate<Float>(n + 1, func(i) { path[i] })
  };

  func det3(
    a11 : Float, a12 : Float, a13 : Float,
    a21 : Float, a22 : Float, a23 : Float,
    a31 : Float, a32 : Float, a33 : Float,
  ) : Float {
    a11 * (a22 * a33 - a23 * a32)
    - a12 * (a21 * a33 - a23 * a31)
    + a13 * (a21 * a32 - a22 * a31)
  };

  func quadraticRegression(xs : [Float], ys : [Float]) : (Float, Float, Float) {
    if (xs.size() == 0 or ys.size() == 0) {
      return (0.0, 0.0, 0.0);
    };
    let n = xs.size().toFloat();
    let s1 = Array.foldLeft<Float, Float>(xs, 0.0, func(acc, x) { acc + x });
    let s2 = Array.foldLeft<Float, Float>(xs, 0.0, func(acc, x) { acc + x * x });
    let s3 = Array.foldLeft<Float, Float>(xs, 0.0, func(acc, x) { acc + x * x * x });
    let s4 = Array.foldLeft<Float, Float>(xs, 0.0, func(acc, x) { acc + x * x * x * x });
    let sy = Array.foldLeft<Float, Float>(ys, 0.0, func(acc, y) { acc + y });
    var sxy = 0.0;
    var sx2y = 0.0;
    var i : Nat = 0;
    while (i < natMin(xs.size(), ys.size())) {
      sxy += xs[i] * ys[i];
      sx2y += xs[i] * xs[i] * ys[i];
      i += 1;
    };
    let det = det3(n, s1, s2, s1, s2, s3, s2, s3, s4);
    if (Float.abs(det) < EPS) {
      return (sy / n, 0.0, 0.0);
    };
    let b0 = det3(sy, s1, s2, sxy, s2, s3, sx2y, s3, s4) / det;
    let b1 = det3(n, sy, s2, s1, sxy, s3, s2, sx2y, s4) / det;
    let b2 = det3(n, s1, sy, s1, s2, sxy, s2, s3, sx2y) / det;
    (b0, b1, b2)
  };

  public func priceAmericanBinomial(spec : VanillaOptionSpec, kind : OptionKind, steps : Nat) : AmericanOptionResult {
    let n = natMax(steps, 1);
    let dt = spec.maturity / n.toFloat();
    let u = Float.exp(spec.volatility * Float.sqrt(dt));
    let d = 1.0 / Float.max(EPS, u);
    let growth = Float.exp((spec.rate - spec.dividendYield) * dt);
    let p = Float.min(1.0, Float.max(0.0, (growth - d) / Float.max(EPS, u - d)));
    let disc = Float.exp(-spec.rate * dt);
    let values = Array.tabulate<Float>(n + 1, func(_i) { 0.0 }).toVarArray();
    var j : Nat = 0;
    while (j <= n) {
      let downSteps = safeNatSub(n, j);
      let s = spec.spot * Float.pow(u, j.toFloat()) * Float.pow(d, downSteps.toFloat());
      values[j] := intrinsic(kind, s, spec.strike);
      j += 1;
    };
    var i = n;
    while (i > 0) {
      i -= 1;
      let step = i;
      var k : Nat = 0;
      while (k <= step) {
        let continuation = disc * (p * values[k + 1] + (1.0 - p) * values[k]);
        let downSteps = safeNatSub(step, k);
        let s = spec.spot * Float.pow(u, k.toFloat()) * Float.pow(d, downSteps.toFloat());
        let exercise = intrinsic(kind, s, spec.strike);
        values[k] := Float.max(exercise, continuation);
        k += 1;
      };
    };
    let euro = priceBlackScholes(spec, kind).price;
    {
      price = values[0];
      intrinsicValue = intrinsic(kind, spec.spot, spec.strike);
      earlyExercisePremium = values[0] - euro;
      standardError = 0.0;
    }
  };

  public func priceAmericanLongstaffSchwartz(spec : VanillaOptionSpec, kind : OptionKind, config : MonteCarloConfig) : AmericanOptionResult {
    let pathsCount = natMax(config.paths, 16);
    let steps = natMax(config.timeSteps, 8);
    let dt = spec.maturity / steps.toFloat();
    let simulatedPaths = Array.tabulate<[Float]>(pathsCount, func(i) {
      simulatePath(spec, steps, i, config.antithetic)
    });
    let cashflows = Array.tabulate<Float>(pathsCount, func(i) {
      intrinsic(kind, simulatedPaths[i][steps], spec.strike)
    }).toVarArray();
    let exerciseIndex : [var Nat] = Array.tabulate<Nat>(pathsCount, func(_i) { steps }).toVarArray();
    var step = steps;
    while (step > 1) {
      step -= 1;
      let timeIndex = step;
      let xTmp = Array.tabulate<Float>(pathsCount, func(_i) { 0.0 }).toVarArray();
      let yTmp = Array.tabulate<Float>(pathsCount, func(_i) { 0.0 }).toVarArray();
      var fitCount : Nat = 0;
      var p : Nat = 0;
      while (p < pathsCount) {
        let s = simulatedPaths[p][timeIndex];
        let exercise = intrinsic(kind, s, spec.strike);
        if (exercise > 0.0 and exerciseIndex[p] > timeIndex) {
          xTmp[fitCount] := s;
          let futureSteps = safeNatSub(exerciseIndex[p], timeIndex);
          let futureDt = futureSteps.toFloat() * dt;
          yTmp[fitCount] := cashflows[p] * Float.exp(-spec.rate * futureDt);
          fitCount += 1;
        };
        p += 1;
      };
      if (fitCount > 2) {
        let xs = Array.tabulate<Float>(fitCount, func(i) { xTmp[i] });
        let ys = Array.tabulate<Float>(fitCount, func(i) { yTmp[i] });
        let (b0, b1, b2) = quadraticRegression(xs, ys);
        var q : Nat = 0;
        while (q < pathsCount) {
          if (exerciseIndex[q] > timeIndex) {
            let s = simulatedPaths[q][timeIndex];
            let exercise = intrinsic(kind, s, spec.strike);
            if (exercise > 0.0) {
              let continuation = b0 + b1 * s + b2 * s * s;
              if (exercise >= continuation) {
                cashflows[q] := exercise;
                exerciseIndex[q] := timeIndex;
              };
            };
          };
          q += 1;
        };
      };
    };
    let discounted = Array.tabulate<Float>(pathsCount, func(i) {
      cashflows[i] * Float.exp(-spec.rate * exerciseIndex[i].toFloat() * dt)
    });
    let mc = makeMcResult(discounted);
    let euro = priceBlackScholes(spec, kind).price;
    {
      price = mc.price;
      intrinsicValue = intrinsic(kind, spec.spot, spec.strike);
      earlyExercisePremium = mc.price - euro;
      standardError = mc.standardError;
    }
  };

  public func priceAsianOption(spec : AsianOptionSpec, kind : OptionKind, config : MonteCarloConfig) : MonteCarloResult {
    let steps = natMax(spec.averagingSteps, natMax(config.timeSteps, 8));
    let discounted = Array.tabulate<Float>(natMax(config.paths, 32), func(i) {
      let path = simulatePath(spec.vanilla, steps, i, config.antithetic);
      var sum = 0.0;
      var logSum = 0.0;
      var k : Nat = 1;
      while (k < path.size()) {
        sum += path[k];
        logSum += Float.log(Float.max(EPS, path[k]));
        k += 1;
      };
      let observations = Float.max(1.0, path.size().toFloat() - 1.0);
      let average = switch (spec.averagingType) {
        case (#arithmetic) { sum / observations };
        case (#geometric) { Float.exp(logSum / observations) };
      };
      discount(spec.vanilla.rate, spec.vanilla.maturity) * intrinsic(kind, average, spec.vanilla.strike)
    });
    makeMcResult(discounted)
  };

  func barrierTriggered(path : [Float], barrier : Float, barrierType : BarrierType) : Bool {
    switch (barrierType) {
      case (#upAndIn) {
        Array.foldLeft<Float, Bool>(path, false, func(hit, s) { hit or s >= barrier })
      };
      case (#upAndOut) {
        Array.foldLeft<Float, Bool>(path, false, func(hit, s) { hit or s >= barrier })
      };
      case (#downAndIn) {
        Array.foldLeft<Float, Bool>(path, false, func(hit, s) { hit or s <= barrier })
      };
      case (#downAndOut) {
        Array.foldLeft<Float, Bool>(path, false, func(hit, s) { hit or s <= barrier })
      };
    }
  };

  public func priceBarrierOption(spec : BarrierOptionSpec, kind : OptionKind, config : MonteCarloConfig) : MonteCarloResult {
    let steps = natMax(spec.monitoringSteps, natMax(config.timeSteps, 16));
    let discounted = Array.tabulate<Float>(natMax(config.paths, 64), func(i) {
      let path = simulatePath(spec.vanilla, steps, i, config.antithetic);
      let terminal = path[path.size() - 1];
      let hit = barrierTriggered(path, spec.barrier, spec.barrierType);
      let payoff = switch (spec.barrierType) {
        case (#upAndIn) { if (hit) intrinsic(kind, terminal, spec.vanilla.strike) else spec.rebate };
        case (#downAndIn) { if (hit) intrinsic(kind, terminal, spec.vanilla.strike) else spec.rebate };
        case (#upAndOut) { if (hit) spec.rebate else intrinsic(kind, terminal, spec.vanilla.strike) };
        case (#downAndOut) { if (hit) spec.rebate else intrinsic(kind, terminal, spec.vanilla.strike) };
      };
      discount(spec.vanilla.rate, spec.vanilla.maturity) * payoff
    });
    makeMcResult(discounted)
  };

  public func priceBinaryOption(spec : BinaryOptionSpec, kind : OptionKind) : VanillaOptionResult {
    let d1 = blackScholesD1(spec.vanilla);
    let d2 = blackScholesD2(spec.vanilla);
    let discQ = discount(spec.vanilla.dividendYield, spec.vanilla.maturity);
    let discR = discount(spec.vanilla.rate, spec.vanilla.maturity);
    let price = switch (spec.payoffType, kind) {
      case (#cash, #call) { spec.cashPayoff * discR * normalCdf(d2) };
      case (#cash, #put) { spec.cashPayoff * discR * normalCdf(-d2) };
      case (#asset, #call) { spec.vanilla.spot * discQ * normalCdf(d1) };
      case (#asset, #put) { spec.vanilla.spot * discQ * normalCdf(-d1) };
    };
    {
      price = price;
      intrinsicValue = 0.0;
      timeValue = price;
      d1 = d1;
      d2 = d2;
      greeks = { delta = 0.0; gamma = 0.0; vega = 0.0; theta = 0.0; rho = 0.0 };
    }
  };

  public func priceLookbackOption(spec : LookbackOptionSpec, kind : OptionKind, config : MonteCarloConfig) : MonteCarloResult {
    let steps = natMax(spec.lookbackSteps, natMax(config.timeSteps, 16));
    let discounted = Array.tabulate<Float>(natMax(config.paths, 64), func(i) {
      let path = simulatePath(spec.vanilla, steps, i, config.antithetic);
      let terminal = path[path.size() - 1];
      let runningMin = Array.foldLeft<Float, Float>(path, path[0], func(acc, s) { Float.min(acc, s) });
      let runningMax = Array.foldLeft<Float, Float>(path, path[0], func(acc, s) { Float.max(acc, s) });
      let payoff = switch (spec.style, kind) {
        case (#fixedStrike, #call) { max0(runningMax - spec.vanilla.strike) };
        case (#fixedStrike, #put) { max0(spec.vanilla.strike - runningMin) };
        case (#floatingStrike, #call) { max0(terminal - runningMin) };
        case (#floatingStrike, #put) { max0(runningMax - terminal) };
      };
      discount(spec.vanilla.rate, spec.vanilla.maturity) * payoff
    });
    makeMcResult(discounted)
  };

  public func priceCliquetOption(spec : CliquetOptionSpec, config : MonteCarloConfig) : MonteCarloResult {
    let steps = natMax(spec.resetCount, natMax(config.timeSteps, 12));
    let vanilla : VanillaOptionSpec = {
      spot = spec.spot;
      strike = spec.spot;
      rate = spec.rate;
      dividendYield = spec.dividendYield;
      volatility = spec.volatility;
      maturity = spec.maturity;
    };
    let discounted = Array.tabulate<Float>(natMax(config.paths, 64), func(i) {
      let path = simulatePath(vanilla, steps, i, config.antithetic);
      var accumulator = 0.0;
      var k : Nat = 1;
      while (k < path.size()) {
        let localReturn = path[k] / Float.max(EPS, path[k - 1]) - 1.0;
        accumulator += Float.min(spec.localCap, Float.max(spec.localFloor, localReturn));
        k += 1;
      };
      let cliquetReturn = Float.min(spec.globalCap, Float.max(spec.globalFloor, accumulator));
      discount(spec.rate, spec.maturity) * spec.notional * max0(cliquetReturn)
    });
    makeMcResult(discounted)
  };

  func cholesky(correlation : [[Float]]) : [[Float]] {
    let n = correlation.size();
    let lower = Array.tabulate<Float>(n * n, func(_i) { 0.0 }).toVarArray();
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j <= i) {
        var sum = correlation[i][j];
        var k : Nat = 0;
        while (k < j) {
          sum -= lower[i * n + k] * lower[j * n + k];
          k += 1;
        };
        if (i == j) {
          lower[i * n + j] := Float.sqrt(Float.max(EPS, sum));
        } else {
          lower[i * n + j] := sum / Float.max(EPS, lower[j * n + j]);
        };
        j += 1;
      };
      i += 1;
    };
    Array.tabulate<[Float]>(n, func(r) {
      Array.tabulate<Float>(n, func(c) { lower[r * n + c] })
    })
  };

  func correlatedTerminalPrices(market : MultiAssetSpec, pathIndex : Nat, antithetic : Bool) : [Float] {
    let n = market.spots.size();
    let lower = cholesky(market.correlation);
    let indep = Array.tabulate<Float>(n, func(i) { quasiNormal(pathIndex, i + 1, antithetic) });
    let corr = Array.tabulate<Float>(n, func(i) {
      var sum = 0.0;
      var j : Nat = 0;
      while (j <= i) {
        sum += lower[i][j] * indep[j];
        j += 1;
      };
      sum
    });
    Array.tabulate<Float>(n, func(i) {
      let drift = market.rate - market.dividendYields[i] - 0.5 * sq(market.volatilities[i]);
      market.spots[i] * Float.exp(drift * market.maturity + market.volatilities[i] * Float.sqrt(market.maturity) * corr[i])
    })
  };

  public func priceRainbowOption(spec : RainbowOptionSpec, config : MonteCarloConfig) : MonteCarloResult {
    let discounted = Array.tabulate<Float>(natMax(config.paths, 128), func(i) {
      let terminals = correlatedTerminalPrices(spec.market, i, config.antithetic);
      let best = Array.foldLeft<Float, Float>(terminals, terminals[0], func(acc, x) { Float.max(acc, x) });
      let worst = Array.foldLeft<Float, Float>(terminals, terminals[0], func(acc, x) { Float.min(acc, x) });
      let payoff = switch (spec.payoffType) {
        case (#bestOfCall) { max0(best - spec.strike) };
        case (#worstOfCall) { max0(worst - spec.strike) };
        case (#bestOfPut) { max0(spec.strike - best) };
        case (#worstOfPut) { max0(spec.strike - worst) };
      };
      discount(spec.market.rate, spec.market.maturity) * payoff
    });
    makeMcResult(discounted)
  };

  public func priceBasketOption(spec : BasketOptionSpec, config : MonteCarloConfig) : MonteCarloResult {
    let discounted = Array.tabulate<Float>(natMax(config.paths, 128), func(i) {
      let terminals = correlatedTerminalPrices(spec.market, i, config.antithetic);
      var basket = 0.0;
      var k : Nat = 0;
      while (k < natMin(terminals.size(), spec.weights.size())) {
        basket += spec.weights[k] * terminals[k];
        k += 1;
      };
      discount(spec.market.rate, spec.market.maturity) * intrinsic(spec.kind, basket, spec.strike)
    });
    makeMcResult(discounted)
  };

  public func priceSpreadOption(spec : SpreadOptionSpec, config : MonteCarloConfig) : MonteCarloResult {
    let market : MultiAssetSpec = {
      spots = [spec.spot1, spec.spot2];
      volatilities = [spec.vol1, spec.vol2];
      dividendYields = [spec.dividendYield1, spec.dividendYield2];
      correlation = [[1.0, spec.correlation], [spec.correlation, 1.0]];
      rate = spec.rate;
      maturity = spec.maturity;
    };
    let discounted = Array.tabulate<Float>(natMax(config.paths, 128), func(i) {
      let terminals = correlatedTerminalPrices(market, i, config.antithetic);
      let spread = terminals[0] - terminals[1];
      discount(spec.rate, spec.maturity) * intrinsic(spec.kind, spread, spec.strike)
    });
    makeMcResult(discounted)
  };

  public func priceZeroCouponBond(spec : ZeroCouponBondSpec) : BondPriceResult {
    let price = spec.face * discount(spec.yieldRate, spec.maturity);
    {
      price = price;
      macaulayDuration = spec.maturity;
      modifiedDuration = spec.maturity / (1.0 + spec.yieldRate);
    }
  };

  public func priceCouponBond(spec : CouponBondSpec) : BondPriceResult {
    let freq = natMax(spec.paymentsPerYear, 1).toFloat();
    let coupon = spec.face * spec.couponRate / freq;
    let periods = ceilNat(spec.maturity * freq);
    var price = 0.0;
    var weightedTime = 0.0;
    var i : Nat = 1;
    while (i <= periods) {
      let t = Float.min(spec.maturity, i.toFloat() / freq);
      let cf = if (i == periods) coupon + spec.face else coupon;
      let pv = cf * discount(spec.yieldRate, t);
      price += pv;
      weightedTime += t * pv;
      i += 1;
    };
    let macaulay = if (price > EPS) weightedTime / price else 0.0;
    {
      price = price;
      macaulayDuration = macaulay;
      modifiedDuration = macaulay / (1.0 + spec.yieldRate / freq);
    }
  };

  func instrumentMaturity(inst : CurveInstrument) : Float {
    switch (inst) {
      case (#deposit(dep)) dep.maturity;
      case (#couponBond(bond)) bond.maturity;
    }
  };

  func interpolateDiscount(points : [ZeroCurvePoint], maturity : Float) : Float {
    if (points.size() == 0) return 1.0;
    if (maturity <= points[0].maturity) {
      return discount(points[0].zeroRate, maturity);
    };
    var i : Nat = 1;
    while (i < points.size()) {
      if (maturity <= points[i].maturity) {
        let left = points[i - 1];
        let right = points[i];
        let w = (maturity - left.maturity) / Float.max(EPS, right.maturity - left.maturity);
        let zeroRate = left.zeroRate + w * (right.zeroRate - left.zeroRate);
        return discount(zeroRate, maturity);
      };
      i += 1;
    };
    discount(points[points.size() - 1].zeroRate, maturity)
  };

  public func bootstrapYieldCurve(instruments : [CurveInstrument]) : YieldCurveResult {
    let sorted = Array.sort<CurveInstrument>(instruments, func(a, b) {
      if (instrumentMaturity(a) < instrumentMaturity(b)) #less
      else if (instrumentMaturity(a) > instrumentMaturity(b)) #greater
      else #equal
    });
    var points : [ZeroCurvePoint] = [];
    var maxError = 0.0;
    for (inst in sorted.vals()) {
      switch (inst) {
        case (#deposit(dep)) {
          let df = 1.0 / (1.0 + dep.simpleRate * dep.maturity);
          let zero = -Float.log(Float.max(EPS, df)) / safeTime(dep.maturity);
          points := points.concat([{ maturity = dep.maturity; discountFactor = df; zeroRate = zero }]);
        };
        case (#couponBond(bond)) {
          let freq = natMax(bond.paymentsPerYear, 1).toFloat();
          let coupon = bond.face * bond.couponRate / freq;
          let periods = ceilNat(bond.maturity * freq);
          var pvCoupons = 0.0;
          var i : Nat = 1;
          while (i < periods) {
            let t = i.toFloat() / freq;
            pvCoupons += coupon * interpolateDiscount(points, t);
            i += 1;
          };
          let finalDf = Float.max(EPS, (bond.price - pvCoupons) / Float.max(EPS, bond.face + coupon));
          let zero = -Float.log(finalDf) / safeTime(bond.maturity);
          points := points.concat([{ maturity = bond.maturity; discountFactor = finalDf; zeroRate = zero }]);
          let repriced = pvCoupons + (bond.face + coupon) * finalDf;
          maxError := Float.max(maxError, Float.abs(repriced - bond.price));
        };
      };
    };
    { points = points; bootstrapError = maxError }
  };

  public func priceFRA(spec : FRASpec) : FRAResult {
    let tau = Float.max(EPS, spec.end_ - spec.start);
    let df = discount(spec.discountRate, spec.end_);
    let settlement = spec.notional * (spec.forwardRate - spec.strikeRate) * tau / (1.0 + spec.forwardRate * tau);
    {
      value = df * settlement;
      forwardDiscountFactor = df;
      settlementAmount = settlement;
    }
  };

  public func priceInterestRateSwap(spec : SwapSpec) : SwapResult {
    let n = natMin(spec.schedule.paymentTimes.size(), natMin(spec.schedule.accrualFractions.size(), natMin(spec.schedule.forwardRates.size(), spec.schedule.discountFactors.size())));
    var fixedLeg = 0.0;
    var floatingLeg = 0.0;
    var annuity = 0.0;
    var i : Nat = 0;
    while (i < n) {
      let tau = spec.schedule.accrualFractions[i];
      let df = spec.schedule.discountFactors[i];
      fixedLeg += spec.notional * spec.fixedRate * tau * df;
      floatingLeg += spec.notional * spec.schedule.forwardRates[i] * tau * df;
      annuity += tau * df;
      i += 1;
    };
    let parRate = if (annuity > EPS) floatingLeg / (spec.notional * annuity) else 0.0;
    let npv = if (spec.payFixed) floatingLeg - fixedLeg else fixedLeg - floatingLeg;
    {
      fixedLegPV = fixedLeg;
      floatingLegPV = floatingLeg;
      parRate = parRate;
      netPresentValue = npv;
    }
  };

  public func priceCapFloor(spec : CapFloorSpec) : CapFloorResult {
    let n = natMin(spec.forwardRates.size(), natMin(spec.volatilities.size(), natMin(spec.accrualFractions.size(), natMin(spec.paymentTimes.size(), spec.discountFactors.size()))));
    let prices = Array.tabulate<Float>(n, func(i) {
      let unit = priceBlack76({
        forward = spec.forwardRates[i];
        strike = spec.strike;
        rate = 0.0;
        volatility = spec.volatilities[i];
        maturity = spec.paymentTimes[i];
      }, switch (spec.kind) { case (#cap) #call; case (#floor) #put }).price;
      spec.notional * spec.accrualFractions[i] * spec.discountFactors[i] * unit
    });
    let total = Array.foldLeft<Float, Float>(prices, 0.0, func(acc, x) { acc + x });
    var numer = 0.0;
    var denom = 0.0;
    var i : Nat = 0;
    while (i < n) {
      numer += spec.forwardRates[i] * spec.accrualFractions[i] * spec.discountFactors[i];
      denom += spec.accrualFractions[i] * spec.discountFactors[i];
      i += 1;
    };
    {
      price = total;
      capletPrices = prices;
      fairRate = if (denom > EPS) numer / denom else 0.0;
    }
  };

  public func priceSwaption(spec : SwaptionSpec) : SwaptionResult {
    let kind = switch (spec.kind) { case (#payer) #call; case (#receiver) #put };
    let black = priceBlack76({
      forward = spec.forwardSwapRate;
      strike = spec.strike;
      rate = spec.rate;
      volatility = spec.volatility;
      maturity = spec.expiry;
    }, kind);
    {
      price = spec.notional * spec.annuity * black.price;
      intrinsicValue = spec.notional * spec.annuity * intrinsic(kind, spec.forwardSwapRate, spec.strike);
    }
  };

  func realizedVariance(logReturns : [Float], annualizationFactor : Float) : Float {
    if (logReturns.size() == 0) return 0.0;
    let sumSq = Array.foldLeft<Float, Float>(logReturns, 0.0, func(acc, r) { acc + r * r });
    annualizationFactor * sumSq / logReturns.size().toFloat()
  };

  public func priceVarianceSwap(spec : VarianceSwapSpec) : VarianceSwapResult {
    let fairVariance = realizedVariance(spec.logReturns, spec.annualizationFactor);
    {
      fairVariance = fairVariance;
      price = discount(spec.rate, spec.maturity) * spec.notional * (fairVariance - spec.strikeVariance);
    }
  };

  public func priceVolatilitySwap(spec : VolatilitySwapSpec) : VolatilitySwapResult {
    let fairVol = Float.sqrt(Float.max(0.0, spec.realizedVariance));
    let convexityAdjustment = if (fairVol > EPS) spec.volOfVol * spec.volOfVol * spec.maturity / (8.0 * fairVol) else 0.0;
    let adjustedVol = fairVol - convexityAdjustment;
    {
      fairVolatility = adjustedVol;
      convexityAdjustment = convexityAdjustment;
      price = discount(spec.rate, spec.maturity) * spec.notional * (adjustedVol - spec.strikeVolatility);
    }
  };

  public func computeVixStyleIndex(spec : VixSpec) : VixResult {
    let n = spec.optionStrip.size();
    if (n == 0) return { variance = 0.0; vix = 0.0 };
    let sorted = Array.sort<VixOptionQuote>(spec.optionStrip, func(a, b) {
      if (a.strike < b.strike) #less else if (a.strike > b.strike) #greater else #equal
    });
    var k0Index : Nat = 0;
    var i : Nat = 0;
    while (i < n) {
      if (sorted[i].strike <= spec.forward) { k0Index := i };
      i += 1;
    };
    let k0 = sorted[k0Index].strike;
    var integral = 0.0;
    var j : Nat = 0;
    while (j < n) {
      let left = if (j == 0) { sorted[j].strike } else { sorted[j - 1].strike };
      let right = if (j + 1 >= n) { sorted[j].strike } else { sorted[j + 1].strike };
      let deltaK = if (j == 0 and n > 1) {
        sorted[1].strike - sorted[0].strike
      } else if (j + 1 == n and n > 1) {
        sorted[n - 1].strike - sorted[n - 2].strike
      } else if (n > 2) {
        (right - left) / 2.0
      } else {
        Float.max(EPS, right - left)
      };
      let quote = if (sorted[j].strike < k0) {
        sorted[j].putPrice
      } else if (sorted[j].strike > k0) {
        sorted[j].callPrice
      } else {
        0.5 * (sorted[j].callPrice + sorted[j].putPrice)
      };
      integral += deltaK * quote / Float.max(EPS, sq(sorted[j].strike));
      j += 1;
    };
    let variance = Float.max(0.0, (2.0 * Float.exp(spec.rate * spec.maturity) * integral) / safeTime(spec.maturity) - sq(spec.forward / Float.max(EPS, k0) - 1.0) / safeTime(spec.maturity));
    { variance = variance; vix = 100.0 * Float.sqrt(variance) }
  };

  public func constructVolatilitySurface(request : VolSurfaceRequest) : VolSurfaceResult {
    let nodes = Array.tabulate<VolSurfaceNode>(request.maturities.size() * request.strikes.size(), func(index) {
      let strikeCount = natMax(request.strikes.size(), 1);
      let mIndex = index / strikeCount;
      let kIndex = index % strikeCount;
      let targetMaturity = request.maturities[mIndex];
      let targetStrike = request.strikes[kIndex];
      var weightedVol = 0.0;
      var totalWeight = 0.0;
      for (quote in request.quotes.vals()) {
        let dm = (quote.maturity - targetMaturity) / Float.max(0.25, targetMaturity);
        let dk = (quote.strike - targetStrike) / Float.max(1.0, targetStrike);
        let w = 1.0 / Float.max(EPS, dm * dm + dk * dk);
        weightedVol += w * quote.impliedVol;
        totalWeight += w;
      };
      {
        maturity = targetMaturity;
        strike = targetStrike;
        impliedVol = if (totalWeight > EPS) weightedVol / totalWeight else 0.0;
      }
    });
    { nodes = nodes }
  };

  public func estimateDefaultProbability(spec : MertonSpec) : Float {
    let sigmaT = safeVol(spec.assetVolatility) * Float.sqrt(safeTime(spec.maturity));
    let d2 = (Float.log(Float.max(EPS, spec.assetValue) / Float.max(EPS, spec.debtFace)) + (spec.rate - 0.5 * sq(spec.assetVolatility)) * safeTime(spec.maturity)) / sigmaT;
    normalCdf(-d2)
  };

  public func computeCreditSpread(spec : MertonSpec) : Float {
    priceMertonDebt(spec).creditSpread
  };

  public func priceMertonDebt(spec : MertonSpec) : MertonResult {
    let sigmaT = safeVol(spec.assetVolatility) * Float.sqrt(safeTime(spec.maturity));
    let d1 = (Float.log(Float.max(EPS, spec.assetValue) / Float.max(EPS, spec.debtFace)) + (spec.rate + 0.5 * sq(spec.assetVolatility)) * safeTime(spec.maturity)) / sigmaT;
    let d2 = d1 - sigmaT;
    let equity = spec.assetValue * normalCdf(d1) - spec.debtFace * discount(spec.rate, spec.maturity) * normalCdf(d2);
    let debt = spec.assetValue - equity;
    let pd = normalCdf(-d2);
    let spread = Float.max(0.0, -Float.log(Float.max(EPS, debt) / Float.max(EPS, spec.debtFace)) / safeTime(spec.maturity) - spec.rate);
    {
      equityValue = equity;
      riskyDebtValue = debt;
      defaultProbability = pd;
      distanceToDefault = d2;
      creditSpread = spread;
    }
  };

  public func priceCDSMerton(spec : CDSSpec) : CDSResult {
    let merton = priceMertonDebt(spec.merton);
    let hazard = -Float.log(Float.max(EPS, 1.0 - merton.defaultProbability)) / safeTime(spec.merton.maturity);
    let recovery = Float.min(1.0, Float.max(0.0, spec.merton.recoveryRate));
    let lgd = 1.0 - recovery;
    let freq = natMax(spec.paymentsPerYear, 1).toFloat();
    let periods = ceilNat(spec.merton.maturity * freq);
    var premiumAnnuity = 0.0;
    var protectionLeg = 0.0;
    var i : Nat = 1;
    while (i <= periods) {
      let t = Float.min(spec.merton.maturity, i.toFloat() / freq);
      let dt = 1.0 / freq;
      let survival = Float.exp(-hazard * t);
      let df = discount(spec.merton.rate, t);
      premiumAnnuity += df * survival * dt;
      let defaultWindow = Float.exp(-hazard * Float.max(0.0, t - dt)) - survival;
      protectionLeg += df * defaultWindow;
      i += 1;
    };
    protectionLeg *= spec.notional * lgd;
    let fairSpread = if (premiumAnnuity > EPS) protectionLeg / (spec.notional * premiumAnnuity) else 0.0;
    let premiumLeg = spec.notional * spec.marketSpread * premiumAnnuity;
    {
      fairSpread = fairSpread;
      markToMarket = protectionLeg - premiumLeg;
      protectionLeg = protectionLeg;
      premiumLeg = premiumLeg;
      defaultProbability = merton.defaultProbability;
    }
  };
}
