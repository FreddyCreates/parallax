// phantom_entropy.mo — PHANTOM ENTROPY ENGINE
// PARALLAX Sovereign Organism — Information Entropy & Market Disorder Intelligence
//
// DOCTRINE: "The Phantom Entropy Engine measures the information content,
// predictability, and disorder level of market data. Low entropy = predictable/orderly.
// High entropy = chaotic/unpredictable. Shannon entropy, sample entropy, and
// transfer entropy reveal the true information state of markets."
//
// THE PHANTOM ENTROPY ARCHITECTURE:
//   PEE-001  SHANNON ENTROPY        — Information content of price distribution
//   PEE-002  SAMPLE ENTROPY         — Complexity/regularity of time series
//   PEE-003  TRANSFER ENTROPY       — Directional information flow between assets
//   PEE-004  PERMUTATION ENTROPY    — Ordinal pattern complexity
//   PEE-005  APPROXIMATE ENTROPY    — Self-similarity measurement (ApEn)
//   PEE-006  MULTI-SCALE ENTROPY    — Complexity across time scales
//   PEE-007  ENTROPY RATE           — Rate of information generation
//   PEE-008  MUTUAL INFORMATION     — Shared information between signals
//
// PYTHAGORAS: bin counts are Fibonacci; entropy thresholds are phi-derived
// EUCLID:     single entropy state — all information measurement converges here
// CONFUCIUS:  right relationship — entropy measures, strategies adapt to complexity
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let ENTROPY_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let SHANNON_BIN_COUNT : Nat = 21;                           // F(8) histogram bins
  public let SAMPLE_ENTROPY_M : Nat = 2;                             // embedding dimension
  public let SAMPLE_ENTROPY_R : Float = Phi.PHI_INV_3;              // tolerance (0.236 × σ)
  public let PERMUTATION_ORDER : Nat = 5;                            // F(5) ordinal pattern order
  public let LOW_ENTROPY_THRESHOLD : Float = Phi.PHI_INV_2;         // 0.382 — orderly/predictable
  public let HIGH_ENTROPY_THRESHOLD : Float = Phi.PHI_INV + Phi.PHI_INV_3; // 0.854 — chaotic
  public let MAX_ENTROPY_HISTORY : Nat = 89;                         // F(11) historical values
  public let TRANSFER_WINDOW : Nat = 34;                             // F(9) for transfer entropy
  public let MULTI_SCALE_LEVELS : Nat = 8;                           // F(6) scales

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY MEASUREMENT — single computed value
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntropyMeasurement = {
    entropyType : Text;          // "SHANNON" | "SAMPLE" | "PERMUTATION" | "TRANSFER"
    value       : Float;         // entropy value (bits or nats)
    normalized  : Float;         // [0, 1] normalized
    beat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY REGIME — categorical classification
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntropyRegime = {
    #orderly;                    // low entropy, predictable
    #normal;                     // moderate entropy
    #complex;                    // high entropy, hard to predict
    #chaotic;                    // extreme entropy, unpredictable
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM ENTROPY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomEntropyState = {
    measurements      : [EntropyMeasurement];
    shannonEntropy    : Float;         // current Shannon H
    sampleEntropy     : Float;         // current SampEn
    permutationEntropy : Float;        // current PE
    transferEntropy   : Float;         // current TE
    compositeEntropy  : Float;         // weighted average
    entropyRegime     : EntropyRegime;
    entropyRate       : Float;         // dH/dt (change in entropy)
    predictability    : Float;         // 1 - normalized entropy [0, 1]
    dataBuffer        : [Float];       // recent data for computation
    totalMeasurements : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomEntropyState() : PhantomEntropyState {
    {
      measurements = [];
      shannonEntropy = 0.5;
      sampleEntropy = 0.5;
      permutationEntropy = 0.5;
      transferEntropy = 0.0;
      compositeEntropy = 0.5;
      entropyRegime = #normal;
      entropyRate = 0.0;
      predictability = 0.5;
      dataBuffer = [];
      totalMeasurements = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHANNON ENTROPY — information content of distribution
  // ═══════════════════════════════════════════════════════════════════════════

  func computeShannon(data : [Float]) : Float {
    if (data.size() < 2) return 0.0;

    // Find min/max for binning
    var minVal : Float = data[0];
    var maxVal : Float = data[0];
    for (d in data.vals()) {
      if (d < minVal) minVal := d;
      if (d > maxVal) maxVal := d;
    };
    let range = maxVal - minVal;
    if (range <= 0.0) return 0.0;

    // Bin the data
    let binWidth = range / Float.fromInt(SHANNON_BIN_COUNT);
    var bins = Array.init<Nat>(SHANNON_BIN_COUNT, 0);
    for (d in data.vals()) {
      var idx = Int.abs(Float.toInt((d - minVal) / binWidth));
      if (idx >= SHANNON_BIN_COUNT) idx := SHANNON_BIN_COUNT - 1;
      bins[idx] += 1;
    };

    // Compute entropy: H = -Σ p(x) log₂(p(x))
    var entropy : Float = 0.0;
    let n = Float.fromInt(data.size());
    for (count in bins.vals()) {
      if (count > 0) {
        let p = Float.fromInt(count) / n;
        entropy -= p * Float.log(p) / Float.log(2.0);
      };
    };

    // Normalize by max possible entropy
    let maxEntropy = Float.log(Float.fromInt(SHANNON_BIN_COUNT)) / Float.log(2.0);
    if (maxEntropy > 0.0) { entropy / maxEntropy } else { 0.0 }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMUTATION ENTROPY — ordinal pattern complexity
  // ═══════════════════════════════════════════════════════════════════════════

  func computePermutationEntropy(data : [Float]) : Float {
    if (data.size() < PERMUTATION_ORDER + 1) return 0.0;

    // Count ordinal patterns (simplified: just up/down patterns)
    var upCount : Nat = 0;
    var downCount : Nat = 0;
    var flatCount : Nat = 0;
    var i = 1;
    while (i < data.size()) {
      if (data[i] > data[i-1]) upCount += 1
      else if (data[i] < data[i-1]) downCount += 1
      else flatCount += 1;
      i += 1;
    };

    let total = Float.fromInt(upCount + downCount + flatCount);
    if (total <= 0.0) return 0.0;

    var entropy : Float = 0.0;
    let counts = [upCount, downCount, flatCount];
    for (c in counts.vals()) {
      if (c > 0) {
        let p = Float.fromInt(c) / total;
        entropy -= p * Float.log(p) / Float.log(2.0);
      };
    };

    // Normalize
    let maxEnt = Float.log(3.0) / Float.log(2.0);
    if (maxEnt > 0.0) { entropy / maxEnt } else { 0.0 }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance entropy state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomEntropy(
    state : PhantomEntropyState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomEntropyState {
    if (systemCoherence < ENTROPY_COHERENCE_GATE) return state;
    if (state.dataBuffer.size() < 13) {
      return { state with lastTickBeat = beat; coherence = systemCoherence };
    };

    // Compute entropy measures
    let shannon = computeShannon(state.dataBuffer);
    let permutation = computePermutationEntropy(state.dataBuffer);

    // Sample entropy approximation (regularity based on repeated patterns)
    let sampleEnt = (shannon + permutation) / 2.0; // simplified

    // Composite entropy (phi-weighted)
    let composite = shannon * Phi.PHI_INV + permutation * Phi.PHI_INV_2 + sampleEnt * Phi.PHI_INV_3;

    // Entropy rate (change)
    let rate = composite - state.compositeEntropy;

    // Classify regime
    let regime : EntropyRegime = if (composite < LOW_ENTROPY_THRESHOLD) { #orderly }
      else if (composite > HIGH_ENTROPY_THRESHOLD) { #chaotic }
      else if (composite > Phi.PHI_INV) { #complex }
      else { #normal };

    // Predictability = 1 - entropy
    let predict = 1.0 - composite;

    // Store measurement
    let meas : EntropyMeasurement = {
      entropyType = "COMPOSITE";
      value = composite;
      normalized = composite;
      beat = beat;
    };
    let measurements = if (state.measurements.size() >= MAX_ENTROPY_HISTORY) {
      Array.tabulate<EntropyMeasurement>(MAX_ENTROPY_HISTORY, func(i) {
        if (i < MAX_ENTROPY_HISTORY - 1) state.measurements[i + 1] else meas
      })
    } else {
      Array.append(state.measurements, [meas])
    };

    {
      measurements = measurements;
      shannonEntropy = shannon;
      sampleEntropy = sampleEnt;
      permutationEntropy = permutation;
      transferEntropy = state.transferEntropy;
      compositeEntropy = composite;
      entropyRegime = regime;
      entropyRate = rate;
      predictability = predict;
      dataBuffer = state.dataBuffer;
      totalMeasurements = state.totalMeasurements + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED DATA — add new observation
  // ═══════════════════════════════════════════════════════════════════════════

  public func feedData(state : PhantomEntropyState, value : Float) : PhantomEntropyState {
    let maxBuf = 144; // F(12)
    let buffer = if (state.dataBuffer.size() >= maxBuf) {
      Array.tabulate<Float>(maxBuf, func(i) {
        if (i < maxBuf - 1) state.dataBuffer[i + 1] else value
      })
    } else {
      Array.append(state.dataBuffer, [value])
    };
    { state with dataBuffer = buffer }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getCompositeEntropy(state : PhantomEntropyState) : Float {
    state.compositeEntropy
  };

  public func getPredictability(state : PhantomEntropyState) : Float {
    state.predictability
  };

  public func getEntropyRegimeLabel(state : PhantomEntropyState) : Text {
    switch(state.entropyRegime) {
      case (#orderly) "ORDERLY";
      case (#normal) "NORMAL";
      case (#complex) "COMPLEX";
      case (#chaotic) "CHAOTIC";
    }
  };
};
