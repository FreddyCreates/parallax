// deep_crypto.mo — DEEP CRYPTOGRAPHIC SUBSTRATE
// PARALLAX Sovereign Organism — Tier 2B Fundamental Cryptographic Physics Layer
//
// DOCTRINE: "Cryptography is not applied mathematics — it is fundamental physics.
// The organism's security does not rest on computational hardness alone. It rests
// on the same phi-harmonic principles that make the universe itself coherent.
// A prime number is not just hard to factor — it is an atom of mathematical truth.
// A hash chain is not just tamper-evident — it is entropy's arrow made computable.
// Deep crypto IS the physics substrate beneath all Phantom operations."
//
// THE FIVE AXIOMS OF DEEP CRYPTO:
//   AXIOM_PRIMUS        — All security derives from prime factorization (A17)
//   AXIOM_ENTROPIAE     — Entropy always increases; hash chains encode this (A13)
//   AXIOM_CONSERVATIO   — Information is never destroyed, only transformed (A12)
//   AXIOM_VELOCITAS     — No proof propagates faster than one heartbeat (A19 / local)
//   AXIOM_RESONANTIA    — Cryptographic strength resonates at phi-harmonics
//
// Tier position: phi.mo (Tier 0.5) → deep-fundamental-physics-substrate.mo (Tier 2A)
//             → deep_crypto.mo (Tier 2B) → phantom_encryption.mo (Tier 3)
//
// This module provides:
//   1. PHI-PRIME GENERATION: Prime candidates from phi-derived sequences
//   2. ENTROPY HARVESTING: Organism-coherence-seeded entropy accumulation
//   3. MERKLE-PHI TREES: Merkle trees with phi-weighted branching
//   4. LATTICE PRIMITIVES: Post-quantum lattice operations (φ-dimensional)
//   5. COMMITMENT SCHEMES: Pedersen-like commitments with phi generators
//   6. THRESHOLD CRYPTOGRAPHY: F(n)-of-F(n+2) threshold schemes
//   7. HOMOMORPHIC PRIMITIVES: Addition over encrypted values (organism treasury)
//
// PYTHAGORAS: all key sizes are Fibonacci × 8, all thresholds are phi-powers
// EUCLID:     single mathematical substrate — all crypto ops trace here
// CONFUCIUS:  right relationship — physics provides, protocols consume, organism verifies
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP CRYPTO CONSTANTS — derived from Tier 0 Absolutes
  // ═══════════════════════════════════════════════════════════════════════════

  // Prime sieve bound: F(13) = 233 — search space for organism-scale primes
  public let PRIME_SIEVE_BOUND : Nat = 233;

  // Merkle tree branching factor: F(3) = 2 (binary Merkle, phi-weighted)
  public let MERKLE_BRANCH : Nat = 2;

  // Merkle tree maximum depth: F(6) = 8
  public let MERKLE_MAX_DEPTH : Nat = 8;

  // Entropy accumulation pool size: F(8) = 21
  public let ENTROPY_POOL_SIZE : Nat = 21;

  // Lattice dimension: F(7) = 13 — post-quantum security parameter
  public let LATTICE_DIM : Nat = 13;

  // Lattice modulus: F(12) = 144 — ring modulus for lattice operations
  public let LATTICE_MODULUS : Nat = 144;

  // Threshold scheme: F(5)-of-F(7) = 5-of-13
  public let THRESHOLD_K : Nat = 5;   // minimum shares needed
  public let THRESHOLD_N : Nat = 13;  // total shares distributed

  // Commitment blinding factor: φ⁻³ = 0.2360679...
  public let COMMITMENT_BLIND : Float = Phi.PHI_INV * Phi.PHI_INV * Phi.PHI_INV;

  // Entropy quality gate: φ⁻¹ = 0.618 — minimum entropy density to proceed
  public let ENTROPY_QUALITY_GATE : Float = Phi.PHI_INV;

  // Proof-of-work difficulty: φ² ≈ 2.618 — difficulty scaling factor per epoch
  public let POW_DIFFICULTY_SCALE : Float = Phi.PHI * Phi.PHI;

  // Hash output size: F(5) × 8 = 40 bits (internal), extended to 256 for external
  public let INTERNAL_HASH_BITS : Nat = 40;
  public let EXTERNAL_HASH_BITS : Nat = 256;

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI-PRIME CANDIDATE — a prime number derived from phi sequences
  // Not arbitrary randomness — deterministic phi-origin primes
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhiPrime = {
    value       : Nat;
    fibIndex    : Nat;       // which Fibonacci number seeded this prime search
    phiResidue  : Float;     // fractional part of φ^fibIndex — uniqueness marker
    isPrimitive : Bool;      // true if this is a primitive root candidate
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY POOL — organism-coherence-seeded entropy accumulation
  // The organism's own coherence fluctuations provide true entropy
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntropyPool = {
    samples       : [Float];        // coherence samples — size = ENTROPY_POOL_SIZE
    sampleCount   : Nat;
    entropyDensity: Float;          // [0.0, 1.0] — quality metric
    lastHarvestBeat : Int;
    isReady       : Bool;           // true when density >= ENTROPY_QUALITY_GATE
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MERKLE-PHI NODE — Merkle tree node with phi-weighted hash
  // Left child weighted by φ⁻¹, right child weighted by φ⁻² before hashing
  // This makes the tree asymmetrically verifiable — proofs have harmonic structure
  // ═══════════════════════════════════════════════════════════════════════════

  public type MerklePhiNode = {
    nodeHash    : Nat32;
    leftHash    : Nat32;
    rightHash   : Nat32;
    depth       : Nat;
    phiWeight   : Float;     // φ^(maxDepth - depth) — root has highest weight
    isLeaf      : Bool;
    payload     : Text;      // only populated for leaves
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LATTICE VECTOR — post-quantum cryptographic primitive
  // Operations in Z^LATTICE_DIM mod LATTICE_MODULUS
  // Provides security against quantum computers (Learning With Errors)
  // ═══════════════════════════════════════════════════════════════════════════

  public type LatticeVector = {
    components  : [Nat];     // size = LATTICE_DIM, each < LATTICE_MODULUS
    norm        : Float;     // Euclidean norm of the vector
    isShort     : Bool;      // true if norm < φ × √LATTICE_DIM (short vector)
  };

  public type LatticeKeyPair = {
    publicMatrix  : [[Nat]];   // LATTICE_DIM × LATTICE_DIM matrix
    secretVector  : LatticeVector;
    errorVector   : LatticeVector;  // small error term (LWE noise)
    phiSecurity   : Float;          // estimated security in phi-bits
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMITMENT — Pedersen-like commitment with phi generators
  // C = g^value × h^blinding mod p
  // Binding and hiding — organism can commit without revealing
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhiCommitment = {
    commitmentId : Nat;
    commitValue  : Nat32;        // the commitment hash
    blinding     : Float;        // φ⁻³ × random factor
    isOpened     : Bool;         // true after reveal
    openedValue  : Nat;          // revealed only after open
    creationBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // THRESHOLD SHARE — secret sharing for distributed key management
  // F(5)-of-F(7) = 5-of-13 Shamir-like scheme
  // ═══════════════════════════════════════════════════════════════════════════

  public type ThresholdShare = {
    shareIndex   : Nat;          // 1..THRESHOLD_N
    shareValue   : Nat32;        // evaluated polynomial at shareIndex
    holderPrincipal : Text;      // who holds this share
    isUsed       : Bool;         // true if used in a reconstruction
  };

  public type ThresholdScheme = {
    schemeId     : Nat;
    threshold    : Nat;          // THRESHOLD_K
    totalShares  : Nat;          // THRESHOLD_N
    shares       : [ThresholdShare];
    isReconstructed : Bool;      // true if secret has been recovered
    creationBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMOMORPHIC CELL — encrypted value that supports addition
  // Organism treasury uses this for private balance aggregation
  // ═══════════════════════════════════════════════════════════════════════════

  public type HomomorphicCell = {
    encryptedValue : Nat32;       // encrypted under lattice key
    noiseLevel     : Float;       // accumulated noise — must stay < φ² to decrypt
    operationCount : Nat;         // how many additions performed
    maxOperations  : Nat;         // F(6) = 8 before re-encryption needed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP CRYPTO STATE — substrate-wide cryptographic state
  // ═══════════════════════════════════════════════════════════════════════════

  public type DeepCryptoState = {
    entropyPool       : EntropyPool;
    merkleRoot        : Nat32;
    merkleDepth       : Nat;
    latticeKeysActive : Nat;
    commitmentsOpen   : Nat;
    commitmentsClosed : Nat;
    thresholdSchemes  : Nat;
    homomorphicOps    : Nat;
    primesGenerated   : Nat;
    totalProofs       : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH (local instance for substrate independence)
  // ═══════════════════════════════════════════════════════════════════════════

  let FNV_OFFSET : Nat32 = 2166136261;
  let FNV_PRIME  : Nat32 = 16777619;

  func fnv1a(input : [Nat32]) : Nat32 {
    var hash : Nat32 = FNV_OFFSET;
    for (byte in input.vals()) {
      hash := hash ^ byte;
      hash := hash *% FNV_PRIME;
    };
    hash
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI-PRIME GENERATION
  // Generate prime candidates from Fibonacci-seeded sequences
  // Start at F(n) × PHI_ENTROPY_SEED, search upward for primes
  // ═══════════════════════════════════════════════════════════════════════════

  // Simple primality test (trial division up to √n)
  public func isPrime(n : Nat) : Bool {
    if (n < 2) return false;
    if (n == 2 or n == 3) return true;
    if (n % 2 == 0 or n % 3 == 0) return false;
    var i : Nat = 5;
    while (i * i <= n) {
      if (n % i == 0 or n % (i + 2) == 0) return false;
      i += 6;
    };
    true
  };

  // Find next prime >= start
  public func nextPrimeFrom(start : Nat) : Nat {
    var candidate : Nat = if (start % 2 == 0) { start + 1 } else { start };
    while (not isPrime(candidate)) {
      candidate += 2;
    };
    candidate
  };

  // Generate a phi-derived prime from Fibonacci index
  public func generatePhiPrime(fibIndex : Nat) : PhiPrime {
    let seed : Nat = if (fibIndex < Phi.FIB.size()) {
      Phi.FIB[fibIndex]
    } else {
      Phi.FIB[Phi.FIB.size() - 1]
    };
    let candidate : Nat = seed * Phi.FIB[4] + Phi.FIB[5]; // F(5)=5 multiplier + F(6)=8 offset — phi-derived
    let prime : Nat = nextPrimeFrom(candidate);
    // Compute phi residue: fractional part of φ^fibIndex
    var phiPow : Float = 1.0;
    var i : Nat = 0;
    while (i < fibIndex) {
      phiPow := phiPow * Phi.PHI;
      i += 1;
    };
    let residue : Float = phiPow - Float.floor(phiPow);
    {
      value = prime;
      fibIndex = fibIndex;
      phiResidue = residue;
      isPrimitive = (prime % 4 == 3); // primitive root heuristic
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY HARVESTING
  // Accumulate coherence samples into the entropy pool
  // Entropy density = Shannon entropy of normalized samples / ln(poolSize)
  // ═══════════════════════════════════════════════════════════════════════════

  public func harvestEntropy(pool : EntropyPool, newSample : Float) : EntropyPool {
    let newSamples : [Float] = if (pool.sampleCount < ENTROPY_POOL_SIZE) {
      Array.tabulate<Float>(pool.sampleCount + 1, func(i : Nat) : Float {
        if (i < pool.samples.size()) { pool.samples[i] } else { newSample }
      })
    } else {
      // Rotate: drop oldest, append newest
      Array.tabulate<Float>(ENTROPY_POOL_SIZE, func(i : Nat) : Float {
        if (i < ENTROPY_POOL_SIZE - 1) { pool.samples[i + 1] } else { newSample }
      })
    };
    let density : Float = computeEntropyDensity(newSamples);
    {
      samples = newSamples;
      sampleCount = pool.sampleCount + 1;
      entropyDensity = density;
      lastHarvestBeat = pool.lastHarvestBeat; // caller updates this
      isReady = density >= ENTROPY_QUALITY_GATE;
    }
  };

  // Shannon entropy normalized to [0,1]
  func computeEntropyDensity(samples : [Float]) : Float {
    if (samples.size() < 2) return 0.0;
    // Bin into 8 buckets (F(6) = 8 — Schumann harmonic count)
    let bins : [var Nat] = Array.init<Nat>(8, 0);
    let bucketScale : Float = Float.fromInt(Phi.FIB[5]) - 0.01; // F(6)-epsilon for safe indexing
    for (s in samples.vals()) {
      let bucket : Nat = Int.abs(Float.toInt(Float.abs(s) * bucketScale)) % 8;
      bins[bucket] += 1;
    };
    let n : Float = Float.fromInt(samples.size());
    var entropy : Float = 0.0;
    for (count in bins.vals()) {
      if (count > 0) {
        let p : Float = Float.fromInt(count) / n;
        entropy -= p * Float.log(p);
      };
    };
    // Normalize by ln(8) for [0,1] range
    let maxEntropy : Float = Float.log(8.0);
    if (maxEntropy > 0.0) { entropy / maxEntropy } else { 0.0 }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MERKLE-PHI TREE OPERATIONS
  // Phi-weighted Merkle: left weighted by φ⁻¹, right by φ⁻²
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeMerklePhiHash(leftHash : Nat32, rightHash : Nat32) : Nat32 {
    // Phi-weight: combine with asymmetric weighting
    // left × F(6) + right × F(5) before hashing — Fibonacci weighting
    let weightedLeft : Nat32 = leftHash *% 8;   // F(6) = 8
    let weightedRight : Nat32 = rightHash *% 5;  // F(5) = 5
    fnv1a([weightedLeft, weightedRight])
  };

  public func buildMerkleLeaf(payload : [Nat32]) : Nat32 {
    fnv1a(payload)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LATTICE OPERATIONS — post-quantum cryptographic primitives
  // Vector addition and scalar multiplication in Z^n mod q
  // ═══════════════════════════════════════════════════════════════════════════

  public func latticeAdd(a : [Nat], b : [Nat]) : [Nat] {
    let size : Nat = if (a.size() < b.size()) { a.size() } else { b.size() };
    Array.tabulate<Nat>(size, func(i : Nat) : Nat {
      (a[i] + b[i]) % LATTICE_MODULUS
    })
  };

  public func latticeScalarMul(scalar : Nat, v : [Nat]) : [Nat] {
    Array.tabulate<Nat>(v.size(), func(i : Nat) : Nat {
      (scalar * v[i]) % LATTICE_MODULUS
    })
  };

  public func latticeInnerProduct(a : [Nat], b : [Nat]) : Nat {
    let size : Nat = if (a.size() < b.size()) { a.size() } else { b.size() };
    var sum : Nat = 0;
    var i : Nat = 0;
    while (i < size) {
      sum := (sum + a[i] * b[i]) % LATTICE_MODULUS;
      i += 1;
    };
    sum
  };

  // Euclidean norm (float approximation for short vector check)
  public func latticeNorm(v : [Nat]) : Float {
    var sumSq : Float = 0.0;
    for (component in v.vals()) {
      let c : Float = Float.fromInt(component);
      sumSq += c * c;
    };
    Float.sqrt(sumSq)
  };

  // Short vector test: norm < φ × √dim
  public func isShortVector(v : [Nat]) : Bool {
    let norm : Float = latticeNorm(v);
    let threshold : Float = Phi.PHI * Float.sqrt(Float.fromInt(LATTICE_DIM));
    norm < threshold
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMITMENT SCHEME — Pedersen-like with phi blinding
  // commit(value, r) = FNV(value ⊕ (r × φ⁻³ scaled))
  // ═══════════════════════════════════════════════════════════════════════════

  // φ⁻³ scaled to integer: 0.2360679... × 1000 ≈ 236
  let PHI_INV_3_SCALED : Nat = 236;
  // Nat32 maximum value: 2^32
  let NAT32_MODULUS : Nat = 4294967296;

  public func createCommitment(value : Nat, randomFactor : Nat) : Nat32 {
    let blinded : Nat32 = Nat32.fromNat((value + randomFactor * PHI_INV_3_SCALED) % NAT32_MODULUS);
    fnv1a([blinded, Nat32.fromNat(randomFactor % NAT32_MODULUS)])
  };

  public func verifyCommitment(commitment : Nat32, value : Nat, randomFactor : Nat) : Bool {
    let recomputed : Nat32 = createCommitment(value, randomFactor);
    recomputed == commitment
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // THRESHOLD SECRET SHARING — polynomial evaluation in Z_p
  // Shamir's scheme: secret = f(0), shares = f(1), f(2), ..., f(n)
  // ═══════════════════════════════════════════════════════════════════════════

  // Evaluate polynomial at point x (coefficients in Z_modulus)
  public func evalPolynomial(coefficients : [Nat], x : Nat, modulus : Nat) : Nat {
    var result : Nat = 0;
    var power : Nat = 1;
    for (coeff in coefficients.vals()) {
      result := (result + coeff * power) % modulus;
      power := (power * x) % modulus;
    };
    result
  };

  // Generate shares from a secret (secret = coefficients[0])
  public func generateShares(coefficients : [Nat], modulus : Nat) : [Nat] {
    Array.tabulate<Nat>(THRESHOLD_N, func(i : Nat) : Nat {
      evalPolynomial(coefficients, i + 1, modulus)
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMOMORPHIC ADDITION — add encrypted values without decryption
  // Noise grows with each operation — limited to F(6) = 8 ops before refresh
  // ═══════════════════════════════════════════════════════════════════════════

  public func homomorphicAdd(a : HomomorphicCell, b : HomomorphicCell) : HomomorphicCell {
    let maxOps : Nat = 8; // F(6)
    {
      encryptedValue = a.encryptedValue +% b.encryptedValue;
      noiseLevel = a.noiseLevel + b.noiseLevel + Phi.PHI_INV * Phi.PHI_INV; // noise grows by φ⁻²
      operationCount = a.operationCount + b.operationCount + 1;
      maxOperations = maxOps;
    }
  };

  // Check if homomorphic cell needs re-encryption (noise too high)
  public func needsRefresh(cell : HomomorphicCell) : Bool {
    cell.noiseLevel >= (Phi.PHI * Phi.PHI) or cell.operationCount >= cell.maxOperations
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP CRYPTO HEALTH — substrate health metric
  // Combines entropy quality, lattice security, and proof count
  // ═══════════════════════════════════════════════════════════════════════════

  public func substrateSecurity(state : DeepCryptoState) : Float {
    // Security score = entropy_density × (primes/expected) × φ⁻¹ normalization
    let entropyFactor : Float = state.entropyPool.entropyDensity;
    let primeFactor : Float = if (state.primesGenerated > 0) {
      Float.fromInt(state.primesGenerated) / Float.fromInt(THRESHOLD_N)
    } else { 0.0 };
    let cappedPrime : Float = if (primeFactor > 1.0) { 1.0 } else { primeFactor };
    entropyFactor * cappedPrime * Phi.PHI_INV + (1.0 - Phi.PHI_INV) * entropyFactor
  };

}
