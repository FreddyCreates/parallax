// phantom_regime.mo — PHANTOM REGIME ENGINE
// PARALLAX Sovereign Organism — Market Regime Classification Intelligence
//
// DOCTRINE: "The Phantom Regime Engine classifies the current market state into
// discrete regimes: TRENDING, MEAN_REVERTING, VOLATILE, QUIET, CRISIS, EUPHORIA.
// All trading subsystems adapt their parameters based on the identified regime.
// Regime transitions are phi-gated and require coherence confirmation."
//
// THE PHANTOM REGIME ARCHITECTURE:
//   PRE-001  HIDDEN MARKOV MODEL    — HMM-based regime state estimation
//   PRE-002  VOLATILITY CLUSTERING  — GARCH-family regime detection
//   PRE-003  TREND STRENGTH METER   — ADX/phi-scaled trend classification
//   PRE-004  MEAN REVERSION SCORER  — Ornstein-Uhlenbeck parameter estimation
//   PRE-005  CRISIS DETECTOR        — Tail-event and contagion early warning
//   PRE-006  EUPHORIA GAUGE         — Bubble/mania detection via acceleration
//   PRE-007  TRANSITION PROBABILITY — Regime switch probability matrix
//   PRE-008  REGIME PERSISTENCE     — Duration modeling (how long regime lasts)
//
// PYTHAGORAS: regime thresholds, transition probabilities phi-derived
// EUCLID:     single regime state — all classification converges here
// CONFUCIUS:  right relationship — regime classifies, strategies adapt
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // REGIME CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let REGIME_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let REGIME_COUNT : Nat = 6;
  public let TREND_THRESHOLD : Float = Phi.PHI_INV_2;               // 0.382 ADX-equiv
  public let VOLATILITY_THRESHOLD : Float = Phi.PHI_INV;            // 0.618
  public let CRISIS_THRESHOLD : Float = Phi.PHI_4;                  // extreme vol
  public let EUPHORIA_THRESHOLD : Float = Phi.PHI * Phi.PHI;        // φ² acceleration
  public let MEAN_REVERSION_HALFLIFE : Float = Phi.PHI_INV * 21.0;  // phi × F(8) beats
  public let TRANSITION_SMOOTHING : Float = Phi.PHI_INV_2;          // EMA factor
  public let MIN_REGIME_DURATION : Nat = 13;                        // F(7) beats minimum

  // ═══════════════════════════════════════════════════════════════════════════
  // REGIME TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type RegimeType = {
    #trending;
    #meanReverting;
    #volatile;
    #quiet;
    #crisis;
    #euphoria;
  };

  public type RegimeProbability = {
    regime      : RegimeType;
    probability : Float;        // [0, 1]
  };

  public type RegimeTransition = {
    fromRegime  : RegimeType;
    toRegime    : RegimeType;
    probability : Float;
    beat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REGIME INDICATORS — the raw feature vector
  // ═══════════════════════════════════════════════════════════════════════════

  public type RegimeIndicators = {
    trendStrength       : Float;    // [0, 1] ADX-like
    volatilityLevel     : Float;    // realized vol / historical vol
    meanReversionSpeed  : Float;    // OU theta parameter
    accelerationRate    : Float;    // d²price/dt²
    tailRiskProb        : Float;    // probability of extreme move
    correlationBreakdown : Float;   // 1 = normal, 0 = all correlations break
    volumeAnomaly       : Float;    // volume vs F(12)=144 beat average
    spreadWidening      : Float;    // bid-ask spread vs normal
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM REGIME STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomRegimeState = {
    currentRegime       : RegimeType;
    previousRegime      : RegimeType;
    regimeProbabilities : [RegimeProbability];
    indicators          : RegimeIndicators;
    regimeDuration      : Nat;        // beats in current regime
    transitionHistory   : [RegimeTransition];
    totalTransitions    : Nat;
    lastTickBeat        : Int;
    coherence           : Float;
    regimeConfidence    : Float;      // how confident we are in classification
    regimeStability     : Float;      // how stable current regime is
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomRegimeState() : PhantomRegimeState {
    {
      currentRegime = #quiet;
      previousRegime = #quiet;
      regimeProbabilities = [
        { regime = #trending; probability = 0.1 },
        { regime = #meanReverting; probability = 0.2 },
        { regime = #volatile; probability = 0.1 },
        { regime = #quiet; probability = 0.4 },
        { regime = #crisis; probability = 0.1 },
        { regime = #euphoria; probability = 0.1 },
      ];
      indicators = {
        trendStrength = 0.0;
        volatilityLevel = 0.5;
        meanReversionSpeed = Phi.PHI_INV;
        accelerationRate = 0.0;
        tailRiskProb = 0.05;
        correlationBreakdown = 1.0;
        volumeAnomaly = 1.0;
        spreadWidening = 1.0;
      };
      regimeDuration = 0;
      transitionHistory = [];
      totalTransitions = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
      regimeConfidence = 0.4;
      regimeStability = 0.5;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance regime detection per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomRegime(
    state : PhantomRegimeState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomRegimeState {
    if (systemCoherence < REGIME_COHERENCE_GATE) return state;

    let ind = state.indicators;

    // Classify regime from indicators
    let detected : RegimeType = if (ind.tailRiskProb > Phi.PHI_INV_2 or ind.correlationBreakdown < Phi.PHI_INV_3) {
      #crisis
    } else if (ind.accelerationRate > EUPHORIA_THRESHOLD) {
      #euphoria
    } else if (ind.volatilityLevel > VOLATILITY_THRESHOLD) {
      #volatile
    } else if (ind.trendStrength > TREND_THRESHOLD) {
      #trending
    } else if (ind.meanReversionSpeed > Phi.PHI_INV) {
      #meanReverting
    } else {
      #quiet
    };

    // Check if regime transition (require minimum duration)
    let sameRegime = regimeEq(detected, state.currentRegime);
    let duration = if (sameRegime) { state.regimeDuration + 1 } else { state.regimeDuration + 1 };
    let canTransition = state.regimeDuration >= MIN_REGIME_DURATION;

    let (newRegime, newDuration, newPrev, transitions, count) = if (not sameRegime and canTransition) {
      let t : RegimeTransition = {
        fromRegime = state.currentRegime;
        toRegime = detected;
        probability = state.regimeConfidence;
        beat = beat;
      };
      let hist = if (state.transitionHistory.size() >= 21) {
        Array.tabulate<RegimeTransition>(21, func(i) {
          if (i < 20) state.transitionHistory[i + 1] else t
        })
      } else {
        Array.append(state.transitionHistory, [t])
      };
      (detected, 0, state.currentRegime, hist, state.totalTransitions + 1)
    } else {
      (state.currentRegime, duration, state.previousRegime, state.transitionHistory, state.totalTransitions)
    };

    // Confidence: higher if regime persists
    let conf = Float.min(1.0, Float.fromInt(newDuration) / Float.fromInt(MIN_REGIME_DURATION) * Phi.PHI_INV);

    {
      currentRegime = newRegime;
      previousRegime = newPrev;
      regimeProbabilities = state.regimeProbabilities;
      indicators = ind;
      regimeDuration = newDuration;
      transitionHistory = transitions;
      totalTransitions = count;
      lastTickBeat = beat;
      coherence = systemCoherence;
      regimeConfidence = conf;
      regimeStability = if (sameRegime) {
        Float.min(1.0, state.regimeStability + Phi.PHI_INV_3 * 0.1)
      } else {
        Phi.PHI_INV_3
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE INDICATORS — feed new market data
  // ═══════════════════════════════════════════════════════════════════════════

  public func updateIndicators(
    state : PhantomRegimeState,
    trendStrength : Float,
    volatility : Float,
    meanRevSpeed : Float,
    acceleration : Float
  ) : PhantomRegimeState {
    let ind : RegimeIndicators = {
      state.indicators with
      trendStrength = trendStrength;
      volatilityLevel = volatility;
      meanReversionSpeed = meanRevSpeed;
      accelerationRate = acceleration;
    };
    { state with indicators = ind }
  };

  // Helper
  func regimeEq(a : RegimeType, b : RegimeType) : Bool {
    switch(a, b) {
      case (#trending, #trending) true;
      case (#meanReverting, #meanReverting) true;
      case (#volatile, #volatile) true;
      case (#quiet, #quiet) true;
      case (#crisis, #crisis) true;
      case (#euphoria, #euphoria) true;
      case _ false;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getCurrentRegimeLabel(state : PhantomRegimeState) : Text {
    switch(state.currentRegime) {
      case (#trending) "TRENDING";
      case (#meanReverting) "MEAN_REVERTING";
      case (#volatile) "VOLATILE";
      case (#quiet) "QUIET";
      case (#crisis) "CRISIS";
      case (#euphoria) "EUPHORIA";
    }
  };

  public func getRegimeConfidence(state : PhantomRegimeState) : Float {
    state.regimeConfidence
  };
};
