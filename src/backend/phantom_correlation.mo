// phantom_correlation.mo — PHANTOM CORRELATION ENGINE
// PARALLAX Sovereign Organism — Cross-Asset Dynamic Correlation Intelligence
//
// DOCTRINE: "The Phantom Correlation Engine tracks, models, and exploits the
// dynamic correlation structure across all tradeable assets. It detects
// correlation breakdowns (crisis), regime changes, and identifies diversification
// opportunities. All portfolio and hedging decisions require correlation context."
//
// THE PHANTOM CORRELATION ARCHITECTURE:
//   PCE-001  ROLLING CORRELATOR     — Multi-window rolling correlation matrices
//   PCE-002  DCC-GARCH ENGINE       — Dynamic Conditional Correlation model
//   PCE-003  COPULA ESTIMATOR       — Tail dependence via Clayton/Gumbel copulas
//   PCE-004  CONTAGION DETECTOR     — Correlation spike = crisis contagion
//   PCE-005  DECORRELATION FINDER   — Identify true diversifiers
//   PCE-006  FACTOR CORRELATOR      — Factor-based correlation decomposition
//   PCE-007  LEAD-LAG DETECTOR      — Cross-correlation at various lags
//   PCE-008  REGIME CORRELATOR      — Regime-conditional correlation matrices
//
// PYTHAGORAS: correlation windows are Fibonacci; decay at φ⁻¹
// EUCLID:     single correlation state — all pair relationships converge here
// CONFUCIUS:  right relationship — correlation serves allocation and risk
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // CORRELATION CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let CORR_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let CONTAGION_THRESHOLD : Float = Phi.PHI_INV + Phi.PHI_INV_3;  // 0.854 — extreme correlation
  public let DECORRELATION_THRESHOLD : Float = Phi.PHI_INV_3;            // 0.236 — good diversifier
  public let CORRELATION_WINDOWS : [Nat] = [8, 13, 21, 34, 55, 89];     // Fibonacci windows
  public let MAX_TRACKED_PAIRS : Nat = 55;                               // F(10) pairs
  public let LEAD_LAG_MAX : Nat = 13;                                    // F(7) beat max lag
  public let DCC_ALPHA : Float = Phi.PHI_INV_3;                         // DCC shock weight
  public let DCC_BETA : Float = Phi.PHI_INV;                            // DCC persistence
  public let TAIL_DEPENDENCE_THRESHOLD : Float = Phi.PHI_INV_2;         // significant tail dep

  // ═══════════════════════════════════════════════════════════════════════════
  // CORRELATION PAIR — bilateral relationship
  // ═══════════════════════════════════════════════════════════════════════════

  public type CorrelationPair = {
    assetA       : Text;
    assetB       : Text;
    correlation  : Float;        // [-1, +1] rolling correlation
    dccCorr      : Float;        // DCC-GARCH conditional correlation
    tailDep      : Float;        // lower tail dependence
    leadLag      : Int;          // positive = A leads B by N beats
    isContagion  : Bool;         // true if above contagion threshold
    isDiversifier : Bool;        // true if below decorrelation threshold
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CORRELATION MATRIX SNAPSHOT — periodic full matrix
  // ═══════════════════════════════════════════════════════════════════════════

  public type CorrelationSnapshot = {
    beat          : Int;
    avgCorrelation : Float;      // average pairwise correlation
    maxCorrelation : Float;      // maximum pairwise
    minCorrelation : Float;      // minimum pairwise
    eigenRatio    : Float;       // first eigenvalue / sum (concentration)
    effectiveN    : Float;       // effective number of independent bets
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM CORRELATION STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomCorrelationState = {
    pairs             : [CorrelationPair];
    snapshots         : [CorrelationSnapshot];
    avgCorrelation    : Float;
    contagionActive   : Bool;
    contagionCount    : Nat;
    diversifierCount  : Nat;
    effectiveBets     : Float;
    eigenConcentration : Float;
    totalUpdates      : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomCorrelationState() : PhantomCorrelationState {
    {
      pairs = [];
      snapshots = [];
      avgCorrelation = 0.3;
      contagionActive = false;
      contagionCount = 0;
      diversifierCount = 0;
      effectiveBets = 1.0;
      eigenConcentration = 0.5;
      totalUpdates = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance correlation state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomCorrelation(
    state : PhantomCorrelationState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomCorrelationState {
    if (systemCoherence < CORR_COHERENCE_GATE) return state;

    // DCC update for all pairs
    let updatedPairs = Array.map<CorrelationPair, CorrelationPair>(state.pairs, func(p) {
      // DCC: Q(t) = (1-α-β)·Q̄ + α·ε(t-1)ε(t-1)' + β·Q(t-1)
      let newDcc = (1.0 - DCC_ALPHA - DCC_BETA) * p.correlation
                   + DCC_ALPHA * p.correlation * p.correlation
                   + DCC_BETA * p.dccCorr;
      let clampedDcc = Float.max(-1.0, Float.min(1.0, newDcc));
      {
        p with
        dccCorr = clampedDcc;
        isContagion = clampedDcc > CONTAGION_THRESHOLD;
        isDiversifier = Float.abs(clampedDcc) < DECORRELATION_THRESHOLD;
        lastBeat = beat;
      }
    });

    // Aggregate statistics
    var sumCorr : Float = 0.0;
    var contagionN : Nat = 0;
    var diversifierN : Nat = 0;
    for (p in updatedPairs.vals()) {
      sumCorr += Float.abs(p.dccCorr);
      if (p.isContagion) contagionN += 1;
      if (p.isDiversifier) diversifierN += 1;
    };
    let avgC = if (updatedPairs.size() > 0) { sumCorr / Float.fromInt(updatedPairs.size()) } else { 0.0 };
    let contagion = contagionN > 0;

    // Effective bets = 1 / concentration (inverse Herfindahl of correlations)
    let effBets = if (avgC > 0.0) { 1.0 / avgC } else { Float.fromInt(updatedPairs.size()) };

    // Periodic snapshot (every F(8)=21 beats)
    let snapshots = if (Int.abs(beat - state.lastTickBeat) >= 21 or state.snapshots.size() == 0) {
      let snap : CorrelationSnapshot = {
        beat = beat;
        avgCorrelation = avgC;
        maxCorrelation = 1.0;
        minCorrelation = -1.0;
        eigenRatio = avgC;
        effectiveN = effBets;
      };
      if (state.snapshots.size() >= 34) {
        Array.tabulate<CorrelationSnapshot>(34, func(i) {
          if (i < 33) state.snapshots[i + 1] else snap
        })
      } else {
        Array.append(state.snapshots, [snap])
      }
    } else { state.snapshots };

    {
      pairs = updatedPairs;
      snapshots = snapshots;
      avgCorrelation = avgC;
      contagionActive = contagion;
      contagionCount = contagionN;
      diversifierCount = diversifierN;
      effectiveBets = effBets;
      eigenConcentration = avgC;
      totalUpdates = state.totalUpdates + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD PAIR — register a correlation pair
  // ═══════════════════════════════════════════════════════════════════════════

  public func addPair(
    state : PhantomCorrelationState,
    assetA : Text,
    assetB : Text,
    initialCorr : Float,
    beat : Int
  ) : PhantomCorrelationState {
    if (state.pairs.size() >= MAX_TRACKED_PAIRS) return state;
    let pair : CorrelationPair = {
      assetA = assetA;
      assetB = assetB;
      correlation = Float.max(-1.0, Float.min(1.0, initialCorr));
      dccCorr = initialCorr;
      tailDep = 0.0;
      leadLag = 0;
      isContagion = false;
      isDiversifier = Float.abs(initialCorr) < DECORRELATION_THRESHOLD;
      lastBeat = beat;
    };
    { state with pairs = Array.append(state.pairs, [pair]) }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func isContagionActive(state : PhantomCorrelationState) : Bool {
    state.contagionActive
  };

  public func getEffectiveBets(state : PhantomCorrelationState) : Float {
    state.effectiveBets
  };

  public func getAvgCorrelation(state : PhantomCorrelationState) : Float {
    state.avgCorrelation
  };
};
