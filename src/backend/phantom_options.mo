// phantom_options.mo — PHANTOM OPTIONS ENGINE
// PARALLAX Sovereign Organism — Options Pricing & Greeks Intelligence
//
// DOCTRINE: "The Phantom Options Engine computes fair value, Greeks, and
// optimal strategies for options across all asset classes. It uses Black-Scholes,
// Binomial Trees, and Monte Carlo for exotic payoffs — all phi-calibrated."
//
// THE PHANTOM OPTIONS ARCHITECTURE:
//   POE-001  BLACK-SCHOLES PRICER   — Closed-form European option pricing
//   POE-002  BINOMIAL TREE ENGINE   — CRR tree for American options
//   POE-003  GREEKS CALCULATOR      — Delta, Gamma, Theta, Vega, Rho, Charm, Vanna
//   POE-004  IMPLIED VOL SOLVER     — Newton-Raphson IV extraction
//   POE-005  STRATEGY BUILDER       — Multi-leg option strategy construction
//   POE-006  PAYOFF SIMULATOR       — Forward P&L surface at expiry
//   POE-007  EARLY EXERCISE MONITOR — American exercise boundary detection
//   POE-008  VOL SMILE CALIBRATOR   — Smile/skew fitting for pricing
//
// PYTHAGORAS: tree steps are Fibonacci; risk-neutral probabilities phi-weighted
// EUCLID:     single options state — all derivatives pricing converges here
// CONFUCIUS:  right relationship — options serve hedging and income, not reckless leverage
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let OPTIONS_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let TREE_STEPS : Nat = 89;                                  // F(11) binomial steps
  public let IV_NEWTON_MAX_ITER : Nat = 21;                          // F(8) iterations
  public let IV_TOLERANCE : Float = 0.0001;                          // convergence threshold
  public let RISK_FREE_RATE : Float = 0.05;                          // 5% default
  public let MIN_VOL : Float = 0.01;                                 // 1% floor
  public let MAX_VOL : Float = 5.0;                                  // 500% cap
  public let PHI_TREE_PROB : Float = Phi.PHI_INV;                    // up probability bias
  public let MAX_STRATEGIES : Nat = 13;                              // F(7) active strategies
  public let GREEKS_UPDATE_INTERVAL : Nat = 5;                       // F(5) beats

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTION CONTRACT — single option definition
  // ═══════════════════════════════════════════════════════════════════════════

  public type OptionType = { #call; #put };
  public type ExerciseStyle = { #european; #american };

  public type OptionContract = {
    id           : Text;
    underlying   : Text;
    optionType   : OptionType;
    exercise     : ExerciseStyle;
    strike       : Float;
    expiry       : Nat;          // beats to expiry
    spotPrice    : Float;
    vol          : Float;        // implied volatility
    riskFreeRate : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GREEKS — option sensitivities
  // ═══════════════════════════════════════════════════════════════════════════

  public type Greeks = {
    delta    : Float;            // ∂V/∂S
    gamma    : Float;            // ∂²V/∂S²
    theta    : Float;            // ∂V/∂t (per beat)
    vega     : Float;            // ∂V/∂σ
    rho      : Float;            // ∂V/∂r
    charm    : Float;            // ∂δ/∂t (delta decay)
    vanna    : Float;            // ∂δ/∂σ (delta-vol cross)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICED OPTION — option with computed fair value
  // ═══════════════════════════════════════════════════════════════════════════

  public type PricedOption = {
    contract   : OptionContract;
    fairValue  : Float;
    greeks     : Greeks;
    ivSolved   : Float;          // solved implied vol (if market price given)
    moneyness  : Float;          // S/K
    timeValue  : Float;          // fair value - intrinsic
    intrinsic  : Float;          // max(0, S-K) for call, max(0, K-S) for put
    lastBeat   : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STRATEGY — multi-leg position
  // ═══════════════════════════════════════════════════════════════════════════

  public type StrategyLeg = {
    option    : OptionContract;
    quantity  : Int;             // positive = long, negative = short
    premium   : Float;
  };

  public type OptionStrategy = {
    id        : Text;
    name      : Text;           // "IRON_CONDOR" | "STRADDLE" | "BUTTERFLY" | etc.
    legs      : [StrategyLeg];
    maxProfit : Float;
    maxLoss   : Float;
    breakeven : [Float];
    netDelta  : Float;
    netTheta  : Float;
    lastBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM OPTIONS STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomOptionsState = {
    pricedOptions     : [PricedOption];
    strategies        : [OptionStrategy];
    totalContracts    : Nat;
    totalStrategies   : Nat;
    avgImpliedVol     : Float;
    putCallRatio      : Float;
    portfolioDelta    : Float;
    portfolioGamma    : Float;
    portfolioTheta    : Float;
    portfolioVega     : Float;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomOptionsState() : PhantomOptionsState {
    {
      pricedOptions = [];
      strategies = [];
      totalContracts = 0;
      totalStrategies = 0;
      avgImpliedVol = 0.5;
      putCallRatio = 1.0;
      portfolioDelta = 0.0;
      portfolioGamma = 0.0;
      portfolioTheta = 0.0;
      portfolioVega = 0.0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BLACK-SCHOLES PRICING — closed form
  // ═══════════════════════════════════════════════════════════════════════════

  // Standard normal CDF approximation (Abramowitz & Stegun)
  func normCdf(x : Float) : Float {
    let t = 1.0 / (1.0 + 0.2316419 * Float.abs(x));
    let d = 0.3989422804014327; // 1/√(2π)
    let poly = t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
    let cdf = 1.0 - d * Float.exp(-0.5 * x * x) * poly;
    if (x >= 0.0) cdf else 1.0 - cdf
  };

  public func blackScholes(
    spot : Float,
    strike : Float,
    vol : Float,
    t : Float,       // time to expiry in years
    r : Float,       // risk-free rate
    isCall : Bool
  ) : Float {
    if (t <= 0.0) {
      // At expiry
      return if (isCall) Float.max(0.0, spot - strike) else Float.max(0.0, strike - spot);
    };
    let sqrtT = Float.sqrt(t);
    let d1 = (Float.log(spot / strike) + (r + 0.5 * vol * vol) * t) / (vol * sqrtT);
    let d2 = d1 - vol * sqrtT;

    if (isCall) {
      spot * normCdf(d1) - strike * Float.exp(-r * t) * normCdf(d2)
    } else {
      strike * Float.exp(-r * t) * normCdf(-d2) - spot * normCdf(-d1)
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GREEKS COMPUTATION
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeGreeks(
    spot : Float,
    strike : Float,
    vol : Float,
    t : Float,
    r : Float,
    isCall : Bool
  ) : Greeks {
    if (t <= 0.0 or vol <= 0.0) {
      return { delta = 0.0; gamma = 0.0; theta = 0.0; vega = 0.0; rho = 0.0; charm = 0.0; vanna = 0.0 };
    };
    let sqrtT = Float.sqrt(t);
    let d1 = (Float.log(spot / strike) + (r + 0.5 * vol * vol) * t) / (vol * sqrtT);
    let d2 = d1 - vol * sqrtT;
    let nd1 = 0.3989422804014327 * Float.exp(-0.5 * d1 * d1); // standard normal PDF

    let delta_ = if (isCall) normCdf(d1) else normCdf(d1) - 1.0;
    let gamma_ = nd1 / (spot * vol * sqrtT);
    let vega_ = spot * nd1 * sqrtT * 0.01; // per 1% vol move
    let theta_ = -(spot * nd1 * vol) / (2.0 * sqrtT) - r * strike * Float.exp(-r * t) *
      (if (isCall) normCdf(d2) else normCdf(-d2));
    let rho_ = strike * t * Float.exp(-r * t) *
      (if (isCall) normCdf(d2) else -normCdf(-d2)) * 0.01;

    {
      delta = delta_;
      gamma = gamma_;
      theta = theta_ / 365.0;  // daily theta
      vega = vega_;
      rho = rho_;
      charm = -nd1 * (2.0 * r * t - d2 * vol * sqrtT) / (2.0 * t * vol * sqrtT);
      vanna = nd1 * d2 / vol;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance options state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomOptions(
    state : PhantomOptionsState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomOptionsState {
    if (systemCoherence < OPTIONS_COHERENCE_GATE) return state;

    // Update Greeks for all priced options (time decay)
    let updated = Array.map<PricedOption, PricedOption>(state.pricedOptions, func(p) {
      let c = p.contract;
      let newExpiry = if (c.expiry > 0) { c.expiry - 1 } else { 0 };
      let t = Float.fromInt(newExpiry) / (365.0 * 24.0); // crude time conversion
      let isCall = switch(c.optionType) { case (#call) true; case (#put) false };
      let newFv = blackScholes(c.spotPrice, c.strike, c.vol, t, c.riskFreeRate, isCall);
      let newGreeks = computeGreeks(c.spotPrice, c.strike, c.vol, t, c.riskFreeRate, isCall);
      let intrinsic = if (isCall) Float.max(0.0, c.spotPrice - c.strike) else Float.max(0.0, c.strike - c.spotPrice);
      {
        p with
        contract = { c with expiry = newExpiry };
        fairValue = newFv;
        greeks = newGreeks;
        timeValue = newFv - intrinsic;
        intrinsic = intrinsic;
        moneyness = c.spotPrice / c.strike;
        lastBeat = beat;
      }
    });

    // Aggregate portfolio Greeks
    var pDelta : Float = 0.0;
    var pGamma : Float = 0.0;
    var pTheta : Float = 0.0;
    var pVega : Float = 0.0;
    var sumIv : Float = 0.0;
    var callCount : Nat = 0;
    var putCount : Nat = 0;
    for (p in updated.vals()) {
      pDelta += p.greeks.delta;
      pGamma += p.greeks.gamma;
      pTheta += p.greeks.theta;
      pVega += p.greeks.vega;
      sumIv += p.ivSolved;
      switch(p.contract.optionType) {
        case (#call) { callCount += 1 };
        case (#put) { putCount += 1 };
      };
    };
    let avgIv = if (updated.size() > 0) { sumIv / Float.fromInt(updated.size()) } else { 0.5 };
    let pcRatio = if (callCount > 0) { Float.fromInt(putCount) / Float.fromInt(callCount) } else { 1.0 };

    {
      state with
      pricedOptions = updated;
      avgImpliedVol = avgIv;
      putCallRatio = pcRatio;
      portfolioDelta = pDelta;
      portfolioGamma = pGamma;
      portfolioTheta = pTheta;
      portfolioVega = pVega;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getPortfolioDelta(state : PhantomOptionsState) : Float {
    state.portfolioDelta
  };

  public func getPutCallRatio(state : PhantomOptionsState) : Float {
    state.putCallRatio
  };

  public func getAvgIV(state : PhantomOptionsState) : Float {
    state.avgImpliedVol
  };
};
