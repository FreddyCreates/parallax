import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import PhantomExchange "phantom_exchange";

module {

  public let MAX_CHILD_ORDERS : Nat = 13;
  public let ROUTING_HISTORY_LIMIT : Nat = 144;
  public let EXECUTION_QUALITY_LIMIT : Nat = 240;
  public let DEFAULT_SLICE_INTERVAL_BEATS : Nat = 1;
  public let MIN_ORDER_QTY : Float = 0.001;
  public let DARK_POOL_PRICE_IMPROVEMENT_BPS : Float = 6.18;
  public let DEFAULT_SLIPPAGE_BPS : Float = 25.0;
  public let DEFAULT_PARTICIPATION_RATE : Float = 0.236;

  public type RoutingAlgorithm = {
    #bestExecution;
    #multiVenue;
    #liquiditySeeking;
    #darkPool;
    #smartOrderRouting;
  };

  public type SmartOrderType = {
    #market;
    #limit;
    #stop;
    #iceberg;
    #fok;
    #ioc;
    #postOnly;
  };

  public type SmartExecutionStyle = {
    #immediate;
    #timeSlice;
    #participationRate;
    #liquidityDriven;
    #adaptive;
    #stealth;
  };

  public type VenueKind = {
    #litBook;
    #darkPool;
    #liquidityPool;
    #crossPool;
  };

  public type VenueProfile = {
    venueId            : Text;
    poolId             : Text;
    kind               : VenueKind;
    liquidityFactor    : Float;
    feeBps             : Float;
    gasOverhead        : Float;
    mevProtectionScore : Float;
    darkLiquidityBias  : Float;
    arbitrageBias      : Float;
    priorityWeight     : Float;
  };

  public type MarketContext = {
    pairId             : Text;
    tickSize           : Float;
    lastPrice          : Float;
    bestBid            : Float;
    bestAsk            : Float;
    midpoint           : Float;
    spreadBps          : Float;
    visibleBidDepth    : Float;
    visibleAskDepth    : Float;
    visibleLiquidity   : Float;
    liquidityScore     : Float;
    imbalance          : Float;
    volatilityScore    : Float;
    gasPressure        : Float;
    mevRisk            : Float;
    referencePrice     : Float;
    beat               : Int;
  };

  public type VenueQuote = {
    venueId            : Text;
    poolId             : Text;
    kind               : VenueKind;
    quotePrice         : Float;
    availableQty       : Float;
    feeBps             : Float;
    gasEstimate        : Float;
    mevProtectionScore : Float;
    darkLiquidityScore : Float;
    arbitrageScore     : Float;
    totalCostScore     : Float;
    expectedImpactBps  : Float;
  };

  public type SmartOrderRequest = {
    requestId          : Text;
    pairId             : Text;
    owner              : Text;
    side               : PhantomExchange.OrderSide;
    smartOrderType     : SmartOrderType;
    quantity           : Float;
    limitPrice         : ?Float;
    stopPrice          : ?Float;
    maxSlippageBps     : Float;
    participationRate  : Float;
    benchmarkPrice     : ?Float;
    targetVenueCount   : Nat;
    urgency            : Float;
    allowDarkPools     : Bool;
    allowMultiVenue    : Bool;
    allowCrossPool     : Bool;
    postOnly           : Bool;
    stealthFactor      : Float;
    executionStyle     : SmartExecutionStyle;
    algorithm          : RoutingAlgorithm;
  };

  public type ChildOrderPlan = {
    venueId            : Text;
    poolId             : Text;
    kind               : VenueKind;
    orderType          : SmartOrderType;
    baseOrderType      : PhantomExchange.OrderType;
    tif                : PhantomExchange.TimeInForce;
    price              : Float;
    quantity           : Float;
    displayQuantity    : Float;
    expectedFillPrice  : Float;
    expectedSlippageBps: Float;
    expectedImpactBps  : Float;
    gasEstimate        : Float;
    mevProtectionScore : Float;
    rationale          : Text;
  };

  public type RoutingDecision = {
    requestId                         : Text;
    pairId                            : Text;
    selectedAlgorithm                 : RoutingAlgorithm;
    executionStyle                    : SmartExecutionStyle;
    selectedVenues                    : [Text];
    childOrders                       : [ChildOrderPlan];
    aggregateQuantity                 : Float;
    aggregateExpectedPrice            : Float;
    expectedPriceImprovementBps       : Float;
    expectedEffectiveSpreadBps        : Float;
    expectedImplementationShortfallBps: Float;
    expectedMarketImpactBps           : Float;
    gasAdjustedValue                  : Float;
    mevProtectionScore                : Float;
    reason                            : Text;
    decisionBeat                      : Int;
  };

  public type ExecutionProgram = {
    programId         : Nat;
    request           : SmartOrderRequest;
    remainingQty      : Float;
    nextEligibleBeat  : Int;
    sliceIntervalBeats: Nat;
    active            : Bool;
  };

  public type OrderAnalyticsLink = {
    orderId             : Nat;
    pairId              : Text;
    side                : PhantomExchange.OrderSide;
    venueId             : Text;
    benchmarkPrice      : Float;
    arrivalPrice        : Float;
    decisionPrice       : Float;
    parentQuantity      : Float;
    gasEstimate         : Float;
    mevProtectionScore  : Float;
  };

  public type ExecutionQualityRecord = {
    fillId                       : Nat;
    pairId                       : Text;
    venueId                      : Text;
    benchmarkPrice               : Float;
    decisionPrice                : Float;
    executionPrice               : Float;
    arrivalPrice                 : Float;
    postTradeMidPrice            : Float;
    priceImprovementBps          : Float;
    effectiveSpreadBps           : Float;
    realizedSpreadBps            : Float;
    implementationShortfallBps   : Float;
    marketImpactBps              : Float;
    gasCostSaved                 : Float;
    mevProtectionScore           : Float;
    recordedBeat                 : Int;
  };

  public type SmartRoutingState = {
    venueProfiles                    : [VenueProfile];
    routingHistory                   : [RoutingDecision];
    executionQualityHistory          : [ExecutionQualityRecord];
    activePrograms                   : [ExecutionProgram];
    analyticsLinks                   : [OrderAnalyticsLink];
    nextProgramId                    : Nat;
    totalRoutedOrders                : Nat;
    multiVenueOrders                 : Nat;
    darkPoolOrders                   : Nat;
    liquiditySeekingOrders           : Nat;
    mevProtectedOrders               : Nat;
    gasSavedEstimate                 : Float;
    avgExpectedPriceImprovementBps   : Float;
    avgImplementationShortfallBps    : Float;
    avgRealizedSpreadBps             : Float;
    lastRoutingBeat                  : Int;
    lastAnalyzedFillId               : Nat;
  };

  public type OrderRoutingResult = {
    decision        : RoutingDecision;
    placedOrders    : [PhantomExchange.Order];
    queuedProgramId : ?Nat;
  };

  public func defaultSmartRoutingState() : SmartRoutingState {
    {
      venueProfiles                  = defaultVenueProfiles();
      routingHistory                 = [];
      executionQualityHistory        = [];
      activePrograms                 = [];
      analyticsLinks                 = [];
      nextProgramId                  = 1;
      totalRoutedOrders              = 0;
      multiVenueOrders               = 0;
      darkPoolOrders                 = 0;
      liquiditySeekingOrders         = 0;
      mevProtectedOrders             = 0;
      gasSavedEstimate               = 0.0;
      avgExpectedPriceImprovementBps = 0.0;
      avgImplementationShortfallBps  = 0.0;
      avgRealizedSpreadBps           = 0.0;
      lastRoutingBeat                = 0;
      lastAnalyzedFillId             = 0;
    }
  };

  func defaultVenueProfiles() : [VenueProfile] {
    [
      {
        venueId = "PHANTOM_LIT_PRIMARY";
        poolId = "ORDERBOOK_A";
        kind = #litBook;
        liquidityFactor = 1.0;
        feeBps = 0.0;
        gasOverhead = 0.0;
        mevProtectionScore = Phi.PHI_INV_2;
        darkLiquidityBias = 0.0;
        arbitrageBias = 0.236;
        priorityWeight = 1.0;
      },
      {
        venueId = "PHANTOM_LIT_PASSIVE";
        poolId = "ORDERBOOK_B";
        kind = #litBook;
        liquidityFactor = Phi.PHI_INV;
        feeBps = 0.0;
        gasOverhead = 0.0;
        mevProtectionScore = Phi.PHI_INV;
        darkLiquidityBias = 0.0;
        arbitrageBias = 0.382;
        priorityWeight = Phi.PHI_INV;
      },
      {
        venueId = "PHANTOM_DARK_ALPHA";
        poolId = "DARK_ALPHA";
        kind = #darkPool;
        liquidityFactor = Phi.PHI_INV;
        feeBps = 0.0;
        gasOverhead = 0.0;
        mevProtectionScore = 0.95;
        darkLiquidityBias = 1.0;
        arbitrageBias = 0.236;
        priorityWeight = 0.9;
      },
      {
        venueId = "PHANTOM_AMM_CURVE";
        poolId = "AMM_CURVE";
        kind = #liquidityPool;
        liquidityFactor = Phi.PHI_INV_2;
        feeBps = 1.5;
        gasOverhead = 0.0;
        mevProtectionScore = 0.82;
        darkLiquidityBias = 0.146;
        arbitrageBias = 0.5;
        priorityWeight = 0.85;
      },
      {
        venueId = "PHANTOM_CROSS_POOL";
        poolId = "CROSS_ROUTER";
        kind = #crossPool;
        liquidityFactor = 0.5;
        feeBps = 0.75;
        gasOverhead = 0.0;
        mevProtectionScore = 0.98;
        darkLiquidityBias = 0.0;
        arbitrageBias = Phi.PHI_INV;
        priorityWeight = 0.88;
      },
    ]
  };

  public func submitSmartOrder(
    state         : SmartRoutingState,
    exchangeState : PhantomExchange.PhantomExchangeState,
    request       : SmartOrderRequest,
    beat          : Int,
    aiConfidence  : Float,
  ) : (SmartRoutingState, PhantomExchange.PhantomExchangeState, OrderRoutingResult) {
    let context = buildMarketContext(exchangeState, request.pairId, request.quantity, request.limitPrice, beat);
    let sliceQty = initialSliceQuantity(request, context);
    let sliceRequest = { request with quantity = sliceQty };
    let decision = buildRoutingDecision(state, sliceRequest, context, beat);
    let shouldQueue = requiresProgram(request, sliceQty);
    let shouldPlaceNow = if (request.smartOrderType == #stop) {
      stopTriggered(request, context)
    } else {
      decision.childOrders.size() > 0
    };

    let executionResult = if (shouldPlaceNow) {
      placeChildOrders(state, exchangeState, sliceRequest, decision, beat, aiConfidence)
    } else {
      (exchangeState, [] : [PhantomExchange.Order], [] : [OrderAnalyticsLink])
    };

    let placedQty = sumOrders(executionResult.1);
    let remainingQty = if (request.quantity > placedQty) request.quantity - placedQty else 0.0;
    let queuedProgramId = if (shouldQueue and remainingQty > MIN_ORDER_QTY) {
      ?state.nextProgramId
    } else if (request.smartOrderType == #stop and placedQty <= 0.0) {
      ?state.nextProgramId
    } else {
      null
    };

    let baseState = recordDecision({
      state with
      analyticsLinks = Array.append(state.analyticsLinks, executionResult.2);
      lastRoutingBeat = beat;
    }, decision);

    let nextState = switch (queuedProgramId) {
      case null { baseState };
      case (?programId) {
        let program = {
          programId = programId;
          request = request;
          remainingQty = if (request.smartOrderType == #stop and placedQty <= 0.0) request.quantity else remainingQty;
          nextEligibleBeat = if (request.smartOrderType == #stop and placedQty <= 0.0) beat else beat + sliceInterval(request, context).toInt();
          sliceIntervalBeats = sliceInterval(request, context);
          active = true;
        };
        {
          baseState with
          activePrograms = Array.append(baseState.activePrograms, [program]);
          nextProgramId = baseState.nextProgramId + 1;
        }
      };
    };

    (
      nextState,
      executionResult.0,
      {
        decision = decision;
        placedOrders = executionResult.1;
        queuedProgramId = queuedProgramId;
      }
    )
  };

  public func tickSmartRouting(
    state         : SmartRoutingState,
    exchangeState : PhantomExchange.PhantomExchangeState,
    beat          : Int,
    aiConfidence  : Float,
  ) : (SmartRoutingState, PhantomExchange.PhantomExchangeState, [PhantomExchange.Order]) {
    var updatedState = state;
    var updatedExchange = exchangeState;
    var allOrders : [PhantomExchange.Order] = [];
    var remainingPrograms : [ExecutionProgram] = [];

    for (program in state.activePrograms.vals()) {
      if (not program.active or program.remainingQty <= MIN_ORDER_QTY) {
        if (program.remainingQty > MIN_ORDER_QTY) {
          remainingPrograms := Array.append(remainingPrograms, [program]);
        };
      } else if (beat < program.nextEligibleBeat) {
        remainingPrograms := Array.append(remainingPrograms, [program]);
      } else {
        let context = buildMarketContext(updatedExchange, program.request.pairId, program.remainingQty, program.request.limitPrice, beat);
        let canTrigger = if (program.request.smartOrderType == #stop) {
          stopTriggered(program.request, context)
        } else {
          true
        };

        if (not canTrigger) {
          remainingPrograms := Array.append(remainingPrograms, [program]);
        } else {
          let nextQty = recurringSliceQuantity(program.request, context, program.remainingQty);
          let sliceRequest = { program.request with quantity = nextQty };
          let decision = buildRoutingDecision(updatedState, sliceRequest, context, beat);
          let (newExchange, newOrders, newLinks) = placeChildOrders(updatedState, updatedExchange, sliceRequest, decision, beat, aiConfidence);
          let filledQty = sumOrders(newOrders);
          let pendingQty = if (program.remainingQty > filledQty) program.remainingQty - filledQty else 0.0;

          updatedState := recordDecision({
            updatedState with
            analyticsLinks = Array.append(updatedState.analyticsLinks, newLinks);
            lastRoutingBeat = beat;
          }, decision);
          updatedExchange := newExchange;
          allOrders := Array.append(allOrders, newOrders);

          if (pendingQty > MIN_ORDER_QTY) {
            remainingPrograms := Array.append(remainingPrograms, [{
              programId = program.programId;
              request = program.request;
              remainingQty = pendingQty;
              nextEligibleBeat = beat + program.sliceIntervalBeats.toInt();
              sliceIntervalBeats = program.sliceIntervalBeats;
              active = true;
            }]);
          };
        };
      };
    };

    ({ updatedState with activePrograms = remainingPrograms }, updatedExchange, allOrders)
  };

  public func syncExecutionQuality(
    state         : SmartRoutingState,
    exchangeState : PhantomExchange.PhantomExchangeState,
    beat          : Int,
  ) : SmartRoutingState {
    var nextState = state;
    var latestFillId = state.lastAnalyzedFillId;

    for (fill in exchangeState.recentFills.vals()) {
      if (fill.fillId > state.lastAnalyzedFillId) {
        if (fill.fillId > latestFillId) {
          latestFillId := fill.fillId;
        };
        let linkOpt = findAnalyticsLink(state.analyticsLinks, fill);
        switch (linkOpt) {
          case null {};
          case (?link) {
            let postTradeMid = marketMidpoint(exchangeState, fill.pairId, fill.price);
            let record = computeExecutionQuality(
              link.side,
              fill,
              link.venueId,
              link.benchmarkPrice,
              link.decisionPrice,
              link.arrivalPrice,
              postTradeMid,
              link.parentQuantity,
              link.gasEstimate,
              link.mevProtectionScore,
              beat,
            );
            nextState := recordExecutionQuality(nextState, record);
          };
        };
      };
    };

    { nextState with lastAnalyzedFillId = latestFillId }
  };

  public func computeExecutionQuality(
    side               : PhantomExchange.OrderSide,
    fill               : PhantomExchange.Fill,
    venueId            : Text,
    benchmarkPrice     : Float,
    decisionPrice      : Float,
    arrivalPrice       : Float,
    postTradeMidPrice  : Float,
    parentQuantity     : Float,
    gasEstimate        : Float,
    mevProtectionScore : Float,
    beat               : Int,
  ) : ExecutionQualityRecord {
    let explicitCostBps = costToBps(gasEstimate, fill.price, fill.quantity);
    {
      fillId                     = fill.fillId;
      pairId                     = fill.pairId;
      venueId                    = venueId;
      benchmarkPrice             = benchmarkPrice;
      decisionPrice              = decisionPrice;
      executionPrice             = fill.price;
      arrivalPrice               = arrivalPrice;
      postTradeMidPrice          = postTradeMidPrice;
      priceImprovementBps        = priceImprovementBps(side, benchmarkPrice, fill.price);
      effectiveSpreadBps         = effectiveSpreadBps(postTradeMidPrice, fill.price);
      realizedSpreadBps          = realizedSpreadBps(side, fill.price, postTradeMidPrice, arrivalPrice);
      implementationShortfallBps = implementationShortfallBps(side, arrivalPrice, fill.price, explicitCostBps);
      marketImpactBps            = marketImpactBps(side, decisionPrice, fill.price, fill.quantity, parentQuantity);
      gasCostSaved               = gasEstimate;
      mevProtectionScore         = mevProtectionScore;
      recordedBeat               = beat;
    }
  };

  public func priceImprovementBps(
    side           : PhantomExchange.OrderSide,
    benchmarkPrice : Float,
    executionPrice : Float,
  ) : Float {
    if (benchmarkPrice <= 0.0) { return 0.0 };
    switch (side) {
      case (#buy)  { ((benchmarkPrice - executionPrice) / benchmarkPrice) * 10000.0 };
      case (#sell) { ((executionPrice - benchmarkPrice) / benchmarkPrice) * 10000.0 };
    }
  };

  public func effectiveSpreadBps(midPrice : Float, executionPrice : Float) : Float {
    if (midPrice <= 0.0) { return 0.0 };
    (Float.abs(executionPrice - midPrice) / midPrice) * 20000.0
  };

  public func realizedSpreadBps(
    side              : PhantomExchange.OrderSide,
    executionPrice    : Float,
    postTradeMidPrice : Float,
    referencePrice    : Float,
  ) : Float {
    if (referencePrice <= 0.0) { return 0.0 };
    switch (side) {
      case (#buy)  { ((postTradeMidPrice - executionPrice) / referencePrice) * 20000.0 };
      case (#sell) { ((executionPrice - postTradeMidPrice) / referencePrice) * 20000.0 };
    }
  };

  public func implementationShortfallBps(
    side            : PhantomExchange.OrderSide,
    arrivalPrice    : Float,
    executionPrice  : Float,
    explicitCostBps : Float,
  ) : Float {
    if (arrivalPrice <= 0.0) { return explicitCostBps };
    let movement = switch (side) {
      case (#buy)  { ((executionPrice - arrivalPrice) / arrivalPrice) * 10000.0 };
      case (#sell) { ((arrivalPrice - executionPrice) / arrivalPrice) * 10000.0 };
    };
    movement + explicitCostBps
  };

  public func marketImpactBps(
    side            : PhantomExchange.OrderSide,
    decisionPrice   : Float,
    executionPrice  : Float,
    executedQty     : Float,
    parentQty       : Float,
  ) : Float {
    if (decisionPrice <= 0.0) { return 0.0 };
    let rawImpact = switch (side) {
      case (#buy)  { ((executionPrice - decisionPrice) / decisionPrice) * 10000.0 };
      case (#sell) { ((decisionPrice - executionPrice) / decisionPrice) * 10000.0 };
    };
    let participation = if (parentQty <= 0.0) 1.0 else Float.min(1.0, executedQty / parentQty);
    rawImpact * Float.max(Phi.PHI_INV_3, participation)
  };

  func buildRoutingDecision(
    state   : SmartRoutingState,
    request : SmartOrderRequest,
    context : MarketContext,
    beat    : Int,
  ) : RoutingDecision {
    let algorithm = selectAlgorithm(request, context);
    let quotes = venueQuotes(state, request, context, algorithm);
    let plans = buildChildPlans(request, context, quotes, algorithm);
    let aggregateQty = sumPlanQty(plans);
    let expectedPrice = weightedExpectedPrice(plans, aggregateQty, context.referencePrice);
    let improvement = priceImprovementBps(request.side, optionOr(request.benchmarkPrice, context.referencePrice), expectedPrice);
    let effectiveSpread = weightedMetric(plans, aggregateQty, func(plan) { plan.expectedSlippageBps });
    let marketImpact = weightedMetric(plans, aggregateQty, func(plan) { plan.expectedImpactBps });
    let shortfall = implementationShortfallBps(request.side, context.referencePrice, expectedPrice, costToBps(totalGas(plans), expectedPrice, Float.max(MIN_ORDER_QTY, aggregateQty)));
    let mevScore = weightedMetric(plans, aggregateQty, func(plan) { plan.mevProtectionScore * 10000.0 }) / 10000.0;
    let gasAdjusted = expectedPrice + totalGas(plans);
    {
      requestId = request.requestId;
      pairId = request.pairId;
      selectedAlgorithm = algorithm;
      executionStyle = request.executionStyle;
      selectedVenues = Array.map<ChildOrderPlan, Text>(plans, func(plan) { plan.venueId });
      childOrders = plans;
      aggregateQuantity = aggregateQty;
      aggregateExpectedPrice = expectedPrice;
      expectedPriceImprovementBps = improvement;
      expectedEffectiveSpreadBps = effectiveSpread;
      expectedImplementationShortfallBps = shortfall;
      expectedMarketImpactBps = marketImpact;
      gasAdjustedValue = gasAdjusted;
      mevProtectionScore = mevScore;
      reason = decisionReason(algorithm, request, context, plans);
      decisionBeat = beat;
    }
  };

  func buildChildPlans(
    request   : SmartOrderRequest,
    context   : MarketContext,
    quotes    : [VenueQuote],
    algorithm : RoutingAlgorithm,
  ) : [ChildOrderPlan] {
    if (quotes.size() == 0) { return [] };
    let sorted = sortQuotes(quotes, algorithm);
    let targetVenues = if (request.allowMultiVenue) {
      minNat(MAX_CHILD_ORDERS, maxNat(1, minNat(request.targetVenueCount, sorted.size())))
    } else {
      1
    };
    let selected = Array.tabulate<VenueQuote>(targetVenues, func(i) { sorted[i] });
    let totalWeight = Array.foldLeft<VenueQuote, Float>(selected, 0.0, func(acc, quote) {
      acc + venueWeight(quote, algorithm)
    });

    var remainingQty = request.quantity;
    var plans : [ChildOrderPlan] = [];

    for (quote in selected.vals()) {
      if (remainingQty > MIN_ORDER_QTY) {
        let weight = venueWeight(quote, algorithm);
        let rawQty = if (totalWeight <= 0.0) {
          remainingQty
        } else {
          Float.min(quote.availableQty, request.quantity * (weight / totalWeight))
        };
        let childQty = if (quote.venueId == selected[selected.size() - 1].venueId) {
          remainingQty
        } else {
          clampQty(Float.min(remainingQty, Float.max(MIN_ORDER_QTY, rawQty)))
        };
        let priced = planPrice(request, context, quote, childQty);
        plans := Array.append(plans, [{
          venueId = quote.venueId;
          poolId = quote.poolId;
          kind = quote.kind;
          orderType = request.smartOrderType;
          baseOrderType = priced.0;
          tif = priced.1;
          price = priced.2;
          quantity = childQty;
          displayQuantity = displayQuantity(request, childQty);
          expectedFillPrice = quote.quotePrice;
          expectedSlippageBps = Float.max(0.0, priceImprovementBps(request.side, quote.quotePrice, priced.2) * -1.0);
          expectedImpactBps = quote.expectedImpactBps;
          gasEstimate = quote.gasEstimate;
          mevProtectionScore = quote.mevProtectionScore;
          rationale = childRationale(algorithm, request, quote, context);
        }]);
        remainingQty -= childQty;
      };
    };

    plans
  };

  func placeChildOrders(
    _state         : SmartRoutingState,
    exchangeState  : PhantomExchange.PhantomExchangeState,
    request        : SmartOrderRequest,
    decision       : RoutingDecision,
    beat           : Int,
    aiConfidence   : Float,
  ) : (PhantomExchange.PhantomExchangeState, [PhantomExchange.Order], [OrderAnalyticsLink]) {
    var updatedExchange = exchangeState;
    var placedOrders : [PhantomExchange.Order] = [];
    var analytics : [OrderAnalyticsLink] = [];
    let benchmark = optionOr(request.benchmarkPrice, optionOr(request.limitPrice, marketReference(decision, exchangeState, request.pairId)));

    for (plan in decision.childOrders.vals()) {
      let (newExchange, order) = PhantomExchange.placeOrder(
        updatedExchange,
        request.pairId,
        request.owner,
        request.side,
        plan.baseOrderType,
        plan.price,
        plan.quantity,
        plan.tif,
        beat,
        aiConfidence,
      );
      updatedExchange := newExchange;
      placedOrders := Array.append(placedOrders, [order]);
      analytics := Array.append(analytics, [{
        orderId = order.orderId;
        pairId = request.pairId;
        side = request.side;
        venueId = plan.venueId;
        benchmarkPrice = benchmark;
        arrivalPrice = marketReference(decision, updatedExchange, request.pairId);
        decisionPrice = plan.expectedFillPrice;
        parentQuantity = request.quantity;
        gasEstimate = plan.gasEstimate;
        mevProtectionScore = plan.mevProtectionScore;
      }]);
    };

    (updatedExchange, placedOrders, analytics)
  };

  func buildMarketContext(
    exchangeState : PhantomExchange.PhantomExchangeState,
    pairId        : Text,
    quantity      : Float,
    limitPrice    : ?Float,
    beat          : Int,
  ) : MarketContext {
    let pair = switch (Array.find<(Text, PhantomExchange.TradingPair)>(exchangeState.pairs, func(entry) { entry.0 == pairId })) {
      case (?found) { found.1 };
      case null {
        {
          pairId = pairId;
          baseToken = "UNKNOWN";
          quoteToken = "UNKNOWN";
          baseCategory = #crypto;
          quoteCategory = #crypto;
          tickSize = 0.0001;
          lotSize = MIN_ORDER_QTY;
          status = #active;
          createdBeat = beat;
          volume24h = 0.0;
          lastPrice = optionOr(limitPrice, 1.0);
          highPrice24h = optionOr(limitPrice, 1.0);
          lowPrice24h = optionOr(limitPrice, 1.0);
        }
      };
    };

    let book = PhantomExchange.getOrderBook(exchangeState, pairId);
    let bestBid = switch (book) {
      case (?b) { if (b.bids.size() > 0) b.bids[0].price else pair.lastPrice };
      case null { pair.lastPrice };
    };
    let bestAsk = switch (book) {
      case (?b) { if (b.asks.size() > 0) b.asks[0].price else fallbackAsk(bestBid, pair.lastPrice, pair.tickSize) };
      case null { fallbackAsk(bestBid, pair.lastPrice, pair.tickSize) };
    };
    let midpoint = if (bestBid > 0.0 and bestAsk > 0.0) {
      (bestBid + bestAsk) / 2.0
    } else {
      optionOr(limitPrice, if (pair.lastPrice > 0.0) pair.lastPrice else 1.0)
    };
    let bidDepth = switch (book) {
      case (?b) { visibleDepth(b.bids) };
      case null { 0.0 };
    };
    let askDepth = switch (book) {
      case (?b) { visibleDepth(b.asks) };
      case null { 0.0 };
    };
    let visibleLiquidity = if (bidDepth < askDepth) bidDepth else askDepth;
    let totalVisible = bidDepth + askDepth;
    let imbalance = if (totalVisible <= 0.0) 0.0 else (bidDepth - askDepth) / totalVisible;
    let spreadBps = if (midpoint <= 0.0) 0.0 else ((bestAsk - bestBid) / midpoint) * 10000.0;
    let liquidityScore = if (quantity <= 0.0) 1.0 else Float.min(1.0, visibleLiquidity / Float.max(quantity, MIN_ORDER_QTY));
    let volatility = Float.min(1.0, (Float.abs(imbalance) * Phi.PHI_INV) + (spreadBps / 1000.0));
    let referencePrice = optionOr(limitPrice, if (midpoint > 0.0) midpoint else if (pair.lastPrice > 0.0) pair.lastPrice else 1.0);

    {
      pairId = pairId;
      tickSize = pair.tickSize;
      lastPrice = pair.lastPrice;
      bestBid = bestBid;
      bestAsk = bestAsk;
      midpoint = midpoint;
      spreadBps = spreadBps;
      visibleBidDepth = bidDepth;
      visibleAskDepth = askDepth;
      visibleLiquidity = visibleLiquidity;
      liquidityScore = liquidityScore;
      imbalance = imbalance;
      volatilityScore = volatility;
      gasPressure = 0.0;
      mevRisk = Float.min(1.0, volatility + (spreadBps / 10000.0));
      referencePrice = referencePrice;
      beat = beat;
    }
  };

  func venueQuotes(
    state     : SmartRoutingState,
    request   : SmartOrderRequest,
    context   : MarketContext,
    algorithm : RoutingAlgorithm,
  ) : [VenueQuote] {
    var quotes : [VenueQuote] = [];
    for (profile in state.venueProfiles.vals()) {
      let shouldInclude = if (profile.kind == #darkPool and not request.allowDarkPools) {
        false
      } else if (profile.kind == #crossPool and not request.allowCrossPool) {
        false
      } else if (profile.kind != #litBook and not request.allowMultiVenue and algorithm == #bestExecution) {
        profile.kind == #darkPool and request.allowDarkPools
      } else {
        true
      };
      if (shouldInclude) {
        quotes := Array.append(quotes, [buildVenueQuote(profile, request, context)]);
      };
    };
    quotes
  };

  func buildVenueQuote(
    profile : VenueProfile,
    request : SmartOrderRequest,
    context : MarketContext,
  ) : VenueQuote {
    let touch = sideTouchPrice(request.side, context);
    let reference = if (touch > 0.0) touch else context.referencePrice;
    let baseImprovement = switch (profile.kind) {
      case (#darkPool)      { DARK_POOL_PRICE_IMPROVEMENT_BPS * Float.max(0.5, request.stealthFactor) };
      case (#liquidityPool) { 2.0 + (profile.arbitrageBias * 2.0) };
      case (#crossPool)     { 3.0 + (profile.arbitrageBias * 4.0) };
      case (#litBook)       { if (profile.venueId == "PHANTOM_LIT_PASSIVE") 1.5 else 0.5 };
    };
    let effectivePrice = betterPrice(reference, request.side, baseImprovement);
    let liquidityBase = if (profile.kind == #darkPool) context.visibleLiquidity * Float.max(Phi.PHI_INV_3, profile.liquidityFactor)
                        else if (profile.kind == #liquidityPool) context.visibleLiquidity + (context.visibleLiquidity * profile.liquidityFactor)
                        else context.visibleLiquidity * Float.max(Phi.PHI_INV_3, profile.liquidityFactor);
    let availableQty = Float.max(MIN_ORDER_QTY, liquidityBase + (request.quantity * profile.darkLiquidityBias * 0.25));
    let impact = expectedImpact(context, request, profile);
    let totalCost = effectivePrice + costToBps(profile.feeBps + profile.gasOverhead, context.referencePrice, Float.max(request.quantity, MIN_ORDER_QTY));
    {
      venueId = profile.venueId;
      poolId = profile.poolId;
      kind = profile.kind;
      quotePrice = effectivePrice;
      availableQty = availableQty;
      feeBps = profile.feeBps;
      gasEstimate = profile.gasOverhead;
      mevProtectionScore = profile.mevProtectionScore;
      darkLiquidityScore = profile.darkLiquidityBias;
      arbitrageScore = profile.arbitrageBias + arbitrageSignal(context, request, profile);
      totalCostScore = totalCost;
      expectedImpactBps = impact;
    }
  };

  func selectAlgorithm(request : SmartOrderRequest, context : MarketContext) : RoutingAlgorithm {
    switch (request.algorithm) {
      case (#smartOrderRouting) {
        if (request.allowDarkPools and request.executionStyle == #stealth) {
          #darkPool
        } else if (request.allowMultiVenue and request.quantity > Float.max(context.visibleLiquidity, MIN_ORDER_QTY)) {
          #multiVenue
        } else if (context.liquidityScore < Phi.PHI_INV or request.executionStyle == #liquidityDriven or request.executionStyle == #participationRate) {
          #liquiditySeeking
        } else {
          #bestExecution
        }
      };
      case other { other };
    }
  };

  func initialSliceQuantity(request : SmartOrderRequest, context : MarketContext) : Float {
    let base = switch (request.smartOrderType) {
      case (#iceberg) { Float.max(MIN_ORDER_QTY, request.quantity * Phi.PHI_INV_3) };
      case (#stop)    { 0.0 };
      case _          { request.quantity };
    };
    sliceByStyle(request, context, base, request.quantity)
  };

  func recurringSliceQuantity(request : SmartOrderRequest, context : MarketContext, remainingQty : Float) : Float {
    sliceByStyle(request, context, Float.min(remainingQty, Float.max(MIN_ORDER_QTY, remainingQty * Phi.PHI_INV_3)), remainingQty)
  };

  func sliceByStyle(
    request      : SmartOrderRequest,
    context      : MarketContext,
    baseQty      : Float,
    remainingQty : Float,
  ) : Float {
    let sliced = switch (request.executionStyle) {
      case (#immediate)           { baseQty };
      case (#timeSlice)           { Float.min(baseQty, Float.max(MIN_ORDER_QTY, remainingQty * Phi.PHI_INV_3)) };
      case (#participationRate)   { Float.min(baseQty, Float.max(MIN_ORDER_QTY, context.visibleLiquidity * normalizedParticipation(request))) };
      case (#liquidityDriven)     { Float.min(baseQty, Float.max(MIN_ORDER_QTY, context.visibleLiquidity * Phi.PHI_INV_3)) };
      case (#adaptive)            { Float.min(baseQty, Float.max(MIN_ORDER_QTY, remainingQty * adaptiveParticipation(context))) };
      case (#stealth)             { Float.min(baseQty, Float.max(MIN_ORDER_QTY, remainingQty * 0.146)) };
    };
    clampQty(Float.min(remainingQty, sliced))
  };

  func sliceInterval(request : SmartOrderRequest, context : MarketContext) : Nat {
    switch (request.executionStyle) {
      case (#immediate)         { DEFAULT_SLICE_INTERVAL_BEATS };
      case (#timeSlice)         { 2 };
      case (#participationRate) { 1 };
      case (#liquidityDriven)   { if (context.liquidityScore < Phi.PHI_INV) 2 else 1 };
      case (#adaptive)          { if (context.volatilityScore > Phi.PHI_INV) 2 else 1 };
      case (#stealth)           { 3 };
    }
  };

  func requiresProgram(request : SmartOrderRequest, sliceQty : Float) : Bool {
    request.smartOrderType == #stop or request.smartOrderType == #iceberg or request.executionStyle != #immediate or request.quantity - sliceQty > MIN_ORDER_QTY
  };

  func stopTriggered(request : SmartOrderRequest, context : MarketContext) : Bool {
    switch (request.stopPrice) {
      case null { true };
      case (?stopPx) {
        switch (request.side) {
          case (#buy)  { context.bestAsk >= stopPx or context.midpoint >= stopPx };
          case (#sell) { context.bestBid <= stopPx or context.midpoint <= stopPx or context.bestBid == 0.0 };
        }
      };
    }
  };

  func planPrice(
    request  : SmartOrderRequest,
    context  : MarketContext,
    quote    : VenueQuote,
    quantity : Float,
  ) : (PhantomExchange.OrderType, PhantomExchange.TimeInForce, Float) {
    let aggressiveLimit = priceWithSlippageCap(request, quote.quotePrice);
    switch (request.smartOrderType) {
      case (#market) {
        (#market, #ioc, aggressiveLimit)
      };
      case (#limit) {
        (#limit, #gtc, dynamicLimitPrice(request, context, quote.quotePrice, quantity))
      };
      case (#stop) {
        (#stopLimit, #gtc, optionOr(request.stopPrice, dynamicLimitPrice(request, context, aggressiveLimit, quantity)))
      };
      case (#iceberg) {
        (#iceberg, #gtc, dynamicLimitPrice(request, context, quote.quotePrice, quantity))
      };
      case (#fok) {
        (#limit, #fok, aggressiveLimit)
      };
      case (#ioc) {
        (#limit, #ioc, aggressiveLimit)
      };
      case (#postOnly) {
        (#limit, #gtc, postOnlyPrice(request.side, context, optionOr(request.limitPrice, quote.quotePrice)))
      };
    }
  };

  func dynamicLimitPrice(
    request   : SmartOrderRequest,
    context   : MarketContext,
    basePrice : Float,
    _quantity : Float,
  ) : Float {
    let urgencyBps = request.urgency * 4.0;
    let volatilityBuffer = context.volatilityScore * 3.0;
    let raw = betterPrice(basePrice, request.side, if (request.postOnly) 1.0 else 0.0);
    let adjusted = if (request.postOnly or request.smartOrderType == #postOnly) {
      postOnlyPrice(request.side, context, optionOr(request.limitPrice, raw))
    } else if (request.executionStyle == #adaptive and context.spreadBps > 0.0) {
      priceWithBps(raw, request.side, urgencyBps + volatilityBuffer)
    } else {
      optionOr(request.limitPrice, priceWithBps(raw, request.side, urgencyBps))
    };
    quantizePrice(adjusted, context.tickSize)
  };

  func displayQuantity(request : SmartOrderRequest, quantity : Float) : Float {
    if (request.smartOrderType != #iceberg) {
      quantity
    } else {
      clampQty(Float.max(MIN_ORDER_QTY, quantity * Phi.PHI_INV_3))
    }
  };

  func recordDecision(state : SmartRoutingState, decision : RoutingDecision) : SmartRoutingState {
    let totalOrders = state.totalRoutedOrders + 1;
    let history = appendLimitedRouting(state.routingHistory, decision);
    let multiVenueCount = if (decision.childOrders.size() > 1) state.multiVenueOrders + 1 else state.multiVenueOrders;
    let darkCount = if (hasVenueKind(decision.childOrders, #darkPool)) state.darkPoolOrders + 1 else state.darkPoolOrders;
    let liquidityCount = if (decision.selectedAlgorithm == #liquiditySeeking) state.liquiditySeekingOrders + 1 else state.liquiditySeekingOrders;
    let mevCount = if (decision.mevProtectionScore >= Phi.PHI_INV) state.mevProtectedOrders + 1 else state.mevProtectedOrders;
    {
      state with
      routingHistory = history;
      totalRoutedOrders = totalOrders;
      multiVenueOrders = multiVenueCount;
      darkPoolOrders = darkCount;
      liquiditySeekingOrders = liquidityCount;
      mevProtectedOrders = mevCount;
      gasSavedEstimate = state.gasSavedEstimate + totalGas(decision.childOrders);
      avgExpectedPriceImprovementBps = rollingAverage(state.avgExpectedPriceImprovementBps, totalOrders, decision.expectedPriceImprovementBps);
      avgImplementationShortfallBps = rollingAverage(state.avgImplementationShortfallBps, totalOrders, decision.expectedImplementationShortfallBps);
      lastRoutingBeat = decision.decisionBeat;
    }
  };

  func recordExecutionQuality(state : SmartRoutingState, record : ExecutionQualityRecord) : SmartRoutingState {
    let newHistory = appendLimitedQuality(state.executionQualityHistory, record);
    let count = newHistory.size();
    {
      state with
      executionQualityHistory = newHistory;
      avgImplementationShortfallBps = rollingAverage(state.avgImplementationShortfallBps, count, record.implementationShortfallBps);
      avgRealizedSpreadBps = rollingAverage(state.avgRealizedSpreadBps, count, record.realizedSpreadBps);
    }
  };

  func appendLimitedRouting(existing : [RoutingDecision], item : RoutingDecision) : [RoutingDecision] {
    let combined = Array.append(existing, [item]);
    if (combined.size() > ROUTING_HISTORY_LIMIT) {
      Array.tabulate<RoutingDecision>(ROUTING_HISTORY_LIMIT, func(i) {
        combined[combined.size() - ROUTING_HISTORY_LIMIT + i]
      })
    } else {
      combined
    }
  };

  func appendLimitedQuality(existing : [ExecutionQualityRecord], item : ExecutionQualityRecord) : [ExecutionQualityRecord] {
    let combined = Array.append(existing, [item]);
    if (combined.size() > EXECUTION_QUALITY_LIMIT) {
      Array.tabulate<ExecutionQualityRecord>(EXECUTION_QUALITY_LIMIT, func(i) {
        combined[combined.size() - EXECUTION_QUALITY_LIMIT + i]
      })
    } else {
      combined
    }
  };

  func decisionReason(
    algorithm : RoutingAlgorithm,
    request   : SmartOrderRequest,
    context   : MarketContext,
    plans     : [ChildOrderPlan],
  ) : Text {
    let styleText = switch (request.executionStyle) {
      case (#immediate)         { "immediate" };
      case (#timeSlice)         { "time-sliced" };
      case (#participationRate) { "participation-rate" };
      case (#liquidityDriven)   { "liquidity-driven" };
      case (#adaptive)          { "adaptive" };
      case (#stealth)           { "stealth" };
    };
    let algoText = switch (algorithm) {
      case (#bestExecution)     { "best execution" };
      case (#multiVenue)        { "multi-venue" };
      case (#liquiditySeeking)  { "liquidity-seeking" };
      case (#darkPool)          { "dark-pool" };
      case (#smartOrderRouting) { "smart order routing" };
    };
    algoText # " selected " # Nat.toText(plans.size()) # " venue(s) with " # styleText #
    " execution at spread " # Float.toText(context.spreadBps) # " bps"
  };

  func childRationale(
    algorithm : RoutingAlgorithm,
    request   : SmartOrderRequest,
    quote     : VenueQuote,
    context   : MarketContext,
  ) : Text {
    let venueText = switch (quote.kind) {
      case (#litBook)       { "lit book" };
      case (#darkPool)      { "dark pool" };
      case (#liquidityPool) { "liquidity pool" };
      case (#crossPool)     { "cross-pool venue" };
    };
    let algoText = switch (algorithm) {
      case (#bestExecution)     { "best execution" };
      case (#multiVenue)        { "multi-venue balancing" };
      case (#liquiditySeeking)  { "liquidity search" };
      case (#darkPool)          { "stealth routing" };
      case (#smartOrderRouting) { "adaptive SOR" };
    };
    venueText # " selected by " # algoText # "; price=" # Float.toText(quote.quotePrice) #
    ", mev=" # Float.toText(quote.mevProtectionScore) # ", liq=" # Float.toText(context.visibleLiquidity)
  };

  func sortQuotes(quotes : [VenueQuote], algorithm : RoutingAlgorithm) : [VenueQuote] {
    Array.sort<VenueQuote>(quotes, func(a, b) {
      let aScore = venueSortScore(a, algorithm);
      let bScore = venueSortScore(b, algorithm);
      if (aScore > bScore) #less else if (aScore < bScore) #greater else #equal
    })
  };

  func venueSortScore(quote : VenueQuote, algorithm : RoutingAlgorithm) : Float {
    switch (algorithm) {
      case (#bestExecution) {
        (quote.mevProtectionScore * 100.0) + (quote.availableQty * 0.1) - quote.totalCostScore - quote.expectedImpactBps
      };
      case (#multiVenue) {
        (quote.availableQty * 0.5) + (quote.arbitrageScore * 100.0) + (quote.mevProtectionScore * 25.0)
      };
      case (#liquiditySeeking) {
        (quote.availableQty * 0.75) + (quote.darkLiquidityScore * 20.0) - quote.expectedImpactBps
      };
      case (#darkPool) {
        (quote.darkLiquidityScore * 100.0) + (quote.mevProtectionScore * 50.0) - quote.totalCostScore
      };
      case (#smartOrderRouting) {
        (quote.arbitrageScore * 50.0) + (quote.availableQty * 0.25) + (quote.mevProtectionScore * 30.0) - quote.expectedImpactBps
      };
    }
  };

  func venueWeight(quote : VenueQuote, algorithm : RoutingAlgorithm) : Float {
    switch (algorithm) {
      case (#bestExecution) { Float.max(Phi.PHI_INV_3, quote.mevProtectionScore) };
      case (#multiVenue) { Float.max(Phi.PHI_INV_3, quote.availableQty) };
      case (#liquiditySeeking) { Float.max(Phi.PHI_INV_3, quote.availableQty * quote.mevProtectionScore) };
      case (#darkPool) { Float.max(Phi.PHI_INV_3, quote.darkLiquidityScore + quote.mevProtectionScore) };
      case (#smartOrderRouting) { Float.max(Phi.PHI_INV_3, quote.arbitrageScore + quote.mevProtectionScore + (quote.availableQty * 0.01)) };
    }
  };

  func expectedImpact(context : MarketContext, request : SmartOrderRequest, profile : VenueProfile) : Float {
    let participation = if (context.visibleLiquidity <= 0.0) 1.0 else Float.min(1.0, request.quantity / Float.max(context.visibleLiquidity, MIN_ORDER_QTY));
    let stealthBenefit = if (profile.kind == #darkPool) request.stealthFactor * 6.0 else 0.0;
    Float.max(0.0, (participation * 40.0) + (context.spreadBps * 0.1) - stealthBenefit)
  };

  func arbitrageSignal(context : MarketContext, request : SmartOrderRequest, profile : VenueProfile) : Float {
    let directionBias = switch (request.side) {
      case (#buy)  { Float.max(0.0, context.imbalance * -1.0) };
      case (#sell) { Float.max(0.0, context.imbalance) };
    };
    directionBias + profile.arbitrageBias + (if (profile.kind == #crossPool) 0.236 else 0.0)
  };

  func sideTouchPrice(side : PhantomExchange.OrderSide, context : MarketContext) : Float {
    switch (side) {
      case (#buy)  { if (context.bestAsk > 0.0) context.bestAsk else context.referencePrice };
      case (#sell) { if (context.bestBid > 0.0) context.bestBid else context.referencePrice };
    }
  };

  func priceWithSlippageCap(request : SmartOrderRequest, price : Float) : Float {
    let cap = if (request.maxSlippageBps <= 0.0) DEFAULT_SLIPPAGE_BPS else request.maxSlippageBps;
    quantizePrice(priceWithBps(price, request.side, cap), 0.00000001)
  };

  func postOnlyPrice(side : PhantomExchange.OrderSide, context : MarketContext, reference : Float) : Float {
    let tick = if (context.tickSize > 0.0) context.tickSize else 0.0001;
    switch (side) {
      case (#buy)  { quantizePrice(Float.min(reference, Float.max(0.0, context.bestAsk - tick)), tick) };
      case (#sell) { quantizePrice(Float.max(reference, context.bestBid + tick), tick) };
    }
  };

  func betterPrice(price : Float, side : PhantomExchange.OrderSide, improvementBps : Float) : Float {
    priceWithBps(price, side, improvementBps * -1.0)
  };

  func priceWithBps(price : Float, side : PhantomExchange.OrderSide, bps : Float) : Float {
    if (price <= 0.0) { return price };
    switch (side) {
      case (#buy)  { price * (1.0 + (bps / 10000.0)) };
      case (#sell) { price * (1.0 - (bps / 10000.0)) };
    }
  };

  func quantizePrice(price : Float, tickSize : Float) : Float {
    if (tickSize <= 0.0 or price <= 0.0) { return price };
    let ticks = Float.floor(price / tickSize);
    Float.max(tickSize, ticks * tickSize)
  };

  func visibleDepth(orders : [PhantomExchange.Order]) : Float {
    let limit = minNat(5, orders.size());
    var total = 0.0;
    var i : Nat = 0;
    while (i < limit) {
      total += Float.max(0.0, orders[i].remainingQty);
      i += 1;
    };
    total
  };

  func sumOrders(orders : [PhantomExchange.Order]) : Float {
    Array.foldLeft<PhantomExchange.Order, Float>(orders, 0.0, func(acc, order) {
      acc + order.quantity
    })
  };

  func sumPlanQty(plans : [ChildOrderPlan]) : Float {
    Array.foldLeft<ChildOrderPlan, Float>(plans, 0.0, func(acc, plan) {
      acc + plan.quantity
    })
  };

  func totalGas(plans : [ChildOrderPlan]) : Float {
    Array.foldLeft<ChildOrderPlan, Float>(plans, 0.0, func(acc, plan) {
      acc + plan.gasEstimate
    })
  };

  func weightedExpectedPrice(plans : [ChildOrderPlan], totalQty : Float, fallback : Float) : Float {
    if (totalQty <= 0.0 or plans.size() == 0) { return fallback };
    Array.foldLeft<ChildOrderPlan, Float>(plans, 0.0, func(acc, plan) {
      acc + (plan.expectedFillPrice * (plan.quantity / totalQty))
    })
  };

  func weightedMetric(plans : [ChildOrderPlan], totalQty : Float, metric : ChildOrderPlan -> Float) : Float {
    if (totalQty <= 0.0) { return 0.0 };
    Array.foldLeft<ChildOrderPlan, Float>(plans, 0.0, func(acc, plan) {
      acc + (metric(plan) * (plan.quantity / totalQty))
    })
  };

  func findAnalyticsLink(links : [OrderAnalyticsLink], fill : PhantomExchange.Fill) : ?OrderAnalyticsLink {
    Array.find<OrderAnalyticsLink>(links, func(link) {
      link.orderId == fill.buyOrderId or link.orderId == fill.sellOrderId
    })
  };

  func marketMidpoint(exchangeState : PhantomExchange.PhantomExchangeState, pairId : Text, fallback : Float) : Float {
    switch (PhantomExchange.getOrderBook(exchangeState, pairId)) {
      case (?book) {
        if (book.bids.size() > 0 and book.asks.size() > 0) {
          (book.bids[0].price + book.asks[0].price) / 2.0
        } else {
          fallback
        }
      };
      case null { fallback };
    }
  };

  func marketReference(
    decision      : RoutingDecision,
    exchangeState : PhantomExchange.PhantomExchangeState,
    pairId        : Text,
  ) : Float {
    let midpoint = marketMidpoint(exchangeState, pairId, decision.aggregateExpectedPrice);
    if (midpoint > 0.0) midpoint else decision.aggregateExpectedPrice
  };

  func fallbackAsk(bestBid : Float, lastPrice : Float, tickSize : Float) : Float {
    if (bestBid > 0.0 and tickSize > 0.0) {
      bestBid + tickSize
    } else if (lastPrice > 0.0) {
      lastPrice
    } else {
      1.0
    }
  };

  func costToBps(cost : Float, price : Float, quantity : Float) : Float {
    let notional = price * Float.max(quantity, MIN_ORDER_QTY);
    if (notional <= 0.0) { return 0.0 };
    (cost / notional) * 10000.0
  };

  func normalizedParticipation(request : SmartOrderRequest) : Float {
    let raw = if (request.participationRate <= 0.0) DEFAULT_PARTICIPATION_RATE else request.participationRate;
    Float.min(1.0, Float.max(DEFAULT_PARTICIPATION_RATE, raw))
  };

  func adaptiveParticipation(context : MarketContext) : Float {
    if (context.volatilityScore > Phi.PHI_INV) 0.146 else DEFAULT_PARTICIPATION_RATE
  };

  func optionOr(value : ?Float, fallback : Float) : Float {
    switch (value) {
      case (?v) { v };
      case null { fallback };
    }
  };

  func clampQty(quantity : Float) : Float {
    Float.max(MIN_ORDER_QTY, quantity)
  };

  func rollingAverage(current : Float, count : Nat, nextValue : Float) : Float {
    if (count <= 1) { return nextValue };
    ((current * (count - 1).toFloat()) + nextValue) / count.toFloat()
  };

  func hasVenueKind(plans : [ChildOrderPlan], kind : VenueKind) : Bool {
    switch (Array.find<ChildOrderPlan>(plans, func(plan) { plan.kind == kind })) {
      case null { false };
      case (?_) { true };
    }
  };

  func minNat(a : Nat, b : Nat) : Nat {
    if (a < b) a else b
  };

  func maxNat(a : Nat, b : Nat) : Nat {
    if (a > b) a else b
  };
};
