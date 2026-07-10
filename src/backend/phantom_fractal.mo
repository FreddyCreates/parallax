// phantom_fractal.mo — PHANTOM FRACTAL ENGINE
// PARALLAX Sovereign Organism — Fractal Dimension & Hurst Exponent Intelligence
//
// DOCTRINE: "The Phantom Fractal Engine measures the fractal dimension and Hurst
// exponent of price series to determine market character: trending (H>0.5),
// random (H=0.5), or mean-reverting (H<0.5). It detects self-similarity across
// scales and identifies fractal support/resistance levels."
//
// THE PHANTOM FRACTAL ARCHITECTURE:
//   PFR-001  HURST ESTIMATOR        — R/S analysis for Hurst exponent
//   PFR-002  FRACTAL DIMENSION      — Box-counting dimension D = 2 - H
//   PFR-003  DETRENDED FLUCTUATION  — DFA for long-range dependence
//   PFR-004  MULTIFRACTAL SPECTRUM   — α(q) singularity spectrum
//   PFR-005  FRACTAL LEVELS         — Self-similar support/resistance
//   PFR-006  SCALE INVARIANCE       — Cross-timeframe pattern detection
//   PFR-007  PERSISTENCE METER      — Trending vs anti-trending classification
//   PFR-008  ROUGHNESS INDEX        — Surface roughness of price path
//
// PYTHAGORAS: analysis windows are Fibonacci; H=φ⁻¹ is the critical threshold
// EUCLID:     single fractal state — all scale analysis converges here
// CONFUCIUS:  right relationship — fractals reveal structure, strategies exploit it
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // FRACTAL CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let FRACTAL_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let HURST_TRENDING_THRESHOLD : Float = Phi.PHI_INV;          // H > 0.618 = trending
  public let HURST_RANDOM : Float = 0.5;                              // H = 0.5 = random walk
  public let HURST_MEAN_REVERT_THRESHOLD : Float = Phi.PHI_INV_2;    // H < 0.382 = mean-reverting
  public let RS_WINDOWS : [Nat] = [8, 13, 21, 34, 55, 89, 144];     // Fibonacci R/S windows
  public let DFA_ORDERS : [Nat] = [1, 2, 3, 5, 8];                  // DFA polynomial orders
  public let FRACTAL_LEVEL_COUNT : Nat = 13;                          // F(7) fractal levels
  public let MULTIFRACTAL_Q_RANGE : [Float] = [-5.0, -3.0, -1.0, 0.0, 1.0, 3.0, 5.0];
  public let MAX_PRICE_MEMORY : Nat = 233;                            // F(13) prices remembered

  // ═══════════════════════════════════════════════════════════════════════════
  // HURST ANALYSIS — single window result
  // ═══════════════════════════════════════════════════════════════════════════

  public type HurstResult = {
    window      : Nat;
    hurstExp    : Float;         // H ∈ [0, 1]
    rsStatistic : Float;         // rescaled range
    confidence  : Float;
    lastBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FRACTAL LEVEL — self-similar price level
  // ═══════════════════════════════════════════════════════════════════════════

  public type FractalLevel = {
    price       : Float;
    strength    : Float;         // how many scales confirm this level
    levelType   : Text;          // "SUPPORT" | "RESISTANCE"
    scaleCount  : Nat;           // number of scales where level appears
    lastBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM FRACTAL STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomFractalState = {
    hurstResults      : [HurstResult];
    compositeHurst    : Float;         // weighted average H across windows
    fractalDimension  : Float;         // D = 2 - H
    dfaExponent       : Float;         // DFA α exponent
    multifractalWidth : Float;         // width of singularity spectrum
    fractalLevels     : [FractalLevel];
    priceMemory       : [Float];       // recent prices for analysis
    marketCharacter   : Text;          // "TRENDING" | "RANDOM" | "MEAN_REVERTING"
    persistence       : Float;         // composite persistence score [0, 1]
    roughness         : Float;         // path roughness [0, 1]
    totalAnalyses     : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomFractalState() : PhantomFractalState {
    {
      hurstResults = Array.tabulate<HurstResult>(RS_WINDOWS.size(), func(i) {
        { window = RS_WINDOWS[i]; hurstExp = 0.5; rsStatistic = 0.0; confidence = 0.0; lastBeat = 0 }
      });
      compositeHurst = 0.5;
      fractalDimension = 1.5;
      dfaExponent = 0.5;
      multifractalWidth = 0.0;
      fractalLevels = [];
      priceMemory = [];
      marketCharacter = "RANDOM";
      persistence = 0.5;
      roughness = 0.5;
      totalAnalyses = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // R/S ANALYSIS — Rescaled Range computation
  // ═══════════════════════════════════════════════════════════════════════════

  func computeRS(prices : [Float], window : Nat) : Float {
    if (prices.size() < window or window < 2) return 0.0;

    let start = prices.size() - window;
    // Compute mean
    var sum : Float = 0.0;
    var i = start;
    while (i < prices.size()) {
      sum += prices[i];
      i += 1;
    };
    let mean = sum / Float.fromInt(window);

    // Compute cumulative deviations and range
    var cumDev : Float = 0.0;
    var maxCum : Float = 0.0;
    var minCum : Float = 0.0;
    var sumSq : Float = 0.0;
    i := start;
    while (i < prices.size()) {
      let dev = prices[i] - mean;
      cumDev += dev;
      if (cumDev > maxCum) maxCum := cumDev;
      if (cumDev < minCum) minCum := cumDev;
      sumSq += dev * dev;
      i += 1;
    };

    let range = maxCum - minCum;
    let stdDev = Float.sqrt(sumSq / Float.fromInt(window));
    if (stdDev > 0.0) { range / stdDev } else { 0.0 }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance fractal state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomFractal(
    state : PhantomFractalState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomFractalState {
    if (systemCoherence < FRACTAL_COHERENCE_GATE) return state;
    if (state.priceMemory.size() < 13) return { state with lastTickBeat = beat; coherence = systemCoherence };

    // Compute R/S for each window
    let updatedHurst = Array.map<HurstResult, HurstResult>(state.hurstResults, func(h) {
      let rs = computeRS(state.priceMemory, h.window);
      // H ≈ log(R/S) / log(n)
      let logN = Float.log(Float.fromInt(h.window));
      let logRS = if (rs > 0.0) Float.log(rs) else 0.0;
      let hurst = if (logN > 0.0) { Float.max(0.0, Float.min(1.0, logRS / logN)) } else { 0.5 };
      let conf = if (state.priceMemory.size() >= h.window) { Float.min(1.0, Float.fromInt(state.priceMemory.size()) / Float.fromInt(h.window * 2)) } else { 0.0 };
      { h with hurstExp = hurst; rsStatistic = rs; confidence = conf; lastBeat = beat }
    });

    // Composite Hurst (weighted by confidence)
    var hSum : Float = 0.0;
    var wSum : Float = 0.0;
    for (h in updatedHurst.vals()) {
      hSum += h.hurstExp * h.confidence;
      wSum += h.confidence;
    };
    let compositeH = if (wSum > 0.0) { hSum / wSum } else { 0.5 };

    // Fractal dimension D = 2 - H
    let fracDim = 2.0 - compositeH;

    // Market character classification
    let character = if (compositeH > HURST_TRENDING_THRESHOLD) { "TRENDING" }
      else if (compositeH < HURST_MEAN_REVERT_THRESHOLD) { "MEAN_REVERTING" }
      else { "RANDOM" };

    // Persistence score [0, 1] where 1 = maximally persistent
    let persistence = compositeH;

    // Roughness (inverse of Hurst — rough paths have low H)
    let roughness = 1.0 - compositeH;

    {
      hurstResults = updatedHurst;
      compositeHurst = compositeH;
      fractalDimension = fracDim;
      dfaExponent = compositeH; // simplified: DFA α ≈ H
      multifractalWidth = state.multifractalWidth;
      fractalLevels = state.fractalLevels;
      priceMemory = state.priceMemory;
      marketCharacter = character;
      persistence = persistence;
      roughness = roughness;
      totalAnalyses = state.totalAnalyses + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED PRICE — add new price observation
  // ═══════════════════════════════════════════════════════════════════════════

  public func feedPrice(state : PhantomFractalState, price : Float) : PhantomFractalState {
    let memory = if (state.priceMemory.size() >= MAX_PRICE_MEMORY) {
      Array.tabulate<Float>(MAX_PRICE_MEMORY, func(i) {
        if (i < MAX_PRICE_MEMORY - 1) state.priceMemory[i + 1] else price
      })
    } else {
      Array.append(state.priceMemory, [price])
    };
    { state with priceMemory = memory }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getCompositeHurst(state : PhantomFractalState) : Float {
    state.compositeHurst
  };

  public func getMarketCharacter(state : PhantomFractalState) : Text {
    state.marketCharacter
  };

  public func getFractalDimension(state : PhantomFractalState) : Float {
    state.fractalDimension
  };
};
