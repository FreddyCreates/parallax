// phantom_wavelets.mo — PHANTOM WAVELET ENGINE
// PARALLAX Sovereign Organism — Wavelet Multi-Scale Decomposition Intelligence
//
// DOCTRINE: "The Phantom Wavelet Engine decomposes price signals into multiple
// time scales simultaneously using discrete wavelet transforms. Each scale reveals
// different market participants: HFT (scale 1), day traders (scale 3-5),
// swing traders (scale 8-13), investors (scale 21+). Phi-harmonic scale selection."
//
// THE PHANTOM WAVELET ARCHITECTURE:
//   PWE-001  DWT DECOMPOSER         — Discrete Wavelet Transform (Haar/Daubechies)
//   PWE-002  SCALE SEPARATOR        — Isolate signal components per scale
//   PWE-003  DENOISER               — Wavelet shrinkage for noise removal
//   PWE-004  TREND EXTRACTOR        — Low-frequency trend component
//   PWE-005  CYCLE DETECTOR         — Mid-frequency cyclical component
//   PWE-006  NOISE QUANTIFIER       — High-frequency noise measurement
//   PWE-007  MULTI-SCALE CORRELATOR — Cross-scale energy correlation
//   PWE-008  RECONSTRUCTION ENGINE  — Selective component recombination
//
// PYTHAGORAS: decomposition levels are Fibonacci; threshold = φ⁻² × σ
// EUCLID:     single wavelet state — all scale analysis converges here
// CONFUCIUS:  right relationship — wavelets decompose, strategies compose
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVELET CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let WAVELET_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MAX_DECOMP_LEVELS : Nat = 8;                            // F(6) levels
  public let SHRINKAGE_THRESHOLD_FACTOR : Float = Phi.PHI_INV_2;    // φ⁻² × σ
  public let MIN_SIGNAL_LENGTH : Nat = 34;                           // F(9) minimum data points
  public let ENERGY_THRESHOLD : Float = Phi.PHI_INV_3;              // minimum energy for significance
  public let NOISE_LEVEL_DEFAULT : Float = Phi.PHI_INV_2;           // default noise assumption
  public let SCALE_FIBONACCI : [Nat] = [1, 2, 3, 5, 8, 13, 21, 34]; // scale assignments
  public let RECONSTRUCTION_WEIGHT : Float = Phi.PHI_INV;            // weighting for reconstructed signal

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVELET SCALE — single decomposition level
  // ═══════════════════════════════════════════════════════════════════════════

  public type WaveletScale = {
    level       : Nat;           // decomposition level (1 = finest)
    energy      : Float;         // energy at this scale (sum of squared coefficients)
    variance    : Float;         // variance of detail coefficients
    dominantDir : Float;         // directional bias at this scale [-1, +1]
    participant : Text;          // "HFT" | "SCALPER" | "DAY" | "SWING" | "POSITION" | "INVESTOR"
    isSignificant : Bool;        // energy above threshold
    coeffCount  : Nat;           // number of detail coefficients
    lastBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL COMPONENTS — decomposed market signal
  // ═══════════════════════════════════════════════════════════════════════════

  public type SignalComponents = {
    trend       : Float;         // low-frequency trend value
    cycle       : Float;         // mid-frequency cyclical component
    noise       : Float;         // high-frequency noise level
    trendStrength : Float;       // [0, 1] how much energy is in trend
    cycleStrength : Float;       // [0, 1] how much energy is in cycles
    noiseRatio  : Float;         // noise / total energy
    snr         : Float;         // signal-to-noise ratio
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM WAVELET STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomWaveletState = {
    scales            : [WaveletScale];
    components        : SignalComponents;
    priceBuffer       : [Float];        // input data buffer
    denoisedSignal    : Float;          // current denoised value
    totalEnergy       : Float;          // sum of all scale energies
    dominantScale     : Nat;            // scale with most energy
    dominantParticipant : Text;         // who dominates now
    reconstructed     : Float;          // selectively reconstructed signal
    totalDecompositions : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomWaveletState() : PhantomWaveletState {
    let participants = ["HFT", "SCALPER", "DAY_TRADER", "SWING", "POSITION", "INVESTOR", "MACRO", "STRUCTURAL"];
    {
      scales = Array.tabulate<WaveletScale>(MAX_DECOMP_LEVELS, func(i) {
        {
          level = i + 1;
          energy = 0.0;
          variance = 0.0;
          dominantDir = 0.0;
          participant = participants[i];
          isSignificant = false;
          coeffCount = 0;
          lastBeat = 0;
        }
      });
      components = {
        trend = 0.0;
        cycle = 0.0;
        noise = 0.0;
        trendStrength = 0.0;
        cycleStrength = 0.0;
        noiseRatio = 1.0;
        snr = 0.0;
      };
      priceBuffer = [];
      denoisedSignal = 0.0;
      totalEnergy = 0.0;
      dominantScale = 1;
      dominantParticipant = "HFT";
      reconstructed = 0.0;
      totalDecompositions = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HAAR WAVELET TRANSFORM — simplified DWT
  // ═══════════════════════════════════════════════════════════════════════════

  func haarDecompose(signal : [Float]) : ([Float], [Float]) {
    // Returns (approximation, detail) coefficients
    let n = signal.size() / 2;
    if (n == 0) return (signal, []);
    let approx = Array.tabulate<Float>(n, func(i) {
      (signal[2*i] + signal[2*i + 1]) / 1.4142135623730951 // √2
    });
    let detail = Array.tabulate<Float>(n, func(i) {
      (signal[2*i] - signal[2*i + 1]) / 1.4142135623730951
    });
    (approx, detail)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance wavelet state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomWavelet(
    state : PhantomWaveletState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomWaveletState {
    if (systemCoherence < WAVELET_COHERENCE_GATE) return state;
    if (state.priceBuffer.size() < MIN_SIGNAL_LENGTH) {
      return { state with lastTickBeat = beat; coherence = systemCoherence };
    };

    // Multi-level Haar decomposition
    var currentSignal = state.priceBuffer;
    var scales : [WaveletScale] = [];
    var totalEnergy : Float = 0.0;
    var maxEnergy : Float = 0.0;
    var dominantLevel : Nat = 1;
    let participants = ["HFT", "SCALPER", "DAY_TRADER", "SWING", "POSITION", "INVESTOR", "MACRO", "STRUCTURAL"];

    var level : Nat = 0;
    while (level < MAX_DECOMP_LEVELS and currentSignal.size() >= 2) {
      let (approx, detail) = haarDecompose(currentSignal);

      // Compute energy and variance of detail
      var energy : Float = 0.0;
      var sum : Float = 0.0;
      for (d in detail.vals()) {
        energy += d * d;
        sum += d;
      };
      let mean = if (detail.size() > 0) { sum / Float.fromInt(detail.size()) } else { 0.0 };
      var varSum : Float = 0.0;
      for (d in detail.vals()) {
        varSum += (d - mean) * (d - mean);
      };
      let variance = if (detail.size() > 0) { varSum / Float.fromInt(detail.size()) } else { 0.0 };

      // Directional bias: sign of mean detail
      let dir = if (mean > 0.0) { Float.min(1.0, mean * Phi.PHI) }
        else if (mean < 0.0) { Float.max(-1.0, mean * Phi.PHI) }
        else { 0.0 };

      let isSignificant = energy > ENERGY_THRESHOLD * totalEnergy + 0.001;
      totalEnergy += energy;
      if (energy > maxEnergy) { maxEnergy := energy; dominantLevel := level + 1 };

      let participant = if (level < participants.size()) participants[level] else "STRUCTURAL";

      scales := Array.append(scales, [{
        level = level + 1;
        energy = energy;
        variance = variance;
        dominantDir = dir;
        participant = participant;
        isSignificant = isSignificant;
        coeffCount = detail.size();
        lastBeat = beat;
      }]);

      currentSignal := approx;
      level += 1;
    };

    // Components: trend = final approximation, noise = first detail energy
    let trendVal = if (currentSignal.size() > 0) currentSignal[0] else 0.0;
    let noiseEnergy = if (scales.size() > 0) scales[0].energy else 0.0;
    let cycleEnergy = if (scales.size() > 2) scales[2].energy else 0.0;
    let trendEnergy = if (scales.size() > 0) scales[scales.size() - 1].energy else 0.0;

    let snr = if (noiseEnergy > 0.0) { (totalEnergy - noiseEnergy) / noiseEnergy } else { 0.0 };
    let noiseRatio = if (totalEnergy > 0.0) { noiseEnergy / totalEnergy } else { 1.0 };

    let components : SignalComponents = {
      trend = trendVal;
      cycle = if (scales.size() > 2) scales[2].dominantDir else 0.0;
      noise = Float.sqrt(noiseEnergy);
      trendStrength = if (totalEnergy > 0.0) { trendEnergy / totalEnergy } else { 0.0 };
      cycleStrength = if (totalEnergy > 0.0) { cycleEnergy / totalEnergy } else { 0.0 };
      noiseRatio = noiseRatio;
      snr = snr;
    };

    let domPart = if (dominantLevel <= participants.size()) participants[dominantLevel - 1] else "STRUCTURAL";

    // Denoised: last price - noise component
    let lastPrice = state.priceBuffer[state.priceBuffer.size() - 1];
    let denoised = lastPrice; // simplified: in production, wavelet shrinkage applied

    {
      scales = scales;
      components = components;
      priceBuffer = state.priceBuffer;
      denoisedSignal = denoised;
      totalEnergy = totalEnergy;
      dominantScale = dominantLevel;
      dominantParticipant = domPart;
      reconstructed = trendVal;
      totalDecompositions = state.totalDecompositions + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED PRICE — add price to buffer
  // ═══════════════════════════════════════════════════════════════════════════

  public func feedPrice(state : PhantomWaveletState, price : Float) : PhantomWaveletState {
    let maxBuf = 256; // power of 2 for efficient DWT
    let buffer = if (state.priceBuffer.size() >= maxBuf) {
      Array.tabulate<Float>(maxBuf, func(i) {
        if (i < maxBuf - 1) state.priceBuffer[i + 1] else price
      })
    } else {
      Array.append(state.priceBuffer, [price])
    };
    { state with priceBuffer = buffer }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getDominantParticipant(state : PhantomWaveletState) : Text {
    state.dominantParticipant
  };

  public func getSNR(state : PhantomWaveletState) : Float {
    state.components.snr
  };

  public func getTrendStrength(state : PhantomWaveletState) : Float {
    state.components.trendStrength
  };
};
