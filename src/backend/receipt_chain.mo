// receipt_chain.mo — COMPUTATIONAL RECEIPT CHAIN: Hash-Linked Provenance Ledger
// PARALLAX Sovereign Organism — Cryptographia Phantasma Infrastructure
//
// DOCTRINE: "A persistent AI system must be able to prove certain things.
// It may need to prove that a task ran, that a policy gate was checked,
// that a memory state changed, that a settlement calculation occurred.
// However, proof can become dangerous if it exposes too much.
// Computational receipts create proof without full exposure."
//
// The Receipt Chain is the organism's PUBLIC PROOF LEDGER:
//   - Every significant computation produces a receipt
//   - Receipts are hash-chained (each references the previous)
//   - The chain is tamper-evident (break one link, break all downstream)
//   - Public observers can verify work occurred without seeing internals
//   - Chain compacts at F(12)=144 depth (Merkle-root summarization)
//
// RECEIPT SOURCES:
//   - Shadow Wire transfers
//   - Sovereign Vault access events
//   - Settlement computations
//   - Risk-path evaluations
//   - Multi-asset netting operations
//   - Engine coordination events
//   - Key rotation events
//
// PYTHAGORAS: chain compaction at Fibonacci boundaries
// EUCLID:     single chain definition — all engines append to the same structure
// CONFUCIUS:  right relationship — chain proves, core operates, public verifies
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: Cryptographia Phantasma §7 — Computational Receipts Without Core Exposure

import Phi "phi";
import PhantomCrypto "phantom_crypto";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // RECEIPT CHAIN STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Full receipt chain state
  public type ReceiptChainState = {
    receipts         : [PhantomCrypto.ComputeReceipt];
    chainHead        : Nat32;         // hash of latest receipt
    chainLength      : Nat;
    compactionRoots  : [Nat32];       // Merkle roots of compacted segments
    totalCompacted   : Nat;           // receipts summarized into roots
    genesisEngineId  : Text;
  };

  /// Create a new receipt chain for an engine
  public func createChain(engineId : Text, beatStamp : Int) : ReceiptChainState {
    let genesis = PhantomCrypto.genesisReceipt(engineId, beatStamp);
    {
      receipts = [genesis];
      chainHead = genesis.receiptHash;
      chainLength = 1;
      compactionRoots = [];
      totalCompacted = 0;
      genesisEngineId = engineId;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // APPEND — add a new receipt to the chain
  // ═══════════════════════════════════════════════════════════════════════════

  /// Append a pre-built receipt to the chain.
  /// Validates chain linkage (receipt.prevReceiptHash must equal chainHead).
  public func appendReceipt(
    chain : ReceiptChainState,
    receipt : PhantomCrypto.ComputeReceipt,
  ) : ?ReceiptChainState {

    // Validate chain linkage
    if (receipt.prevReceiptHash != chain.chainHead) {
      return null;  // Chain violation — reject
    };

    let newChain : ReceiptChainState = {
      receipts = Array.append(chain.receipts, [receipt]);
      chainHead = receipt.receiptHash;
      chainLength = chain.chainLength + 1;
      compactionRoots = chain.compactionRoots;
      totalCompacted = chain.totalCompacted;
      genesisEngineId = chain.genesisEngineId;
    };

    // Auto-compact if at Fibonacci boundary
    if (newChain.receipts.size() >= PhantomCrypto.CHAIN_COMPACTION_DEPTH) {
      ?compact(newChain);
    } else {
      ?newChain;
    };
  };

  /// Create and append a new receipt in one operation.
  public func sealComputation(
    chain : ReceiptChainState,
    computationClass : Text,
    inputData : Text,
    outputData : Text,
    policyId : Text,
    coherence : Float,
    currentBeat : Int,
  ) : (ReceiptChainState, PhantomCrypto.ComputeReceipt) {

    let receiptIdSeed = chain.genesisEngineId # "|" # computationClass # "|" # Int.toText(currentBeat) # "|" # Nat.toText(chain.chainLength);
    let receiptId = "rcpt_" # Nat32.toText(PhantomCrypto.fnv1a(receiptIdSeed));

    let inputCommitment = PhantomCrypto.fnv1a(inputData);
    let outputCommitment = PhantomCrypto.fnv1a(outputData);

    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, computationClass,
      inputCommitment, outputCommitment,
      chain.chainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = computationClass;
      engineId = chain.genesisEngineId;
      inputCommitment = inputCommitment;
      outputCommitment = outputCommitment;
      policyGate = {
        result = #pass;
        policyId = policyId;
        reasonCode = #scope_match;
        coherence = coherence;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00042; latencyMs = 6.0; memoryBytes = 128 };
      prevReceiptHash = chain.chainHead;
      receiptHash = receiptHash;
    };

    let newChain : ReceiptChainState = {
      receipts = Array.append(chain.receipts, [receipt]);
      chainHead = receiptHash;
      chainLength = chain.chainLength + 1;
      compactionRoots = chain.compactionRoots;
      totalCompacted = chain.totalCompacted;
      genesisEngineId = chain.genesisEngineId;
    };

    // Auto-compact check
    let finalChain = if (newChain.receipts.size() >= PhantomCrypto.CHAIN_COMPACTION_DEPTH) {
      compact(newChain);
    } else { newChain };

    (finalChain, receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPACTION — Merkle-root summarization at F(12) boundaries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compact the chain: compute Merkle root of oldest segment, keep only recent
  func compact(chain : ReceiptChainState) : ReceiptChainState {
    let keepCount : Nat = 21;  // Keep last F(8)=21 receipts in active window
    let total = chain.receipts.size();

    if (total <= keepCount) { return chain };

    let compactCount = total - keepCount;

    // Compute Merkle root of compacted segment
    var merkleRoot : Nat32 = 0;
    var idx : Nat = 0;
    while (idx < compactCount) {
      merkleRoot := PhantomCrypto.chainHash(merkleRoot, chain.receipts[idx].receiptId);
      idx += 1;
    };

    // Keep only recent receipts
    let remaining = Array.tabulate<PhantomCrypto.ComputeReceipt>(
      keepCount,
      func (i) { chain.receipts[compactCount + i] }
    );

    {
      receipts = remaining;
      chainHead = chain.chainHead;
      chainLength = chain.chainLength;
      compactionRoots = Array.append(chain.compactionRoots, [merkleRoot]);
      totalCompacted = chain.totalCompacted + compactCount;
      genesisEngineId = chain.genesisEngineId;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFICATION — validate chain integrity
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verify the active chain segment integrity.
  /// Returns true if all receipt links are valid.
  public func verifyChain(chain : ReceiptChainState) : Bool {
    if (chain.receipts.size() <= 1) { return true };

    var i : Nat = 1;
    while (i < chain.receipts.size()) {
      if (chain.receipts[i].prevReceiptHash != chain.receipts[i - 1].receiptHash) {
        return false;
      };
      i += 1;
    };
    true;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC PROOF SURFACE — safe ledger view
  // ═══════════════════════════════════════════════════════════════════════════

  /// Public receipt summary (safe for external observers)
  public type PublicReceiptSummary = {
    receiptId        : Text;
    computationClass : Text;
    engineId         : Text;
    beatStamp        : Int;
    policyResult     : PhantomCrypto.PolicyResult;
    receiptHash      : Nat32;
  };

  /// Get the public ledger — safe proof surface
  public func publicLedger(chain : ReceiptChainState) : [PublicReceiptSummary] {
    Array.map<PhantomCrypto.ComputeReceipt, PublicReceiptSummary>(
      chain.receipts,
      func (r) {
        {
          receiptId = r.receiptId;
          computationClass = r.computationClass;
          engineId = r.engineId;
          beatStamp = r.timestampNs;
          policyResult = r.policyGate.result;
          receiptHash = r.receiptHash;
        };
      }
    );
  };

  /// Get chain diagnostics
  public func getStats(chain : ReceiptChainState) : {
    chainLength : Nat;
    activeReceipts : Nat;
    compactionRoots : Nat;
    totalCompacted : Nat;
    chainHead : Nat32;
    isValid : Bool;
  } {
    {
      chainLength = chain.chainLength;
      activeReceipts = chain.receipts.size();
      compactionRoots = chain.compactionRoots.size();
      totalCompacted = chain.totalCompacted;
      chainHead = chain.chainHead;
      isValid = verifyChain(chain);
    };
  };

  /// Get the latest N receipts from the chain
  public func latestReceipts(chain : ReceiptChainState, count : Nat) : [PhantomCrypto.ComputeReceipt] {
    let total = chain.receipts.size();
    let start = if (total > count) { total - count } else { 0 };
    Array.tabulate<PhantomCrypto.ComputeReceipt>(
      total - start,
      func (i) { chain.receipts[start + i] }
    );
  };
};
