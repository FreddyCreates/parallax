import Float "mo:core/Float";
import Array "mo:core/Array";
import Iter "mo:core/Iter";
import Nat "mo:core/Nat";

// PARALLAX — 12 Metal Transfer Functions (SOVEREIGN MATH v3)
// Fibonacci resonance (IRIDIUM), logistic saturation (CARBON),
// phase-conjugate mirror (RHODIUM), exact power law (TITANIUM)
// All outputs floored at S0=1.0
module {

  let S0  : Float = 1.0;
  let PHI : Float = 1.6180339887;  // Golden ratio

  func clamp(x : Float) : Float { Float.max(S0, x) };

  // GOLD — golden ratio resonance
  public func gold(input : Float, resonance : Float) : Float {
    let base = Float.max(S0, input);
    clamp(base * (1.0 + Float.max(0.0, resonance) * (PHI - 1.0) * 0.1))
  };

  // SILVER — full sovereign conductance (σ=1.0, zero lag)
  public func silver(input : Float, conductance : Float, prev : Float) : Float {
    // output(t) = σ·input(t) + (1-σ)·output(t-1)
    // At σ=1.0: output = input, zero lag
    let sigma = Float.min(1.0, Float.max(0.0, conductance));
    clamp(sigma * Float.max(S0, input) + (1.0 - sigma) * Float.max(S0, prev))
  };

  // IRON — strength amplifier with sovereign floor
  public func iron(input : Float, strength : Float) : Float {
    clamp(Float.max(S0, input) * Float.max(S0, strength))
  };

  // COPPER — entanglement bridge (logarithmic entangla scaling)
  public func copper(input : Float, bridge : Float, crossR : Float) : Float {
    // C(x) = x * (1 + ln(E)) where E = entanglaIndex
    let logE = Float.log(Float.max(1.001, Float.abs(bridge)));
    clamp(Float.max(S0, input) * (1.0 + logE * Float.max(S0, crossR) * 0.1))
  };

  // PLATINUM — exact power law: exp(boost * ln(x))
  public func platinum(input : Float, boost : Float) : Float {
    let base = Float.max(S0, input);
    let exp_val = 1.0 + Float.max(0.0, boost) * 0.01;
    clamp(Float.exp(exp_val * Float.log(base)))
  };

  // TITANIUM — exact power 1.1: exp(1.1 * ln(x))  [NOT linear approx]
  public func titanium(input : Float, armor : Float, deflect : Float) : Float {
    let base = Float.max(S0, input);
    let armor_boost = Float.max(0.0, armor) * Float.max(0.0, deflect);
    // True x^1.1 via exp(1.1 * ln(x))
    let powered = Float.exp(1.1 * Float.log(base));
    clamp(powered + armor_boost)
  };

  // CARBON — logistic saturation: x_max * x / (x + K)
  // Prevents unbounded growth while preserving sovereign floor
  public func lithium(input : Float, baseline : Float) : Float {
    let x    = Float.max(S0, input);
    let xmax = 10.0;
    let K    = Float.max(0.1, baseline);
    clamp(xmax * x / (x + K))
  };

  // COBALT — magnetic phase lock
  public func cobalt(input : Float, phase : Float) : Float {
    clamp(Float.max(S0, input) * Float.abs(Float.cos(phase * 3.14159265 / 180.0)) + S0)
  };

  // MERCURY — temporal flux modulator
  public func mercury(input : Float, flux : Float, beat : Nat) : Float {
    clamp(Float.max(S0, input) * (1.0 + Float.max(0.0, flux) * Float.abs(Float.sin((beat : Int).toFloat() * 0.001))))
  };

  // TUNGSTEN — sovereign thermal stability
  public func tungsten(input : Float, heat : Float, formaRate : Float) : Float {
    clamp(Float.max(S0, input) * (1.0 + Float.max(0.0, heat) * Float.max(0.0, formaRate) * 0.001))
  };

  // ZINC — recovery amplifier
  public func zinc(input : Float, recovery : Float, prev : Float) : Float {
    clamp(input + Float.max(0.0, recovery) * Float.max(0.0, 1.0 - Float.min(1.0, prev)))
  };

  // OSMIUM — density × coherence with secondary log boost
  // O(x) = sqrt(x) × mass × coherence + 0.1*ln(x)
  public func osmium(input : Float, mass : Float, coherence : Float) : Float {
    let x = Float.max(S0, input);
    let base = Float.sqrt(x) * Float.max(S0, mass) * Float.max(S0, coherence) * 0.1;
    let log_boost = 0.1 * Float.log(x);
    clamp(base + log_boost)
  };

  // IRIDIUM — Fibonacci resonance: two harmonics sin(x*φ) + sin(x*φ²)
  // (replaces simple resonator)
  func iridium_resonance(x : Float) : Float {
    let phi2 = PHI * PHI;  // ≈ 2.618
    S0 + Float.abs(Float.sin(x * PHI)) + Float.abs(Float.sin(x * phi2)) * 0.5
  };

  // RHODIUM — phase-conjugate mirror reflecting around coherence level
  func rhodium_mirror(x : Float, coherence : Float) : Float {
    let ref = Float.max(S0, coherence);
    clamp(2.0 * ref - x + S0)
  };

  // Apply all 12 metals to a single organ signal
  func applyOne(signal : Float, params : [Float], beat : Nat, coherence : Float, formaRate : Float) : Float {
    let p = func(i : Nat) : Float {
      if (i < params.size()) Float.max(S0, params[i]) else S0
    };
    var v = signal;
    v := gold(v, p(0));                           // GOLD
    v := silver(v, p(1), signal);                 // SILVER (full conductance)
    v := iron(v, p(2));                           // IRON
    v := copper(v, p(3), coherence);              // COPPER
    v := platinum(v, p(4));                       // PLATINUM
    v := titanium(v, p(5), 0.1);                  // TITANIUM (exact x^1.1)
    v := lithium(v, p(6));                        // CARBON/LITHIUM (logistic)
    v := cobalt(v, p(7));                         // COBALT
    v := mercury(v, p(8), beat);                  // MERCURY
    v := tungsten(v, p(9), formaRate);            // TUNGSTEN
    v := zinc(v, p(10), signal);                  // ZINC
    v := osmium(v, p(11), coherence);             // OSMIUM (√x + log boost)
    // Apply Fibonacci resonance (IRIDIUM) and phase mirror (RHODIUM) as final pass
    v := clamp(v * iridium_resonance(v * 0.1));
    v := rhodium_mirror(v, coherence);
    v
  };

  // Apply all metals to all organ signals
  public func applyAll(
    organSignals : [Float],
    metalParams  : [Float],
    beat         : Nat,
    coherence    : Float,
    formaRate    : Float
  ) : [Float] {
    Array.tabulate<Float>(organSignals.size(), func(i) {
      applyOne(organSignals[i], metalParams, beat, coherence, formaRate)
    })
  };

};
