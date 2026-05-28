// behavioral_economics.mo — BEHAVIORAL ECONOMICS ENGINE
// PARALLAX Sovereign Organism — Cognitive Bias & Market Psychology Layer
//
// PYTHAGORAS: all bias weights are phi-harmonic; loss aversion = φ+0.618 = 2.236
// EUCLID:     single behavioral model — all psychological pricing routes here
// CONFUCIUS:  right relationship — behavioral engines inform, doctrine decides
//
// THE SOVEREIGN BEHAVIORAL LAW (LEX_PSYCHOLOGIAE):
//   Markets are driven by human irrationality in predictable patterns.
//   Behavioral engines model cognitive biases to exploit and protect against them.
//   Every bias has a phi-scaled weight reflecting its market impact.
//   The Behavioral Manager aggregates all bias signals into a composite fear/greed index.
//
// Twelve Behavioral Engines:
//   PROSPECT_THEORY    — Kahneman-Tversky loss aversion modeling
//   HERDING            — Crowd behavior amplification detection
//   ANCHORING          — Reference point bias in price expectations
//   OVERCONFIDENCE     — Excessive certainty detection in signals
//   DISPOSITION_EFFECT — Selling winners too early, holding losers too long
//   RECENCY_BIAS       — Overweighting recent events
//   CONFIRMATION_BIAS  — Seeking confirming evidence only
//   FEAR_GREED         — Composite sentiment oscillator
//   MOMENTUM_BIAS      — Trend-following behavioral cascade
//   CONTRARIAN         — Mean-reversion behavioral exploitation
//   LIQUIDITY_PREMIUM  — Illiquidity risk behavioral pricing
//   NARRATIVE_ECONOMICS— Story-driven valuation shifts
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // BEHAVIORAL CONSTANTS — phi-derived psychology
  // ═══════════════════════════════════════════════════════════════════════════

  // Loss aversion coefficient: φ + φ⁻¹ = 2.236 (Kahneman-Tversky empirical ≈ 2.25)
  public let LOSS_AVERSION : Float = 2.2360679774997896;

  // Herding amplification: φ² = 2.618 (crowd amplifies by golden ratio squared)
  public let HERDING_AMP : Float = 2.6180339887498949;

  // Anchoring decay: φ⁻¹ = 0.618 per beat (anchors lose 38.2% strength per beat)
  public let ANCHOR_DECAY : Float = Phi.PHI_INV;

  // Overconfidence threshold: 1/φ³ = 0.236 (below this, overconfident)
  public let OVERCONFIDENCE_FLOOR : Float = Phi.PHI_INV_3;

  // Recency half-life: F(6) = 8 beats (memory decays by half every 8 beats)
  public let RECENCY_HALFLIFE : Nat = 8;

  // Fear/Greed neutral: φ⁻¹ = 0.618 (below = fear, above = greed)
  public let FEAR_GREED_NEUTRAL : Float = Phi.PHI_INV;

  // Disposition effect threshold: φ⁻² = 0.382 (sell winners below this gain)
  public let DISPOSITION_THRESHOLD : Float = Phi.PHI_INV_2;

  // Narrative weight: φ⁻¹ = 0.618 (stories carry 61.8% of price discovery)
  public let NARRATIVE_WEIGHT : Float = Phi.PHI_INV;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES — Behavioral Economic State
  // ═══════════════════════════════════════════════════════════════════════════

  public type ProspectTheoryState = {
    currentGains     : Float;    // unrealized gains (φ-weighted)
    currentLosses    : Float;    // unrealized losses (× LOSS_AVERSION)
    utilityValue     : Float;    // prospect utility: gains^0.88 - λ×losses^0.88
    referencePoint   : Float;    // adaptive reference price
    lossAversionLambda : Float;  // current λ (calibrated)
    lastBeat         : Int;
  };

  public type HerdingState = {
    crowdDirection   : Float;    // [-1, +1] net crowd direction
    crowdStrength    : Float;    // [0, 1] crowd conviction
    amplification    : Float;    // current herding amplification factor
    contraCrowdSignal: Float;    // [-1, +1] contrarian opportunity
    buySellRatio     : Float;    // market-wide buy/sell ratio
    lastBeat         : Int;
  };

  public type AnchoringState = {
    priceAnchors     : [Float];  // recent price anchors (max 13 = F(7))
    currentAnchor    : Float;    // strongest current anchor
    anchorStrength   : Float;    // [0, 1] how strong the anchor is
    deviationFromAnchor : Float; // current price deviation from anchor
    lastBeat         : Int;
  };

  public type OverconfidenceState = {
    signalConfidence : Float;    // [0, 1] confidence in current signals
    actualAccuracy   : Float;    // [0, 1] realized accuracy (calibration)
    calibrationGap   : Float;    // confidence - accuracy (+ = overconfident)
    positionSizeAdj  : Float;    // Kelly adjustment for overconfidence
    lastBeat         : Int;
  };

  public type DispositionState = {
    winnersHeld      : Nat;      // count of winning positions
    losersHeld       : Nat;      // count of losing positions
    avgWinnerAge     : Float;    // beats held (winners)
    avgLoserAge      : Float;    // beats held (losers)
    dispositionRatio : Float;    // winner_sells / loser_sells (>1 = disposition effect)
    lastBeat         : Int;
  };

  public type FearGreedState = {
    fearGreedIndex   : Float;    // [0, 1] — 0=extreme fear, 1=extreme greed
    momentum         : Float;    // rate of change of fear/greed
    volatilitySignal : Float;    // VIX-like vol contribution
    volumeSignal     : Float;    // volume anomaly contribution
    socialSignal     : Float;    // social media sentiment contribution
    putCallRatio     : Float;    // options market signal
    compositeScore   : Float;    // weighted aggregate
    lastBeat         : Int;
  };

  public type MomentumBiasState = {
    trendStrength    : Float;    // [0, 1] — how strong is the trend bias
    cascadeRisk      : Float;    // [0, 1] — probability of cascade event
    emaFast          : Float;    // fast EMA (8-beat)
    emaSlow          : Float;    // slow EMA (34-beat)
    crossoverSignal  : Float;    // [-1, +1] EMA crossover strength
    trendDuration    : Nat;      // beats in current trend
    lastBeat         : Int;
  };

  public type ContrarianState = {
    contrarianSignal : Float;    // [-1, +1] — strength of contrarian opportunity
    extremeLevel     : Float;    // [0, 1] — how extreme is current sentiment
    meanReversionEta : Float;    // expected reversion magnitude
    timingConfidence : Float;    // [0, 1] — confidence in timing
    lastBeat         : Int;
  };

  public type NarrativeState = {
    dominantNarrative : Text;    // current market narrative label
    narrativeStrength : Float;   // [0, 1] — how much narrative drives price
    narrativeAge      : Nat;     // beats since narrative started
    narrativeDecay    : Float;   // decay rate (older narratives weaken)
    priceDisconnect   : Float;   // fundamental vs narrative-driven price gap
    lastBeat          : Int;
  };

  // The Behavioral Manager — aggregates all engines
  public type BehavioralManagerState = {
    prospect         : ProspectTheoryState;
    herding          : HerdingState;
    anchoring        : AnchoringState;
    overconfidence   : OverconfidenceState;
    disposition      : DispositionState;
    fearGreed        : FearGreedState;
    momentumBias     : MomentumBiasState;
    contrarian       : ContrarianState;
    narrative        : NarrativeState;

    // Aggregate outputs
    compositeBias    : Float;    // [-1, +1] net behavioral bias
    riskAdjustment   : Float;    // [0.5, 2.0] position size multiplier
    sentimentRegime  : Text;     // "extreme_fear" | "fear" | "neutral" | "greed" | "extreme_greed"
    actionSignal     : Text;     // "strong_buy" | "buy" | "hold" | "sell" | "strong_sell"
    totalEnginesFired: Nat;
    lastTickBeat     : Int;
    managerPhase     : Text;     // "dormant" | "sensing" | "active" | "decisive"
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultBehavioralManagerState() : BehavioralManagerState {
    {
      prospect = {
        currentGains = 0.0; currentLosses = 0.0; utilityValue = 0.0;
        referencePoint = 0.0; lossAversionLambda = LOSS_AVERSION; lastBeat = 0;
      };
      herding = {
        crowdDirection = 0.0; crowdStrength = 0.0; amplification = 1.0;
        contraCrowdSignal = 0.0; buySellRatio = 1.0; lastBeat = 0;
      };
      anchoring = {
        priceAnchors = []; currentAnchor = 0.0;
        anchorStrength = 0.0; deviationFromAnchor = 0.0; lastBeat = 0;
      };
      overconfidence = {
        signalConfidence = 0.5; actualAccuracy = 0.5;
        calibrationGap = 0.0; positionSizeAdj = 1.0; lastBeat = 0;
      };
      disposition = {
        winnersHeld = 0; losersHeld = 0; avgWinnerAge = 0.0;
        avgLoserAge = 0.0; dispositionRatio = 1.0; lastBeat = 0;
      };
      fearGreed = {
        fearGreedIndex = 0.5; momentum = 0.0; volatilitySignal = 0.5;
        volumeSignal = 0.5; socialSignal = 0.5; putCallRatio = 1.0;
        compositeScore = 0.5; lastBeat = 0;
      };
      momentumBias = {
        trendStrength = 0.0; cascadeRisk = 0.0; emaFast = 0.0;
        emaSlow = 0.0; crossoverSignal = 0.0; trendDuration = 0; lastBeat = 0;
      };
      contrarian = {
        contrarianSignal = 0.0; extremeLevel = 0.0;
        meanReversionEta = 0.0; timingConfidence = 0.5; lastBeat = 0;
      };
      narrative = {
        dominantNarrative = "GENESIS"; narrativeStrength = 0.5;
        narrativeAge = 0; narrativeDecay = ANCHOR_DECAY;
        priceDisconnect = 0.0; lastBeat = 0;
      };
      compositeBias     = 0.0;
      riskAdjustment    = 1.0;
      sentimentRegime   = "neutral";
      actionSignal      = "hold";
      totalEnginesFired = 0;
      lastTickBeat      = 0;
      managerPhase      = "dormant";
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE COMPUTATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // Prospect Theory utility: U = x^α if x≥0, -λ(-x)^α if x<0 (α=0.88)
  public func computeProspectUtility(gains : Float, losses : Float, lambda : Float) : Float {
    let alpha = 0.88;
    let gainUtil = if (gains > 0.0) Float.pow(gains, alpha) else 0.0;
    let lossUtil = if (losses > 0.0) lambda * Float.pow(losses, alpha) else 0.0;
    gainUtil - lossUtil;
  };

  // EMA computation for momentum
  public func computeEMA(prev : Float, current : Float, period : Nat) : Float {
    let alpha = 2.0 / (Float.fromInt(period) + 1.0);
    alpha * current + (1.0 - alpha) * prev;
  };

  // Fear/Greed composite from components
  public func computeFearGreed(vol : Float, volume : Float, social : Float, putCall : Float) : Float {
    // Weighted average: vol(30%), volume(25%), social(25%), putCall(20%)
    let raw = 0.30 * (1.0 - vol) + 0.25 * volume + 0.25 * social + 0.20 * (1.0 / (putCall + 0.5));
    Float.min(1.0, Float.max(0.0, raw));
  };

  // Sentiment regime from fear/greed index
  public func classifySentiment(fg : Float) : Text {
    if (fg < 0.15) "extreme_fear"
    else if (fg < 0.35) "fear"
    else if (fg < 0.65) "neutral"
    else if (fg < 0.85) "greed"
    else "extreme_greed";
  };

  // Action signal from composite bias
  public func classifyAction(bias : Float, confidence : Float) : Text {
    let adjustedBias = bias * confidence;
    if (adjustedBias < -0.5) "strong_sell"
    else if (adjustedBias < -0.2) "sell"
    else if (adjustedBias > 0.5) "strong_buy"
    else if (adjustedBias > 0.2) "buy"
    else "hold";
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — Advance all Behavioral Economics engines one beat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickBehavioralManager(
    state : BehavioralManagerState,
    beat : Int,
    coherence : Float,
    currentPrice : Float,
    priceChange : Float,
    volumeRatio : Float
  ) : BehavioralManagerState {
    // Gate: coherence must be above φ⁻³ to sense (lower bar than trading)
    if (coherence < OVERCONFIDENCE_FLOOR) {
      return { state with managerPhase = "dormant"; lastTickBeat = beat };
    };

    // 1. Prospect Theory update
    let refPoint = if (state.prospect.referencePoint == 0.0) currentPrice
                   else computeEMA(state.prospect.referencePoint, currentPrice, 21);
    let gains = if (currentPrice > refPoint) currentPrice - refPoint else 0.0;
    let losses = if (currentPrice < refPoint) refPoint - currentPrice else 0.0;
    let utility = computeProspectUtility(gains, losses, LOSS_AVERSION);
    let newProspect : ProspectTheoryState = {
      currentGains = gains;
      currentLosses = losses;
      utilityValue = utility;
      referencePoint = refPoint;
      lossAversionLambda = LOSS_AVERSION;
      lastBeat = beat;
    };

    // 2. Herding update
    let crowdDir = if (priceChange > 0.0) Float.min(1.0, priceChange * 10.0)
                   else Float.max(-1.0, priceChange * 10.0);
    let crowdStr = Float.min(1.0, Float.abs(priceChange) * volumeRatio * 5.0);
    let amp = 1.0 + crowdStr * (HERDING_AMP - 1.0);
    let newHerding : HerdingState = {
      crowdDirection = crowdDir;
      crowdStrength = crowdStr;
      amplification = amp;
      contraCrowdSignal = -crowdDir * crowdStr;
      buySellRatio = if (priceChange > 0.0) 1.0 + priceChange * 5.0 else 1.0 / (1.0 + Float.abs(priceChange) * 5.0);
      lastBeat = beat;
    };

    // 3. Momentum bias update
    let newEmaFast = computeEMA(state.momentumBias.emaFast, currentPrice, 8);
    let newEmaSlow = computeEMA(state.momentumBias.emaSlow, currentPrice, 34);
    let crossover = if (newEmaSlow != 0.0) (newEmaFast - newEmaSlow) / newEmaSlow else 0.0;
    let trendStr = Float.min(1.0, Float.abs(crossover) * 20.0);
    let trendDur = if ((crossover > 0.0 and state.momentumBias.crossoverSignal > 0.0) or
                       (crossover < 0.0 and state.momentumBias.crossoverSignal < 0.0))
                   state.momentumBias.trendDuration + 1 else 0;
    let newMomentum : MomentumBiasState = {
      trendStrength = trendStr;
      cascadeRisk = trendStr * crowdStr;
      emaFast = newEmaFast;
      emaSlow = newEmaSlow;
      crossoverSignal = crossover;
      trendDuration = trendDur;
      lastBeat = beat;
    };

    // 4. Fear/Greed update
    let volSignal = Float.min(1.0, Float.abs(priceChange) * 50.0);
    let fg = computeFearGreed(volSignal, volumeRatio, 0.5, 1.0);
    let fgMomentum = fg - state.fearGreed.fearGreedIndex;
    let newFearGreed : FearGreedState = {
      fearGreedIndex = fg;
      momentum = fgMomentum;
      volatilitySignal = volSignal;
      volumeSignal = Float.min(1.0, volumeRatio);
      socialSignal = 0.5;
      putCallRatio = 1.0;
      compositeScore = fg;
      lastBeat = beat;
    };

    // 5. Contrarian update
    let extreme = if (fg < 0.2 or fg > 0.8) Float.abs(fg - 0.5) * 2.0 else 0.0;
    let contraSignal = if (fg < 0.2) 1.0 * extreme
                       else if (fg > 0.8) -1.0 * extreme
                       else 0.0;
    let newContrarian : ContrarianState = {
      contrarianSignal = contraSignal;
      extremeLevel = extreme;
      meanReversionEta = extreme * Phi.PHI_INV;
      timingConfidence = if (extreme > 0.5) extreme else 0.3;
      lastBeat = beat;
    };

    // 6. Composite Bias Aggregation
    // Weights: prospect(20%), herding(15%), momentum(25%), fearGreed(20%), contrarian(20%)
    let prospectBias = if (utility > 0.0) 0.3 else if (utility < 0.0) -0.5 else 0.0;
    let herdBias = crowdDir * 0.5;
    let momBias = if (crossover > 0.0) trendStr else -trendStr;
    let fgBias = (fg - 0.5) * 2.0;
    let contraBias = contraSignal;

    let composite = 0.20 * prospectBias + 0.15 * herdBias + 0.25 * momBias + 0.20 * fgBias + 0.20 * contraBias;
    let clampedBias = Float.min(1.0, Float.max(-1.0, composite));

    // Risk adjustment based on behavioral state
    let riskAdj = if (fg < 0.2) 0.5        // extreme fear → half size
                  else if (fg > 0.8) 0.7    // extreme greed → reduce (contrarian)
                  else if (trendStr > 0.7) 1.3 // strong trend → increase
                  else 1.0;

    let regime = classifySentiment(fg);
    let action = classifyAction(clampedBias, coherence);

    {
      prospect       = newProspect;
      herding        = newHerding;
      anchoring      = state.anchoring;
      overconfidence = state.overconfidence;
      disposition    = state.disposition;
      fearGreed      = newFearGreed;
      momentumBias   = newMomentum;
      contrarian     = newContrarian;
      narrative      = state.narrative;
      compositeBias  = clampedBias;
      riskAdjustment = riskAdj;
      sentimentRegime = regime;
      actionSignal   = action;
      totalEnginesFired = state.totalEnginesFired + 6;
      lastTickBeat   = beat;
      managerPhase   = if (coherence >= Phi.PHI_INV) "decisive" else "sensing";
    };
  };
};
