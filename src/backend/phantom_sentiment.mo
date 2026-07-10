// phantom_sentiment.mo — PHANTOM SENTIMENT ENGINE
// PARALLAX Sovereign Organism — Multi-Source Sentiment Intelligence Layer
//
// DOCTRINE: "The Phantom Sentiment Engine aggregates emotional market state
// from social media, news feeds, on-chain activity, and whale movements.
// Sentiment is quantified into phi-harmonic conviction scores that feed
// all trading subsystems. No decision fires without sentiment context."
//
// THE PHANTOM SENTIMENT ARCHITECTURE:
//   PSE-001  SOCIAL PULSE          — Twitter/X, Reddit, Telegram aggregation
//   PSE-002  NEWS RESONANCE        — Headline NLP scoring with decay
//   PSE-003  ON-CHAIN EMOTION      — Whale accumulation/distribution detection
//   PSE-004  FEAR-GREED HARMONICS  — Multi-factor fear/greed index (phi-weighted)
//   PSE-005  CROWD DIVERGENCE      — Contrarian signal when crowd is extreme
//   PSE-006  NARRATIVE TRACKER     — Dominant market narrative identification
//   PSE-007  INFLUENCER WEIGHT     — Key opinion leader signal amplification
//   PSE-008  FUNDING SENTIMENT     — Perpetual funding rate sentiment proxy
//
// PYTHAGORAS: all sentiment scores decay at φ⁻¹ per beat; thresholds are phi-derived
// EUCLID:     single sentiment state — all emotion data converges here
// CONFUCIUS:  right relationship — sentiment informs but never overrides doctrine
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SENTIMENT CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let SENTIMENT_COHERENCE_GATE : Float = Phi.PHI_INV;       // 0.618
  public let SENTIMENT_DECAY_RATE : Float = Phi.PHI_INV;           // signals fade at φ⁻¹
  public let FEAR_EXTREME_THRESHOLD : Float = Phi.PHI_INV_3;       // 0.236 — extreme fear
  public let GREED_EXTREME_THRESHOLD : Float = Phi.PHI_INV + Phi.PHI_INV_3; // 0.854
  public let CONTRARIAN_TRIGGER : Float = Phi.PHI_INV_2;           // 0.382 deviation from neutral
  public let NARRATIVE_HALF_LIFE_BEATS : Nat = 89;                 // F(11) beats
  public let MAX_SENTIMENT_SOURCES : Nat = 34;                     // F(9)
  public let INFLUENCER_AMPLIFICATION : Float = Phi.PHI;           // φ multiplier for KOL signals

  // ═══════════════════════════════════════════════════════════════════════════
  // SENTIMENT SOURCE — individual signal feed
  // ═══════════════════════════════════════════════════════════════════════════

  public type SentimentSource = {
    #social;
    #news;
    #onChain;
    #funding;
    #influencer;
    #narrative;
    #crowd;
    #fearGreed;
  };

  public type SentimentSignal = {
    source       : SentimentSource;
    score        : Float;       // [-1.0, +1.0] bearish to bullish
    confidence   : Float;       // [0.0, 1.0]
    weight       : Float;       // phi-derived source weight
    sampleCount  : Nat;
    lastBeat     : Int;
    decayedScore : Float;       // score after temporal decay
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEAR-GREED STATE — composite emotional index
  // ═══════════════════════════════════════════════════════════════════════════

  public type FearGreedState = {
    index             : Float;     // [0.0, 1.0] where 0=extreme fear, 1=extreme greed
    previousIndex     : Float;
    momentum          : Float;     // rate of change
    regime            : Text;      // "EXTREME_FEAR" | "FEAR" | "NEUTRAL" | "GREED" | "EXTREME_GREED"
    daysSinceExtreme  : Nat;
    contrarianSignal  : Float;     // strength of contrarian trigger [-1, +1]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NARRATIVE — dominant market story tracking
  // ═══════════════════════════════════════════════════════════════════════════

  public type Narrative = {
    id          : Text;
    label       : Text;           // e.g. "AI_TOKENS", "BTC_ETF", "L2_SEASON"
    strength    : Float;          // [0.0, 1.0]
    birthBeat   : Int;
    lastBeat    : Int;
    mentions    : Nat;
    decayRate   : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM SENTIMENT STATE — the complete emotional model
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomSentimentState = {
    signals           : [SentimentSignal];
    fearGreed         : FearGreedState;
    narratives        : [Narrative];
    compositeSentiment : Float;     // weighted aggregate [-1, +1]
    compositeConfidence : Float;    // overall confidence [0, 1]
    totalSignalsProcessed : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
    contrarian        : Bool;       // true when crowd is at extreme
    dominantSource    : SentimentSource;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomSentimentState() : PhantomSentimentState {
    {
      signals = Array.tabulate<SentimentSignal>(8, func(i) {
        let src : SentimentSource = switch(i) {
          case 0 { #social };
          case 1 { #news };
          case 2 { #onChain };
          case 3 { #funding };
          case 4 { #influencer };
          case 5 { #narrative };
          case 6 { #crowd };
          case _ { #fearGreed };
        };
        {
          source = src;
          score = 0.0;
          confidence = 0.5;
          weight = Phi.PHI_INV;
          sampleCount = 0;
          lastBeat = 0;
          decayedScore = 0.0;
        }
      });
      fearGreed = {
        index = 0.5;
        previousIndex = 0.5;
        momentum = 0.0;
        regime = "NEUTRAL";
        daysSinceExtreme = 0;
        contrarianSignal = 0.0;
      };
      narratives = [];
      compositeSentiment = 0.0;
      compositeConfidence = 0.5;
      totalSignalsProcessed = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
      contrarian = false;
      dominantSource = #social;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance sentiment state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomSentiment(
    state : PhantomSentimentState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomSentimentState {
    // Gate: only tick if system coherence is above threshold
    if (systemCoherence < SENTIMENT_COHERENCE_GATE) return state;

    // Decay all signals
    let decayedSignals = Array.map<SentimentSignal, SentimentSignal>(state.signals, func(s) {
      let beatDelta = Int.abs(beat - s.lastBeat);
      let decay = Float.pow(SENTIMENT_DECAY_RATE, Float.fromInt(beatDelta));
      { s with decayedScore = s.score * decay }
    });

    // Compute composite sentiment (weighted average of decayed scores)
    var totalWeight : Float = 0.0;
    var weightedSum : Float = 0.0;
    var maxWeight : Float = 0.0;
    var dominantIdx : Nat = 0;
    for (i in decayedSignals.keys()) {
      let s = decayedSignals[i];
      let w = s.weight * s.confidence;
      weightedSum += s.decayedScore * w;
      totalWeight += w;
      if (w > maxWeight) { maxWeight := w; dominantIdx := i };
    };
    let composite = if (totalWeight > 0.0) { weightedSum / totalWeight } else { 0.0 };

    // Update fear-greed index
    let fgIndex = (composite + 1.0) / 2.0; // map [-1,+1] to [0,1]
    let fgMomentum = fgIndex - state.fearGreed.index;
    let fgRegime = if (fgIndex < FEAR_EXTREME_THRESHOLD) { "EXTREME_FEAR" }
      else if (fgIndex < Phi.PHI_INV_2) { "FEAR" }
      else if (fgIndex > GREED_EXTREME_THRESHOLD) { "EXTREME_GREED" }
      else if (fgIndex > Phi.PHI_INV) { "GREED" }
      else { "NEUTRAL" };

    // Contrarian detection
    let isContrarian = Float.abs(composite) > CONTRARIAN_TRIGGER;
    let contrarianSig = if (isContrarian) { -composite * Phi.PHI_INV } else { 0.0 };

    // Decay narratives
    let decayedNarratives = Array.map<Narrative, Narrative>(state.narratives, func(n) {
      let age = Int.abs(beat - n.lastBeat);
      let decay = Float.pow(n.decayRate, Float.fromInt(age));
      { n with strength = n.strength * decay }
    });

    // Determine dominant source
    let dominant = if (dominantIdx < decayedSignals.size()) {
      decayedSignals[dominantIdx].source
    } else { #social };

    {
      signals = decayedSignals;
      fearGreed = {
        index = fgIndex;
        previousIndex = state.fearGreed.index;
        momentum = fgMomentum;
        regime = fgRegime;
        daysSinceExtreme = if (isContrarian) 0 else state.fearGreed.daysSinceExtreme + 1;
        contrarianSignal = contrarianSig;
      };
      narratives = decayedNarratives;
      compositeSentiment = composite;
      compositeConfidence = if (totalWeight > 0.0) { totalWeight / Float.fromInt(decayedSignals.size()) } else { 0.0 };
      totalSignalsProcessed = state.totalSignalsProcessed + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
      contrarian = isContrarian;
      dominantSource = dominant;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INGEST — add new raw sentiment signal
  // ═══════════════════════════════════════════════════════════════════════════

  public func ingestSignal(
    state : PhantomSentimentState,
    source : SentimentSource,
    rawScore : Float,
    confidence : Float,
    beat : Int
  ) : PhantomSentimentState {
    let clampedScore = Float.max(-1.0, Float.min(1.0, rawScore));
    let clampedConf = Float.max(0.0, Float.min(1.0, confidence));

    let updatedSignals = Array.map<SentimentSignal, SentimentSignal>(state.signals, func(s) {
      if (sentimentSourceEq(s.source, source)) {
        {
          s with
          score = clampedScore;
          confidence = clampedConf;
          sampleCount = s.sampleCount + 1;
          lastBeat = beat;
          decayedScore = clampedScore;
        }
      } else { s }
    });
    { state with signals = updatedSignals; totalSignalsProcessed = state.totalSignalsProcessed + 1 }
  };

  // Helper: compare sentiment sources
  func sentimentSourceEq(a : SentimentSource, b : SentimentSource) : Bool {
    switch(a, b) {
      case (#social, #social) true;
      case (#news, #news) true;
      case (#onChain, #onChain) true;
      case (#funding, #funding) true;
      case (#influencer, #influencer) true;
      case (#narrative, #narrative) true;
      case (#crowd, #crowd) true;
      case (#fearGreed, #fearGreed) true;
      case _ false;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getCompositeSentiment(state : PhantomSentimentState) : Float {
    state.compositeSentiment
  };

  public func getFearGreedIndex(state : PhantomSentimentState) : Float {
    state.fearGreed.index
  };

  public func isContrarian(state : PhantomSentimentState) : Bool {
    state.contrarian
  };
};
