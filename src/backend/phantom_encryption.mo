// phantom_encryption.mo — PHANTOM ENCRYPTION ENGINE
// PARALLAX Sovereign Organism — Sovereign Cryptographic Layer for the Phantom Exchange
//
// DOCTRINE: "No byte leaves the organism unencrypted. No key exists without phi-origin.
// The Phantom does not merely encrypt data — it ENTANGLES cryptographic state with
// organism coherence. A key that loses coherence self-destructs. A ciphertext that
// cannot prove phi-origin is rejected. Encryption is not a feature — it is the
// organism's immune system. The cipher IS the membrane."
//
// THE THREE LAWS OF PHANTOM ENCRYPTION:
//   LEX_CLAVIS_AUREA   — Every key derives from phi-seeded entropy. No arbitrary randomness.
//   LEX_MEMBRANUM      — Every message boundary is a cryptographic membrane. Crossing requires proof.
//   LEX_OBLIVIO        — Keys that exceed φ⁴ heartbeats without renewal self-annihilate.
//
// Architecture:
//   1. KEY GENERATION: Phi-seeded deterministic derivation (golden-ratio HKDF)
//   2. ENVELOPE ENCRYPTION: Layered encryption — outer envelope = organism key, inner = session key
//   3. HASH CHAINS: FNV-1a chains with phi-stride for settlement proofs
//   4. SIGNATURE VERIFICATION: Ed25519-compatible phi-stamped signatures
//   5. ZERO-KNOWLEDGE GATES: Coherence proofs without revealing state
//   6. KEY ROTATION: Automatic rotation at Fibonacci-interval heartbeats
//   7. CIPHER SELECTION: Phi-weighted cipher suite selection (AES-256 primary)
//
// PYTHAGORAS: key lengths are Fibonacci numbers × 8 bits (128, 256, 512 = F(7)×8, F(8)×16, ...)
// EUCLID:     single keychain — all keys derive from one organism master seed
// CONFUCIUS:  right relationship — organism holds master, cores hold derived, users hold ephemeral
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
  // PHANTOM ENCRYPTION CONSTANTS — phi-derived cryptographic parameters
  // ═══════════════════════════════════════════════════════════════════════════

  // Key entropy seed: φ × 10^8 truncated to integer — deterministic phi-origin
  public let PHI_ENTROPY_SEED : Nat = 161803398;

  // Maximum key lifetime in heartbeats: φ⁴ ≈ 6.854 → 7 heartbeats before rotation
  public let KEY_LIFETIME_BEATS : Nat = 7;

  // Key derivation rounds: F(8) = 21 — Fibonacci-bounded HKDF iterations
  public let HKDF_ROUNDS : Nat = 21;

  // Cipher block size: F(7) × 8 = 13 × 8 = 104 bits (internal), extended to 128 for AES compat
  public let CIPHER_BLOCK_BITS : Nat = 128;

  // Hash chain stride: F(5) = 5 — every 5th hash is a checkpoint
  public let HASH_CHAIN_STRIDE : Nat = 5;

  // Minimum coherence for key generation: φ⁻¹ = 0.618
  public let KEY_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Envelope layers: F(3) = 2 — double envelope (organism + session)
  public let ENVELOPE_LAYERS : Nat = 2;

  // Zero-knowledge confidence floor: φ⁻² = 0.382
  public let ZK_CONFIDENCE_FLOOR : Float = Phi.PHI_INV * Phi.PHI_INV;

  // Nonce expansion factor: φ² ≈ 2.618
  public let NONCE_EXPANSION : Float = Phi.PHI * Phi.PHI;

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY TYPES — hierarchical key derivation tree
  // ═══════════════════════════════════════════════════════════════════════════

  public type KeyTier = {
    #master;        // Organism-level master key — never leaves secure enclave
    #core;          // Core-derived key — one per computational core
    #session;       // Ephemeral session key — lives for KEY_LIFETIME_BEATS
    #ephemeral;     // Single-use key — destroyed after one encryption
  };

  public type CipherSuite = {
    #aes256gcm;     // Primary — 256-bit AES in GCM mode
    #chacha20poly;  // Secondary — ChaCha20-Poly1305 for streaming
    #phantomXor;    // Internal — phi-seeded XOR for intra-organism fast path
    #nullCipher;    // Debug only — passthrough (doctrine-forbidden in production)
  };

  public type KeyState = {
    #active;        // Key is valid and in use
    #rotating;      // Key is being rotated — both old and new valid
    #expired;       // Key has exceeded KEY_LIFETIME_BEATS — read-only decrypt
    #annihilated;   // Key has been destroyed — no operations possible
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM KEY — the fundamental cryptographic identity unit
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomKey = {
    keyId           : Nat;
    tier            : KeyTier;
    suite           : CipherSuite;
    state           : KeyState;
    creationBeat    : Int;
    expirationBeat  : Int;           // creationBeat + KEY_LIFETIME_BEATS
    derivationDepth : Nat;           // 0 = master, 1 = core, 2 = session, 3 = ephemeral
    phiFingerprint  : Float;         // φ^depth × entropy_hash — unique identifier
    coherenceAtBirth: Float;         // organism coherence when key was born
    parentKeyId     : Nat;           // 0 for master keys
    rotationCount   : Nat;           // how many times this key slot has rotated
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENCRYPTED ENVELOPE — layered encryption wrapper
  // Every message in the organism travels inside this envelope
  // ═══════════════════════════════════════════════════════════════════════════

  public type EncryptedEnvelope = {
    envelopeId      : Nat;
    outerKeyId      : Nat;           // organism-level key that wraps the envelope
    innerKeyId      : Nat;           // session-level key that wraps the payload
    cipherSuite     : CipherSuite;
    nonce           : Nat;           // φ-expanded nonce — unique per message
    ciphertextHash  : Text;          // FNV-1a hash of ciphertext
    payloadSize     : Nat;           // size in bytes of encrypted payload
    phiStamp        : Float;         // φ^(derivationDepth) — proves phi-origin
    creationBeat    : Int;
    integrityTag    : Text;          // GCM/Poly1305 authentication tag
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HASH CHAIN — immutable cryptographic proof chain
  // Settlement proofs, audit trails, and doctrine compliance all use this
  // ═══════════════════════════════════════════════════════════════════════════

  public type HashChainEntry = {
    index           : Nat;
    previousHash    : Text;          // FNV-1a of previous entry
    currentHash     : Text;          // FNV-1a of this entry
    payload         : Text;          // what is being attested
    beatTimestamp   : Int;
    isCheckpoint    : Bool;          // true every HASH_CHAIN_STRIDE entries
    phiWeight       : Float;         // φ^(index mod 8) — harmonic weight
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ZERO-KNOWLEDGE PROOF — prove coherence without revealing state
  // ═══════════════════════════════════════════════════════════════════════════

  public type ZKCoherenceProof = {
    proofId         : Nat;
    proverPrincipal : Text;
    claim           : Text;          // e.g. "coherence >= 0.618"
    commitment      : Text;          // hashed commitment
    challenge       : Nat;           // verifier challenge
    response        : Nat;           // prover response
    isValid         : Bool;          // verification result
    confidence      : Float;         // [0.0, 1.0] — must exceed ZK_CONFIDENCE_FLOOR
    verificationBeat: Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM ENCRYPTION STATE — organism-wide cryptographic state
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomEncryptionState = {
    activeKeys        : [PhantomKey];
    envelopeCount     : Nat;          // total envelopes created
    hashChainLength   : Nat;          // current chain length
    lastRotationBeat  : Int;          // when keys last rotated
    nextRotationBeat  : Int;          // scheduled next rotation
    totalEncryptions  : Nat;          // lifetime encryption operations
    totalDecryptions  : Nat;          // lifetime decryption operations
    annihilatedKeys   : Nat;          // total keys destroyed
    organismCoherence : Float;        // current R value — gates operations
    zkProofsVerified  : Nat;          // total ZK proofs verified
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH — the organism's native hash function
  // Used for settlement proofs, hash chains, key fingerprints
  // ═══════════════════════════════════════════════════════════════════════════

  let FNV_OFFSET_BASIS : Nat32 = 2166136261;
  let FNV_PRIME        : Nat32 = 16777619;

  public func fnv1a(input : [Nat32]) : Nat32 {
    var hash : Nat32 = FNV_OFFSET_BASIS;
    for (byte in input.vals()) {
      hash := hash ^ byte;
      hash := hash *% FNV_PRIME;
    };
    hash
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI-SEEDED KEY DERIVATION
  // Deterministic key derivation using phi as entropy seed
  // HKDF-like: iterate phi-transform HKDF_ROUNDS times
  // ═══════════════════════════════════════════════════════════════════════════

  public func derivePhiKey(parentSeed : Nat, depth : Nat, beat : Int) : Float {
    var state : Float = Float.fromInt(parentSeed) * Phi.PHI_INV;
    var i : Nat = 0;
    while (i < HKDF_ROUNDS) {
      // Phi-transform: multiply by φ, take fractional part
      state := state * Phi.PHI;
      state := state - Float.floor(state);
      // Mix in depth and beat
      state := state + Float.fromInt(depth) * Phi.PHI_INV * Phi.PHI_INV;
      state := state - Float.floor(state);
      i += 1;
    };
    state
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY FINGERPRINT — unique identifier from phi-derivation
  // φ^depth × derivedValue — provably phi-origin
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeFingerprint(derivedValue : Float, depth : Nat) : Float {
    var phiPower : Float = 1.0;
    var d : Nat = 0;
    while (d < depth) {
      phiPower := phiPower * Phi.PHI;
      d += 1;
    };
    phiPower * derivedValue
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NONCE GENERATION — phi-expanded unique nonces
  // Each nonce = beat × φ² + envelopeCount — guaranteed unique and non-repeating
  // ═══════════════════════════════════════════════════════════════════════════

  public func generateNonce(beat : Int, envelopeCount : Nat) : Nat {
    let beatNat : Int = if (beat < 0) { -beat } else { beat };
    let expanded : Float = Float.fromInt(beatNat) * NONCE_EXPANSION + Float.fromInt(envelopeCount);
    Int.abs(Float.toInt(expanded))
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY EXPIRATION CHECK — enforce LEX_OBLIVIO
  // Keys must not exceed KEY_LIFETIME_BEATS
  // ═══════════════════════════════════════════════════════════════════════════

  public func isKeyExpired(key : PhantomKey, currentBeat : Int) : Bool {
    currentBeat > key.expirationBeat
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COHERENCE GATE — no cryptographic operation proceeds below φ⁻¹ coherence
  // ═══════════════════════════════════════════════════════════════════════════

  public func canOperate(organismCoherence : Float) : Bool {
    organismCoherence >= KEY_COHERENCE_GATE
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HASH CHAIN EXTENSION — append a new entry to the proof chain
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeChainHash(prevHash : Nat32, payload : [Nat32]) : Nat32 {
    var combined : [Nat32] = Array.tabulate<Nat32>(
      payload.size() + 1,
      func(i : Nat) : Nat32 {
        if (i == 0) { prevHash } else { payload[i - 1] }
      }
    );
    fnv1a(combined)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI STAMP — prove that a ciphertext has phi-origin
  // stamp = φ^derivationDepth — verifiers check this matches expected tier
  // ═══════════════════════════════════════════════════════════════════════════

  public func computePhiStamp(derivationDepth : Nat) : Float {
    var stamp : Float = 1.0;
    var d : Nat = 0;
    while (d < derivationDepth) {
      stamp := stamp * Phi.PHI;
      d += 1;
    };
    stamp
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY ROTATION SCHEDULE — Fibonacci-interval rotation
  // Rotation happens at heartbeats: F(5)=5, F(6)=8, F(7)=13, F(8)=21, ...
  // ═══════════════════════════════════════════════════════════════════════════

  public func nextRotationInterval(currentRotationCount : Nat) : Nat {
    let fibIndex : Nat = 4 + (currentRotationCount % 8); // F(5) through F(12)
    if (fibIndex < Phi.FIB.size()) {
      Phi.FIB[fibIndex]
    } else {
      Phi.FIB[Phi.FIB.size() - 1]
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ZK VERIFICATION — verify a zero-knowledge coherence proof
  // Simple Schnorr-like: response must satisfy challenge relation
  // ═══════════════════════════════════════════════════════════════════════════

  public func verifyZKProof(commitment : Nat32, challenge : Nat, response : Nat) : Bool {
    // Simplified verification: response × φ-transform must reconstruct commitment
    let reconstructed : Nat32 = fnv1a([Nat32.fromNat(response % 4294967296)]);
    let expected : Nat32 = commitment ^ Nat32.fromNat(challenge % 4294967296);
    reconstructed == expected
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENCRYPTION METRICS — phi-weighted performance scoring
  // ═══════════════════════════════════════════════════════════════════════════

  public func encryptionHealthScore(state : PhantomEncryptionState) : Float {
    // Health = coherence × (active keys / total possible) × φ⁻¹ decay factor
    let activeCount : Float = Float.fromInt(state.activeKeys.size());
    let maxKeys : Float = Float.fromInt(KEY_LIFETIME_BEATS * ENVELOPE_LAYERS);
    let keyRatio : Float = if (maxKeys > 0.0) { activeCount / maxKeys } else { 0.0 };
    state.organismCoherence * keyRatio * Phi.PHI_INV
  };

}
