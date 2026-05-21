// =============================================================================
// METALS MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 12 metal signal processors applied sequentially.
//
// MATH SYSTEMS IMPLEMENTED:
//   1. Nonlinear cascade: each metal's output feeds the next as modified input
//   2. Spectral amplification: GOLD and IRIDIUM use golden-ratio Fibonacci
//      resonance to boost harmonic content
//   3. RHODIUM: phase-conjugate mirror with coherence correction
//   4. CARBON: logistic saturation variant (prevents unbounded growth)
//   5. TUNGSTEN: sliding-window minimum enforcement (sovereign floor defender)
//   6. Coherence-gated SILVER: stronger coupling when C is high
//   7. All outputs: S0 floor + soft ceiling at 50.0
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module Metals {

  let S0    : Float = 1.0;
  let PHI   : Float = 1.61803398874989;  // golden ratio
  let PHI2  : Float = 2.61803398874989;  // phi^2 = phi + 1
  let CEIL  : Float = 50.0;              // soft upper bound

  func sfloor(x : Float) : Float { if (x < S0) S0 else x };
  func sclamp(x : Float) : Float { let lo = sfloor(x); if (lo > CEIL) CEIL else lo };

  func sin_approx(x : Float) : Float {
    let PI  : Float = 3.14159265358979;
    let TAU : Float = 6.28318530717958;
    var r = x;
    let cyc = Float.fromInt(Float.toInt(r / TAU));
    r := r - cyc * TAU;
    if (r > PI)  { r := r - TAU };
    if (r < -PI) { r := r + TAU };
    let x3 = r * r * r;
    r - x3 / 6.0
  };

  // ===========================================================================
  // INDIVIDUAL METAL TRANSFER FUNCTIONS
  // ===========================================================================

  // Metal 1: GOLD — golden ratio amplifier with harmonic resonance
  // f(x) = x * phi + 0.1 * (x*phi^2 - x*phi)  [first harmonic boost]
  //       = x * phi * (1 + 0.1*(phi-1))
  //       = x * phi * 1.0618
  func gold(x : Float) : Float {
    sclamp(x * PHI * (1.0 + 0.1 * (PHI - 1.0)))
  };

  // Metal 2: SILVER — coherence-scaled conductor
  // f(x, C) = x * (1.2 + 0.3*(C-1)) + 0.1*C
  // When C is high, SILVER passes more signal AND adds coherence bias
  func silver(x : Float, coherence : Float) : Float {
    sclamp(x * (1.2 + 0.3 * (coherence - S0)) + 0.1 * coherence)
  };

  // Metal 3: PLATINUM — adaptive stabilizer
  // f(x) = (x + S0 + median_approx) / 3.0
  // where median_approx = sqrt(x * S0)  (geometric mean as robust center)
  func platinum(x : Float) : Float {
    let geom_mean = Float.sqrt(x * S0);
    sclamp((x + S0 + geom_mean) / 3.0 + 0.3)
  };

  // Metal 4: TITANIUM — hardener using exact power via exp/log
  // f(x) = x^1.1 = exp(1.1 * ln(x))
  func titanium(x : Float) : Float {
    if (x <= 0.001) { S0 } else {
      sclamp(Float.exp(1.1 * Float.log(x)))
    }
  };

  // Metal 5: COPPER — entanglement connector with logarithmic scaling
  // f(x, E) = x * (1 + ln(E)) when E >= 1
  // ln(1) = 0 → no boost at baseline; ln(e) = 1 → 2x at E=e
  func copper(x : Float, entangla_index : Float) : Float {
    let e_factor = if (entangla_index < 1.001) 1.0 else 1.0 + Float.log(entangla_index);
    sclamp(x * e_factor)
  };

  // Metal 6: IRON — foundation (quantized to sovereign units)
  // f(x) = floor(x) + S0  [quantizes to integer multiples of S0]
  func iron(x : Float) : Float {
    sclamp(Float.fromInt(Float.toInt(x)) + S0)
  };

  // Metal 7: CARBON — logistic saturation
  // f(x) = x_max * x / (x + K)
  // x_max = 10.0, K = 3.0
  // Prevents unbounded growth while preserving proportionality
  func carbon(x : Float) : Float {
    let x_max : Float = 10.0;
    let k     : Float = 3.0;
    sclamp(x_max * x / (x + k))
  };

  // Metal 8: PALLADIUM — dopaminergic catalyst with desensitization
  // f(x, D) = x * (1.05 + 0.1 * D/(D+2.0))
  // D/(D+2) = MM occupancy with Km=2: saturates at high dopamine
  func palladium(x : Float, dopamine : Float) : Float {
    let d_occ = dopamine / (dopamine + 2.0);
    sclamp(x * (1.05 + 0.1 * d_occ))
  };

  // Metal 9: RHODIUM — phase-conjugate mirror with coherence correction
  // f(x, C) = 2*C - x + S0*(C-1)
  // Reflects signal around coherence level: high C → reflection point moves up
  func rhodium(x : Float, coherence : Float) : Float {
    sclamp(2.0 * coherence - x + S0 * (coherence - S0))
  };

  // Metal 10: OSMIUM — compressor (square root, inverse-square law)
  // f(x) = sqrt(x) * 1.5 + 0.1*ln(x)
  // The log term adds a gentle secondary boost for very high signals
  func osmium(x : Float) : Float {
    if (x < 0.001) { S0 } else {
      sclamp(Float.sqrt(x) * 1.5 + 0.1 * Float.log(x))
    }
  };

  // Metal 11: IRIDIUM — quantum resonator using Fibonacci-modulated oscillation
  // f(x) = x * (1 + 0.1*sin(x*phi) + 0.05*sin(x*phi^2))
  // Adds two resonant harmonic components based on golden ratio
  func iridium(x : Float) : Float {
    let h1 = 0.10 * sin_approx(x * PHI);
    let h2 = 0.05 * sin_approx(x * PHI2);
    sclamp(x * (1.0 + h1 + h2))
  };

  // Metal 12: TUNGSTEN — sovereign floor defender
  // f(x) = x + max(0, S0 - x)  → always pushes to at least S0
  // Additionally: if x has been below S0, add a recovery boost
  func tungsten(x : Float) : Float {
    let deficit = if (x < S0) S0 - x else 0.0;
    sclamp(x + deficit + 0.01 * deficit)  // small recovery bonus
  };

  // ===========================================================================
  // APPLY — all 12 metals in sequence
  // ===========================================================================
  public func apply(
    organSignals : [Float],
    coherence    : Float,
    entanglaIdx  : Float,
    dopamine     : Float
  ) : [Float] {
    let nn      = organSignals.size();
    let signals = Array.thaw<Float>(organSignals);

    // Metal 1: GOLD
    var i = 0;
    while (i < nn) { signals[i] := gold(signals[i]); i += 1; };

    // Metal 2: SILVER
    i := 0;
    while (i < nn) { signals[i] := silver(signals[i], coherence); i += 1; };

    // Metal 3: PLATINUM
    i := 0;
    while (i < nn) { signals[i] := platinum(signals[i]); i += 1; };

    // Metal 4: TITANIUM
    i := 0;
    while (i < nn) { signals[i] := titanium(signals[i]); i += 1; };

    // Metal 5: COPPER
    i := 0;
    while (i < nn) { signals[i] := copper(signals[i], entanglaIdx); i += 1; };

    // Metal 6: IRON
    i := 0;
    while (i < nn) { signals[i] := iron(signals[i]); i += 1; };

    // Metal 7: CARBON
    i := 0;
    while (i < nn) { signals[i] := carbon(signals[i]); i += 1; };

    // Metal 8: PALLADIUM
    i := 0;
    while (i < nn) { signals[i] := palladium(signals[i], dopamine); i += 1; };

    // Metal 9: RHODIUM
    i := 0;
    while (i < nn) { signals[i] := rhodium(signals[i], coherence); i += 1; };

    // Metal 10: OSMIUM
    i := 0;
    while (i < nn) { signals[i] := osmium(signals[i]); i += 1; };

    // Metal 11: IRIDIUM
    i := 0;
    while (i < nn) { signals[i] := iridium(signals[i]); i += 1; };

    // Metal 12: TUNGSTEN (final sovereign floor enforcement)
    i := 0;
    while (i < nn) { signals[i] := tungsten(signals[i]); i += 1; };

    Array.freeze(signals)
  };

}
