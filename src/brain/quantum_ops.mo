// =============================================================================
// QUANTUM OPS MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 7 quantum operators on classical hardware with quantum-inspired mathematics.
//
// MATH SYSTEMS IMPLEMENTED:
//   QOP1: PARALLAX ANGLE — angular distance (arccos) with proper range clamp
//   QOP2: ENTANGLA INDEX — normalized mutual information approximation
//         using cross-correlation and entropy estimates
//   QOP3: BYPASS GATE — superposition 3-path routing with interference term
//   QOP4: RESONEX FIELD — weighted spectral power density
//   QOP5: QMEM RING — 7-state density matrix (diagonal) simulation
//         with Von Neumann entropy measure
//   QOP6: CHRONO DILATION — already in main.mo, referenced here
//   QOP7: VERITAS COHERENCE — weighted compliance with law tier importance
//
// DENSITY MATRIX (QOP5):
//   ρ = diag(p_0, ..., p_6)  where p_k = C_k / Σ C_k (normalized)
//   Von Neumann entropy: S(ρ) = -Σ_k p_k * log(p_k)
//   Coherence prediction: C_pred = Σ_k p_k * C_k * exp(-S(ρ)/log(7))
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module QuantumOps {

  let S0        : Float = 1.0;
  let PI        : Float = 3.14159265358979323846;
  let TAU       : Float = 6.28318530717958647692;
  let QMEM_SIZE : Nat   = 7;
  let LOG7      : Float = 1.94591014906;  // ln(7)

  public type QuantumState = {
    parallax_angle  : Float;  // [0, pi]
    entangla_index  : Float;  // >= S0
    bypass_active   : Bool;
    bypass_output   : Float;  // blended signal from BYPASS gate
    resonex_field   : Float;
    qmem_coherence  : Float;  // predicted coherence from density matrix
    vn_entropy      : Float;  // Von Neumann entropy of QMEM ring
    chrono_dilation : Float;
    veritas_coh     : Float;
    entangla_entropy : Float; // Shannon entropy of cross-correlation distribution
  };

  func sfloor(x : Float) : Float { if (x < S0) S0 else x };

  func sin_approx(x : Float) : Float {
    var r = x;
    let cyc = Float.fromInt(Float.toInt(r / TAU));
    r := r - cyc * TAU;
    if (r > PI)  { r := r - TAU };
    if (r < -PI) { r := r + TAU };
    let x2 = r * r; let x3 = x2 * r; let x5 = x3 * x2; let x7 = x5 * x2;
    r - x3/6.0 + x5/120.0 - x7/5040.0
  };

  func cos_approx(x : Float) : Float { sin_approx(x + PI / 2.0) };

  func dot(a : [Float], b : [Float], n : Nat) : Float {
    var s = 0.0; var i = 0;
    while (i < n) { s += a[i] * b[i]; i += 1; }; s
  };

  func norm_sq(a : [Float], n : Nat) : Float {
    var s = 0.0; var i = 0;
    while (i < n) { s += a[i] * a[i]; i += 1; }; s
  };

  // arccos via Newton-Raphson: 2 iterations from initial estimate
  // Initial: arccos(x) ≈ pi/2 - arcsin(x), arcsin(x) ≈ polynomial
  func arccos_approx(x : Float) : Float {
    let cx = if (x > 1.0) 1.0 else if (x < -1.0) -1.0 else x;
    // For |x| close to 1, use sqrt-based formula: arccos(x) ≈ sqrt(2(1-x))
    if (Float.abs(cx) > 0.9) {
      let t = 2.0 * (1.0 - Float.abs(cx));
      let ang = Float.sqrt(t) * (1.0 + t / 12.0 + 3.0*t*t/160.0);
      if (cx > 0.0) ang else PI - ang
    } else {
      // Standard polynomial approximation for mid-range
      let x2 = cx * cx; let x3 = x2 * cx; let x5 = x3 * x2;
      let arcsin = cx + x3/6.0 + 3.0*x5/40.0;
      PI / 2.0 - arcsin
    }
  };

  // Shannon entropy of a probability vector
  func shannon_entropy(probs : [Float]) : Float {
    var h = 0.0;
    var i = 0;
    while (i < probs.size()) {
      let p = probs[i];
      if (p > 0.0001) {
        h := h - p * Float.log(p);
      };
      i += 1;
    };
    h
  };

  // ===========================================================================
  // QOP1: PARALLAX ANGLE
  // Angular distance between Shell 0 (ALPHA) and Shell 2 (GAMMA)
  // θ = arccos( a·b / (|a| * |b|) )  ∈ [0, π]
  // ===========================================================================
  func parallax_angle(
    allActs  : [Float],
    maxNodes : Nat
  ) : Float {
    let n = maxNodes;
    let s1 = Array.tabulate<Float>(n, func(i) { allActs[0*maxNodes + i] });
    let s2 = Array.tabulate<Float>(n, func(i) { allActs[2*maxNodes + i] });
    let d  = dot(s1, s2, n);
    let n1 = Float.sqrt(norm_sq(s1, n));
    let n2 = Float.sqrt(norm_sq(s2, n));
    if (n1 < 0.001 or n2 < 0.001) { PI / 2.0 } else {
      arccos_approx(d / (n1 * n2))
    }
  };

  // ===========================================================================
  // QOP2: ENTANGLA INDEX (EXPANDED)
  //
  // Computes normalized mutual information approximation:
  //   For each shell pair (s1, s2):
  //     corr(s1,s2) = |dot(a_s1, a_s2)| / (|a_s1| * |a_s2|)
  //   Distribution: p[k] = corr[k] / Σ corr[k]
  //   Shannon entropy: H = -Σ p[k] log p[k]
  //   Max entropy: H_max = log(N_pairs)
  //   Normalized MI proxy: NMI = (H_max - H) / H_max
  //   Entangla index: E = max(S0, 1 + NMI * 2.0)
  //     High E → shells are highly correlated (entangled)
  //     Low E  → shells are independent
  // ===========================================================================
  func entangla_index(
    allActs   : [Float],
    maxNodes  : Nat,
    shellCount : Nat
  ) : { index : Float; entropy : Float } {
    let pairs : [(Nat,Nat)] = [(0,1),(0,2),(1,3),(2,4),(3,5),(4,6),(5,7),(6,8),(7,9),(8,10)];
    let nPairs = pairs.size();
    let corrs = Array.init<Float>(nPairs, 0.0);
    var total = 0.0;
    var pi = 0;
    while (pi < nPairs) {
      let (s1, s2) = pairs[pi];
      if (s1 < shellCount and s2 < shellCount) {
        let a  = Array.tabulate<Float>(maxNodes, func(i) { allActs[s1*maxNodes + i] });
        let b  = Array.tabulate<Float>(maxNodes, func(i) { allActs[s2*maxNodes + i] });
        let n1 = Float.sqrt(norm_sq(a, maxNodes));
        let n2 = Float.sqrt(norm_sq(b, maxNodes));
        if (n1 > 0.001 and n2 > 0.001) {
          let c = Float.abs(dot(a, b, maxNodes) / (n1 * n2));
          corrs[pi] := c;
          total := total + c;
        } else {
          corrs[pi] := 0.0;
        };
      };
      pi += 1;
    };

    // Normalize to probability distribution
    let probs = Array.init<Float>(nPairs, 0.0);
    if (total > 0.001) {
      var k = 0;
      while (k < nPairs) { probs[k] := corrs[k] / total; k += 1; };
    } else {
      // Uniform distribution
      let unif = 1.0 / Float.fromInt(nPairs);
      var k = 0;
      while (k < nPairs) { probs[k] := unif; k += 1; };
    };

    let h       = shannon_entropy(Array.freeze(probs));
    let h_max   = Float.log(Float.fromInt(nPairs));
    let nmi     = if (h_max < 0.001) 0.0 else (h_max - h) / h_max;
    let e_index = sfloor(1.0 + nmi * 2.0);

    { index = e_index; entropy = h }
  };

  // ===========================================================================
  // QOP3: BYPASS GATE (EXPANDED WITH INTERFERENCE)
  //
  // 3-path superposition with constructive/destructive interference:
  //   path_1 = x * 1.0                     (direct)
  //   path_2 = x * 0.5 + C * 0.5           (coherence-blended)
  //   path_3 = x * neuroAvg               (neurochemically modulated)
  //
  //   interference = cos(parallax_angle) * (path_1 - path_2)
  //   output = (path_1 + path_2 + path_3 + interference) / 3.5
  //
  //   Constructive when parallax_angle is small (shells aligned)
  //   Destructive when parallax_angle is large (shells opposed)
  // ===========================================================================
  public func bypass(
    signal         : Float,
    coherence      : Float,
    neuroAvg       : Float,
    cortisol       : Float,
    parallax_angle : Float
  ) : { active : Bool; output : Float } {
    let active = cortisol > 2.0;
    let path1 = signal;
    let path2 = signal * 0.5 + coherence * 0.5;
    let path3 = signal * neuroAvg;
    let interference = cos_approx(parallax_angle) * (path1 - path2);
    let out   = (path1 + path2 + path3 + interference) / 3.5;
    { active = active; output = sfloor(out) }
  };

  // ===========================================================================
  // QOP4: RESONEX FIELD (SPECTRAL POWER DENSITY)
  //
  // Φ = Σ_s R[s] * meanAct[s] * freq[s]^2 / Σ_s freq[s]^2
  //
  // Using frequency-squared weighting: high-frequency shells (OMNIS=108Hz,
  // LAMBDA=80Hz) contribute more to the field, reflecting their role as
  // high-bandwidth integrators.
  // ===========================================================================
  func resonex_field(
    kuramotoR : [Float],
    meanActs  : [Float],
    freqs     : [Float],
    nShells   : Nat
  ) : Float {
    var num = 0.0; var den = 0.0;
    var s = 0;
    while (s < nShells) {
      let f2 = freqs[s] * freqs[s];
      num := num + kuramotoR[s] * meanActs[s] * f2;
      den := den + f2;
      s += 1;
    };
    if (den < 0.001) { S0 } else { sfloor(num / den) }
  };

  // ===========================================================================
  // QOP5: QMEM RING — DENSITY MATRIX SIMULATION (EXPANDED)
  //
  // Classical simulation of 7-state quantum memory:
  //   ρ = diag(p_0, ..., p_6)  (diagonal density matrix)
  //   p_k = (C_k - S0) / Σ_k(C_k - S0) if Σ > 0 else 1/7
  //
  //   Von Neumann entropy: S(ρ) = -Σ_k p_k ln(p_k)
  //   Purity: Tr(ρ²) = Σ_k p_k²
  //
  //   Coherence prediction:
  //     C_pred = (Σ_k p_k * C_k) * exp(-S(ρ)/ln(7)) * tDilation
  //   This means: near-pure state → prediction close to best episode
  //               mixed state     → prediction reverts toward mean
  // ===========================================================================
  public func qmem_update(
    ring      : [var Float],
    coherence : Float,
    beatCount : Nat,
    tDilation : Float
  ) : { predicted_coherence : Float; vn_entropy : Float } {
    // Write new coherence
    ring[beatCount % QMEM_SIZE] := coherence;

    // Compute probability distribution (shift by S0 to get non-negative)
    var total_excess = 0.0;
    var k = 0;
    while (k < QMEM_SIZE) {
      let excess = if (ring[k] > S0) ring[k] - S0 else 0.0;
      total_excess := total_excess + excess;
      k += 1;
    };

    let probs = Array.init<Float>(QMEM_SIZE, 0.0);
    if (total_excess > 0.001) {
      k := 0;
      while (k < QMEM_SIZE) {
        let excess = if (ring[k] > S0) ring[k] - S0 else 0.0;
        probs[k] := excess / total_excess;
        k += 1;
      };
    } else {
      // Uniform: maximum entropy state
      k := 0;
      while (k < QMEM_SIZE) {
        probs[k] := 1.0 / Float.fromInt(QMEM_SIZE);
        k += 1;
      };
    };

    // Von Neumann entropy
    let vn_ent = shannon_entropy(Array.freeze(probs));

    // Coherence prediction: expectation value weighted by purity
    var expected_c = 0.0;
    k := 0;
    while (k < QMEM_SIZE) {
      expected_c := expected_c + probs[k] * ring[k];
      k += 1;
    };
    // Scale by purity factor: exp(-S/ln7) → 1.0 at pure, → 1/7 at max entropy
    let purity_factor = Float.exp(-(vn_ent / LOG7));
    let c_pred = sfloor(expected_c * purity_factor * tDilation);

    { predicted_coherence = c_pred; vn_entropy = vn_ent }
  };

  // ===========================================================================
  // QOP7: VERITAS COHERENCE (EXPANDED)
  // Tier-weighted compliance: higher tiers carry more weight.
  // Tier 5 (sovereignty) weighted 3x, Tier 4 (world) 2x, others 1x.
  // VC = Σ_t weight[t] * mean(compliance[tier_t]) / Σ_t weight[t]
  // ===========================================================================
  func veritas_coherence(complianceVec : [Float]) : Float {
    if (complianceVec.size() < 60) { return S0; };
    // Tier boundaries: 0-9, 10-19, 20-29, 30-39, 40-49, 50-59
    let tier_weights : [Float] = [1.0, 1.0, 1.5, 1.5, 2.0, 3.0];
    var weighted_sum = 0.0;
    var weight_total = 0.0;
    var t = 0;
    while (t < 6) {
      let start = t * 10;
      var tier_sum = 0.0;
      var k = start;
      while (k < start + 10) {
        tier_sum := tier_sum + complianceVec[k];
        k += 1;
      };
      let tier_mean = tier_sum / 10.0;
      let wt = tier_weights[t];
      weighted_sum := weighted_sum + wt * tier_mean;
      weight_total := weight_total + wt;
      t += 1;
    };
    sfloor(weighted_sum / weight_total)
  };

  // ===========================================================================
  // FULL UPDATE
  // ===========================================================================
  public func update(
    allActs        : [Float],
    kuramotoR      : [Float],
    meanActs       : [Float],
    freqs          : [Float],
    neuroVec       : [Float],
    qmemRing       : [var Float],
    beatCount      : Nat,
    cortisol       : Float,
    tDilation      : Float,
    complianceVec  : [Float],
    maxNodes       : Nat,
    shellCount     : Nat,
    globalCoh      : Float
  ) : QuantumState {
    let pAngle = parallax_angle(allActs, maxNodes);
    let eResult = entangla_index(allActs, maxNodes, shellCount);

    let neuroAvg = if (neuroVec.size() == 0) { S0 } else {
      var t = 0.0; var i = 0;
      while (i < neuroVec.size()) { t := t + neuroVec[i]; i += 1; };
      t / Float.fromInt(neuroVec.size())
    };

    let bypassResult = bypass(globalCoh, globalCoh, neuroAvg, cortisol, pAngle);
    let rField = resonex_field(kuramotoR, meanActs, freqs, shellCount);
    let qmemResult = qmem_update(qmemRing, globalCoh, beatCount, tDilation);
    let vCoh = veritas_coherence(complianceVec);

    {
      parallax_angle   = pAngle;
      entangla_index   = eResult.index;
      bypass_active    = bypassResult.active;
      bypass_output    = bypassResult.output;
      resonex_field    = rField;
      qmem_coherence   = qmemResult.predicted_coherence;
      vn_entropy       = qmemResult.vn_entropy;
      chrono_dilation  = tDilation;
      veritas_coh      = vCoh;
      entangla_entropy = eResult.entropy;
    }
  };

  public func init_qmem_ring() : [var Float] {
    Array.init<Float>(QMEM_SIZE, S0)
  };

}
