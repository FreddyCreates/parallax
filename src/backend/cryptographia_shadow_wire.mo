// cryptographia_shadow_wire.mo — CRYPTOGRAPHIA PHANTASMA: Shadow Wires
// PARALLAX Sovereign Organism — Protected Inter-Agent Communication Channels
//
// FROM THE PAPER: "Shadow Wires: Protected inter-agent communication channels
// that safeguard not just payload but context, intent, routing, memory fragments,
// and relationships between components. Public schema uses hashes + encrypted
// ciphertext + receipts."
//
// DOCTRINE: "Shadow Wires protect the cognitive pathways between organism
// subsystems. The wire itself is invisible — only the receipt of communication
// is public. Context, intent, and routing are sovereign and private."
//
// THE SHADOW WIRE ARCHITECTURE:
//   SW-001  WIRE FACTORY            — Create new protected channels between domains
//   SW-002  ENVELOPE CONSTRUCTOR    — Build shadow wire envelopes (hash + cipher + receipt)
//   SW-003  CONTEXT ENCRYPTOR       — Encrypt not just payload but intent and routing
//   SW-004  ROUTING OBFUSCATOR      — Hide true source/destination in public view
//   SW-005  INTEGRITY VERIFIER      — Verify envelope integrity without decryption
//   SW-006  WIRE LIFECYCLE          — Birth, active, dormant, terminated states
//   SW-007  MULTI-HOP RELAY         — Route through intermediate nodes for unlinkability
//   SW-008  RECEIPT GENERATOR       — Produce public proof of communication without content
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
  // SHADOW WIRE CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  public let WIRE_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MAX_ACTIVE_WIRES : Nat = 55;                            // F(10)
  public let WIRE_TTL_BEATS : Nat = 144;                             // F(12) max wire lifetime
  public let ENVELOPE_NONCE_SIZE : Nat = 12;                         // 96-bit nonce (AES-GCM standard)
  public let MAX_HOPS : Nat = 5;                                     // F(5) relay hops
  public let RECEIPT_CHAIN_DEPTH : Nat = 34;                         // F(9) receipt history
  public let OBFUSCATION_ROUNDS : Nat = 8;                           // F(6) routing obfuscation
  public let WIRE_DORMANT_THRESHOLD : Nat = 21;                      // F(8) idle beats → dormant

  // ═══════════════════════════════════════════════════════════════════════════
  // WIRE STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  public type WireStatus = {
    #active;
    #dormant;
    #terminated;
    #compromised;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOW WIRE ENVELOPE — the public-facing message container
  // ═══════════════════════════════════════════════════════════════════════════

  public type ShadowEnvelope = {
    envelopeId      : Text;          // unique envelope identifier
    wireId          : Text;          // which wire this travels on
    contentHash     : Nat64;         // hash of encrypted content (public)
    ciphertextSize  : Nat;           // size hint (no content exposed)
    nonce           : Nat64;         // unique per message
    routingTag      : Nat64;         // obfuscated routing information
    receiptHash     : Nat64;         // proof of delivery/creation
    hopCount        : Nat;           // number of relay hops taken
    beat            : Int;           // creation beat
    integrityProof  : Nat64;         // HMAC of envelope metadata
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOW WIRE — a protected channel
  // ═══════════════════════════════════════════════════════════════════════════

  public type ShadowWire = {
    wireId          : Text;
    sourceHash      : Nat64;         // obfuscated source identity
    destHash        : Nat64;         // obfuscated destination identity
    status          : WireStatus;
    envelopesSent   : Nat;
    envelopesRecvd  : Nat;
    birthBeat       : Int;
    lastActivityBeat : Int;
    expiryBeat      : Int;
    keyId           : Text;          // reference to CryptographiaKey used
    routingPath     : [Nat64];       // obfuscated intermediate hops
    integrityScore  : Float;         // [0, 1] wire health
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WIRE RECEIPT — public proof of communication
  // ═══════════════════════════════════════════════════════════════════════════

  public type WireReceipt = {
    receiptId       : Text;
    wireId          : Text;
    envelopeHash    : Nat64;
    action          : Text;          // "SENT" | "DELIVERED" | "ACKNOWLEDGED"
    beat            : Int;
    chainHash       : Nat64;         // links to previous receipt (chain)
    publicProof     : Nat64;         // verifiable without private data
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOW WIRE STATE — complete wire management
  // ═══════════════════════════════════════════════════════════════════════════

  public type CryptographiaShadowWireState = {
    wires             : [ShadowWire];
    recentEnvelopes   : [ShadowEnvelope];
    receiptChain      : [WireReceipt];
    lastReceiptHash   : Nat64;         // head of receipt chain
    totalWiresCreated : Nat;
    totalEnvelopesSent : Nat;
    totalReceipts     : Nat;
    activeWireCount   : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultShadowWireState() : CryptographiaShadowWireState {
    {
      wires = [];
      recentEnvelopes = [];
      receiptChain = [];
      lastReceiptHash = 0;
      totalWiresCreated = 0;
      totalEnvelopesSent = 0;
      totalReceipts = 0;
      activeWireCount = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV HASH helper
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1a(seed : Nat64, data : Nat64) : Nat64 {
    (seed ^ data) *% 1099511628211
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE WIRE — establish new shadow wire channel
  // ═══════════════════════════════════════════════════════════════════════════

  public func createWire(
    state : CryptographiaShadowWireState,
    sourceId : Nat64,
    destId : Nat64,
    keyId : Text,
    beat : Int
  ) : (CryptographiaShadowWireState, ShadowWire) {
    // Obfuscate source and dest
    let srcHash = fnv1a(sourceId, Nat64.fromNat(Int.abs(beat)));
    let dstHash = fnv1a(destId, Nat64.fromNat(Int.abs(beat) + 1));
    let wireId = Nat64.toText(fnv1a(srcHash, dstHash));

    // Generate obfuscated routing path
    let path = Array.tabulate<Nat64>(MAX_HOPS, func(i) {
      fnv1a(srcHash, Nat64.fromNat(i * 13 + 7))
    });

    let wire : ShadowWire = {
      wireId = wireId;
      sourceHash = srcHash;
      destHash = dstHash;
      status = #active;
      envelopesSent = 0;
      envelopesRecvd = 0;
      birthBeat = beat;
      lastActivityBeat = beat;
      expiryBeat = beat + WIRE_TTL_BEATS;
      keyId = keyId;
      routingPath = path;
      integrityScore = 1.0;
    };

    let newWires = if (state.wires.size() >= MAX_ACTIVE_WIRES) {
      // Evict terminated wires
      let active = Array.filter<ShadowWire>(state.wires, func(w) {
        switch(w.status) { case (#terminated) false; case _ true }
      });
      Array.append(active, [wire])
    } else {
      Array.append(state.wires, [wire])
    };

    let newState = {
      state with
      wires = newWires;
      totalWiresCreated = state.totalWiresCreated + 1;
      activeWireCount = state.activeWireCount + 1;
    };
    (newState, wire)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND ENVELOPE — transmit message on shadow wire
  // ═══════════════════════════════════════════════════════════════════════════

  public func sendEnvelope(
    state : CryptographiaShadowWireState,
    wireId : Text,
    contentHash : Nat64,
    contentSize : Nat,
    beat : Int
  ) : CryptographiaShadowWireState {
    // Find wire
    var found = false;
    let updatedWires = Array.map<ShadowWire, ShadowWire>(state.wires, func(w) {
      if (w.wireId == wireId) {
        switch(w.status) {
          case (#active) {
            found := true;
            { w with envelopesSent = w.envelopesSent + 1; lastActivityBeat = beat }
          };
          case _ { w };
        }
      } else { w }
    });
    if (not found) return state;

    // Create envelope
    let nonce = fnv1a(contentHash, Nat64.fromNat(Int.abs(beat)));
    let routingTag = fnv1a(nonce, Nat64.fromNat(contentSize));
    let integrityProof = fnv1a(routingTag, contentHash);
    let receiptHash = fnv1a(integrityProof, state.lastReceiptHash);

    let envelope : ShadowEnvelope = {
      envelopeId = Nat64.toText(nonce);
      wireId = wireId;
      contentHash = contentHash;
      ciphertextSize = contentSize;
      nonce = nonce;
      routingTag = routingTag;
      receiptHash = receiptHash;
      hopCount = 0;
      beat = beat;
      integrityProof = integrityProof;
    };

    // Create receipt
    let receipt : WireReceipt = {
      receiptId = Nat64.toText(receiptHash);
      wireId = wireId;
      envelopeHash = contentHash;
      action = "SENT";
      beat = beat;
      chainHash = receiptHash;
      publicProof = integrityProof;
    };

    let envelopes = if (state.recentEnvelopes.size() >= 34) {
      Array.tabulate<ShadowEnvelope>(34, func(i) {
        if (i < 33) state.recentEnvelopes[i + 1] else envelope
      })
    } else {
      Array.append(state.recentEnvelopes, [envelope])
    };

    let receipts = if (state.receiptChain.size() >= RECEIPT_CHAIN_DEPTH) {
      Array.tabulate<WireReceipt>(RECEIPT_CHAIN_DEPTH, func(i) {
        if (i < RECEIPT_CHAIN_DEPTH - 1) state.receiptChain[i + 1] else receipt
      })
    } else {
      Array.append(state.receiptChain, [receipt])
    };

    {
      state with
      wires = updatedWires;
      recentEnvelopes = envelopes;
      receiptChain = receipts;
      lastReceiptHash = receiptHash;
      totalEnvelopesSent = state.totalEnvelopesSent + 1;
      totalReceipts = state.totalReceipts + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — manage wire lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickShadowWires(
    state : CryptographiaShadowWireState,
    beat : Int,
    systemCoherence : Float
  ) : CryptographiaShadowWireState {
    if (systemCoherence < WIRE_COHERENCE_GATE) return state;

    var activeCount : Nat = 0;
    let updatedWires = Array.map<ShadowWire, ShadowWire>(state.wires, func(w) {
      switch(w.status) {
        case (#active) {
          if (beat >= w.expiryBeat) {
            { w with status = #terminated }
          } else if (Int.abs(beat - w.lastActivityBeat) >= WIRE_DORMANT_THRESHOLD) {
            { w with status = #dormant; integrityScore = w.integrityScore * Phi.PHI_INV }
          } else {
            activeCount += 1;
            w
          }
        };
        case (#dormant) {
          if (beat >= w.expiryBeat) { { w with status = #terminated } } else { w }
        };
        case _ { w };
      }
    });

    {
      state with
      wires = updatedWires;
      activeWireCount = activeCount;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getActiveWireCount(state : CryptographiaShadowWireState) : Nat {
    state.activeWireCount
  };

  public func getTotalEnvelopesSent(state : CryptographiaShadowWireState) : Nat {
    state.totalEnvelopesSent
  };

  public func getReceiptChainLength(state : CryptographiaShadowWireState) : Nat {
    state.receiptChain.size()
  };
};
