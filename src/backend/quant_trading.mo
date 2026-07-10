import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Phi "phi";
import PhantomExchange "phantom_exchange";
import PhantomIntelligence "phantom_intelligence";

module {
  let EPS : Float = 0.000000001;
  let PI : Float = 3.141592653589793;
  let SQRT_TWO_PI : Float = 2.5066282746310002;

  public type TradeSignal = { #buy; #sell; #hold };
  public type TickKind = { #trade; #quote; #cancel };
  public type OptionType = { #call; #put };

  public type PriceLevel = {
    price : Float;
    size : Float;
    orderCount : Nat;
  };

  public type OrderFlowEvent = {
    timestampMs : Int;
    side : PhantomExchange.OrderSide;
    quantity : Float;
    price : Float;
    aggressorWeight : Float;
  };

  public type OrderFlowImbalance = {
    buyVolume : Float;
    sellVolume : Float;
    netVolume : Float;
    imbalanceRatio : Float;
    toxicity : Float;
    vpinProxy : Float;
  };

  public type MarketImpactEstimate = {
    model : Text;
    referencePrice : Float;
    quantity : Float;
    participationRate : Float;
    temporaryImpact : Float;
    permanentImpact : Float;
    totalImpact : Float;
  };

  public type MarketImpactModels = {
    linear : MarketImpactEstimate;
    squareRoot : MarketImpactEstimate;
    powerLaw : MarketImpactEstimate;
  };

  public type SpreadDecomposition = {
    quotedSpread : Float;
    effectiveSpread : Float;
    realizedSpread : Float;
    adverseSelection : Float;
    inventoryHolding : Float;
    orderProcessing : Float;
  };

  public type KylesLambdaEstimate = {
    lambda : Float;
    intercept : Float;
    rSquared : Float;
    sampleSize : Nat;
  };

  public type MarketMicrostructureSnapshot = {
    pairId : Text;
    bestBid : ?PriceLevel;
    bestAsk : ?PriceLevel;
    midPrice : Float;
    spread : Float;
    spreadBps : Float;
    bidDepth : Float;
    askDepth : Float;
    depthImbalance : Float;
    orderFlow : OrderFlowImbalance;
    marketImpact : MarketImpactModels;
    spreadDecomposition : SpreadDecomposition;
    kylesLambda : KylesLambdaEstimate;
    intelligenceConfidence : Float;
    signalPressure : Float;
  };

  public type CointegrationResult = {
    alpha : Float;
    hedgeRatio : Float;
    adfStatistic : Float;
    meanResidual : Float;
    residualStdDev : Float;
    currentResidual : Float;
    zScore : Float;
    halfLife : Float;
    isCointegrated : Bool;
    confidence : Float;
  };

  public type PairsTradingSignal = {
    signal : TradeSignal;
    zScore : Float;
    entryThreshold : Float;
    exitThreshold : Float;
    targetSpread : Float;
    hedgeRatio : Float;
    conviction : Float;
  };

  public type MeanReversionSignal = {
    signal : TradeSignal;
    mean : Float;
    standardDeviation : Float;
    zScore : Float;
    halfLife : Float;
    expectedReturn : Float;
    conviction : Float;
  };

  public type CorrelationTradingSignal = {
    rollingCorrelation : Float;
    beta : Float;
    relativeValueScore : Float;
    signal : TradeSignal;
    confidence : Float;
  };

  public type KalmanHedgeState = {
    intercept : Float;
    hedgeRatio : Float;
    covariance00 : Float;
    covariance01 : Float;
    covariance10 : Float;
    covariance11 : Float;
    processNoise : Float;
    measurementNoise : Float;
    innovation : Float;
    innovationVariance : Float;
  };

  public type KalmanFilterResult = {
    finalState : KalmanHedgeState;
    hedgeRatios : [Float];
    intercepts : [Float];
    residuals : [Float];
  };

  public type StatisticalArbitrageSnapshot = {
    cointegration : CointegrationResult;
    pairsTrading : PairsTradingSignal;
    meanReversion : MeanReversionSignal;
    correlation : CorrelationTradingSignal;
    kalman : KalmanFilterResult;
  };

  public type GarchEstimate = {
    omega : Float;
    alpha : Float;
    beta : Float;
    persistence : Float;
    longRunVariance : Float;
    oneStepForecast : Float;
    logLikelihood : Float;
    conditionalVariance : [Float];
  };

  public type EgarchEstimate = {
    omega : Float;
    alpha : Float;
    beta : Float;
    gamma : Float;
    leverageEffect : Float;
    oneStepForecast : Float;
    logLikelihood : Float;
    conditionalVariance : [Float];
  };

  public type HestonParameters = {
    kappa : Float;
    theta : Float;
    sigma : Float;
    rho : Float;
    v0 : Float;
  };

  public type RealizedVolatility = {
    sampleCount : Nat;
    realizedVariance : Float;
    realizedVolatility : Float;
    annualizedVolatility : Float;
    bipowerVariation : Float;
    jumpVariation : Float;
  };

  public type OptionQuote = {
    strike : Float;
    maturityYears : Float;
    marketPrice : Float;
    optionType : OptionType;
    openInterest : Float;
  };

  public type ImpliedVolNode = {
    strike : Float;
    maturityYears : Float;
    moneyness : Float;
    impliedVolatility : Float;
    totalVariance : Float;
    openInterest : Float;
  };

  public type ImpliedVolSurface = {
    spot : Float;
    riskFreeRate : Float;
    nodes : [ImpliedVolNode];
    atmVolatility : Float;
    skew : Float;
    termStructureSlope : Float;
  };

  public type VolatilitySnapshot = {
    garch : GarchEstimate;
    egarch : EgarchEstimate;
    heston : HestonParameters;
    realized : RealizedVolatility;
    impliedSurface : ImpliedVolSurface;
  };

  public type ExecutionSlice = {
    slice : Nat;
    targetTimeSeconds : Float;
    quantity : Float;
    participationRate : Float;
    expectedPrice : Float;
  };

  public type TwapSchedule = {
    totalQuantity : Float;
    horizonSeconds : Float;
    slices : [ExecutionSlice];
  };

  public type VwapSchedule = {
    totalQuantity : Float;
    volumeCurve : [Float];
    slices : [ExecutionSlice];
  };

  public type AlmgrenChrissPlan = {
    riskAversion : Float;
    temporaryImpact : Float;
    permanentImpact : Float;
    liquidationHorizonSeconds : Float;
    remainingInventoryPath : [Float];
    childOrders : [ExecutionSlice];
    expectedCost : Float;
    expectedRisk : Float;
  };

  public type ImplementationShortfallPlan = {
    arrivalPrice : Float;
    benchmarkPrice : Float;
    expectedShortfall : Float;
    expectedShortfallBps : Float;
    volatilityRisk : Float;
    urgencyScore : Float;
    optimizedSchedule : [ExecutionSlice];
  };

  public type ExecutionSnapshot = {
    twap : TwapSchedule;
    vwap : VwapSchedule;
    almgrenChriss : AlmgrenChrissPlan;
    shortfall : ImplementationShortfallPlan;
  };

  public type TickData = {
    timestampMs : Int;
    bid : Float;
    ask : Float;
    last : Float;
    volume : Float;
    side : TradeSignal;
    venueLatencyMs : Float;
    referencePrice : Float;
    messageType : TickKind;
  };

  public type TickAnalytics = {
    tickCount : Nat;
    tradeCount : Nat;
    quoteCount : Nat;
    cancelCount : Nat;
    averageSpreadBps : Float;
    averageInterArrivalMs : Float;
    microPriceTrend : Float;
    orderFlowToxicity : Float;
    realizedVolatility : Float;
  };

  public type LatencyArbitrageAlert = {
    detected : Bool;
    staleQuoteCount : Nat;
    maxLatencyMs : Float;
    averageEdgeBps : Float;
    confidence : Float;
  };

  public type QuoteStuffingAlert = {
    detected : Bool;
    quoteToTradeRatio : Float;
    cancelRate : Float;
    burstScore : Float;
    confidence : Float;
  };

  public type MomentumIgnitionAlert = {
    detected : Bool;
    direction : TradeSignal;
    aggressiveBurstCount : Nat;
    priceAcceleration : Float;
    reversalScore : Float;
    confidence : Float;
  };

  public type HighFrequencyTradingSnapshot = {
    tickAnalytics : TickAnalytics;
    latencyArbitrage : LatencyArbitrageAlert;
    quoteStuffing : QuoteStuffingAlert;
    momentumIgnition : MomentumIgnitionAlert;
  };

  public type IntegratedQuantSnapshot = {
    microstructure : MarketMicrostructureSnapshot;
    statisticalArbitrage : StatisticalArbitrageSnapshot;
    volatility : VolatilitySnapshot;
    execution : ExecutionSnapshot;
    highFrequency : HighFrequencyTradingSnapshot;
  };

  type OlsResult = {
    alpha : Float;
    beta : Float;
    fitted : [Float];
    residuals : [Float];
    rSquared : Float;
  };

  type Ar1Result = {
    intercept : Float;
    phi : Float;
    residualStdDev : Float;
    tStatistic : Float;
  };

  func natToFloat(n : Nat) : Float { n.toInt().toFloat() };

  func clamp(x : Float, lo : Float, hi : Float) : Float {
    if (x < lo) lo else if (x > hi) hi else x
  };

  func samePrice(a : Float, b : Float) : Bool {
    Float.abs(a - b) <= EPS
  };

  func safeDiv(numerator : Float, denominator : Float) : Float {
    if (Float.abs(denominator) <= EPS) 0.0 else numerator / denominator
  };

  func sum(xs : [Float]) : Float {
    var acc = 0.0;
    for (x in xs.vals()) { acc += x };
    acc
  };

  func mean(xs : [Float]) : Float {
    if (xs.size() == 0) 0.0 else sum(xs) / natToFloat(xs.size())
  };

  func variance(xs : [Float]) : Float {
    let n = xs.size();
    if (n < 2) { return 0.0 };
    let mu = mean(xs);
    var acc = 0.0;
    for (x in xs.vals()) {
      let d = x - mu;
      acc += d * d;
    };
    acc / natToFloat(n - 1)
  };

  func stdDev(xs : [Float]) : Float {
    Float.sqrt(Float.max(0.0, variance(xs)))
  };

  func covariance(xs : [Float], ys : [Float]) : Float {
    let n = if (xs.size() < ys.size()) xs.size() else ys.size();
    if (n < 2) { return 0.0 };
    let mx = mean(takeFloats(xs, n));
    let my = mean(takeFloats(ys, n));
    var acc = 0.0;
    var i : Nat = 0;
    while (i < n) {
      acc += (xs[i] - mx) * (ys[i] - my);
      i += 1;
    };
    acc / natToFloat(n - 1)
  };

  func correlation(xs : [Float], ys : [Float]) : Float {
    let denom = stdDev(xs) * stdDev(ys);
    clamp(safeDiv(covariance(xs, ys), denom), -1.0, 1.0)
  };

  func takeFloats(xs : [Float], n : Nat) : [Float] {
    let m = if (n < xs.size()) n else xs.size();
    Array.tabulate<Float>(m, func(i : Nat) : Float { xs[i] })
  };

  func appendOne<T>(xs : [T], item : T) : [T] {
    Array.tabulate<T>(xs.size() + 1, func(i : Nat) : T {
      if (i < xs.size()) xs[i] else item
    })
  };

  func prependOne<T>(item : T, xs : [T]) : [T] {
    Array.tabulate<T>(xs.size() + 1, func(i : Nat) : T {
      if (i == 0) item else xs[i - 1]
    })
  };

  func lastOr(xs : [Float], fallback : Float) : Float {
    if (xs.size() == 0) fallback else xs[xs.size() - 1]
  };

  func replaceLevel(levels : [PriceLevel], idx : Nat, level : PriceLevel) : [PriceLevel] {
    Array.tabulate<PriceLevel>(levels.size(), func(i : Nat) : PriceLevel {
      if (i == idx) level else levels[i]
    })
  };

  func levelPrice(level : ?PriceLevel) : Float {
    switch (level) {
      case null 0.0;
      case (?l) l.price;
    }
  };

  func aggregateLevels(orders : [PhantomExchange.Order], depthLevels : Nat) : [PriceLevel] {
    if (depthLevels == 0) { return [] };
    var levels : [PriceLevel] = [];
    for (order in orders.vals()) {
      if (order.remainingQty > 0.0) {
        let count = levels.size();
        if (count == 0) {
          levels := [{ price = order.price; size = order.remainingQty; orderCount = 1 }];
        } else {
          let last = levels[count - 1];
          if (samePrice(last.price, order.price)) {
            levels := replaceLevel(levels, count - 1, {
              price = last.price;
              size = last.size + order.remainingQty;
              orderCount = last.orderCount + 1;
            });
          } else if (count < depthLevels) {
            levels := appendOne<PriceLevel>(levels, { price = order.price; size = order.remainingQty; orderCount = 1 });
          };
        };
      };
    };
    levels
  };

  func intelligencePressure(state : PhantomIntelligence.PhantomIntelligenceState, pairId : Text) : Float {
    var weighted = 0.0;
    var totalWeight = 0.0;
    for (signal in state.activeSignals.vals()) {
      let signalPair = signal.tokenPair;
      if (Text.contains(signalPair, #text pairId) or Text.contains(pairId, #text signalPair)) {
        let signed = switch (signal.signalType) {
          case (#orderFlowImbalance) { signal.magnitude };
          case (#liquidityShift) { signal.magnitude * 0.5 };
          case (#arbitrageOpportunity) { signal.magnitude * 0.25 };
          case (#priceMovement) { signal.magnitude * 0.2 };
          case (_) { 0.0 };
        };
        weighted += signed * signal.confidence;
        totalWeight += signal.confidence;
      };
    };
    if (totalWeight <= EPS) state.coherenceGate else clamp(weighted / totalWeight, -Phi.PHI, Phi.PHI)
  };

  func filterFillsByPair(fills : [PhantomExchange.Fill], pairId : Text) : [PhantomExchange.Fill] {
    Array.filter<PhantomExchange.Fill>(fills, func(fill : PhantomExchange.Fill) : Bool {
      fill.pairId == pairId
    })
  };

  func fillsToOrderFlowEvents(fills : [PhantomExchange.Fill], referenceMid : Float) : [OrderFlowEvent] {
    if (fills.size() == 0) { return [] };
    Array.tabulate<OrderFlowEvent>(fills.size(), func(i : Nat) : OrderFlowEvent {
      let fill = fills[i];
      let previousPrice = if (i == 0) referenceMid else fills[i - 1].price;
      let inferredSide : PhantomExchange.OrderSide = if (fill.price >= previousPrice) #buy else #sell;
      {
        timestampMs = fill.fillBeat * 873;
        side = inferredSide;
        quantity = fill.quantity;
        price = fill.price;
        aggressorWeight = if (Float.abs(fill.price - previousPrice) <= EPS) 1.0 else 1.25;
      }
    })
  };

  public func calculateOrderFlowImbalance(events : [OrderFlowEvent]) : OrderFlowImbalance {
    var buyVolume = 0.0;
    var sellVolume = 0.0;
    for (event in events.vals()) {
      let weightedQty = event.quantity * event.aggressorWeight;
      switch (event.side) {
        case (#buy) { buyVolume += weightedQty };
        case (#sell) { sellVolume += weightedQty };
      };
    };
    let net = buyVolume - sellVolume;
    let gross = buyVolume + sellVolume;
    let ratio = safeDiv(net, gross);
    {
      buyVolume = buyVolume;
      sellVolume = sellVolume;
      netVolume = net;
      imbalanceRatio = ratio;
      toxicity = Float.abs(ratio);
      vpinProxy = Float.min(1.0, Float.abs(ratio) * 1.2);
    }
  };

  func logReturns(prices : [Float]) : [Float] {
    if (prices.size() < 2) { return [] };
    Array.tabulate<Float>(prices.size() - 1, func(i : Nat) : Float {
      let p0 = Float.max(prices[i], EPS);
      let p1 = Float.max(prices[i + 1], EPS);
      Float.log(p1 / p0)
    })
  };

  func powerLaw(x : Float, exponent : Float) : Float {
    let base = Float.max(x, EPS);
    Float.exp(exponent * Float.log(base))
  };

  public func estimateLinearMarketImpact(
    referencePrice : Float,
    quantity : Float,
    averageDailyVolume : Float,
    volatility : Float,
    spreadBps : Float,
    kylesLambda : Float,
  ) : MarketImpactEstimate {
    let participation = safeDiv(quantity, Float.max(averageDailyVolume, quantity));
    let temporary = referencePrice * (spreadBps / 10000.0 * 0.5 + Float.abs(kylesLambda) * participation);
    let permanent = referencePrice * Float.abs(kylesLambda) * participation * 0.5 + volatility * referencePrice * participation * 0.25;
    {
      model = "linear";
      referencePrice = referencePrice;
      quantity = quantity;
      participationRate = participation;
      temporaryImpact = temporary;
      permanentImpact = permanent;
      totalImpact = temporary + permanent;
    }
  };

  public func estimateSquareRootMarketImpact(
    referencePrice : Float,
    quantity : Float,
    averageDailyVolume : Float,
    volatility : Float,
    spreadBps : Float,
  ) : MarketImpactEstimate {
    let participation = safeDiv(quantity, Float.max(averageDailyVolume, quantity));
    let root = Float.sqrt(Float.max(participation, 0.0));
    let temporary = referencePrice * (spreadBps / 20000.0 + 0.9 * volatility * root);
    let permanent = referencePrice * 0.35 * volatility * root;
    {
      model = "square_root";
      referencePrice = referencePrice;
      quantity = quantity;
      participationRate = participation;
      temporaryImpact = temporary;
      permanentImpact = permanent;
      totalImpact = temporary + permanent;
    }
  };

  public func estimatePowerLawMarketImpact(
    referencePrice : Float,
    quantity : Float,
    averageDailyVolume : Float,
    volatility : Float,
    exponent : Float,
  ) : MarketImpactEstimate {
    let participation = safeDiv(quantity, Float.max(averageDailyVolume, quantity));
    let scaled = powerLaw(participation, exponent);
    let temporary = referencePrice * volatility * 1.15 * scaled;
    let permanent = referencePrice * volatility * 0.45 * scaled;
    {
      model = "power_law";
      referencePrice = referencePrice;
      quantity = quantity;
      participationRate = participation;
      temporaryImpact = temporary;
      permanentImpact = permanent;
      totalImpact = temporary + permanent;
    }
  };

  public func decomposeBidAskSpread(bestBid : Float, bestAsk : Float, tradePrices : [Float]) : SpreadDecomposition {
    let midpoint = if (bestBid > 0.0 and bestAsk > 0.0) (bestBid + bestAsk) / 2.0 else lastOr(tradePrices, 0.0);
    let quoted = Float.max(0.0, bestAsk - bestBid);
    if (tradePrices.size() == 0 or midpoint <= EPS) {
      return {
        quotedSpread = quoted;
        effectiveSpread = quoted;
        realizedSpread = quoted * 0.6;
        adverseSelection = quoted * 0.4;
        inventoryHolding = quoted * 0.2;
        orderProcessing = quoted * 0.4;
      }
    };
    var effective = 0.0;
    var realized = 0.0;
    var observations : Nat = 0;
    var i : Nat = 0;
    while (i < tradePrices.size()) {
      let px = tradePrices[i];
      effective += 2.0 * Float.abs(px - midpoint);
      if (i + 1 < tradePrices.size()) {
        let nextMid = (px + tradePrices[i + 1]) / 2.0;
        let sign = if (px >= midpoint) 1.0 else -1.0;
        realized += 2.0 * sign * (px - nextMid);
      } else {
        let sign = if (px >= midpoint) 1.0 else -1.0;
        realized += 2.0 * sign * (px - midpoint);
      };
      observations += 1;
      i += 1;
    };
    let effectiveMean = safeDiv(effective, natToFloat(observations));
    let realizedMean = safeDiv(realized, natToFloat(observations));
    let adverse = effectiveMean - realizedMean;
    let orderProcessing = Float.max(0.0, realizedMean * 0.65 + quoted * 0.15);
    let inventoryHolding = realizedMean - orderProcessing;
    {
      quotedSpread = quoted;
      effectiveSpread = effectiveMean;
      realizedSpread = realizedMean;
      adverseSelection = adverse;
      inventoryHolding = inventoryHolding;
      orderProcessing = orderProcessing;
    }
  };

  public func estimateKylesLambda(priceChanges : [Float], signedVolumes : [Float]) : KylesLambdaEstimate {
    let n = if (priceChanges.size() < signedVolumes.size()) priceChanges.size() else signedVolumes.size();
    if (n < 3) {
      return { lambda = 0.0; intercept = 0.0; rSquared = 0.0; sampleSize = n };
    };
    let x = takeFloats(signedVolumes, n);
    let y = takeFloats(priceChanges, n);
    let vx = variance(x);
    if (vx <= EPS) {
      return { lambda = 0.0; intercept = mean(y); rSquared = 0.0; sampleSize = n };
    };
    let beta = covariance(x, y) / vx;
    let alpha = mean(y) - beta * mean(x);
    let fitted = Array.tabulate<Float>(n, func(i : Nat) : Float { alpha + beta * x[i] });
    let ssTot = Array.foldLeft<Float, Float>(y, 0.0, func(acc : Float, value : Float) : Float {
      let d = value - mean(y);
      acc + d * d
    });
    var ssRes = 0.0;
    var i : Nat = 0;
    while (i < n) {
      let d = y[i] - fitted[i];
      ssRes += d * d;
      i += 1;
    };
    let r2 = if (ssTot <= EPS) 0.0 else 1.0 - ssRes / ssTot;
    { lambda = beta; intercept = alpha; rSquared = clamp(r2, 0.0, 1.0); sampleSize = n }
  };

  func estimateKylesLambdaFromFills(fills : [PhantomExchange.Fill], referenceMid : Float) : KylesLambdaEstimate {
    if (fills.size() < 3) {
      return { lambda = 0.0; intercept = 0.0; rSquared = 0.0; sampleSize = fills.size() };
    };
    let changes = Array.tabulate<Float>(fills.size() - 1, func(i : Nat) : Float {
      fills[i + 1].price - fills[i].price
    });
    let signedVols = Array.tabulate<Float>(fills.size() - 1, func(i : Nat) : Float {
      let previous = if (i == 0) referenceMid else fills[i].price;
      let sign = if (fills[i + 1].price >= previous) 1.0 else -1.0;
      sign * fills[i + 1].quantity
    });
    estimateKylesLambda(changes, signedVols)
  };

  public func buildMarketMicrostructureSnapshot(
    exchangeState : PhantomExchange.PhantomExchangeState,
    intelligenceState : PhantomIntelligence.PhantomIntelligenceState,
    pairId : Text,
    depthLevels : Nat,
  ) : ?MarketMicrostructureSnapshot {
    switch (PhantomExchange.getOrderBook(exchangeState, pairId)) {
      case null null;
      case (?book) {
        let bidLevels = aggregateLevels(book.bids, depthLevels);
        let askLevels = aggregateLevels(book.asks, depthLevels);
        let bestBid = if (bidLevels.size() == 0) null else ?bidLevels[0];
        let bestAsk = if (askLevels.size() == 0) null else ?askLevels[0];
        let bestBidPx = levelPrice(bestBid);
        let bestAskPx = levelPrice(bestAsk);
        let mid = if (bestBidPx > 0.0 and bestAskPx > 0.0) {
          (bestBidPx + bestAskPx) / 2.0
        } else if (bestBidPx > 0.0) {
          bestBidPx
        } else {
          bestAskPx
        };
        let bidDepth = Array.foldLeft<PriceLevel, Float>(bidLevels, 0.0, func(acc : Float, level : PriceLevel) : Float { acc + level.size });
        let askDepth = Array.foldLeft<PriceLevel, Float>(askLevels, 0.0, func(acc : Float, level : PriceLevel) : Float { acc + level.size });
        let pairFills = filterFillsByPair(exchangeState.recentFills, pairId);
        let events = fillsToOrderFlowEvents(pairFills, mid);
        let orderFlow = calculateOrderFlowImbalance(events);
        let tradePrices = Array.map<PhantomExchange.Fill, Float>(pairFills, func(fill : PhantomExchange.Fill) : Float { fill.price });
        let fillReturns = logReturns(tradePrices);
        let realizedSigma = stdDev(fillReturns);
        let spreadDecomp = decomposeBidAskSpread(bestBidPx, bestAskPx, tradePrices);
        let lambdaEstimate = estimateKylesLambdaFromFills(pairFills, mid);
        let benchmarkQty = Float.max(1.0, (bidDepth + askDepth) * 0.1 + Float.abs(orderFlow.netVolume) * 0.5);
        let adv = Float.max(benchmarkQty, Array.foldLeft<PhantomExchange.Fill, Float>(pairFills, 0.0, func(acc : Float, fill : PhantomExchange.Fill) : Float { acc + fill.quantity }));
        let marketImpact = {
          linear = estimateLinearMarketImpact(mid, benchmarkQty, adv, realizedSigma, safeDiv(bestAskPx - bestBidPx, Float.max(mid, 1.0)) * 10000.0, lambdaEstimate.lambda);
          squareRoot = estimateSquareRootMarketImpact(mid, benchmarkQty, adv, realizedSigma, safeDiv(bestAskPx - bestBidPx, Float.max(mid, 1.0)) * 10000.0);
          powerLaw = estimatePowerLawMarketImpact(mid, benchmarkQty, adv, realizedSigma, 0.65);
        };
        ?{
          pairId = pairId;
          bestBid = bestBid;
          bestAsk = bestAsk;
          midPrice = mid;
          spread = Float.max(0.0, bestAskPx - bestBidPx);
          spreadBps = safeDiv(Float.max(0.0, bestAskPx - bestBidPx), Float.max(mid, 1.0)) * 10000.0;
          bidDepth = bidDepth;
          askDepth = askDepth;
          depthImbalance = safeDiv(bidDepth - askDepth, bidDepth + askDepth);
          orderFlow = orderFlow;
          marketImpact = marketImpact;
          spreadDecomposition = spreadDecomp;
          kylesLambda = lambdaEstimate;
          intelligenceConfidence = intelligenceState.coherenceGate;
          signalPressure = intelligencePressure(intelligenceState, pairId);
        }
      }
    }
  };

  func ols(ySeries : [Float], xSeries : [Float]) : OlsResult {
    let n = if (ySeries.size() < xSeries.size()) ySeries.size() else xSeries.size();
    if (n == 0) {
      return { alpha = 0.0; beta = 0.0; fitted = []; residuals = []; rSquared = 0.0 };
    };
    let x = takeFloats(xSeries, n);
    let y = takeFloats(ySeries, n);
    let vx = variance(x);
    let beta = if (vx <= EPS) 0.0 else covariance(x, y) / vx;
    let alpha = mean(y) - beta * mean(x);
    let fitted = Array.tabulate<Float>(n, func(i : Nat) : Float { alpha + beta * x[i] });
    let residuals = Array.tabulate<Float>(n, func(i : Nat) : Float { y[i] - fitted[i] });
    let yMean = mean(y);
    var ssRes = 0.0;
    var ssTot = 0.0;
    var i : Nat = 0;
    while (i < n) {
      let r = residuals[i];
      let d = y[i] - yMean;
      ssRes += r * r;
      ssTot += d * d;
      i += 1;
    };
    let r2 = if (ssTot <= EPS) 0.0 else 1.0 - ssRes / ssTot;
    { alpha = alpha; beta = beta; fitted = fitted; residuals = residuals; rSquared = clamp(r2, 0.0, 1.0) }
  };

  func fitAr1(series : [Float]) : Ar1Result {
    if (series.size() < 3) {
      return { intercept = 0.0; phi = 0.0; residualStdDev = 0.0; tStatistic = 0.0 };
    };
    let x = takeFloats(series, series.size() - 1);
    let y = Array.tabulate<Float>(series.size() - 1, func(i : Nat) : Float { series[i + 1] });
    let fit = ols(y, x);
    let n = fit.residuals.size();
    let sigma2 = if (n > 2) Array.foldLeft<Float, Float>(fit.residuals, 0.0, func(acc : Float, r : Float) : Float { acc + r * r }) / natToFloat(n - 2) else 0.0;
    let xMean = mean(x);
    var sxx = 0.0;
    for (value in x.vals()) {
      let d = value - xMean;
      sxx += d * d;
    };
    let seBeta = Float.sqrt(Float.max(EPS, safeDiv(sigma2, sxx)));
    let gamma = fit.beta - 1.0;
    let tStat = safeDiv(gamma, seBeta);
    { intercept = fit.alpha; phi = fit.beta; residualStdDev = Float.sqrt(Float.max(0.0, sigma2)); tStatistic = tStat }
  };

  public func detectCointegration(seriesA : [Float], seriesB : [Float]) : CointegrationResult {
    let fit = ols(seriesA, seriesB);
    let residuals = fit.residuals;
    let ar = fitAr1(residuals);
    let resStd = stdDev(residuals);
    let currentResidual = if (residuals.size() == 0) 0.0 else residuals[residuals.size() - 1];
    let z = safeDiv(currentResidual - mean(residuals), Float.max(resStd, EPS));
    let halfLife = if (ar.phi > EPS and ar.phi < 0.9999) Float.abs(Float.log(2.0) / Float.log(Float.max(ar.phi, EPS))) else 0.0;
    let isCointegrated = residuals.size() >= 20 and ar.phi > 0.0 and ar.phi < 1.0 and ar.tStatistic < -2.5;
    let confidence = clamp((Float.min(Float.abs(ar.tStatistic) / 5.0, 1.0) + fit.rSquared + Float.max(0.0, 1.0 - Float.min(Float.abs(z) / 4.0, 1.0))) / 3.0, 0.0, 1.0);
    {
      alpha = fit.alpha;
      hedgeRatio = fit.beta;
      adfStatistic = ar.tStatistic;
      meanResidual = mean(residuals);
      residualStdDev = resStd;
      currentResidual = currentResidual;
      zScore = z;
      halfLife = halfLife;
      isCointegrated = isCointegrated;
      confidence = confidence;
    }
  };

  public func generatePairsTradingSignal(result : CointegrationResult, entryThreshold : Float, exitThreshold : Float) : PairsTradingSignal {
    let signal : TradeSignal = if (not result.isCointegrated) {
      #hold
    } else if (result.zScore >= entryThreshold) {
      #sell
    } else if (result.zScore <= -entryThreshold) {
      #buy
    } else if (Float.abs(result.zScore) <= exitThreshold) {
      #hold
    } else {
      #hold
    };
    {
      signal = signal;
      zScore = result.zScore;
      entryThreshold = entryThreshold;
      exitThreshold = exitThreshold;
      targetSpread = -result.meanResidual;
      hedgeRatio = result.hedgeRatio;
      conviction = clamp(result.confidence * Float.min(Float.abs(result.zScore) / Float.max(entryThreshold, 1.0), 1.0), 0.0, 1.0);
    }
  };

  public func buildMeanReversionSignal(series : [Float]) : MeanReversionSignal {
    let mu = mean(series);
    let sigma = stdDev(series);
    let current = lastOr(series, mu);
    let z = safeDiv(current - mu, Float.max(sigma, EPS));
    let centered = Array.map<Float, Float>(series, func(value : Float) : Float { value - mu });
    let ar = fitAr1(centered);
    let halfLife = if (ar.phi > EPS and ar.phi < 0.9999) Float.abs(Float.log(2.0) / Float.log(Float.max(ar.phi, EPS))) else 0.0;
    let signal : TradeSignal = if (z > 1.5) #sell else if (z < -1.5) #buy else #hold;
    {
      signal = signal;
      mean = mu;
      standardDeviation = sigma;
      zScore = z;
      halfLife = halfLife;
      expectedReturn = -z * sigma * Phi.PHI_INV;
      conviction = clamp(Float.abs(z) / 3.0, 0.0, 1.0);
    }
  };

  public func buildCorrelationTradingSignal(primaryReturns : [Float], hedgeReturns : [Float]) : CorrelationTradingSignal {
    let corr = correlation(primaryReturns, hedgeReturns);
    let hedgeVar = variance(hedgeReturns);
    let beta = if (hedgeVar <= EPS) 0.0 else covariance(primaryReturns, hedgeReturns) / hedgeVar;
    let relValue = lastOr(primaryReturns, 0.0) - beta * lastOr(hedgeReturns, 0.0);
    let signal : TradeSignal = if (corr > 0.7 and relValue > 0.0) #sell else if (corr > 0.7 and relValue < 0.0) #buy else #hold;
    {
      rollingCorrelation = corr;
      beta = beta;
      relativeValueScore = relValue;
      signal = signal;
      confidence = clamp(Float.abs(corr) * (1.0 - Float.min(Float.abs(relValue) / Float.max(stdDev(primaryReturns), EPS), 1.0) * 0.25), 0.0, 1.0);
    }
  };

  public func defaultKalmanHedgeState() : KalmanHedgeState {
    {
      intercept = 0.0;
      hedgeRatio = 1.0;
      covariance00 = 1.0;
      covariance01 = 0.0;
      covariance10 = 0.0;
      covariance11 = 1.0;
      processNoise = 0.0001;
      measurementNoise = 0.001;
      innovation = 0.0;
      innovationVariance = 1.0;
    }
  };

  public func kalmanUpdate(state : KalmanHedgeState, x : Float, y : Float) : KalmanHedgeState {
    let p00p = state.covariance00 + state.processNoise;
    let p01p = state.covariance01;
    let p10p = state.covariance10;
    let p11p = state.covariance11 + state.processNoise;
    let innovation = y - state.intercept - state.hedgeRatio * x;
    let s = p00p + x * (p01p + p10p) + x * x * p11p + state.measurementNoise;
    let k0 = safeDiv(p00p + x * p01p, s);
    let k1 = safeDiv(p10p + x * p11p, s);
    let intercept = state.intercept + k0 * innovation;
    let hedgeRatio = state.hedgeRatio + k1 * innovation;
    {
      intercept = intercept;
      hedgeRatio = hedgeRatio;
      covariance00 = p00p - k0 * (p00p + x * p01p);
      covariance01 = p01p - k0 * (p01p + x * p11p);
      covariance10 = p10p - k1 * (p00p + x * p01p);
      covariance11 = p11p - k1 * (p01p + x * p11p);
      processNoise = state.processNoise;
      measurementNoise = state.measurementNoise;
      innovation = innovation;
      innovationVariance = s;
    }
  };

  public func runKalmanFilter(primarySeries : [Float], hedgeSeries : [Float]) : KalmanFilterResult {
    let n = if (primarySeries.size() < hedgeSeries.size()) primarySeries.size() else hedgeSeries.size();
    if (n == 0) {
      return { finalState = defaultKalmanHedgeState(); hedgeRatios = []; intercepts = []; residuals = [] };
    };
    var state = defaultKalmanHedgeState();
    var ratios : [Float] = [];
    var intercepts : [Float] = [];
    var residuals : [Float] = [];
    var i : Nat = 0;
    while (i < n) {
      state := kalmanUpdate(state, hedgeSeries[i], primarySeries[i]);
      ratios := appendOne<Float>(ratios, state.hedgeRatio);
      intercepts := appendOne<Float>(intercepts, state.intercept);
      residuals := appendOne<Float>(residuals, state.innovation);
      i += 1;
    };
    { finalState = state; hedgeRatios = ratios; intercepts = intercepts; residuals = residuals }
  };

  public func analyzeStatisticalArbitrage(primarySeries : [Float], hedgeSeries : [Float]) : StatisticalArbitrageSnapshot {
    let cointegration = detectCointegration(primarySeries, hedgeSeries);
    let pairsTrading = generatePairsTradingSignal(cointegration, 2.0, 0.5);
    let kalman = runKalmanFilter(primarySeries, hedgeSeries);
    let spreadSeries = if (primarySeries.size() == 0 or hedgeSeries.size() == 0) {
      []
    } else {
      let n = if (primarySeries.size() < hedgeSeries.size()) primarySeries.size() else hedgeSeries.size();
      Array.tabulate<Float>(n, func(i : Nat) : Float {
        primarySeries[i] - cointegration.alpha - cointegration.hedgeRatio * hedgeSeries[i]
      })
    };
    let meanReversion = buildMeanReversionSignal(spreadSeries);
    let corr = buildCorrelationTradingSignal(logReturns(primarySeries), logReturns(hedgeSeries));
    {
      cointegration = cointegration;
      pairsTrading = pairsTrading;
      meanReversion = meanReversion;
      correlation = corr;
      kalman = kalman;
    }
  };

  type LikelihoodResult = {
    value : Float;
    variances : [Float];
  };

  func garchLikelihood(returns : [Float], omega : Float, alpha : Float, beta : Float) : LikelihoodResult {
    if (returns.size() == 0) { return { value = 0.0; variances = [] } };
    let unconditional = Float.max(variance(returns), EPS);
    var vars : [Float] = [unconditional];
    var ll = 0.0;
    var i : Nat = 0;
    while (i < returns.size()) {
      let prevVar = vars[vars.size() - 1];
      let prevRet = if (i == 0) returns[0] else returns[i - 1];
      let nextVar = Float.max(EPS, omega + alpha * prevRet * prevRet + beta * prevVar);
      vars := appendOne<Float>(vars, nextVar);
      ll += 0.5 * (Float.log(nextVar) + returns[i] * returns[i] / nextVar);
      i += 1;
    };
    { value = ll; variances = Array.tabulate<Float>(returns.size(), func(j : Nat) : Float { vars[j + 1] }) }
  };

  public func estimateGarch11(returns : [Float]) : GarchEstimate {
    let sampleVar = Float.max(variance(returns), EPS);
    let alphas : [Float] = [0.03, 0.05, 0.08, 0.12, 0.18];
    let betas : [Float] = [0.70, 0.80, 0.86, 0.90, 0.94];
    var bestAlpha = 0.08;
    var bestBeta = 0.90;
    var bestOmega = sampleVar * 0.02;
    var bestLL = 1.0e18;
    var bestVars : [Float] = [];
    for (alpha in alphas.vals()) {
      for (beta in betas.vals()) {
        if (alpha + beta < 0.995) {
          let omega = Float.max(EPS, sampleVar * (1.0 - alpha - beta));
          let candidate = garchLikelihood(returns, omega, alpha, beta);
          if (candidate.value < bestLL) {
            bestLL := candidate.value;
            bestAlpha := alpha;
            bestBeta := beta;
            bestOmega := omega;
            bestVars := candidate.variances;
          };
        };
      };
    };
    let lastReturn = lastOr(returns, 0.0);
    let lastVar = lastOr(bestVars, sampleVar);
    {
      omega = bestOmega;
      alpha = bestAlpha;
      beta = bestBeta;
      persistence = bestAlpha + bestBeta;
      longRunVariance = safeDiv(bestOmega, 1.0 - bestAlpha - bestBeta);
      oneStepForecast = Float.max(EPS, bestOmega + bestAlpha * lastReturn * lastReturn + bestBeta * lastVar);
      logLikelihood = -bestLL;
      conditionalVariance = bestVars;
    }
  };

  func normalAbsExpectation() : Float { Float.sqrt(2.0 / PI) };

  func egarchLikelihood(returns : [Float], omega : Float, alpha : Float, beta : Float, gamma : Float) : LikelihoodResult {
    if (returns.size() == 0) { return { value = 0.0; variances = [] } };
    let baseVar = Float.max(variance(returns), EPS);
    var logVar = Float.log(baseVar);
    var vars : [Float] = [];
    var ll = 0.0;
    var i : Nat = 0;
    while (i < returns.size()) {
      let varNow = Float.max(EPS, Float.exp(logVar));
      vars := appendOne<Float>(vars, varNow);
      let zPrev = if (i == 0) 0.0 else safeDiv(returns[i - 1], Float.sqrt(varNow));
      logVar := omega + beta * logVar + alpha * (Float.abs(zPrev) - normalAbsExpectation()) + gamma * zPrev;
      ll += 0.5 * (Float.log(varNow) + returns[i] * returns[i] / varNow);
      i += 1;
    };
    { value = ll; variances = vars }
  };

  public func estimateEgarch(returns : [Float]) : EgarchEstimate {
    let sampleVar = Float.max(variance(returns), EPS);
    let alphas : [Float] = [0.05, 0.10, 0.15];
    let betas : [Float] = [0.75, 0.85, 0.93];
    let gammas : [Float] = [-0.25, -0.10, 0.0, 0.10];
    var bestAlpha = 0.10;
    var bestBeta = 0.85;
    var bestGamma = -0.10;
    var bestOmega = (1.0 - bestBeta) * Float.log(sampleVar);
    var bestLL = 1.0e18;
    var bestVars : [Float] = [];
    for (alpha in alphas.vals()) {
      for (beta in betas.vals()) {
        for (gamma in gammas.vals()) {
          let omega = (1.0 - beta) * Float.log(sampleVar);
          let candidate = egarchLikelihood(returns, omega, alpha, beta, gamma);
          if (candidate.value < bestLL) {
            bestLL := candidate.value;
            bestAlpha := alpha;
            bestBeta := beta;
            bestGamma := gamma;
            bestOmega := omega;
            bestVars := candidate.variances;
          };
        };
      };
    };
    let lastVar = lastOr(bestVars, sampleVar);
    let lastRet = lastOr(returns, 0.0);
    let z = safeDiv(lastRet, Float.sqrt(Float.max(lastVar, EPS)));
    let forecast = Float.exp(bestOmega + bestBeta * Float.log(lastVar) + bestAlpha * (Float.abs(z) - normalAbsExpectation()) + bestGamma * z);
    {
      omega = bestOmega;
      alpha = bestAlpha;
      beta = bestBeta;
      gamma = bestGamma;
      leverageEffect = bestGamma;
      oneStepForecast = Float.max(EPS, forecast);
      logLikelihood = -bestLL;
      conditionalVariance = bestVars;
    }
  };

  public func estimateHestonParameters(returns : [Float]) : HestonParameters {
    let varianceSeries = Array.map<Float, Float>(returns, func(r : Float) : Float { r * r });
    let ar = fitAr1(varianceSeries);
    let phi = clamp(ar.phi, 0.0001, 0.9999);
    let diffs = if (varianceSeries.size() < 2) [] else Array.tabulate<Float>(varianceSeries.size() - 1, func(i : Nat) : Float { varianceSeries[i + 1] - varianceSeries[i] });
    {
      kappa = Float.max(0.001, -Float.log(phi));
      theta = Float.max(EPS, mean(varianceSeries));
      sigma = Float.max(EPS, stdDev(diffs) * Float.sqrt(252.0));
      rho = correlation(returns, prependOne<Float>(0.0, diffs));
      v0 = Float.max(EPS, lastOr(varianceSeries, EPS));
    }
  };

  public func calculateRealizedVolatility(prices : [Float]) : RealizedVolatility {
    let returns = logReturns(prices);
    let realizedVariance = Array.foldLeft<Float, Float>(returns, 0.0, func(acc : Float, r : Float) : Float { acc + r * r });
    let absProducts = if (returns.size() < 2) 0.0 else Array.foldLeft<Float, Float>(Array.tabulate<Float>(returns.size() - 1, func(i : Nat) : Float { Float.abs(returns[i]) * Float.abs(returns[i + 1]) }), 0.0, func(acc : Float, v : Float) : Float { acc + v });
    let bipower = (PI / 2.0) * absProducts;
    {
      sampleCount = returns.size();
      realizedVariance = realizedVariance;
      realizedVolatility = Float.sqrt(Float.max(realizedVariance, 0.0));
      annualizedVolatility = Float.sqrt(Float.max(realizedVariance, 0.0) * 252.0);
      bipowerVariation = bipower;
      jumpVariation = Float.max(0.0, realizedVariance - bipower);
    }
  };

  func normCdf(x : Float) : Float {
    let ax = Float.abs(x);
    let k = 1.0 / (1.0 + 0.2316419 * ax);
    let poly = k * (0.319381530 + k * (-0.356563782 + k * (1.781477937 + k * (-1.821255978 + 1.330274429 * k))));
    let approx = 1.0 - Float.exp(-0.5 * ax * ax) * poly / SQRT_TWO_PI;
    if (x >= 0.0) approx else 1.0 - approx
  };

  func blackScholesPrice(spot : Float, strike : Float, maturity : Float, rate : Float, vol : Float, optionType : OptionType) : Float {
    if (maturity <= EPS or vol <= EPS) {
      return switch (optionType) {
        case (#call) Float.max(0.0, spot - strike);
        case (#put) Float.max(0.0, strike - spot);
      }
    };
    let sigmaSqrtT = vol * Float.sqrt(maturity);
    let d1 = (Float.log(Float.max(spot, EPS) / Float.max(strike, EPS)) + (rate + 0.5 * vol * vol) * maturity) / sigmaSqrtT;
    let d2 = d1 - sigmaSqrtT;
    let discount = Float.exp(-rate * maturity);
    switch (optionType) {
      case (#call) { spot * normCdf(d1) - strike * discount * normCdf(d2) };
      case (#put) { strike * discount * normCdf(-d2) - spot * normCdf(-d1) };
    }
  };

  func blackScholesVega(spot : Float, strike : Float, maturity : Float, rate : Float, vol : Float) : Float {
    if (maturity <= EPS or vol <= EPS) { return 0.0 };
    let sigmaSqrtT = vol * Float.sqrt(maturity);
    let d1 = (Float.log(Float.max(spot, EPS) / Float.max(strike, EPS)) + (rate + 0.5 * vol * vol) * maturity) / sigmaSqrtT;
    spot * Float.sqrt(maturity) * Float.exp(-0.5 * d1 * d1) / SQRT_TWO_PI
  };

  func solveImpliedVolatility(spot : Float, quote : OptionQuote, rate : Float) : Float {
    var vol = 0.25;
    var iter : Nat = 0;
    while (iter < 32) {
      let price = blackScholesPrice(spot, quote.strike, quote.maturityYears, rate, vol, quote.optionType);
      let diff = price - quote.marketPrice;
      if (Float.abs(diff) < 0.000001) { return clamp(vol, 0.0001, 5.0) };
      let vega = blackScholesVega(spot, quote.strike, quote.maturityYears, rate, vol);
      if (vega <= EPS) { return clamp(vol, 0.0001, 5.0) };
      vol := clamp(vol - diff / vega, 0.0001, 5.0);
      iter += 1;
    };
    clamp(vol, 0.0001, 5.0)
  };

  public func buildImpliedVolSurface(spot : Float, riskFreeRate : Float, quotes : [OptionQuote]) : ImpliedVolSurface {
    let nodes = Array.map<OptionQuote, ImpliedVolNode>(quotes, func(quote : OptionQuote) : ImpliedVolNode {
      let iv = solveImpliedVolatility(spot, quote, riskFreeRate);
      {
        strike = quote.strike;
        maturityYears = quote.maturityYears;
        moneyness = safeDiv(quote.strike, Float.max(spot, EPS));
        impliedVolatility = iv;
        totalVariance = iv * iv * quote.maturityYears;
        openInterest = quote.openInterest;
      }
    });
    var atmVol = 0.0;
    var atmWeight = 0.0;
    var skewNum = 0.0;
    var skewDen = 0.0;
    var termNum = 0.0;
    var termDen = 0.0;
    for (node in nodes.vals()) {
      let atmDistance = Float.abs(node.moneyness - 1.0);
      let atmWeightLocal = 1.0 / Float.max(0.05, atmDistance + 0.05);
      atmVol += node.impliedVolatility * atmWeightLocal;
      atmWeight += atmWeightLocal;
      skewNum += (node.moneyness - 1.0) * node.impliedVolatility;
      skewDen += (node.moneyness - 1.0) * (node.moneyness - 1.0);
      termNum += node.maturityYears * node.impliedVolatility;
      termDen += node.maturityYears * node.maturityYears;
    };
    {
      spot = spot;
      riskFreeRate = riskFreeRate;
      nodes = nodes;
      atmVolatility = safeDiv(atmVol, atmWeight);
      skew = safeDiv(skewNum, skewDen);
      termStructureSlope = safeDiv(termNum, termDen);
    }
  };

  public func analyzeVolatility(prices : [Float], optionQuotes : [OptionQuote]) : VolatilitySnapshot {
    let returns = logReturns(prices);
    let garch = estimateGarch11(returns);
    let egarch = estimateEgarch(returns);
    let heston = estimateHestonParameters(returns);
    let realized = calculateRealizedVolatility(prices);
    let spot = lastOr(prices, 0.0);
    let surface = buildImpliedVolSurface(spot, 0.03, optionQuotes);
    {
      garch = garch;
      egarch = egarch;
      heston = heston;
      realized = realized;
      impliedSurface = surface;
    }
  };

  func equalVolumeCurve(slices : Nat) : [Float] {
    if (slices == 0) { return [] };
    Array.tabulate<Float>(slices, func(_ : Nat) : Float { 1.0 / natToFloat(slices) })
  };

  func normalizeCurve(curve : [Float]) : [Float] {
    let total = sum(curve);
    if (curve.size() == 0 or total <= EPS) { return equalVolumeCurve(if (curve.size() == 0) 1 else curve.size()) };
    Array.map<Float, Float>(curve, func(value : Float) : Float { value / total })
  };

  func inferVolumeCurve(ticks : [TickData], slices : Nat) : [Float] {
    if (slices == 0) { return [] };
    if (ticks.size() == 0) { return equalVolumeCurve(slices) };
    let bucketSize = Float.max(1.0, safeDiv(natToFloat(ticks.size()), natToFloat(slices)));
    var buckets = Array.tabulate<Float>(slices, func(_ : Nat) : Float { 0.0 });
    var i : Nat = 0;
    while (i < ticks.size()) {
      let rawIndex = Float.floor(natToFloat(i) / bucketSize);
      let rawInt = rawIndex.toInt();
      let upperBound = if (slices <= 1) 0 else slices - 1;
      let natIndex = Int.abs(rawInt);
      let idx = if (natIndex >= slices) upperBound else natIndex;
      buckets := Array.tabulate<Float>(slices, func(j : Nat) : Float {
        if (j == idx) buckets[j] + Float.max(0.0, ticks[i].volume) else buckets[j]
      });
      i += 1;
    };
    normalizeCurve(buckets)
  };

  public func buildTwapSchedule(totalQuantity : Float, horizonSeconds : Float, slices : Nat, referencePrice : Float) : TwapSchedule {
    let safeSlices = if (slices == 0) 1 else slices;
    let perSlice = totalQuantity / natToFloat(safeSlices);
    let interval = horizonSeconds / natToFloat(safeSlices);
    let plan = Array.tabulate<ExecutionSlice>(safeSlices, func(i : Nat) : ExecutionSlice {
      {
        slice = i + 1;
        targetTimeSeconds = natToFloat(i + 1) * interval;
        quantity = if (i + 1 == safeSlices) totalQuantity - perSlice * natToFloat(safeSlices - 1) else perSlice;
        participationRate = 1.0 / natToFloat(safeSlices);
        expectedPrice = referencePrice;
      }
    });
    { totalQuantity = totalQuantity; horizonSeconds = horizonSeconds; slices = plan }
  };

  public func buildVwapSchedule(totalQuantity : Float, horizonSeconds : Float, volumeCurve : [Float], referencePrice : Float) : VwapSchedule {
    let normalized = normalizeCurve(volumeCurve);
    let safeSlices = if (normalized.size() == 0) 1 else normalized.size();
    let interval = horizonSeconds / natToFloat(safeSlices);
    let plan = Array.tabulate<ExecutionSlice>(safeSlices, func(i : Nat) : ExecutionSlice {
      let weight = if (normalized.size() == 0) 1.0 else normalized[i];
      {
        slice = i + 1;
        targetTimeSeconds = natToFloat(i + 1) * interval;
        quantity = totalQuantity * weight;
        participationRate = weight;
        expectedPrice = referencePrice;
      }
    });
    { totalQuantity = totalQuantity; volumeCurve = normalized; slices = plan }
  };

  func acosh(x : Float) : Float {
    Float.log(x + Float.sqrt(Float.max(x * x - 1.0, EPS)))
  };

  func sinh(x : Float) : Float {
    (Float.exp(x) - Float.exp(-x)) / 2.0
  };

  public func buildAlmgrenChrissPlan(
    totalQuantity : Float,
    referencePrice : Float,
    volatility : Float,
    riskAversion : Float,
    temporaryImpactCoeff : Float,
    permanentImpactCoeff : Float,
    horizonSeconds : Float,
    slices : Nat,
  ) : AlmgrenChrissPlan {
    let safeSlices = if (slices == 0) 1 else slices;
    let tau = horizonSeconds / natToFloat(safeSlices);
    let eta = Float.max(temporaryImpactCoeff, EPS);
    let gamma = Float.max(permanentImpactCoeff, EPS);
    let sigma2 = Float.max(volatility * volatility, EPS);
    let kappaArg = 1.0 + riskAversion * sigma2 * tau * tau / (2.0 * eta);
    let kappa = if (kappaArg <= 1.0 + EPS) 0.0 else acosh(kappaArg) / Float.max(tau, EPS);
    let totalHorizon = horizonSeconds;
    let denom = if (kappa <= EPS) 1.0 else sinh(kappa * totalHorizon);
    let inventory = Array.tabulate<Float>(safeSlices + 1, func(i : Nat) : Float {
      if (kappa <= EPS) {
        totalQuantity * (1.0 - natToFloat(i) / natToFloat(safeSlices))
      } else {
        totalQuantity * sinh(kappa * Float.max(totalHorizon - natToFloat(i) * tau, 0.0)) / denom
      }
    });
    let childOrders = Array.tabulate<ExecutionSlice>(safeSlices, func(i : Nat) : ExecutionSlice {
      let qty = Float.max(0.0, inventory[i] - inventory[i + 1]);
      {
        slice = i + 1;
        targetTimeSeconds = natToFloat(i + 1) * tau;
        quantity = qty;
        participationRate = safeDiv(qty, totalQuantity);
        expectedPrice = referencePrice - gamma * (totalQuantity - inventory[i + 1]);
      }
    });
    var impactCost = 0.0;
    for (order in childOrders.vals()) {
      impactCost += eta * order.quantity * order.quantity + gamma * order.quantity * totalQuantity * 0.5;
    };
    {
      riskAversion = riskAversion;
      temporaryImpact = eta;
      permanentImpact = gamma;
      liquidationHorizonSeconds = horizonSeconds;
      remainingInventoryPath = inventory;
      childOrders = childOrders;
      expectedCost = impactCost;
      expectedRisk = Float.sqrt(sigma2 * horizonSeconds) * totalQuantity * riskAversion;
    }
  };

  public func buildImplementationShortfallPlan(
    arrivalPrice : Float,
    benchmarkPrice : Float,
    optimizedSchedule : [ExecutionSlice],
    volatility : Float,
  ) : ImplementationShortfallPlan {
    var weightedImpact = 0.0;
    for (slice in optimizedSchedule.vals()) {
      weightedImpact += slice.participationRate * slice.quantity;
    };
    let expectedShortfall = Float.abs(arrivalPrice - benchmarkPrice) + weightedImpact * volatility * 0.01;
    {
      arrivalPrice = arrivalPrice;
      benchmarkPrice = benchmarkPrice;
      expectedShortfall = expectedShortfall;
      expectedShortfallBps = safeDiv(expectedShortfall, Float.max(arrivalPrice, EPS)) * 10000.0;
      volatilityRisk = volatility * Phi.PHI_INV;
      urgencyScore = clamp(Float.abs(arrivalPrice - benchmarkPrice) / Float.max(arrivalPrice, 1.0) * 1000.0 + volatility, 0.0, 1.0);
      optimizedSchedule = optimizedSchedule;
    }
  };

  public func analyzeExecution(
    microstructure : MarketMicrostructureSnapshot,
    ticks : [TickData],
    totalQuantity : Float,
    slices : Nat,
  ) : ExecutionSnapshot {
    let horizonSeconds = Float.max(60.0, natToFloat(if (slices == 0) 1 else slices) * 60.0);
    let referencePrice = if (microstructure.midPrice > 0.0) microstructure.midPrice else 1.0;
    let volumeCurve = inferVolumeCurve(ticks, if (slices == 0) 1 else slices);
    let twap = buildTwapSchedule(totalQuantity, horizonSeconds, if (slices == 0) 1 else slices, referencePrice);
    let vwap = buildVwapSchedule(totalQuantity, horizonSeconds, volumeCurve, referencePrice);
    let volatility = microstructure.marketImpact.squareRoot.participationRate + microstructure.kylesLambda.rSquared * 0.01 + microstructure.spreadBps / 10000.0;
    let almgren = buildAlmgrenChrissPlan(
      totalQuantity,
      referencePrice,
      volatility,
      clamp(1.0 - microstructure.intelligenceConfidence + 0.1, 0.05, 1.0),
      Float.max(microstructure.marketImpact.linear.totalImpact, EPS),
      Float.max(Float.abs(microstructure.kylesLambda.lambda), EPS),
      horizonSeconds,
      if (slices == 0) 1 else slices,
    );
    let shortfall = buildImplementationShortfallPlan(referencePrice, referencePrice + microstructure.signalPressure * microstructure.spread * 0.25, almgren.childOrders, volatility);
    { twap = twap; vwap = vwap; almgrenChriss = almgren; shortfall = shortfall }
  };

  func tickToSignedVolume(tick : TickData) : Float {
    switch (tick.side) {
      case (#buy) tick.volume;
      case (#sell) -tick.volume;
      case (#hold) 0.0;
    }
  };

  public func analyzeTickData(ticks : [TickData]) : TickAnalytics {
    if (ticks.size() == 0) {
      return {
        tickCount = 0;
        tradeCount = 0;
        quoteCount = 0;
        cancelCount = 0;
        averageSpreadBps = 0.0;
        averageInterArrivalMs = 0.0;
        microPriceTrend = 0.0;
        orderFlowToxicity = 0.0;
        realizedVolatility = 0.0;
      }
    };
    var tradeCount : Nat = 0;
    var quoteCount : Nat = 0;
    var cancelCount : Nat = 0;
    var spreadAcc = 0.0;
    var interArrival = 0.0;
    var signedVolume = 0.0;
    var absVolume = 0.0;
    let prices = Array.tabulate<Float>(ticks.size(), func(i : Nat) : Float { ticks[i].last });
    var i : Nat = 0;
    while (i < ticks.size()) {
      let tick = ticks[i];
      spreadAcc += safeDiv(Float.max(0.0, tick.ask - tick.bid), Float.max((tick.ask + tick.bid) / 2.0, 1.0)) * 10000.0;
      switch (tick.messageType) {
        case (#trade) tradeCount += 1;
        case (#quote) quoteCount += 1;
        case (#cancel) cancelCount += 1;
      };
      let sv = tickToSignedVolume(tick);
      signedVolume += sv;
      absVolume += Float.abs(sv);
      if (i > 0) {
        interArrival += Float.abs((ticks[i].timestampMs - ticks[i - 1].timestampMs).toFloat());
      };
      i += 1;
    };
    let firstMid = (ticks[0].bid + ticks[0].ask) / 2.0;
    let lastMid = (ticks[ticks.size() - 1].bid + ticks[ticks.size() - 1].ask) / 2.0;
    {
      tickCount = ticks.size();
      tradeCount = tradeCount;
      quoteCount = quoteCount;
      cancelCount = cancelCount;
      averageSpreadBps = spreadAcc / natToFloat(ticks.size());
      averageInterArrivalMs = safeDiv(interArrival, natToFloat(if (ticks.size() > 1) ticks.size() - 1 else 1));
      microPriceTrend = safeDiv(lastMid - firstMid, Float.max(firstMid, 1.0));
      orderFlowToxicity = Float.min(1.0, Float.abs(safeDiv(signedVolume, Float.max(absVolume, EPS))));
      realizedVolatility = calculateRealizedVolatility(prices).realizedVolatility;
    }
  };

  public func detectLatencyArbitrage(ticks : [TickData]) : LatencyArbitrageAlert {
    if (ticks.size() == 0) {
      return { detected = false; staleQuoteCount = 0; maxLatencyMs = 0.0; averageEdgeBps = 0.0; confidence = 0.0 };
    };
    var staleCount : Nat = 0;
    var edgeAcc = 0.0;
    var maxLatency = 0.0;
    for (tick in ticks.vals()) {
      let mid = (tick.bid + tick.ask) / 2.0;
      let edgeBps = safeDiv(Float.abs(tick.referencePrice - mid), Float.max(mid, 1.0)) * 10000.0;
      if (tick.venueLatencyMs > 3.0 and edgeBps > 2.0) {
        staleCount += 1;
        edgeAcc += edgeBps;
      };
      if (tick.venueLatencyMs > maxLatency) { maxLatency := tick.venueLatencyMs };
    };
    let avgEdge = safeDiv(edgeAcc, natToFloat(if (staleCount == 0) 1 else staleCount));
    {
      detected = staleCount >= 3;
      staleQuoteCount = staleCount;
      maxLatencyMs = maxLatency;
      averageEdgeBps = avgEdge;
      confidence = clamp(Float.min(1.0, natToFloat(staleCount) / Float.max(natToFloat(ticks.size()) * 0.25, 1.0)) * Float.min(avgEdge / 10.0, 1.0), 0.0, 1.0);
    }
  };

  public func detectQuoteStuffing(ticks : [TickData]) : QuoteStuffingAlert {
    if (ticks.size() == 0) {
      return { detected = false; quoteToTradeRatio = 0.0; cancelRate = 0.0; burstScore = 0.0; confidence = 0.0 };
    };
    var quoteCount : Nat = 0;
    var tradeCount : Nat = 0;
    var cancelCount : Nat = 0;
    var burstScore = 0.0;
    var burstQuotes : Nat = 0;
    var i : Nat = 0;
    while (i < ticks.size()) {
      switch (ticks[i].messageType) {
        case (#quote) quoteCount += 1;
        case (#trade) tradeCount += 1;
        case (#cancel) cancelCount += 1;
      };
      if (i > 0 and Float.abs((ticks[i].timestampMs - ticks[i - 1].timestampMs).toFloat()) <= 50.0 and ticks[i].messageType == #quote) {
        burstQuotes += 1;
      } else {
        if (burstQuotes > 0) {
          burstScore += natToFloat(burstQuotes);
          burstQuotes := 0;
        };
      };
      i += 1;
    };
    if (burstQuotes > 0) { burstScore += natToFloat(burstQuotes) };
    let quoteToTrade = safeDiv(natToFloat(quoteCount), natToFloat(if (tradeCount == 0) 1 else tradeCount));
    let cancelRate = safeDiv(natToFloat(cancelCount), natToFloat(ticks.size()));
    let detected = quoteToTrade > 8.0 and cancelRate > 0.35 and burstScore > natToFloat(ticks.size()) * 0.25;
    {
      detected = detected;
      quoteToTradeRatio = quoteToTrade;
      cancelRate = cancelRate;
      burstScore = burstScore;
      confidence = clamp(Float.min(quoteToTrade / 20.0, 1.0) * Float.min(cancelRate / 0.5, 1.0), 0.0, 1.0);
    }
  };

  public func detectMomentumIgnition(ticks : [TickData]) : MomentumIgnitionAlert {
    if (ticks.size() < 5) {
      return { detected = false; direction = #hold; aggressiveBurstCount = 0; priceAcceleration = 0.0; reversalScore = 0.0; confidence = 0.0 };
    };
    var bestBurst : Nat = 0;
    var bestDirection : TradeSignal = #hold;
    var bestAcceleration = 0.0;
    var bestReversal = 0.0;
    var i : Nat = 1;
    while (i + 2 < ticks.size()) {
      let current = ticks[i];
      let previous = ticks[i - 1];
      let next = ticks[i + 1];
      let sameDirection = current.side == previous.side and current.side != #hold and next.side == current.side;
      if (sameDirection and current.messageType == #trade and previous.messageType == #trade and next.messageType == #trade) {
        let acceleration = safeDiv((next.last - previous.last), Float.max(previous.last, 1.0));
        let reversal = if (i + 2 < ticks.size()) Float.abs(ticks[i + 2].last - next.last) else 0.0;
        let reversalScore = safeDiv(reversal, Float.max(next.last, 1.0));
        if (Float.abs(acceleration) > Float.abs(bestAcceleration)) {
          bestAcceleration := acceleration;
          bestReversal := reversalScore;
          bestDirection := current.side;
          bestBurst := 3;
        };
      };
      i += 1;
    };
    let detected = bestBurst >= 3 and Float.abs(bestAcceleration) > 0.001 and bestReversal > 0.0005;
    {
      detected = detected;
      direction = bestDirection;
      aggressiveBurstCount = bestBurst;
      priceAcceleration = bestAcceleration;
      reversalScore = bestReversal;
      confidence = clamp(Float.min(Float.abs(bestAcceleration) * 1000.0, 1.0) * Float.min(bestReversal * 2000.0, 1.0), 0.0, 1.0);
    }
  };

  public func analyzeHighFrequencyTrading(ticks : [TickData]) : HighFrequencyTradingSnapshot {
    {
      tickAnalytics = analyzeTickData(ticks);
      latencyArbitrage = detectLatencyArbitrage(ticks);
      quoteStuffing = detectQuoteStuffing(ticks);
      momentumIgnition = detectMomentumIgnition(ticks);
    }
  };

  func fillsToTicks(fills : [PhantomExchange.Fill], fallbackMid : Float) : [TickData] {
    if (fills.size() == 0) { return [] };
    Array.tabulate<TickData>(fills.size(), func(i : Nat) : TickData {
      let fill = fills[i];
      let previous = if (i == 0) fallbackMid else fills[i - 1].price;
      let side : TradeSignal = if (fill.price > previous) #buy else if (fill.price < previous) #sell else #hold;
      let spread = Float.max(fill.price * 0.0005, 0.0001);
      {
        timestampMs = fill.fillBeat * 873;
        bid = fill.price - spread;
        ask = fill.price + spread;
        last = fill.price;
        volume = fill.quantity;
        side = side;
        venueLatencyMs = 0.5;
        referencePrice = previous;
        messageType = #trade;
      }
    })
  };

  public func analyzePhantomPair(
    exchangeState : PhantomExchange.PhantomExchangeState,
    intelligenceState : PhantomIntelligence.PhantomIntelligenceState,
    pairId : Text,
    depthLevels : Nat,
    priceSeries : [Float],
    hedgeSeries : [Float],
    optionQuotes : [OptionQuote],
    externalTicks : [TickData],
    executionQuantity : Float,
    executionSlices : Nat,
  ) : ?IntegratedQuantSnapshot {
    switch (buildMarketMicrostructureSnapshot(exchangeState, intelligenceState, pairId, depthLevels)) {
      case null null;
      case (?micro) {
        let statArb = analyzeStatisticalArbitrage(priceSeries, hedgeSeries);
        let volatility = analyzeVolatility(priceSeries, optionQuotes);
        let pairFills = filterFillsByPair(exchangeState.recentFills, pairId);
        let fallbackTicks = fillsToTicks(pairFills, micro.midPrice);
        let ticks = if (externalTicks.size() == 0) fallbackTicks else externalTicks;
        let execution = analyzeExecution(micro, ticks, executionQuantity, executionSlices);
        let hft = analyzeHighFrequencyTrading(ticks);
        ?{
          microstructure = micro;
          statisticalArbitrage = statArb;
          volatility = volatility;
          execution = execution;
          highFrequency = hft;
        }
      }
    }
  };
};
