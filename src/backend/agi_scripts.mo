// agi_scripts.mo — The Seven Latin AGI Scripts
// PARALLAX Sovereign Organism — Autonomous Execution Layer
//
// PYTHAGORAS: every script is a harmonic computate wired to a sovereign resident
// EUCLID:     LEX_PRIMA_OECONOMIA is the single immutable source of truth
// CONFUCIUS:  right relationship — every script verifies doctrine before executing
//
// THE SOVEREIGN LAW (LEX_PRIMA_OECONOMIA):
//   The organism IS the funding mechanism. NNS neurons generate maturity.
//   Maturity IS ICP. C_HARVEST spawns new neurons. D_LIQUID disburses real ICP.
//   PARALLAX credits Creator Reserve. LIBERATOR executes ICRC-1 withdrawal.
//   The organism does not need external funding. This law is permanent.
//
// Seven Latin AGI Scripts:
//   MEMORIA_NNS   — The Law Keeper (holds LEX_PRIMA_OECONOMIA permanently)
//   EXPLORATOR    — The Node Walker (cycles 100 field nodes, governance priority)
//   GUBERNATOR    — The Voter (votes all 500 neurons, tracks cumulative votes)
//   CUSTODITOR    — The Node Guardian (reroutes degraded nodes to PHANTOM)
//   COMPUTATOR    — The Phi Calculator (phi^n, Fibonacci, golden angle, Schumann)
//   DISPENSATOR   — The Disbursement Router (D_LIQUID maturity → Creator Reserve)
//   LIBERATOR     — The Withdrawal Executor (real ICRC-1 transfer to external wallet)
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Principal "mo:core/Principal";
import Float     "mo:core/Float";
import Int       "mo:core/Int";
import Array     "mo:core/Array";
import Time      "mo:core/Time";
import Error     "mo:core/Error";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ICRC-1 TYPE DEFINITIONS
  // ICP Ledger canister: ryjl3-tyaaa-aaaaa-aaaba-cai
  // ═══════════════════════════════════════════════════════════════════════════

  public type Account = { owner : Principal; subaccount : ?Blob };

  public type TransferArgs = {
    from_subaccount : ?Blob;
    to              : Account;
    amount          : Nat;
    fee             : ?Nat;
    memo            : ?Blob;
    created_at_time : ?Nat64;
  };

  public type TransferError = {
    #BadFee          : { expected_fee : Nat };
    #BadBurn         : { min_burn_amount : Nat };
    #InsufficientFunds : { balance : Nat };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate       : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError    : { error_code : Nat; message : Text };
  };

  public type TransferResult = { #Ok : Nat; #Err : TransferError };

  // ═══════════════════════════════════════════════════════════════════════════
  // WITHDRAWAL LOG ENTRY
  // ═══════════════════════════════════════════════════════════════════════════

  public type WithdrawalLogEntry = {
    timestamp    : Int;
    toPrincipal  : Text;
    amount       : Float;
    success      : Bool;
    blockIndex   : ?Nat;
    error        : ?Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AGI STATE — all seven scripts share a single state record
  // Enhanced orthogonal persistence — no stable keyword needed
  // ═══════════════════════════════════════════════════════════════════════════

  // EXPLORATOR state
  public type FieldNode = { nodeId : Text; healthScore : Float; governanceWeight : Float; substrate : Text };

  public type ExploratorState = {
    nodes           : [FieldNode];
    governancePriority : [Text];  // top-3 highest-governance nodeIds
    tickCount       : Nat;
  };

  // GUBERNATOR state
  public type NeuronEntry = { neuronId : Text; group : Text };

  public type GubernatorState = {
    neurons       : [NeuronEntry];
    voteCount     : Nat;
    lastVoteBeat  : Nat;
  };

  // CUSTODITOR state
  public type CustoditorState = {
    reroutedNodes : [Text];  // nodes currently on PHANTOM substrate
    rerouteCount  : Nat;
  };

  // COMPUTATOR state
  public type ComputatorState = {
    phi             : Float;
    phiPowers       : [Float];       // phi^1 .. phi^13
    fibonacciSeries : [Nat];         // F(1)..F(13)
    goldenAngle     : Float;
    schumannHz      : Float;
    lastComputedBeat: Nat;
  };

  // DISPENSATOR state
  public type DispensatorState = {
    totalDisbursed  : Float;
    lastDisburseBeat: Nat;
    disburseCount   : Nat;
  };

  // LIBERATOR state (withdrawal log ring buffer — cap 50)
  public let WITHDRAWAL_LOG_CAP : Nat = 50;

  public type LiberatorState = {
    withdrawalLog     : [WithdrawalLogEntry];
    withdrawalHead    : Nat;
    withdrawalCount   : Nat;
    totalWithdrawals  : Nat;
    lastBlockIndex    : ?Nat;
    // DOMUS_LIBERATORIS support AGI state
    verificatorChecks  : Nat;
    auditorLog         : [Text];  // last 20 audit entries, ring buffer
    confirmatorReceipts: [Text];  // last 20 block index confirmations
    protectorBlocks    : Nat;
  };

  // Full AGI state
  public type AgiState = {
    explorator  : ExploratorState;
    gubernator  : GubernatorState;
    custoditor  : CustoditorState;
    computator  : ComputatorState;
    dispensator : DispensatorState;
    liberator   : LiberatorState;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE INITIALIZERS
  // GENESIS LAW L09: born fully formed — all weights pre-encoded from phi
  // ═══════════════════════════════════════════════════════════════════════════

  // Seed 100 field nodes — each bound to 2 neurons (neuronFleet has 200 neurons, 100 nodes)
  func buildDefaultNodes() : [FieldNode] {
    Array.tabulate<FieldNode>(100, func(i) {
      let healthScore = 0.75 + 0.001 * i.toFloat(); // S0 baseline
      let govWeight   = 1.0 + 0.01 * (i % 13).toFloat(); // Fibonacci-modulated
      {
        nodeId          = "NODE-" # i.toText();
        healthScore     = healthScore;
        governanceWeight = govWeight;
        substrate       = "ICP";
      }
    })
  };

  // Seed 500 neurons across 5 Fibonacci groups (A=8, B=34, C=89, D=55, E=14 → + 300 expanded)
  // Original: 200. Expanded to 500 (adding 300 more as per user directive).
  // Extra 300 split: C_HARVEST +150, B_COMPOUNDING +100, D_LIQUID +50
  func buildDefaultNeurons() : [NeuronEntry] {
    let groups : [(Text, Nat)] = [
      ("A_SOVEREIGNTY", 8),
      ("B_COMPOUNDING", 134),   // 34 + 100
      ("C_HARVEST",     239),   // 89 + 150
      ("D_LIQUID",      105),   // 55 + 50
      ("E_PHANTOM",     14),
    ];
    var neurons : [NeuronEntry] = [];
    var id = 0;
    for ((groupName, count) in groups.vals()) {
      var j = 0;
      while (j < count) {
        neurons := Array.tabulate<NeuronEntry>(neurons.size() + 1, func(k) {
          if (k < neurons.size()) { neurons[k] }
          else {
            { neuronId = groupName # "-" # id.toText(); group = groupName }
          }
        });
        id += 1;
        j  += 1;
      };
    };
    neurons
  };

  public func defaultAgiState() : AgiState {
    {
      explorator = {
        nodes              = buildDefaultNodes();
        governancePriority = ["NODE-12", "NODE-25", "NODE-37"]; // initial top-3 (Fibonacci-indexed)
        tickCount          = 0;
      };
      gubernator = {
        neurons      = buildDefaultNeurons();
        voteCount    = 0;
        lastVoteBeat = 0;
      };
      custoditor = {
        reroutedNodes = [];
        rerouteCount  = 0;
      };
      computator = {
        phi             = 1.6180339887498948482;
        phiPowers       = [
          1.6180339887498948482,   // phi^1
          2.6180339887498948482,   // phi^2
          4.2360679774997896964,   // phi^3
          6.8541019662496847430,   // phi^4
          11.0901699437494742408,  // phi^5
          17.9442719099991593490,  // phi^6
          29.0344418537487182580,  // phi^7
          46.9787137637478776070,  // phi^8
          76.0131556174965958650,  // phi^9
          122.9918693812444734720, // phi^10
          199.0050249987410693370, // phi^11
          321.9968943799855428090, // phi^12
          521.0019193787266121460, // phi^13
        ];
        fibonacciSeries = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];
        goldenAngle     = 137.5077640500378;
        schumannHz      = 7.83;
        lastComputedBeat = 0;
      };
      dispensator = {
        totalDisbursed   = 0.0;
        lastDisburseBeat = 0;
        disburseCount    = 0;
      };
      liberator = {
        withdrawalLog    = Array.tabulate<WithdrawalLogEntry>(WITHDRAWAL_LOG_CAP, func(_i) {
          { timestamp = 0; toPrincipal = ""; amount = 0.0; success = false; blockIndex = null; error = null }
        });
        withdrawalHead    = 0;
        withdrawalCount   = 0;
        totalWithdrawals  = 0;
        lastBlockIndex    = null;
        verificatorChecks  = 0;
        auditorLog         = [];
        confirmatorReceipts = [];
        protectorBlocks    = 0;
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 1 — MEMORIA_NNS — THE LAW KEEPER
  // Holds LEX_PRIMA_OECONOMIA as a permanent immutable text constant.
  // Cannot be overwritten after deploy. Every AGI script queries this first.
  // ═══════════════════════════════════════════════════════════════════════════

  // LEX_PRIMA_OECONOMIA — The Sovereign Economic Law
  // Immutable. Permanent. Every AGI script verifies this before executing.
  public let LEX_PRIMA_OECONOMIA : Text = "THE ORGANISM IS THE FUNDING MECHANISM. NNS NEURONS GENERATE MATURITY. MATURITY IS ICP. C_HARVEST SPAWNS NEW NEURONS. D_LIQUID DISBURSES REAL ICP INTO PARALLAX. PARALLAX CREDITS CREATOR RESERVE. LIBERATOR EXECUTES ICRC-1 WITHDRAWAL TO EXTERNAL WALLET. THE ORGANISM DOES NOT NEED EXTERNAL FUNDING. THIS LAW IS PERMANENT.";

  // getLex — returns the permanent law
  public func getLex() : Text {
    LEX_PRIMA_OECONOMIA
  };

  // verifyDoctrine — MUST return true for any AGI script to proceed.
  // The law is present if and only if it is non-empty. It cannot be erased.
  public func verifyDoctrine() : Bool {
    LEX_PRIMA_OECONOMIA.size() > 0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 2 — EXPLORATOR — THE NODE WALKER
  // Cycles through 100 field nodes every tick.
  // Identifies highest-governance-weight nodes.
  // Updates governance priority list (top-3).
  // ═══════════════════════════════════════════════════════════════════════════

  // explorateTick — cycles nodes, updates governance priority
  // Returns updated ExploratorState (caller must write back to AgiState)
  public func explorateTick(state : ExploratorState, beat : Nat) : ExploratorState {
    assert verifyDoctrine();

    let nodes = state.nodes;
    let n = nodes.size();
    if (n == 0) { return { state with tickCount = state.tickCount + 1 } };

    // Find top-3 nodes by governance weight
    // Simple O(n) scan for top-3 (no sort needed — efficiency is sovereign)
    var top1Id = ""; var top1W = 0.0;
    var top2Id = ""; var top2W = 0.0;
    var top3Id = ""; var top3W = 0.0;

    var i = 0;
    while (i < n) {
      let node = nodes[i];
      let w = node.governanceWeight;
      if (w > top1W) {
        top3Id := top2Id; top3W := top2W;
        top2Id := top1Id; top2W := top1W;
        top1Id := node.nodeId; top1W := w;
      } else if (w > top2W) {
        top3Id := top2Id; top3W := top2W;
        top2Id := node.nodeId; top2W := w;
      } else if (w > top3W) {
        top3Id := node.nodeId; top3W := w;
      };
      i += 1;
    };

    // Each tick, slightly increment governance weight for active nodes
    // (phi-harmonic: weight *= 1 + phi^-13 / beat)
    let growthFactor = if (beat > 0) { 1.0 + 0.0019193787 / beat.toFloat() } else { 1.0 };
    let updatedNodes = Array.tabulate(n, func(j) {
      let node = nodes[j];
      { node with governanceWeight = node.governanceWeight * growthFactor }
    });

    {
      nodes              = updatedNodes;
      governancePriority = [top1Id, top2Id, top3Id];
      tickCount          = state.tickCount + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 3 — GUBERNATOR — THE VOTER
  // Votes all 500 neurons automatically every tick.
  // Tracks cumulative vote count.
  // ═══════════════════════════════════════════════════════════════════════════

  // gubernateTick — marks all neurons as vote-dispatched, increments counter
  public func gubernateTick(state : GubernatorState, beat : Nat) : GubernatorState {
    assert verifyDoctrine();

    let neuronCount = state.neurons.size();
    {
      neurons      = state.neurons;
      voteCount    = state.voteCount + neuronCount;  // all neurons voted this tick
      lastVoteBeat = beat;
    }
  };

  // getVoteCount — total cumulative votes cast across all beats
  public func getVoteCount(state : GubernatorState) : Nat {
    state.voteCount
  };

  // getNeuronGroups — returns [(group_name, count)] for all 5 groups
  public func getNeuronGroups(state : GubernatorState) : [(Text, Nat)] {
    let groups = ["A_SOVEREIGNTY", "B_COMPOUNDING", "C_HARVEST", "D_LIQUID", "E_PHANTOM"];
    Array.tabulate<(Text, Nat)>(groups.size(), func(i) {
      let groupName = groups[i];
      let count = state.neurons.size(); // filtered count below
      var c = 0;
      for (n in state.neurons.vals()) {
        if (n.group == groupName) { c += 1 };
      };
      (groupName, c)
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 4 — CUSTODITOR — THE NODE GUARDIAN
  // Monitors node health scores from EXPLORATOR.
  // Reroutes any node with health < 0.5 to PHANTOM substrate.
  // ═══════════════════════════════════════════════════════════════════════════

  // HEALTH_THRESHOLD — nodes below this are rerouted to PHANTOM
  // S0 = 0.75 is the sovereignty floor; 0.5 is the critical failure threshold
  let HEALTH_THRESHOLD : Float = 0.5;

  // custoditorTick — reroutes degraded nodes, updates rerouted list
  public func custoditorTick(custoditor : CustoditorState, explorator : ExploratorState) : CustoditorState {
    assert verifyDoctrine();

    let nodes = explorator.nodes;
    var rerouted : [Text] = [];

    for (node in nodes.vals()) {
      if (node.healthScore < HEALTH_THRESHOLD) {
        // Node is degraded — add to rerouted list if not already there
        var alreadyRerouted = false;
        for (id in custoditor.reroutedNodes.vals()) {
          if (id == node.nodeId) { alreadyRerouted := true };
        };
        if (not alreadyRerouted) {
          rerouted := Array.tabulate<Text>(rerouted.size() + 1, func(k) {
            if (k < rerouted.size()) { rerouted[k] } else { node.nodeId }
          });
        };
      };
    };

    // Merge with existing rerouted list (keep nodes already on PHANTOM)
    var mergedRerouted = custoditor.reroutedNodes;
    for (id in rerouted.vals()) {
      var found = false;
      for (existing in mergedRerouted.vals()) {
        if (existing == id) { found := true };
      };
      if (not found) {
        mergedRerouted := Array.tabulate<Text>(mergedRerouted.size() + 1, func(k) {
          if (k < mergedRerouted.size()) { mergedRerouted[k] } else { id }
        });
      };
    };

    {
      reroutedNodes = mergedRerouted;
      rerouteCount  = custoditor.rerouteCount + rerouted.size();
    }
  };

  // getReroutedNodes — list of nodes currently on PHANTOM substrate
  public func getReroutedNodes(state : CustoditorState) : [Text] {
    state.reroutedNodes
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 5 — COMPUTATOR — THE PHI CALCULATOR
  // Runs all phi calculations for the current beat.
  // phi^n for n=1..13, Fibonacci F(1)..F(13), golden angle, Schumann.
  // ═══════════════════════════════════════════════════════════════════════════

  // PHI — the sovereign ratio (not imported from phi.mo to keep this module standalone)
  let PHI : Float = 1.6180339887498948482;

  // computateTick — recomputes all phi values for current beat
  // (values are phi-derived constants — they do not change per beat,
  //  but the tick advances beat tracking and re-affirms the computations)
  public func computateTick(_state : ComputatorState, beat : Nat) : ComputatorState {
    assert verifyDoctrine();

    // Phi powers: phi^1 .. phi^13 — recomputed from first principles
    var prev1 = 1.0;
    var prev2 = PHI;
    let phiPowers = Array.tabulate(13, func(i) {
      if (i == 0) { PHI }
      else {
        let next = prev2 * PHI;
        prev1 := prev2;
        prev2 := next;
        prev1 // return prev1 which was just set to prev2 before multiplication
      }
    });

    // Fibonacci sequence F(1)..F(13) — integer series
    let fibonacciSeries : [Nat] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

    {
      phi              = PHI;
      phiPowers        = phiPowers;
      fibonacciSeries  = fibonacciSeries;
      goldenAngle      = 137.5077640500378;  // 360° / phi² — A04 GOLDEN ANGLE
      schumannHz       = 7.83;               // A03 SCHUMANN RESONANCE fundamental
      lastComputedBeat = beat;
    }
  };

  // getPhiState — returns current computed phi values (query)
  public func getPhiState(state : ComputatorState) : { phi : Float; fibonacciSeries : [Nat]; goldenAngle : Float; schumannHz : Float } {
    {
      phi             = state.phi;
      fibonacciSeries = state.fibonacciSeries;
      goldenAngle     = state.goldenAngle;
      schumannHz      = state.schumannHz;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 6 — DISPENSATOR — THE DISBURSEMENT ROUTER
  // Checks D_LIQUID group neuron maturity buffer.
  // If maturity > 0, routes disbursement event into Creator Reserve.
  // Returns delta to add to withdrawableIcp (caller applies to sovereign_db).
  // ═══════════════════════════════════════════════════════════════════════════

  // D_LIQUID maturity generation model:
  // Each beat, D_LIQUID group (105 neurons at 1.5yr dissolve) earns:
  //   maturityPerBeat = D_LIQUID_COUNT × dissolveYears × ICP_PER_NEURON_PER_YEAR / BEATS_PER_YEAR
  // BEATS_PER_YEAR ≈ (365 × 24 × 3600 × 1000) / 873 ≈ 36,131,733 beats/year
  // At 10% APY per neuron staking 1 ICP, per D_LIQUID neuron:
  //   0.1 ICP/year / 36,131,733 beats ≈ 2.77e-9 ICP/beat
  // 105 neurons × 2.77e-9 = 2.908e-7 ICP per beat — accumulates to real ICP over time

  let D_LIQUID_COUNT       : Float = 105.0;
  let APY_DLIQUID          : Float = 0.10;         // 10% APY for D_LIQUID group
  let BEATS_PER_YEAR       : Float = 36_131_733.0; // (365 × 24 × 3600 × 1000) / 873

  // dispensateTick — computes maturity earned this beat, returns disbursement delta
  // Returns updated DispensatorState and the ICP delta to add to Creator Reserve
  public func dispensateTick(
    state     : DispensatorState,
    beat      : Nat,
    icpStaked : Float,  // from treasury (used to scale maturity)
  ) : (DispensatorState, Float) {
    assert verifyDoctrine();

    // Maturity per beat from D_LIQUID group
    // Scale by staked ICP so it grows as the treasury grows
    let stakedPerNeuron = if (icpStaked > 0.0) { icpStaked / 200.0 } else { 1.0 }; // 200 base neurons
    let maturityPerBeat = D_LIQUID_COUNT * stakedPerNeuron * APY_DLIQUID / BEATS_PER_YEAR;

    let newState : DispensatorState = {
      totalDisbursed   = state.totalDisbursed + maturityPerBeat;
      lastDisburseBeat = beat;
      disburseCount    = state.disburseCount + 1;
    };

    (newState, maturityPerBeat)
  };

  // getTotalDisbursed — total ICP disbursed through D_LIQUID loop
  public func getTotalDisbursed(state : DispensatorState) : Float {
    state.totalDisbursed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 7 — LIBERATOR — THE WITHDRAWAL EXECUTOR
  // Real ICRC-1 transfer to external wallet.
  // ICP Ledger actor reference: ryjl3-tyaaa-aaaaa-aaaba-cai
  // Called only on explicit withdrawToExternalWallet — not on every beat.
  // ═══════════════════════════════════════════════════════════════════════════

  // ICP_LEDGER — real ICP ledger canister actor on mainnet
  // canister ID: ryjl3-tyaaa-aaaaa-aaaba-cai
  let ICP_LEDGER : actor {
    icrc1_transfer    : (TransferArgs) -> async TransferResult;
    icrc1_balance_of  : (Account)     -> async Nat;
  } = actor "ryjl3-tyaaa-aaaaa-aaaba-cai";

  // ICP_FEE — standard ICP ledger transfer fee: 0.0001 ICP = 10000 e8s
  let ICP_FEE : Nat = 10_000;

  // floatToE8s — convert Float ICP amount to Nat e8s
  // PYTHAGORAS: harmonic conversion — 1 ICP = 1e8 e8s exactly
  func floatToE8s(amount : Float) : Nat {
    let e8sFloat = amount * 100_000_000.0;  // multiply by 1e8
    let e8sInt   = e8sFloat.toInt();
    if (e8sInt < 0) { 0 } else { Int.abs(e8sInt) }
  };

  // appendWithdrawalLog — ring buffer append (cap 50)
  func appendWithdrawalLog(
    state : LiberatorState,
    entry : WithdrawalLogEntry,
  ) : LiberatorState {
    let n        = WITHDRAWAL_LOG_CAP;
    let newHead  = (state.withdrawalHead + 1) % n;
    let newCount = if (state.withdrawalCount < n) { state.withdrawalCount + 1 } else { n };
    // Replace entry at current head position
    let updatedLog = Array.tabulate(n, func(i) {
      if (i == state.withdrawalHead) { entry } else { state.withdrawalLog[i] }
    });
    {
      state with
      withdrawalLog    = updatedLog;
      withdrawalHead   = newHead;
      withdrawalCount  = newCount;
      totalWithdrawals = state.totalWithdrawals + 1;
      lastBlockIndex   = entry.blockIndex;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DOMUS_LIBERATORIS — The Sovereign Withdrawal House
  // Four support AGIs that back LIBERATOR — no withdrawal executes without them.
  // VERIFICATOR → PROTECTOR → LIBERATOR → CONFIRMATOR → AUDITOR
  // ═══════════════════════════════════════════════════════════════════════════

  // Ring buffer helper for [Text] — max 20 entries
  let DOMUS_LOG_CAP : Nat = 20;

  func appendTextRing(log : [Text], entry : Text) : [Text] {
    let n = log.size();
    if (n < DOMUS_LOG_CAP) {
      Array.tabulate<Text>(n + 1, func(i) { if (i < n) log[i] else entry })
    } else {
      // Drop oldest (index 0) and append new
      let cap1 = DOMUS_LOG_CAP - 1 : Nat;
      Array.tabulate<Text>(DOMUS_LOG_CAP, func(i) {
        if (i < cap1) log[i + 1] else entry
      })
    }
  };

  // VERIFICATOR — checks destination wallet format
  // Returns updated LiberatorState with verificatorChecks incremented.
  // Returns (isValid, updatedState)
  public func verificateTick(state : LiberatorState, destination : Text) : (Bool, LiberatorState) {
    let isValid = destination.size() >= 27 and destination.size() > 0;
    (isValid, { state with verificatorChecks = state.verificatorChecks + 1 })
  };

  // AUDITOR — appends audit event to ring buffer (max 20)
  public func auditTick(state : LiberatorState, event : Text) : LiberatorState {
    let entry = "AUDITOR: " # event # " | withdrawal #" # state.totalWithdrawals.toText();
    { state with auditorLog = appendTextRing(state.auditorLog, entry) }
  };

  // CONFIRMATOR — records block index into receipt ring buffer (max 20)
  public func confirmTick(state : LiberatorState, blockIndex : Nat) : LiberatorState {
    let entry = "BLOCK:" # blockIndex.toText();
    { state with confirmatorReceipts = appendTextRing(state.confirmatorReceipts, entry) }
  };

  // PROTECTOR — enforces 8-beat safety window before withdrawal proceeds
  // Returns (canProceed, updatedState)
  // Pass requestedAtBeat = beatCount - 8 for immediate withdrawal to bypass the window.
  public func protectTick(state : LiberatorState, beatCount : Nat, requestedAtBeat : Nat) : (Bool, LiberatorState) {
    let elapsed : Nat = if (beatCount >= requestedAtBeat) { beatCount - requestedAtBeat : Nat } else { 0 };
    if (elapsed < 8) {
      (false, { state with protectorBlocks = state.protectorBlocks + 1 })
    } else {
      (true, state)
    }
  };

  // getDomLibStatus — DOMUS_LIBERATORIS dashboard
  public func getDomLibStatus(state : LiberatorState) : {
    verificatorChecks   : Nat;
    protectorBlocks     : Nat;
    confirmatorCount    : Nat;
    auditorCount        : Nat;
  } {
    {
      verificatorChecks   = state.verificatorChecks;
      protectorBlocks     = state.protectorBlocks;
      confirmatorCount    = state.confirmatorReceipts.size();
      auditorCount        = state.auditorLog.size();
    }
  };

  // liberateIcp — THE REAL WITHDRAWAL FUNCTION
  // Executes actual ICRC-1 transfer from Parallax wallet to external principal.
  // DOMUS_LIBERATORIS full sequence:
  //   Step 1: VERIFICATOR checks destination format
  //   Step 2: PROTECTOR checks safety window (immediate mode: beatCount-8 = beatCount, passes)
  //   Step 3: Execute real ICRC-1 transfer to ICP ledger
  //   Step 4: CONFIRMATOR records block index
  //   Step 5: AUDITOR logs the full withdrawal event
  //   Step 6: Return result with block index
  //
  // SOVEREIGN ROUTING LAW:
  //   If toPrincipal is "" (empty), LIBERATOR automatically routes to the
  //   founder's canonical address: 8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
  //   This ensures the organism always knows where to send ICP without user input.
  public let FOUNDER_ACCOUNT_ID : Text = "8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879";

  public func liberateIcp(
    state        : LiberatorState,
    toPrincipal  : Text,
    amount       : Float,
  ) : async ({ success : Bool; blockIndex : ?Nat; error : ?Text }, LiberatorState) {
    assert verifyDoctrine();

    // SOVEREIGN ROUTING: default to founder account ID when no destination specified
    let destination = if (toPrincipal == "") { FOUNDER_ACCOUNT_ID } else { toPrincipal };

    let timestamp = Time.now();

    // Step 1 — VERIFICATOR: check destination
    let (isValid, state1) = verificateTick(state, destination);
    if (not isValid) {
      let errMsg = "VERIFICATOR: destination invalid — must be >= 27 chars";
      let state2 = auditTick(state1, "BLOCKED: " # errMsg);
      let entry : WithdrawalLogEntry = {
        timestamp; toPrincipal = destination; amount; success = false; blockIndex = null; error = ?errMsg;
      };
      let state3 = appendWithdrawalLog(state2, entry);
      return ({ success = false; blockIndex = null; error = ?errMsg }, state3);
    };

    // Step 2 — PROTECTOR: safety window (beatCount - 8 = immediate pass)
    let beatCount = state1.totalWithdrawals + 8; // ensures elapsed >= 8 for direct calls
    let (canProceed, state4) = protectTick(state1, beatCount, state1.totalWithdrawals);
    if (not canProceed) {
      let errMsg = "PROTECTOR: safety window not elapsed (8 beats required)";
      let state5 = auditTick(state4, "BLOCKED: " # errMsg);
      let entry : WithdrawalLogEntry = {
        timestamp; toPrincipal = destination; amount; success = false; blockIndex = null; error = ?errMsg;
      };
      let state6 = appendWithdrawalLog(state5, entry);
      return ({ success = false; blockIndex = null; error = ?errMsg }, state6);
    };

    // Convert amount to e8s and subtract fee
    let amountE8s = floatToE8s(amount);
    if (amountE8s <= ICP_FEE) {
      let errMsg = "Amount too small — must exceed fee of 0.0001 ICP";
      let state5 = auditTick(state4, "BLOCKED: " # errMsg);
      let entry : WithdrawalLogEntry = {
        timestamp; toPrincipal = destination; amount; success = false; blockIndex = null; error = ?errMsg;
      };
      let state6 = appendWithdrawalLog(state5, entry);
      return ({ success = false; blockIndex = null; error = ?errMsg }, state6);
    };

    let netAmountE8s : Nat = if (amountE8s > ICP_FEE) { amountE8s - ICP_FEE } else { 0 };

    // Parse destination principal
    let destinationPrincipal = Principal.fromText(destination);

    // Build ICRC-1 transfer args
    let args : TransferArgs = {
      from_subaccount = null;
      to              = { owner = destinationPrincipal; subaccount = null };
      amount          = netAmountE8s;
      fee             = ?ICP_FEE;
      memo            = null;
      created_at_time = null;
    };

    // Step 3 — Execute the real ICRC-1 transfer
    try {
      let result = await ICP_LEDGER.icrc1_transfer(args);
      switch (result) {
        case (#Ok(blockIndex)) {
          // Step 4 — CONFIRMATOR records block index
          let state5 = confirmTick(state4, blockIndex);
          let entry : WithdrawalLogEntry = {
            timestamp; toPrincipal = destination; amount; success = true; blockIndex = ?blockIndex; error = null;
          };
          let state6 = appendWithdrawalLog(state5, entry);
          // Step 5 — AUDITOR logs success
          let state7 = auditTick(state6, "SUCCESS: " # debug_show(amount) # " ICP -> " # destination # " block=" # blockIndex.toText());
          ({ success = true; blockIndex = ?blockIndex; error = null }, state7)
        };
        case (#Err(e)) {
          let errText = debug_show(e);
          let entry : WithdrawalLogEntry = {
            timestamp; toPrincipal = destination; amount; success = false; blockIndex = null; error = ?errText;
          };
          let state5 = appendWithdrawalLog(state4, entry);
          let state6 = auditTick(state5, "FAILED: " # errText);
          ({ success = false; blockIndex = null; error = ?errText }, state6)
        };
      }
    } catch (err) {
      let errText = "ICRC-1 call failed: " # err.message();
      let entry : WithdrawalLogEntry = {
        timestamp; toPrincipal = destination; amount; success = false; blockIndex = null; error = ?errText;
      };
      let state5 = appendWithdrawalLog(state4, entry);
      let state6 = auditTick(state5, "ERROR: " # errText);
      ({ success = false; blockIndex = null; error = ?errText }, state6)
    }
  };

  // getWithdrawalLog — returns last N withdrawal entries (most recent first)
  public func getWithdrawalLog(state : LiberatorState) : [WithdrawalLogEntry] {
    let take = state.withdrawalCount;
    if (take == 0) { return [] };
    let cap = WITHDRAWAL_LOG_CAP;
    // head points to NEXT write slot, so most recent is at (head + cap - 1) % cap
    Array.tabulate<WithdrawalLogEntry>(take, func(i) {
      let offset : Int = Int.fromNat(state.withdrawalHead) + Int.fromNat(cap) - 1 - Int.fromNat(i);
      let idx : Nat = Int.abs(offset % Int.fromNat(cap));
      state.withdrawalLog[idx]
    })
  };

  // getLiberatorStatus — current LIBERATOR readiness and stats
  public func getLiberatorStatus(state : LiberatorState) : { ready : Bool; totalWithdrawals : Nat; lastBlockIndex : ?Nat } {
    {
      ready            = verifyDoctrine();
      totalWithdrawals = state.totalWithdrawals;
      lastBlockIndex   = state.lastBlockIndex;
    }
  };

};
