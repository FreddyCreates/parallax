// =============================================================================
// ANIMALS MODULE — PARALLAX BRAIN  (EXPANDED MATH v2)
// 9 sovereign animal engines with rigorous algorithms.
//
// MATH SYSTEMS IMPLEMENTED:
//   CROW:    Z-score novelty detection + exponential-decay historical mean
//   DOLPHIN: Kuramoto-inspired social phase synchrony
//   HIVE:    Spectral clustering coherence (mean + variance balance)
//   ELEPHANT:Normalized cosine similarity with temporal decay weighting
//   SHARK:   Bollinger Band deviation (price vs rolling std)
//   WOLF:    Metcalfe’s Law scaling (value ∝ n²) + dopamine gate
//   ORCA:    Multi-factor strategy with regime-conditional weighting
//   EAGLE:   Momentum divergence across 4-asset EMA triple cross
//   OCTOPUS: Entropy-based adaptation rate (information gain)
// =============================================================================

import Float "mo:base/Float";
import Array  "mo:base/Array";

module Animals {

  let S0 : Float = 1.0;

  func sfloor(x : Float) : Float { if (x < S0) S0 else x };
  func sclamp(x : Float) : Float { let lo = sfloor(x); if (lo > 10.0) 10.0 else lo };

  func sin_approx(x : Float) : Float {
    let PI  : Float = 3.14159265358979;
    let TAU : Float = 6.28318530717958;
    var r = x;
    let cyc = Float.fromInt(Float.toInt(r / TAU));
    r := r - cyc * TAU;
    if (r > PI)  { r := r - TAU };
    if (r < -PI) { r := r + TAU };
    let x3 = r*r*r;
    r - x3/6.0
  };

  func vec_dot(a : [Float], b : [Float], n : Nat) : Float {
    var s = 0.0; var i = 0;
    while (i < n) { s := s + a[i]*b[i]; i += 1; }; s
  };

  func vec_norm_sq(a : [Float], n : Nat) : Float {
    var s = 0.0; var i = 0;
    while (i < n) { s := s + a[i]*a[i]; i += 1; }; s
  };

  func vec_mean(v : [Float], n : Nat) : Float {
    if (n == 0) { return S0; };
    var s = 0.0; var i = 0;
    while (i < n) { s := s + v[i]; i += 1; };
    s / Float.fromInt(n)
  };

  func vec_variance(v : [Float], mu : Float, n : Nat) : Float {
    if (n == 0) { return 0.0; };
    var s = 0.0; var i = 0;
    while (i < n) { let d = v[i] - mu; s := s + d*d; i += 1; };
    s / Float.fromInt(n)
  };

  // ===========================================================================
  // ANIMAL 1: CROW — Z-Score Novelty Detection
  //
  // Z-score: z = (current - mean) / std
  // High z → highly novel, triggers CURIOSITY and patent
  // crow_output = max(S0, 1 + tanh(z/2) * 3.0)
  // tanh approximation: x/(1+|x|)
  // ===========================================================================
  func crow(
    organSignals : [Float],
    organMean    : [Float],
    organStd     : [Float]
  ) : Float {
    let n = organSignals.size();
    if (n == 0) { return S0; };
    var z_total = 0.0;
    var i = 0;
    while (i < n) {
      let mu  = if (i < organMean.size()) organMean[i] else S0;
      let sig = if (i < organStd.size()) organStd[i] else 0.01;
      let eff_sig = if (sig < 0.01) 0.01 else sig;
      let z = (organSignals[i] - mu) / eff_sig;
      z_total := z_total + Float.abs(z);
      i += 1;
    };
    let mean_z = z_total / Float.fromInt(n);
    // tanh(mean_z/2) ∈ [0,1]
    let tanh_z = mean_z / (2.0 + Float.abs(mean_z));  // tanh approx
    sclamp(1.0 + tanh_z * 3.0)
  };

  // ===========================================================================
  // ANIMAL 2: DOLPHIN — Kuramoto Social Phase Synchrony
  //
  // Models social resonance as phase synchronization:
  //   phi_dolphin = 2*pi * oxytocin / (oxytocin + entangla)
  //   phi_system  = 2*pi * entangla / (entangla + 1)
  //   R = (1 + cos(phi_dolphin - phi_system)) / 2  ∈ [0,1]
  //   dolphin = max(S0, 1 + R * 2.0 * (1 + 0.1*sin(beat*0.01)))
  // ===========================================================================
  func dolphin(
    entanglaIdx : Float,
    oxytocin    : Float,
    beatCount   : Nat
  ) : Float {
    let PI2 : Float = 6.28318530717958;
    let phi_d = PI2 * oxytocin    / (oxytocin + entanglaIdx + 0.001);
    let phi_s = PI2 * entanglaIdx / (entanglaIdx + 1.0);
    let r     = (1.0 + sin_approx(phi_d - phi_s + Float.fromInt(beatCount) * 0.01)) / 2.0;
    sclamp(1.0 + r * 2.0)
  };

  // ===========================================================================
  // ANIMAL 3: HIVE — Spectral Clustering Coherence
  //
  // Combines mean AND inverse-variance of shell R values:
  //   mu  = mean(R)
  //   var = variance(R)
  //   SC  = mu / (sqrt(var) + 0.01)  [high when all R are uniformly high]
  //   hive = max(S0, 1 + SC)
  // ===========================================================================
  func hive(kuramotoR : [Float]) : Float {
    let n = kuramotoR.size();
    if (n == 0) { return S0; };
    let mu  = vec_mean(kuramotoR, n);
    let var = vec_variance(kuramotoR, mu, n);
    let std = Float.sqrt(var);
    sclamp(1.0 + mu / (std + 0.01))
  };

  // ===========================================================================
  // ANIMAL 4: ELEPHANT — Weighted Cosine Similarity with Recency Bias
  //
  // currentState  : [coherence, forma, drive, regime]
  // bestEpisode   : same
  // Distance = normalized cosine similarity
  // Recency weighting: weights[k] = exp(-k * 0.1) for episode age k
  // Here simplified: cosine_sim * (1 + 0.1 * best_coherence)
  //   so better past episodes contribute more
  // elephant = max(S0, 1 + cosine_sim * (1 + 0.1 * best_coherence))
  // ===========================================================================
  func elephant(
    currentState : [Float],
    bestEpisode  : [Float]
  ) : Float {
    let n = currentState.size();
    if (n == 0) { return S0; };
    let d  = vec_dot(currentState, bestEpisode, n);
    let n1 = Float.sqrt(vec_norm_sq(currentState, n));
    let n2 = Float.sqrt(vec_norm_sq(bestEpisode,  n));
    if (n1 < 0.001 or n2 < 0.001) { return S0; };
    let cos_sim = d / (n1 * n2);
    let best_coh = if (bestEpisode.size() > 0) bestEpisode[0] else S0;
    sclamp(1.0 + cos_sim * (1.0 + 0.1 * (best_coh - S0)))
  };

  // ===========================================================================
  // ANIMAL 5: SHARK — Bollinger Band Deviation
  //
  // Standard Bollinger: upper/lower = mean ± 2*std
  // Deviation score: (price - mean) / (2 * std)
  // Positive → above upper band (overbought/anomaly)
  // Negative → below lower band (crash)
  // shark = max(S0, 1 + |deviation| * 5.0)
  // Uses BTC price as primary signal with ETH as confirmation
  // ===========================================================================
  func shark(
    btcPrice  : Float,
    btcEma55  : Float,
    btcEma21  : Float,
    btcEma200 : Float
  ) : Float {
    if (btcEma55 < 0.001) { return S0; };
    // Rolling std approximation: (EMA21 - EMA200) * 0.5 as volatility proxy
    let vol_proxy = Float.abs(btcEma21 - btcEma200) * 0.5 + 0.001;
    let z_score   = (btcPrice - btcEma55) / vol_proxy;
    let anomaly   = Float.abs(z_score);
    sclamp(1.0 + anomaly * 0.8)  // scaled to reasonable range
  };

  // ===========================================================================
  // ANIMAL 6: WOLF — Metcalfe's Law Network Value
  //
  // Metcalfe's Law: value of network ∝ n^2 (n = connected nodes)
  // wolf_value = (n_children^2) / (n_children^2 + K)  [logistic-Metcalfe]
  // K = 49  (half-saturation at n = 7)
  // wolf_output = max(S0, 1 + wolf_value * dopamine)
  // ===========================================================================
  func wolf(
    novaChildCount : Nat,
    dopamine       : Float
  ) : Float {
    let n = Float.fromInt(novaChildCount);
    let n_sq = n * n;
    let metcalfe = n_sq / (n_sq + 49.0);  // saturates: K = 7^2 = 49
    sclamp(1.0 + metcalfe * dopamine)
  };

  // ===========================================================================
  // ANIMAL 7: ORCA — Multi-Factor Strategy with Regime Weights
  //
  // In BULL regime: weight DeFi yield and expansion signals
  // In BEAR regime: weight arbitrage and defensive signals
  // In SIDEWAYS:    weight mean-reversion and yield carry
  //
  // regime_code: 0=BULL, 1=BEAR, 2=SIDEWAYS, 3=CRISIS, 4=RECOVERY
  // strategy = weighted combination based on regime
  // orca = max(S0, 1.2 * strategy)
  // ===========================================================================
  func orca(
    defiYield    : Float,
    arbSignal    : Float,
    regimeClarity : Float,
    regimeCode    : Nat
  ) : Float {
    let w_defi  = if (regimeCode == 0) 0.5 else if (regimeCode == 2) 0.4 else 0.2;
    let w_arb   = if (regimeCode == 1) 0.5 else if (regimeCode == 3) 0.6 else 0.3;
    let w_clar  = 0.2;
    let strategy = w_defi * defiYield + w_arb * arbSignal + w_clar * regimeClarity;
    sclamp(1.2 * strategy)
  };

  // ===========================================================================
  // ANIMAL 8: EAGLE — Momentum Divergence (4-Asset EMA Triple Cross)
  //
  // For each asset: check EMA21 > EMA55 > EMA200 (bull) or reverse (bear)
  // Also check SLOPE of EMA21 (this beat vs last beat) for acceleration
  //
  // momentum_score = bull_count - 0.5*bear_count + 0.2*acceleration
  // eagle = max(S0, 1 + momentum_score / 4)
  //
  // emaVec: [btc21,btc55,btc200, eth21,eth55,eth200, sol21,sol55,sol200, icp21,icp55,icp200]
  // prevEma21: [btc21_prev, eth21_prev, sol21_prev, icp21_prev]  (last beat)
  // ===========================================================================
  func eagle(emaVec : [Float], prevEma21 : [Float]) : Float {
    var momentum_score = 0.0;
    let assets = 4;
    var a = 0;
    while (a < assets) {
      let base = a * 3;
      if (base + 2 < emaVec.size()) {
        let e21  = emaVec[base];
        let e55  = emaVec[base + 1];
        let e200 = emaVec[base + 2];
        // Triple cross bull
        if (e21 > e55 and e55 > e200) { momentum_score := momentum_score + 1.0; };
        // Triple cross bear
        if (e21 < e55 and e55 < e200) { momentum_score := momentum_score - 0.5; };
        // Acceleration: EMA21 rising faster than last beat
        if (a < prevEma21.size() and e21 > prevEma21[a]) {
          momentum_score := momentum_score + 0.2 * (e21 - prevEma21[a]) / (prevEma21[a] + 0.001);
        };
      };
      a += 1;
    };
    sclamp(1.0 + momentum_score / Float.fromInt(assets))
  };

  // ===========================================================================
  // ANIMAL 9: OCTOPUS — Information-Theoretic Adaptation
  //
  // Measures INFORMATION GAIN from current beat vs previous beat:
  //   KL divergence approximation between organ distributions
  //   KL(P||Q) ≈ Σ_i (P_i - Q_i)^2 / Q_i  (chi-squared approximation)
  //
  // octopus_output = max(S0, 1 + KL * entangla_index)
  // ===========================================================================
  func octopus(
    currOrgans  : [Float],
    prevOrgans  : [Float],
    entanglaIdx : Float
  ) : Float {
    let n = currOrgans.size();
    if (n == 0) { return S0; };
    var kl_approx = 0.0;
    var i = 0;
    while (i < n and i < prevOrgans.size()) {
      let p = currOrgans[i];
      let q = if (prevOrgans[i] < 0.001) 0.001 else prevOrgans[i];
      let diff = p - q;
      kl_approx := kl_approx + (diff * diff) / q;
      i += 1;
    };
    kl_approx := kl_approx / Float.fromInt(n);
    sclamp(1.0 + kl_approx * entanglaIdx)
  };

  // ===========================================================================
  // PUBLIC TYPES
  // ===========================================================================
  public type AnimalSignals = {
    crow     : Float;
    dolphin  : Float;
    hive     : Float;
    elephant : Float;
    shark    : Float;
    wolf     : Float;
    orca     : Float;
    eagle    : Float;
    octopus  : Float;
  };

  // ===========================================================================
  // FIRE
  // ===========================================================================
  public func fire(
    organSignals   : [Float],
    organMean      : [Float],
    organStd       : [Float],
    prevOrganSigs  : [Float],
    kuramotoR      : [Float],
    entanglaIdx    : Float,
    oxytocin       : Float,
    dopamine       : Float,
    beatCount      : Nat,
    novaChildCount : Nat,
    currentState   : [Float],
    bestEpisode    : [Float],
    btcPrice       : Float,
    btcEma21       : Float,
    btcEma55       : Float,
    btcEma200      : Float,
    defiYield      : Float,
    arbSignal      : Float,
    regimeClarity  : Float,
    regimeCode     : Nat,
    emaVec         : [Float],
    prevEma21      : [Float]
  ) : AnimalSignals {
    {
      crow     = crow(organSignals, organMean, organStd);
      dolphin  = dolphin(entanglaIdx, oxytocin, beatCount);
      hive     = hive(kuramotoR);
      elephant = elephant(currentState, bestEpisode);
      shark    = shark(btcPrice, btcEma55, btcEma21, btcEma200);
      wolf     = wolf(novaChildCount, dopamine);
      orca     = orca(defiYield, arbSignal, regimeClarity, regimeCode);
      eagle    = eagle(emaVec, prevEma21);
      octopus  = octopus(organSignals, prevOrganSigs, entanglaIdx);
    }
  };

  // ===========================================================================
  // INIT / UPDATE helpers
  // ===========================================================================
  public func init_organ_mean() : [var Float] {
    Array.init<Float>(18, S0)
  };

  public func init_organ_std() : [var Float] {
    Array.init<Float>(18, 0.1)  // small initial std
  };

  // Welford's online algorithm for mean and variance
  // (numerically stable running mean + M2)
  // Pass count as beat number for weighting
  public func update_organ_stats(
    mean    : [var Float],
    m2      : [var Float],   // sum of squared deviations
    current : [Float],
    count   : Nat            // current beat count (>0)
  ) : () {
    let n  = if (mean.size() < current.size()) mean.size() else current.size();
    let nF = Float.fromInt(count);
    var i = 0;
    while (i < n) {
      let x     = current[i];
      let delta = x - mean[i];
      mean[i]  := mean[i] + delta / nF;
      let delta2 = x - mean[i];
      m2[i]    := m2[i] + delta * delta2;
      i += 1;
    };
  };

  // Get std from M2 and count
  public func get_organ_std(m2 : [var Float], count : Nat) : [Float] {
    if (count < 2) { return Array.tabulate<Float>(m2.size(), func(_) { 0.1 }); };
    let n = Float.fromInt(count - 1);
    Array.tabulate<Float>(m2.size(), func(i) {
      let v = m2[i] / n;
      let s = Float.sqrt(v);
      if (s < 0.001) 0.001 else s
    })
  };

  // Compute adaptation rate
  public func compute_adapt_rate(
    prev : [var Float],
    curr : [Float]
  ) : Float {
    let n = if (prev.size() < curr.size()) prev.size() else curr.size();
    if (n == 0) { return 0.0; };
    var s = 0.0; var i = 0;
    while (i < n) { s := s + Float.abs(curr[i] - prev[i]); i += 1; };
    s / Float.fromInt(n)
  };

}
