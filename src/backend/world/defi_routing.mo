import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

// ============================================================
// DEFI ROUTING ENGINE — PARALLAX PHASE K
// Cross-protocol yield routing, auto-rebalancing,
// AURUM council organism primary tool, FORMA capital allocation
// Protocols: Lido, EigenLayer, Rocket Pool, Marinade, Jito, NNS
// ============================================================
module {

  let NUM_PROTOCOLS : Nat = 6;
  // Protocol codes: 0=Lido 1=EigenLayer 2=RocketPool 3=Marinade 4=Jito 5=NNS

  public type ProtocolState = {
    var allocated     : Float;  // Capital allocated to this protocol
    var apr           : Float;  // Current APR
    var risk          : Float;  // Risk score [1.0, 2.0]: 1=low, 2=high
    var tvl           : Float;  // Total value locked proxy
    var yieldAccrued  : Float;  // Total yield earned lifetime
    var yieldBeat     : Float;  // Yield this beat
    var active        : Bool;   // Is protocol active
    var lastRebalance : Nat;    // Beat of last rebalance
  };

  public type DefiRoutingState = {
    var protocols        : [var ProtocolState];
    var totalAllocated   : Float;
    var totalYieldBeat   : Float;    // Sum of all protocol yields this beat
    var totalYieldLife   : Float;    // Lifetime total
    var aurumScore       : Float;    // AURUM treasury health [1.0, 2.0]
    var rebalanceCooldown: Nat;      // Beats until next rebalance allowed
    var rebalanceCount   : Nat;
    var optimalAlloc     : [var Float]; // Target allocation fractions
    var actualAlloc      : [var Float]; // Current allocation fractions
    var allocationDrift  : Float;    // Max deviation from optimal
    var rebalanceNeeded  : Bool;
    var riskAdjReturn    : Float;    // Sharpe-like metric
    var diversityScore   : Float;    // Herfindahl index inverse
    var mrcYieldBeat     : Float;    // MRC routing yield this beat
    var formaYieldBeat   : Float;    // FORMA energy from DeFi
    var defiSignalStrength: Float;
  };

  func initProtocol(alloc: Float, apr: Float, risk: Float, tvl: Float) : ProtocolState = {
    var allocated     = alloc;
    var apr           = apr;
    var risk          = risk;
    var tvl           = tvl;
    var yieldAccrued  = 0.0;
    var yieldBeat     = 0.0;
    var active        = true;
    var lastRebalance = 0;
  };

  public func initDefiRoutingState() : DefiRoutingState = {
    var protocols = [
      var initProtocol(300.0, 0.037, 1.1, 1000000.0), // Lido
          initProtocol(200.0, 0.049, 1.3, 500000.0),  // EigenLayer
          initProtocol(100.0, 0.035, 1.2, 300000.0),  // RocketPool
          initProtocol(200.0, 0.075, 1.2, 400000.0),  // Marinade
          initProtocol(100.0, 0.085, 1.3, 350000.0),  // Jito
          initProtocol(100.0, 0.180, 1.0, 900000.0)   // NNS
    ];
    var totalAllocated   = 1000.0;
    var totalYieldBeat   = 0.0;
    var totalYieldLife   = 0.0;
    var aurumScore       = 1.5;
    var rebalanceCooldown= 0;
    var rebalanceCount   = 0;
    var optimalAlloc     = Array.init<Float>(6, 1.0/6.0);
    var actualAlloc      = Array.init<Float>(6, 1.0/6.0);
    var allocationDrift  = 0.0;
    var rebalanceNeeded  = false;
    var riskAdjReturn    = 1.0;
    var diversityScore   = 1.0;
    var mrcYieldBeat     = 0.0;
    var formaYieldBeat   = 1.0;
    var defiSignalStrength = 1.0;
  };

  // Risk-adjusted return: sum(apr_i * alloc_i) / sum(risk_i * alloc_i)
  func computeRiskAdjReturn(protocols: [var ProtocolState], total: Float) : Float {
    var sumReturn = 0.0;
    var sumRisk   = 0.0;
    for (p in protocols.vals()) {
      if (p.active) {
        let w = p.allocated / Float.max(1.0, total);
        sumReturn += p.apr * w;
        sumRisk   += p.risk * w;
      };
    };
    Float.max(1.0, sumReturn / Float.max(0.001, sumRisk))
  };

  // Herfindahl diversity: 1 - sum(w_i^2)
  // Higher = more diversified
  func computeDiversity(protocols: [var ProtocolState], total: Float) : Float {
    var hhi = 0.0;
    for (p in protocols.vals()) {
      let w = p.allocated / Float.max(1.0, total);
      hhi += w * w;
    };
    Float.max(1.0, 1.0 + (1.0 - hhi))
  };

  // Optimal allocation: weight by (APR / risk) normalized
  // More yield per unit risk = more allocation
  func computeOptimalAlloc(protocols: [var ProtocolState]) : [var Float] {
    let scores = Array.init<Float>(NUM_PROTOCOLS, 0.0);
    var total = 0.0;
    var i = 0;
    for (p in protocols.vals()) {
      let s = if (p.active) p.apr / Float.max(1.0, p.risk) else 0.0;
      scores[i] := s;
      total += s;
      i += 1;
    };
    let result = Array.init<Float>(NUM_PROTOCOLS, 0.0);
    var j = 0;
    for (sc in scores.vals()) {
      result[j] := sc / Float.max(0.0001, total);
      j += 1;
    };
    result
  };

  // Compute allocation drift: max |actual - optimal|
  func allocationDrift(actual: [var Float], optimal: [var Float]) : Float {
    var maxDrift = 0.0;
    var i = 0;
    while (i < NUM_PROTOCOLS) {
      let drift = Float.abs(actual[i] - optimal[i]);
      if (drift > maxDrift) maxDrift := drift;
      i += 1;
    };
    maxDrift
  };

  // Rebalance: move allocations toward optimal
  // Gentle rebalancing: 10% correction per rebalance event
  func rebalance(
    protocols : [var ProtocolState],
    optimal   : [var Float],
    total     : Float
  ) {
    var i = 0;
    for (opt in optimal.vals()) {
      let targetAlloc = opt * total;
      let current = protocols[i].allocated;
      let correction = (targetAlloc - current) * 0.10;
      protocols[i].allocated := Float.max(0.0, current + correction);
      i += 1;
    };
  };

  // AURUM score: weighted health of all protocols
  func computeAurumScore(
    rar     : Float,
    div     : Float,
    drift   : Float,
    C       : Float
  ) : Float {
    Float.max(1.0, Float.min(2.0,
      rar * 0.4 + div * 0.3 + (1.0 - Float.min(1.0, drift * 5.0)) * 0.3 + (C - 1.0) * 0.2
    ))
  };

  public func updateDefiRouting(
    s          : DefiRoutingState,
    // Per-protocol APR updates (0 = no update)
    lidoApr    : Float,
    eigenApr   : Float,
    rpApr      : Float,
    marinApr   : Float,
    jitoApr    : Float,
    nnsApr     : Float,
    beatCount  : Nat,
    coherenceC : Float
  ) : DefiRoutingState {
    // Update APRs if new data
    if (lidoApr  > 0.001) s.protocols[0].apr := lidoApr;
    if (eigenApr > 0.001) s.protocols[1].apr := eigenApr;
    if (rpApr    > 0.001) s.protocols[2].apr := rpApr;
    if (marinApr > 0.001) s.protocols[3].apr := marinApr;
    if (jitoApr  > 0.001) s.protocols[4].apr := jitoApr;
    if (nnsApr   > 0.001) s.protocols[5].apr := nnsApr;

    // Compound each protocol
    var totalYield = 0.0;
    var totalAlloc = 0.0;
    var i = 0;
    for (p in s.protocols.vals()) {
      if (p.active) {
        let beatYield = p.allocated * p.apr / 365.0 / 144.0;
        p.yieldBeat     := beatYield;
        p.yieldAccrued  := p.yieldAccrued + beatYield;
        p.allocated     := p.allocated + beatYield; // auto-compound
        totalYield      += beatYield;
        totalAlloc      += p.allocated;
      };
      i += 1;
    };

    // Update actual allocation fractions
    var j = 0;
    for (p in s.protocols.vals()) {
      s.actualAlloc[j] := if (p.active) p.allocated / Float.max(1.0, totalAlloc) else 0.0;
      j += 1;
    };

    // Compute optimal allocation
    let optimal = computeOptimalAlloc(s.protocols);
    var k = 0;
    for (o in optimal.vals()) {
      s.optimalAlloc[k] := o;
      k += 1;
    };

    // Check drift
    let drift = allocationDrift(s.actualAlloc, optimal);
    let needRebal = drift > 0.15; // Rebalance if any protocol drifts >15%

    // Rebalance if needed and off cooldown
    var newCD = if (s.rebalanceCooldown > 0) s.rebalanceCooldown - 1 else 0;
    var newRebalCount = s.rebalanceCount;
    if (needRebal and newCD == 0) {
      rebalance(s.protocols, optimal, totalAlloc);
      newCD := 1440; // 10-day cooldown
      newRebalCount += 1;
    };

    // Risk-adjusted return and diversity
    let rar = computeRiskAdjReturn(s.protocols, totalAlloc);
    let div = computeDiversity(s.protocols, totalAlloc);
    let aurumScore = computeAurumScore(rar, div, drift, coherenceC);

    // MRC cut: 20% of all yield
    let mrcY = totalYield * 0.20;

    // FORMA contribution
    let fc = Float.max(1.0, totalYield * coherenceC * 10.0);

    // Composite signal
    let sig = Float.max(1.0, aurumScore * div * 0.5);

    s.totalAllocated    := totalAlloc;
    s.totalYieldBeat    := totalYield;
    s.totalYieldLife    := s.totalYieldLife + totalYield;
    s.aurumScore        := aurumScore;
    s.rebalanceCooldown := newCD;
    s.rebalanceCount    := newRebalCount;
    s.allocationDrift   := drift;
    s.rebalanceNeeded   := needRebal;
    s.riskAdjReturn     := rar;
    s.diversityScore    := div;
    s.mrcYieldBeat      := mrcY;
    s.formaYieldBeat    := fc;
    s.defiSignalStrength := sig;
    s
  };

  // Best protocol by APR/risk ratio
  public func bestProtocol(s: DefiRoutingState) : Nat {
    var bestIdx = 0;
    var bestScore = 0.0;
    var i = 0;
    for (p in s.protocols.vals()) {
      let sc = if (p.active) p.apr / Float.max(1.0, p.risk) else 0.0;
      if (sc > bestScore) { bestScore := sc; bestIdx := i; };
      i += 1;
    };
    bestIdx
  };

};
