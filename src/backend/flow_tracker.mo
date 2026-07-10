import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Phi "phi";
import GraphControl "graph_control";
import PhantomClearinghouse "phantom_clearinghouse";
import PhantomExchange "phantom_exchange";

module {

  public type FlowType = { #settlement; #crossChain; #arbitrage; #liquidity; #stress };
  public type RiskTier = { #low; #elevated; #high; #critical };

  public type FlowRecord = {
    flowId : Nat;
    flowType : FlowType;
    sourceId : Text;
    targetId : Text;
    asset : Text;
    amount : Float;
    notional : Float;
    price : Float;
    pairId : ?Text;
    poolId : ?Text;
    beat : Int;
    economicWeight : Float;
    settlementId : ?Nat;
    crossChainId : ?Nat;
  };

  public type LiquidityProvider = {
    providerId : Text;
    cumulativeProvided : Float;
    share : Float;
    lastActiveBeat : Int;
  };

  public type PoolState = {
    poolId : Text;
    pairId : Text;
    baseToken : Text;
    quoteToken : Text;
    baseBalance : Float;
    quoteBalance : Float;
    grossBaseThroughput : Float;
    grossQuoteThroughput : Float;
    cumulativeVolume : Float;
    referencePrice : Float;
    lastPrice : Float;
    utilizationRate : Float;
    impermanentLoss : Float;
    liquidityConcentration : Float;
    activeLiquidityProviders : [LiquidityProvider];
    lastUpdateBeat : Int;
  };

  public type NodeMetrics = {
    nodeId : Text;
    totalInflow : Float;
    totalOutflow : Float;
    inDegree : Nat;
    outDegree : Nat;
    degreeCentrality : Float;
    betweenness : Float;
    pageRank : Float;
    hubScore : Float;
    liquidityProviderScore : Float;
    systemicImportance : Float;
    isHub : Bool;
  };

  public type CircularFlow = {
    path : [Text];
    asset : Text;
    cycleLength : Nat;
    totalVolume : Float;
    firstBeat : Int;
    lastBeat : Int;
  };

  public type ArbitragePath = {
    path : [Text];
    assets : [Text];
    poolIds : [Text];
    syntheticRate : Float;
    profitability : Float;
    beat : Int;
  };

  public type ExposureCell = {
    sourceId : Text;
    targetId : Text;
    asset : Text;
    exposure : Float;
    riskWeight : Float;
  };

  public type HistoricalSnapshot = {
    beat : Int;
    totalVolume : Float;
    activeNodes : Nat;
    poolUtilization : Float;
    contagionRisk : Float;
    leverage : Float;
    anomalyCount : Nat;
  };

  public type FlowAnomaly = {
    anomalyId : Nat;
    category : Text;
    subject : Text;
    description : Text;
    score : Float;
    beat : Int;
  };

  public type AssetFlowAnalytics = {
    asset : Text;
    inflowVelocity : Float;
    outflowVelocity : Float;
    netFlow : Float;
    netDirection : Text;
    volumeWeightedFlowPrice : Float;
    persistence : Float;
    anomalyScore : Float;
    lastUpdateBeat : Int;
  };

  public type VisualizationNode = {
    id : Text;
    displayLabel : Text;
    nodeType : Text;
    size : Float;
    color : Text;
  };

  public type VisualizationEdge = {
    source : Text;
    target : Text;
    asset : Text;
    weight : Float;
    displayLabel : Text;
  };

  public type VisualizationGraph = {
    nodes : [VisualizationNode];
    edges : [VisualizationEdge];
    hubs : [Text];
    cycles : [[Text]];
  };

  public type TransactionGraphAnalytics = {
    totalNodes : Nat;
    totalEdges : Nat;
    averageDegree : Float;
    density : Float;
    nodeMetrics : [NodeMetrics];
    circularFlows : [CircularFlow];
    arbitragePaths : [ArbitragePath];
    topHubs : [Text];
    topLiquidityProviders : [Text];
  };

  public type SystemicRiskMetrics = {
    contagionRisk : Float;
    systemLeverage : Float;
    counterpartyConcentration : Float;
    exposureMatrix : [ExposureCell];
    systemicImportanceScores : [(Text, Float)];
    stressLossEstimate : Float;
    riskTier : RiskTier;
  };

  public type FlowTrackerState = {
    flowHistory : [FlowRecord];
    pools : [(Text, PoolState)];
    graphAnalytics : TransactionGraphAnalytics;
    riskMetrics : SystemicRiskMetrics;
    assetAnalytics : [AssetFlowAnalytics];
    anomalies : [FlowAnomaly];
    historicalSnapshots : [HistoricalSnapshot];
    visualization : VisualizationGraph;
    totalTrackedVolume : Float;
    nextFlowId : Nat;
    nextAnomalyId : Nat;
    lastProcessedFillId : Nat;
    lastProcessedSettlementId : Nat;
    lastProcessedCrossChainId : Nat;
    lastUpdateBeat : Int;
  };

  let MAX_FLOWS = 1500;
  let MAX_POOLS = 128;
  let MAX_CYCLES = 64;
  let MAX_ARBITRAGE = 64;
  let MAX_ANOMALIES = 128;
  let MAX_SNAPSHOTS = 365;
  let MAX_VIS_EDGES = 160;
  let MAX_VIS_NODES = 100;

  public func defaultFlowTrackerState() : FlowTrackerState {
    {
      flowHistory = [];
      pools = [];
      graphAnalytics = emptyGraphAnalytics();
      riskMetrics = emptyRiskMetrics();
      assetAnalytics = [];
      anomalies = [];
      historicalSnapshots = [];
      visualization = emptyVisualization();
      totalTrackedVolume = 0.0;
      nextFlowId = 1;
      nextAnomalyId = 1;
      lastProcessedFillId = 0;
      lastProcessedSettlementId = 0;
      lastProcessedCrossChainId = 0;
      lastUpdateBeat = 0;
    }
  };

  public func syncExchangeSettlements(
    state : FlowTrackerState,
    clearinghouse : PhantomClearinghouse.PhantomClearinghouseState,
    exchange : PhantomExchange.PhantomExchangeState,
    beat : Int,
  ) : (FlowTrackerState, PhantomClearinghouse.PhantomClearinghouseState) {
    var tracker = state;
    var clearing = clearinghouse;
    var maxFillId = state.lastProcessedFillId;

    for (fill in exchange.recentFills.vals()) {
      if (fill.fillId > state.lastProcessedFillId) {
        switch (findPair(exchange.pairs, fill.pairId)) {
          case (?pair) {
            let quoteAmount = fill.price * fill.quantity;
            clearing := PhantomClearinghouse.settleFill(
              clearing,
              fill.fillId,
              fill.pairId,
              fill.buyerPrincipal,
              fill.sellerPrincipal,
              pair.baseToken,
              pair.quoteToken,
              fill.quantity,
              quoteAmount,
              beat,
            );
            switch (findSettlementByFillId(clearing.recentSettlements, fill.fillId)) {
              case (?settlement) {
                tracker := recordSettlement(tracker, settlement, beat);
              };
              case null {};
            };
          };
          case null {};
        };
        if (fill.fillId > maxFillId) { maxFillId := fill.fillId };
      };
    };

    ({ tracker with lastProcessedFillId = maxFillId; lastUpdateBeat = beat }, clearing)
  };

  public func trackCrossChainSettlement(
    state : FlowTrackerState,
    settlement : PhantomClearinghouse.CrossChainSettlement,
    beat : Int,
  ) : FlowTrackerState {
    if (settlement.settlementId <= state.lastProcessedCrossChainId) { return state };

    let routeNode = "XCHAIN:" # settlement.sourceChain # "→" # settlement.destChain;
    let sourceNode = settlement.sourceChain # ":" # settlement.sourceToken;
    let targetNode = settlement.destChain # ":" # settlement.destToken;

    let flowA : FlowRecord = {
      flowId = state.nextFlowId;
      flowType = #crossChain;
      sourceId = sourceNode;
      targetId = routeNode;
      asset = settlement.sourceToken;
      amount = settlement.sourceAmount;
      notional = settlement.destAmount;
      price = settlement.exchangeRate;
      pairId = null;
      poolId = ?routeNode;
      beat = beat;
      economicWeight = 0.5;
      settlementId = ?settlement.settlementId;
      crossChainId = ?settlement.settlementId;
    };
    let flowB : FlowRecord = {
      flowId = state.nextFlowId + 1;
      flowType = #crossChain;
      sourceId = routeNode;
      targetId = targetNode;
      asset = settlement.destToken;
      amount = settlement.destAmount;
      notional = settlement.destAmount;
      price = settlement.exchangeRate;
      pairId = null;
      poolId = ?routeNode;
      beat = beat;
      economicWeight = 0.5;
      settlementId = ?settlement.settlementId;
      crossChainId = ?settlement.settlementId;
    };

    let appended = appendFlows(state.flowHistory, [flowA, flowB]);
    let updated = recomputeDerivedState({
      state with
      flowHistory = appended;
      nextFlowId = state.nextFlowId + 2;
      totalTrackedVolume = state.totalTrackedVolume + settlement.destAmount;
      lastProcessedCrossChainId = settlement.settlementId;
      lastUpdateBeat = beat;
    });
    updated
  };

  public func getVisualizationData(state : FlowTrackerState) : VisualizationGraph {
    state.visualization
  };

  public func getPoolStates(state : FlowTrackerState) : [PoolState] {
    Array.map<(Text, PoolState), PoolState>(state.pools, func (entry) { entry.1 })
  };

  public func getSystemicRiskMetrics(state : FlowTrackerState) : SystemicRiskMetrics {
    state.riskMetrics
  };

  public func toLiquidityNetwork(state : FlowTrackerState) : GraphControl.LiquidityNetwork {
    {
      pools = Array.map<(Text, PoolState), GraphControl.LiquidityPool>(state.pools, func (entry) {
        let pool = entry.1;
        {
          poolId = pool.poolId;
          pairId = pool.pairId;
          baseToken = pool.baseToken;
          quoteToken = pool.quoteToken;
          baseBalance = pool.baseBalance;
          quoteBalance = pool.quoteBalance;
          referencePrice = pool.referencePrice;
          lastPrice = pool.lastPrice;
          utilizationRate = pool.utilizationRate;
          impermanentLoss = pool.impermanentLoss;
        }
      })
    }
  };

  func recordSettlement(
    state : FlowTrackerState,
    settlement : PhantomClearinghouse.SettlementRecord,
    beat : Int,
  ) : FlowTrackerState {
    if (settlement.settlementId <= state.lastProcessedSettlementId) { return state };

    let poolId = poolNodeId(settlement.pairId);
    let price = if (settlement.baseAmount > 0.0) settlement.quoteAmount / settlement.baseAmount else 0.0;

    let flows : [FlowRecord] = [
      {
        flowId = state.nextFlowId;
        flowType = #settlement;
        sourceId = settlement.seller;
        targetId = poolId;
        asset = settlement.baseToken;
        amount = settlement.baseAmount;
        notional = settlement.quoteAmount;
        price = price;
        pairId = ?settlement.pairId;
        poolId = ?poolId;
        beat = beat;
        economicWeight = 0.5;
        settlementId = ?settlement.settlementId;
        crossChainId = null;
      },
      {
        flowId = state.nextFlowId + 1;
        flowType = #settlement;
        sourceId = poolId;
        targetId = settlement.buyer;
        asset = settlement.baseToken;
        amount = settlement.baseAmount;
        notional = settlement.quoteAmount;
        price = price;
        pairId = ?settlement.pairId;
        poolId = ?poolId;
        beat = beat;
        economicWeight = 0.5;
        settlementId = ?settlement.settlementId;
        crossChainId = null;
      },
      {
        flowId = state.nextFlowId + 2;
        flowType = #settlement;
        sourceId = settlement.buyer;
        targetId = poolId;
        asset = settlement.quoteToken;
        amount = settlement.quoteAmount;
        notional = settlement.quoteAmount;
        price = 1.0;
        pairId = ?settlement.pairId;
        poolId = ?poolId;
        beat = beat;
        economicWeight = 0.5;
        settlementId = ?settlement.settlementId;
        crossChainId = null;
      },
      {
        flowId = state.nextFlowId + 3;
        flowType = #settlement;
        sourceId = poolId;
        targetId = settlement.seller;
        asset = settlement.quoteToken;
        amount = settlement.quoteAmount;
        notional = settlement.quoteAmount;
        price = 1.0;
        pairId = ?settlement.pairId;
        poolId = ?poolId;
        beat = beat;
        economicWeight = 0.5;
        settlementId = ?settlement.settlementId;
        crossChainId = null;
      },
    ];

    let updatedPool = upsertPool(state.pools, settlement, price, beat);
    let appended = appendFlows(state.flowHistory, flows);

    recomputeDerivedState({
      state with
      flowHistory = appended;
      pools = updatedPool;
      nextFlowId = state.nextFlowId + flows.size();
      totalTrackedVolume = state.totalTrackedVolume + settlement.quoteAmount;
      lastProcessedSettlementId = settlement.settlementId;
      lastUpdateBeat = beat;
    })
  };

  func recomputeDerivedState(state : FlowTrackerState) : FlowTrackerState {
    let nodeIds = collectNodeIds(state.flowHistory);
    let ranks = computePageRank(nodeIds, state.flowHistory);
    let poolScores = poolProviderScores(state.pools);
    let nodeMetrics = computeNodeMetrics(nodeIds, state.flowHistory, ranks, poolScores);
    let cycles = detectCircularFlows(state.flowHistory);
    let arbitrage = detectArbitrage(state.pools, state.flowHistory, state.lastUpdateBeat);
    let graph = buildGraphAnalytics(nodeIds, state.flowHistory, nodeMetrics, cycles, arbitrage, state.pools);
    let risk = computeRiskMetrics(state.flowHistory, nodeMetrics, state.pools);
    let assets = computeAssetAnalytics(state.flowHistory, state.lastUpdateBeat);
    let anomalies = buildAnomalies(state.anomalies, state.nextAnomalyId, cycles, state.pools, assets, risk, state.lastUpdateBeat);
    let nextAnomalyId = state.nextAnomalyId + (anomalies.size() - state.anomalies.size());
    let vis = buildVisualization(nodeMetrics, state.flowHistory, cycles);
    let snapshots = appendSnapshot(state.historicalSnapshots, makeSnapshot(state.totalTrackedVolume, nodeIds.size(), state.pools, risk, anomalies.size(), state.lastUpdateBeat));

    {
      state with
      graphAnalytics = graph;
      riskMetrics = risk;
      assetAnalytics = assets;
      anomalies = anomalies;
      historicalSnapshots = snapshots;
      visualization = vis;
      nextAnomalyId = nextAnomalyId;
    }
  };

  func buildGraphAnalytics(
    nodeIds : [Text],
    flows : [FlowRecord],
    nodeMetrics : [NodeMetrics],
    cycles : [CircularFlow],
    arbitrage : [ArbitragePath],
    pools : [(Text, PoolState)],
  ) : TransactionGraphAnalytics {
    let totalNodes = nodeIds.size();
    let totalEdges = flows.size();
    let averageDegree = if (totalNodes == 0) 0.0 else (2.0 * totalEdges.toInt().toFloat()) / totalNodes.toInt().toFloat();
    let density = if (totalNodes <= 1) 0.0 else totalEdges.toInt().toFloat() / ((totalNodes * (totalNodes - 1)).toInt().toFloat());
    {
      totalNodes = totalNodes;
      totalEdges = totalEdges;
      averageDegree = averageDegree;
      density = density;
      nodeMetrics = nodeMetrics;
      circularFlows = cycles;
      arbitragePaths = arbitrage;
      topHubs = topNodes(nodeMetrics, 10, func (m) { m.systemicImportance });
      topLiquidityProviders = topProviders(pools, 10);
    }
  };

  func computeNodeMetrics(
    nodeIds : [Text],
    flows : [FlowRecord],
    ranks : [(Text, Float)],
    poolScores : [(Text, Float)],
  ) : [NodeMetrics] {
    let rawBetweenness = approxBetweenness(nodeIds, flows);
    let maxBetween = maxScore(rawBetweenness);
    Array.map<Text, NodeMetrics>(nodeIds, func (nodeId) {
      let inflow = sumFlows(flows, nodeId, true);
      let outflow = sumFlows(flows, nodeId, false);
      let inDegree = degree(flows, nodeId, true);
      let outDegree = degree(flows, nodeId, false);
      let rank = lookupScore(ranks, nodeId);
      let between = normalize(lookupScore(rawBetweenness, nodeId), maxBetween);
      let degreeCent = if (nodeIds.size() <= 1) 0.0 else (inDegree + outDegree).toInt().toFloat() / (2 * (nodeIds.size() - 1)).toInt().toFloat();
      let lpScore = lookupScore(poolScores, nodeId);
      let hubScore = (inflow + outflow) * (0.5 + rank);
      let systemic = 0.25 * degreeCent + 0.25 * between + 0.25 * rank + 0.25 * normalize(hubScore, totalFlowMagnitude(flows));
      {
        nodeId = nodeId;
        totalInflow = inflow;
        totalOutflow = outflow;
        inDegree = inDegree;
        outDegree = outDegree;
        degreeCentrality = degreeCent;
        betweenness = between;
        pageRank = rank;
        hubScore = hubScore;
        liquidityProviderScore = lpScore;
        systemicImportance = systemic + (0.2 * lpScore);
        isHub = systemic >= Phi.PHI_INV;
      }
    })
  };

  func computeRiskMetrics(
    flows : [FlowRecord],
    nodeMetrics : [NodeMetrics],
    pools : [(Text, PoolState)],
  ) : SystemicRiskMetrics {
    let exposures = buildExposureMatrix(flows);
    let totalExposure = Array.foldLeft<ExposureCell, Float>(exposures, 0.0, func (acc, e) { acc + e.exposure });
    let maxExposure = Array.foldLeft<ExposureCell, Float>(exposures, 0.0, func (acc, e) { if (e.exposure > acc) e.exposure else acc });
    let poolDepth = totalPoolDepth(pools);
    let leverage = if (poolDepth > 0.0) totalExposure / poolDepth else totalExposure;
    let concentration = exposureConcentration(exposures);
    let nodeImportance = Array.map<NodeMetrics, (Text, Float)>(nodeMetrics, func (m) { (m.nodeId, m.systemicImportance) });
    let contagion = Float.min(1.0, normalize(maxExposure, Float.max(totalExposure, 1.0)) + (0.35 * concentration) + (0.15 * Float.min(1.0, leverage / Phi.PHI)));
    let stressLoss = totalExposure * (0.08 + 0.22 * contagion);
    {
      contagionRisk = contagion;
      systemLeverage = leverage;
      counterpartyConcentration = concentration;
      exposureMatrix = exposures;
      systemicImportanceScores = nodeImportance;
      stressLossEstimate = stressLoss;
      riskTier = classifyRisk(contagion, leverage, concentration);
    }
  };

  func computeAssetAnalytics(flows : [FlowRecord], beat : Int) : [AssetFlowAnalytics] {
    let assets = uniqueAssets(flows);
    Array.map<Text, AssetFlowAnalytics>(assets, func (asset) {
      var weightedIn = 0.0;
      var weightedOut = 0.0;
      var weightedPrice = 0.0;
      var weightSum = 0.0;
      var firstBeat = beat;
      var lastBeat = beat;
      var positiveWindows : Nat = 0;
      var windows : Nat = 0;
      for (flow in flows.vals()) {
        if (flow.asset == asset) {
          let wAmt = flow.amount * flow.economicWeight;
          if (not isPoolNode(flow.sourceId)) { weightedOut += wAmt };
          if (not isPoolNode(flow.targetId)) { weightedIn += wAmt };
          weightedPrice += flow.price * wAmt;
          weightSum += wAmt;
          if (flow.beat < firstBeat) { firstBeat := flow.beat };
          if (flow.beat > lastBeat) { lastBeat := flow.beat };
          windows += 1;
          if (wAmt > 0.0) { positiveWindows += 1 };
        };
      };
      let span = Int.abs(lastBeat - firstBeat) + 1;
      let net = weightedIn - weightedOut;
      let anomaly = assetAnomalyScore(flows, asset);
      {
        asset = asset;
        inflowVelocity = weightedIn / span.toFloat();
        outflowVelocity = weightedOut / span.toFloat();
        netFlow = net;
        netDirection = if (net > 0.0) "inflow" else if (net < 0.0) "outflow" else "balanced";
        volumeWeightedFlowPrice = if (weightSum > 0.0) weightedPrice / weightSum else 0.0;
        persistence = if (windows == 0) 0.0 else positiveWindows.toInt().toFloat() / windows.toInt().toFloat();
        anomalyScore = anomaly;
        lastUpdateBeat = beat;
      }
    })
  };

  func buildAnomalies(
    existing : [FlowAnomaly],
    nextId : Nat,
    cycles : [CircularFlow],
    pools : [(Text, PoolState)],
    assets : [AssetFlowAnalytics],
    risk : SystemicRiskMetrics,
    beat : Int,
  ) : [FlowAnomaly] {
    var anomalies = existing;
    var cursor = nextId;

    for (cycle in cycles.vals()) {
      if (cycle.totalVolume > 0.0 and cycle.cycleLength >= 3) {
        anomalies := appendAnomaly(anomalies, {
          anomalyId = cursor;
          category = "circular-flow";
          subject = joinPath(cycle.path);
          description = "Detected circular capital path with repeat routing pressure.";
          score = Float.min(1.0, cycle.totalVolume / 1000.0);
          beat = beat;
        });
        cursor += 1;
      };
    };

    for (pool in pools.vals()) {
      if (pool.1.utilizationRate >= 0.85 or pool.1.liquidityConcentration >= 0.55 or pool.1.impermanentLoss <= -0.12) {
        anomalies := appendAnomaly(anomalies, {
          anomalyId = cursor;
          category = "pool-stress";
          subject = pool.1.poolId;
          description = "Pool utilization, concentration, or impermanent loss breached stress threshold.";
          score = Float.min(1.0, pool.1.utilizationRate + pool.1.liquidityConcentration + Float.abs(pool.1.impermanentLoss));
          beat = beat;
        });
        cursor += 1;
      };
    };

    for (asset in assets.vals()) {
      if (asset.anomalyScore >= 0.72) {
        anomalies := appendAnomaly(anomalies, {
          anomalyId = cursor;
          category = "flow-anomaly";
          subject = asset.asset;
          description = "Asset flow velocity deviated materially from rolling baseline.";
          score = asset.anomalyScore;
          beat = beat;
        });
        cursor += 1;
      };
    };

    if (risk.contagionRisk >= 0.72 or risk.systemLeverage >= Phi.PHI) {
      anomalies := appendAnomaly(anomalies, {
        anomalyId = cursor;
        category = "systemic-risk";
        subject = "PARALLAX";
        description = "System contagion or leverage exceeded acceptable real-time threshold.";
        score = Float.min(1.0, risk.contagionRisk + (risk.systemLeverage / (Phi.PHI * 4.0)));
        beat = beat;
      });
    };

    capTail(anomalies, MAX_ANOMALIES)
  };

  func buildVisualization(
    nodeMetrics : [NodeMetrics],
    flows : [FlowRecord],
    cycles : [CircularFlow],
  ) : VisualizationGraph {
    let chosenNodes = topNodeMetrics(nodeMetrics, MAX_VIS_NODES);
    let nodeIds = Array.map<NodeMetrics, Text>(chosenNodes, func (m) { m.nodeId });
    let nodes = Array.map<NodeMetrics, VisualizationNode>(chosenNodes, func (m) {
      {
        id = m.nodeId;
        displayLabel = m.nodeId;
        nodeType = if (isPoolNode(m.nodeId)) "pool" else if (isRouteNode(m.nodeId)) "route" else "account";
        size = 8.0 + (32.0 * m.systemicImportance);
        color = if (isPoolNode(m.nodeId)) "#7c3aed" else if (m.isHub) "#ea580c" else "#2563eb";
      }
    });

    var edges : [VisualizationEdge] = [];
    for (flow in flows.vals()) {
      if (edges.size() >= MAX_VIS_EDGES) { } else if (arrayContains(nodeIds, flow.sourceId) and arrayContains(nodeIds, flow.targetId)) {
        edges := Array.concat(edges, [{
          source = flow.sourceId;
          target = flow.targetId;
          asset = flow.asset;
          weight = flow.notional * flow.economicWeight;
          displayLabel = flow.asset # " " # Float.toText(flow.amount);
        }]);
      };
    };

    {
      nodes = nodes;
      edges = edges;
      hubs = topNodes(nodeMetrics, 10, func (m) { m.systemicImportance });
      cycles = Array.map<CircularFlow, [Text]>(cycles, func (c) { c.path });
    }
  };

  func detectCircularFlows(flows : [FlowRecord]) : [CircularFlow] {
    let nodes = collectNodeIds(flows);
    var cycles : [CircularFlow] = [];
    for (a in nodes.vals()) {
      let outward = outgoingTargets(flows, a);
      for (b in outward.vals()) {
        if (b != a) {
          let outwardB = outgoingTargets(flows, b);
          for (c in outwardB.vals()) {
            if (c != a and c != b and hasEdge(flows, c, a)) {
              let volume = Float.min(edgeVolume(flows, a, b), Float.min(edgeVolume(flows, b, c), edgeVolume(flows, c, a)));
              cycles := appendCycle(cycles, {
                path = [a, b, c, a];
                asset = dominantAsset(flows, [a, b, c, a]);
                cycleLength = 3;
                totalVolume = volume;
                firstBeat = minBeatForPath(flows, [a, b, c, a]);
                lastBeat = maxBeatForPath(flows, [a, b, c, a]);
              });
            };
          };
        };
      };
    };
    capTail(cycles, MAX_CYCLES)
  };

  func detectArbitrage(pools : [(Text, PoolState)], _flows : [FlowRecord], beat : Int) : [ArbitragePath] {
    let assets = poolAssets(pools);
    var paths : [ArbitragePath] = [];
    for (a in assets.vals()) {
      for (b in assets.vals()) {
        for (c in assets.vals()) {
          if (a != b and b != c and a != c) {
            switch (findPoolByTokens(pools, a, b)) {
              case (?ab) {
                switch (findPoolByTokens(pools, b, c)) {
                  case (?bc) {
                    switch (findPoolByTokens(pools, c, a)) {
                      case (?ca) {
                        let syntheticRate = poolRate(ab, a, b) * poolRate(bc, b, c) * poolRate(ca, c, a);
                        if (syntheticRate > 1.01) {
                          paths := appendArbitrage(paths, {
                            path = [a, b, c, a];
                            assets = [a, b, c];
                            poolIds = [ab.poolId, bc.poolId, ca.poolId];
                            syntheticRate = syntheticRate;
                            profitability = syntheticRate - 1.0;
                            beat = beat;
                          });
                        };
                      };
                      case null {};
                    };
                  };
                  case null {};
                };
              };
              case null {};
            };
          };
        };
      };
    };
    capTail(paths, MAX_ARBITRAGE)
  };

  func buildExposureMatrix(flows : [FlowRecord]) : [ExposureCell] {
    var exposures : [ExposureCell] = [];
    for (flow in flows.vals()) {
      let amount = flow.notional * Float.max(0.1, flow.price);
      exposures := upsertExposure(exposures, flow.sourceId, flow.targetId, flow.asset, amount);
    };
    exposures
  };

  func computePageRank(nodeIds : [Text], flows : [FlowRecord]) : [(Text, Float)] {
    if (nodeIds.size() == 0) { return [] };
    let initial = 1.0 / nodeIds.size().toInt().toFloat();
    var ranks = Array.map<Text, (Text, Float)>(nodeIds, func (nodeId) { (nodeId, initial) });
    var iteration : Nat = 0;
    while (iteration < 8) {
      ranks := Array.map<Text, (Text, Float)>(nodeIds, func (nodeId) {
        var incoming = 0.0;
        for (flow in flows.vals()) {
          if (flow.targetId == nodeId) {
            let outDegree = degree(flows, flow.sourceId, false);
            if (outDegree > 0) {
              incoming += lookupScore(ranks, flow.sourceId) / outDegree.toInt().toFloat();
            };
          };
        };
        (nodeId, ((1.0 - 0.85) / nodeIds.size().toInt().toFloat()) + (0.85 * incoming))
      });
      iteration += 1;
    };
    ranks
  };

  func approxBetweenness(nodeIds : [Text], flows : [FlowRecord]) : [(Text, Float)] {
    Array.map<Text, (Text, Float)>(nodeIds, func (nodeId) {
      var score = 0.0;
      let incoming = incomingSources(flows, nodeId);
      let outgoing = outgoingTargets(flows, nodeId);
      for (src in incoming.vals()) {
        for (dst in outgoing.vals()) {
          if (src != dst and not hasEdge(flows, src, dst)) {
            score += edgeVolume(flows, src, nodeId) + edgeVolume(flows, nodeId, dst);
          };
        };
      };
      (nodeId, score)
    })
  };

  func upsertPool(
    pools : [(Text, PoolState)],
    settlement : PhantomClearinghouse.SettlementRecord,
    price : Float,
    beat : Int,
  ) : [(Text, PoolState)] {
    let poolId = poolNodeId(settlement.pairId);
    let existing = switch (findPool(pools, poolId)) {
      case (?pool) { pool };
      case null {
        {
          poolId = poolId;
          pairId = settlement.pairId;
          baseToken = settlement.baseToken;
          quoteToken = settlement.quoteToken;
          baseBalance = settlement.baseAmount * Phi.PHI;
          quoteBalance = settlement.quoteAmount * Phi.PHI;
          grossBaseThroughput = 0.0;
          grossQuoteThroughput = 0.0;
          cumulativeVolume = 0.0;
          referencePrice = if (price > 0.0) price else 1.0;
          lastPrice = if (price > 0.0) price else 1.0;
          utilizationRate = 0.0;
          impermanentLoss = 0.0;
          liquidityConcentration = 1.0;
          activeLiquidityProviders = [];
          lastUpdateBeat = beat;
        }
      };
    };

    let providers = normalizeProviderShares(
      updateProvider(
        updateProvider(existing.activeLiquidityProviders, settlement.seller, settlement.baseAmount, beat),
        settlement.buyer,
        settlement.quoteAmount,
        beat,
      )
    );
    let baseBalance = (existing.baseBalance * 0.92) + settlement.baseAmount;
    let quoteBalance = (existing.quoteBalance * 0.92) + settlement.quoteAmount;
    let cumulativeVolume = existing.cumulativeVolume + settlement.quoteAmount;
    let utilDenom = Float.max(1.0, (baseBalance * Float.max(price, existing.lastPrice)) + quoteBalance);
    let utilization = Float.min(1.0, cumulativeVolume / utilDenom);
    let priceRatio = if (existing.referencePrice > 0.0 and price > 0.0) price / existing.referencePrice else 1.0;
    let il = impermanentLoss(priceRatio);
    let concentration = providerConcentration(providers);
    let nextPool : PoolState = {
      poolId = poolId;
      pairId = settlement.pairId;
      baseToken = settlement.baseToken;
      quoteToken = settlement.quoteToken;
      baseBalance = baseBalance;
      quoteBalance = quoteBalance;
      grossBaseThroughput = existing.grossBaseThroughput + settlement.baseAmount;
      grossQuoteThroughput = existing.grossQuoteThroughput + settlement.quoteAmount;
      cumulativeVolume = cumulativeVolume;
      referencePrice = existing.referencePrice;
      lastPrice = if (price > 0.0) price else existing.lastPrice;
      utilizationRate = utilization;
      impermanentLoss = il;
      liquidityConcentration = concentration;
      activeLiquidityProviders = providers;
      lastUpdateBeat = beat;
    };

    upsertPoolEntry(pools, poolId, nextPool)
  };

  func appendFlows(existing : [FlowRecord], incoming : [FlowRecord]) : [FlowRecord] {
    capTail(Array.concat(existing, incoming), MAX_FLOWS)
  };

  func appendSnapshot(existing : [HistoricalSnapshot], snapshot : HistoricalSnapshot) : [HistoricalSnapshot] {
    capTail(Array.concat(existing, [snapshot]), MAX_SNAPSHOTS)
  };

  func appendAnomaly(existing : [FlowAnomaly], anomaly : FlowAnomaly) : [FlowAnomaly] {
    Array.concat(existing, [anomaly])
  };

  func appendCycle(existing : [CircularFlow], cycle : CircularFlow) : [CircularFlow] {
    if (hasCycle(existing, cycle.path)) { existing } else Array.concat(existing, [cycle])
  };

  func appendArbitrage(existing : [ArbitragePath], arb : ArbitragePath) : [ArbitragePath] {
    if (hasArbitrage(existing, arb.path)) { existing } else Array.concat(existing, [arb])
  };

  func capTail<T>(items : [T], max : Nat) : [T] {
    if (items.size() <= max) {
      items
    } else {
      Array.tabulate<T>(max, func (i : Nat) : T { items[items.size() - max + i] })
    }
  };

  func takeHead<T>(items : [T], max : Nat) : [T] {
    if (items.size() <= max) {
      items
    } else {
      Array.tabulate<T>(max, func (i : Nat) : T { items[i] })
    }
  };

  func poolNodeId(pairId : Text) : Text {
    "POOL:" # pairId
  };

  func emptyGraphAnalytics() : TransactionGraphAnalytics {
    {
      totalNodes = 0;
      totalEdges = 0;
      averageDegree = 0.0;
      density = 0.0;
      nodeMetrics = [];
      circularFlows = [];
      arbitragePaths = [];
      topHubs = [];
      topLiquidityProviders = [];
    }
  };

  func emptyRiskMetrics() : SystemicRiskMetrics {
    {
      contagionRisk = 0.0;
      systemLeverage = 0.0;
      counterpartyConcentration = 0.0;
      exposureMatrix = [];
      systemicImportanceScores = [];
      stressLossEstimate = 0.0;
      riskTier = #low;
    }
  };

  func emptyVisualization() : VisualizationGraph {
    {
      nodes = [];
      edges = [];
      hubs = [];
      cycles = [];
    }
  };

  func makeSnapshot(totalVolume : Float, activeNodes : Nat, pools : [(Text, PoolState)], risk : SystemicRiskMetrics, anomalyCount : Nat, beat : Int) : HistoricalSnapshot {
    {
      beat = beat;
      totalVolume = totalVolume;
      activeNodes = activeNodes;
      poolUtilization = averagePoolUtilization(pools);
      contagionRisk = risk.contagionRisk;
      leverage = risk.systemLeverage;
      anomalyCount = anomalyCount;
    }
  };

  func sumFlows(flows : [FlowRecord], nodeId : Text, inbound : Bool) : Float {
    Array.foldLeft<FlowRecord, Float>(flows, 0.0, func (acc, flow) {
      if ((inbound and flow.targetId == nodeId) or ((not inbound) and flow.sourceId == nodeId)) {
        acc + flow.notional
      } else {
        acc
      }
    })
  };

  func degree(flows : [FlowRecord], nodeId : Text, inbound : Bool) : Nat {
    let peers = if (inbound) incomingSources(flows, nodeId) else outgoingTargets(flows, nodeId);
    peers.size()
  };

  func incomingSources(flows : [FlowRecord], nodeId : Text) : [Text] {
    var items : [Text] = [];
    for (flow in flows.vals()) {
      if (flow.targetId == nodeId and not arrayContains(items, flow.sourceId)) {
        items := Array.concat(items, [flow.sourceId]);
      };
    };
    items
  };

  func outgoingTargets(flows : [FlowRecord], nodeId : Text) : [Text] {
    var items : [Text] = [];
    for (flow in flows.vals()) {
      if (flow.sourceId == nodeId and not arrayContains(items, flow.targetId)) {
        items := Array.concat(items, [flow.targetId]);
      };
    };
    items
  };

  func collectNodeIds(flows : [FlowRecord]) : [Text] {
    var nodes : [Text] = [];
    for (flow in flows.vals()) {
      if (not arrayContains(nodes, flow.sourceId)) { nodes := Array.concat(nodes, [flow.sourceId]) };
      if (not arrayContains(nodes, flow.targetId)) { nodes := Array.concat(nodes, [flow.targetId]) };
    };
    nodes
  };

  func uniqueAssets(flows : [FlowRecord]) : [Text] {
    var assets : [Text] = [];
    for (flow in flows.vals()) {
      if (not arrayContains(assets, flow.asset)) { assets := Array.concat(assets, [flow.asset]) };
    };
    assets
  };

  func poolAssets(pools : [(Text, PoolState)]) : [Text] {
    var assets : [Text] = [];
    for (entry in pools.vals()) {
      if (not arrayContains(assets, entry.1.baseToken)) { assets := Array.concat(assets, [entry.1.baseToken]) };
      if (not arrayContains(assets, entry.1.quoteToken)) { assets := Array.concat(assets, [entry.1.quoteToken]) };
    };
    assets
  };

  func poolProviderScores(pools : [(Text, PoolState)]) : [(Text, Float)] {
    var scores : [(Text, Float)] = [];
    for (entry in pools.vals()) {
      for (provider in entry.1.activeLiquidityProviders.vals()) {
        scores := upsertScore(scores, provider.providerId, provider.share * Float.max(1.0, entry.1.cumulativeVolume));
      };
    };
    scores
  };

  func totalPoolDepth(pools : [(Text, PoolState)]) : Float {
    Array.foldLeft<(Text, PoolState), Float>(pools, 0.0, func (acc, entry) {
      acc + entry.1.quoteBalance + (entry.1.baseBalance * Float.max(1.0, entry.1.lastPrice))
    })
  };

  func averagePoolUtilization(pools : [(Text, PoolState)]) : Float {
    if (pools.size() == 0) { return 0.0 };
    Array.foldLeft<(Text, PoolState), Float>(pools, 0.0, func (acc, entry) { acc + entry.1.utilizationRate }) / pools.size().toInt().toFloat()
  };

  func providerConcentration(providers : [LiquidityProvider]) : Float {
    Array.foldLeft<LiquidityProvider, Float>(providers, 0.0, func (acc, provider) { acc + (provider.share * provider.share) })
  };

  func normalizeProviderShares(providers : [LiquidityProvider]) : [LiquidityProvider] {
    let total = Array.foldLeft<LiquidityProvider, Float>(providers, 0.0, func (acc, provider) { acc + provider.cumulativeProvided });
    if (total <= 0.0) { return providers };
    Array.map<LiquidityProvider, LiquidityProvider>(providers, func (provider) {
      { provider with share = provider.cumulativeProvided / total }
    })
  };

  func updateProvider(providers : [LiquidityProvider], providerId : Text, amount : Float, beat : Int) : [LiquidityProvider] {
    let found = Array.find<LiquidityProvider>(providers, func (provider) { provider.providerId == providerId });
    switch (found) {
      case (?_) {
        Array.map<LiquidityProvider, LiquidityProvider>(providers, func (provider) {
          if (provider.providerId == providerId) {
            {
              providerId = providerId;
              cumulativeProvided = provider.cumulativeProvided + amount;
              share = provider.share;
              lastActiveBeat = beat;
            }
          } else {
            provider
          }
        })
      };
      case null {
        Array.concat(providers, [{
          providerId = providerId;
          cumulativeProvided = amount;
          share = 0.0;
          lastActiveBeat = beat;
        }])
      };
    }
  };

  func upsertPoolEntry(pools : [(Text, PoolState)], poolId : Text, pool : PoolState) : [(Text, PoolState)] {
    let found = Array.find<(Text, PoolState)>(pools, func (entry) { entry.0 == poolId });
    switch (found) {
      case (?_) {
        Array.map<(Text, PoolState), (Text, PoolState)>(pools, func (entry) {
          if (entry.0 == poolId) (poolId, pool) else entry
        })
      };
      case null {
        capTail(Array.concat(pools, [(poolId, pool)]), MAX_POOLS)
      };
    }
  };

  func findPool(pools : [(Text, PoolState)], poolId : Text) : ?PoolState {
    switch (Array.find<(Text, PoolState)>(pools, func (entry) { entry.0 == poolId })) {
      case (?entry) { ?entry.1 };
      case null { null };
    }
  };

  func findPoolByTokens(pools : [(Text, PoolState)], tokenA : Text, tokenB : Text) : ?PoolState {
    Array.find<PoolState>(Array.map<(Text, PoolState), PoolState>(pools, func (entry) { entry.1 }), func (pool) {
      (pool.baseToken == tokenA and pool.quoteToken == tokenB) or (pool.baseToken == tokenB and pool.quoteToken == tokenA)
    })
  };

  func findPair(pairs : [(Text, PhantomExchange.TradingPair)], pairId : Text) : ?PhantomExchange.TradingPair {
    switch (Array.find<(Text, PhantomExchange.TradingPair)>(pairs, func (entry) { entry.0 == pairId })) {
      case (?entry) { ?entry.1 };
      case null { null };
    }
  };

  func findSettlementByFillId(settlements : [PhantomClearinghouse.SettlementRecord], fillId : Nat) : ?PhantomClearinghouse.SettlementRecord {
    Array.find<PhantomClearinghouse.SettlementRecord>(settlements, func (settlement) { settlement.fillId == fillId })
  };

  func poolRate(pool : PoolState, assetFrom : Text, assetTo : Text) : Float {
    if (pool.baseToken == assetFrom and pool.quoteToken == assetTo) {
      Float.max(0.000001, pool.lastPrice)
    } else if (pool.quoteToken == assetFrom and pool.baseToken == assetTo and pool.lastPrice > 0.0) {
      1.0 / pool.lastPrice
    } else {
      0.0
    }
  };

  func impermanentLoss(priceRatio : Float) : Float {
    if (priceRatio <= 0.0) { return 0.0 };
    let numerator = 2.0 * Float.sqrt(priceRatio);
    let denominator = 1.0 + priceRatio;
    (numerator / denominator) - 1.0
  };

  func exposureConcentration(exposures : [ExposureCell]) : Float {
    let total = Array.foldLeft<ExposureCell, Float>(exposures, 0.0, func (acc, exposure) { acc + exposure.exposure });
    if (total <= 0.0) { return 0.0 };
    Array.foldLeft<ExposureCell, Float>(exposures, 0.0, func (acc, exposure) {
      let share = exposure.exposure / total;
      acc + (share * share)
    })
  };

  func classifyRisk(contagion : Float, leverage : Float, concentration : Float) : RiskTier {
    if (contagion >= 0.85 or leverage >= (Phi.PHI * 2.0) or concentration >= 0.75) {
      #critical
    } else if (contagion >= 0.65 or leverage >= Phi.PHI or concentration >= 0.55) {
      #high
    } else if (contagion >= 0.45 or leverage >= Phi.PHI_INV or concentration >= 0.35) {
      #elevated
    } else {
      #low
    }
  };

  func assetAnomalyScore(flows : [FlowRecord], asset : Text) : Float {
    var total = 0.0;
    var count : Nat = 0;
    var latest = 0.0;
    var latestBeat = -1;
    for (flow in flows.vals()) {
      if (flow.asset == asset) {
        let amount = flow.amount * flow.economicWeight;
        total += amount;
        count += 1;
        if (flow.beat >= latestBeat) {
          latestBeat := flow.beat;
          latest := amount;
        };
      };
    };
    if (count == 0) { return 0.0 };
    let avg = total / count.toInt().toFloat();
    Float.min(1.0, latest / Float.max(avg * Phi.PHI, 0.000001))
  };

  func topNodes(metrics : [NodeMetrics], limit : Nat, scoreOf : (NodeMetrics) -> Float) : [Text] {
    Array.map<NodeMetrics, Text>(topNodeMetricsBy(metrics, limit, scoreOf), func (metric) { metric.nodeId })
  };

  func topNodeMetrics(metrics : [NodeMetrics], limit : Nat) : [NodeMetrics] {
    topNodeMetricsBy(metrics, limit, func (metric) { metric.systemicImportance })
  };

  func topNodeMetricsBy(metrics : [NodeMetrics], limit : Nat, scoreOf : (NodeMetrics) -> Float) : [NodeMetrics] {
    var selected : [NodeMetrics] = [];
    for (metric in metrics.vals()) {
      selected := insertMetric(selected, metric, limit, scoreOf);
    };
    selected
  };

  func insertMetric(metrics : [NodeMetrics], metric : NodeMetrics, limit : Nat, scoreOf : (NodeMetrics) -> Float) : [NodeMetrics] {
    var inserted = false;
    var result : [NodeMetrics] = [];
    for (existing in metrics.vals()) {
      if (not inserted and scoreOf(metric) > scoreOf(existing)) {
        result := Array.concat(result, [metric]);
        inserted := true;
      };
      result := Array.concat(result, [existing]);
    };
    if (not inserted) { result := Array.concat(result, [metric]) };
    takeHead(result, limit)
  };

  func topProviders(pools : [(Text, PoolState)], limit : Nat) : [Text] {
    var ranked : [(Text, Float)] = [];
    for (entry in pools.vals()) {
      for (provider in entry.1.activeLiquidityProviders.vals()) {
        ranked := upsertScore(ranked, provider.providerId, provider.cumulativeProvided);
      };
    };
    var names : [Text] = [];
    var selected : [(Text, Float)] = [];
    for (entry in ranked.vals()) {
      selected := insertScore(selected, entry, limit);
    };
    for (entry in selected.vals()) { names := Array.concat(names, [entry.0]) };
    names
  };

  func insertScore(scores : [(Text, Float)], score : (Text, Float), limit : Nat) : [(Text, Float)] {
    var inserted = false;
    var result : [(Text, Float)] = [];
    for (existing in scores.vals()) {
      if (not inserted and score.1 > existing.1) {
        result := Array.concat(result, [score]);
        inserted := true;
      };
      result := Array.concat(result, [existing]);
    };
    if (not inserted) { result := Array.concat(result, [score]) };
    takeHead(result, limit)
  };

  func upsertScore(scores : [(Text, Float)], key : Text, delta : Float) : [(Text, Float)] {
    let found = Array.find<(Text, Float)>(scores, func (entry) { entry.0 == key });
    switch (found) {
      case (?_) {
        Array.map<(Text, Float), (Text, Float)>(scores, func (entry) {
          if (entry.0 == key) (key, entry.1 + delta) else entry
        })
      };
      case null {
        Array.concat(scores, [(key, delta)])
      };
    }
  };

  func upsertExposure(exposures : [ExposureCell], sourceId : Text, targetId : Text, asset : Text, delta : Float) : [ExposureCell] {
    let found = Array.find<ExposureCell>(exposures, func (cell) { cell.sourceId == sourceId and cell.targetId == targetId and cell.asset == asset });
    switch (found) {
      case (?_) {
        Array.map<ExposureCell, ExposureCell>(exposures, func (cell) {
          if (cell.sourceId == sourceId and cell.targetId == targetId and cell.asset == asset) {
            {
              sourceId = sourceId;
              targetId = targetId;
              asset = asset;
              exposure = cell.exposure + delta;
              riskWeight = Float.min(1.0, (cell.exposure + delta) / 10000.0);
            }
          } else {
            cell
          }
        })
      };
      case null {
        Array.concat(exposures, [{
          sourceId = sourceId;
          targetId = targetId;
          asset = asset;
          exposure = delta;
          riskWeight = Float.min(1.0, delta / 10000.0);
        }])
      };
    }
  };

  func totalFlowMagnitude(flows : [FlowRecord]) : Float {
    Array.foldLeft<FlowRecord, Float>(flows, 0.0, func (acc, flow) { acc + flow.notional })
  };

  func lookupScore(scores : [(Text, Float)], key : Text) : Float {
    switch (Array.find<(Text, Float)>(scores, func (entry) { entry.0 == key })) {
      case (?entry) { entry.1 };
      case null { 0.0 };
    }
  };

  func maxScore(scores : [(Text, Float)]) : Float {
    Array.foldLeft<(Text, Float), Float>(scores, 0.0, func (acc, score) { if (score.1 > acc) score.1 else acc })
  };

  func normalize(value : Float, maxValue : Float) : Float {
    if (maxValue <= 0.0) 0.0 else Float.min(1.0, value / maxValue)
  };

  func hasEdge(flows : [FlowRecord], sourceId : Text, targetId : Text) : Bool {
    switch (Array.find<FlowRecord>(flows, func (flow) { flow.sourceId == sourceId and flow.targetId == targetId })) {
      case (?_) { true };
      case null { false };
    }
  };

  func edgeVolume(flows : [FlowRecord], sourceId : Text, targetId : Text) : Float {
    Array.foldLeft<FlowRecord, Float>(flows, 0.0, func (acc, flow) {
      if (flow.sourceId == sourceId and flow.targetId == targetId) acc + (flow.notional * flow.economicWeight) else acc
    })
  };

  func dominantAsset(flows : [FlowRecord], path : [Text]) : Text {
    var bestAsset = "";
    var bestVolume = 0.0;
    let assets = uniqueAssets(flows);
    for (asset in assets.vals()) {
      var volume = 0.0;
      var i : Nat = 0;
      while (i + 1 < path.size()) {
        volume += edgeVolumeByAsset(flows, path[i], path[i + 1], asset);
        i += 1;
      };
      if (volume > bestVolume) {
        bestVolume := volume;
        bestAsset := asset;
      };
    };
    bestAsset
  };

  func edgeVolumeByAsset(flows : [FlowRecord], sourceId : Text, targetId : Text, asset : Text) : Float {
    Array.foldLeft<FlowRecord, Float>(flows, 0.0, func (acc, flow) {
      if (flow.sourceId == sourceId and flow.targetId == targetId and flow.asset == asset) acc + (flow.notional * flow.economicWeight) else acc
    })
  };

  func minBeatForPath(flows : [FlowRecord], path : [Text]) : Int {
    var result = 0;
    var started = false;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      for (flow in flows.vals()) {
        if (flow.sourceId == path[i] and flow.targetId == path[i + 1]) {
          if (not started or flow.beat < result) {
            result := flow.beat;
            started := true;
          };
        };
      };
      i += 1;
    };
    result
  };

  func maxBeatForPath(flows : [FlowRecord], path : [Text]) : Int {
    var result = 0;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      for (flow in flows.vals()) {
        if (flow.sourceId == path[i] and flow.targetId == path[i + 1] and flow.beat > result) {
          result := flow.beat;
        };
      };
      i += 1;
    };
    result
  };

  func hasCycle(cycles : [CircularFlow], path : [Text]) : Bool {
    switch (Array.find<CircularFlow>(cycles, func (cycle) { joinPath(cycle.path) == joinPath(path) })) {
      case (?_) { true };
      case null { false };
    }
  };

  func hasArbitrage(items : [ArbitragePath], path : [Text]) : Bool {
    switch (Array.find<ArbitragePath>(items, func (item) { joinPath(item.path) == joinPath(path) })) {
      case (?_) { true };
      case null { false };
    }
  };

  func joinPath(path : [Text]) : Text {
    var out = "";
    var first = true;
    for (node in path.vals()) {
      if (first) {
        out := node;
        first := false;
      } else {
        out := out # "→" # node;
      };
    };
    out
  };

  func isPoolNode(nodeId : Text) : Bool {
    Text.contains(nodeId, #text "POOL:")
  };

  func isRouteNode(nodeId : Text) : Bool {
    Text.contains(nodeId, #text "XCHAIN:")
  };

  func arrayContains(items : [Text], value : Text) : Bool {
    switch (Array.find<Text>(items, func (item) { item == value })) {
      case (?_) { true };
      case null { false };
    }
  };

};
