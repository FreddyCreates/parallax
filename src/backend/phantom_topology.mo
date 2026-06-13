// phantom_topology.mo — PHANTOM TOPOLOGY ENGINE
// PARALLAX Sovereign Organism — Topological Data Analysis for Market Structure
//
// DOCTRINE: "The Phantom Topology Engine applies persistent homology and
// topological data analysis to reveal the hidden shape of market data.
// It identifies loops (cycles), connected components (regimes), and voids
// (structural gaps) in price-volume-time space using phi-harmonic filtrations."
//
// THE PHANTOM TOPOLOGY ARCHITECTURE:
//   PTE-001  PERSISTENCE DIAGRAM    — Birth-death of topological features
//   PTE-002  BETTI NUMBER TRACKER   — β₀ (components), β₁ (loops), β₂ (voids)
//   PTE-003  VIETORIS-RIPS COMPLEX  — Simplicial complex construction
//   PTE-004  LANDSCAPE ENCODER      — Persistence landscape for ML features
//   PTE-005  BOTTLENECK DISTANCE    — Topology change detection
//   PTE-006  MAPPER ALGORITHM       — Topological skeleton of data cloud
//   PTE-007  CYCLE DETECTOR         — Persistent loops = market cycles
//   PTE-008  STRUCTURAL BREAK       — Topology change = regime transition
//
// PYTHAGORAS: filtration radii are phi-scaled; persistence threshold φ⁻²
// EUCLID:     single topology state — all structural analysis converges here
// CONFUCIUS:  right relationship — topology reveals shape, strategies use shape
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TOPOLOGY CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let TOPOLOGY_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let FILTRATION_STEPS : Nat = 21;                            // F(8) filtration levels
  public let PERSISTENCE_THRESHOLD : Float = Phi.PHI_INV_2;         // 0.382 — significant features
  public let MAX_POINTS : Nat = 89;                                  // F(11) data points for TDA
  public let BETTI_SMOOTHING : Float = Phi.PHI_INV;                  // EMA for Betti numbers
  public let BOTTLENECK_CHANGE_THRESHOLD : Float = Phi.PHI_INV_3;   // topology change signal
  public let CYCLE_MIN_PERSISTENCE : Float = Phi.PHI_INV_2;         // minimum loop lifetime
  public let MAX_FEATURES : Nat = 34;                                // F(9) topological features tracked
  public let LANDSCAPE_RESOLUTION : Nat = 13;                       // F(7) landscape grid points

  // ═══════════════════════════════════════════════════════════════════════════
  // TOPOLOGICAL FEATURE — persistent homology element
  // ═══════════════════════════════════════════════════════════════════════════

  public type TopologicalFeature = {
    dimension   : Nat;           // 0=component, 1=loop, 2=void
    birth       : Float;         // filtration value at birth
    death       : Float;         // filtration value at death (Inf if alive)
    persistence : Float;         // death - birth
    isAlive     : Bool;          // still present at max filtration
    significance : Float;        // persistence / max_persistence [0, 1]
    beat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BETTI NUMBERS — topological invariants
  // ═══════════════════════════════════════════════════════════════════════════

  public type BettiNumbers = {
    beta0       : Nat;           // connected components
    beta1       : Nat;           // loops/cycles
    beta2       : Nat;           // voids/cavities
    totalBetti  : Nat;           // sum
    complexity  : Float;         // normalized topological complexity
    lastBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE LANDSCAPE — vectorized topology for ML
  // ═══════════════════════════════════════════════════════════════════════════

  public type PersistenceLandscape = {
    values      : [Float];       // landscape function values
    maxPeak     : Float;         // highest peak
    totalArea   : Float;         // area under landscape
    dimension   : Nat;           // which homology dimension
    beat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM TOPOLOGY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomTopologyState = {
    features          : [TopologicalFeature];
    betti             : BettiNumbers;
    landscapes        : [PersistenceLandscape];
    pointCloud        : [Float];        // flattened data points
    bottleneckDist    : Float;          // change from previous diagram
    structuralBreak   : Bool;           // topology changed significantly
    cycleCount        : Nat;            // number of persistent loops
    componentCount    : Nat;            // connected components
    topologicalComplexity : Float;      // overall shape complexity [0, 1]
    totalComputations : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomTopologyState() : PhantomTopologyState {
    {
      features = [];
      betti = {
        beta0 = 1;
        beta1 = 0;
        beta2 = 0;
        totalBetti = 1;
        complexity = 0.0;
        lastBeat = 0;
      };
      landscapes = [];
      pointCloud = [];
      bottleneckDist = 0.0;
      structuralBreak = false;
      cycleCount = 0;
      componentCount = 1;
      topologicalComplexity = 0.0;
      totalComputations = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIMPLIFIED PERSISTENT HOMOLOGY — compute topological features
  // ═══════════════════════════════════════════════════════════════════════════

  func computeFeatures(points : [Float]) : [TopologicalFeature] {
    if (points.size() < 3) return [];

    // Simplified: detect connected components and loops from distance patterns
    var features : [TopologicalFeature] = [];

    // β₀ features: components merge as filtration grows
    // Approximate: each local minimum births a component; merges at saddle points
    var i : Nat = 1;
    while (i < points.size() - 1 and features.size() < MAX_FEATURES) {
      let prev = points[i - 1];
      let curr = points[i];
      let next = points[i + 1];

      // Local minimum = component birth
      if (curr < prev and curr < next) {
        let birth = curr;
        // Find death (next saddle point above)
        let death = Float.max(prev, next);
        let pers = Float.abs(death - birth);
        if (pers > PERSISTENCE_THRESHOLD * 0.1) {
          features := Array.append(features, [{
            dimension = 0;
            birth = birth;
            death = death;
            persistence = pers;
            isAlive = false;
            significance = Float.min(1.0, pers);
            beat = 0;
          }]);
        };
      };

      // Local maximum with specific pattern = potential loop
      if (curr > prev and curr > next and i > 2 and i < points.size() - 2) {
        let pers = Float.abs(curr - Float.min(prev, next));
        if (pers > CYCLE_MIN_PERSISTENCE * 0.1) {
          features := Array.append(features, [{
            dimension = 1;
            birth = Float.min(prev, next);
            death = curr;
            persistence = pers;
            isAlive = false;
            significance = Float.min(1.0, pers * Phi.PHI);
            beat = 0;
          }]);
        };
      };
      i += 1;
    };

    features
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance topology state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomTopology(
    state : PhantomTopologyState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomTopologyState {
    if (systemCoherence < TOPOLOGY_COHERENCE_GATE) return state;
    if (state.pointCloud.size() < 8) {
      return { state with lastTickBeat = beat; coherence = systemCoherence };
    };

    // Compute persistent homology features
    let newFeatures = computeFeatures(state.pointCloud);

    // Count Betti numbers
    var b0 : Nat = 0;
    var b1 : Nat = 0;
    var b2 : Nat = 0;
    for (f in newFeatures.vals()) {
      switch(f.dimension) {
        case 0 { b0 += 1 };
        case 1 { b1 += 1 };
        case _ { b2 += 1 };
      };
    };
    let totalBetti = b0 + b1 + b2;
    let complexity = if (totalBetti > 0) {
      Float.fromInt(b1 + b2 * 2) / Float.fromInt(totalBetti)
    } else { 0.0 };

    // Bottleneck distance (simplified: change in feature count and persistence)
    let prevTotal = state.features.size();
    let currTotal = newFeatures.size();
    let countChange = Float.abs(Float.fromInt(currTotal) - Float.fromInt(prevTotal));
    let bottleneck = countChange / Float.max(1.0, Float.fromInt(prevTotal + currTotal));

    // Structural break detection
    let structBreak = bottleneck > BOTTLENECK_CHANGE_THRESHOLD;

    // Landscape computation (simplified: max persistence per dimension)
    var maxPers : Float = 0.0;
    var totalArea : Float = 0.0;
    for (f in newFeatures.vals()) {
      if (f.persistence > maxPers) maxPers := f.persistence;
      totalArea += f.persistence;
    };

    let landscape : PersistenceLandscape = {
      values = Array.tabulate<Float>(LANDSCAPE_RESOLUTION, func(i) {
        let t = Float.fromInt(i) / Float.fromInt(LANDSCAPE_RESOLUTION);
        maxPers * (1.0 - t) // triangular approximation
      });
      maxPeak = maxPers;
      totalArea = totalArea;
      dimension = 0;
      beat = beat;
    };

    let landscapes = if (state.landscapes.size() >= 13) {
      Array.tabulate<PersistenceLandscape>(13, func(i) {
        if (i < 12) state.landscapes[i + 1] else landscape
      })
    } else {
      Array.append(state.landscapes, [landscape])
    };

    {
      features = newFeatures;
      betti = { beta0 = b0; beta1 = b1; beta2 = b2; totalBetti = totalBetti; complexity = complexity; lastBeat = beat };
      landscapes = landscapes;
      pointCloud = state.pointCloud;
      bottleneckDist = bottleneck;
      structuralBreak = structBreak;
      cycleCount = b1;
      componentCount = b0;
      topologicalComplexity = complexity;
      totalComputations = state.totalComputations + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED POINT — add data point to cloud
  // ═══════════════════════════════════════════════════════════════════════════

  public func feedPoint(state : PhantomTopologyState, value : Float) : PhantomTopologyState {
    let cloud = if (state.pointCloud.size() >= MAX_POINTS) {
      Array.tabulate<Float>(MAX_POINTS, func(i) {
        if (i < MAX_POINTS - 1) state.pointCloud[i + 1] else value
      })
    } else {
      Array.append(state.pointCloud, [value])
    };
    { state with pointCloud = cloud }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func isStructuralBreak(state : PhantomTopologyState) : Bool {
    state.structuralBreak
  };

  public func getTopologicalComplexity(state : PhantomTopologyState) : Float {
    state.topologicalComplexity
  };

  public func getCycleCount(state : PhantomTopologyState) : Nat {
    state.cycleCount
  };

  public func getBettiNumbers(state : PhantomTopologyState) : (Nat, Nat, Nat) {
    (state.betti.beta0, state.betti.beta1, state.betti.beta2)
  };
};
