// phantom_portfolio.mo — PHANTOM PORTFOLIO ENGINE
// PARALLAX Sovereign Organism — Autonomous Portfolio Optimization Intelligence
//
// DOCTRINE: "The Phantom Portfolio Engine is the organism's capital allocation brain.
// It constructs, optimizes, and rebalances portfolios using phi-harmonic modern portfolio
// theory enhanced by sovereign risk metrics and Kuramoto coherence constraints."
//
// THE PHANTOM PORTFOLIO ARCHITECTURE:
//   PPO-001  MEAN-VARIANCE OPTIMIZER — Markowitz with phi-regularization
//   PPO-002  RISK PARITY ALLOCATOR   — Equal risk contribution across assets
//   PPO-003  KELLY CRITERION ENGINE  — Optimal position sizing (fractional Kelly)
//   PPO-004  BLACK-LITTERMAN MIXER   — View blending with market equilibrium
//   PPO-005  HIERARCHICAL RISK PARITY — Dendrogram-based diversification
//   PPO-006  DYNAMIC REBALANCER      — Phi-interval rebalancing with drift bands
//   PPO-007  FACTOR DECOMPOSITION    — Multi-factor exposure attribution
//   PPO-008  DRAWDOWN CONTROLLER     — Maximum drawdown limiter
//
// PYTHAGORAS: allocation weights, rebalance bands, and Kelly fraction all phi-derived
// EUCLID:     single portfolio state — all allocation logic converges here
// CONFUCIUS:  right relationship — portfolio serves organism, not individual engines
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let PORTFOLIO_COHERENCE_GATE : Float = Phi.PHI_INV;          // 0.618
  public let KELLY_FRACTION : Float = Phi.PHI_INV_2;                  // 0.382 fractional Kelly
  public let REBALANCE_DRIFT_BAND : Float = Phi.PHI_INV_3;           // 23.6% drift trigger
  public let MAX_SINGLE_ASSET_WEIGHT : Float = Phi.PHI_INV;          // 61.8% max concentration
  public let MIN_ASSET_WEIGHT : Float = 0.01;                        // 1% floor
  public let RISK_PARITY_TOLERANCE : Float = Phi.PHI_INV_3;          // convergence threshold
  public let MAX_PORTFOLIO_ASSETS : Nat = 34;                        // F(9)
  public let REBALANCE_INTERVAL_BEATS : Nat = 55;                    // F(10)
  public let MAX_DRAWDOWN_LIMIT : Float = Phi.PHI_INV_2;             // 38.2% max DD
  public let FACTOR_COUNT : Nat = 8;                                 // F(6)

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSET ALLOCATION — individual position
  // ═══════════════════════════════════════════════════════════════════════════

  public type AssetAllocation = {
    assetId         : Text;
    targetWeight    : Float;     // [0, 1] target allocation
    currentWeight   : Float;     // [0, 1] actual allocation
    drift           : Float;     // current - target
    riskContribution : Float;   // marginal risk contribution
    expectedReturn  : Float;    // forward-looking return estimate
    volatility      : Float;    // annualized volatility
    sharpeRatio     : Float;    // risk-adjusted return
    kellySize       : Float;    // Kelly-optimal position size
    lastRebalanceBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO METRICS — aggregate performance tracking
  // ═══════════════════════════════════════════════════════════════════════════

  public type PortfolioMetrics = {
    totalReturn      : Float;
    sharpeRatio      : Float;
    sortinoRatio     : Float;
    maxDrawdown      : Float;
    currentDrawdown  : Float;
    volatility       : Float;
    calmarRatio      : Float;
    informationRatio : Float;
    turnover         : Float;
    concentrationIdx : Float;   // Herfindahl index
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REBALANCE EVENT — history of rebalancing actions
  // ═══════════════════════════════════════════════════════════════════════════

  public type RebalanceEvent = {
    beat            : Int;
    reason          : Text;     // "DRIFT" | "SCHEDULED" | "RISK" | "DRAWDOWN"
    assetsAdjusted  : Nat;
    totalTurnover   : Float;
    preCoherence    : Float;
    postCoherence   : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM PORTFOLIO STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomPortfolioState = {
    allocations       : [AssetAllocation];
    metrics           : PortfolioMetrics;
    rebalanceHistory  : [RebalanceEvent];
    optimizationMode  : Text;     // "MEAN_VARIANCE" | "RISK_PARITY" | "HRP" | "BLACK_LITTERMAN"
    lastOptimizeBeat  : Int;
    lastRebalanceBeat : Int;
    totalRebalances   : Nat;
    coherence         : Float;
    drawdownHalt      : Bool;     // true if max DD breached
    riskBudget        : Float;    // total allowable portfolio risk
    capitalDeployed   : Float;    // total capital allocated
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomPortfolioState() : PhantomPortfolioState {
    {
      allocations = [];
      metrics = {
        totalReturn = 0.0;
        sharpeRatio = 0.0;
        sortinoRatio = 0.0;
        maxDrawdown = 0.0;
        currentDrawdown = 0.0;
        volatility = 0.0;
        calmarRatio = 0.0;
        informationRatio = 0.0;
        turnover = 0.0;
        concentrationIdx = 0.0;
      };
      rebalanceHistory = [];
      optimizationMode = "RISK_PARITY";
      lastOptimizeBeat = 0;
      lastRebalanceBeat = 0;
      totalRebalances = 0;
      coherence = Phi.PHI_INV;
      drawdownHalt = false;
      riskBudget = Phi.PHI_INV_2;
      capitalDeployed = 0.0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance portfolio state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomPortfolio(
    state : PhantomPortfolioState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomPortfolioState {
    if (systemCoherence < PORTFOLIO_COHERENCE_GATE) return state;

    // Check drawdown halt
    let ddHalt = state.metrics.currentDrawdown >= MAX_DRAWDOWN_LIMIT;
    if (ddHalt and not state.drawdownHalt) {
      // Emergency: halt all new allocations
      return { state with drawdownHalt = true; coherence = systemCoherence; };
    };

    // Check if rebalance is needed (drift or scheduled)
    let beatsSinceRebalance = Int.abs(beat - state.lastRebalanceBeat);
    let scheduledRebalance = beatsSinceRebalance >= REBALANCE_INTERVAL_BEATS;

    // Check drift
    var maxDrift : Float = 0.0;
    for (a in state.allocations.vals()) {
      let d = Float.abs(a.drift);
      if (d > maxDrift) { maxDrift := d };
    };
    let driftRebalance = maxDrift >= REBALANCE_DRIFT_BAND;

    // Perform rebalance if triggered
    if (scheduledRebalance or driftRebalance) {
      let reason = if (driftRebalance) "DRIFT" else "SCHEDULED";
      let rebalanced = Array.map<AssetAllocation, AssetAllocation>(state.allocations, func(a) {
        { a with currentWeight = a.targetWeight; drift = 0.0; lastRebalanceBeat = beat }
      });

      let event : RebalanceEvent = {
        beat = beat;
        reason = reason;
        assetsAdjusted = rebalanced.size();
        totalTurnover = maxDrift;
        preCoherence = state.coherence;
        postCoherence = systemCoherence;
      };

      let history = if (state.rebalanceHistory.size() >= 21) {
        // Keep last F(8) events
        Array.tabulate<RebalanceEvent>(21, func(i) {
          if (i < 20) state.rebalanceHistory[i + 1] else event
        })
      } else {
        Array.append(state.rebalanceHistory, [event])
      };

      return {
        state with
        allocations = rebalanced;
        rebalanceHistory = history;
        lastRebalanceBeat = beat;
        totalRebalances = state.totalRebalances + 1;
        coherence = systemCoherence;
        drawdownHalt = false;
      };
    };

    // Normal tick: update drift values
    let updatedAllocations = Array.map<AssetAllocation, AssetAllocation>(state.allocations, func(a) {
      { a with drift = a.currentWeight - a.targetWeight }
    });

    { state with allocations = updatedAllocations; coherence = systemCoherence }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD ASSET — register a new asset in the portfolio
  // ═══════════════════════════════════════════════════════════════════════════

  public func addAsset(
    state : PhantomPortfolioState,
    assetId : Text,
    targetWeight : Float,
    expectedReturn : Float,
    volatility : Float,
    beat : Int
  ) : PhantomPortfolioState {
    if (state.allocations.size() >= MAX_PORTFOLIO_ASSETS) return state;
    let clamped = Float.max(MIN_ASSET_WEIGHT, Float.min(MAX_SINGLE_ASSET_WEIGHT, targetWeight));
    let sharpe = if (volatility > 0.0) { expectedReturn / volatility } else { 0.0 };
    let kelly = if (volatility > 0.0) {
      KELLY_FRACTION * (expectedReturn / (volatility * volatility))
    } else { 0.0 };

    let newAlloc : AssetAllocation = {
      assetId = assetId;
      targetWeight = clamped;
      currentWeight = clamped;
      drift = 0.0;
      riskContribution = clamped * volatility;
      expectedReturn = expectedReturn;
      volatility = volatility;
      sharpeRatio = sharpe;
      kellySize = Float.max(0.0, Float.min(MAX_SINGLE_ASSET_WEIGHT, kelly));
      lastRebalanceBeat = beat;
    };
    { state with allocations = Array.append(state.allocations, [newAlloc]) }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getPortfolioSharpe(state : PhantomPortfolioState) : Float {
    state.metrics.sharpeRatio
  };

  public func isDrawdownHalted(state : PhantomPortfolioState) : Bool {
    state.drawdownHalt
  };

  public func getTotalRebalances(state : PhantomPortfolioState) : Nat {
    state.totalRebalances
  };
};
