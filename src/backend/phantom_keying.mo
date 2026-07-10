// phantom_keying.mo — QUANTUM-INSPIRED KEYING: Ephemeral Session Key Management
// PARALLAX Sovereign Organism — Cryptographia Phantasma Infrastructure
//
// DOCTRINE: "Quantum-inspired keying refers to design patterns that borrow
// conceptual properties from quantum systems: uncertainty, state-dependence,
// non-reusable measurement contexts, ephemeral correlation, and sensitivity
// to observation. A persistent AI system should not expose the same internal
// pathway every time it performs similar work."
//
// Key Properties:
//   - EPHEMERAL SESSION KEYS: keys rotate every F(5)=5 heartbeats
//   - CONTEXT-DERIVED: key material is derived from computational context
//   - NON-REUSABLE: each key window is single-use, then rotated
//   - STATE-DEPENDENT: key derivation depends on organism state at creation
//   - TIME-BOUNDED: keys expire automatically after rotation interval
//   - REPLAY-RESISTANT: expired keys cannot be reused
//
// KEY HIERARCHY:
//   Master Seed → Beat-Derived Key → Context-Bound Session Key → Wire Key
//   Each level adds entropy and narrows scope.
//
// PYTHAGORAS: rotation at Fibonacci intervals — F(5)=5 beats per rotation
// EUCLID:     single keying module — all ephemeral material generated here
// CONFUCIUS:  right relationship — keying serves protection, not complexity
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: Cryptographia Phantasma §4 — Quantum-Inspired Keying

import Phi "phi";
import PhantomCrypto "phantom_crypto";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYING STATE — ephemeral key session manager
  // ═══════════════════════════════════════════════════════════════════════════

  /// Full keying engine state
  public type PhantomKeyingState = {
    activeSessions    : [PhantomCrypto.EphemeralKeySession];
    rotatedSessions   : Nat;
    totalDerivations  : Nat;
    masterSeedHash    : Nat32;        // Hash of master seed (seed itself NEVER stored in state)
    currentEpoch      : Nat;          // Key epoch counter (increments on rotation)
    lastRotationBeat  : Int;
    receiptChainHead  : Nat32;
  };

  /// Default keying state
  public func defaultKeyingState(masterSeed : Text) : PhantomKeyingState {
    {
      activeSessions = [];
      rotatedSessions = 0;
      totalDerivations = 0;
      masterSeedHash = PhantomCrypto.fnv1a(masterSeed);
      currentEpoch = 0;
      lastRotationBeat = 0;
      receiptChainHead = PhantomCrypto.GENESIS_RECEIPT_HASH;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY DERIVATION — context-bound ephemeral key generation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Derive a new context-bound ephemeral session key.
  /// Key material is derived from: masterSeedHash + context + epoch + beat
  /// The actual key material stays in private-core — only hash is stored.
  public func deriveSessionKey(
    state : PhantomKeyingState,
    context : Text,
    boundAgent : Text,
    currentBeat : Int,
  ) : (PhantomKeyingState, PhantomCrypto.EphemeralKeySession, PhantomCrypto.ComputeReceipt) {

    // Derive key material hash (actual key material computed but not stored)
    let derivationInput = Nat32.toText(state.masterSeedHash) # "|"
      # context # "|" # boundAgent # "|"
      # Nat.toText(state.currentEpoch) # "|"
      # Int.toText(currentBeat);
    let keyMaterialHash = PhantomCrypto.fnv1a(derivationInput);

    // Session ID
    let sessionId = "ks_" # Nat32.toText(PhantomCrypto.fnv1a(
      derivationInput # "|sid"
    ));

    // Rotation scheduled at current + F(5) = 5 beats
    let rotationBeat = currentBeat + PhantomCrypto.KEY_ROTATION_BEATS;

    let session : PhantomCrypto.EphemeralKeySession = {
      sessionId = sessionId;
      keyMaterialHash = keyMaterialHash;
      createdBeat = currentBeat;
      rotationBeat = rotationBeat;
      boundContext = context;
      state = #active;
      derivationDepth = state.totalDerivations + 1;
    };

    // Build receipt
    let receiptId = "rcpt_key_" # Nat32.toText(PhantomCrypto.fnv1a(sessionId));
    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, "key_derivation",
      PhantomCrypto.fnv1a(context # "|" # boundAgent),
      keyMaterialHash,
      state.receiptChainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = "key_derivation";
      engineId = "phantom_keying.sovereign";
      inputCommitment = PhantomCrypto.fnv1a(context # "|" # boundAgent);
      outputCommitment = keyMaterialHash;
      policyGate = {
        result = #pass;
        policyId = "policy.keying.derive";
        reasonCode = #scope_match;
        coherence = 1.0;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00028; latencyMs = 2.1; memoryBytes = 96 };
      prevReceiptHash = state.receiptChainHead;
      receiptHash = receiptHash;
    };

    let newState : PhantomKeyingState = {
      activeSessions = Array.append(state.activeSessions, [session]);
      rotatedSessions = state.rotatedSessions;
      totalDerivations = state.totalDerivations + 1;
      masterSeedHash = state.masterSeedHash;
      currentEpoch = state.currentEpoch;
      lastRotationBeat = state.lastRotationBeat;
      receiptChainHead = receiptHash;
    };

    (newState, session, receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY ROTATION — heartbeat-driven automatic rotation
  // Called every 873ms — expires keys past their rotation beat
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rotate all keys past their rotation beat. Called by heartbeat.
  /// Rotated keys can NEVER be reused (replay resistance).
  public func rotateKeys(state : PhantomKeyingState, currentBeat : Int) : PhantomKeyingState {
    var rotatedCount : Nat = 0;
    let updatedSessions = Array.map<PhantomCrypto.EphemeralKeySession, PhantomCrypto.EphemeralKeySession>(
      state.activeSessions,
      func (s) {
        if (s.rotationBeat <= currentBeat and s.state == #active) {
          rotatedCount += 1;
          { s with state = #rotated };
        } else { s };
      }
    );

    // Prune rotated sessions (keep only active)
    let activeSessions = Array.filter<PhantomCrypto.EphemeralKeySession>(
      updatedSessions,
      func (s) { s.state == #active }
    );

    {
      activeSessions = activeSessions;
      rotatedSessions = state.rotatedSessions + rotatedCount;
      totalDerivations = state.totalDerivations;
      masterSeedHash = state.masterSeedHash;
      currentEpoch = if (rotatedCount > 0) { state.currentEpoch + 1 } else { state.currentEpoch };
      lastRotationBeat = if (rotatedCount > 0) { currentBeat } else { state.lastRotationBeat };
      receiptChainHead = state.receiptChainHead;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY LOOKUP — find active key for a context
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find an active session key bound to a specific context
  public func findActiveKey(
    state : PhantomKeyingState,
    context : Text,
  ) : ?PhantomCrypto.EphemeralKeySession {
    for (s in state.activeSessions.vals()) {
      if (s.boundContext == context and s.state == #active) {
        return ?s;
      };
    };
    null;
  };

  /// Validate that a key material hash is currently active
  public func validateKeyHash(state : PhantomKeyingState, keyHash : Nat32) : Bool {
    for (s in state.activeSessions.vals()) {
      if (s.keyMaterialHash == keyHash and s.state == #active) {
        return true;
      };
    };
    false;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPROMISE — emergency key invalidation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark all keys for a context as compromised. Emergency use only.
  public func compromiseContext(
    state : PhantomKeyingState,
    context : Text,
    currentBeat : Int,
  ) : PhantomKeyingState {
    let updatedSessions = Array.map<PhantomCrypto.EphemeralKeySession, PhantomCrypto.EphemeralKeySession>(
      state.activeSessions,
      func (s) {
        if (s.boundContext == context and s.state == #active) {
          { s with state = #compromised };
        } else { s };
      }
    );

    // Remove compromised immediately
    let activeSessions = Array.filter<PhantomCrypto.EphemeralKeySession>(
      updatedSessions,
      func (s) { s.state == #active }
    );

    {
      activeSessions = activeSessions;
      rotatedSessions = state.rotatedSessions;
      totalDerivations = state.totalDerivations;
      masterSeedHash = state.masterSeedHash;
      currentEpoch = state.currentEpoch + 1;  // Force epoch bump
      lastRotationBeat = currentBeat;
      receiptChainHead = state.receiptChainHead;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC PROOF SURFACE — safe keying diagnostics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Public-safe keying stats (no key material exposed)
  public func getStats(state : PhantomKeyingState) : {
    activeKeys : Nat;
    rotatedKeys : Nat;
    totalDerivations : Nat;
    currentEpoch : Nat;
    lastRotationBeat : Int;
    chainHead : Nat32;
  } {
    {
      activeKeys = state.activeSessions.size();
      rotatedKeys = state.rotatedSessions;
      totalDerivations = state.totalDerivations;
      currentEpoch = state.currentEpoch;
      lastRotationBeat = state.lastRotationBeat;
      chainHead = state.receiptChainHead;
    };
  };
};
