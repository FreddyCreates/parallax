import Phi "phi";
import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";

module {
  public type StrategyModel = { #avellanedaStoikov; #gueantLehalleTapia; #inventoryAware; #dynamicAmm };
  public type CFMMModel = { #constantProduct; #constantSum; #constantMean; #hybrid; #concentratedLiquidity };

  public type StrategyConfig = {
    riskAversion : Float;
    orderArrivalIntensity : Float;
    liquiditySlope : Float;
    timeHorizon : Float;
    minSpreadBps : Float;
    maxSpreadBps : Float;
    skewIntensity : Float;
    inventoryMeanReversion : Float;
    baseFeeBps : Float;
    maxFeeBps : Float;
  };

  public type MarketState = {
    midPrice : Float;
    bestBid : Float;
    bestAsk : Float;
    fairPrice : Float;
    oraclePrice : Float;
    volatility : Float;
    depthImbalance : Float;
    recentVolume : Float;
    mevRisk : Float;
    toxicFlowRatio : Float;
    adverseSelectionScore : Float;
  };

  public type InventoryState = {
    baseInventory : Float;
    quoteInventory : Float;
    inventoryCostBasis : Float;
    realizedPnl : Float;
    unrealizedPnl : Float;
    inventoryLimit : Float;
    targetBaseInventory : Float;
  };

  public type RiskLimits = {
    maxInventory : Float;
    maxDrawdown : Float;
    maxToxicFlow : Float;
    maxAdverseSelection : Float;
    maxNotional : Float;
    lossAversionLambda : Float;
  };

  public type RiskSignal = {
    inventoryRisk : Float;
    adverseSelectionRisk : Float;
    toxicFlowRisk : Float;
    lossAverseScore : Float;
    quoteThrottle : Float;
    shouldHedge : Bool;
    shouldPause : Bool;
  };

  public type QuoteIntent = {
    model : StrategyModel;
    reservationPrice : Float;
    bidPrice : Float;
    askPrice : Float;
    bidSize : Float;
    askSize : Float;
    spreadBps : Float;
    skew : Float;
    confidence : Float;
    quoteEnabled : Bool;
  };

  public type InventoryPolicy = {
    targetInventory : Float;
    hedgeRatio : Float;
    rebalanceUrgency : Float;
    skewDirection : Float;
    quoteParticipation : Float;
  };

  public type SpreadOptimization = {
    targetSpreadBps : Float;
    volAdjustedSpreadBps : Float;
    feeAdjustedSpreadBps : Float;
    oracleAnchorPrice : Float;
    impermanentLossBufferBps : Float;
  };

  public type PoolAsset = {
    symbol : Text;
    reserve : Float;
    weight : Float;
    oraclePrice : Float;
  };

  public type ConcentratedLiquidityBand = {
    lowerPrice : Float;
    upperPrice : Float;
    liquidity : Float;
    feeWeight : Float;
    active : Bool;
  };

  public type DynamicFeeState = {
    baseFeeBps : Float;
    currentFeeBps : Float;
    feeCapBps : Float;
    lastFeeUpdateBeat : Int;
  };

  public type OracleGuard = {
    referencePrice : Float;
    maxDeviationBps : Float;
    staleAfterBeats : Int;
    lastUpdateBeat : Int;
  };

  public type MEVProtection = {
    sandwichRisk : Float;
    maxSlippageBps : Float;
    virtualReserveFactor : Float;
    latencyWindowBeats : Int;
  };

  public type CFMMState = {
    poolId : Text;
    model : CFMMModel;
    assets : [PoolAsset];
    invariant : Float;
    amplification : Float;
    concentration : [ConcentratedLiquidityBand];
    feeState : DynamicFeeState;
    oracleGuard : OracleGuard;
    mevProtection : MEVProtection;
    volatilitySpreadBps : Float;
    impermanentLossScore : Float;
    lastRebalanceBeat : Int;
  };

  public type LiquidityAllocation = {
    poolId : Text;
    targetWeight : Float;
    capitalAllocated : Float;
    rebalanceDelta : Float;
    expectedApr : Float;
  };

  public type LPValuation = {
    poolValue : Float;
    lpSupply : Float;
    lpTokenPrice : Float;
    accruedFees : Float;
    impermanentLoss : Float;
    netAssetValue : Float;
    hedgeAdjustedValue : Float;
  };

  public type YieldFarmingPlan = {
    bestPoolId : ?Text;
    expectedNetApr : Float;
    hedgeRatio : Float;
    rebalanceUrgency : Float;
  };

  public type PairInput = {
    pairId : Text;
    baseSymbol : Text;
    quoteSymbol : Text;
    market : MarketState;
    inventory : InventoryState;
    lpTokenSupply : Float;
    weightBase : Float;
    weightQuote : Float;
  };

  public type StrategySnapshot = {
    pairId : Text;
    beat : Int;
    quote : QuoteIntent;
    avellanedaStoikov : QuoteIntent;
    gueantLehalleTapia : QuoteIntent;
    inventoryPolicy : InventoryPolicy;
    spreadOptimization : SpreadOptimization;
    risk : RiskSignal;
    pool : CFMMState;
    lpValuation : LPValuation;
    yieldPlan : YieldFarmingPlan;
  };

  public type MarketMakingState = {
    strategyConfig : StrategyConfig;
    riskLimits : RiskLimits;
    pools : [(Text, CFMMState)];
    inventories : [(Text, InventoryState)];
    latestSnapshots : [(Text, StrategySnapshot)];
    latestQuotes : [(Text, QuoteIntent)];
    allocations : [LiquidityAllocation];
    totalValueLocked : Float;
    totalFeesEarned : Float;
    totalImpermanentLossSaved : Float;
    lastRebalanceBeat : Int;
  };

  public func defaultInventoryState(limit : Float) : InventoryState {
    {
      baseInventory = 0.0;
      quoteInventory = limit;
      inventoryCostBasis = 0.0;
      realizedPnl = 0.0;
      unrealizedPnl = 0.0;
      inventoryLimit = limit;
      targetBaseInventory = 0.0;
    }
  };

  public func defaultMarketMakingState() : MarketMakingState {
    {
      strategyConfig = {
        riskAversion = 0.15;
        orderArrivalIntensity = 1.618;
        liquiditySlope = Phi.PHI_INV;
        timeHorizon = 1.0;
        minSpreadBps = 8.0;
        maxSpreadBps = 200.0;
        skewIntensity = 0.85;
        inventoryMeanReversion = Phi.PHI_INV;
        baseFeeBps = 5.0;
        maxFeeBps = 100.0;
      };
      riskLimits = {
        maxInventory = Phi.PHI * 1000.0;
        maxDrawdown = 5000.0;
        maxToxicFlow = 0.55;
        maxAdverseSelection = 0.70;
        maxNotional = 500000.0;
        lossAversionLambda = 2.25;
      };
      pools = [];
      inventories = [];
      latestSnapshots = [];
      latestQuotes = [];
      allocations = [];
      totalValueLocked = 0.0;
      totalFeesEarned = 0.0;
      totalImpermanentLossSaved = 0.0;
      lastRebalanceBeat = 0;
    }
  };

  func clamp(minimum : Float, value : Float, maximum : Float) : Float {
    Float.max(minimum, Float.min(maximum, value))
  };

  func clamp01(value : Float) : Float {
    clamp(0.0, value, 1.0)
  };

  func safeDiv(n : Float, d : Float) : Float {
    if (Float.abs(d) < 0.000000001) 0.0 else n / d
  };

  func inventoryRatio(inventory : InventoryState) : Float {
    safeDiv(inventory.baseInventory - inventory.targetBaseInventory, Float.max(1.0, inventory.inventoryLimit))
  };

  func spreadFromPrices(bid : Float, ask : Float) : Float {
    if (bid <= 0.0 or ask <= 0.0 or ask <= bid) 0.0
    else safeDiv(ask - bid, (ask + bid) / 2.0) * 10000.0
  };

  func poolValue(assets : [PoolAsset]) : Float {
    Array.foldLeft<PoolAsset, Float>(assets, 0.0, func(acc, asset) {
      acc + asset.reserve * Float.max(0.000001, asset.oraclePrice)
    })
  };

  func pairAssets(pool : CFMMState) : (PoolAsset, PoolAsset) {
    if (pool.assets.size() >= 2) {
      (pool.assets[0], pool.assets[1])
    } else {
      (
        { symbol = "BASE"; reserve = 1.0; weight = 0.5; oraclePrice = 1.0 },
        { symbol = "QUOTE"; reserve = 1.0; weight = 0.5; oraclePrice = 1.0 },
      )
    }
  };

  public func assessRisk(market : MarketState, inventory : InventoryState, limits : RiskLimits) : RiskSignal {
    let invRisk = clamp01(Float.abs(inventoryRatio(inventory)) / Float.max(0.000001, safeDiv(limits.maxInventory, Float.max(1.0, inventory.inventoryLimit))));
    let oracleDrift = clamp01(Float.abs(market.oraclePrice - market.midPrice) / Float.max(0.000001, market.midPrice));
    let adverse = clamp01(Float.max(market.adverseSelectionScore, oracleDrift * 5.0));
    let toxic = clamp01(Float.max(market.toxicFlowRatio, market.mevRisk));
    let drawdown = if (inventory.unrealizedPnl + inventory.realizedPnl >= 0.0) 0.0 else Float.abs(inventory.unrealizedPnl + inventory.realizedPnl);
    let lossAverse = clamp01(safeDiv(drawdown * limits.lossAversionLambda, Float.max(1.0, limits.maxDrawdown)));
    let throttle = clamp01(invRisk * 0.35 + adverse * 0.25 + toxic * 0.25 + lossAverse * 0.15);
    {
      inventoryRisk = invRisk;
      adverseSelectionRisk = adverse;
      toxicFlowRisk = toxic;
      lossAverseScore = lossAverse;
      quoteThrottle = throttle;
      shouldHedge = invRisk > 0.55 or lossAverse > 0.55;
      shouldPause = toxic > limits.maxToxicFlow or adverse > limits.maxAdverseSelection or throttle > 0.92;
    }
  };

  public func avellanedaStoikov(config : StrategyConfig, market : MarketState, inventory : InventoryState, risk : RiskSignal) : QuoteIntent {
    let gamma = Float.max(0.001, config.riskAversion);
    let k = Float.max(0.001, config.orderArrivalIntensity);
    let sigma2T = Float.max(0.000001, market.volatility * market.volatility * Float.max(0.25, config.timeHorizon));
    let invRatio = inventoryRatio(inventory);
    let reservationShift = invRatio * gamma * sigma2T * Float.max(1.0, market.midPrice);
    let reservation = Float.max(0.000001, market.fairPrice - reservationShift);
    let spreadPrice = Float.max(
      market.midPrice * config.minSpreadBps / 10000.0,
      market.midPrice * (gamma * sigma2T + Float.log(1.0 + gamma / k) * 0.01 + market.toxicFlowRatio * 0.002 + market.mevRisk * 0.0015)
    );
    let boundedSpreadPrice = Float.min(market.midPrice * config.maxSpreadBps / 10000.0, spreadPrice);
    let skew = clamp(-0.95, -(invRatio * config.skewIntensity + market.depthImbalance * 0.25), 0.95);
    let half = boundedSpreadPrice / 2.0;
    let rawBid = Float.max(0.000001, reservation - half * (1.0 + skew));
    let rawAsk = Float.max(rawBid + market.midPrice * 0.000001, reservation + half * (1.0 - skew));
    let capacity = clamp01(1.0 - Float.abs(invRatio));
    let bidSize = Float.max(0.0, (0.25 + capacity * (1.0 - Float.max(0.0, skew))) * (1.0 - risk.quoteThrottle));
    let askSize = Float.max(0.0, (0.25 + capacity * (1.0 + Float.min(0.0, skew) * -1.0)) * (1.0 - risk.quoteThrottle));
    {
      model = #avellanedaStoikov;
      reservationPrice = reservation;
      bidPrice = rawBid;
      askPrice = rawAsk;
      bidSize = bidSize;
      askSize = askSize;
      spreadBps = spreadFromPrices(rawBid, rawAsk);
      skew = skew;
      confidence = clamp01(1.0 - risk.quoteThrottle * 0.8);
      quoteEnabled = not risk.shouldPause;
    }
  };

  public func gueantLehalleTapia(config : StrategyConfig, market : MarketState, inventory : InventoryState, risk : RiskSignal) : QuoteIntent {
    let invRatio = inventoryRatio(inventory);
    let liquidityPenalty = Float.abs(market.depthImbalance) * config.liquiditySlope;
    let spreadBps = clamp(
      config.minSpreadBps,
      config.minSpreadBps + market.volatility * 10000.0 * 0.75 + liquidityPenalty * 75.0 + market.adverseSelectionScore * 60.0 + market.toxicFlowRatio * 45.0,
      config.maxSpreadBps,
    );
    let spreadPrice = Float.max(market.midPrice * spreadBps / 10000.0, market.midPrice * config.minSpreadBps / 10000.0);
    let reservation = Float.max(0.000001, market.oraclePrice - market.midPrice * (invRatio * config.inventoryMeanReversion * 0.5 + market.depthImbalance * 0.1));
    let skew = clamp(-0.95, -(invRatio * config.skewIntensity * 1.15 + market.depthImbalance * 0.5), 0.95);
    let half = spreadPrice / 2.0;
    let bid = Float.max(0.000001, reservation - half * (1.0 + skew));
    let ask = Float.max(bid + market.midPrice * 0.000001, reservation + half * (1.0 - skew));
    let baseSize = Float.max(0.1, (1.0 - risk.quoteThrottle) * (1.0 + market.recentVolume / 100000.0));
    {
      model = #gueantLehalleTapia;
      reservationPrice = reservation;
      bidPrice = bid;
      askPrice = ask;
      bidSize = baseSize * (1.0 - Float.max(0.0, skew));
      askSize = baseSize * (1.0 + Float.min(0.0, skew) * -1.0);
      spreadBps = spreadFromPrices(bid, ask);
      skew = skew;
      confidence = clamp01(1.0 - risk.quoteThrottle * 0.7);
      quoteEnabled = not risk.shouldPause;
    }
  };

  public func buildInventoryPolicy(config : StrategyConfig, inventory : InventoryState, risk : RiskSignal) : InventoryPolicy {
    let invRatio = inventoryRatio(inventory);
    let urgency = clamp01(Float.abs(invRatio) * config.inventoryMeanReversion + risk.lossAverseScore * 0.5 + risk.toxicFlowRisk * 0.35);
    {
      targetInventory = inventory.targetBaseInventory;
      hedgeRatio = clamp01(urgency * 0.85 + risk.adverseSelectionRisk * 0.15);
      rebalanceUrgency = urgency;
      skewDirection = clamp(-1.0, -invRatio, 1.0);
      quoteParticipation = clamp01(1.0 - risk.quoteThrottle);
    }
  };

  public func optimizeSpread(config : StrategyConfig, market : MarketState, risk : RiskSignal, avs : QuoteIntent, glt : QuoteIntent) : SpreadOptimization {
    let volAdjusted = clamp(config.minSpreadBps, (avs.spreadBps * 0.55 + glt.spreadBps * 0.45) + market.volatility * 10000.0 * 0.25, config.maxSpreadBps);
    let feeAdjusted = clamp(config.baseFeeBps, config.baseFeeBps + market.volatility * 30.0 + risk.toxicFlowRisk * 45.0 + market.mevRisk * 35.0, config.maxFeeBps);
    let ilBuffer = clamp(0.0, market.volatility * 10000.0 * 0.5 + Float.abs(market.oraclePrice - market.midPrice) / Float.max(0.000001, market.midPrice) * 5000.0, config.maxSpreadBps);
    {
      targetSpreadBps = clamp(config.minSpreadBps, volAdjusted + risk.quoteThrottle * 35.0 + ilBuffer * 0.15, config.maxSpreadBps);
      volAdjustedSpreadBps = volAdjusted;
      feeAdjustedSpreadBps = feeAdjusted;
      oracleAnchorPrice = if (market.oraclePrice > 0.0) market.oraclePrice else market.fairPrice;
      impermanentLossBufferBps = ilBuffer;
    }
  };

  func mergeQuotes(avs : QuoteIntent, glt : QuoteIntent, spreadOpt : SpreadOptimization, inventory : InventoryPolicy, risk : RiskSignal) : QuoteIntent {
    let reservation = (avs.reservationPrice * 0.6 + glt.reservationPrice * 0.4 + spreadOpt.oracleAnchorPrice * 0.15) / 1.15;
    let spreadPrice = Float.max(reservation * spreadOpt.targetSpreadBps / 10000.0, reservation * 0.000001);
    let half = spreadPrice / 2.0;
    let skew = clamp(-0.95, (avs.skew * 0.55 + glt.skew * 0.45 + inventory.skewDirection * 0.2) / 1.2, 0.95);
    let bid = Float.max(0.000001, reservation - half * (1.0 + skew));
    let ask = Float.max(bid + reservation * 0.000001, reservation + half * (1.0 - skew));
    let bidSize = Float.max(0.0, (avs.bidSize * 0.5 + glt.bidSize * 0.5) * inventory.quoteParticipation);
    let askSize = Float.max(0.0, (avs.askSize * 0.5 + glt.askSize * 0.5) * inventory.quoteParticipation);
    {
      model = #inventoryAware;
      reservationPrice = reservation;
      bidPrice = bid;
      askPrice = ask;
      bidSize = bidSize;
      askSize = askSize;
      spreadBps = spreadFromPrices(bid, ask);
      skew = skew;
      confidence = clamp01((avs.confidence * 0.5 + glt.confidence * 0.5) * (1.0 - risk.quoteThrottle * 0.5));
      quoteEnabled = avs.quoteEnabled and glt.quoteEnabled and not risk.shouldPause;
    }
  };

  public func constantProductInvariant(x : Float, y : Float) : Float {
    Float.max(0.0, x) * Float.max(0.0, y)
  };

  public func constantSumInvariant(x : Float, y : Float) : Float {
    Float.max(0.0, x) + Float.max(0.0, y)
  };

  public func constantMeanInvariant(assets : [PoolAsset]) : Float {
    Float.exp(
      Array.foldLeft<PoolAsset, Float>(assets, 0.0, func(acc, asset) {
        acc + Float.max(0.0, asset.weight) * Float.log(Float.max(0.000001, asset.reserve))
      })
    )
  };

  public func hybridInvariant(x : Float, y : Float, amplification : Float) : Float {
    let a = clamp01(amplification);
    constantSumInvariant(x, y) * a + (2.0 * Float.sqrt(Float.max(0.0, x) * Float.max(0.0, y))) * (1.0 - a)
  };

  public func concentratedLiquidityInvariant(bands : [ConcentratedLiquidityBand]) : Float {
    Array.foldLeft<ConcentratedLiquidityBand, Float>(bands, 0.0, func(acc, band) {
      let width = Float.max(0.000001, band.upperPrice - band.lowerPrice);
      acc + band.liquidity * Float.sqrt(width) * (1.0 + band.feeWeight)
    })
  };

  public func computeInvariant(pool : CFMMState) : Float {
    let (a0, a1) = pairAssets(pool);
    switch (pool.model) {
      case (#constantProduct) { constantProductInvariant(a0.reserve, a1.reserve) };
      case (#constantSum) { constantSumInvariant(a0.reserve, a1.reserve) };
      case (#constantMean) { constantMeanInvariant(pool.assets) };
      case (#hybrid) { hybridInvariant(a0.reserve, a1.reserve, pool.amplification) };
      case (#concentratedLiquidity) { concentratedLiquidityInvariant(pool.concentration) };
    }
  };

  public func quoteCfmmSwap(pool : CFMMState, assetIn : Text, assetOut : Text, amountIn : Float) : Float {
    if (pool.assets.size() < 2 or amountIn <= 0.0) { return 0.0 };
    let feeFactor = 1.0 - pool.feeState.currentFeeBps / 10000.0;
    let dx = amountIn * feeFactor;
    let a0 = pool.assets[0];
    let a1 = pool.assets[1];
    let x = if (a0.symbol == assetIn) a0 else a1;
    let y = if (a0.symbol == assetOut) a0 else a1;
    switch (pool.model) {
      case (#constantProduct) {
        let k = constantProductInvariant(x.reserve, y.reserve);
        let newX = x.reserve + dx;
        Float.max(0.0, y.reserve - safeDiv(k, Float.max(0.000001, newX)))
      };
      case (#constantSum) { Float.max(0.0, Float.min(dx, y.reserve)) };
      case (#constantMean) {
        let exponent = safeDiv(Float.max(0.000001, x.weight), Float.max(0.000001, y.weight));
        let ratio = safeDiv(x.reserve, x.reserve + dx);
        Float.max(0.0, y.reserve * (1.0 - Float.exp(exponent * Float.log(Float.max(0.000001, ratio)))))
      };
      case (#hybrid) {
        let cpOut = quoteCfmmSwap({ pool with model = #constantProduct }, assetIn, assetOut, amountIn);
        let csOut = quoteCfmmSwap({ pool with model = #constantSum }, assetIn, assetOut, amountIn);
        cpOut * (1.0 - clamp01(pool.amplification)) + csOut * clamp01(pool.amplification)
      };
      case (#concentratedLiquidity) {
        let activeLiquidity = Array.foldLeft<ConcentratedLiquidityBand, Float>(pool.concentration, 0.0, func(acc, band) {
          if (band.active) acc + band.liquidity else acc
        });
        let boost = 1.0 + safeDiv(activeLiquidity, Float.max(1.0, x.reserve + y.reserve));
        let baseOut = quoteCfmmSwap({ pool with model = #constantProduct }, assetIn, assetOut, amountIn);
        Float.min(y.reserve, baseOut * boost)
      };
    }
  };

  func computeImpermanentLoss(pool : CFMMState, market : MarketState) : Float {
    let (base, quote) = pairAssets(pool);
    if (base.oraclePrice <= 0.0 or quote.oraclePrice <= 0.0) { return 0.0 };
    let priceRatio = Float.max(0.000001, market.oraclePrice / Float.max(0.000001, market.fairPrice));
    let il = 1.0 - (2.0 * Float.sqrt(priceRatio) / (1.0 + priceRatio));
    clamp01(Float.abs(il) + market.volatility * 0.2 + safeDiv(Float.abs(base.weight - quote.weight), 2.0))
  };

  func defaultPool(input : PairInput, config : StrategyConfig, beat : Int) : CFMMState {
    let mid = Float.max(0.000001, input.market.midPrice);
    let baseReserve = Float.max(1000.0, Float.abs(input.inventory.baseInventory) + 1000.0);
    let quoteReserve = Float.max(1000.0, input.inventory.quoteInventory + mid * 1000.0);
    let bands = [
      { lowerPrice = mid * (1.0 - Float.max(0.01, input.market.volatility)); upperPrice = mid; liquidity = quoteReserve * 0.30; feeWeight = 0.5; active = input.market.midPrice <= mid },
      { lowerPrice = mid; upperPrice = mid * (1.0 + Float.max(0.01, input.market.volatility)); liquidity = quoteReserve * 0.45; feeWeight = 1.0; active = true },
      { lowerPrice = mid * (1.0 + Float.max(0.01, input.market.volatility)); upperPrice = mid * (1.0 + Float.max(0.02, input.market.volatility * 2.0)); liquidity = quoteReserve * 0.25; feeWeight = 1.5; active = input.market.midPrice >= mid },
    ];
    let pool : CFMMState = {
      poolId = input.pairId;
      model = #concentratedLiquidity;
      assets = [
        { symbol = input.baseSymbol; reserve = baseReserve; weight = clamp(0.05, input.weightBase, 0.95); oraclePrice = mid },
        { symbol = input.quoteSymbol; reserve = quoteReserve; weight = clamp(0.05, input.weightQuote, 0.95); oraclePrice = 1.0 },
      ];
      invariant = 0.0;
      amplification = Phi.PHI_INV;
      concentration = bands;
      feeState = { baseFeeBps = config.baseFeeBps; currentFeeBps = config.baseFeeBps; feeCapBps = config.maxFeeBps; lastFeeUpdateBeat = beat };
      oracleGuard = { referencePrice = input.market.oraclePrice; maxDeviationBps = 75.0; staleAfterBeats = 21; lastUpdateBeat = beat };
      mevProtection = { sandwichRisk = input.market.mevRisk; maxSlippageBps = 35.0; virtualReserveFactor = 1.0 + input.market.mevRisk * 0.5; latencyWindowBeats = 3 };
      volatilitySpreadBps = input.market.volatility * 10000.0;
      impermanentLossScore = 0.0;
      lastRebalanceBeat = beat;
    };
    { pool with invariant = computeInvariant(pool) }
  };

  func updatePool(pool : CFMMState, input : PairInput, spreadOpt : SpreadOptimization, risk : RiskSignal, beat : Int) : CFMMState {
    let il = computeImpermanentLoss(pool, input.market);
    let fee = clamp(pool.feeState.baseFeeBps, pool.feeState.baseFeeBps + input.market.volatility * 60.0 + risk.toxicFlowRisk * 45.0 + risk.adverseSelectionRisk * 30.0 + il * 40.0, pool.feeState.feeCapBps);
    let updated : CFMMState = {
      pool with
      feeState = { pool.feeState with currentFeeBps = fee; lastFeeUpdateBeat = beat };
      oracleGuard = { pool.oracleGuard with referencePrice = input.market.oraclePrice; lastUpdateBeat = beat };
      mevProtection = { pool.mevProtection with sandwichRisk = input.market.mevRisk; virtualReserveFactor = 1.0 + input.market.mevRisk * 0.5 };
      volatilitySpreadBps = spreadOpt.targetSpreadBps;
      impermanentLossScore = il;
      lastRebalanceBeat = if (risk.shouldHedge) beat else pool.lastRebalanceBeat;
    };
    { updated with invariant = computeInvariant(updated) }
  };

  public func valueLpToken(pool : CFMMState, lpSupply : Float, market : MarketState) : LPValuation {
    let gross = poolValue(pool.assets);
    let fees = gross * pool.feeState.currentFeeBps / 10000.0 * Float.max(0.01, market.recentVolume / 1000000.0);
    let il = computeImpermanentLoss(pool, market);
    let supply = Float.max(1.0, lpSupply);
    let nav = gross + fees - gross * il;
    let hedgeValue = nav + gross * il * 0.5;
    {
      poolValue = gross;
      lpSupply = supply;
      lpTokenPrice = nav / supply;
      accruedFees = fees;
      impermanentLoss = gross * il;
      netAssetValue = nav;
      hedgeAdjustedValue = hedgeValue;
    }
  };

  func buildYieldPlan(snapshot : StrategySnapshot) : YieldFarmingPlan {
    let grossApr = snapshot.pool.feeState.currentFeeBps * Float.max(0.25, snapshot.quote.confidence) + snapshot.spreadOptimization.impermanentLossBufferBps * 0.05;
    let riskHaircut = (snapshot.risk.quoteThrottle + snapshot.pool.impermanentLossScore) * 25.0;
    {
      bestPoolId = ?snapshot.pairId;
      expectedNetApr = Float.max(0.0, grossApr - riskHaircut);
      hedgeRatio = snapshot.inventoryPolicy.hedgeRatio;
      rebalanceUrgency = snapshot.inventoryPolicy.rebalanceUrgency;
    }
  };

  func buildAllocations(snapshots : [(Text, StrategySnapshot)], capital : Float) : [LiquidityAllocation] {
    let scoreSum = Array.foldLeft<(Text, StrategySnapshot), Float>(snapshots, 0.0, func(acc, entry) {
      let s = entry.1;
      let score = Float.max(0.01, s.yieldPlan.expectedNetApr * 0.01 + s.quote.confidence * 0.7 + (1.0 - s.risk.quoteThrottle) * 0.3);
      acc + score
    });
    Array.map<(Text, StrategySnapshot), LiquidityAllocation>(snapshots, func(entry) {
      let s = entry.1;
      let score = Float.max(0.01, s.yieldPlan.expectedNetApr * 0.01 + s.quote.confidence * 0.7 + (1.0 - s.risk.quoteThrottle) * 0.3);
      let weight = safeDiv(score, Float.max(0.01, scoreSum));
      let allocated = capital * weight;
      {
        poolId = s.pairId;
        targetWeight = weight;
        capitalAllocated = allocated;
        rebalanceDelta = allocated * (s.inventoryPolicy.rebalanceUrgency - 0.5);
        expectedApr = s.yieldPlan.expectedNetApr;
      }
    })
  };

  func upsertByKey<T>(items : [(Text, T)], key : Text, value : T) : [(Text, T)] {
    var found = false;
    let updated = Array.map<(Text, T), (Text, T)>(items, func(entry) {
      if (entry.0 == key) {
        found := true;
        (key, value)
      } else {
        entry
      }
    });
    if (found) updated else Array.append(updated, [(key, value)])
  };

  public func getSnapshot(state : MarketMakingState, pairId : Text) : ?StrategySnapshot {
    switch (Array.find<(Text, StrategySnapshot)>(state.latestSnapshots, func(entry) { entry.0 == pairId })) {
      case (?entry) { ?entry.1 };
      case null { null };
    }
  };

  public func tickMarketMaking(state : MarketMakingState, inputs : [PairInput], beat : Int) : MarketMakingState {
    if (inputs.size() == 0) { return state };
    var pools = state.pools;
    var inventories = state.inventories;
    var snapshots : [(Text, StrategySnapshot)] = [];
    var quotes : [(Text, QuoteIntent)] = [];
    var tvl = 0.0;
    var fees = state.totalFeesEarned;
    var ilSaved = state.totalImpermanentLossSaved;
    let capital = Array.foldLeft<PairInput, Float>(inputs, 0.0, func(acc, input) {
      acc + input.inventory.quoteInventory + Float.abs(input.inventory.baseInventory) * Float.max(0.000001, input.market.midPrice)
    });

    for (input in inputs.vals()) {
      let inventory = input.inventory;
      inventories := upsertByKey<InventoryState>(inventories, input.pairId, inventory);
      let pool = switch (Array.find<(Text, CFMMState)>(pools, func(entry) { entry.0 == input.pairId })) {
        case (?entry) { entry.1 };
        case null { defaultPool(input, state.strategyConfig, beat) };
      };
      let risk = assessRisk(input.market, inventory, state.riskLimits);
      let avs = avellanedaStoikov(state.strategyConfig, input.market, inventory, risk);
      let glt = gueantLehalleTapia(state.strategyConfig, input.market, inventory, risk);
      let inventoryPolicy = buildInventoryPolicy(state.strategyConfig, inventory, risk);
      let spreadOpt = optimizeSpread(state.strategyConfig, input.market, risk, avs, glt);
      let finalQuote = mergeQuotes(avs, glt, spreadOpt, inventoryPolicy, risk);
      let updatedPool = updatePool(pool, input, spreadOpt, risk, beat);
      let lpValuation = valueLpToken(updatedPool, input.lpTokenSupply, input.market);
      let provisional : StrategySnapshot = {
        pairId = input.pairId;
        beat = beat;
        quote = finalQuote;
        avellanedaStoikov = avs;
        gueantLehalleTapia = glt;
        inventoryPolicy = inventoryPolicy;
        spreadOptimization = spreadOpt;
        risk = risk;
        pool = updatedPool;
        lpValuation = lpValuation;
        yieldPlan = { bestPoolId = null; expectedNetApr = 0.0; hedgeRatio = inventoryPolicy.hedgeRatio; rebalanceUrgency = inventoryPolicy.rebalanceUrgency };
      };
      let finalSnapshot = { provisional with yieldPlan = buildYieldPlan(provisional) };
      pools := upsertByKey<CFMMState>(pools, input.pairId, updatedPool);
      snapshots := upsertByKey<StrategySnapshot>(snapshots, input.pairId, finalSnapshot);
      quotes := upsertByKey<QuoteIntent>(quotes, input.pairId, finalQuote);
      tvl += lpValuation.poolValue;
      fees += lpValuation.accruedFees;
      ilSaved += lpValuation.impermanentLoss * finalSnapshot.inventoryPolicy.hedgeRatio;
    };

    {
      state with
      pools = pools;
      inventories = inventories;
      latestSnapshots = snapshots;
      latestQuotes = quotes;
      allocations = buildAllocations(snapshots, Float.max(1.0, capital));
      totalValueLocked = tvl;
      totalFeesEarned = fees;
      totalImpermanentLossSaved = ilSaved;
      lastRebalanceBeat = beat;
    }
  };
}
