// phantom_funding.mo — PHANTOM FUNDING ENGINE
// PARALLAX Sovereign Organism — Funding Rate Arbitrage & Yield Intelligence
//
// DOCTRINE: "The Phantom Funding Engine captures persistent yield from funding
// rate differentials across perpetual swap venues. It identifies carry trades,
// basis spreads, and yield optimization opportunities using phi-harmonic timing."
//
// THE PHANTOM FUNDING ARCHITECTURE:
//   PFE-001  FUNDING RATE MONITOR   — Real-time funding rate across venues
//   PFE-002  BASIS TRADE ENGINE     — Spot-futures basis arbitrage
//   PFE-003  CARRY OPTIMIZER        — Multi-venue carry portfolio construction
//   PFE-004  YIELD CURVE BUILDER    — Crypto-native yield term structure
//   PFE-005  RATE FORECASTER        — Funding rate prediction (phi-AR model)
//   PFE-006  DIVERGENCE DETECTOR    — Cross-venue funding rate divergence
//   PFE-007  POSITION ROLLER        — Optimal roll timing for expiring contracts
//   PFE-008  NET YIELD CALCULATOR   — After-cost yield computation
//
// PYTHAGORAS: funding intervals, carry thresholds are Fibonacci-derived
// EUCLID:     single funding state — all yield data converges here
// CONFUCIUS:  right relationship — funding captures, never chases
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNDING CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let FUNDING_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MIN_CARRY_THRESHOLD : Float = Phi.PHI_INV_3 * 0.01;     // 0.236% min annual carry
  public let BASIS_SIGNAL_THRESHOLD : Float = Phi.PHI_INV_2 * 0.01;  // 0.382% basis
  public let FUNDING_INTERVAL_BEATS : Nat = 8;                       // F(6) = 8h equivalent
  public let MAX_VENUES : Nat = 13;                                  // F(7) venues tracked
  public let RATE_FORECAST_WINDOW : Nat = 21;                        // F(8) observations
  public let ROLL_ADVANCE_BEATS : Nat = 34;                          // F(9) beats before expiry
  public let MAX_CARRY_POSITIONS : Nat = 8;                          // F(6) simultaneous carries
  public let DIVERGENCE_THRESHOLD : Float = Phi.PHI_INV_3;           // significant divergence

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNDING RATE — single venue observation
  // ═══════════════════════════════════════════════════════════════════════════

  public type FundingRate = {
    venue        : Text;         // "BINANCE" | "DERIBIT" | "BYBIT" | etc.
    asset        : Text;         // "BTC" | "ETH" | etc.
    rate         : Float;        // current funding rate (8h)
    annualized   : Float;        // annualized rate
    nextPayment  : Int;          // beat of next funding payment
    trend        : Float;        // EMA direction of rate
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIS TRADE — spot-futures spread opportunity
  // ═══════════════════════════════════════════════════════════════════════════

  public type BasisTrade = {
    asset        : Text;
    spotPrice    : Float;
    futuresPrice : Float;
    basis        : Float;         // (futures - spot) / spot
    annualizedBasis : Float;
    daysToExpiry : Nat;
    isSignal     : Bool;          // above threshold
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CARRY POSITION — active yield position
  // ═══════════════════════════════════════════════════════════════════════════

  public type CarryPosition = {
    id           : Text;
    venue        : Text;
    asset        : Text;
    direction    : Text;          // "LONG_SPOT_SHORT_PERP" | "SHORT_SPOT_LONG_PERP"
    notional     : Float;
    entryRate    : Float;
    currentRate  : Float;
    pnl          : Float;
    entryBeat    : Int;
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM FUNDING STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomFundingState = {
    fundingRates      : [FundingRate];
    basisTrades       : [BasisTrade];
    carryPositions    : [CarryPosition];
    aggregateYield    : Float;         // portfolio-level annualized yield
    totalYieldEarned  : Float;         // cumulative yield captured
    activeBasis       : Nat;           // number of active basis signals
    maxDivergence     : Float;         // largest cross-venue divergence
    forecastRate      : Float;         // 1-step ahead rate forecast
    totalPayments     : Nat;           // funding payments captured
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomFundingState() : PhantomFundingState {
    {
      fundingRates = [];
      basisTrades = [];
      carryPositions = [];
      aggregateYield = 0.0;
      totalYieldEarned = 0.0;
      activeBasis = 0;
      maxDivergence = 0.0;
      forecastRate = 0.0;
      totalPayments = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance funding state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomFunding(
    state : PhantomFundingState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomFundingState {
    if (systemCoherence < FUNDING_COHERENCE_GATE) return state;

    // Update rate trends (EMA decay)
    let updatedRates = Array.map<FundingRate, FundingRate>(state.fundingRates, func(r) {
      let newTrend = r.trend * Phi.PHI_INV + r.rate * Phi.PHI_INV_2;
      { r with trend = newTrend; lastBeat = beat }
    });

    // Find max divergence across venues
    var maxDiv : Float = 0.0;
    if (updatedRates.size() >= 2) {
      var i = 0;
      while (i < updatedRates.size()) {
        var j = i + 1;
        while (j < updatedRates.size()) {
          let div = Float.abs(updatedRates[i].rate - updatedRates[j].rate);
          if (div > maxDiv) maxDiv := div;
          j += 1;
        };
        i += 1;
      };
    };

    // Forecast: simple phi-weighted EMA of rates
    var sumRate : Float = 0.0;
    for (r in updatedRates.vals()) { sumRate += r.rate };
    let avgRate = if (updatedRates.size() > 0) { sumRate / Float.fromInt(updatedRates.size()) } else { 0.0 };
    let forecast = state.forecastRate * Phi.PHI_INV + avgRate * Phi.PHI_INV_2;

    // Count active basis signals
    var basisCount : Nat = 0;
    for (b in state.basisTrades.vals()) {
      if (b.isSignal) basisCount += 1;
    };

    // Update carry positions PnL (funding accrual per beat)
    let updatedCarry = Array.map<CarryPosition, CarryPosition>(state.carryPositions, func(c) {
      let accrual = c.currentRate * c.notional / Float.fromInt(FUNDING_INTERVAL_BEATS);
      { c with pnl = c.pnl + accrual; lastBeat = beat }
    });

    // Aggregate yield
    var totalPnl : Float = 0.0;
    var totalNotional : Float = 0.0;
    for (c in updatedCarry.vals()) {
      totalPnl += c.pnl;
      totalNotional += c.notional;
    };
    let aggYield = if (totalNotional > 0.0) { totalPnl / totalNotional * 365.0 * 3.0 } else { 0.0 };

    {
      fundingRates = updatedRates;
      basisTrades = state.basisTrades;
      carryPositions = updatedCarry;
      aggregateYield = aggYield;
      totalYieldEarned = state.totalYieldEarned + totalPnl;
      activeBasis = basisCount;
      maxDivergence = maxDiv;
      forecastRate = forecast;
      totalPayments = state.totalPayments + (if (beat % FUNDING_INTERVAL_BEATS == 0) 1 else 0);
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getAggregateYield(state : PhantomFundingState) : Float {
    state.aggregateYield
  };

  public func getMaxDivergence(state : PhantomFundingState) : Float {
    state.maxDivergence
  };

  public func getTotalYieldEarned(state : PhantomFundingState) : Float {
    state.totalYieldEarned
  };
};
