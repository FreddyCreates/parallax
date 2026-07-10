// phantom_crypto.mo — CRYPTOGRAPHIA PHANTASMA: Core Types & Constants
// PARALLAX Sovereign Organism — Protected Cognition Infrastructure
//
// DOCTRINE: "Security is not merely encryption applied to data. Security becomes
// a structural property of cognition itself. A sovereign intelligence must be able
// to prove without surrendering its core. It must remember without leaking its memory.
// It must route without exposing its nervous system."
//
// This module defines the foundational types for Phantom Cryptography:
//   1. RECEIPT STRUCTURES — proof objects without core exposure
//   2. POLICY GATES — governance decisions as sealed events
//   3. COMMITMENT TYPES — hash commitments for private-core/public-proof separation
//   4. WIRE IDENTIFIERS — scoped, bounded, replay-resistant channel IDs
//   5. VAULT EVENTS — governed memory access records
//
// RELATIONSHIP TO PARALLAX:
//   Protected settlement computations, private risk-path evaluation,
//   sealed clearinghouse receipts, multi-asset netting commitments,
//   protocol memory boundaries, private coordination between engines.
//
// PYTHAGORAS: receipt chain hashes use FNV-1a (phi-native) — same as organism doctrine
// EUCLID:     single receipt specification — all modules produce the same proof format
// CONFUCIUS:  right relationship — private core operates, public proof verifies
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: Cryptographia Phantasma (2026-06-08)

import Phi "phi";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Int "mo:core/Int";
import Float "mo:core/Float";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM CONSTANTS — cryptographic parameters derived from phi
  // ═══════════════════════════════════════════════════════════════════════════

  /// Receipt specification version
  public let SPEC_VERSION : Text = "0.1.0";

  /// Maximum shadow wire lifespan: F(8) = 21 heartbeats (~18.3 seconds)
  public let WIRE_MAX_BEATS : Nat = 21;

  /// Minimum coherence to open a shadow wire: φ⁻¹ = 0.618
  public let WIRE_COHERENCE_GATE : Float = Phi.PHI_INV;

  /// Vault access requires governance gate: φ⁻¹ coherence minimum
  public let VAULT_ACCESS_GATE : Float = Phi.PHI_INV;

  /// Receipt chain depth before compaction: F(12) = 144
  public let CHAIN_COMPACTION_DEPTH : Nat = 144;

  /// Ephemeral key rotation interval: F(5) = 5 heartbeats (~4.365 seconds)
  public let KEY_ROTATION_BEATS : Nat = 5;

  /// Nonce entropy size in Nat32 words
  public let NONCE_WORDS : Nat = 4;

  // ═══════════════════════════════════════════════════════════════════════════
  // POLICY GATE — governance decision record (sealed, immutable)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Policy gate result
  public type PolicyResult = { #pass; #deny; #abstain };

  /// Reason codes for policy decisions
  public type PolicyReasonCode = {
    #scope_match;
    #least_privilege;
    #coherence_met;
    #coherence_failed;
    #expired;
    #replay_detected;
    #unauthorized_actor;
    #quarantined;
  };

  /// A sealed policy gate decision
  public type PolicyGate = {
    result     : PolicyResult;
    policyId   : Text;
    reasonCode : PolicyReasonCode;
    coherence  : Float;           // Kuramoto R at decision time
    beatStamp  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTATIONAL RECEIPT — proof without core exposure
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resource summary for a computation
  public type ResourceSummary = {
    cyclesEstimated : Float;
    latencyMs       : Float;
    memoryBytes     : Nat;
  };

  /// A sealed computational receipt — the fundamental proof object
  public type ComputeReceipt = {
    receiptId         : Text;           // unique identifier
    specVersion       : Text;           // "0.1.0"
    timestampNs       : Int;            // nanosecond timestamp
    computationClass  : Text;           // "shadow_wire_transfer" | "vault_access" | "settlement" | etc.
    engineId          : Text;           // producing engine
    inputCommitment   : Nat32;          // FNV-1a hash of input
    outputCommitment  : Nat32;          // FNV-1a hash of output
    policyGate        : PolicyGate;     // governance gate result
    resourceSummary   : ResourceSummary;
    prevReceiptHash   : Nat32;          // chain link to previous receipt (GENESIS = 0)
    receiptHash       : Nat32;          // self-hash for chain integrity
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOW WIRE TYPES — protected cognitive channels
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shadow wire state
  public type WireState = { #active; #expired; #terminated; #sealed };

  /// Shadow wire envelope — carries encrypted payload + public proof
  public type ShadowWireEnvelope = {
    wireId          : Text;
    sourceAgent     : Text;
    targetAgent     : Text;
    routeCommitment : Nat32;         // hash of route — route itself is private
    createdBeat     : Int;
    expiresBeat     : Int;
    nonce           : [Nat32];       // 4 × Nat32 = 128-bit nonce
    payloadHash     : Nat32;         // commitment to encrypted payload
    aadCommitment   : Nat32;         // associated authenticated data commitment
    state           : WireState;
    receiptId       : Text;          // linked receipt
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN VAULT TYPES — governed memory structures
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vault entry access level
  public type VaultAccessLevel = {
    #private_core;       // Only internal organism
    #abstracted;         // Returns commitment, not plaintext
    #governed_read;      // Requires policy gate pass
    #sealed;             // Cannot be accessed again — one-time read
  };

  /// Vault event type
  public type VaultEventType = {
    #vault_write;
    #vault_read_exact;
    #vault_read_abstracted;
    #vault_seal;
    #vault_expire;
    #vault_governance_check;
  };

  /// A vault access event — recorded in receipt chain
  public type VaultEvent = {
    eventId          : Text;
    vaultIdHash      : Nat32;         // hash of vault identity — vault ID is private
    eventType        : VaultEventType;
    timestampNs      : Int;
    actorId          : Text;          // requesting agent
    entryCommitment  : Nat32;         // hash of entry — content is private
    policyGate       : PolicyGate;
    receiptId        : Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYING TYPES — quantum-inspired ephemeral key management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Key material state
  public type KeyState = { #active; #rotated; #expired; #compromised };

  /// Ephemeral key session record
  public type EphemeralKeySession = {
    sessionId        : Text;
    keyMaterialHash  : Nat32;         // hash of key — key material is NEVER exposed
    createdBeat      : Int;
    rotationBeat     : Int;           // scheduled rotation
    boundContext     : Text;          // context this key is bound to
    state            : KeyState;
    derivationDepth  : Nat;           // how many rotations from genesis
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH — the organism's native hashing function
  // Mirrors phi.mo doctrine hash — single source of truth
  // ═══════════════════════════════════════════════════════════════════════════

  /// FNV-1a hash a text string to Nat32
  public func fnv1a(data : Text) : Nat32 {
    var hash : Nat32 = 2_166_136_261; // FNV offset basis — prime
    for (c in data.chars()) {
      hash := (hash ^ c.toNat32()) *% 16_777_619; // FNV prime
    };
    hash;
  };

  /// Chain two FNV hashes together (for receipt chain linking)
  public func chainHash(prev : Nat32, current : Text) : Nat32 {
    let combined = Nat32.toText(prev) # "|" # current;
    fnv1a(combined);
  };

  /// Compute a receipt's self-hash from its components
  public func computeReceiptHash(
    receiptId : Text,
    computationClass : Text,
    inputCommitment : Nat32,
    outputCommitment : Nat32,
    prevHash : Nat32,
    beatStamp : Int,
  ) : Nat32 {
    let payload = receiptId # "|" # computationClass # "|"
      # Nat32.toText(inputCommitment) # "|"
      # Nat32.toText(outputCommitment) # "|"
      # Nat32.toText(prevHash) # "|"
      # Int.toText(beatStamp);
    fnv1a(payload);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS RECEIPT — root of all phantom receipt chains
  // ═══════════════════════════════════════════════════════════════════════════

  /// The genesis hash for receipt chains — all chains start here
  public let GENESIS_RECEIPT_HASH : Nat32 = 0;

  /// Create the genesis receipt for a new chain
  public func genesisReceipt(engineId : Text, beatStamp : Int) : ComputeReceipt {
    let receiptId = "GENESIS_" # engineId;
    {
      receiptId = receiptId;
      specVersion = SPEC_VERSION;
      timestampNs = beatStamp;
      computationClass = "genesis";
      engineId = engineId;
      inputCommitment = 0 : Nat32;
      outputCommitment = 0 : Nat32;
      policyGate = {
        result = #pass;
        policyId = "policy.genesis";
        reasonCode = #scope_match;
        coherence = 1.0;
        beatStamp = beatStamp;
      };
      resourceSummary = { cyclesEstimated = 0.0; latencyMs = 0.0; memoryBytes = 0 };
      prevReceiptHash = GENESIS_RECEIPT_HASH;
      receiptHash = fnv1a(receiptId # "|genesis|" # Int.toText(beatStamp));
    };
  };
};
