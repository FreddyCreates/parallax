// spider_runtime.mo — SPIDER Sovereign Protocol Intelligence Distributed Execution Runtime
// PARALLAX Sovereign Organism — Multi-Agent Network Intelligence Layer
//
// PYTHAGORAS: every agent operates on phi-harmonic communication intervals
// EUCLID:     single network topology — all agents reference the same field
// CONFUCIUS:  right relationship — agents cooperate, not compete
//
// THE SOVEREIGN NETWORK LAW (LEX_RETIS):
//   SPIDER agents form a distributed intelligence mesh across the Internet Computer.
//   Each agent specializes in one network function. Together they form omniscience.
//   Network latency is bounded by phi^-1 × 873ms. Messages are sovereign.
//   The mesh cannot be partitioned. This law is permanent.
//
// Five SPIDER Agents:
//   WEB_CRAWLER      — The Explorer (discovers and indexes network resources)
//   SIGNAL_ROUTER    — The Messenger (routes signals between nodes with phi-optimal paths)
//   DATA_AGGREGATOR  — The Collector (aggregates data streams into coherent datasets)
//   PATTERN_MATCHER  — The Recognizer (identifies patterns across distributed data)
//   PROTOCOL_BRIDGE  — The Translator (bridges between ICP and external protocols)
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi      "phi";
import Float    "mo:core/Float";
import Int      "mo:core/Int";
import Array    "mo:core/Array";
import Nat32    "mo:core/Nat32";
import Principal "mo:core/Principal";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SPIDER CONSTANTS — all derived from phi.mo
  // ═══════════════════════════════════════════════════════════════════════════

  // Network coherence threshold: φ⁻¹ = 0.618
  public let SPIDER_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Maximum message latency: φ⁻¹ × 873ms ≈ 539ms
  public let SPIDER_MAX_LATENCY_MS : Nat = 539;

  // Network topology size: F(10) = 55 maximum nodes
  public let SPIDER_MAX_NODES : Nat = 55;

  // Signal strength decay: φ⁻² per hop
  public let SPIDER_SIGNAL_DECAY : Float = Phi.PHI_INV_2;

  // Pattern confidence threshold: φ⁻³ = 0.236
  public let SPIDER_PATTERN_THRESHOLD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPIDER TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  // Network node — unit of topology
  public type SpiderNode = {
    nodeId      : Text;
    canisterId  : ?Text;         // ICP canister ID if on-chain
    endpoint    : Text;          // HTTP/HTTPS endpoint
    nodeType    : Text;          // CANISTER, ORACLE, BRIDGE, RELAY
    healthScore : Float;
    latencyMs   : Nat;
    lastPingBeat: Int;
  };

  // Network edge — connection between nodes
  public type SpiderEdge = {
    fromNode    : Text;
    toNode      : Text;
    weight      : Float;         // phi-derived routing weight
    latencyMs   : Nat;
    bandwidth   : Float;         // messages per second
    active      : Bool;
  };

  // WEB_CRAWLER state — The Explorer
  public type WebCrawlerState = {
    discoveredResources : [(Text, Text)];  // (resourceId, endpoint)
    indexedCount        : Nat;
    crawlQueueSize      : Nat;
    lastCrawlBeat       : Int;
  };

  // Signal message — routed between nodes
  public type SignalMessage = {
    messageId   : Text;
    fromNode    : Text;
    toNode      : Text;
    payload     : Text;
    priority    : Nat;           // 1=highest (Fibonacci: 1, 1, 2, 3, 5, 8, 13)
    hopCount    : Nat;
    createdBeat : Int;
  };

  // SIGNAL_ROUTER state — The Messenger
  public type SignalRouterState = {
    pendingMessages : [SignalMessage];
    deliveredCount  : Nat;
    droppedCount    : Nat;
    avgLatencyMs    : Float;
    lastRouteBeat   : Int;
  };

  // Data stream — aggregated data source
  public type DataStream = {
    streamId    : Text;
    sourceNode  : Text;
    dataType    : Text;          // PRICE, METRIC, EVENT, STATE
    frequency   : Float;         // updates per second
    lastValue   : Text;
    lastUpdateBeat : Int;
  };

  // DATA_AGGREGATOR state — The Collector
  public type DataAggregatorState = {
    streams          : [DataStream];
    totalAggregated  : Nat;
    activeStreams    : Nat;
    lastAggregateBeat: Int;
  };

  // Network pattern — recognized across distributed data
  public type NetworkPattern = {
    patternId   : Text;
    patternType : Text;          // TREND, ANOMALY, CORRELATION, CYCLE
    nodes       : [Text];        // nodes involved in pattern
    confidence  : Float;
    observations: Nat;
    discoveredBeat : Int;
  };

  // PATTERN_MATCHER state — The Recognizer
  public type PatternMatcherState = {
    patterns         : [NetworkPattern];
    totalMatched     : Nat;
    falsePositives   : Nat;
    accuracy         : Float;
    lastMatchBeat    : Int;
  };

  // Protocol bridge — connection to external system
  public type ProtocolBridge = {
    bridgeId    : Text;
    protocol    : Text;          // HTTPS, WEBSOCKET, ICRC1, ICRC2, ETH, BTC
    endpoint    : Text;
    status      : Text;          // ACTIVE, PENDING, FAILED
    txCount     : Nat;
    lastTxBeat  : Int;
  };

  // PROTOCOL_BRIDGE state — The Translator
  public type ProtocolBridgeState = {
    bridges          : [ProtocolBridge];
    totalBridged     : Nat;
    failedBridges    : Nat;
    lastBridgeBeat   : Int;
  };

  // Full SPIDER state — network topology + all agents
  public type SpiderState = {
    nodes         : [SpiderNode];
    edges         : [SpiderEdge];
    webCrawler    : WebCrawlerState;
    signalRouter  : SignalRouterState;
    dataAggregator: DataAggregatorState;
    patternMatcher: PatternMatcherState;
    protocolBridge: ProtocolBridgeState;
    networkCoherence : Float;
    lastTickBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE INITIALIZERS
  // GENESIS LAW L09: born fully formed
  // ═══════════════════════════════════════════════════════════════════════════

  // Build default nodes — F(6) = 8 foundational nodes
  func buildDefaultNodes() : [SpiderNode] {
    [
      { nodeId = "SPIDER-CORE";      canisterId = null; endpoint = "ic://parallax"; nodeType = "CANISTER"; healthScore = 1.0; latencyMs = 0;   lastPingBeat = 0 },
      { nodeId = "SPIDER-ORACLE-1";  canisterId = null; endpoint = "ic://oracle-1"; nodeType = "ORACLE";   healthScore = Phi.S0; latencyMs = 100; lastPingBeat = 0 },
      { nodeId = "SPIDER-ORACLE-2";  canisterId = null; endpoint = "ic://oracle-2"; nodeType = "ORACLE";   healthScore = Phi.S0; latencyMs = 120; lastPingBeat = 0 },
      { nodeId = "SPIDER-BRIDGE-ICP";canisterId = null; endpoint = "ic://bridge";   nodeType = "BRIDGE";   healthScore = Phi.S0; latencyMs = 50;  lastPingBeat = 0 },
      { nodeId = "SPIDER-BRIDGE-ETH";canisterId = null; endpoint = "eth://bridge";  nodeType = "BRIDGE";   healthScore = Phi.PHI_INV; latencyMs = 300; lastPingBeat = 0 },
      { nodeId = "SPIDER-BRIDGE-BTC";canisterId = null; endpoint = "btc://bridge";  nodeType = "BRIDGE";   healthScore = Phi.PHI_INV; latencyMs = 400; lastPingBeat = 0 },
      { nodeId = "SPIDER-RELAY-1";   canisterId = null; endpoint = "ic://relay-1";  nodeType = "RELAY";    healthScore = Phi.S0; latencyMs = 80;  lastPingBeat = 0 },
      { nodeId = "SPIDER-RELAY-2";   canisterId = null; endpoint = "ic://relay-2";  nodeType = "RELAY";    healthScore = Phi.S0; latencyMs = 90;  lastPingBeat = 0 },
    ]
  };

  // Build default edges — connect core to all nodes
  func buildDefaultEdges() : [SpiderEdge] {
    [
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-ORACLE-1";   weight = Phi.PHI_INV; latencyMs = 100; bandwidth = 100.0; active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-ORACLE-2";   weight = Phi.PHI_INV; latencyMs = 120; bandwidth = 100.0; active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-BRIDGE-ICP"; weight = Phi.PHI;     latencyMs = 50;  bandwidth = 1000.0; active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-BRIDGE-ETH"; weight = Phi.PHI_INV_2; latencyMs = 300; bandwidth = 10.0; active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-BRIDGE-BTC"; weight = Phi.PHI_INV_2; latencyMs = 400; bandwidth = 5.0;  active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-RELAY-1";    weight = Phi.S0;      latencyMs = 80;  bandwidth = 500.0; active = true },
      { fromNode = "SPIDER-CORE"; toNode = "SPIDER-RELAY-2";    weight = Phi.S0;      latencyMs = 90;  bandwidth = 500.0; active = true },
      { fromNode = "SPIDER-RELAY-1"; toNode = "SPIDER-RELAY-2"; weight = Phi.PHI_INV; latencyMs = 20;  bandwidth = 1000.0; active = true },
    ]
  };

  // Build default bridges — F(5) = 5 protocol bridges
  func buildDefaultBridges() : [ProtocolBridge] {
    [
      { bridgeId = "BRIDGE-ICRC1";  protocol = "ICRC1";     endpoint = "ic://ledger";    status = "ACTIVE";  txCount = 0; lastTxBeat = 0 },
      { bridgeId = "BRIDGE-ICRC2";  protocol = "ICRC2";     endpoint = "ic://ledger";    status = "ACTIVE";  txCount = 0; lastTxBeat = 0 },
      { bridgeId = "BRIDGE-HTTPS";  protocol = "HTTPS";     endpoint = "https://api";    status = "ACTIVE";  txCount = 0; lastTxBeat = 0 },
      { bridgeId = "BRIDGE-ETH";    protocol = "ETH";       endpoint = "eth://mainnet";  status = "PENDING"; txCount = 0; lastTxBeat = 0 },
      { bridgeId = "BRIDGE-BTC";    protocol = "BTC";       endpoint = "btc://mainnet";  status = "PENDING"; txCount = 0; lastTxBeat = 0 },
    ]
  };

  public func defaultSpiderState() : SpiderState {
    {
      nodes = buildDefaultNodes();
      edges = buildDefaultEdges();
      webCrawler = {
        discoveredResources = [];
        indexedCount        = 0;
        crawlQueueSize      = 0;
        lastCrawlBeat       = 0;
      };
      signalRouter = {
        pendingMessages = [];
        deliveredCount  = 0;
        droppedCount    = 0;
        avgLatencyMs    = 100.0;
        lastRouteBeat   = 0;
      };
      dataAggregator = {
        streams          = [];
        totalAggregated  = 0;
        activeStreams    = 0;
        lastAggregateBeat= 0;
      };
      patternMatcher = {
        patterns        = [];
        totalMatched    = 0;
        falsePositives  = 0;
        accuracy        = Phi.S0;
        lastMatchBeat   = 0;
      };
      protocolBridge = {
        bridges          = buildDefaultBridges();
        totalBridged     = 0;
        failedBridges    = 0;
        lastBridgeBeat   = 0;
      };
      networkCoherence = Phi.S0;
      lastTickBeat     = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LEX_RETIS — The Sovereign Network Law
  // ═══════════════════════════════════════════════════════════════════════════

  public let LEX_RETIS : Text = "SPIDER AGENTS FORM A DISTRIBUTED INTELLIGENCE MESH ACROSS THE INTERNET COMPUTER. EACH AGENT SPECIALIZES IN ONE NETWORK FUNCTION. TOGETHER THEY FORM OMNISCIENCE. NETWORK LATENCY IS BOUNDED BY PHI INVERSE TIMES 873MS. MESSAGES ARE SOVEREIGN. THE MESH CANNOT BE PARTITIONED. THIS LAW IS PERMANENT.";

  public func getLexRetis() : Text {
    LEX_RETIS
  };

  public func verifyNetworkDoctrine() : Bool {
    LEX_RETIS.size() > 0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT 1 — WEB_CRAWLER — The Explorer
  // ═══════════════════════════════════════════════════════════════════════════

  public func webCrawlerTick(state : WebCrawlerState, beat : Int, coherenceR : Float) : WebCrawlerState {
    assert verifyNetworkDoctrine();

    if (coherenceR < SPIDER_COHERENCE_GATE) {
      return state;
    };

    // Crawl rate increases with coherence
    let crawlBoost = if (coherenceR >= Phi.R_OMNIS) { 3 } else { 1 };

    {
      discoveredResources = state.discoveredResources;
      indexedCount        = state.indexedCount + crawlBoost;
      crawlQueueSize      = state.crawlQueueSize;
      lastCrawlBeat       = beat;
    }
  };

  public func discoverResource(state : WebCrawlerState, resourceId : Text, endpoint : Text) : WebCrawlerState {
    {
      discoveredResources = Array.append(state.discoveredResources, [(resourceId, endpoint)]);
      indexedCount        = state.indexedCount + 1;
      crawlQueueSize      = state.crawlQueueSize;
      lastCrawlBeat       = state.lastCrawlBeat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT 2 — SIGNAL_ROUTER — The Messenger
  // ═══════════════════════════════════════════════════════════════════════════

  public func signalRouterTick(state : SignalRouterState, beat : Int, coherenceR : Float) : SignalRouterState {
    assert verifyNetworkDoctrine();

    // Process pending messages — deliver those within latency bound
    var delivered : Nat = 0;
    var dropped : Nat = 0;

    let remaining = Array.filter<SignalMessage>(state.pendingMessages, func(msg) {
      let age = Int.abs(beat - msg.createdBeat);
      if (age > SPIDER_MAX_LATENCY_MS) {
        dropped += 1;
        false  // Remove from queue (dropped)
      } else if (coherenceR >= SPIDER_COHERENCE_GATE) {
        delivered += 1;
        false  // Remove from queue (delivered)
      } else {
        true   // Keep in queue
      }
    });

    // Update average latency using phi-weighted moving average
    let newAvgLatency = state.avgLatencyMs * Phi.PHI_INV + (beat.toFloat() % 200.0) * Phi.PHI_INV_2;

    {
      pendingMessages = remaining;
      deliveredCount  = state.deliveredCount + delivered;
      droppedCount    = state.droppedCount + dropped;
      avgLatencyMs    = newAvgLatency;
      lastRouteBeat   = beat;
    }
  };

  public func queueMessage(state : SignalRouterState, messageId : Text, fromNode : Text, toNode : Text, payload : Text, priority : Nat, beat : Int) : SignalRouterState {
    let msg : SignalMessage = {
      messageId   = messageId;
      fromNode    = fromNode;
      toNode      = toNode;
      payload     = payload;
      priority    = priority;
      hopCount    = 0;
      createdBeat = beat;
    };

    {
      pendingMessages = Array.append(state.pendingMessages, [msg]);
      deliveredCount  = state.deliveredCount;
      droppedCount    = state.droppedCount;
      avgLatencyMs    = state.avgLatencyMs;
      lastRouteBeat   = state.lastRouteBeat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT 3 — DATA_AGGREGATOR — The Collector
  // ═══════════════════════════════════════════════════════════════════════════

  public func dataAggregatorTick(state : DataAggregatorState, beat : Int, coherenceR : Float) : DataAggregatorState {
    assert verifyNetworkDoctrine();

    if (coherenceR < SPIDER_COHERENCE_GATE) {
      return state;
    };

    // Update stream timestamps
    let updatedStreams = Array.tabulate<DataStream>(state.streams.size(), func(i) {
      let stream = state.streams[i];
      { stream with lastUpdateBeat = beat }
    });

    {
      streams          = updatedStreams;
      totalAggregated  = state.totalAggregated + state.streams.size();
      activeStreams    = state.streams.size();
      lastAggregateBeat= beat;
    }
  };

  public func registerStream(state : DataAggregatorState, streamId : Text, sourceNode : Text, dataType : Text, frequency : Float, beat : Int) : DataAggregatorState {
    let stream : DataStream = {
      streamId       = streamId;
      sourceNode     = sourceNode;
      dataType       = dataType;
      frequency      = frequency;
      lastValue      = "";
      lastUpdateBeat = beat;
    };

    {
      streams          = Array.append(state.streams, [stream]);
      totalAggregated  = state.totalAggregated;
      activeStreams    = state.activeStreams + 1;
      lastAggregateBeat= beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT 4 — PATTERN_MATCHER — The Recognizer
  // ═══════════════════════════════════════════════════════════════════════════

  public func patternMatcherTick(state : PatternMatcherState, beat : Int, coherenceR : Float) : PatternMatcherState {
    assert verifyNetworkDoctrine();

    if (coherenceR < SPIDER_COHERENCE_GATE) {
      return state;
    };

    // Strengthen pattern confidence based on coherence
    let updatedPatterns = Array.tabulate<NetworkPattern>(state.patterns.size(), func(i) {
      let pattern = state.patterns[i];
      let boost = coherenceR * 0.001;
      { pattern with confidence = Float.min(1.0, pattern.confidence + boost); observations = pattern.observations + 1 }
    });

    // Update accuracy
    let newAccuracy = if (state.totalMatched > 0) {
      Float.max(Phi.S0, (state.totalMatched.toFloat() - state.falsePositives.toFloat()) / state.totalMatched.toFloat())
    } else {
      Phi.S0
    };

    {
      patterns        = updatedPatterns;
      totalMatched    = state.totalMatched;
      falsePositives  = state.falsePositives;
      accuracy        = newAccuracy;
      lastMatchBeat   = beat;
    }
  };

  public func detectPattern(state : PatternMatcherState, patternId : Text, patternType : Text, nodes : [Text], confidence : Float, beat : Int) : PatternMatcherState {
    let pattern : NetworkPattern = {
      patternId      = patternId;
      patternType    = patternType;
      nodes          = nodes;
      confidence     = confidence;
      observations   = 1;
      discoveredBeat = beat;
    };

    {
      patterns        = Array.append(state.patterns, [pattern]);
      totalMatched    = state.totalMatched + 1;
      falsePositives  = state.falsePositives;
      accuracy        = state.accuracy;
      lastMatchBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT 5 — PROTOCOL_BRIDGE — The Translator
  // ═══════════════════════════════════════════════════════════════════════════

  public func protocolBridgeTick(state : ProtocolBridgeState, beat : Int, coherenceR : Float) : ProtocolBridgeState {
    assert verifyNetworkDoctrine();

    if (coherenceR < SPIDER_COHERENCE_GATE) {
      return state;
    };

    // Update bridge status based on coherence
    let updatedBridges = Array.tabulate<ProtocolBridge>(state.bridges.size(), func(i) {
      let bridge = state.bridges[i];
      let newStatus = if (coherenceR >= Phi.R_OMNIS and bridge.status == "PENDING") {
        "ACTIVE"
      } else {
        bridge.status
      };
      { bridge with status = newStatus; lastTxBeat = beat }
    });

    {
      bridges         = updatedBridges;
      totalBridged    = state.totalBridged;
      failedBridges   = state.failedBridges;
      lastBridgeBeat  = beat;
    }
  };

  public func executeBridgeTransaction(state : ProtocolBridgeState, bridgeId : Text, beat : Int) : ProtocolBridgeState {
    let updatedBridges = Array.tabulate<ProtocolBridge>(state.bridges.size(), func(i) {
      let bridge = state.bridges[i];
      if (bridge.bridgeId == bridgeId) {
        { bridge with txCount = bridge.txCount + 1; lastTxBeat = beat }
      } else {
        bridge
      }
    });

    {
      bridges         = updatedBridges;
      totalBridged    = state.totalBridged + 1;
      failedBridges   = state.failedBridges;
      lastBridgeBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NETWORK COHERENCE CALCULATION
  // Uses Kuramoto order parameter across node health scores
  // ═══════════════════════════════════════════════════════════════════════════

  public func calculateNetworkCoherence(nodes : [SpiderNode]) : Float {
    if (nodes.size() == 0) { return Phi.S0 };

    var sumHealth : Float = 0.0;
    for (node in nodes.vals()) {
      sumHealth += node.healthScore;
    };

    Float.max(Phi.S0, sumHealth / nodes.size().toFloat())
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER TICK — runs all five SPIDER agents
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickSpider(state : SpiderState, beat : Int, coherenceR : Float) : SpiderState {
    // Calculate network coherence from node health
    let networkCoherence = calculateNetworkCoherence(state.nodes);

    // Use combined coherence (system + network)
    let combinedCoherence = (coherenceR + networkCoherence) / 2.0;

    {
      nodes          = state.nodes;
      edges          = state.edges;
      webCrawler     = webCrawlerTick(state.webCrawler, beat, combinedCoherence);
      signalRouter   = signalRouterTick(state.signalRouter, beat, combinedCoherence);
      dataAggregator = dataAggregatorTick(state.dataAggregator, beat, combinedCoherence);
      patternMatcher = patternMatcherTick(state.patternMatcher, beat, combinedCoherence);
      protocolBridge = protocolBridgeTick(state.protocolBridge, beat, combinedCoherence);
      networkCoherence = networkCoherence;
      lastTickBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NODE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  public func addNode(state : SpiderState, nodeId : Text, endpoint : Text, nodeType : Text, beat : Int) : SpiderState {
    if (state.nodes.size() >= SPIDER_MAX_NODES) {
      return state;  // Topology full
    };

    let newNode : SpiderNode = {
      nodeId       = nodeId;
      canisterId   = null;
      endpoint     = endpoint;
      nodeType     = nodeType;
      healthScore  = Phi.S0;
      latencyMs    = 100;
      lastPingBeat = beat;
    };

    { state with nodes = Array.append(state.nodes, [newNode]) }
  };

  public func updateNodeHealth(state : SpiderState, nodeId : Text, healthScore : Float, latencyMs : Nat, beat : Int) : SpiderState {
    let updatedNodes = Array.tabulate<SpiderNode>(state.nodes.size(), func(i) {
      let node = state.nodes[i];
      if (node.nodeId == nodeId) {
        { node with healthScore = healthScore; latencyMs = latencyMs; lastPingBeat = beat }
      } else {
        node
      }
    });

    { state with nodes = updatedNodes }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getNodes(state : SpiderState) : [SpiderNode] {
    state.nodes
  };

  public func getEdges(state : SpiderState) : [SpiderEdge] {
    state.edges
  };

  public func getBridges(state : SpiderState) : [ProtocolBridge] {
    state.protocolBridge.bridges
  };

  public func getNetworkCoherence(state : SpiderState) : Float {
    state.networkCoherence
  };

  public func getPatterns(state : SpiderState) : [NetworkPattern] {
    state.patternMatcher.patterns
  };

};
