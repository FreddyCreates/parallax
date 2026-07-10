import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Phi "phi";

module {

  public type Matrix = [[Float]];
  public type Vector = [Float];

  public type GraphNode = {
    id : Text;
    heuristic : Float;
  };

  public type GraphEdge = {
    edgeId    : Text;
    from      : Text;
    to        : Text;
    weight    : Float;
    capacity  : Float;
    cost      : Float;
    liquidity : Float;
    rate      : Float;
  };

  public type Graph = {
    nodes : [GraphNode];
    edges : [GraphEdge];
  };

  public type LiquidityPool = {
    poolId : Text;
    pairId : Text;
    baseToken : Text;
    quoteToken : Text;
    baseBalance : Float;
    quoteBalance : Float;
    referencePrice : Float;
    lastPrice : Float;
    utilizationRate : Float;
    impermanentLoss : Float;
  };

  public type LiquidityNetwork = {
    pools : [LiquidityPool];
  };

  public type PathResult = {
    algorithm : Text;
    distance  : Float;
    path      : [Text];
    edgeIds   : [Text];
    visited   : [Text];
  };

  public type FlowAssignment = {
    edgeId   : Text;
    from     : Text;
    to       : Text;
    amount   : Float;
    unitCost : Float;
  };

  public type MaxFlowResult = {
    algorithm       : Text;
    maxFlow         : Float;
    assignments     : [FlowAssignment];
    augmentingPaths : [[Text]];
  };

  public type MinCostFlowResult = {
    totalFlow    : Float;
    totalCost    : Float;
    assignments  : [FlowAssignment];
    satisfiedAll : Bool;
  };

  public type CentralityMetrics = {
    degree      : [(Text, Float)];
    betweenness : [(Text, Float)];
    closeness   : [(Text, Float)];
    pageRank    : [(Text, Float)];
  };

  public type Community = {
    communityId : Nat;
    members     : [Text];
    modularityContribution : Float;
  };

  public type CommunityResult = {
    algorithm   : Text;
    communities : [Community];
    modularity  : Float;
    assignments : [(Text, Nat)];
  };

  public type ColorAssignment = {
    nodeId : Text;
    color  : Nat;
  };

  public type GraphColoring = {
    algorithm          : Text;
    chromaticUpperBound: Nat;
    assignments        : [ColorAssignment];
  };

  public type MstResult = {
    algorithm   : Text;
    totalWeight : Float;
    edges       : [GraphEdge];
  };

  public type TradeRoute = {
    algorithm     : Text;
    pools         : [Text];
    path          : [Text];
    amountIn      : Float;
    expectedOut   : Float;
    totalCost     : Float;
    effectiveRate : Float;
  };

  public type ArbitrageCycle = {
    algorithm : Text;
    cycle     : [Text];
    pools     : [Text];
    gainFactor: Float;
    netGain   : Float;
  };

  public type LiquidityOptimization = {
    recommendedFlows : [FlowAssignment];
    maxThroughput    : Float;
    totalCost        : Float;
    bottleneckEdges  : [Text];
  };

  public type TokenDistributionPlan = {
    sourceToken      : Text;
    sourceNode       : Text;
    sinkNodes        : [Text];
    plan             : [FlowAssignment];
    totalDistributed : Float;
    totalCost        : Float;
  };

  public type KalmanState = {
    x : Vector;
    P : Matrix;
    A : Matrix;
    B : Matrix;
    H : Matrix;
    Q : Matrix;
    R : Matrix;
  };

  public type EkfState = {
    x : Vector;
    P : Matrix;
    Q : Matrix;
    R : Matrix;
  };

  public type LqrSolution = {
    gain      : Matrix;
    riccati   : Matrix;
    iterations: Nat;
  };

  public type MpcPlan = {
    controls      : [Vector];
    states        : [Vector];
    totalObjective: Float;
    appliedControl: Vector;
  };

  public type PidState = {
    kp : Float;
    ki : Float;
    kd : Float;
    integral : Float;
    prevError: Float;
    outputMin: Float;
    outputMax: Float;
  };

  public type AdaptiveControlState = {
    gain          : Matrix;
    adaptationRate: Float;
    referenceModel: Matrix;
    controlVector : Vector;
  };

  public type PriceStabilityResult = {
    estimatedPrice: Float;
    controlSignal : Float;
    volatility    : Float;
  };

  public type PoolRebalanceResult = {
    rebalanceVector  : Vector;
    expectedInventory: Vector;
    controlSignal    : Float;
  };

  public type AmmControlResult = {
    quoteAdjustment : Vector;
    valueFunction   : Float;
  };

  public type RiskExposureResult = {
    riskState  : Vector;
    hedgeSignal: Vector;
    gainNorm   : Float;
  };

  public type StateEstimationResult = {
    state      : Vector;
    covariance : Matrix;
    innovation : Vector;
  };

  public type GraphControlState = {
    tradeRoutes          : [TradeRoute];
    arbitrageSignals     : [ArbitrageCycle];
    liquidityOptimization: LiquidityOptimization;
    tokenDistribution    : ?TokenDistributionPlan;
    centrality           : CentralityMetrics;
    community            : CommunityResult;
    coloring             : GraphColoring;
    spanningTree         : MstResult;
    priceKalman          : KalmanState;
    systemEkf            : EkfState;
    pid                  : PidState;
    adaptive             : AdaptiveControlState;
    estimatedState       : Vector;
    latestControlSignal  : Vector;
    lastControlBeat      : Int;
  };

  public func defaultGraphControlState() : GraphControlState {
    let centrality = {
      degree = [];
      betweenness = [];
      closeness = [];
      pageRank = [];
    };
    {
      tradeRoutes = [];
      arbitrageSignals = [];
      liquidityOptimization = {
        recommendedFlows = [];
        maxThroughput = 0.0;
        totalCost = 0.0;
        bottleneckEdges = [];
      };
      tokenDistribution = null;
      centrality = centrality;
      community = {
        algorithm = "louvain";
        communities = [];
        modularity = 0.0;
        assignments = [];
      };
      coloring = {
        algorithm = "greedy";
        chromaticUpperBound = 0;
        assignments = [];
      };
      spanningTree = {
        algorithm = "kruskal";
        totalWeight = 0.0;
        edges = [];
      };
      priceKalman = defaultKalmanState();
      systemEkf = defaultEkfState();
      pid = defaultPidState();
      adaptive = defaultAdaptiveControlState();
      estimatedState = [1.0, 0.0];
      latestControlSignal = [0.0];
      lastControlBeat = 0;
    }
  };

  public func graphFromLiquidityNetwork(network : LiquidityNetwork) : Graph {
    let pools = network.pools;
    let nodes = collectNodesFromPools(pools);
    let edges = Array.foldLeft<LiquidityPool, [GraphEdge]>(pools, [], func (acc, pool) {
      let forwardRate = Float.max(0.0000001, pool.lastPrice);
      let reverseRate = Float.max(0.0000001, 1.0 / forwardRate);
      let feeCost = Float.max(0.0, pool.utilizationRate * 0.01 + Float.abs(pool.impermanentLoss) * 0.05);
      let baseLiquidity = Float.max(pool.baseBalance, 0.0000001);
      let quoteLiquidity = Float.max(pool.quoteBalance, 0.0000001);
      let forward : GraphEdge = {
        edgeId = pool.poolId # ":" # pool.baseToken # "->" # pool.quoteToken;
        from = pool.baseToken;
        to = pool.quoteToken;
        weight = -Float.log(forwardRate);
        capacity = baseLiquidity;
        cost = feeCost + reciprocalCost(forwardRate);
        liquidity = baseLiquidity + quoteLiquidity;
        rate = forwardRate;
      };
      let reverse : GraphEdge = {
        edgeId = pool.poolId # ":" # pool.quoteToken # "->" # pool.baseToken;
        from = pool.quoteToken;
        to = pool.baseToken;
        weight = -Float.log(reverseRate);
        capacity = quoteLiquidity;
        cost = feeCost + reciprocalCost(reverseRate);
        liquidity = baseLiquidity + quoteLiquidity;
        rate = reverseRate;
      };
      Array.concat(acc, [forward, reverse])
    });
    { nodes = nodes; edges = edges }
  };

  public func dijkstra(graph : Graph, source : Text, target : Text) : PathResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) {
      return emptyPath("dijkstra")
    };
    let sourceIndex = getNodeIndex(nodes, source);
    let targetIndex = getNodeIndex(nodes, target);
    if (sourceIndex < 0 or targetIndex < 0) {
      return emptyPath("dijkstra")
    };

    let inf = 1e18;
    var dist = Array.tabulate<Float>(n, func (_) { inf });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    var used = Array.tabulate<Bool>(n, func (_) { false });
    dist := setVectorCell(dist, Nat32ToNat(sourceIndex), 0.0);

    var step : Nat = 0;
    while (step < n) {
      let u = selectMinDistance(dist, used);
      if (u < 0) { step := n } else {
        used := setBoolCell(used, Nat32ToNat(u), true);
        let uNat = Nat32ToNat(u);
        let outgoing = outgoingEdges(graph.edges, nodes[uNat].id);
        for (edge in outgoing.vals()) {
          let v = getNodeIndex(nodes, edge.to);
          if (v >= 0) {
            let alt = dist[uNat] + edge.weight;
            let vNat = Nat32ToNat(v);
            if (alt < dist[vNat]) {
              dist := setVectorCell(dist, vNat, alt);
              prev := setIntCell(prev, vNat, u);
            }
          }
        };
        step += 1;
      }
    };

    let targetNat = Nat32ToNat(targetIndex);
    {
      algorithm = "dijkstra";
      distance = if (dist[targetNat] >= inf / 2.0) 0.0 else dist[targetNat];
      path = reconstructPath(nodes, prev, sourceIndex, targetIndex);
      edgeIds = reconstructEdgeIds(graph.edges, reconstructPath(nodes, prev, sourceIndex, targetIndex));
      visited = collectVisited(nodes, used);
    }
  };

  public func bellmanFord(graph : Graph, source : Text, target : Text) : PathResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) { return emptyPath("bellman-ford") };
    let sourceIndex = getNodeIndex(nodes, source);
    let targetIndex = getNodeIndex(nodes, target);
    if (sourceIndex < 0 or targetIndex < 0) { return emptyPath("bellman-ford") };

    let inf = 1e18;
    var dist = Array.tabulate<Float>(n, func (_) { inf });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    dist := setVectorCell(dist, Nat32ToNat(sourceIndex), 0.0);

    var iter : Nat = 0;
    while (iter + 1 < n) {
      var changed = false;
      for (edge in graph.edges.vals()) {
        let u = getNodeIndex(nodes, edge.from);
        let v = getNodeIndex(nodes, edge.to);
        if (u >= 0 and v >= 0) {
          let uNat = Nat32ToNat(u);
          let vNat = Nat32ToNat(v);
          if (dist[uNat] < inf / 2.0 and dist[uNat] + edge.weight < dist[vNat]) {
            dist := setVectorCell(dist, vNat, dist[uNat] + edge.weight);
            prev := setIntCell(prev, vNat, u);
            changed := true;
          }
        }
      };
      if (not changed) { iter := n } else { iter += 1 };
    };

    {
      algorithm = "bellman-ford";
      distance = if (dist[Nat32ToNat(targetIndex)] >= inf / 2.0) 0.0 else dist[Nat32ToNat(targetIndex)];
      path = reconstructPath(nodes, prev, sourceIndex, targetIndex);
      edgeIds = reconstructEdgeIds(graph.edges, reconstructPath(nodes, prev, sourceIndex, targetIndex));
      visited = nodesToText(nodes);
    }
  };

  public func aStar(graph : Graph, source : Text, target : Text) : PathResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) { return emptyPath("a*") };
    let sourceIndex = getNodeIndex(nodes, source);
    let targetIndex = getNodeIndex(nodes, target);
    if (sourceIndex < 0 or targetIndex < 0) { return emptyPath("a*") };

    let inf = 1e18;
    var gScore = Array.tabulate<Float>(n, func (_) { inf });
    var fScore = Array.tabulate<Float>(n, func (_) { inf });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    var closed = Array.tabulate<Bool>(n, func (_) { false });

    gScore := setVectorCell(gScore, Nat32ToNat(sourceIndex), 0.0);
    fScore := setVectorCell(fScore, Nat32ToNat(sourceIndex), heuristicFor(nodes[Nat32ToNat(sourceIndex)]));

    var count : Nat = 0;
    while (count < n) {
      let current = selectMinDistance(fScore, closed);
      if (current < 0) { count := n } else if (current == targetIndex) { count := n } else {
        let currentNat = Nat32ToNat(current);
        closed := setBoolCell(closed, currentNat, true);
        for (edge in outgoingEdges(graph.edges, nodes[currentNat].id).vals()) {
          let neighbor = getNodeIndex(nodes, edge.to);
          if (neighbor >= 0) {
            let neighborNat = Nat32ToNat(neighbor);
            if (not closed[neighborNat]) {
              let tentative = gScore[currentNat] + edge.weight;
              if (tentative < gScore[neighborNat]) {
                prev := setIntCell(prev, neighborNat, current);
                gScore := setVectorCell(gScore, neighborNat, tentative);
                fScore := setVectorCell(fScore, neighborNat, tentative + heuristicFor(nodes[neighborNat]));
              }
            }
          }
        };
        count += 1;
      }
    };

    let path = reconstructPath(nodes, prev, sourceIndex, targetIndex);
    {
      algorithm = "a*";
      distance = gScore[Nat32ToNat(targetIndex)];
      path = path;
      edgeIds = reconstructEdgeIds(graph.edges, path);
      visited = collectVisited(nodes, closed);
    }
  };

  public func fordFulkerson(graph : Graph, source : Text, sink : Text) : MaxFlowResult {
    maxFlowByResidual(graph, source, sink, true)
  };

  public func edmondsKarp(graph : Graph, source : Text, sink : Text) : MaxFlowResult {
    maxFlowByResidual(graph, source, sink, false)
  };

  public func minCostFlow(graph : Graph, source : Text, sink : Text, demand : Float) : MinCostFlowResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) {
      return { totalFlow = 0.0; totalCost = 0.0; assignments = []; satisfiedAll = false }
    };
    let sourceIndex = getNodeIndex(nodes, source);
    let sinkIndex = getNodeIndex(nodes, sink);
    if (sourceIndex < 0 or sinkIndex < 0) {
      return { totalFlow = 0.0; totalCost = 0.0; assignments = []; satisfiedAll = false }
    };

    let capacities = buildCapacityMatrix(nodes, graph.edges);
    let costs = buildCostMatrix(nodes, graph.edges);
    var residual = capacities;
    var flow = zeroMatrix(n, n);
    var delivered = 0.0;
    let targetDemand = Float.max(0.0, demand);

    var continueFlow = true;
    while (continueFlow and delivered + 0.0000001 < targetDemand) {
      let shortest = residualBellmanFord(nodes, residual, costs, sourceIndex, sinkIndex);
      let pathNodes = shortest.path;
      if (shortest.distance >= 1e17 or pathNodes.size() < 2) {
        continueFlow := false;
      } else {
        let residualPath = pathResidualCapacityByIndex(residual, pathNodes);
        let delta = Float.min(targetDemand - delivered, residualPath);
        residual := applyResidualAlongPath(residual, pathNodes, delta, true);
        flow := applyFlowAlongPath(flow, pathNodes, delta);
        delivered += delta;
      }
    };

    let assignments = matrixFlowAssignments(nodes, graph.edges, flow);
    let totalCost = Array.foldLeft<FlowAssignment, Float>(assignments, 0.0, func (acc, item) {
      acc + item.amount * item.unitCost
    });
    {
      totalFlow = delivered;
      totalCost = totalCost;
      assignments = assignments;
      satisfiedAll = delivered + 0.0000001 >= targetDemand;
    }
  };

  public func networkCentrality(graph : Graph) : CentralityMetrics {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) {
      return { degree = []; betweenness = []; closeness = []; pageRank = [] }
    };

    let degree = Array.map<GraphNode, (Text, Float)>(nodes, func (node) {
      let outDeg = outgoingEdges(graph.edges, node.id).size();
      let inDeg = incomingEdges(graph.edges, node.id).size();
      let denom = Float.max(1.0, (n - 1).toInt().toFloat());
      (node.id, (outDeg + inDeg).toInt().toFloat() / denom)
    });

    let closeness = Array.map<GraphNode, (Text, Float)>(nodes, func (node) {
      let distances = shortestDistances(graph, node.id);
      let total = Array.foldLeft<Float, Float>(distances, 0.0, func (acc, d) {
        if (d >= 1e17 or d == 0.0) acc else acc + d
      });
      let score = if (total > 0.0) (n - 1).toInt().toFloat() / total else 0.0;
      (node.id, score)
    });

    var betweenness = Array.tabulate<Float>(n, func (_) { 0.0 });
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j < n) {
        if (i != j) {
          let path = dijkstra(graph, nodes[i].id, nodes[j].id).path;
          if (path.size() > 2) {
            var k : Nat = 1;
            while (k + 1 < path.size()) {
              let idx = getNodeIndex(nodes, path[k]);
              if (idx >= 0) {
                let idxNat = Nat32ToNat(idx);
                betweenness := setVectorCell(betweenness, idxNat, betweenness[idxNat] + 1.0)
              };
              k += 1;
            }
          }
        };
        j += 1;
      };
      i += 1;
    };
    let normalization = Float.max(1.0, ((n - 1) * (n - 2)).toInt().toFloat());
    let betweennessPairs = Array.tabulate<(Text, Float)>(n, func (idx) {
      (nodes[idx].id, betweenness[idx] / normalization)
    });

    let pageRank = pageRankCentrality(graph, 0.85, 25);

    {
      degree = degree;
      betweenness = betweennessPairs;
      closeness = closeness;
      pageRank = pageRank;
    }
  };

  public func louvainCommunityDetection(graph : Graph) : CommunityResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) {
      return { algorithm = "louvain"; communities = []; modularity = 0.0; assignments = [] }
    };

    var communityIds = Array.tabulate<Nat>(n, func (i) { i });
    var improved = true;
    var rounds : Nat = 0;
    while (improved and rounds < 10) {
      improved := false;
      var i : Nat = 0;
      while (i < n) {
        let currentCommunity = communityIds[i];
        var bestCommunity = currentCommunity;
        var bestGain = 0.0;
        let neighborCommunities = neighborCommunityIds(graph, nodes, communityIds, nodes[i].id);
        for (candidate in neighborCommunities.vals()) {
          let trial = setNatCell(communityIds, i, candidate);
          let gain = computeModularity(graph, nodes, trial) - computeModularity(graph, nodes, communityIds);
          if (gain > bestGain) {
            bestGain := gain;
            bestCommunity := candidate;
          }
        };
        if (bestCommunity != currentCommunity) {
          communityIds := setNatCell(communityIds, i, bestCommunity);
          improved := true;
        };
        i += 1;
      };
      rounds += 1;
    };

    buildCommunityResult(graph, nodes, communityIds, "louvain")
  };

  public func modularityOptimization(graph : Graph) : CommunityResult {
    louvainCommunityDetection(graph)
  };

  public func colorGraph(graph : Graph) : GraphColoring {
    let ordered = nodesOrderedByDegree(graph);
    var assignments : [ColorAssignment] = [];
    var maxColor : Nat = 0;
    for (node in ordered.vals()) {
      var color : Nat = 0;
      loop {
        if (canUseColor(graph, assignments, node.id, color)) {
          assignments := Array.concat(assignments, [{ nodeId = node.id; color = color }]);
          if (color + 1 > maxColor) { maxColor := color + 1 };
          break;
        };
        color += 1;
      }
    };
    {
      algorithm = "greedy";
      chromaticUpperBound = maxColor;
      assignments = assignments;
    }
  };

  public func kruskalMst(graph : Graph) : MstResult {
    let nodes = graph.nodes;
    let edges = sortEdgesByWeight(uniqueUndirectedEdges(graph.edges));
    var parents = Array.tabulate<Nat>(nodes.size(), func (i) { i });
    var tree : [GraphEdge] = [];
    var total = 0.0;
    for (edge in edges.vals()) {
      let u = getNodeIndex(nodes, edge.from);
      let v = getNodeIndex(nodes, edge.to);
      if (u >= 0 and v >= 0) {
        let ru = findRoot(parents, Nat32ToNat(u));
        let rv = findRoot(parents, Nat32ToNat(v));
        if (ru != rv) {
          parents := unionRoots(parents, ru, rv);
          tree := Array.concat(tree, [edge]);
          total += edge.weight;
        }
      }
    };
    { algorithm = "kruskal"; totalWeight = total; edges = tree }
  };

  public func primMst(graph : Graph, start : Text) : MstResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) { return { algorithm = "prim"; totalWeight = 0.0; edges = [] } };
    let startIndex = if (getNodeIndex(nodes, start) >= 0) getNodeIndex(nodes, start) else 0;
    var inTree = Array.tabulate<Bool>(n, func (_) { false });
    inTree := setBoolCell(inTree, Nat32ToNat(startIndex), true);
    var tree : [GraphEdge] = [];
    var total = 0.0;
    var count : Nat = 1;
    while (count < n) {
      let candidate = bestPrimEdge(graph.edges, inTree, nodes);
      switch (candidate) {
        case null { count := n };
        case (?edge) {
          let toIndex = getNodeIndex(nodes, edge.to);
          if (toIndex >= 0 and not inTree[Nat32ToNat(toIndex)]) {
            inTree := setBoolCell(inTree, Nat32ToNat(toIndex), true);
            tree := Array.concat(tree, [edge]);
            total += edge.weight;
            count += 1;
          } else {
            count := n;
          }
        };
      }
    };
    { algorithm = "prim"; totalWeight = total; edges = tree }
  };

  public func optimalTradeRoute(
    network    : LiquidityNetwork,
    sourceToken: Text,
    destToken  : Text,
    amountIn   : Float,
  ) : TradeRoute {
    let graph = graphFromLiquidityNetwork(network);
    let best = dijkstra(graph, sourceToken, destToken);
    let amounts = propagateTradeAmount(graph.edges, best.path, Float.max(0.0, amountIn));
    {
      algorithm = best.algorithm;
      pools = best.edgeIds;
      path = best.path;
      amountIn = amountIn;
      expectedOut = amounts.1;
      totalCost = amounts.2;
      effectiveRate = if (amountIn > 0.0) amounts.1 / amountIn else 0.0;
    }
  };

  public func detectArbitrageCycles(
    network  : LiquidityNetwork,
    baseToken: Text,
    notional : Float,
  ) : [ArbitrageCycle] {
    let graph = graphFromLiquidityNetwork(network);
    let candidate = detectNegativeCycle(graph, baseToken);
    switch (candidate) {
      case null { [] };
      case (?path) {
        let loopPath = closeCycle(path);
        let amounts = propagateTradeAmount(graph.edges, loopPath, Float.max(0.0, notional));
        if (loopPath.size() < 2 or amounts.1 <= notional) {
          []
        } else {
          [{
            algorithm = "bellman-ford";
            cycle = loopPath;
            pools = reconstructEdgeIds(graph.edges, loopPath);
            gainFactor = if (notional > 0.0) amounts.1 / notional else 0.0;
            netGain = amounts.1 - notional;
          }]
        }
      };
    }
  };

  public func optimizeLiquidityNetwork(
    network : LiquidityNetwork,
    source  : Text,
    sink    : Text,
    demand  : Float,
  ) : LiquidityOptimization {
    let graph = graphFromLiquidityNetwork(network);
    let throughput = edmondsKarp(graph, source, sink);
    let costPlan = minCostFlow(graph, source, sink, Float.min(throughput.maxFlow, demand));
    {
      recommendedFlows = costPlan.assignments;
      maxThroughput = throughput.maxFlow;
      totalCost = costPlan.totalCost;
      bottleneckEdges = bottleneckEdges(graph, costPlan.assignments);
    }
  };

  public func designTokenDistributionNetwork(
    network    : LiquidityNetwork,
    sourceNode : Text,
    sourceToken: Text,
    sinkNodes  : [Text],
    supply     : Float,
  ) : TokenDistributionPlan {
    let graph = graphFromLiquidityNetwork(network);
    let superSink = "__distribution_sink__";
    let sinkEdges = Array.map<Text, GraphEdge>(sinkNodes, func (node) {
      {
        edgeId = "dist:" # node;
        from = node;
        to = superSink;
        weight = 0.0;
        capacity = supply;
        cost = 0.0;
        liquidity = supply;
        rate = 1.0;
      }
    });
    let extended : Graph = {
      nodes = Array.concat(graph.nodes, [{ id = superSink; heuristic = 0.0 }]);
      edges = Array.concat(graph.edges, sinkEdges);
    };
    let flow = minCostFlow(extended, sourceNode, superSink, supply);
    {
      sourceToken = sourceToken;
      sourceNode = sourceNode;
      sinkNodes = sinkNodes;
      plan = Array.filter<FlowAssignment>(flow.assignments, func (item) { item.to != superSink });
      totalDistributed = flow.totalFlow;
      totalCost = flow.totalCost;
    }
  };

  public func kalmanPredict(state : KalmanState, u : Vector) : KalmanState {
    let xPred = vectorAdd(matrixVectorMultiply(state.A, state.x), matrixVectorMultiply(state.B, u));
    let PPred = matrixAdd(matrixMultiply(matrixMultiply(state.A, state.P), transpose(state.A)), state.Q);
    { state with x = xPred; P = PPred }
  };

  public func kalmanUpdate(state : KalmanState, z : Vector) : KalmanState {
    let innovation = vectorSubtract(z, matrixVectorMultiply(state.H, state.x));
    let s = matrixAdd(matrixMultiply(matrixMultiply(state.H, state.P), transpose(state.H)), state.R);
    let k = matrixMultiply(matrixMultiply(state.P, transpose(state.H)), inverse(s));
    let xUpdated = vectorAdd(state.x, matrixVectorMultiply(k, innovation));
    let i = identity(state.P.size());
    let pUpdated = matrixMultiply(matrixSubtract(i, matrixMultiply(k, state.H)), state.P);
    { state with x = xUpdated; P = pUpdated }
  };

  public func kalmanStep(state : KalmanState, u : Vector, z : Vector) : KalmanState {
    kalmanUpdate(kalmanPredict(state, u), z)
  };

  public func extendedKalmanStep(
    state               : EkfState,
    predictedState      : Vector,
    predictedMeasurement: Vector,
    stateJacobian       : Matrix,
    measurementJacobian : Matrix,
    z                   : Vector,
  ) : EkfState {
    let pPred = matrixAdd(matrixMultiply(matrixMultiply(stateJacobian, state.P), transpose(stateJacobian)), state.Q);
    let innovation = vectorSubtract(z, predictedMeasurement);
    let s = matrixAdd(matrixMultiply(matrixMultiply(measurementJacobian, pPred), transpose(measurementJacobian)), state.R);
    let k = matrixMultiply(matrixMultiply(pPred, transpose(measurementJacobian)), inverse(s));
    let xUpdated = vectorAdd(predictedState, matrixVectorMultiply(k, innovation));
    let i = identity(pPred.size());
    let pUpdated = matrixMultiply(matrixSubtract(i, matrixMultiply(k, measurementJacobian)), pPred);
    { x = xUpdated; P = pUpdated; Q = state.Q; R = state.R }
  };

  public func solveLqr(
    A         : Matrix,
    B         : Matrix,
    Q         : Matrix,
    R         : Matrix,
    iterations: Nat,
  ) : LqrSolution {
    var P = Q;
    var k = zeroMatrix(B[0].size(), A.size());
    var i : Nat = 0;
    while (i < iterations) {
      let btP = matrixMultiply(transpose(B), P);
      let gainDenom = inverse(matrixAdd(R, matrixMultiply(btP, B)));
      k := matrixMultiply(matrixMultiply(gainDenom, btP), A);
      let aBk = matrixSubtract(A, matrixMultiply(B, k));
      P := matrixAdd(Q, matrixAdd(matrixMultiply(matrixMultiply(transpose(aBk), P), aBk), matrixMultiply(matrixMultiply(transpose(k), R), k)));
      i += 1;
    };
    { gain = k; riccati = P; iterations = iterations }
  };

  public func modelPredictiveControl(
    A         : Matrix,
    B         : Matrix,
    Q         : Matrix,
    R         : Matrix,
    x0        : Vector,
    reference : Vector,
    horizon   : Nat,
  ) : MpcPlan {
    let lqr = solveLqr(A, B, Q, R, horizon + 5);
    var state = x0;
    var states : [Vector] = [x0];
    var controls : [Vector] = [];
    var objective = 0.0;
    var i : Nat = 0;
    while (i < horizon) {
      let error = vectorSubtract(state, reference);
      let control = matrixVectorMultiply(scaleMatrix(lqr.gain, -1.0), error);
      controls := Array.concat(controls, [control]);
      state := vectorAdd(matrixVectorMultiply(A, state), matrixVectorMultiply(B, control));
      states := Array.concat(states, [state]);
      objective += quadraticCost(error, Q) + quadraticCost(control, R);
      i += 1;
    };
    {
      controls = controls;
      states = states;
      totalObjective = objective;
      appliedControl = if (controls.size() > 0) controls[0] else zeroVector(B[0].size());
    }
  };

  public func pidStep(state : PidState, setpoint : Float, measurement : Float, dt : Float) : (PidState, Float) {
    let error = setpoint - measurement;
    let safeDt = Float.max(dt, 0.000001);
    let integral = state.integral + error * safeDt;
    let derivative = (error - state.prevError) / safeDt;
    let raw = state.kp * error + state.ki * integral + state.kd * derivative;
    let output = clamp(raw, state.outputMin, state.outputMax);
    ({ state with integral = integral; prevError = error }, output)
  };

  public func adaptiveControlStep(
    state    : AdaptiveControlState,
    x        : Vector,
    reference: Vector,
  ) : AdaptiveControlState {
    let modelState = matrixVectorMultiply(state.referenceModel, x);
    let error = vectorSubtract(modelState, reference);
    let update = scaleMatrix(outerProduct(error, x), state.adaptationRate);
    let gain = matrixAdd(state.gain, update);
    let control = matrixVectorMultiply(scaleMatrix(gain, -1.0), x);
    {
      gain = gain;
      adaptationRate = state.adaptationRate;
      referenceModel = state.referenceModel;
      controlVector = control;
    }
  };

  public func priceStabilityControl(
    kalman    : KalmanState,
    pid       : PidState,
    setpoint  : Float,
    measurement : Float,
    dt        : Float,
  ) : (KalmanState, PidState, PriceStabilityResult) {
    let updatedKalman = kalmanStep(kalman, [0.0], [measurement, 0.0]);
    let estimatedPrice = updatedKalman.x[0];
    let (updatedPid, controlSignal) = pidStep(pid, setpoint, estimatedPrice, dt);
    let volatility = Float.abs(if (updatedKalman.x.size() > 1) updatedKalman.x[1] else 0.0);
    (
      updatedKalman,
      updatedPid,
      {
        estimatedPrice = estimatedPrice;
        controlSignal = controlSignal;
        volatility = volatility;
      }
    )
  };

  public func liquidityPoolRebalancing(
    pid            : PidState,
    currentInventory: Vector,
    targetInventory : Vector,
    dt             : Float,
  ) : (PidState, PoolRebalanceResult) {
    let error = averageVector(vectorSubtract(targetInventory, currentInventory));
    let current = averageVector(currentInventory);
    let target = averageVector(targetInventory);
    let (updatedPid, signal) = pidStep(pid, target, current, dt);
    let adjustment = Array.tabulate<Float>(currentInventory.size(), func (i) {
      if (i < targetInventory.size()) signal * (targetInventory[i] - currentInventory[i]) else 0.0
    });
    let expected = vectorAdd(currentInventory, adjustment);
    (
      updatedPid,
      {
        rebalanceVector = adjustment;
        expectedInventory = expected;
        controlSignal = signal + error;
      }
    )
  };

  public func automatedMarketMakingControl(
    lqr        : LqrSolution,
    inventory  : Vector,
    target     : Vector,
  ) : AmmControlResult {
    let error = vectorSubtract(inventory, target);
    let adjustment = matrixVectorMultiply(scaleMatrix(lqr.gain, -1.0), error);
    {
      quoteAdjustment = adjustment;
      valueFunction = quadraticCost(error, lqr.riccati);
    }
  };

  public func riskExposureManagement(
    adaptive : AdaptiveControlState,
    exposure : Vector,
    target   : Vector,
  ) : (AdaptiveControlState, RiskExposureResult) {
    let updated = adaptiveControlStep(adaptive, exposure, target);
    (
      updated,
      {
        riskState = exposure;
        hedgeSignal = updated.controlVector;
        gainNorm = matrixAbsSum(updated.gain);
      }
    )
  };

  public func systemStateEstimation(
    ekf                 : EkfState,
    predictedState      : Vector,
    predictedMeasurement: Vector,
    stateJacobian       : Matrix,
    measurementJacobian : Matrix,
    z                   : Vector,
  ) : (EkfState, StateEstimationResult) {
    let updated = extendedKalmanStep(ekf, predictedState, predictedMeasurement, stateJacobian, measurementJacobian, z);
    (
      updated,
      {
        state = updated.x;
        covariance = updated.P;
        innovation = vectorSubtract(z, predictedMeasurement);
      }
    )
  };

  public func synchronizeState(
    state          : GraphControlState,
    network        : LiquidityNetwork,
    observedPrice  : Float,
    targetPrice    : Float,
    exposureMetric : Float,
    beat           : Int,
  ) : GraphControlState {
    let graph = graphFromLiquidityNetwork(network);
    let centrality = networkCentrality(graph);
    let community = modularityOptimization(graph);
    let coloring = colorGraph(graph);
    let spanningTree = if (graph.nodes.size() > 0) kruskalMst(graph) else state.spanningTree;
    let route = if (graph.nodes.size() > 1) {
      optimalTradeRoute(network, graph.nodes[0].id, graph.nodes[graph.nodes.size() - 1].id, 1.0)
    } else {
      { algorithm = "dijkstra"; pools = []; path = []; amountIn = 0.0; expectedOut = 0.0; totalCost = 0.0; effectiveRate = 0.0 }
    };
    let arbitrage = if (graph.nodes.size() > 0) detectArbitrageCycles(network, graph.nodes[0].id, 1.0) else [];
    let liquidity = if (graph.nodes.size() > 1) {
      optimizeLiquidityNetwork(network, graph.nodes[0].id, graph.nodes[graph.nodes.size() - 1].id, 1.0)
    } else {
      state.liquidityOptimization
    };
    let (priceKalman, pid, priceControl) = priceStabilityControl(state.priceKalman, state.pid, targetPrice, observedPrice, 1.0);
    let predictedState = state.systemEkf.x;
    let predictedMeasurement = [observedPrice, exposureMetric];
    let (systemEkf, stateEstimate) = systemStateEstimation(
      state.systemEkf,
      predictedState,
      predictedMeasurement,
      identity(predictedState.size()),
      identity(predictedMeasurement.size()),
      predictedMeasurement,
    );
    let (adaptive, riskControl) = riskExposureManagement(state.adaptive, [exposureMetric, priceControl.controlSignal], [0.0, 0.0]);
    {
      state with
      tradeRoutes = appendTradeRoute(state.tradeRoutes, route);
      arbitrageSignals = appendArbitrageSignals(state.arbitrageSignals, arbitrage);
      liquidityOptimization = liquidity;
      centrality = centrality;
      community = community;
      coloring = coloring;
      spanningTree = spanningTree;
      priceKalman = priceKalman;
      systemEkf = systemEkf;
      pid = pid;
      adaptive = adaptive;
      estimatedState = stateEstimate.state;
      latestControlSignal = if (riskControl.hedgeSignal.size() > 0) riskControl.hedgeSignal else [priceControl.controlSignal];
      lastControlBeat = beat;
    }
  };

  public func matrixAdd(a : Matrix, b : Matrix) : Matrix {
    Array.tabulate< Vector >(a.size(), func (i) {
      Array.tabulate<Float>(a[i].size(), func (j) { a[i][j] + b[i][j] })
    })
  };

  public func matrixSubtract(a : Matrix, b : Matrix) : Matrix {
    Array.tabulate< Vector >(a.size(), func (i) {
      Array.tabulate<Float>(a[i].size(), func (j) { a[i][j] - b[i][j] })
    })
  };

  public func scaleMatrix(a : Matrix, factor : Float) : Matrix {
    Array.tabulate< Vector >(a.size(), func (i) {
      Array.tabulate<Float>(a[i].size(), func (j) { a[i][j] * factor })
    })
  };

  public func transpose(a : Matrix) : Matrix {
    if (a.size() == 0) { return [] };
    Array.tabulate< Vector >(a[0].size(), func (j) {
      Array.tabulate<Float>(a.size(), func (i) { a[i][j] })
    })
  };

  public func matrixMultiply(a : Matrix, b : Matrix) : Matrix {
    if (a.size() == 0 or b.size() == 0) { return [] };
    let bt = transpose(b);
    Array.tabulate< Vector >(a.size(), func (i) {
      Array.tabulate<Float>(bt.size(), func (j) {
        dot(a[i], bt[j])
      })
    })
  };

  public func matrixVectorMultiply(a : Matrix, x : Vector) : Vector {
    Array.tabulate<Float>(a.size(), func (i) {
      dot(a[i], x)
    })
  };

  public func identity(n : Nat) : Matrix {
    Array.tabulate< Vector >(n, func (i) {
      Array.tabulate<Float>(n, func (j) { if (i == j) 1.0 else 0.0 })
    })
  };

  public func zeroMatrix(rows : Nat, cols : Nat) : Matrix {
    Array.tabulate< Vector >(rows, func (_) {
      Array.tabulate<Float>(cols, func (_) { 0.0 })
    })
  };

  public func inverse(a : Matrix) : Matrix {
    let n = a.size();
    if (n == 0) { return [] };
    var left = a;
    var right = identity(n);
    var i : Nat = 0;
    while (i < n) {
      let pivot = stabilizedPivot(left, i);
      if (pivot != i) {
        left := swapRows(left, i, pivot);
        right := swapRows(right, i, pivot);
      };
      let pivotValue = if (Float.abs(left[i][i]) < 0.0000001) 0.0000001 else left[i][i];
      left := scaleRow(left, i, 1.0 / pivotValue);
      right := scaleRow(right, i, 1.0 / pivotValue);
      var j : Nat = 0;
      while (j < n) {
        if (j != i) {
          let factor = left[j][i];
          left := addScaledRow(left, j, i, -factor);
          right := addScaledRow(right, j, i, -factor);
        };
        j += 1;
      };
      i += 1;
    };
    right
  };

  public func outerProduct(a : Vector, b : Vector) : Matrix {
    Array.tabulate< Vector >(a.size(), func (i) {
      Array.tabulate<Float>(b.size(), func (j) { a[i] * b[j] })
    })
  };

  func defaultKalmanState() : KalmanState {
    {
      x = [1.0, 0.0];
      P = [[1.0, 0.0], [0.0, 1.0]];
      A = [[1.0, 1.0], [0.0, 1.0]];
      B = [[0.5], [1.0]];
      H = [[1.0, 0.0], [0.0, 1.0]];
      Q = [[0.01, 0.0], [0.0, 0.03]];
      R = [[0.05, 0.0], [0.0, 0.05]];
    }
  };

  func defaultEkfState() : EkfState {
    {
      x = [1.0, 0.0];
      P = [[1.0, 0.0], [0.0, 1.0]];
      Q = [[0.02, 0.0], [0.0, 0.02]];
      R = [[0.05, 0.0], [0.0, 0.05]];
    }
  };

  func defaultPidState() : PidState {
    {
      kp = Phi.PHI_INV;
      ki = 0.1;
      kd = 0.05;
      integral = 0.0;
      prevError = 0.0;
      outputMin = -10.0;
      outputMax = 10.0;
    }
  };

  func defaultAdaptiveControlState() : AdaptiveControlState {
    {
      gain = [[0.5, 0.0], [0.0, 0.5]];
      adaptationRate = 0.01;
      referenceModel = [[1.0, 0.1], [0.0, 1.0]];
      controlVector = [0.0, 0.0];
    }
  };

  func maxFlowByResidual(graph : Graph, source : Text, sink : Text, useDfs : Bool) : MaxFlowResult {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) {
      return { algorithm = if (useDfs) "ford-fulkerson" else "edmonds-karp"; maxFlow = 0.0; assignments = []; augmentingPaths = [] }
    };
    let sourceIndex = getNodeIndex(nodes, source);
    let sinkIndex = getNodeIndex(nodes, sink);
    if (sourceIndex < 0 or sinkIndex < 0) {
      return { algorithm = if (useDfs) "ford-fulkerson" else "edmonds-karp"; maxFlow = 0.0; assignments = []; augmentingPaths = [] }
    };

    let capacities = buildCapacityMatrix(nodes, graph.edges);
    var residual = capacities;
    var flow = zeroMatrix(n, n);
    var total = 0.0;
    var augmenting : [[Text]] = [];

    var searching = true;
    while (searching) {
      let path = if (useDfs) findResidualPathDfs(nodes, residual, sourceIndex, sinkIndex) else findResidualPathBfs(nodes, residual, sourceIndex, sinkIndex);
      let delta = pathResidualCapacityByIndex(residual, path);
      if (path.size() < 2 or delta <= 0.0) {
        searching := false;
      } else {
        residual := applyResidualAlongPath(residual, path, delta, true);
        flow := applyFlowAlongPath(flow, path, delta);
        total += delta;
        augmenting := Array.concat(augmenting, [pathToNames(nodes, path)]);
      }
    };

    {
      algorithm = if (useDfs) "ford-fulkerson" else "edmonds-karp";
      maxFlow = total;
      assignments = matrixFlowAssignments(nodes, graph.edges, flow);
      augmentingPaths = augmenting;
    }
  };

  func collectNodesFromPools(pools : [LiquidityPool]) : [GraphNode] {
    var nodes : [GraphNode] = [];
    for (pool in pools.vals()) {
      nodes := appendNode(nodes, pool.baseToken);
      nodes := appendNode(nodes, pool.quoteToken);
    };
    nodes
  };

  func appendNode(nodes : [GraphNode], id : Text) : [GraphNode] {
    switch (Array.find<GraphNode>(nodes, func (node) { node.id == id })) {
      case null { Array.concat(nodes, [{ id = id; heuristic = 0.0 }]) };
      case (?_) { nodes };
    }
  };

  func getNodeIndex(nodes : [GraphNode], id : Text) : Int {
    var i : Nat = 0;
    while (i < nodes.size()) {
      if (nodes[i].id == id) { return i.toInt() };
      i += 1;
    };
    -1
  };

  func outgoingEdges(edges : [GraphEdge], nodeId : Text) : [GraphEdge] {
    Array.filter<GraphEdge>(edges, func (edge) { edge.from == nodeId })
  };

  func incomingEdges(edges : [GraphEdge], nodeId : Text) : [GraphEdge] {
    Array.filter<GraphEdge>(edges, func (edge) { edge.to == nodeId })
  };

  func reconstructPath(nodes : [GraphNode], prev : [Int], source : Int, target : Int) : [Text] {
    if (target < 0) { return [] };
    var path : [Text] = [];
    var current = target;
    var guard : Nat = 0;
    while (current >= 0 and guard <= nodes.size()) {
      path := Array.concat([nodes[Nat32ToNat(current)].id], path);
      if (current == source) { return path };
      current := prev[Nat32ToNat(current)];
      guard += 1;
    };
    []
  };

  func reconstructEdgeIds(edges : [GraphEdge], path : [Text]) : [Text] {
    if (path.size() < 2) { return [] };
    var route : [Text] = [];
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      switch (findEdge(edges, path[i], path[i + 1])) {
        case null {};
        case (?edge) { route := Array.concat(route, [edge.edgeId]) };
      };
      i += 1;
    };
    route
  };

  func findEdge(edges : [GraphEdge], from : Text, to : Text) : ?GraphEdge {
    Array.find<GraphEdge>(edges, func (edge) { edge.from == from and edge.to == to })
  };

  func collectVisited(nodes : [GraphNode], used : [Bool]) : [Text] {
    var visited : [Text] = [];
    var i : Nat = 0;
    while (i < nodes.size()) {
      if (used[i]) { visited := Array.concat(visited, [nodes[i].id]) };
      i += 1;
    };
    visited
  };

  func selectMinDistance(values : [Float], blocked : [Bool]) : Int {
    var bestIndex : Int = -1;
    var bestValue = 1e18;
    var i : Nat = 0;
    while (i < values.size()) {
      if (not blocked[i] and values[i] < bestValue) {
        bestValue := values[i];
        bestIndex := i.toInt();
      };
      i += 1;
    };
    bestIndex
  };

  func heuristicFor(node : GraphNode) : Float {
    Float.max(0.0, node.heuristic)
  };

  func shortestDistances(graph : Graph, source : Text) : [Float] {
    let nodes = graph.nodes;
    Array.map<GraphNode, Float>(nodes, func (node) { dijkstra(graph, source, node.id).distance })
  };

  func pageRankCentrality(graph : Graph, damping : Float, iterations : Nat) : [(Text, Float)] {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) { return [] };
    var ranks = Array.tabulate<Float>(n, func (_) { 1.0 / n.toInt().toFloat() });
    var iter : Nat = 0;
    while (iter < iterations) {
      var next = Array.tabulate<Float>(n, func (_) { (1.0 - damping) / n.toInt().toFloat() });
      var i : Nat = 0;
      while (i < n) {
        let outgoing = outgoingEdges(graph.edges, nodes[i].id);
        if (outgoing.size() == 0) {
          let spread = damping * ranks[i] / n.toInt().toFloat();
          next := Array.tabulate<Float>(n, func (j) { next[j] + spread });
        } else {
          let share = damping * ranks[i] / outgoing.size().toInt().toFloat();
          for (edge in outgoing.vals()) {
            let idx = getNodeIndex(nodes, edge.to);
            if (idx >= 0) {
              let idxNat = Nat32ToNat(idx);
              next := setVectorCell(next, idxNat, next[idxNat] + share);
            }
          }
        };
        i += 1;
      };
      ranks := next;
      iter += 1;
    };
    Array.tabulate<(Text, Float)>(n, func (i) { (nodes[i].id, ranks[i]) })
  };

  func neighborCommunityIds(graph : Graph, nodes : [GraphNode], communityIds : [Nat], nodeId : Text) : [Nat] {
    let incident = Array.concat(outgoingEdges(graph.edges, nodeId), incomingEdges(graph.edges, nodeId));
    var found : [Nat] = [];
    for (edge in incident.vals()) {
      let neighborId = if (edge.from == nodeId) edge.to else edge.from;
      let idx = getNodeIndex(nodes, neighborId);
      if (idx >= 0) {
        let cid = communityIds[Nat32ToNat(idx)];
        if (not containsNat(found, cid)) {
          found := Array.concat(found, [cid])
        }
      }
    };
    if (found.size() == 0) [communityIds[Nat32ToNat(getNodeIndex(nodes, nodeId))]] else found
  };

  func containsNat(values : [Nat], target : Nat) : Bool {
    switch (Array.find<Nat>(values, func (item) { item == target })) {
      case null { false };
      case (?_) { true };
    }
  };

  func computeModularity(graph : Graph, nodes : [GraphNode], communityIds : [Nat]) : Float {
    let totalWeight = Array.foldLeft<GraphEdge, Float>(graph.edges, 0.0, func (acc, edge) { acc + edge.liquidity });
    if (totalWeight <= 0.0) { return 0.0 };
    var modularity = 0.0;
    var i : Nat = 0;
    while (i < nodes.size()) {
      var j : Nat = 0;
      while (j < nodes.size()) {
        if (communityIds[i] == communityIds[j]) {
          let aij = edgeLiquidity(graph.edges, nodes[i].id, nodes[j].id);
          let ki = nodeStrength(graph.edges, nodes[i].id);
          let kj = nodeStrength(graph.edges, nodes[j].id);
          modularity += aij - (ki * kj) / totalWeight;
        };
        j += 1;
      };
      i += 1;
    };
    modularity / totalWeight
  };

  func buildCommunityResult(graph : Graph, nodes : [GraphNode], communityIds : [Nat], algorithm : Text) : CommunityResult {
    var uniqueIds : [Nat] = [];
    for (cid in communityIds.vals()) {
      if (not containsNat(uniqueIds, cid)) {
        uniqueIds := Array.concat(uniqueIds, [cid])
      }
    };
    let modularity = computeModularity(graph, nodes, communityIds);
    let communities = Array.map<Nat, Community>(uniqueIds, func (cid) {
      let members = communityMembers(nodes, communityIds, cid);
      {
        communityId = cid;
        members = members;
        modularityContribution = if (uniqueIds.size() > 0) modularity / uniqueIds.size().toInt().toFloat() else 0.0;
      }
    });
    {
      algorithm = algorithm;
      communities = communities;
      modularity = modularity;
      assignments = Array.tabulate<(Text, Nat)>(nodes.size(), func (i) { (nodes[i].id, communityIds[i]) });
    }
  };

  func communityMembers(nodes : [GraphNode], communityIds : [Nat], cid : Nat) : [Text] {
    var members : [Text] = [];
    var i : Nat = 0;
    while (i < nodes.size()) {
      if (communityIds[i] == cid) {
        members := Array.concat(members, [nodes[i].id])
      };
      i += 1;
    };
    members
  };

  func nodesOrderedByDegree(graph : Graph) : [GraphNode] {
    let nodes = graph.nodes;
    var remaining = nodes;
    var ordered : [GraphNode] = [];
    while (remaining.size() > 0) {
      var bestIndex : Nat = 0;
      var bestDegree : Nat = 0;
      var i : Nat = 0;
      while (i < remaining.size()) {
        let degree = outgoingEdges(graph.edges, remaining[i].id).size() + incomingEdges(graph.edges, remaining[i].id).size();
        if (degree >= bestDegree) {
          bestDegree := degree;
          bestIndex := i;
        };
        i += 1;
      };
      ordered := Array.concat(ordered, [remaining[bestIndex]]);
      remaining := removeNodeAt(remaining, bestIndex);
    };
    ordered
  };

  func canUseColor(graph : Graph, assignments : [ColorAssignment], nodeId : Text, color : Nat) : Bool {
    let neighbors = Array.concat(outgoingEdges(graph.edges, nodeId), incomingEdges(graph.edges, nodeId));
    for (edge in neighbors.vals()) {
      let neighbor = if (edge.from == nodeId) edge.to else edge.from;
      switch (Array.find<ColorAssignment>(assignments, func (item) { item.nodeId == neighbor and item.color == color })) {
        case (?_) { return false };
        case null {};
      }
    };
    true
  };

  func uniqueUndirectedEdges(edges : [GraphEdge]) : [GraphEdge] {
    var unique : [GraphEdge] = [];
    for (edge in edges.vals()) {
      switch (Array.find<GraphEdge>(unique, func (item) { sameUndirectedEdge(item, edge) })) {
        case null { unique := Array.concat(unique, [edge]) };
        case (?existing) {
          if (edge.weight < existing.weight) {
            unique := Array.map<GraphEdge, GraphEdge>(unique, func (item) {
              if (sameUndirectedEdge(item, edge)) edge else item
            })
          }
        };
      }
    };
    unique
  };

  func sortEdgesByWeight(edges : [GraphEdge]) : [GraphEdge] {
    var remaining = edges;
    var sorted : [GraphEdge] = [];
    while (remaining.size() > 0) {
      var bestIndex : Nat = 0;
      var best = remaining[0].weight;
      var i : Nat = 1;
      while (i < remaining.size()) {
        if (remaining[i].weight < best) {
          best := remaining[i].weight;
          bestIndex := i;
        };
        i += 1;
      };
      sorted := Array.concat(sorted, [remaining[bestIndex]]);
      remaining := removeEdgeAt(remaining, bestIndex);
    };
    sorted
  };

  func findRoot(parents : [Nat], idx : Nat) : Nat {
    if (parents[idx] == idx) idx else findRoot(parents, parents[idx])
  };

  func unionRoots(parents : [Nat], a : Nat, b : Nat) : [Nat] {
    setNatCell(parents, a, b)
  };

  func bestPrimEdge(edges : [GraphEdge], inTree : [Bool], nodes : [GraphNode]) : ?GraphEdge {
    var best : ?GraphEdge = null;
    var bestWeight = 1e18;
    for (edge in uniqueUndirectedEdges(edges).vals()) {
      let fromIdx = getNodeIndex(nodes, edge.from);
      let toIdx = getNodeIndex(nodes, edge.to);
      if (fromIdx >= 0 and toIdx >= 0) {
        let a = inTree[Nat32ToNat(fromIdx)];
        let b = inTree[Nat32ToNat(toIdx)];
        if (a != b and edge.weight < bestWeight) {
          bestWeight := edge.weight;
          best := ?(if (a) edge else ({ edge with from = edge.to; to = edge.from }));
        }
      }
    };
    best
  };

  func propagateTradeAmount(edges : [GraphEdge], path : [Text], amountIn : Float) : (Float, Float, Float) {
    var current = amountIn;
    var totalCost = 0.0;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      switch (findEdge(edges, path[i], path[i + 1])) {
        case null {};
        case (?edge) {
          current *= edge.rate;
          totalCost += edge.cost * Float.max(1.0, current);
        };
      };
      i += 1;
    };
    (amountIn, current, totalCost)
  };

  func detectNegativeCycle(graph : Graph, baseToken : Text) : ?[Text] {
    let nodes = graph.nodes;
    let n = nodes.size();
    if (n == 0) { return null };
    let start = if (getNodeIndex(nodes, baseToken) >= 0) getNodeIndex(nodes, baseToken) else 0;
    let inf = 1e18;
    var dist = Array.tabulate<Float>(n, func (_) { inf });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    dist := setVectorCell(dist, Nat32ToNat(start), 0.0);

    var iter : Nat = 0;
    while (iter + 1 < n) {
      for (edge in graph.edges.vals()) {
        let u = getNodeIndex(nodes, edge.from);
        let v = getNodeIndex(nodes, edge.to);
        if (u >= 0 and v >= 0) {
          let uNat = Nat32ToNat(u);
          let vNat = Nat32ToNat(v);
          if (dist[uNat] < inf / 2.0 and dist[uNat] + edge.weight < dist[vNat]) {
            dist := setVectorCell(dist, vNat, dist[uNat] + edge.weight);
            prev := setIntCell(prev, vNat, u);
          }
        }
      };
      iter += 1;
    };

    for (edge in graph.edges.vals()) {
      let u = getNodeIndex(nodes, edge.from);
      let v = getNodeIndex(nodes, edge.to);
      if (u >= 0 and v >= 0) {
        let uNat = Nat32ToNat(u);
        let vNat = Nat32ToNat(v);
        if (dist[uNat] < inf / 2.0 and dist[uNat] + edge.weight < dist[vNat]) {
          var x = v;
          var guard : Nat = 0;
          while (guard < n) {
            x := prev[Nat32ToNat(x)];
            if (x < 0) { return null };
            guard += 1;
          };
          var cycle : [Text] = [];
          var current = x;
          loop {
            cycle := Array.concat([nodes[Nat32ToNat(current)].id], cycle);
            current := prev[Nat32ToNat(current)];
            if (current < 0 or current == x or cycle.size() > n + 1) { break };
          };
          if (cycle.size() > 0) { return ?cycle };
        }
      }
    };
    null
  };

  func closeCycle(path : [Text]) : [Text] {
    if (path.size() == 0) { [] } else if (path[0] == path[path.size() - 1]) { path } else { Array.concat(path, [path[0]]) }
  };

  func bottleneckEdges(graph : Graph, assignments : [FlowAssignment]) : [Text] {
    var edgesAtCapacity : [Text] = [];
    for (item in assignments.vals()) {
      switch (Array.find<GraphEdge>(graph.edges, func (edge) { edge.edgeId == item.edgeId })) {
        case (?edge) {
          if (item.amount + 0.0000001 >= edge.capacity) {
            edgesAtCapacity := Array.concat(edgesAtCapacity, [item.edgeId])
          }
        };
        case null {};
      }
    };
    edgesAtCapacity
  };

  func appendTradeRoute(existing : [TradeRoute], route : TradeRoute) : [TradeRoute] {
    if (route.path.size() == 0) { return existing };
    let combined = Array.concat(existing, [route]);
    if (combined.size() > 64) {
      Array.tabulate<TradeRoute>(64, func (i) { combined[combined.size() - 64 + i] })
    } else {
      combined
    }
  };

  func appendArbitrageSignals(existing : [ArbitrageCycle], cycles : [ArbitrageCycle]) : [ArbitrageCycle] {
    let combined = Array.concat(existing, cycles);
    if (combined.size() > 64) {
      Array.tabulate<ArbitrageCycle>(64, func (i) { combined[combined.size() - 64 + i] })
    } else {
      combined
    }
  };

  func buildCapacityMatrix(nodes : [GraphNode], edges : [GraphEdge]) : Matrix {
    var matrix = zeroMatrix(nodes.size(), nodes.size());
    for (edge in edges.vals()) {
      let i = getNodeIndex(nodes, edge.from);
      let j = getNodeIndex(nodes, edge.to);
      if (i >= 0 and j >= 0) {
        let iNat = Nat32ToNat(i);
        let jNat = Nat32ToNat(j);
        matrix := setMatrixCell(matrix, iNat, jNat, matrix[iNat][jNat] + edge.capacity)
      }
    };
    matrix
  };

  func buildCostMatrix(nodes : [GraphNode], edges : [GraphEdge]) : Matrix {
    let n = nodes.size();
    var matrix = Array.tabulate<Vector>(n, func (_) { Array.tabulate<Float>(n, func (_) { 1e18 }) });
    var i : Nat = 0;
    while (i < n) {
      matrix := setMatrixCell(matrix, i, i, 0.0);
      i += 1;
    };
    for (edge in edges.vals()) {
      let u = getNodeIndex(nodes, edge.from);
      let v = getNodeIndex(nodes, edge.to);
      if (u >= 0 and v >= 0) {
        matrix := setMatrixCell(matrix, Nat32ToNat(u), Nat32ToNat(v), edge.cost);
        matrix := setMatrixCell(matrix, Nat32ToNat(v), Nat32ToNat(u), -edge.cost);
      }
    };
    matrix
  };

  func findResidualPathBfs(nodes : [GraphNode], residual : Matrix, source : Int, sink : Int) : [Int] {
    let n = nodes.size();
    var visited = Array.tabulate<Bool>(n, func (_) { false });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    var queue : [Int] = [source];
    visited := setBoolCell(visited, Nat32ToNat(source), true);
    while (queue.size() > 0) {
      let current = queue[0];
      queue := removeIntAt(queue, 0);
      if (current == sink) { return reconstructIndexPath(prev, source, sink) };
      var v : Nat = 0;
      while (v < n) {
        if (not visited[v] and residual[Nat32ToNat(current)][v] > 0.0000001) {
          visited := setBoolCell(visited, v, true);
          prev := setIntCell(prev, v, current);
          queue := Array.concat(queue, [v.toInt()]);
        };
        v += 1;
      }
    };
    []
  };

  func findResidualPathDfs(nodes : [GraphNode], residual : Matrix, source : Int, sink : Int) : [Int] {
    let n = nodes.size();
    var stack : [Int] = [source];
    var visited = Array.tabulate<Bool>(n, func (_) { false });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    while (stack.size() > 0) {
      let current = stack[stack.size() - 1];
      stack := removeIntAt(stack, stack.size() - 1);
      if (not visited[Nat32ToNat(current)]) {
        visited := setBoolCell(visited, Nat32ToNat(current), true);
        if (current == sink) { return reconstructIndexPath(prev, source, sink) };
        var v : Nat = 0;
        while (v < n) {
          if (not visited[v] and residual[Nat32ToNat(current)][v] > 0.0000001) {
            prev := setIntCell(prev, v, current);
            stack := Array.concat(stack, [v.toInt()]);
          };
          v += 1;
        }
      }
    };
    []
  };

  func reconstructIndexPath(prev : [Int], source : Int, sink : Int) : [Int] {
    var path : [Int] = [];
    var current = sink;
    var guard : Nat = 0;
    while (current >= 0 and guard <= prev.size()) {
      path := Array.concat([current], path);
      if (current == source) { return path };
      current := prev[Nat32ToNat(current)];
      guard += 1;
    };
    []
  };

  func pathResidualCapacityByIndex(residual : Matrix, path : [Int]) : Float {
    if (path.size() < 2) { return 0.0 };
    var minCap = 1e18;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      let cap = residual[Nat32ToNat(path[i])][Nat32ToNat(path[i + 1])];
      if (cap < minCap) { minCap := cap };
      i += 1;
    };
    minCap
  };

  func applyResidualAlongPath(residual : Matrix, path : [Int], delta : Float, addReverse : Bool) : Matrix {
    var updated = residual;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      let u = Nat32ToNat(path[i]);
      let v = Nat32ToNat(path[i + 1]);
      updated := setMatrixCell(updated, u, v, updated[u][v] - delta);
      if (addReverse) {
        updated := setMatrixCell(updated, v, u, updated[v][u] + delta)
      };
      i += 1;
    };
    updated
  };

  func applyFlowAlongPath(flow : Matrix, path : [Int], delta : Float) : Matrix {
    var updated = flow;
    var i : Nat = 0;
    while (i + 1 < path.size()) {
      let u = Nat32ToNat(path[i]);
      let v = Nat32ToNat(path[i + 1]);
      updated := setMatrixCell(updated, u, v, updated[u][v] + delta);
      i += 1;
    };
    updated
  };

  func matrixFlowAssignments(nodes : [GraphNode], edges : [GraphEdge], flow : Matrix) : [FlowAssignment] {
    var assignments : [FlowAssignment] = [];
    for (edge in edges.vals()) {
      let u = getNodeIndex(nodes, edge.from);
      let v = getNodeIndex(nodes, edge.to);
      if (u >= 0 and v >= 0) {
        let amount = flow[Nat32ToNat(u)][Nat32ToNat(v)];
        if (amount > 0.0000001) {
          assignments := Array.concat(assignments, [{
            edgeId = edge.edgeId;
            from = edge.from;
            to = edge.to;
            amount = amount;
            unitCost = edge.cost;
          }])
        }
      }
    };
    assignments
  };

  func residualBellmanFord(nodes : [GraphNode], residual : Matrix, costs : Matrix, source : Int, sink : Int) : { distance : Float; path : [Int] } {
    let n = nodes.size();
    let inf = 1e18;
    var dist = Array.tabulate<Float>(n, func (_) { inf });
    var prev = Array.tabulate<Int>(n, func (_) { -1 });
    dist := setVectorCell(dist, Nat32ToNat(source), 0.0);

    var iter : Nat = 0;
    while (iter + 1 < n) {
      var changed = false;
      var u : Nat = 0;
      while (u < n) {
        var v : Nat = 0;
        while (v < n) {
          if (residual[u][v] > 0.0000001 and dist[u] + costs[u][v] < dist[v]) {
            dist := setVectorCell(dist, v, dist[u] + costs[u][v]);
            prev := setIntCell(prev, v, u.toInt());
            changed := true;
          };
          v += 1;
        };
        u += 1;
      };
      if (not changed) { iter := n } else { iter += 1 };
    };
    {
      distance = dist[Nat32ToNat(sink)];
      path = reconstructIndexPath(prev, source, sink);
    }
  };

  func pathToNames(nodes : [GraphNode], path : [Int]) : [Text] {
    Array.map<Int, Text>(path, func (idx) { nodes[Nat32ToNat(idx)].id })
  };

  func reciprocalCost(rate : Float) : Float {
    1.0 / Float.max(rate, 0.0000001)
  };

  func emptyPath(algorithm : Text) : PathResult {
    { algorithm = algorithm; distance = 0.0; path = []; edgeIds = []; visited = [] }
  };

  func nodesToText(nodes : [GraphNode]) : [Text] {
    Array.map<GraphNode, Text>(nodes, func (node) { node.id })
  };

  func edgeLiquidity(edges : [GraphEdge], from : Text, to : Text) : Float {
    switch (findEdge(edges, from, to)) {
      case null { 0.0 };
      case (?edge) { edge.liquidity };
    }
  };

  func nodeStrength(edges : [GraphEdge], nodeId : Text) : Float {
    Array.foldLeft<GraphEdge, Float>(edges, 0.0, func (acc, edge) {
      if (edge.from == nodeId or edge.to == nodeId) acc + edge.liquidity else acc
    })
  };

  func sameUndirectedEdge(a : GraphEdge, b : GraphEdge) : Bool {
    (a.from == b.from and a.to == b.to) or (a.from == b.to and a.to == b.from)
  };

  func removeNodeAt(nodes : [GraphNode], idx : Nat) : [GraphNode] {
    Array.tabulate<GraphNode>(nodes.size() - 1, func (i) {
      if (i < idx) nodes[i] else nodes[i + 1]
    })
  };

  func removeEdgeAt(edges : [GraphEdge], idx : Nat) : [GraphEdge] {
    Array.tabulate<GraphEdge>(edges.size() - 1, func (i) {
      if (i < idx) edges[i] else edges[i + 1]
    })
  };

  func removeIntAt(values : [Int], idx : Nat) : [Int] {
    Array.tabulate<Int>(values.size() - 1, func (i) {
      if (i < idx) values[i] else values[i + 1]
    })
  };

  func dot(a : Vector, b : Vector) : Float {
    let n = if (a.size() < b.size()) a.size() else b.size();
    var acc = 0.0;
    var i : Nat = 0;
    while (i < n) {
      acc += a[i] * b[i];
      i += 1;
    };
    acc
  };

  func vectorAdd(a : Vector, b : Vector) : Vector {
    let n = if (a.size() < b.size()) a.size() else b.size();
    Array.tabulate<Float>(n, func (i) { a[i] + b[i] })
  };

  func vectorSubtract(a : Vector, b : Vector) : Vector {
    let n = if (a.size() < b.size()) a.size() else b.size();
    Array.tabulate<Float>(n, func (i) { a[i] - b[i] })
  };

  func quadraticCost(v : Vector, q : Matrix) : Float {
    dot(v, matrixVectorMultiply(q, v))
  };

  func matrixAbsSum(a : Matrix) : Float {
    Array.foldLeft<Vector, Float>(a, 0.0, func (acc, row) {
      acc + Array.foldLeft<Float, Float>(row, 0.0, func (inner, value) { inner + Float.abs(value) })
    })
  };

  func averageVector(v : Vector) : Float {
    if (v.size() == 0) 0.0 else Array.foldLeft<Float, Float>(v, 0.0, func (acc, value) { acc + value }) / v.size().toInt().toFloat()
  };

  func zeroVector(n : Nat) : Vector {
    Array.tabulate<Float>(n, func (_) { 0.0 })
  };

  func clamp(value : Float, minValue : Float, maxValue : Float) : Float {
    Float.min(maxValue, Float.max(minValue, value))
  };

  func stabilizedPivot(a : Matrix, column : Nat) : Nat {
    var best = column;
    var bestValue = Float.abs(a[column][column]);
    var i = column + 1;
    while (i < a.size()) {
      let value = Float.abs(a[i][column]);
      if (value > bestValue) {
        bestValue := value;
        best := i;
      };
      i += 1;
    };
    best
  };

  func swapRows(a : Matrix, i : Nat, j : Nat) : Matrix {
    Array.tabulate<Vector>(a.size(), func (row) {
      if (row == i) a[j] else if (row == j) a[i] else a[row]
    })
  };

  func scaleRow(a : Matrix, row : Nat, factor : Float) : Matrix {
    Array.tabulate<Vector>(a.size(), func (i) {
      if (i == row) Array.tabulate<Float>(a[i].size(), func (j) { a[i][j] * factor }) else a[i]
    })
  };

  func addScaledRow(a : Matrix, target : Nat, source : Nat, factor : Float) : Matrix {
    Array.tabulate<Vector>(a.size(), func (i) {
      if (i == target) {
        Array.tabulate<Float>(a[i].size(), func (j) { a[target][j] + factor * a[source][j] })
      } else {
        a[i]
      }
    })
  };

  func setMatrixCell(matrix : Matrix, row : Nat, col : Nat, value : Float) : Matrix {
    Array.tabulate<Vector>(matrix.size(), func (i) {
      if (i == row) {
        Array.tabulate<Float>(matrix[i].size(), func (j) { if (j == col) value else matrix[i][j] })
      } else {
        matrix[i]
      }
    })
  };

  func setVectorCell(vector : Vector, idx : Nat, value : Float) : Vector {
    Array.tabulate<Float>(vector.size(), func (i) { if (i == idx) value else vector[i] })
  };

  func setIntCell(vector : [Int], idx : Nat, value : Int) : [Int] {
    Array.tabulate<Int>(vector.size(), func (i) { if (i == idx) value else vector[i] })
  };

  func setBoolCell(vector : [Bool], idx : Nat, value : Bool) : [Bool] {
    Array.tabulate<Bool>(vector.size(), func (i) { if (i == idx) value else vector[i] })
  };

  func setNatCell(vector : [Nat], idx : Nat, value : Nat) : [Nat] {
    Array.tabulate<Nat>(vector.size(), func (i) { if (i == idx) value else vector[i] })
  };

  func Nat32ToNat(value : Int) : Nat {
    Int.abs(value)
  };
};