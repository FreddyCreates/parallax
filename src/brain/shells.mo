// =============================================================================
// SHELLS MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 11 neural shells: ALPHA, BETA, GAMMA, DELTA, THETA, SIGMA, LAMBDA,
// EPSILON, DEEP, HERITAGE, OMNIS
//
// MATH SYSTEMS IMPLEMENTED:
//   1. Hebbian weight update with Oja's regularization term
//   2. Spike-timing-dependent plasticity (STDP) additive component
//   3. Full Kuramoto phase dynamics with second-order coupling
//   4. Spectral coherence (mean-field approximation)
//   5. Global coherence with spectral radius weighting
//   6. Inter-shell lateral inhibition matrix
//   7. Sovereign floor S0=1.0 on ALL outputs
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module Shells {

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  public let S0          : Float = 1.0;
  public let SHELL_COUNT : Nat   = 11;
  public let MAX_NODES   : Nat   = 36;
  public let K_COUPLING  : Float = 0.1;    // Kuramoto coupling constant
  public let K2_COUPLING : Float = 0.02;   // second-order Kuramoto correction
  public let PI          : Float = 3.14159265358979323846;
  public let TAU         : Float = 6.28318530717958647692;
  public let ETA_BASE    : Float = 0.01;   // base Hebbian learning rate
  public let OJA_LAMBDA  : Float = 0.001;  // Oja regularization coefficient
  public let STDP_AP     : Float = 0.005;  // STDP potentiation amplitude
  public let STDP_AD     : Float = 0.003;  // STDP depression amplitude
  public let STDP_TAU_P  : Float = 20.0;   // STDP potentiation time constant
  public let STDP_TAU_D  : Float = 40.0;   // STDP depression time constant
  public let LATERAL_INH : Float = 0.05;   // inter-shell lateral inhibition

  // Node counts per shell (index 0..10)
  // ALPHA=8, BETA=16, GAMMA=32, DELTA=8, THETA=16, SIGMA=16,
  // LAMBDA=8, EPSILON=16, DEEP=36, HERITAGE=24, OMNIS=36
  public let NODE_COUNTS : [Nat] = [8, 16, 32, 8, 16, 16, 8, 16, 36, 24, 36];

  // Shell frequencies in Hz
  public let FREQUENCIES : [Float] = [
    8.0, 14.0, 40.0, 2.0, 6.0, 12.0, 80.0, 0.1, 0.0, 0.0, 108.0
  ];

  // ===========================================================================
  // MATH HELPERS
  // ===========================================================================

  // tanh approximation using rational Padé [5/4]: more accurate than x/(1+|x|)
  // tanh(x) ≈ x(1 + x²/9) / (1 + x²(4/9 + x²/63))  for |x| < 4
  // Outside that range, saturate to ±1 with sovereign floor applied after
  public func tanh_pade(x : Float) : Float {
    let ax = Float.abs(x);
    if (ax > 4.0) {
      if (x > 0.0) 1.0 else -1.0
    } else {
      let x2 = x * x;
      let num = x * (1.0 + x2 / 9.0);
      let den = 1.0 + x2 * (4.0 / 9.0 + x2 / 63.0);
      num / den
    }
  };

  // sin approximation via Taylor series (5 terms) after range reduction to [-pi, pi]
  public func sin_approx(x : Float) : Float {
    var r = x;
    let cycles = Float.fromInt(Float.toInt(r / TAU));
    r := r - cycles * TAU;
    if (r > PI)  { r := r - TAU };
    if (r < -PI) { r := r + TAU };
    let x2 = r * r;
    let x3 = x2 * r;
    let x5 = x3 * x2;
    let x7 = x5 * x2;
    let x9 = x7 * x2;
    r - x3/6.0 + x5/120.0 - x7/5040.0 + x9/362880.0
  };

  public func cos_approx(x : Float) : Float {
    sin_approx(x + PI / 2.0)
  };

  // exp approximation: split into integer + fractional, use Padé for fractional
  // For large values use Float.exp (ICP supports it via native ops)
  // We keep Float.exp here — it IS available in Motoko base
  // but sin/cos we approximate ourselves to match sovereign spec.

  // Sovereign floor: no value falls below S0 = 1.0
  public func sfloor(x : Float) : Float {
    if (x < S0) S0 else x
  };

  // Soft upper clamp to prevent runaway activation (sovereign ceiling at 100*S0)
  public func sclamp(x : Float) : Float {
    let lo = sfloor(x);
    if (lo > 100.0) 100.0 else lo
  };

  // ===========================================================================
  // HEBBIAN + OJA'S RULE + STDP
  //
  // Full update equation:
  //
  //   Hebbian:  Δw_ij  = η * (a_i - w_ij)(a_j - w_ij)           [original]
  //   Oja reg:  Δw_ij -= λ * w_ij * a_i²                         [prevents explosion]
  //   STDP:     Δw_ij += A+ * exp(-|Δt|/τ+)  if pre before post  [potentiation]
  //             Δw_ij -= A- * exp(-|Δt|/τ-)  if post before pre  [depression]
  //
  //   Δt proxy: sign(a_i - a_j) * mean(|a_i - a_j|)
  //             positive → i fires before j → potentiation
  //             negative → j fires before i → depression
  //
  // Combined: w[i][j] = max(S0, w[i][j] + Δw_Hebb + Δw_Oja + Δw_STDP)
  // ===========================================================================
  public func hebbian_update(
    weights     : [var Float],
    activations : [var Float],
    nodeCount   : Nat,
    organInputs : [Float],
    metalBias   : Float,
    bdnfLevel   : Float,
    neuroMod    : Float
  ) : () {
    // Effective learning rate: boosted by BDNF, modulated by general neuro state
    let eta = ETA_BASE * (1.0 + 0.5 * (bdnfLevel - S0)) * neuroMod;

    // Step 1: compute new activations via recurrent input + organ bias
    let newActs = Array.init<Float>(MAX_NODES, S0);
    var i = 0;
    while (i < nodeCount) {
      var weighted_sum = 0.0;
      var j = 0;
      while (j < nodeCount) {
        weighted_sum += weights[i * MAX_NODES + j] * activations[j];
        j += 1;
      };
      let organ_in = if (i < organInputs.size()) organInputs[i] else S0;
      // Activation = S0 + tanh(Σw*a + organ + bias) shifted so minimum is S0
      let raw = tanh_pade(weighted_sum + organ_in + metalBias);
      newActs[i] := sclamp(S0 + raw);
      i += 1;
    };

    // Step 2: copy new activations back
    i := 0;
    while (i < nodeCount) {
      activations[i] := newActs[i];
      i += 1;
    };

    // Step 3: combined weight update
    i := 0;
    while (i < nodeCount) {
      let ai = activations[i];
      let ai2 = ai * ai;   // for Oja term
      var j = 0;
      while (j < nodeCount) {
        let aj = activations[j];
        let w  = weights[i * MAX_NODES + j];

        // --- Hebbian component ---
        let dw_hebb = eta * (ai - w) * (aj - w);

        // --- Oja's regularization: prevents weight explosion ---
        // Δw_Oja = -λ * w * a_i²
        let dw_oja = -(OJA_LAMBDA * w * ai2);

        // --- STDP component ---
        // Δt proxy: (ai - aj), positive means i leads j
        let dt_proxy = ai - aj;
        let dw_stdp = if (dt_proxy > 0.0) {
          // pre before post: potentiation
          STDP_AP * Float.exp(-(dt_proxy) / STDP_TAU_P)
        } else if (dt_proxy < 0.0) {
          // post before pre: depression
          -(STDP_AD * Float.exp((dt_proxy) / STDP_TAU_D))
        } else { 0.0 };

        weights[i * MAX_NODES + j] := sfloor(w + dw_hebb + dw_oja + dw_stdp);
        j += 1;
      };
      i += 1;
    };
  };

  // ===========================================================================
  // KURAMOTO PHASE DYNAMICS (SECOND-ORDER EXTENDED)
  //
  // Standard Kuramoto:
  //   dφ_i/dt = ω_i + (K/N) Σ_j sin(φ_j - φ_i)
  //
  // Second-order correction (velocity-dependent coupling):
  //   dφ_i/dt += (K2/N) Σ_j sin(2*(φ_j - φ_i))   [higher harmonic]
  //
  // Phase velocity damping (soft friction):
  //   φ_i(t+1) = φ_i(t) + Δφ_i * (1 - friction * |Δφ_i|)
  //   friction = 0.01
  //
  // Returns R: Kuramoto order parameter ∈ [0, 1]
  //   R = (1/N)|Σ_i exp(iφ_i)| = (1/N)√(Σcos²φ + Σsin²φ)
  //
  // Also returns Ψ: mean phase (not stored, used internally)
  // ===========================================================================
  public func kuramoto_update(
    phases    : [var Float],
    nodeCount : Nat,
    frequency : Float
  ) : Float {
    let omega    = frequency * TAU / 500.0;
    let nF       = Float.fromInt(nodeCount);
    let kOverN   = K_COUPLING / nF;
    let k2OverN  = K2_COUPLING / nF;
    let friction : Float = 0.01;

    // Precompute sin/cos of all phases (avoids recomputation in inner loop)
    let sinPhi = Array.init<Float>(MAX_NODES, 0.0);
    let cosPhi = Array.init<Float>(MAX_NODES, 0.0);
    var i = 0;
    while (i < nodeCount) {
      sinPhi[i] := sin_approx(phases[i]);
      cosPhi[i] := cos_approx(phases[i]);
      i += 1;
    };

    // Compute phase increments
    let newPhases = Array.init<Float>(MAX_NODES, 0.0);
    i := 0;
    while (i < nodeCount) {
      var coupling1 = 0.0;  // first harmonic
      var coupling2 = 0.0;  // second harmonic
      var j = 0;
      while (j < nodeCount) {
        let dphi = phases[j] - phases[i];
        coupling1 += sin_approx(dphi);
        coupling2 += sin_approx(2.0 * dphi);
        j += 1;
      };
      let delta_phi = omega + kOverN * coupling1 + k2OverN * coupling2;
      // Apply soft friction damping
      let damped = delta_phi * (1.0 - friction * Float.abs(delta_phi));
      newPhases[i] := phases[i] + damped;
      i += 1;
    };

    // Write back
    i := 0;
    while (i < nodeCount) {
      phases[i] := newPhases[i];
      i += 1;
    };

    // Compute R (Kuramoto order parameter)
    var sum_cos = 0.0;
    var sum_sin = 0.0;
    i := 0;
    while (i < nodeCount) {
      sum_cos += cos_approx(phases[i]);
      sum_sin += sin_approx(phases[i]);
      i += 1;
    };
    let cx = sum_cos / nF;
    let cy = sum_sin / nF;
    let r  = Float.sqrt(cx * cx + cy * cy);
    if (r < 0.0) 0.0 else if (r > 1.0) 1.0 else r
  };

  // ===========================================================================
  // SPECTRAL COHERENCE
  // Measures the spread of the activation distribution relative to its mean.
  // Based on coefficient-of-variation inverse:
  //   SC = mean(a) / (std(a) + ε)
  // High SC → activations are tightly packed (coherent)
  // Low SC  → activations are spread (incoherent)
  // Returns value in [S0, ∞)
  // ===========================================================================
  public func spectral_coherence(activations : [var Float], nodeCount : Nat) : Float {
    if (nodeCount == 0) { return S0; };
    let nF = Float.fromInt(nodeCount);

    // Mean
    var mu = 0.0;
    var i = 0;
    while (i < nodeCount) { mu += activations[i]; i += 1; };
    mu := mu / nF;

    // Variance
    var variance = 0.0;
    i := 0;
    while (i < nodeCount) {
      let d = activations[i] - mu;
      variance += d * d;
      i += 1;
    };
    variance := variance / nF;
    let std_dev = Float.sqrt(variance);

    sfloor(mu / (std_dev + 0.001))
  };

  // ===========================================================================
  // MEAN ACTIVATION for a shell
  // ===========================================================================
  public func mean_activation(activations : [var Float], nodeCount : Nat) : Float {
    if (nodeCount == 0) { return S0; };
    var s = 0.0;
    var i = 0;
    while (i < nodeCount) {
      s += activations[i];
      i += 1;
    };
    sfloor(s / Float.fromInt(nodeCount))
  };

  // ===========================================================================
  // LATERAL INHIBITION BETWEEN SHELLS
  // When shell s1 has high coherence, it mildly suppresses neighboring shells.
  // This is a winner-take-all mechanism at the shell level.
  //
  // inhibition[s] = LATERAL_INH * mean(R[other shells])
  // Applied as: meanActs[s] *= (1.0 - inhibition[s])
  // Sovereign floor applied after.
  // ===========================================================================
  public func apply_lateral_inhibition(
    meanActsIn : [Float],
    kuramotoR  : [Float]
  ) : [Float] {
    let n = SHELL_COUNT;
    let out = Array.init<Float>(n, S0);
    var s = 0;
    while (s < n) {
      // Sum R of all OTHER shells
      var sumR = 0.0;
      var k = 0;
      while (k < n) {
        if (k != s) { sumR += kuramotoR[k]; };
        k += 1;
      };
      let inhibition = LATERAL_INH * (sumR / Float.fromInt(n - 1));
      out[s] := sfloor(meanActsIn[s] * (1.0 - inhibition));
      s += 1;
    };
    Array.freeze(out)
  };

  // ===========================================================================
  // GLOBAL COHERENCE (EXPANDED)
  //
  // C = max(S0, (1/11) * Σ_s [ R[s] * meanAct[s] * spectralCoherence[s] ]
  //              * (1 + nitric_oxide_boost) )
  //
  // spectralCoherence is passed in as precomputed vector
  // nitric_oxide_boost: small positive signal from NO (neurochemical 20)
  // ===========================================================================
  public func compute_global_coherence(
    kuramotoR      : [Float],
    meanActs       : [Float],
    spectralCoh    : [Float],
    nitricOxideLvl : Float
  ) : Float {
    var s = 0.0;
    var i = 0;
    while (i < SHELL_COUNT) {
      let sc = if (i < spectralCoh.size()) spectralCoh[i] else S0;
      s += kuramotoR[i] * meanActs[i] * sc;
      i += 1;
    };
    let raw = (s / Float.fromInt(SHELL_COUNT)) * (1.0 + 0.05 * (nitricOxideLvl - S0));
    sfloor(raw)
  };

  // ===========================================================================
  // INIT FUNCTIONS
  // ===========================================================================

  public func init_weights() : [var Float] {
    Array.init<Float>(MAX_NODES * MAX_NODES, S0)
  };

  public func init_activations() : [var Float] {
    Array.init<Float>(MAX_NODES, S0)
  };

  public func init_phases() : [var Float] {
    // Initialize phases slightly staggered to break symmetry
    // phi_i = (i / MAX_NODES) * 2*pi
    let ph = Array.init<Float>(MAX_NODES, 0.0);
    var i = 0;
    while (i < MAX_NODES) {
      ph[i] := Float.fromInt(i) * TAU / Float.fromInt(MAX_NODES);
      i += 1;
    };
    ph
  };

  public func init_spectral_coh() : [var Float] {
    Array.init<Float>(SHELL_COUNT, S0)
  };

  // ===========================================================================
  // FLATTEN activations across all shells into a single vector
  // ===========================================================================
  public func flatten_activations(
    all_acts : [[var Float]]
  ) : [Float] {
    let out = Array.init<Float>(SHELL_COUNT * MAX_NODES, S0);
    var s = 0;
    while (s < SHELL_COUNT) {
      var i = 0;
      while (i < MAX_NODES) {
        out[s * MAX_NODES + i] := all_acts[s][i];
        i += 1;
      };
      s += 1;
    };
    Array.freeze(out)
  };

}
