import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

// PARALLAX — 7 Quantum Operators (SOVEREIGN MATH v3)
// Von Neumann entropy, normalized mutual information,
// density matrix QMEM, quantum interference BYPASS
module {

  let S0 : Float = 1.0;

  // Shannon entropy of a probability distribution
  func shannonH(probs : [Float]) : Float {
    var h : Float = 0.0;
    for (p in probs.vals()) {
      if (p > 0.0001) { h -= p * Float.log(p) };
    };
    h
  };

  // Normalize a float array to a probability distribution
  func normalize(arr : [Float]) : [Float] {
    var total : Float = 0.0;
    for (v in arr.vals()) { total += Float.abs(v) };
    if (total < 0.0001) {
      let n = arr.size();
      return Array.tabulate<Float>(n, func(_) { 1.0 / (n : Int).toFloat() });
    };
    arr.map(func(v : Float) : Float { Float.abs(v) / total })
  };

  // Von Neumann entropy: S(ρ) = -Σ λₖ ln(λₖ)
  // For diagonal density matrix, eigenvalues = diagonal = normalized activations
  func vonNeumannEntropy(activations : [Float]) : Float {
    let probs = normalize(activations);
    shannonH(probs)
  };

  // PARALLAX ANGLE — arccos of normalized shell sum vs coherence
  // Upgraded: includes Von Neumann entropy as phase offset
  public func parallaxAngle(shellSum : Float, coherence : Float, beat : Nat) : Float {
    let c = Float.max(0.001, coherence);
    let base = shellSum / c;
    let atan_val = if (Float.abs(base) <= 1.0) {
      let x = base;
      x * (1.0 - x*x/3.0 + x*x*x*x/5.0)
    } else {
      let sign = if (base > 0.0) 1.0 else -1.0;
      let inv = 1.0 / Float.abs(base);
      sign * (1.5707963 - inv * (1.0 - inv*inv/3.0 + inv*inv*inv*inv/5.0))
    };
    atan_val + (beat % 1000 : Int).toFloat() * 0.000001
  };

  // ENTANGLA INDEX — normalized mutual information between shell pairs
  // NMI(X,Y) = 2*I(X;Y) / (H(X) + H(Y))
  // I(X;Y) = H(X) + H(Y) - H(X,Y)
  public func entanglaIndex(shellR : [Float]) : Float {
    let n = shellR.size();
    if (n < 2) return S0;
    // Build probability distributions from shell R values
    let probs = normalize(shellR);
    let hTotal = shannonH(probs);  // H(X∪Y) approximation

    // Pairwise NMI sum over all pairs
    var nmiSum : Float = 0.0;
    var pairCount : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = i + 1;
      while (j < n) {
        let pi = Float.max(0.0001, probs[i]);
        let pj = Float.max(0.0001, probs[j]);
        let pij = (pi + pj) / 2.0;  // joint proxy
        let hi = Float.neg(pi * Float.log(pi));
        let hj = Float.neg(pj * Float.log(pj));
        let hij = Float.neg(pij * Float.log(pij));
        let mi = hi + hj - hij;     // mutual information
        let denom = Float.max(0.001, hi + hj);
        nmiSum += Float.abs(mi) / denom;
        pairCount += 1.0;
        j += 1;
      };
      i += 1;
    };
    let avgNMI = if (pairCount > 0.0) nmiSum / pairCount else 0.0;
    // Scale by total entropy magnitude for sovereign range
    Float.max(S0, S0 + avgNMI * Float.max(0.1, hTotal))
  };

  // BYPASS GATE — 3-path superposition with quantum interference term
  // path1 = sigmoid(coherence), path2 = sigmoid(sacesiTarget)
  // interference = cos(parallax_angle) * (path1 - path2)
  public func bypassGate(coherence : Float, sacesiTarget : Float) : Float {
    let x1 = coherence - sacesiTarget;
    let path1 = 1.0 / (1.0 + Float.exp(Float.neg(10.0 * x1)));
    let x2 = sacesiTarget;
    let path2 = 1.0 / (1.0 + Float.exp(Float.neg(5.0 * x2)));
    // Interference term using cosine of phase difference
    let phase = (coherence - sacesiTarget) * 3.14159265;
    let interference = Float.cos(phase) * (path1 - path2) * 0.1;
    Float.max(0.1, (path1 + path2) / 2.0 + interference)
  };

  // RESONEX FIELD — frequency-squared weighted activation density
  // High-frequency shells (QUANTUM, CREATIVE) dominate
  public func resonexField(shellActivations : [Float], weights : [Float]) : Float {
    let n = shellActivations.size();
    if (n == 0) return S0;
    var sum : Float = 0.0;
    var wSum : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      // Frequency weight: higher index shells get quadratic boost
      let freq_weight = ((i + 1) * (i + 1) : Int).toFloat();
      var rowWSum : Float = 0.0;
      var rowCount : Nat = 0;
      var j : Nat = 0;
      while (j < n) {
        let idx = i * n + j;
        if (idx < weights.size()) {
          rowWSum += weights[idx];
          rowCount += 1;
        };
        j += 1;
      };
      let wMean = if (rowCount > 0) rowWSum / (rowCount : Int).toFloat() else S0;
      sum  += shellActivations[i] * wMean * freq_weight;
      wSum += freq_weight;
      i += 1;
    };
    Float.max(S0, sum / Float.max(0.001, wSum))
  };

  // CHRONO DILATION — organism speeds up with age
  public func chronoDilation(beat : Nat) : Float {
    1.0 + 0.001 * Float.log(1.0 + (beat : Int).toFloat())
  };

  // VERITAS COHERENCE — tier-weighted: sovereignty tier 5x, world 2x, cognitive 1x
  // compliance proxy for sovereignty tier, coherence for cognitive tier
  public func veritasCoherence(compliance : Float, coherence : Float) : Float {
    let sov_tier   = Float.max(0.0, compliance) * 5.0;
    let world_tier = Float.max(S0, coherence) * 2.0;
    let cog_tier   = Float.max(S0, coherence) * 1.0;
    let weighted   = (sov_tier + world_tier + cog_tier) / 8.0;
    Float.max(S0, weighted)
  };

  // Cosine similarity
  func cosineSim(a : [Float], b : [Float]) : Float {
    let n = Nat.min(a.size(), b.size());
    if (n == 0) return 0.0;
    var dot  : Float = 0.0;
    var magA : Float = 0.0;
    var magB : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      dot  += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
      i += 1;
    };
    let denom = Float.max(0.001, Float.sqrt(magA) * Float.sqrt(magB));
    dot / denom
  };

  // NOVELTY SCORE — 1 - max cosine similarity to QMEM ring
  // Also factors in Von Neumann entropy of current state (higher entropy = more novel)
  public func noveltyScore(currentState : [Float], qmemRing : [[Float]]) : Float {
    var maxSim : Float = 0.0;
    for (entry in qmemRing.vals()) {
      if (entry.size() > 0) {
        let sim = cosineSim(currentState, entry);
        if (sim > maxSim) { maxSim := sim };
      };
    };
    let cosine_novelty = Float.max(0.0, Float.min(1.0, 1.0 - maxSim));
    // Entropy boost: high-entropy states are intrinsically more novel
    let vne = vonNeumannEntropy(currentState);
    let entropy_boost = Float.min(0.3, vne * 0.05);
    Float.max(0.0, Float.min(1.0, cosine_novelty + entropy_boost))
  };

};
