import Array "mo:base/Array";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor QMEM {

  // ─── Constants ────────────────────────────────────────────────────────────
  let S0            : Float = 1.0;
  let RING_SIZE     : Nat   = 2048;
  let LT_SIZE       : Nat   = 256;
  let EPISODE_DIM   : Nat   = 41;
  // Dims: [0]=coherence,[1-11]=shell activations,[12-18]=drive Q-values,
  //       [19-30]=token balances,[31-33]=market prices,[34-40]=quantum ops

  // ─── Stable State ─────────────────────────────────────────────────────────
  stable var creatorPrincipal  : Text   = "";
  stable var genesisSealed     : Bool   = false;
  stable var beatCount         : Nat    = 0;

  stable var ring       : [var [Float]] = Array.init<[Float]>(RING_SIZE, Array.freeze(Array.init<Float>(EPISODE_DIM, S0)));
  stable var ringHead   : Nat           = 0;
  stable var ringFull   : Bool          = false;

  stable var longTerm   : [var [Float]] = Array.init<[Float]>(LT_SIZE, Array.freeze(Array.init<Float>(EPISODE_DIM, S0)));
  stable var ltHead     : Nat           = 0;
  stable var ltCount    : Nat           = 0;

  stable var matriarchIdx       : Nat   = 0;
  stable var matriarchCoherence : Float = S0;

  stable var totalEpisodes : Nat   = 0;
  stable var lastEntropy   : Float = 0.0;

  // ─── Auth ─────────────────────────────────────────────────────────────────
  func assertCreator(caller: Principal) {
    if (creatorPrincipal != "") {
      assert (Principal.toText(caller) == creatorPrincipal);
    };
  };

  public shared(msg) func sealGenesis() : async () {
    assert (not genesisSealed);
    creatorPrincipal := Principal.toText(msg.caller);
    genesisSealed    := true;
  };

  // ─── Math Helpers ─────────────────────────────────────────────────────────
  func clamp(x: Float, lo: Float, hi: Float) : Float {
    if (x < lo) lo else if (x > hi) hi else x;
  };

  func dotProduct(a: [Float], b: [Float]) : Float {
    var s = 0.0;
    let n = Nat.min(a.size(), b.size());
    var i = 0;
    while (i < n) { s += a[i] * b[i]; i += 1; };
    s;
  };

  func norm(a: [Float]) : Float {
    var s = 0.0;
    for (v in a.vals()) { s += v * v; };
    Float.sqrt(s) + 1e-9;
  };

  func cosineSimilarity(a: [Float], b: [Float]) : Float {
    clamp(dotProduct(a, b) / (norm(a) * norm(b)), -1.0, 1.0);
  };

  // Shannon entropy over a normalized distribution
  func shannonEntropy(probs: [Float]) : Float {
    var h = 0.0;
    for (p in probs.vals()) {
      if (p > 1e-12) { h -= p * Float.log(p); };
    };
    h;
  };

  // Von Neumann entropy: treat coherence dim of each episode as diagonal
  // density matrix element. Normalize to get probability distribution,
  // then compute S(ρ) = -Σ p_k ln(p_k)
  func computeVonNeumannEntropy() : Float {
    let count = if (ringFull) RING_SIZE else ringHead;
    if (count == 0) return 0.0;

    // Collect coherence values as diagonal ρ elements
    var total = 0.0;
    var i = 0;
    while (i < count) {
      let ep = ring[i];
      let c = if (ep.size() > 0) Float.max(1e-12, ep[0]) else 1e-12;
      total += c;
      i += 1;
    };

    // Normalize and compute entropy
    var entropy = 0.0;
    i := 0;
    while (i < count) {
      let ep = ring[i];
      let c = if (ep.size() > 0) Float.max(1e-12, ep[0]) else 1e-12;
      let p = c / total;
      if (p > 1e-12) { entropy -= p * Float.log(p); };
      i += 1;
    };
    entropy;
  };

  // ─── Episode Recording ────────────────────────────────────────────────────
  public shared(msg) func recordEpisode(episode: [Float]) : async () {
    // Pad or truncate to EPISODE_DIM
    let ep : [Float] = Array.tabulate<Float>(EPISODE_DIM, func(i) {
      if (i < episode.size()) episode[i] else S0;
    });

    ring[ringHead] := ep;
    ringHead := (ringHead + 1) % RING_SIZE;
    if (ringHead == 0) { ringFull := true; };
    totalEpisodes += 1;
    beatCount += 1;

    // Update matriarch (highest coherence episode)
    let c = ep[0];
    if (c > matriarchCoherence) {
      matriarchCoherence := c;
      matriarchIdx := (ringHead + RING_SIZE - 1) % RING_SIZE;
    };

    // Recompute entropy every 64 episodes
    if (beatCount % 64 == 0) {
      lastEntropy := computeVonNeumannEntropy();
    };
  };

  // ─── Matriarch ────────────────────────────────────────────────────────────
  public query func getMatriarchEpisode() : async [Float] {
    Array.freeze(Array.init<Float>(EPISODE_DIM, func(i) { ring[matriarchIdx][i] }));
    // idiomatic:
    ring[matriarchIdx];
  };

  public query func getMatriarchCoherence() : async Float { matriarchCoherence };

  // ─── Cosine Recall ────────────────────────────────────────────────────────
  // Returns topK most similar episodes to query vector
  public query func recallNearest(query: [Float], topK: Nat) : async [[Float]] {
    let count = if (ringFull) RING_SIZE else ringHead;
    if (count == 0) return [];

    // Compute similarities
    let sims = Array.tabulate<(Float, Nat)>(count, func(i) {
      (cosineSimilarity(query, ring[i]), i);
    });

    // Simple selection sort for topK (topK is expected to be small, e.g. 5-10)
    let k = Nat.min(topK, count);
    let result = Array.init<[Float]>(k, []);
    let used  = Array.init<Bool>(count, false);

    var j = 0;
    while (j < k) {
      var bestSim = -2.0;
      var bestIdx = 0;
      var m = 0;
      while (m < count) {
        if (not used[m] and sims[m].0 > bestSim) {
          bestSim := sims[m].0;
          bestIdx := m;
        };
        m += 1;
      };
      used[bestIdx] := true;
      result[j] := ring[sims[bestIdx].1];
      j += 1;
    };
    Array.freeze(result);
  };

  // ─── Long-Term Memory Consolidation ───────────────────────────────────────
  // Promotes episodes with coherence > threshold to long-term stable memory
  public shared(msg) func consolidateLongTerm(threshold: Float) : async Nat {
    let count = if (ringFull) RING_SIZE else ringHead;
    var promoted = 0;
    var i = 0;
    while (i < count and ltCount < LT_SIZE) {
      let ep = ring[i];
      let c = if (ep.size() > 0) ep[0] else 0.0;
      if (c >= threshold) {
        longTerm[ltHead] := ep;
        ltHead  := (ltHead + 1) % LT_SIZE;
        if (ltCount < LT_SIZE) { ltCount += 1; };
        promoted += 1;
      };
      i += 1;
    };
    promoted;
  };

  public query func getLongTermMemory() : async [[Float]] {
    let n = Nat.min(ltCount, LT_SIZE);
    Array.tabulate<[Float]>(n, func(i) { longTerm[i] });
  };

  // ─── Stats ────────────────────────────────────────────────────────────────
  public query func getMemoryStats() : async {
    episodeCount     : Nat;
    matriarchCoherence : Float;
    vonNeumannEntropy  : Float;
    longTermCount    : Nat;
    ringHead         : Nat;
    ringFull         : Bool;
  } {
    {
      episodeCount       = totalEpisodes;
      matriarchCoherence = matriarchCoherence;
      vonNeumannEntropy  = lastEntropy;
      longTermCount      = ltCount;
      ringHead           = ringHead;
      ringFull           = ringFull;
    };
  };

  // ─── Ring Access ──────────────────────────────────────────────────────────
  // Returns a window of recent episodes (last N, capped at 64 for query size)
  public query func getRecentEpisodes(n: Nat) : async [[Float]] {
    let count = if (ringFull) RING_SIZE else ringHead;
    let window = Nat.min(n, Nat.min(count, 64));
    if (window == 0) return [];
    Array.tabulate<[Float]>(window, func(i) {
      let idx = (ringHead + RING_SIZE - window + i) % RING_SIZE;
      ring[idx];
    });
  };

  // ─── Coherence Distribution ───────────────────────────────────────────────
  // Returns histogram of coherence values across ring (10 buckets)
  public query func getCoherenceDistribution() : async [Float] {
    let count = if (ringFull) RING_SIZE else ringHead;
    let buckets = Array.init<Float>(10, 0.0);
    var i = 0;
    while (i < count) {
      let c = ring[i][0];
      let b = Nat.min(9, Int.abs(Float.toInt(c * 10.0 - S0)));
      buckets[b] += 1.0;
      i += 1;
    };
    // Normalize
    let total : Float = Float.fromInt(count);
    Array.freeze(Array.tabulate<Float>(10, func(j) {
      if (total > 0.0) buckets[j] / total else 0.0;
    }));
  };
};
