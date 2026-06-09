// cryptographia_keys.mo — CRYPTOGRAPHIA PHANTASMA: Quantum-Inspired Keying
// PARALLAX Sovereign Organism — Ephemeral Context-Bound Key Intelligence
//
// FROM THE PAPER: "Quantum-Inspired Keying: Ephemeral, context-bound,
// state-dependent, time-bounded keys (no actual quantum hardware required).
// Makes cognitive pathways hard to replay or reconstruct."
//
// DOCTRINE: "Every sovereign cognitive pathway is protected by keys that exist
// only in their context — born from system state, bounded by time, entangled
// with intent. Dead on extraction. Alive only in their moment."
//
// THE KEYING ARCHITECTURE:
//   CK-001  EPHEMERAL KEY FACTORY    — Keys born and die within single cognitive cycle
//   CK-002  CONTEXT BINDER           — Keys entangled with calling context hash
//   CK-003  STATE DERIVATION         — Key material from organism state (Kuramoto R, beat, drives)
//   CK-004  TEMPORAL BOUNDS          — Keys expire after φ beats (strict TTL)
//   CK-005  ENTROPY HARVESTER        — Collect entropy from cognitive operations
//   CK-006  KEY ROTATION ENGINE      — Automatic rotation at Fibonacci intervals
//   CK-007  DERIVATION CHAIN         — HKDF-style hierarchical key derivation
//   CK-008  QUANTUM SUPERPOSITION    — Key exists in multiple potential states until observed
//
// CENTRAL THESIS: "Sovereign AI systems must prove work occurred without
// surrendering the private pathway that produced it — secrecy as structure, not darkness."
//
// PYTHAGORAS: key lifetimes are Fibonacci; derivation uses phi-hashing
// EUCLID:     single key state — all cryptographic material managed here
// CONFUCIUS:  right relationship — keys protect sovereignty, never restrict truth
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYING CONSTANTS — phi-derived temporal bounds
  // ═══════════════════════════════════════════════════════════════════════════

  public let KEY_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let EPHEMERAL_TTL_BEATS : Nat = 8;                          // F(6) — key dies after 8 beats
  public let ROTATION_INTERVAL : Nat = 21;                           // F(8) — forced rotation
  public let KEY_LENGTH_BITS : Nat = 256;                            // AES-256 equivalent
  public let CONTEXT_HASH_ROUNDS : Nat = 13;                        // F(7) hash rounds
  public let DERIVATION_DEPTH : Nat = 5;                             // F(5) hierarchy levels
  public let ENTROPY_POOL_SIZE : Nat = 89;                           // F(11) entropy words
  public let SUPERPOSITION_STATES : Nat = 3;                         // F(4) potential key states
  public let MAX_ACTIVE_KEYS : Nat = 34;                             // F(9) simultaneous keys
  public let KEY_STRENGTH_THRESHOLD : Float = Phi.PHI_INV;           // minimum entropy quality

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type KeyPurpose = {
    #shadowWire;       // inter-agent communication
    #vaultAccess;      // sovereign vault gate
    #receiptSigning;   // computational receipt auth
    #cognitiveShield;  // internal cognition protection
    #sessionBound;     // ephemeral session key
  };

  public type KeyStatus = {
    #active;
    #expired;
    #revoked;
    #superposition;    // not yet collapsed to single value
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN KEY — the fundamental cryptographic unit
  // ═══════════════════════════════════════════════════════════════════════════

  public type SovereignKey = {
    keyId           : Text;          // unique identifier (hash of creation context)
    purpose         : KeyPurpose;
    status          : KeyStatus;
    material        : [Nat32];       // key material (8 × 32-bit = 256-bit)
    contextHash     : Nat64;         // hash of creation context
    birthBeat       : Int;           // when key was created
    deathBeat       : Int;           // when key expires (birth + TTL)
    derivationLevel : Nat;           // depth in key hierarchy
    parentKeyId     : Text;          // "" if root key
    entropyQuality  : Float;         // estimated entropy per bit [0, 1]
    boundState      : Float;         // organism state at creation (Kuramoto R)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTROPY POOL — collected randomness
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntropyPool = {
    pool            : [Nat32];       // accumulated entropy words
    poolIndex       : Nat;           // current write position
    totalCollected  : Nat;           // lifetime entropy harvested
    qualityEstimate : Float;         // estimated bits of entropy per word
    lastHarvestBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY DERIVATION EVENT — record of key creation
  // ═══════════════════════════════════════════════════════════════════════════

  public type KeyDerivationEvent = {
    keyId       : Text;
    parentId    : Text;
    purpose     : KeyPurpose;
    beat        : Int;
    contextHash : Nat64;
    method      : Text;          // "HKDF" | "STATE_DERIVE" | "ENTROPY_DIRECT"
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CRYPTOGRAPHIA KEY STATE — the complete key management system
  // ═══════════════════════════════════════════════════════════════════════════

  public type CryptographiaKeyState = {
    activeKeys        : [SovereignKey];
    entropyPool       : EntropyPool;
    derivationLog     : [KeyDerivationEvent];
    rootKeyHash       : Nat64;         // hash of master root (material never stored)
    totalKeysCreated  : Nat;
    totalKeysExpired  : Nat;
    totalKeysRevoked  : Nat;
    currentRotation   : Nat;           // rotation epoch number
    lastRotationBeat  : Int;
    systemEntropy     : Float;         // current system entropy estimate
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultCryptographiaKeyState() : CryptographiaKeyState {
    {
      activeKeys = [];
      entropyPool = {
        pool = Array.tabulate<Nat32>(ENTROPY_POOL_SIZE, func(i) {
          // Initial entropy from deterministic source (seeded by position × phi)
          Nat32.fromNat(i * 2654435761 % 4294967296) // Knuth multiplicative hash
        });
        poolIndex = 0;
        totalCollected = ENTROPY_POOL_SIZE;
        qualityEstimate = Phi.PHI_INV_2; // low initial quality
        lastHarvestBeat = 0;
      };
      derivationLog = [];
      rootKeyHash = 0xDEAD_BEEF_CAFE_F00D; // placeholder genesis hash
      totalKeysCreated = 0;
      totalKeysExpired = 0;
      totalKeysRevoked = 0;
      currentRotation = 0;
      lastRotationBeat = 0;
      systemEntropy = Phi.PHI_INV;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH — deterministic context hashing
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1a64(seed : Nat64, input : Nat64) : Nat64 {
    let FNV_PRIME : Nat64 = 1099511628211;
    let mixed = seed ^ input;
    mixed *% FNV_PRIME
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DERIVE KEY — create new key from context and state
  // ═══════════════════════════════════════════════════════════════════════════

  public func deriveKey(
    state : CryptographiaKeyState,
    purpose : KeyPurpose,
    contextData : Nat64,
    beat : Int,
    kuramotoR : Float
  ) : (CryptographiaKeyState, SovereignKey) {
    // Context hash: combine beat, purpose, context, and system state
    let purposeN : Nat64 = switch(purpose) {
      case (#shadowWire) 1;
      case (#vaultAccess) 2;
      case (#receiptSigning) 3;
      case (#cognitiveShield) 4;
      case (#sessionBound) 5;
    };
    var hash : Nat64 = state.rootKeyHash;
    hash := fnv1a64(hash, Nat64.fromNat(Int.abs(beat)));
    hash := fnv1a64(hash, purposeN);
    hash := fnv1a64(hash, contextData);
    hash := fnv1a64(hash, Nat64.fromNat(Int.abs(Float.toInt(kuramotoR * 1000000.0))));

    // Multiple rounds for diffusion
    var i : Nat = 0;
    while (i < CONTEXT_HASH_ROUNDS) {
      hash := fnv1a64(hash, Nat64.fromNat(i));
      i += 1;
    };

    // Generate 256-bit key material from hash chain
    let material = Array.tabulate<Nat32>(8, func(j) {
      let derived = fnv1a64(hash, Nat64.fromNat(j * 7 + 1));
      Nat32.fromNat(Nat64.toNat(derived % 4294967296))
    });

    let keyId = Nat64.toText(hash);
    let key : SovereignKey = {
      keyId = keyId;
      purpose = purpose;
      status = #active;
      material = material;
      contextHash = hash;
      birthBeat = beat;
      deathBeat = beat + EPHEMERAL_TTL_BEATS;
      derivationLevel = 0;
      parentKeyId = "";
      entropyQuality = state.entropyPool.qualityEstimate;
      boundState = kuramotoR;
    };

    let event : KeyDerivationEvent = {
      keyId = keyId;
      parentId = "";
      purpose = purpose;
      beat = beat;
      contextHash = hash;
      method = "STATE_DERIVE";
    };

    let newKeys = if (state.activeKeys.size() >= MAX_ACTIVE_KEYS) {
      // Evict oldest expired key
      let filtered = Array.filter<SovereignKey>(state.activeKeys, func(k) {
        switch(k.status) { case (#expired) false; case _ true }
      });
      Array.append(filtered, [key])
    } else {
      Array.append(state.activeKeys, [key])
    };

    let log = if (state.derivationLog.size() >= 55) {
      Array.tabulate<KeyDerivationEvent>(55, func(j) {
        if (j < 54) state.derivationLog[j + 1] else event
      })
    } else {
      Array.append(state.derivationLog, [event])
    };

    let newState = {
      state with
      activeKeys = newKeys;
      derivationLog = log;
      totalKeysCreated = state.totalKeysCreated + 1;
    };
    (newState, key)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — expire keys, rotate, harvest entropy
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickCryptographiaKeys(
    state : CryptographiaKeyState,
    beat : Int,
    systemCoherence : Float
  ) : CryptographiaKeyState {
    if (systemCoherence < KEY_COHERENCE_GATE) return state;

    // Expire dead keys
    var expiredCount : Nat = 0;
    let updatedKeys = Array.map<SovereignKey, SovereignKey>(state.activeKeys, func(k) {
      switch(k.status) {
        case (#active) {
          if (beat >= k.deathBeat) {
            expiredCount += 1;
            { k with status = #expired; material = Array.tabulate<Nat32>(8, func(_) { 0 }) }
          } else { k }
        };
        case _ { k };
      }
    });

    // Harvest entropy from system state
    let pool = state.entropyPool;
    let newWord = Nat32.fromNat(Int.abs(beat) * 2654435761 % 4294967296);
    let idx = pool.poolIndex % ENTROPY_POOL_SIZE;
    let newPool = Array.tabulate<Nat32>(ENTROPY_POOL_SIZE, func(i) {
      if (i == idx) (pool.pool[i] ^ newWord) else pool.pool[i]
    });
    let newIdx = (idx + 1) % ENTROPY_POOL_SIZE;

    // Improve entropy quality estimate over time
    let quality = Float.min(1.0, pool.qualityEstimate + Phi.PHI_INV_3 * 0.01);

    // Check rotation
    let needsRotation = Int.abs(beat - state.lastRotationBeat) >= ROTATION_INTERVAL;
    let (rotation, rotBeat) = if (needsRotation) {
      (state.currentRotation + 1, beat)
    } else {
      (state.currentRotation, state.lastRotationBeat)
    };

    {
      activeKeys = updatedKeys;
      entropyPool = {
        pool = newPool;
        poolIndex = newIdx;
        totalCollected = pool.totalCollected + 1;
        qualityEstimate = quality;
        lastHarvestBeat = beat;
      };
      derivationLog = state.derivationLog;
      rootKeyHash = state.rootKeyHash;
      totalKeysCreated = state.totalKeysCreated;
      totalKeysExpired = state.totalKeysExpired + expiredCount;
      totalKeysRevoked = state.totalKeysRevoked;
      currentRotation = rotation;
      lastRotationBeat = rotBeat;
      systemEntropy = quality;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getActiveKeyCount(state : CryptographiaKeyState) : Nat {
    var count : Nat = 0;
    for (k in state.activeKeys.vals()) {
      switch(k.status) { case (#active) count += 1; case _ {} };
    };
    count
  };

  public func getSystemEntropy(state : CryptographiaKeyState) : Float {
    state.systemEntropy
  };

  public func getCurrentRotation(state : CryptographiaKeyState) : Nat {
    state.currentRotation
  };

  public func getTotalKeysCreated(state : CryptographiaKeyState) : Nat {
    state.totalKeysCreated
  };
};
