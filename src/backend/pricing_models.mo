import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {
  let EPS : Float = 0.000001;

  public type SchedulePoint = {
    price : Float;
    quantity : Float;
  };

  public type EquilibriumMarket = {
    marketId : Text;
    currentPrice : Float;
    supply : [SchedulePoint];
    demand : [SchedulePoint];
  };

  public type WalrasianMarket = {
    marketId : Text;
    currentPrice : Float;
    supply : [SchedulePoint];
    demand : [SchedulePoint];
    tatonnementStep : Float;
  };

  public type MarketEquilibrium = {
    marketId : Text;
    equilibriumPrice : Float;
    equilibriumQuantity : Float;
    supplyAtEquilibrium : Float;
    demandAtEquilibrium : Float;
    excessDemand : Float;
  };

  public type WalrasianEquilibrium = {
    markets : [MarketEquilibrium];
    priceVector : [Float];
    aggregateExcessDemand : Float;
    converged : Bool;
    iterations : Nat;
  };

  public type OrderLevel = {
    price : Float;
    quantity : Float;
  };

  public type MarketClearingResult = {
    clearingPrice : Float;
    matchedVolume : Float;
    bidVolume : Float;
    askVolume : Float;
    imbalance : Float;
  };

  public type BilateralTradeInput = {
    buyerValue : Float;
    sellerCost : Float;
    buyerDisagreement : Float;
    sellerDisagreement : Float;
    buyerBargainingPower : Float;
    transactionCost : Float;
    executionProbability : Float;
  };

  public type NashBargainingResult = {
    agreedPrice : Float;
    buyerUtility : Float;
    sellerUtility : Float;
    totalSurplus : Float;
    feasible : Bool;
  };

  public type IndivisibleBid = {
    participant : Text;
    valuation : Float;
  };

  public type IndivisibleAsk = {
    participant : Text;
    cost : Float;
  };

  public type IndivisibleMatch = {
    buyer : Text;
    seller : Text;
    price : Float;
    surplus : Float;
  };

  public type IndivisibleAuctionInput = {
    buyers : [IndivisibleBid];
    sellers : [IndivisibleAsk];
  };

  public type CompetitiveEquilibriumResult = {
    clearingPrice : Float;
    matchedUnits : Nat;
    welfare : Float;
    matches : [IndivisibleMatch];
  };

  public type PricingEquilibriumInput = {
    primaryMarket : EquilibriumMarket;
    walrasianMarkets : [WalrasianMarket];
    bids : [OrderLevel];
    asks : [OrderLevel];
    bilateralTrade : BilateralTradeInput;
    indivisibleAuction : IndivisibleAuctionInput;
  };

  public type PricingEquilibriumResult = {
    supplyDemand : MarketEquilibrium;
    walrasian : WalrasianEquilibrium;
    marketClearing : MarketClearingResult;
    nashBargaining : NashBargainingResult;
    competitiveEquilibrium : CompetitiveEquilibriumResult;
  };

  public type FundamentalInput = {
    normalizedCashFlow : Float;
    bookValue : Float;
    returnOnCapital : Float;
    costOfCapital : Float;
    reinvestmentRate : Float;
    growthRate : Float;
    excessReturnPersistence : Float;
    netCash : Float;
    sharesOutstanding : Float;
  };

  public type FundamentalValuation = {
    enterpriseValue : Float;
    equityValue : Float;
    valuePerShare : Float;
    franchiseValue : Float;
    residualIncomeValue : Float;
  };

  public type CashFlowProjection = {
    period : Float;
    amount : Float;
  };

  public type DCFInput = {
    cashFlows : [CashFlowProjection];
    discountRate : Float;
    terminalGrowthRate : Float;
    netDebt : Float;
    sharesOutstanding : Float;
  };

  public type DCFValuation = {
    enterpriseValue : Float;
    equityValue : Float;
    valuePerShare : Float;
    presentValueCashFlows : Float;
    presentValueTerminal : Float;
  };

  public type ComparableMultiple = {
    name : Text;
    multiple : Float;
    metric : Float;
    weight : Float;
    premiumDiscount : Float;
  };

  public type RelativeValuationInput = {
    comparables : [ComparableMultiple];
    netDebt : Float;
    sharesOutstanding : Float;
  };

  public type RelativeValuation = {
    enterpriseValue : Float;
    equityValue : Float;
    valuePerShare : Float;
    weightedMultiple : Float;
  };

  public type StatePayoff = {
    payoff : Float;
    probability : Float;
  };

  public type RiskNeutralInput = {
    states : [StatePayoff];
    riskFreeRate : Float;
    carryRate : Float;
    timeToMaturity : Float;
  };

  public type RiskNeutralValuation = {
    price : Float;
    expectedPayoff : Float;
    discountFactor : Float;
  };

  public type RealWorldMeasureInput = {
    scenarios : [StatePayoff];
    riskFreeRate : Float;
    timeToMaturity : Float;
    marketPriceOfRisk : Float;
    liquidityPremium : Float;
    riskAversion : Float;
  };

  public type RealWorldValuation = {
    price : Float;
    expectedPayoff : Float;
    certaintyEquivalent : Float;
    riskPremium : Float;
  };

  public type FairValueInput = {
    fundamental : FundamentalInput;
    dcf : DCFInput;
    relative : RelativeValuationInput;
    riskNeutral : RiskNeutralInput;
    realWorld : RealWorldMeasureInput;
  };

  public type FairValueResult = {
    fundamental : FundamentalValuation;
    dcf : DCFValuation;
    relative : RelativeValuation;
    riskNeutral : RiskNeutralValuation;
    realWorld : RealWorldValuation;
  };

  public type OrderFlowObservation = {
    signedVolume : Float;
    priceChange : Float;
    spread : Float;
    inventory : Float;
    holdingTime : Float;
    processingFee : Float;
  };

  public type KylesLambdaResult = {
    lambda : Float;
    intercept : Float;
    explanatoryPower : Float;
  };

  public type GlostenMilgromInput = {
    priorHighProbability : Float;
    highValue : Float;
    lowValue : Float;
    informedTraderProbability : Float;
    signalAccuracy : Float;
    noiseBuyProbability : Float;
  };

  public type GlostenMilgromResult = {
    bid : Float;
    ask : Float;
    mid : Float;
    spread : Float;
    posteriorHighAfterBuy : Float;
    posteriorHighAfterSell : Float;
  };

  public type SpreadDecomposition = {
    quotedSpread : Float;
    adverseSelectionComponent : Float;
    inventoryHoldingComponent : Float;
    orderProcessingComponent : Float;
  };

  public type MicrostructureInput = {
    observations : [OrderFlowObservation];
    glostenMilgrom : GlostenMilgromInput;
    quotedSpread : Float;
    inventoryRiskAversion : Float;
    assetVolatility : Float;
    fundingRate : Float;
    averageTradeSize : Float;
  };

  public type MicrostructureResult = {
    kyleLambda : KylesLambdaResult;
    glostenMilgrom : GlostenMilgromResult;
    adverseSelectionComponent : Float;
    inventoryHoldingCost : Float;
    orderProcessingDecomposition : SpreadDecomposition;
  };

  public type DynamicPricingInput = {
    basePrice : Float;
    baselineDemand : Float;
    currentDemand : Float;
    currentSupply : Float;
    utilization : Float;
    congestionIndex : Float;
    hourOfDay : Nat;
    peakStartHour : Nat;
    peakEndHour : Nat;
    elasticity : Float;
    competitorPrice : Float;
    inventoryPressure : Float;
    priceFloor : Float;
    priceCap : Float;
    phiSensitivity : Float;
  };

  public type DynamicPricingResult = {
    surgePrice : Float;
    congestionPrice : Float;
    timeOfDayPrice : Float;
    demandResponsivePrice : Float;
    phiWeightedPrice : Float;
    surgeMultiplier : Float;
  };

  public type AIAssetPricingInput = {
    baseValue : Float;
    resonanceScore : Float;
    coherenceScore : Float;
    noveltyScore : Float;
    provenanceScore : Float;
    scarcityScore : Float;
    computeUnits : Float;
    utilizationHours : Float;
    reliabilityScore : Float;
    availabilityRatio : Float;
    marginalCostPerUnit : Float;
    activeUsers : Float;
    collaboratorAgents : Float;
    integrationDepth : Float;
    retentionRate : Float;
    accuracyScore : Float;
    safetyScore : Float;
    latencyMs : Float;
    benchmarkCost : Float;
    benchmarkQuality : Float;
    trainingCost : Float;
    refreshCost : Float;
  };

  public type AIAssetPricingResult = {
    cognitiveResonancePrice : Float;
    computeUtilityPrice : Float;
    networkEffectPrice : Float;
    qualityAdjustedPrice : Float;
    compositePrice : Float;
  };

  public type TradePrint = {
    price : Float;
    quantity : Float;
    timestamp : Int;
    informationWeight : Float;
  };

  public type InformationSignal = {
    estimate : Float;
    confidence : Float;
    recencyWeight : Float;
  };

  public type InformationAggregate = {
    estimate : Float;
    aggregateConfidence : Float;
  };

  public type OracleObservation = {
    provider : Text;
    price : Float;
    confidence : Float;
    stakeWeight : Float;
    freshness : Float;
    latencyMs : Float;
  };

  public type OracleAggregation = {
    aggregatedPrice : Float;
    consensusDispersion : Float;
    confidence : Float;
  };

  public type PriceDiscoveryInput = {
    trades : [TradePrint];
    referencePrice : Float;
    microstructureMid : Float;
    fundamentalPrice : Float;
    orderImbalance : Float;
    impactCoefficient : Float;
    signals : [InformationSignal];
    oracles : [OracleObservation];
  };

  public type PriceDiscoveryResult = {
    vwap : Float;
    twap : Float;
    priceFormation : Float;
    informationAggregation : InformationAggregate;
    oracleAggregation : OracleAggregation;
  };

  public type CompositePrice = {
    equilibriumAnchor : Float;
    fairValueAnchor : Float;
    discoveryAnchor : Float;
    dynamicPrice : Float;
    aiCompositePrice : Float;
    finalPrice : Float;
    confidence : Float;
  };

  public type PricingInput = {
    equilibrium : PricingEquilibriumInput;
    fairValue : FairValueInput;
    microstructure : MicrostructureInput;
    dynamicPricing : DynamicPricingInput;
    aiAsset : AIAssetPricingInput;
    discovery : PriceDiscoveryInput;
  };

  public type PricingAnalytics = {
    equilibrium : PricingEquilibriumResult;
    fairValue : FairValueResult;
    microstructure : MicrostructureResult;
    dynamicPricing : DynamicPricingResult;
    aiAsset : AIAssetPricingResult;
    discovery : PriceDiscoveryResult;
    compositePrice : CompositePrice;
  };

  func minFloat(a : Float, b : Float) : Float { if (a < b) { a } else { b } };
  func maxFloat(a : Float, b : Float) : Float { if (a > b) { a } else { b } };
  func clamp(value : Float, low : Float, high : Float) : Float { maxFloat(low, minFloat(high, value)) };
  func safeDiv(numerator : Float, denominator : Float) : Float { if (Float.abs(denominator) <= EPS) { 0.0 } else { numerator / denominator } };

  func sum(xs : [Float]) : Float {
    var total : Float = 0.0;
    for (x in xs.vals()) { total += x };
    total
  };

  func mean(xs : [Float]) : Float {
    if (xs.size() == 0) { 0.0 } else { sum(xs) / xs.size().toFloat() }
  };

  func variance(xs : [Float]) : Float {
    if (xs.size() < 2) { return 0.0 };
    let mu = mean(xs);
    var total : Float = 0.0;
    for (x in xs.vals()) {
      let diff = x - mu;
      total += diff * diff;
    };
    let sampleDenominator = if (xs.size() > 1) { (xs.size() - 1).toFloat() } else { 1.0 };
    total / sampleDenominator
  };

  func covariance(xs : [Float], ys : [Float]) : Float {
    let n = if (xs.size() < ys.size()) { xs.size() } else { ys.size() };
    if (n < 2) { return 0.0 };
    let xTrim = Array.tabulate<Float>(n, func(i) { xs[i] });
    let yTrim = Array.tabulate<Float>(n, func(i) { ys[i] });
    let muX = mean(xTrim);
    let muY = mean(yTrim);
    var total : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      total += (xTrim[i] - muX) * (yTrim[i] - muY);
      i += 1;
    };
    let sampleDenominator = if (n > 1) { (n - 1).toFloat() } else { 1.0 };
    total / sampleDenominator
  };

  func weightedAverage(values : [Float], weights : [Float], fallback : Float) : Float {
    let n = if (values.size() < weights.size()) { values.size() } else { weights.size() };
    if (n == 0) { return fallback };
    var weighted : Float = 0.0;
    var totalWeight : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      let w = maxFloat(weights[i], 0.0);
      weighted += values[i] * w;
      totalWeight += w;
      i += 1;
    };
    if (totalWeight <= EPS) { fallback } else { weighted / totalWeight }
  };

  func normalizeProbabilities(states : [StatePayoff]) : [Float] {
    if (states.size() == 0) { return [] };
    let total = Array.foldLeft<StatePayoff, Float>(states, 0.0, func(acc, state) {
      acc + maxFloat(state.probability, 0.0)
    });
    if (total <= EPS) {
      let w = 1.0 / states.size().toFloat();
      Array.tabulate<Float>(states.size(), func(_) { w })
    } else {
      Array.tabulate<Float>(states.size(), func(i) { maxFloat(states[i].probability, 0.0) / total })
    }
  };

  func sortSchedule(points : [SchedulePoint]) : [SchedulePoint] {
    Array.sort<SchedulePoint>(points, func(a, b) {
      if (a.price < b.price) #less else if (a.price > b.price) #greater else #equal
    })
  };

  func sortOrderLevels(points : [OrderLevel], descending : Bool) : [OrderLevel] {
    Array.sort<OrderLevel>(points, func(a, b) {
      if (descending) {
        if (a.price > b.price) #less else if (a.price < b.price) #greater else #equal
      } else {
        if (a.price < b.price) #less else if (a.price > b.price) #greater else #equal
      }
    })
  };

  func sortTradePrints(trades : [TradePrint]) : [TradePrint] {
    Array.sort<TradePrint>(trades, func(a, b) {
      if (a.timestamp < b.timestamp) #less else if (a.timestamp > b.timestamp) #greater else #equal
    })
  };

  func median(values : [Float], fallback : Float) : Float {
    if (values.size() == 0) { return fallback };
    let sorted = Array.sort<Float>(values, Float.compare);
    let n = sorted.size();
    if (n % 2 == 1) {
      sorted[n / 2]
    } else {
      (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
    }
  };

  func quantityAtPrice(points : [SchedulePoint], price : Float) : Float {
    if (points.size() == 0) { return 0.0 };
    let sorted = sortSchedule(points);
    if (sorted.size() == 1) {
      if (sorted[0].price <= EPS) { return maxFloat(0.0, sorted[0].quantity) };
      return maxFloat(0.0, sorted[0].quantity * clamp(price / sorted[0].price, 0.0, Phi.PHI_2));
    };
    if (price <= sorted[0].price) {
      if (sorted[0].price <= EPS) { return maxFloat(0.0, sorted[0].quantity) };
      return maxFloat(0.0, sorted[0].quantity * clamp(price / sorted[0].price, 0.0, 1.0));
    };
    let last = sorted[sorted.size() - 1];
    if (price >= last.price) { return maxFloat(0.0, last.quantity) };
    var i : Nat = 0;
    while (i + 1 < sorted.size()) {
      let left = sorted[i];
      let right = sorted[i + 1];
      if (price >= left.price and price <= right.price) {
        let slope = safeDiv(right.quantity - left.quantity, right.price - left.price);
        return maxFloat(0.0, left.quantity + slope * (price - left.price));
      };
      i += 1;
    };
    maxFloat(0.0, last.quantity)
  };

  func marketStateAtPrice(market : { marketId : Text; supply : [SchedulePoint]; demand : [SchedulePoint] }, price : Float) : MarketEquilibrium {
    let supplyAt = quantityAtPrice(market.supply, price);
    let demandAt = quantityAtPrice(market.demand, price);
    {
      marketId = market.marketId;
      equilibriumPrice = price;
      equilibriumQuantity = minFloat(supplyAt, demandAt);
      supplyAtEquilibrium = supplyAt;
      demandAtEquilibrium = demandAt;
      excessDemand = demandAt - supplyAt;
    }
  };

  public func supplyDemandEquilibrium(market : EquilibriumMarket) : MarketEquilibrium {
    let supplySorted = sortSchedule(market.supply);
    let demandSorted = sortSchedule(market.demand);
    if (supplySorted.size() == 0 or demandSorted.size() == 0) {
      return {
        marketId = market.marketId;
        equilibriumPrice = maxFloat(market.currentPrice, EPS);
        equilibriumQuantity = 0.0;
        supplyAtEquilibrium = 0.0;
        demandAtEquilibrium = 0.0;
        excessDemand = 0.0;
      };
    };
    var low : Float = 0.0;
    var high : Float = maxFloat(maxFloat(supplySorted[supplySorted.size() - 1].price, demandSorted[demandSorted.size() - 1].price), maxFloat(market.currentPrice, EPS) * Phi.PHI_2);
    var best = marketStateAtPrice({ marketId = market.marketId; supply = supplySorted; demand = demandSorted }, maxFloat(market.currentPrice, EPS));
    var i : Nat = 0;
    while (i < 48) {
      let mid = (low + high) / 2.0;
      let state = marketStateAtPrice({ marketId = market.marketId; supply = supplySorted; demand = demandSorted }, mid);
      if (Float.abs(state.excessDemand) < Float.abs(best.excessDemand)) { best := state };
      if (state.excessDemand > 0.0) {
        low := mid;
      } else {
        high := mid;
      };
      i += 1;
    };
    best
  };

  public func walrasianEquilibrium(markets : [WalrasianMarket], maxIterations : Nat, tolerance : Float) : WalrasianEquilibrium {
    if (markets.size() == 0) {
      return { markets = []; priceVector = []; aggregateExcessDemand = 0.0; converged = true; iterations = 0 };
    };
    let prices = Array.toVarArray<Float>(Array.tabulate<Float>(markets.size(), func(i) { maxFloat(markets[i].currentPrice, EPS) }));
    var currentStates = Array.tabulate<MarketEquilibrium>(markets.size(), func(i) {
      marketStateAtPrice({ marketId = markets[i].marketId; supply = markets[i].supply; demand = markets[i].demand }, prices[i])
    });
    var iter : Nat = 0;
    var converged = false;
    while (iter < maxIterations and not converged) {
      var maxExcess : Float = 0.0;
      currentStates := Array.tabulate<MarketEquilibrium>(markets.size(), func(i) {
        marketStateAtPrice({ marketId = markets[i].marketId; supply = markets[i].supply; demand = markets[i].demand }, prices[i])
      });
      var i : Nat = 0;
      while (i < markets.size()) {
        let state = currentStates[i];
        maxExcess := maxFloat(maxExcess, Float.abs(state.excessDemand));
        let scale = safeDiv(state.excessDemand, maxFloat(state.equilibriumQuantity, 1.0));
        let step = maxFloat(markets[i].tatonnementStep, Phi.PHI_INV_5);
        prices[i] := maxFloat(EPS, prices[i] * (1.0 + step * scale));
        i += 1;
      };
      converged := maxExcess <= tolerance;
      iter += 1;
    };
    currentStates := Array.tabulate<MarketEquilibrium>(markets.size(), func(i) {
      marketStateAtPrice({ marketId = markets[i].marketId; supply = markets[i].supply; demand = markets[i].demand }, prices[i])
    });
    {
      markets = currentStates;
      priceVector = Array.tabulate<Float>(prices.size(), func(i) { prices[i] });
      aggregateExcessDemand = Array.foldLeft<MarketEquilibrium, Float>(currentStates, 0.0, func(acc, item) {
        acc + Float.abs(item.excessDemand)
      });
      converged = converged;
      iterations = iter;
    }
  };

  public func marketClearingPrice(bids : [OrderLevel], asks : [OrderLevel]) : MarketClearingResult {
    if (bids.size() == 0 or asks.size() == 0) {
      return { clearingPrice = 0.0; matchedVolume = 0.0; bidVolume = 0.0; askVolume = 0.0; imbalance = 0.0 };
    };
    let sortedBids = sortOrderLevels(bids, true);
    let sortedAsks = sortOrderLevels(asks, false);
    let prices = Array.concat<Float>(
      Array.map<OrderLevel, Float>(sortedBids, func(level) { level.price }),
      Array.map<OrderLevel, Float>(sortedAsks, func(level) { level.price })
    );
    let candidates = Array.sort<Float>(prices, Float.compare);
    let referenceMid = (sortedBids[0].price + sortedAsks[0].price) / 2.0;
    var best = { clearingPrice = referenceMid; matchedVolume = 0.0; bidVolume = 0.0; askVolume = 0.0; imbalance = 0.0 };
    for (candidate in candidates.vals()) {
      let bidVolume = Array.foldLeft<OrderLevel, Float>(sortedBids, 0.0, func(acc, level) {
        if (level.price >= candidate) { acc + maxFloat(level.quantity, 0.0) } else { acc }
      });
      let askVolume = Array.foldLeft<OrderLevel, Float>(sortedAsks, 0.0, func(acc, level) {
        if (level.price <= candidate) { acc + maxFloat(level.quantity, 0.0) } else { acc }
      });
      let matched = minFloat(bidVolume, askVolume);
      let imbalance = bidVolume - askVolume;
      let better = matched > best.matchedVolume + EPS or (
        Float.abs(matched - best.matchedVolume) <= EPS and Float.abs(imbalance) < Float.abs(best.imbalance)
      ) or (
        Float.abs(matched - best.matchedVolume) <= EPS and Float.abs(Float.abs(imbalance) - Float.abs(best.imbalance)) <= EPS and Float.abs(candidate - referenceMid) < Float.abs(best.clearingPrice - referenceMid)
      );
      if (better) {
        best := { clearingPrice = candidate; matchedVolume = matched; bidVolume = bidVolume; askVolume = askVolume; imbalance = imbalance };
      };
    };
    best
  };

  public func nashBargainingSolution(input : BilateralTradeInput) : NashBargainingResult {
    let buyerPower = clamp(input.buyerBargainingPower, 0.0, 1.0);
    let feasibleSurplus = (input.buyerValue - input.buyerDisagreement) - (input.sellerCost + input.sellerDisagreement + input.transactionCost);
    if (feasibleSurplus <= EPS or input.executionProbability <= EPS) {
      return {
        agreedPrice = 0.0;
        buyerUtility = 0.0;
        sellerUtility = 0.0;
        totalSurplus = 0.0;
        feasible = false;
      };
    };
    let adjustedBuyerValue = input.buyerValue - input.transactionCost;
    let agreedPrice = clamp(
      (1.0 - buyerPower) * (adjustedBuyerValue - input.buyerDisagreement) + buyerPower * (input.sellerCost + input.sellerDisagreement),
      input.sellerCost + input.sellerDisagreement,
      adjustedBuyerValue - input.buyerDisagreement,
    );
    let buyerUtility = maxFloat(0.0, (input.buyerValue - agreedPrice - input.transactionCost - input.buyerDisagreement) * input.executionProbability);
    let sellerUtility = maxFloat(0.0, (agreedPrice - input.sellerCost - input.sellerDisagreement) * input.executionProbability);
    {
      agreedPrice = agreedPrice;
      buyerUtility = buyerUtility;
      sellerUtility = sellerUtility;
      totalSurplus = buyerUtility + sellerUtility;
      feasible = true;
    }
  };

  public func competitiveEquilibriumWithIndivisibilities(input : IndivisibleAuctionInput) : CompetitiveEquilibriumResult {
    if (input.buyers.size() == 0 or input.sellers.size() == 0) {
      return { clearingPrice = 0.0; matchedUnits = 0; welfare = 0.0; matches = [] };
    };
    let buyers = Array.sort<IndivisibleBid>(input.buyers, func(a, b) {
      if (a.valuation > b.valuation) #less else if (a.valuation < b.valuation) #greater else #equal
    });
    let sellers = Array.sort<IndivisibleAsk>(input.sellers, func(a, b) {
      if (a.cost < b.cost) #less else if (a.cost > b.cost) #greater else #equal
    });
    var matched : Nat = 0;
    var welfare : Float = 0.0;
    var lastBuyerValue : Float = 0.0;
    var lastSellerCost : Float = 0.0;
    let limit = if (buyers.size() < sellers.size()) { buyers.size() } else { sellers.size() };
    while (matched < limit and buyers[matched].valuation >= sellers[matched].cost) {
      welfare += buyers[matched].valuation - sellers[matched].cost;
      lastBuyerValue := buyers[matched].valuation;
      lastSellerCost := sellers[matched].cost;
      matched += 1;
    };
    if (matched == 0) {
      return { clearingPrice = 0.0; matchedUnits = 0; welfare = 0.0; matches = [] };
    };
    let nextBuyerBound = if (matched < buyers.size()) { buyers[matched].valuation } else { lastBuyerValue };
    let nextSellerBound = if (matched < sellers.size()) { sellers[matched].cost } else { lastSellerCost };
    let lower = maxFloat(lastSellerCost, nextSellerBound);
    let upper = minFloat(lastBuyerValue, nextBuyerBound);
    let clearingPrice = if (lower <= upper) {
      (lower + upper) / 2.0
    } else {
      clamp((lastBuyerValue + lastSellerCost) / 2.0, lastSellerCost, lastBuyerValue)
    };
    {
      clearingPrice = clearingPrice;
      matchedUnits = matched;
      welfare = welfare;
      matches = Array.tabulate<IndivisibleMatch>(matched, func(i) {
        {
          buyer = buyers[i].participant;
          seller = sellers[i].participant;
          price = clearingPrice;
          surplus = buyers[i].valuation - sellers[i].cost;
        }
      });
    }
  };

  public func fundamentalValuation(input : FundamentalInput) : FundamentalValuation {
    let sustainableGrowth = clamp(input.growthRate * (1.0 + input.reinvestmentRate) / 2.0, -0.50, input.costOfCapital - EPS);
    let continuingCash = input.normalizedCashFlow * (1.0 + sustainableGrowth);
    let goingConcernValue = continuingCash / maxFloat(input.costOfCapital - sustainableGrowth, EPS);
    let residualSpread = input.returnOnCapital - input.costOfCapital;
    let residualIncomePV = if (residualSpread <= 0.0) {
      0.0
    } else {
      input.bookValue * residualSpread * maxFloat(input.excessReturnPersistence, Phi.PHI_INV_3) / maxFloat(input.costOfCapital - sustainableGrowth, EPS)
    };
    let franchiseValue = maxFloat(0.0, residualIncomePV * input.excessReturnPersistence);
    let enterpriseValue = maxFloat(0.0, 0.5 * goingConcernValue + 0.5 * (input.bookValue + residualIncomePV + franchiseValue));
    let equityValue = enterpriseValue + input.netCash;
    {
      enterpriseValue = enterpriseValue;
      equityValue = equityValue;
      valuePerShare = equityValue / maxFloat(input.sharesOutstanding, 1.0);
      franchiseValue = franchiseValue;
      residualIncomeValue = input.bookValue + residualIncomePV;
    }
  };

  public func discountedCashFlow(input : DCFInput) : DCFValuation {
    if (input.cashFlows.size() == 0) {
      return { enterpriseValue = 0.0; equityValue = -input.netDebt; valuePerShare = safeDiv(-input.netDebt, maxFloat(input.sharesOutstanding, 1.0)); presentValueCashFlows = 0.0; presentValueTerminal = 0.0 };
    };
    let rate = maxFloat(input.discountRate, EPS);
    var pvCashFlows : Float = 0.0;
    for (flow in input.cashFlows.vals()) {
      pvCashFlows += flow.amount / Float.pow(1.0 + rate, maxFloat(flow.period, 0.0));
    };
    let last = input.cashFlows[input.cashFlows.size() - 1];
    let stableGrowth = clamp(input.terminalGrowthRate, -0.50, rate - EPS);
    let terminalCash = last.amount * (1.0 + stableGrowth);
    let terminalValue = terminalCash / maxFloat(rate - stableGrowth, EPS);
    let pvTerminal = terminalValue / Float.pow(1.0 + rate, maxFloat(last.period, 0.0));
    let enterpriseValue = pvCashFlows + pvTerminal;
    let equityValue = enterpriseValue - input.netDebt;
    {
      enterpriseValue = enterpriseValue;
      equityValue = equityValue;
      valuePerShare = equityValue / maxFloat(input.sharesOutstanding, 1.0);
      presentValueCashFlows = pvCashFlows;
      presentValueTerminal = pvTerminal;
    }
  };

  public func relativeValuation(input : RelativeValuationInput) : RelativeValuation {
    if (input.comparables.size() == 0) {
      return { enterpriseValue = 0.0; equityValue = -input.netDebt; valuePerShare = safeDiv(-input.netDebt, maxFloat(input.sharesOutstanding, 1.0)); weightedMultiple = 0.0 };
    };
    var totalWeight : Float = 0.0;
    var enterpriseValue : Float = 0.0;
    var weightedMultiple : Float = 0.0;
    for (comp in input.comparables.vals()) {
      let weight = maxFloat(comp.weight, Phi.PHI_INV_5);
      let adjustedMultiple = comp.multiple * (1.0 + comp.premiumDiscount);
      enterpriseValue += adjustedMultiple * comp.metric * weight;
      weightedMultiple += adjustedMultiple * weight;
      totalWeight += weight;
    };
    let normalizedEnterprise = safeDiv(enterpriseValue, totalWeight);
    let equityValue = normalizedEnterprise - input.netDebt;
    {
      enterpriseValue = normalizedEnterprise;
      equityValue = equityValue;
      valuePerShare = equityValue / maxFloat(input.sharesOutstanding, 1.0);
      weightedMultiple = safeDiv(weightedMultiple, totalWeight);
    }
  };

  public func riskNeutralValuation(input : RiskNeutralInput) : RiskNeutralValuation {
    let normalized = normalizeProbabilities(input.states);
    var expectedPayoff : Float = 0.0;
    var i : Nat = 0;
    while (i < input.states.size()) {
      expectedPayoff += input.states[i].payoff * normalized[i];
      i += 1;
    };
    let discountFactor = Float.exp(-(input.riskFreeRate - input.carryRate) * maxFloat(input.timeToMaturity, 0.0));
    {
      price = expectedPayoff * discountFactor;
      expectedPayoff = expectedPayoff;
      discountFactor = discountFactor;
    }
  };

  public func realWorldMeasurePricing(input : RealWorldMeasureInput) : RealWorldValuation {
    let normalized = normalizeProbabilities(input.scenarios);
    var expectedPayoff : Float = 0.0;
    let payoffs : [Float] = Array.tabulate<Float>(input.scenarios.size(), func(i) { input.scenarios[i].payoff });
    var i : Nat = 0;
    while (i < input.scenarios.size()) {
      expectedPayoff += input.scenarios[i].payoff * normalized[i];
      i += 1;
    };
    let payoffVariance = variance(payoffs);
    let riskPremium = input.marketPriceOfRisk * Float.sqrt(maxFloat(payoffVariance, 0.0)) + input.liquidityPremium;
    let certaintyEquivalent = maxFloat(0.0, expectedPayoff - 0.5 * maxFloat(input.riskAversion, 0.0) * payoffVariance);
    let discountRate = input.riskFreeRate + riskPremium;
    {
      price = certaintyEquivalent * Float.exp(-discountRate * maxFloat(input.timeToMaturity, 0.0));
      expectedPayoff = expectedPayoff;
      certaintyEquivalent = certaintyEquivalent;
      riskPremium = riskPremium;
    }
  };

  public func kylesLambdaModel(observations : [OrderFlowObservation]) : KylesLambdaResult {
    if (observations.size() < 2) {
      return { lambda = 0.0; intercept = 0.0; explanatoryPower = 0.0 };
    };
    let signedVolume = Array.map<OrderFlowObservation, Float>(observations, func(obs) { obs.signedVolume });
    let priceChange = Array.map<OrderFlowObservation, Float>(observations, func(obs) { obs.priceChange });
    let volumeVariance = variance(signedVolume);
    let lambda = if (volumeVariance <= EPS) { 0.0 } else { covariance(priceChange, signedVolume) / volumeVariance };
    let intercept = mean(priceChange) - lambda * mean(signedVolume);
    let priceVariance = variance(priceChange);
    let explanatoryPower = if (volumeVariance <= EPS or priceVariance <= EPS) {
      0.0
    } else {
      let corr = covariance(priceChange, signedVolume) / Float.sqrt(maxFloat(volumeVariance * priceVariance, EPS));
      clamp(corr * corr, 0.0, 1.0)
    };
    { lambda = lambda; intercept = intercept; explanatoryPower = explanatoryPower }
  };

  public func glostenMilgromModel(input : GlostenMilgromInput) : GlostenMilgromResult {
    let prior = clamp(input.priorHighProbability, 0.0, 1.0);
    let alpha = clamp(input.informedTraderProbability, 0.0, 1.0);
    let signalAccuracy = clamp(input.signalAccuracy, 0.5, 1.0);
    let noiseBuy = clamp(input.noiseBuyProbability, 0.0, 1.0);
    let probBuyGivenHigh = alpha * signalAccuracy + (1.0 - alpha) * noiseBuy;
    let probBuyGivenLow = alpha * (1.0 - signalAccuracy) + (1.0 - alpha) * noiseBuy;
    let probSellGivenHigh = alpha * (1.0 - signalAccuracy) + (1.0 - alpha) * (1.0 - noiseBuy);
    let probSellGivenLow = alpha * signalAccuracy + (1.0 - alpha) * (1.0 - noiseBuy);
    let posteriorBuyNumerator = prior * probBuyGivenHigh;
    let posteriorBuyDenominator = posteriorBuyNumerator + (1.0 - prior) * probBuyGivenLow;
    let posteriorSellNumerator = prior * probSellGivenHigh;
    let posteriorSellDenominator = posteriorSellNumerator + (1.0 - prior) * probSellGivenLow;
    let posteriorHighAfterBuy = safeDiv(posteriorBuyNumerator, posteriorBuyDenominator);
    let posteriorHighAfterSell = safeDiv(posteriorSellNumerator, posteriorSellDenominator);
    let ask = posteriorHighAfterBuy * input.highValue + (1.0 - posteriorHighAfterBuy) * input.lowValue;
    let bid = posteriorHighAfterSell * input.highValue + (1.0 - posteriorHighAfterSell) * input.lowValue;
    let mid = prior * input.highValue + (1.0 - prior) * input.lowValue;
    {
      bid = bid;
      ask = ask;
      mid = mid;
      spread = maxFloat(0.0, ask - bid);
      posteriorHighAfterBuy = posteriorHighAfterBuy;
      posteriorHighAfterSell = posteriorHighAfterSell;
    }
  };

  public func adverseSelectionComponent(result : GlostenMilgromResult) : Float {
    maxFloat(0.0, ((result.ask - result.mid) + (result.mid - result.bid)) / 2.0)
  };

  public func inventoryHoldingCost(
    observations : [OrderFlowObservation],
    inventoryRiskAversion : Float,
    assetVolatility : Float,
    fundingRate : Float,
  ) : Float {
    if (observations.size() == 0) { return 0.0 };
    let avgInventory = Array.foldLeft<OrderFlowObservation, Float>(observations, 0.0, func(acc, obs) {
      acc + Float.abs(obs.inventory)
    }) / observations.size().toFloat();
    let avgHoldingTime = Array.foldLeft<OrderFlowObservation, Float>(observations, 0.0, func(acc, obs) {
      acc + maxFloat(obs.holdingTime, 0.0)
    }) / observations.size().toFloat();
    inventoryRiskAversion * assetVolatility * assetVolatility * avgInventory * maxFloat(avgHoldingTime, 1.0) + fundingRate * avgInventory * maxFloat(avgHoldingTime, 1.0)
  };

  public func orderProcessingCostDecomposition(input : MicrostructureInput) : SpreadDecomposition {
    let gm = glostenMilgromModel(input.glostenMilgrom);
    let adverse = adverseSelectionComponent(gm);
    let rawInventoryCost = inventoryHoldingCost(input.observations, input.inventoryRiskAversion, input.assetVolatility, input.fundingRate);
    let inventoryComponent = safeDiv(rawInventoryCost, maxFloat(input.averageTradeSize, 1.0));
    let observedSpread = if (input.quotedSpread > EPS) {
      input.quotedSpread
    } else if (input.observations.size() == 0) {
      gm.spread
    } else {
      Array.foldLeft<OrderFlowObservation, Float>(input.observations, 0.0, func(acc, obs) { acc + maxFloat(obs.spread, 0.0) }) / input.observations.size().toFloat()
    };
    let halfSpread = observedSpread / 2.0;
    let processingHalf = maxFloat(0.0, halfSpread - adverse - inventoryComponent);
    {
      quotedSpread = observedSpread;
      adverseSelectionComponent = adverse * 2.0;
      inventoryHoldingComponent = inventoryComponent * 2.0;
      orderProcessingComponent = processingHalf * 2.0;
    }
  };

  func hourWithinPeak(hour : Nat, startHour : Nat, endHour : Nat) : Bool {
    if (startHour <= endHour) {
      hour >= startHour and hour <= endHour
    } else {
      hour >= startHour or hour <= endHour
    }
  };

  public func surgePricing(input : DynamicPricingInput) : { price : Float; multiplier : Float } {
    let demandSupplyRatio = safeDiv(maxFloat(input.currentDemand, 0.0), maxFloat(input.currentSupply, 1.0));
    let utilizationPressure = maxFloat(input.utilization - 1.0, 0.0);
    let multiplier = clamp(1.0 + Float.log(maxFloat(demandSupplyRatio, 1.0)) * maxFloat(input.phiSensitivity, Phi.PHI_INV_5) + utilizationPressure * Phi.PHI_INV, 1.0, 1.0 + Phi.PHI);
    {
      price = clamp(input.basePrice * multiplier, input.priceFloor, input.priceCap);
      multiplier = multiplier;
    }
  };

  public func congestionPricing(input : DynamicPricingInput) : Float {
    let multiplier = 1.0 + maxFloat(input.congestionIndex, 0.0) * Phi.PHI_INV + maxFloat(input.utilization - 1.0, 0.0) * maxFloat(input.elasticity, Phi.PHI_INV_5);
    clamp(input.basePrice * multiplier, input.priceFloor, input.priceCap)
  };

  public func timeOfDayPricing(input : DynamicPricingInput) : Float {
    let peak = hourWithinPeak(input.hourOfDay, input.peakStartHour, input.peakEndHour);
    let multiplier = if (peak) {
      1.0 + Phi.PHI_INV_2 + maxFloat(input.utilization - 1.0, 0.0) * Phi.PHI_INV_3
    } else if (input.hourOfDay < 6) {
      maxFloat(0.5, 1.0 - Phi.PHI_INV_4)
    } else {
      1.0 + Phi.PHI_INV_5 * maxFloat(input.congestionIndex, 0.0)
    };
    clamp(input.basePrice * multiplier, input.priceFloor, input.priceCap)
  };

  public func demandResponsivePricing(input : DynamicPricingInput) : Float {
    let demandGap = safeDiv(input.currentDemand - input.baselineDemand, maxFloat(input.baselineDemand, 1.0));
    let internalPrice = input.basePrice * (1.0 + demandGap * maxFloat(input.elasticity, 0.0) - input.inventoryPressure * Phi.PHI_INV_4);
    let blended = 0.7 * internalPrice + 0.3 * maxFloat(input.competitorPrice, input.basePrice);
    clamp(blended, input.priceFloor, input.priceCap)
  };

  public func phiWeightedDynamicAdjustment(input : DynamicPricingInput) : DynamicPricingResult {
    let surge = surgePricing(input);
    let congestion = congestionPricing(input);
    let tod = timeOfDayPricing(input);
    let demandResponsive = demandResponsivePricing(input);
    let weighted = weightedAverage(
      [surge.price, congestion, tod, demandResponsive],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3],
      input.basePrice,
    );
    let inventorySkew = 1.0 - input.inventoryPressure * Phi.PHI_INV_5 + maxFloat(input.phiSensitivity, 0.0) * Phi.PHI_INV_5;
    let phiWeighted = clamp(weighted * inventorySkew, input.priceFloor, input.priceCap);
    {
      surgePrice = surge.price;
      congestionPrice = congestion;
      timeOfDayPrice = tod;
      demandResponsivePrice = demandResponsive;
      phiWeightedPrice = phiWeighted;
      surgeMultiplier = surge.multiplier;
    }
  };

  public func cognitiveResonancePricing(input : AIAssetPricingInput) : Float {
    let resonanceIndex = weightedAverage(
      [input.resonanceScore, input.coherenceScore, input.noveltyScore, input.provenanceScore],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3],
      0.0,
    );
    let scarcityPremium = 1.0 + maxFloat(input.scarcityScore, 0.0) * Phi.PHI_INV;
    maxFloat(0.0, input.baseValue * (1.0 + resonanceIndex) * scarcityPremium)
  };

  public func computeUtilityBasedPricing(input : AIAssetPricingInput) : Float {
    let utilityIntensity = Float.sqrt(maxFloat(input.utilizationHours, 0.0) + 1.0) * (0.5 + 0.5 * clamp(input.reliabilityScore, 0.0, 1.0));
    let scarcity = safeDiv(1.0, maxFloat(input.availabilityRatio, EPS));
    let baseCost = maxFloat(input.computeUnits, 0.0) * maxFloat(input.marginalCostPerUnit, 0.0);
    maxFloat(0.0, baseCost * (1.0 + utilityIntensity * scarcity * Phi.PHI_INV_3))
  };

  public func networkEffectPricing(input : AIAssetPricingInput) : Float {
    let userTerm = Float.log(1.0 + maxFloat(input.activeUsers, 0.0)) * clamp(input.retentionRate, 0.0, 1.0);
    let collaborationTerm = Float.sqrt(1.0 + maxFloat(input.collaboratorAgents, 0.0)) * maxFloat(input.integrationDepth, 0.0) * Phi.PHI_INV_4;
    maxFloat(0.0, input.baseValue * (1.0 + userTerm + collaborationTerm))
  };

  public func qualityAdjustedPricing(input : AIAssetPricingInput) : Float {
    let latencyAdjustment = safeDiv(1.0, 1.0 + maxFloat(input.latencyMs, 0.0) / 1000.0);
    let qualityIndex = weightedAverage(
      [input.accuracyScore, input.safetyScore, latencyAdjustment],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2],
      0.0,
    );
    let benchmarkAnchor = if (input.benchmarkQuality <= EPS) {
      input.benchmarkCost * qualityIndex
    } else {
      input.benchmarkCost * safeDiv(qualityIndex, input.benchmarkQuality)
    };
    let supportCost = (maxFloat(input.trainingCost, 0.0) + maxFloat(input.refreshCost, 0.0)) * Phi.PHI_INV_5;
    maxFloat(0.0, benchmarkAnchor + supportCost)
  };

  public func aiAssetPricing(input : AIAssetPricingInput) : AIAssetPricingResult {
    let cognitive = cognitiveResonancePricing(input);
    let utility = computeUtilityBasedPricing(input);
    let network = networkEffectPricing(input);
    let quality = qualityAdjustedPricing(input);
    {
      cognitiveResonancePrice = cognitive;
      computeUtilityPrice = utility;
      networkEffectPrice = network;
      qualityAdjustedPrice = quality;
      compositePrice = weightedAverage(
        [cognitive, utility, network, quality],
        [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3],
        input.baseValue,
      );
    }
  };

  public func vwap(trades : [TradePrint], fallback : Float) : Float {
    if (trades.size() == 0) { return fallback };
    var numerator : Float = 0.0;
    var denominator : Float = 0.0;
    for (trade in trades.vals()) {
      let qty = maxFloat(trade.quantity, 0.0);
      numerator += trade.price * qty;
      denominator += qty;
    };
    if (denominator <= EPS) { fallback } else { numerator / denominator }
  };

  public func twap(trades : [TradePrint], fallback : Float) : Float {
    if (trades.size() == 0) { return fallback };
    let sorted = sortTradePrints(trades);
    if (sorted.size() == 1) { return sorted[0].price };
    var weighted : Float = 0.0;
    var totalTime : Float = 0.0;
    var i : Nat = 0;
    while (i < sorted.size()) {
      let current = sorted[i];
      let duration = if (i + 1 < sorted.size()) {
        maxFloat((sorted[i + 1].timestamp - current.timestamp).toFloat(), 1.0)
      } else {
        if (i == 0) { 1.0 } else { maxFloat((current.timestamp - sorted[i - 1].timestamp).toFloat(), 1.0) }
      };
      weighted += current.price * duration;
      totalTime += duration;
      i += 1;
    };
    if (totalTime <= EPS) { fallback } else { weighted / totalTime }
  };

  public func informationAggregation(signals : [InformationSignal], fallback : Float) : InformationAggregate {
    if (signals.size() == 0) {
      return { estimate = fallback; aggregateConfidence = 0.0 };
    };
    var weightedEstimate : Float = 0.0;
    var totalWeight : Float = 0.0;
    for (signal in signals.vals()) {
      let weight = maxFloat(signal.confidence, 0.0) * maxFloat(signal.recencyWeight, Phi.PHI_INV_5);
      weightedEstimate += signal.estimate * weight;
      totalWeight += weight;
    };
    {
      estimate = if (totalWeight <= EPS) { fallback } else { weightedEstimate / totalWeight };
      aggregateConfidence = clamp(safeDiv(totalWeight, signals.size().toFloat() * Phi.PHI), 0.0, 1.0);
    }
  };

  public func oraclePriceAggregation(oracles : [OracleObservation], fallback : Float) : OracleAggregation {
    if (oracles.size() == 0) {
      return { aggregatedPrice = fallback; consensusDispersion = 0.0; confidence = 0.0 };
    };
    let prices = Array.map<OracleObservation, Float>(oracles, func(oracle) { oracle.price });
    let center = median(prices, fallback);
    var weightedPrice : Float = 0.0;
    var totalWeight : Float = 0.0;
    let adjustedPrices = Array.map<OracleObservation, Float>(oracles, func(oracle) { oracle.price });
    for (oracle in oracles.vals()) {
      let latencyPenalty = 1.0 + maxFloat(oracle.latencyMs, 0.0) / 1000.0;
      let baseWeight = maxFloat(oracle.confidence, 0.0) * maxFloat(oracle.stakeWeight, 0.0) * maxFloat(oracle.freshness, 0.0) / latencyPenalty;
      let deviation = safeDiv(Float.abs(oracle.price - center), maxFloat(center, EPS));
      let weight = safeDiv(baseWeight, 1.0 + deviation * Phi.PHI_2);
      weightedPrice += oracle.price * weight;
      totalWeight += weight;
    };
    let aggregated = if (totalWeight <= EPS) { center } else { weightedPrice / totalWeight };
    let dispersion = Float.sqrt(maxFloat(variance(adjustedPrices), 0.0));
    {
      aggregatedPrice = aggregated;
      consensusDispersion = dispersion;
      confidence = clamp(safeDiv(totalWeight, oracles.size().toFloat() * Phi.PHI) * safeDiv(1.0, 1.0 + safeDiv(dispersion, maxFloat(aggregated, EPS))), 0.0, 1.0);
    }
  };

  public func priceFormationModel(input : PriceDiscoveryInput) : Float {
    let vwapPrice = vwap(input.trades, input.referencePrice);
    let twapPrice = twap(input.trades, input.referencePrice);
    let signalAggregate = informationAggregation(input.signals, input.referencePrice);
    let oracleAggregate = oraclePriceAggregation(input.oracles, input.referencePrice);
    let base = weightedAverage(
      [vwapPrice, twapPrice, signalAggregate.estimate, oracleAggregate.aggregatedPrice, input.microstructureMid, input.fundamentalPrice],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_2, Phi.PHI_INV_3, Phi.PHI_INV],
      input.referencePrice,
    );
    let imbalanceAdjustment = input.impactCoefficient * input.orderImbalance * maxFloat(input.referencePrice, EPS) * Phi.PHI_INV_5;
    maxFloat(0.0, base + imbalanceAdjustment)
  };

  public func priceDiscovery(input : PriceDiscoveryInput) : PriceDiscoveryResult {
    let vwapPrice = vwap(input.trades, input.referencePrice);
    let twapPrice = twap(input.trades, input.referencePrice);
    let infoAggregate = informationAggregation(input.signals, input.referencePrice);
    let oracleAggregate = oraclePriceAggregation(input.oracles, input.referencePrice);
    {
      vwap = vwapPrice;
      twap = twapPrice;
      priceFormation = priceFormationModel(input);
      informationAggregation = infoAggregate;
      oracleAggregation = oracleAggregate;
    }
  };

  public func computeEquilibriumPricing(input : PricingEquilibriumInput) : PricingEquilibriumResult {
    {
      supplyDemand = supplyDemandEquilibrium(input.primaryMarket);
      walrasian = walrasianEquilibrium(input.walrasianMarkets, 64, Phi.PHI_INV_4);
      marketClearing = marketClearingPrice(input.bids, input.asks);
      nashBargaining = nashBargainingSolution(input.bilateralTrade);
      competitiveEquilibrium = competitiveEquilibriumWithIndivisibilities(input.indivisibleAuction);
    }
  };

  public func computeFairValueModels(input : FairValueInput) : FairValueResult {
    {
      fundamental = fundamentalValuation(input.fundamental);
      dcf = discountedCashFlow(input.dcf);
      relative = relativeValuation(input.relative);
      riskNeutral = riskNeutralValuation(input.riskNeutral);
      realWorld = realWorldMeasurePricing(input.realWorld);
    }
  };

  public func computeMarketMicrostructurePricing(input : MicrostructureInput) : MicrostructureResult {
    let gm = glostenMilgromModel(input.glostenMilgrom);
    {
      kyleLambda = kylesLambdaModel(input.observations);
      glostenMilgrom = gm;
      adverseSelectionComponent = adverseSelectionComponent(gm);
      inventoryHoldingCost = inventoryHoldingCost(input.observations, input.inventoryRiskAversion, input.assetVolatility, input.fundingRate);
      orderProcessingDecomposition = orderProcessingCostDecomposition(input);
    }
  };

  public func computeDynamicPricing(input : DynamicPricingInput) : DynamicPricingResult {
    phiWeightedDynamicAdjustment(input)
  };

  public func computeAIAssetPricing(input : AIAssetPricingInput) : AIAssetPricingResult {
    aiAssetPricing(input)
  };

  public func computePriceDiscovery(input : PriceDiscoveryInput) : PriceDiscoveryResult {
    priceDiscovery(input)
  };

  public func computeCompositePrice(input : PricingInput) : CompositePrice {
    let equilibrium = computeEquilibriumPricing(input.equilibrium);
    let fairValue = computeFairValueModels(input.fairValue);
    let dynamicPricing = computeDynamicPricing(input.dynamicPricing);
    let ai = computeAIAssetPricing(input.aiAsset);
    let discovery = computePriceDiscovery(input.discovery);
    let equilibriumAnchor = weightedAverage(
      [equilibrium.supplyDemand.equilibriumPrice, equilibrium.marketClearing.clearingPrice, equilibrium.nashBargaining.agreedPrice, equilibrium.competitiveEquilibrium.clearingPrice],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3],
      equilibrium.supplyDemand.equilibriumPrice,
    );
    let fairAnchor = weightedAverage(
      [fairValue.fundamental.valuePerShare, fairValue.dcf.valuePerShare, fairValue.relative.valuePerShare, fairValue.riskNeutral.price, fairValue.realWorld.price],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3, Phi.PHI_INV_4],
      fairValue.fundamental.valuePerShare,
    );
    let discoveryAnchor = weightedAverage(
      [discovery.vwap, discovery.twap, discovery.priceFormation, discovery.oracleAggregation.aggregatedPrice, discovery.informationAggregation.estimate],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3, Phi.PHI_INV_4],
      discovery.priceFormation,
    );
    let microstructure = computeMarketMicrostructurePricing(input.microstructure);
    let microAdjustment = microstructure.kyleLambda.lambda * input.discovery.orderImbalance * Phi.PHI_INV_5;
    let finalPrice = maxFloat(0.0, weightedAverage(
      [equilibriumAnchor, fairAnchor, discoveryAnchor, dynamicPricing.phiWeightedPrice, ai.compositePrice],
      [Phi.PHI, Phi.PHI_INV, Phi.PHI, Phi.PHI_INV_2, Phi.PHI_INV_3],
      fairAnchor,
    ) + microAdjustment);
    let confidence = clamp(weightedAverage(
      [1.0 - minFloat(1.0, Float.abs(equilibrium.supplyDemand.excessDemand)), discovery.oracleAggregation.confidence, microstructure.kyleLambda.explanatoryPower],
      [Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3],
      Phi.PHI_INV_3,
    ), 0.0, 1.0);
    {
      equilibriumAnchor = equilibriumAnchor;
      fairValueAnchor = fairAnchor;
      discoveryAnchor = discoveryAnchor;
      dynamicPrice = dynamicPricing.phiWeightedPrice;
      aiCompositePrice = ai.compositePrice;
      finalPrice = finalPrice;
      confidence = confidence;
    }
  };

  public func computePricingAnalytics(input : PricingInput) : PricingAnalytics {
    let equilibrium = computeEquilibriumPricing(input.equilibrium);
    let fairValue = computeFairValueModels(input.fairValue);
    let microstructure = computeMarketMicrostructurePricing(input.microstructure);
    let dynamicPricing = computeDynamicPricing(input.dynamicPricing);
    let ai = computeAIAssetPricing(input.aiAsset);
    let discovery = computePriceDiscovery(input.discovery);
    {
      equilibrium = equilibrium;
      fairValue = fairValue;
      microstructure = microstructure;
      dynamicPricing = dynamicPricing;
      aiAsset = ai;
      discovery = discovery;
      compositePrice = computeCompositePrice(input);
    }
  };

  public func defaultPricingInput() : PricingInput {
    {
      equilibrium = {
        primaryMarket = {
          marketId = "AI-COMPUTE";
          currentPrice = 100.0;
          supply = [
            { price = 80.0; quantity = 40.0 },
            { price = 100.0; quantity = 65.0 },
            { price = 120.0; quantity = 90.0 }
          ];
          demand = [
            { price = 80.0; quantity = 110.0 },
            { price = 100.0; quantity = 80.0 },
            { price = 120.0; quantity = 55.0 }
          ];
        };
        walrasianMarkets = [
          {
            marketId = "AI-COMPUTE";
            currentPrice = 100.0;
            supply = [
              { price = 80.0; quantity = 40.0 },
              { price = 100.0; quantity = 65.0 },
              { price = 120.0; quantity = 90.0 }
            ];
            demand = [
              { price = 80.0; quantity = 110.0 },
              { price = 100.0; quantity = 80.0 },
              { price = 120.0; quantity = 55.0 }
            ];
            tatonnementStep = Phi.PHI_INV_5;
          },
          {
            marketId = "AI-AGENT";
            currentPrice = 55.0;
            supply = [
              { price = 40.0; quantity = 30.0 },
              { price = 55.0; quantity = 48.0 },
              { price = 70.0; quantity = 70.0 }
            ];
            demand = [
              { price = 40.0; quantity = 88.0 },
              { price = 55.0; quantity = 60.0 },
              { price = 70.0; quantity = 38.0 }
            ];
            tatonnementStep = Phi.PHI_INV_5;
          }
        ];
        bids = [
          { price = 102.0; quantity = 15.0 },
          { price = 101.0; quantity = 20.0 },
          { price = 99.5; quantity = 25.0 }
        ];
        asks = [
          { price = 100.5; quantity = 18.0 },
          { price = 101.5; quantity = 22.0 },
          { price = 103.0; quantity = 27.0 }
        ];
        bilateralTrade = {
          buyerValue = 108.0;
          sellerCost = 94.0;
          buyerDisagreement = 2.0;
          sellerDisagreement = 1.0;
          buyerBargainingPower = Phi.PHI_INV;
          transactionCost = 1.5;
          executionProbability = 0.92;
        };
        indivisibleAuction = {
          buyers = [
            { participant = "buyer-a"; valuation = 112.0 },
            { participant = "buyer-b"; valuation = 105.0 },
            { participant = "buyer-c"; valuation = 97.0 }
          ];
          sellers = [
            { participant = "seller-a"; cost = 82.0 },
            { participant = "seller-b"; cost = 92.0 },
            { participant = "seller-c"; cost = 103.0 }
          ];
        };
      };
      fairValue = {
        fundamental = {
          normalizedCashFlow = 18.0;
          bookValue = 92.0;
          returnOnCapital = 0.17;
          costOfCapital = 0.10;
          reinvestmentRate = 0.45;
          growthRate = 0.05;
          excessReturnPersistence = 0.70;
          netCash = 12.0;
          sharesOutstanding = 10.0;
        };
        dcf = {
          cashFlows = [
            { period = 1.0; amount = 15.0 },
            { period = 2.0; amount = 17.0 },
            { period = 3.0; amount = 19.0 },
            { period = 4.0; amount = 21.0 }
          ];
          discountRate = 0.10;
          terminalGrowthRate = 0.03;
          netDebt = 20.0;
          sharesOutstanding = 10.0;
        };
        relative = {
          comparables = [
            { name = "comp-a"; multiple = 8.0; metric = 18.0; weight = 0.4; premiumDiscount = 0.05 },
            { name = "comp-b"; multiple = 7.4; metric = 18.0; weight = 0.35; premiumDiscount = 0.00 },
            { name = "comp-c"; multiple = 8.6; metric = 18.0; weight = 0.25; premiumDiscount = -0.03 }
          ];
          netDebt = 20.0;
          sharesOutstanding = 10.0;
        };
        riskNeutral = {
          states = [
            { payoff = 80.0; probability = 0.25 },
            { payoff = 105.0; probability = 0.50 },
            { payoff = 140.0; probability = 0.25 }
          ];
          riskFreeRate = 0.04;
          carryRate = 0.00;
          timeToMaturity = 1.0;
        };
        realWorld = {
          scenarios = [
            { payoff = 78.0; probability = 0.20 },
            { payoff = 108.0; probability = 0.55 },
            { payoff = 150.0; probability = 0.25 }
          ];
          riskFreeRate = 0.04;
          timeToMaturity = 1.0;
          marketPriceOfRisk = 0.08;
          liquidityPremium = 0.02;
          riskAversion = Phi.PHI_INV_3;
        };
      };
      microstructure = {
        observations = [
          { signedVolume = 12.0; priceChange = 0.18; spread = 1.2; inventory = 35.0; holdingTime = 1.0; processingFee = 0.12 },
          { signedVolume = -9.0; priceChange = -0.14; spread = 1.1; inventory = 28.0; holdingTime = 1.4; processingFee = 0.11 },
          { signedVolume = 15.0; priceChange = 0.25; spread = 1.3; inventory = 40.0; holdingTime = 1.1; processingFee = 0.13 },
          { signedVolume = -11.0; priceChange = -0.19; spread = 1.0; inventory = 30.0; holdingTime = 1.2; processingFee = 0.10 }
        ];
        glostenMilgrom = {
          priorHighProbability = 0.52;
          highValue = 104.0;
          lowValue = 96.0;
          informedTraderProbability = 0.35;
          signalAccuracy = 0.82;
          noiseBuyProbability = 0.50;
        };
        quotedSpread = 1.15;
        inventoryRiskAversion = 0.015;
        assetVolatility = 0.22;
        fundingRate = 0.01;
        averageTradeSize = 12.0;
      };
      dynamicPricing = {
        basePrice = 100.0;
        baselineDemand = 75.0;
        currentDemand = 98.0;
        currentSupply = 62.0;
        utilization = 1.18;
        congestionIndex = 0.42;
        hourOfDay = 18;
        peakStartHour = 16;
        peakEndHour = 21;
        elasticity = 0.35;
        competitorPrice = 103.0;
        inventoryPressure = 0.15;
        priceFloor = 75.0;
        priceCap = 175.0;
        phiSensitivity = Phi.PHI_INV;
      };
      aiAsset = {
        baseValue = 100.0;
        resonanceScore = 0.84;
        coherenceScore = 0.80;
        noveltyScore = 0.72;
        provenanceScore = 0.91;
        scarcityScore = 0.38;
        computeUnits = 250.0;
        utilizationHours = 18.0;
        reliabilityScore = 0.96;
        availabilityRatio = 0.72;
        marginalCostPerUnit = 0.18;
        activeUsers = 540.0;
        collaboratorAgents = 32.0;
        integrationDepth = 0.68;
        retentionRate = 0.82;
        accuracyScore = 0.93;
        safetyScore = 0.89;
        latencyMs = 240.0;
        benchmarkCost = 120.0;
        benchmarkQuality = 0.85;
        trainingCost = 1800.0;
        refreshCost = 260.0;
      };
      discovery = {
        trades = [
          { price = 100.5; quantity = 12.0; timestamp = 1; informationWeight = 0.7 },
          { price = 101.2; quantity = 18.0; timestamp = 2; informationWeight = 0.8 },
          { price = 100.9; quantity = 20.0; timestamp = 4; informationWeight = 0.75 },
          { price = 101.6; quantity = 15.0; timestamp = 7; informationWeight = 0.9 }
        ];
        referencePrice = 100.0;
        microstructureMid = 100.8;
        fundamentalPrice = 102.5;
        orderImbalance = 0.12;
        impactCoefficient = 0.85;
        signals = [
          { estimate = 101.8; confidence = 0.82; recencyWeight = 0.95 },
          { estimate = 100.9; confidence = 0.78; recencyWeight = 0.90 },
          { estimate = 102.3; confidence = 0.70; recencyWeight = 0.80 }
        ];
        oracles = [
          { provider = "oracle-a"; price = 101.4; confidence = 0.92; stakeWeight = 1.2; freshness = 0.96; latencyMs = 180.0 },
          { provider = "oracle-b"; price = 100.8; confidence = 0.88; stakeWeight = 1.0; freshness = 0.94; latencyMs = 220.0 },
          { provider = "oracle-c"; price = 101.9; confidence = 0.84; stakeWeight = 1.1; freshness = 0.90; latencyMs = 260.0 }
        ];
      };
    }
  };
}
