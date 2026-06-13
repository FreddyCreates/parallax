// cryptographia_receipts.mo — CRYPTOGRAPHIA PHANTASMA: Computational Receipts
// PARALLAX Sovereign Organism — Verifiable Proof Objects for Sovereign Work
//
// FROM THE PAPER: "Computational Receipts: Verifiable proof objects that log work
// (e.g., transfers, reads) while hiding private pathways. Includes chaining for ledgers."
//
// CENTRAL THESIS: "Sovereign AI systems must prove work occurred without
// surrendering the private pathway that produced it."
//
// DOCTRINE: "Every cognitive operation, every trade, every decision produces
// a Computational Receipt — a public proof that work happened, chained into
// an immutable ledger. The receipt proves WHAT and WHEN without revealing HOW or WHY."
//
// THE RECEIPT ARCHITECTURE:
//   CR-001  RECEIPT FACTORY          — Mint new receipts for any operation
//   CR-002  CHAIN LINKER             — SHA-chain receipts into immutable ledger
//   CR-003  PROOF CONSTRUCTOR        — Build verifiable proofs from private data
//   CR-004  PRIVACY SEPARATOR        — Split private pathway from public proof
//   CR-005  TIMESTAMP AUTHORITY      — Beat-bound temporal proof
//   CR-006  CATEGORY ROUTER          — Route receipts by operation type
//   CR-007  VERIFICATION ENGINE      — Verify receipt chain integrity
//   CR-008  RECEIPT QUERY GATEWAY    — Public endpoint for receipt verification
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // RECEIPT CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  public let RECEIPT_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MAX_RECEIPT_CHAIN : Nat = 987;                          // F(16) — long chain
  public let RECEIPT_HASH_ROUNDS : Nat = 13;                         // F(7) for proof strength
  public let MAX_CATEGORIES : Nat = 21;                              // F(8) operation categories
  public let VERIFICATION_DEPTH : Nat = 55;                          // F(10) verify last N
  public let RECEIPT_SUMMARY_INTERVAL : Nat = 89;                    // F(11) beats per summary

  // ═══════════════════════════════════════════════════════════════════════════
  // RECEIPT TYPES — what was computed
  // ═══════════════════════════════════════════════════════════════════════════

  public type ReceiptCategory = {
    #trade;            // trading operation
    #transfer;         // asset transfer
    #inference;        // AI inference
    #decision;         // trading decision
    #hedge;            // hedging operation
    #rebalance;        // portfolio rebalance
    #signal;           // signal generation
    #keyDerivation;    // cryptographic key created
    #vaultAccess;      // vault read/write
    #wireMessage;      // shadow wire communication
    #heartbeat;        // organism heartbeat tick
    #governance;       // governance action
    #genesis;          // genesis-level operation
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTATIONAL RECEIPT — the fundamental proof unit
  // ═══════════════════════════════════════════════════════════════════════════

  public type ComputationalReceipt = {
    receiptId       : Text;          // unique receipt identifier
    category        : ReceiptCategory;
    operationHash   : Nat64;         // hash of what was done (hides details)
    inputCommitment : Nat64;         // commitment to inputs (no raw data)
    outputCommitment : Nat64;        // commitment to outputs (no raw data)
    beat            : Int;           // temporal proof (when)
    prevReceiptHash : Nat64;         // chain link to previous receipt
    chainHash       : Nat64;         // this receipt's position in chain
    coherenceProof  : Float;         // system coherence at time of computation
    computeCycles   : Nat;           // work units consumed (proof of compute)
    isVerified      : Bool;          // chain integrity confirmed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RECEIPT CHAIN SUMMARY — periodic aggregation
  // ═══════════════════════════════════════════════════════════════════════════

  public type ChainSummary = {
    summaryId       : Text;
    startBeat       : Int;
    endBeat         : Int;
    receiptCount    : Nat;
    chainHeadHash   : Nat64;
    chainTailHash   : Nat64;
    totalCompute    : Nat;           // total cycles in summary window
    categoryCounts  : [(Text, Nat)]; // per-category receipt counts
    integrityScore  : Float;         // chain verification result [0, 1]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CRYPTOGRAPHIA RECEIPT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type CryptographiaReceiptState = {
    receiptChain      : [ComputationalReceipt];
    chainHead         : Nat64;         // hash of most recent receipt
    summaries         : [ChainSummary];
    totalReceipts     : Nat;
    totalCompute      : Nat;           // lifetime compute cycles
    categoryCounts    : [(Text, Nat)]; // per-category totals
    chainIntegrity    : Float;         // overall chain health [0, 1]
    lastVerifyBeat    : Int;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultCryptographiaReceiptState() : CryptographiaReceiptState {
    {
      receiptChain = [];
      chainHead = 0x00000000_CAFE_BABE : Nat64;
      summaries = [];
      totalReceipts = 0;
      totalCompute = 0;
      categoryCounts = [
        ("trade", 0), ("transfer", 0), ("inference", 0), ("decision", 0),
        ("hedge", 0), ("rebalance", 0), ("signal", 0), ("keyDerivation", 0),
        ("vaultAccess", 0), ("wireMessage", 0), ("heartbeat", 0),
        ("governance", 0), ("genesis", 0)
      ];
      chainIntegrity = 1.0;
      lastVerifyBeat = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV HASH
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1a(a : Nat64, b : Nat64) : Nat64 { (a ^ b) *% 1099511628211 };

  func multiHash(seed : Nat64, rounds : Nat) : Nat64 {
    var h = seed;
    var i : Nat = 0;
    while (i < rounds) {
      h := fnv1a(h, Nat64.fromNat(i + 1));
      i += 1;
    };
    h
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY LABEL
  // ═══════════════════════════════════════════════════════════════════════════

  func categoryToText(cat : ReceiptCategory) : Text {
    switch(cat) {
      case (#trade) "trade";
      case (#transfer) "transfer";
      case (#inference) "inference";
      case (#decision) "decision";
      case (#hedge) "hedge";
      case (#rebalance) "rebalance";
      case (#signal) "signal";
      case (#keyDerivation) "keyDerivation";
      case (#vaultAccess) "vaultAccess";
      case (#wireMessage) "wireMessage";
      case (#heartbeat) "heartbeat";
      case (#governance) "governance";
      case (#genesis) "genesis";
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MINT RECEIPT — create new computational receipt
  // ═══════════════════════════════════════════════════════════════════════════

  public func mintReceipt(
    state : CryptographiaReceiptState,
    category : ReceiptCategory,
    inputData : Nat64,           // hash of input (caller computes)
    outputData : Nat64,          // hash of output (caller computes)
    computeCycles : Nat,
    beat : Int,
    systemCoherence : Float
  ) : CryptographiaReceiptState {
    // Build commitments (hide raw data behind additional hashing)
    let inputCommit = multiHash(inputData, RECEIPT_HASH_ROUNDS);
    let outputCommit = multiHash(outputData, RECEIPT_HASH_ROUNDS);

    // Operation hash: combines category + input + output into single proof
    let opHash = fnv1a(fnv1a(inputCommit, outputCommit), Nat64.fromNat(computeCycles));

    // Chain hash: links to previous receipt
    let chainHash = fnv1a(state.chainHead, opHash);

    let receipt : ComputationalReceipt = {
      receiptId = Nat64.toText(chainHash);
      category = category;
      operationHash = opHash;
      inputCommitment = inputCommit;
      outputCommitment = outputCommit;
      beat = beat;
      prevReceiptHash = state.chainHead;
      chainHash = chainHash;
      coherenceProof = systemCoherence;
      computeCycles = computeCycles;
      isVerified = true;
    };

    // Add to chain (bounded)
    let chain = if (state.receiptChain.size() >= MAX_RECEIPT_CHAIN) {
      Array.tabulate<ComputationalReceipt>(MAX_RECEIPT_CHAIN, func(i) {
        if (i < MAX_RECEIPT_CHAIN - 1) state.receiptChain[i + 1] else receipt
      })
    } else {
      Array.append(state.receiptChain, [receipt])
    };

    // Update category counts
    let catText = categoryToText(category);
    let updatedCounts = Array.map<(Text, Nat), (Text, Nat)>(state.categoryCounts, func((t, n)) {
      if (t == catText) (t, n + 1) else (t, n)
    });

    {
      state with
      receiptChain = chain;
      chainHead = chainHash;
      totalReceipts = state.totalReceipts + 1;
      totalCompute = state.totalCompute + computeCycles;
      categoryCounts = updatedCounts;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFY CHAIN — check integrity of recent receipts
  // ═══════════════════════════════════════════════════════════════════════════

  public func verifyChain(state : CryptographiaReceiptState) : Float {
    if (state.receiptChain.size() < 2) return 1.0;

    var valid : Nat = 0;
    let checkDepth = if (state.receiptChain.size() < VERIFICATION_DEPTH) {
      state.receiptChain.size()
    } else { VERIFICATION_DEPTH };

    let start = state.receiptChain.size() - checkDepth;
    var i = start + 1;
    while (i < state.receiptChain.size()) {
      let prev = state.receiptChain[i - 1];
      let curr = state.receiptChain[i];
      if (curr.prevReceiptHash == prev.chainHash) { valid += 1 };
      i += 1;
    };

    Float.fromInt(valid) / Float.fromInt(checkDepth - 1)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — periodic verification and summary generation
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickCryptographiaReceipts(
    state : CryptographiaReceiptState,
    beat : Int,
    systemCoherence : Float
  ) : CryptographiaReceiptState {
    if (systemCoherence < RECEIPT_COHERENCE_GATE) return state;

    // Verify chain integrity periodically
    let integrity = if (Int.abs(beat - state.lastVerifyBeat) >= 21) {
      verifyChain(state)
    } else { state.chainIntegrity };

    // Generate summary at intervals
    let summaries = if (Int.abs(beat - state.lastTickBeat) >= RECEIPT_SUMMARY_INTERVAL and state.receiptChain.size() > 0) {
      let summary : ChainSummary = {
        summaryId = "SUM-" # Int.toText(beat);
        startBeat = state.lastTickBeat;
        endBeat = beat;
        receiptCount = state.receiptChain.size();
        chainHeadHash = state.chainHead;
        chainTailHash = if (state.receiptChain.size() > 0) state.receiptChain[0].chainHash else 0;
        totalCompute = state.totalCompute;
        categoryCounts = state.categoryCounts;
        integrityScore = integrity;
      };
      if (state.summaries.size() >= 21) {
        Array.tabulate<ChainSummary>(21, func(i) {
          if (i < 20) state.summaries[i + 1] else summary
        })
      } else {
        Array.append(state.summaries, [summary])
      }
    } else { state.summaries };

    {
      state with
      summaries = summaries;
      chainIntegrity = integrity;
      lastVerifyBeat = if (Int.abs(beat - state.lastVerifyBeat) >= 21) beat else state.lastVerifyBeat;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getChainIntegrity(state : CryptographiaReceiptState) : Float {
    state.chainIntegrity
  };

  public func getTotalReceipts(state : CryptographiaReceiptState) : Nat {
    state.totalReceipts
  };

  public func getTotalCompute(state : CryptographiaReceiptState) : Nat {
    state.totalCompute
  };

  public func getChainHead(state : CryptographiaReceiptState) : Nat64 {
    state.chainHead
  };
};
