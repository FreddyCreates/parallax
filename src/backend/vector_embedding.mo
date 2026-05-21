// vector_embedding.mo — PHI-SEEDED VECTOR EMBEDDING ENGINE
// PARALLAX Sovereign Organism — Semantic proximity layer
//
// Meaning: Every sovereign model has a 64-dim phi-seeded embedding vector.
//          Proximity in this space = resonance.
// Computation: dims[i] = sin(hash * PHI * (i+1)); cosine similarity for topK
// Binding: buildEmbedding, buildQueryEmbedding, cosineSimilarity, topK, buildAllEmbeddings
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float  "mo:core/Float";
import Array  "mo:core/Array";
import List   "mo:core/List";
import Phi    "phi";

module {

  public type EmbeddingRecord = {
    modelId     : Text;
    microTokenId: Nat32;
    dims        : [Float];
    cosineSim   : Float;
    lastUpdated : Int;
  };

  let DIMS : Nat = 64;

  func tokenToFloat(microTokenId : Nat32) : Float {
    microTokenId.toNat().toInt().toFloat()
  };

  func idxToFloat(i : Nat) : Float {
    (i + 1).toInt().toFloat()
  };

  func buildDims(tf : Float) : [Float] {
    Array.tabulate(DIMS, func i : Float {
      Float.sin(tf * Phi.PHI * idxToFloat(i))
    })
  };

  /// buildEmbedding — 64-dim phi-seeded embedding for a model
  public func buildEmbedding(modelId : Text, microTokenId : Nat32, lastUpdated : Int) : EmbeddingRecord {
    let dims = buildDims(tokenToFloat(microTokenId));
    { modelId; microTokenId; dims; cosineSim = 0.0; lastUpdated }
  };

  /// buildQueryEmbedding — FNV-1a seed -> 64-dim phi-seeded embedding
  public func buildQueryEmbedding(queryText : Text) : [Float] {
    var seed : Nat32 = 2166136261;
    for (c in queryText.chars()) {
      seed := (seed ^ c.toNat32()) *% 16777619;
    };
    buildDims(seed.toNat().toInt().toFloat())
  };

  /// cosineSimilarity — dot(a,b) / (|a| * |b|); floored at 0.0001
  public func cosineSimilarity(a : [Float], b : [Float]) : Float {
    let n = if (a.size() < b.size()) a.size() else b.size();
    if (n == 0) { return 0.0001 };
    var dot    : Float = 0.0;
    var normA  : Float = 0.0;
    var normB  : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      dot   += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
      i += 1;
    };
    let magA = Float.sqrt(normA);
    let magB = Float.sqrt(normB);
    if (magA < 0.0001 or magB < 0.0001) { return 0.0001 };
    let sim = dot / (magA * magB);
    if (sim < 0.0001) 0.0001 else sim
  };

  /// topK — return k model IDs with highest cosine similarity to queryVec
  public func topK(queryVec : [Float], k : Nat, allEmbeddings : [(Text, [Float])]) : [Text] {
    if (k == 0 or allEmbeddings.size() == 0) { return [] };

    // Build scored list
    let n = allEmbeddings.size();
    let ids   = List.tabulate(n, func i : Text { allEmbeddings[i].0 });
    let scores = Array.tabulate(n, func i : Float {
      cosineSimilarity(queryVec, allEmbeddings[i].1)
    });

    let take = if (k < n) k else n;
    let result = List.empty<Text>();
    var used = Array.tabulate(n, func _ : Bool { false });

    var j = 0;
    while (j < take) {
      var maxIdx   : Nat   = 0;
      var maxScore : Float = -2.0;
      var r = 0;
      while (r < n) {
        if (not used[r] and scores[r] > maxScore) {
          maxScore := scores[r];
          maxIdx := r;
        };
        r += 1;
      };
      result.add(ids.at(maxIdx));
      let sz = used.size();
      used := Array.tabulate(sz, func ri : Bool {
        if (ri == maxIdx) true else used[ri]
      });
      j += 1;
    };
    result.toArray()
  };

  /// buildAllEmbeddings — generate embedding vectors for all provided model specs
  public func buildAllEmbeddings(models : [(Text, Nat32)]) : [(Text, [Float])] {
    let buf = List.empty<(Text, [Float])>();
    var i = 0;
    while (i < models.size()) {
      let (modelId, microTokenId) = models[i];
      buf.add((modelId, buildDims(tokenToFloat(microTokenId))));
      i += 1;
    };
    buf.toArray()
  };

};
