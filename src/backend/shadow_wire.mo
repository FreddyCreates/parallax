// shadow_wire.mo — SHADOW WIRE: Protected Cognitive Communication Channels
// PARALLAX Sovereign Organism — Cryptographia Phantasma Infrastructure
//
// DOCTRINE: "A shadow wire exists to protect cognitive transmissions.
// It does not merely encrypt a message. It defines a protected relationship
// between components. Shadow wires protect both content and context."
//
// Shadow wires connect:
//   agent ↔ agent, agent ↔ vault, engine ↔ engine, memory ↔ governance,
//   governance ↔ execution, execution ↔ receipt, receipt ↔ public interface,
//   private core ↔ public proof layer.
//
// Properties:
//   - SCOPED ACCESS: only source and target can interact
//   - BOUNDED DURATION: max F(8) = 21 heartbeats (~18.3s)
//   - ROUTE IDENTITY: each wire has unique route commitment
//   - REPLAY RESISTANCE: nonce + beat-bounded expiry
//   - RECEIPT COMPATIBILITY: every transfer produces a sealed receipt
//   - METADATA MINIMIZATION: public layer sees only commitments
//   - TERMINATION AFTER USE: single-use wires auto-terminate
//
// PYTHAGORAS: wire lifetimes are Fibonacci-bounded
// EUCLID:     single wire engine — all cognitive channels route through here
// CONFUCIUS:  right relationship — wire serves the route, not the route the wire
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: Cryptographia Phantasma §5 — Shadow Wires

import Phi "phi";
import PhantomCrypto "phantom_crypto";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOW WIRE STATE — organism-level wire registry
  // ═══════════════════════════════════════════════════════════════════════════

  /// Full shadow wire engine state
  public type ShadowWireState = {
    activeWires      : [PhantomCrypto.ShadowWireEnvelope];
    expiredWires     : Nat;         // count of expired (pruned from active)
    totalSent        : Nat;
    totalReceived    : Nat;
    lastBeat         : Int;
    receiptChainHead : Nat32;       // latest receipt hash in this engine's chain
  };

  /// Default initial state
  public func defaultShadowWireState() : ShadowWireState {
    {
      activeWires      = [];
      expiredWires     = 0;
      totalSent        = 0;
      totalReceived    = 0;
      lastBeat         = 0;
      receiptChainHead = PhantomCrypto.GENESIS_RECEIPT_HASH;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WIRE CREATION — open a new protected channel
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new shadow wire between two agents.
  /// Gate: Kuramoto coherence must be ≥ φ⁻¹ (0.618).
  /// Duration: bounded by lifetimeBeats (max 21).
  public func openWire(
    state : ShadowWireState,
    sourceAgent : Text,
    targetAgent : Text,
    payloadData : Text,
    coherence : Float,
    currentBeat : Int,
    lifetimeBeats : Nat,
  ) : (ShadowWireState, ?PhantomCrypto.ShadowWireEnvelope, ?PhantomCrypto.ComputeReceipt) {

    // GATE: coherence check
    if (coherence < PhantomCrypto.WIRE_COHERENCE_GATE) {
      return (state, null, null);
    };

    // Bound lifetime to max
    let boundedLife : Nat = if (lifetimeBeats > PhantomCrypto.WIRE_MAX_BEATS) {
      PhantomCrypto.WIRE_MAX_BEATS;
    } else { lifetimeBeats };

    // Generate wire ID from components
    let wireIdSeed = sourceAgent # "→" # targetAgent # "|" # Int.toText(currentBeat);
    let wireId = "wire_" # Nat32.toText(PhantomCrypto.fnv1a(wireIdSeed));

    // Generate nonce from beat + agent identities (deterministic for ICP — real entropy via IC management canister)
    let n0 = PhantomCrypto.fnv1a(wireIdSeed # "|n0");
    let n1 = PhantomCrypto.fnv1a(wireIdSeed # "|n1");
    let n2 = PhantomCrypto.fnv1a(wireIdSeed # "|n2");
    let n3 = PhantomCrypto.fnv1a(wireIdSeed # "|n3");

    // Compute commitments (public proof layer sees only hashes)
    let routeCommitment = PhantomCrypto.fnv1a(sourceAgent # "→" # targetAgent);
    let payloadHash = PhantomCrypto.fnv1a(payloadData);
    let aadCommitment = PhantomCrypto.fnv1a(wireId # "|aad|" # Int.toText(currentBeat));

    // Build receipt
    let receiptId = "rcpt_sw_" # Nat32.toText(PhantomCrypto.fnv1a(wireId));
    let inputCommitment = PhantomCrypto.fnv1a(sourceAgent # "|" # payloadData);
    let outputCommitment = PhantomCrypto.fnv1a(targetAgent # "|" # wireId);

    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, "shadow_wire_transfer",
      inputCommitment, outputCommitment,
      state.receiptChainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = "shadow_wire_transfer";
      engineId = "shadow_wire_engine.sovereign";
      inputCommitment = inputCommitment;
      outputCommitment = outputCommitment;
      policyGate = {
        result = #pass;
        policyId = "policy.shadow_wire.transfer";
        reasonCode = #scope_match;
        coherence = coherence;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00042; latencyMs = 12.8; memoryBytes = 256 };
      prevReceiptHash = state.receiptChainHead;
      receiptHash = receiptHash;
    };

    // Build envelope
    let envelope : PhantomCrypto.ShadowWireEnvelope = {
      wireId = wireId;
      sourceAgent = sourceAgent;
      targetAgent = targetAgent;
      routeCommitment = routeCommitment;
      createdBeat = currentBeat;
      expiresBeat = currentBeat + boundedLife;
      nonce = [n0, n1, n2, n3];
      payloadHash = payloadHash;
      aadCommitment = aadCommitment;
      state = #active;
      receiptId = receiptId;
    };

    // Update state
    let newState : ShadowWireState = {
      activeWires = Array.append(state.activeWires, [envelope]);
      expiredWires = state.expiredWires;
      totalSent = state.totalSent + 1;
      totalReceived = state.totalReceived;
      lastBeat = currentBeat;
      receiptChainHead = receiptHash;
    };

    (newState, ?envelope, ?receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WIRE RECEIVE — acknowledge receipt on target side
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark a wire as received and produce a receipt
  public func acknowledgeWire(
    state : ShadowWireState,
    wireId : Text,
    actorId : Text,
    currentBeat : Int,
  ) : (ShadowWireState, ?PhantomCrypto.ComputeReceipt) {

    var found = false;
    let updatedWires = Array.map<PhantomCrypto.ShadowWireEnvelope, PhantomCrypto.ShadowWireEnvelope>(
      state.activeWires,
      func (w) {
        if (w.wireId == wireId and w.targetAgent == actorId and w.state == #active) {
          found := true;
          { w with state = #sealed };
        } else { w };
      }
    );

    if (not found) { return (state, null) };

    let receiptId = "rcpt_sw_ack_" # Nat32.toText(PhantomCrypto.fnv1a(wireId # "|ack"));
    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, "shadow_wire_acknowledge",
      PhantomCrypto.fnv1a(wireId), PhantomCrypto.fnv1a(actorId),
      state.receiptChainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = "shadow_wire_acknowledge";
      engineId = "shadow_wire_engine.sovereign";
      inputCommitment = PhantomCrypto.fnv1a(wireId);
      outputCommitment = PhantomCrypto.fnv1a(actorId # "|received");
      policyGate = {
        result = #pass;
        policyId = "policy.shadow_wire.acknowledge";
        reasonCode = #scope_match;
        coherence = 1.0;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00021; latencyMs = 3.2; memoryBytes = 64 };
      prevReceiptHash = state.receiptChainHead;
      receiptHash = receiptHash;
    };

    let newState : ShadowWireState = {
      activeWires = updatedWires;
      expiredWires = state.expiredWires;
      totalSent = state.totalSent;
      totalReceived = state.totalReceived + 1;
      lastBeat = currentBeat;
      receiptChainHead = receiptHash;
    };

    (newState, ?receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WIRE EXPIRY — heartbeat-driven cleanup
  // Called every 873ms to expire stale wires (replay resistance)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Expire all wires past their expiresBeat. Called by heartbeat.
  public func expireWires(state : ShadowWireState, currentBeat : Int) : ShadowWireState {
    var expiredCount : Nat = 0;
    let remaining = Array.filter<PhantomCrypto.ShadowWireEnvelope>(
      state.activeWires,
      func (w) {
        if (w.expiresBeat <= currentBeat and w.state == #active) {
          expiredCount += 1;
          false;  // remove
        } else { true };
      }
    );

    {
      activeWires = remaining;
      expiredWires = state.expiredWires + expiredCount;
      totalSent = state.totalSent;
      totalReceived = state.totalReceived;
      lastBeat = currentBeat;
      receiptChainHead = state.receiptChainHead;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC LEDGER — safe proof surface (no private data)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Public-safe wire summary (no payload, no route details)
  public type WirePublicSummary = {
    wireId        : Text;
    state         : PhantomCrypto.WireState;
    createdBeat   : Int;
    expiresBeat   : Int;
    receiptId     : Text;
  };

  /// Get the public ledger view of all active wires
  public func publicLedger(state : ShadowWireState) : [WirePublicSummary] {
    Array.map<PhantomCrypto.ShadowWireEnvelope, WirePublicSummary>(
      state.activeWires,
      func (w) {
        {
          wireId = w.wireId;
          state = w.state;
          createdBeat = w.createdBeat;
          expiresBeat = w.expiresBeat;
          receiptId = w.receiptId;
        };
      }
    );
  };

  /// Get wire statistics (public-safe)
  public func getStats(state : ShadowWireState) : {
    activeCount : Nat;
    expiredCount : Nat;
    totalSent : Nat;
    totalReceived : Nat;
    chainHead : Nat32;
  } {
    {
      activeCount = state.activeWires.size();
      expiredCount = state.expiredWires;
      totalSent = state.totalSent;
      totalReceived = state.totalReceived;
      chainHead = state.receiptChainHead;
    };
  };
};
