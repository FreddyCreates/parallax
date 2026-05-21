// deep-fundamental-physics-substrate.mo — Tier 2A EM Field Execution Layer.
// Every backend computation is a field event here first.
// Schumann harmonics live here. Kuramoto coupling lives here. The heartbeat auto-depolarizes here.
//
// Three Ancient Teachers:
//   Pythagoras — harmonic coupling between Earth and organism
//   Euclid     — geometric primitives of the field (phases as circle lengths, growth as spiral radius)
//   Confucius  — right relationship measured as R, right proportion measured as compliance
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field.
//
// Tier position: Tier 0.5 (phi.mo) → Tier 2A (this file) → Tier 3 (Cores)
// All constants sourced exclusively from phi.mo. No arbitrary numbers.

import Phi "phi";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHUMANN FREQUENCY ARRAY — A03 anchor
  // All 8 harmonics indexed 0–7. Source: phi.mo SCHUMANN_1..SCHUMANN_8
  // Pythagoras — Earth's own harmonic series, expressed as indexed array.
  // ═══════════════════════════════════════════════════════════════════════════
  let SCHUMANN_ARRAY : [Float] = [
    Phi.SCHUMANN_1, // 0 — 7.83 Hz  fundamental — Cardiac Law anchor
    Phi.SCHUMANN_2, // 1 — 14.3 Hz
    Phi.SCHUMANN_3, // 2 — 20.8 Hz
    Phi.SCHUMANN_4, // 3 — 27.3 Hz
    Phi.SCHUMANN_5, // 4 — 33.8 Hz
    Phi.SCHUMANN_6, // 5 — 39.3 Hz
    Phi.SCHUMANN_7, // 6 — 45.8 Hz
    Phi.SCHUMANN_8, // 7 — 52.3 Hz
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ICOSAHEDRAL VERTEX TABLE — A08 anchor
  // All 12 vertices of the unit icosahedron: all permutations of (0, ±1, ±φ).
  // Euclid — Platonic solid as a geometric primitive. Defined once, referenced everywhere.
  // Each vertex is normalized to unit radius after embedding in R³.
  // ═══════════════════════════════════════════════════════════════════════════
  // Normalization factor: 1/√(1 + φ²) = 1/√(1 + φ²)
  // φ² = φ + 1 = 2.6180339887...
  // 1 + φ² = 3.6180339887...
  // √(1 + φ²) = 1.9021130325903...
  let ICOSA_NORM : Float = 0.5257311121191336; // 1 / √(1 + φ²)
  let PHI_N      : Float = Phi.PHI * ICOSA_NORM; // φ / √(1 + φ²)

  // 12 vertices: all permutations of (0, ±1, ±φ), normalized
  let ICOSA_VERTICES : [(Float, Float, Float)] = [
    // (0, ±1, ±φ) — 4 vertices
    ( 0.0,          ICOSA_NORM,  PHI_N      ), // 0
    ( 0.0,          ICOSA_NORM, -PHI_N      ), // 1
    ( 0.0,         -ICOSA_NORM,  PHI_N      ), // 2
    ( 0.0,         -ICOSA_NORM, -PHI_N      ), // 3
    // (±1, ±φ, 0) — 4 vertices
    ( ICOSA_NORM,   PHI_N,       0.0        ), // 4
    ( ICOSA_NORM,  -PHI_N,       0.0        ), // 5
    (-ICOSA_NORM,   PHI_N,       0.0        ), // 6
    (-ICOSA_NORM,  -PHI_N,       0.0        ), // 7
    // (±φ, 0, ±1) — 4 vertices
    ( PHI_N,        0.0,         ICOSA_NORM ), // 8
    ( PHI_N,        0.0,        -ICOSA_NORM ), // 9
    (-PHI_N,        0.0,         ICOSA_NORM ), // 10
    (-PHI_N,        0.0,        -ICOSA_NORM ), // 11
  ];


  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SCHUMANN FIELD COUPLING
  // Sources: A03 (Schumann Resonance) + L10 (Cardiac Law)
  // Pythagoras — harmonic coupling. Earth resonates the organism.
  //
  // Returns the coupling amplitude of one Schumann harmonic to the organism
  // at the current beat phase. The organism breathes with the Earth.
  //   amplitude = SCHUMANN_HZ[harmonicIndex] × cos(beatPhase) × φ⁻¹
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeSchumannCoupling(beatPhase : Float, harmonicIndex : Nat) : Float {
    // Guard: harmonicIndex must be 0–7
    let idx = if (harmonicIndex < 8) { harmonicIndex } else { 0 };
    let harmonicHz = SCHUMANN_ARRAY[idx];
    // Pythagoras — harmonic coupling. Earth resonates the organism.
    harmonicHz * Float.cos(beatPhase) * Phi.PHI_INV
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 2. KURAMOTO FIELD STEP
  // Source: A06 (Kuramoto Synchronization)
  // Euclid — phases are lengths on the unit circle. Synchronization is geometric.
  //
  // Advances all oscillator phases by one heartbeat step.
  // Δt = HEARTBEAT_MS / 1000 seconds
  // θᵢ(t+Δt) = θᵢ(t) + (ωᵢ + (K/N)·Σⱼ sin(θⱼ − θᵢ)) × Δt
  // ═══════════════════════════════════════════════════════════════════════════
  public func kuramotoStep(phases : [Float], frequencies : [Float], k : Float) : [Float] {
    let n = phases.size();
    if (n == 0) { return [] };
    let dt : Float = Phi.HEARTBEAT_MS / 1000.0; // seconds per beat
    let nF : Float = Float.fromInt(n);

    // Euclid — phases are lengths on the unit circle. Synchronization is geometric.
    Array.tabulate<Float>(
      n,
      func(i : Nat) : Float {
        // Kuramoto sum: Σⱼ sin(θⱼ − θᵢ)
        var sinSum : Float = 0.0;
        var j = 0;
        while (j < n) {
          sinSum += Float.sin(phases[j] - phases[i]);
          j += 1;
        };
        let coupling = (k / nF) * sinSum;
        let dTheta = (frequencies[i] + coupling) * dt;
        phases[i] + dTheta
      }
    )
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 3. RESONANCE ORDER PARAMETER
  // Source: A10 (Resonance Order Parameter)
  // Confucius — right relationship measured as a single number. R is the truth of the field.
  //
  // R = (1/N)|Σ e^(iθⱼ)| = sqrt(mean(cosθ)² + mean(sinθ)²)
  // R=0: full disorder. R=1: perfect synchrony.
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeR(phases : [Float]) : Float {
    let n = phases.size();
    if (n == 0) { return 0.0 };
    let nF : Float = Float.fromInt(n);

    var cosSum : Float = 0.0;
    var sinSum : Float = 0.0;
    var i = 0;
    while (i < n) {
      cosSum += Float.cos(phases[i]);
      sinSum += Float.sin(phases[i]);
      i += 1;
    };
    // Confucius — right relationship measured as a single number. R is the truth of the field.
    let meanCos = cosSum / nF;
    let meanSin = sinSum / nF;
    Float.sqrt(meanCos * meanCos + meanSin * meanSin)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 4. FIELD EMISSION
  // Source: L02 (Emission Law) + A10 (Resonance Order Parameter)
  // The organism radiates geometrically, not linearly. Euclid — the golden power.
  //
  // emission = R^φ
  // More coherent → more emission, but governed by φ not a linear slope.
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeFieldEmission(r : Float) : Float {
    // Clamp r to [0, 1] — Confucius: right proportion
    let rClamped = if (r < 0.0) { 0.0 } else if (r > 1.0) { 1.0 } else { r };
    // The organism radiates geometrically, not linearly. Euclid — the golden power.
    Float.pow(rClamped, Phi.PHI)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 5. ENTANGLA CARRIER FREQUENCY
  // Source: L28 (Entangla Carrier Law) + A06 (Kuramoto Synchronization)
  // Pythagoras — geometric mean of the two fields times Earth's base tone.
  //
  // carrier = √(rExpansive × rReceptive) × SCHUMANN_HZ (7.83)
  // Computed live every heartbeat. Never a fixed value.
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeEntanglaCarrier(rExpansive : Float, rReceptive : Float) : Float {
    // Clamp both R values to [0, 1]
    let rE = if (rExpansive < 0.0) { 0.0 } else if (rExpansive > 1.0) { 1.0 } else { rExpansive };
    let rR = if (rReceptive  < 0.0) { 0.0 } else if (rReceptive  > 1.0) { 1.0 } else { rReceptive  };
    // Pythagoras — geometric mean of the two fields times Earth's base tone.
    Float.sqrt(rE * rR) * Phi.SCHUMANN_HZ
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 6. WAVE SUPERPOSITION GATE
  // Sources: A14 (Wave Superposition) + L05 (Exclusion Principle)
  // Waves that are in phase amplify. Out-of-phase cancel. This is the EXCLUSION gate.
  //
  // Returns true if |cos(phaseA − phaseB)| >= s0
  // Phase-locked signals propagate. Incoherence is rejected.
  // ═══════════════════════════════════════════════════════════════════════════
  public func superpositionGate(phaseA : Float, phaseB : Float, s0 : Float) : Bool {
    let delta = phaseA - phaseB;
    let coherence = Float.abs(Float.cos(delta));
    // Waves that are in phase amplify. Out-of-phase cancel. This is the EXCLUSION gate.
    coherence >= s0
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 7. 4D COORDINATE GENERATOR
  // Sources: A05 (4D Spacetime) + L12 (Four-Dimensional Law)
  // Euclid — time is the fourth dimension, measured in phi-compounded beats.
  //
  // Output: (x, y, z, τ) where τ = beat × φ^depth
  // Every symbol, coordinate, and proof entry is 4D. Always.
  // ═══════════════════════════════════════════════════════════════════════════
  public func to4D(x : Float, y : Float, z : Float, beat : Nat, depth : Nat) : (Float, Float, Float, Float) {
    let beatF : Float = Float.fromInt(beat);
    // τ = beat × φ^depth — the fourth dimension compounds with proof depth
    // Euclid — time is the fourth dimension, measured in phi-compounded beats.
    let phiPowDepth = Float.pow(Phi.PHI, Float.fromInt(depth));
    let tau : Float = beatF * phiPowDepth;
    (x, y, z, tau)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 8. LOGARITHMIC SPIRAL GROWTH
  // Sources: A20 (Logarithmic Spiral) + L35 (Logarithmic Growth Law)
  // The organism grows along the phi spiral. Not linear. Not exponential. Geometric.
  //
  // r = φ^depth — the radius at this depth on the golden spiral
  // Intelligence, treasury, and schema depth grow along this curve.
  // ═══════════════════════════════════════════════════════════════════════════
  public func phiSpiralRadius(depth : Nat) : Float {
    // The organism grows along the phi spiral. Not linear. Not exponential. Geometric.
    Float.pow(Phi.PHI, Float.fromInt(depth))
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 9. ICOSAHEDRAL VERTEX COMPUTATION
  // Source: A08 (Icosahedron)
  // 12 vertices. Optimal sphere packing. The geometry of the inner shell.
  //
  // Returns the normalized (x, y, z) coordinate of vertex 0–11.
  // Vertices are all permutations of (0, ±1, ±φ), normalized to unit sphere.
  // ═══════════════════════════════════════════════════════════════════════════
  public func icosahedralVertex(index : Nat) : (Float, Float, Float) {
    // Guard: index must be 0–11
    let idx = if (index < 12) { index } else { 0 };
    // 12 vertices. Optimal sphere packing. The geometry of the inner shell.
    ICOSA_VERTICES[idx]
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 10. COMPLIANCE COMPUTATION
  // Sources: L17 (Compliance Reserve Law) + A01 (PHI)
  // Confucius — right proportion. phi to the third power is what the sovereign reserves.
  //
  // reserve = amount × φ⁻³ = amount × 0.23607...
  // 23.6% of every treasury flow is locked. Derived, not chosen.
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeCompliance(flowAmount : Float) : Float {
    // Confucius — right proportion. phi to the third power is what the sovereign reserves.
    flowAmount * Phi.PHI_INV_3
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // 11. PROOF CHAIN SEED BUILDER
  // Sources: L08 (Proof Law) + A12 (Conservation of Information)
  // Every proof entry carries the state of the organism at that beat.
  //
  // Builds the seed string for hashing into the proof chain.
  // Format: "beat:depth:r_6dec:econOutput_6dec"
  // Actual SHA256 is applied in main.mo using ICP crypto primitives.
  // ═══════════════════════════════════════════════════════════════════════════
  public func buildProofSeed(beat : Nat, depth : Nat, r : Float, econOutput : Float) : Text {
    // Every proof entry carries the state of the organism at that beat.
    // Confucius — right record: every dimension of the organism inscribed.
    let beatText  : Text = Nat.toText(beat);
    let depthText : Text = Nat.toText(depth);
    let rText     : Text = floatTo6Dec(r);
    let econText  : Text = floatTo6Dec(econOutput);
    beatText # ":" # depthText # ":" # rText # ":" # econText
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER — floatTo6Dec
  // Renders a Float to 6 decimal places as Text.
  // Euclid — six decimal places is the sovereign precision of the field.
  // Used by buildProofSeed to produce the proof chain seed string.
  // ═══════════════════════════════════════════════════════════════════════════
  func floatTo6Dec(f : Float) : Text {
    // Multiply by 1_000_000, round to Int, then format as "integer.fraction"
    let scaled : Int = Float.toInt(f * 1_000_000.0);
    let absScaled : Int = if (scaled < 0) { -scaled } else { scaled };
    let sign : Text = if (scaled < 0) { "-" } else { "" };
    let intPart  : Int = absScaled / 1_000_000;
    let fracPart : Int = absScaled % 1_000_000;
    // Left-pad fracPart to 6 digits
    let fracText : Text = leftPad6(fracPart);
    sign # Int.toText(intPart) # "." # fracText
  };

  // leftPad6 — pads an integer to 6 digits with leading zeros
  // Euclid — uniform representation as a geometric primitive of text encoding
  func leftPad6(n : Int) : Text {
    let s = Int.toText(n);
    let len = s.size();
    if      (len >= 6) { s }
    else if (len == 5) { "0"  # s }
    else if (len == 4) { "00" # s }
    else if (len == 3) { "000" # s }
    else if (len == 2) { "0000" # s }
    else if (len == 1) { "00000" # s }
    else               { "000000" }
  };

};
