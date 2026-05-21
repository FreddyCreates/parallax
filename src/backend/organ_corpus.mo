// organ_corpus.mo — CORPUS Sovereign Organ Canister (Body / Execution)
// SOVEREIGN CANISTER — deployed independently, beats at 873ms, never depends on main.mo
//
// MEDINA-ARTIFACT — CORPUS — TIER 3 — COMPUTATE
// ──────────────────────────────────────────────
// MEANING (Layer 1):
//   "I am the body of the organism. I execute tasks, maintain energy, and process
//    one task from the queue every 873ms. The body runs before cognition.
//    My energy level is phi-derived: φ⁻¹ × (executions / (executions + errors))."
//
// MODEL (Layer 2):
//   CorpusState: genesisHash, beatCount, executionCount, lastExecution,
//                taskQueue ([Text]), energyLevel (Float)
//
// COMPUTATION (Layer 3):
//   energyLevel = PHI_INV × (executionCount / (executionCount + errorCount))
//   healthScore = (1.0 − errorRate) × PHI_INV
//   genesisHash = FNV-1a(beatCount_at_init || "CORPUS")
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: CORPUS — 873ms recurringTimer
//   GATE:   energyLevel >= PHI_INV before task accepted
//   BEAT:   every 873ms — process one task, update energyLevel, health report
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Timer  "mo:core/Timer";
import Time   "mo:core/Time";
import Float  "mo:core/Float";
import Array  "mo:core/Array";
import Nat    "mo:core/Nat";
import Phi    "phi";

actor CORPUS {

  // ══════════════════════════════════════════════════════════════════════
  // HEALTH REPORT TYPE
  // ══════════════════════════════════════════════════════════════════════

  public type HealthReport = {
    organType  : Text;
    healthScore: Float;
    cycles     : Nat;
    messages   : Nat;
    errors     : Nat;
    latencyMs  : Int;
    timestamp  : Int;
  };

  // ══════════════════════════════════════════════════════════════════════
  // CORPUS STATE
  // ══════════════════════════════════════════════════════════════════════

  public type CorpusState = {
    genesisHash    : Text;
    beatCount      : Nat;
    executionCount : Nat;
    lastExecution  : Text;
    taskQueue      : [Text];
    energyLevel    : Float;
  };

  // Task result store: simple array of (taskId, result) pairs
  // Ring buffer capped at 100 results
  public type TaskResult = { taskId : Text; result : Text; completedAt : Nat };

  var genesisHash    : Text    = "";
  var beatCount      : Nat     = 0;
  var executionCount : Nat     = 0;
  var lastExecution  : Text    = "CORPUS_INITIALIZED";
  var taskQueue      : [Text]  = [];
  var energyLevel    : Float   = Phi.PHI_INV;
  var taskResults    : [TaskResult] = [];
  var errorCount     : Nat     = 0;
  var lastBeatNs     : Int     = 0;
  var lastLatencyMs  : Int     = 0;

  // ══════════════════════════════════════════════════════════════════════
  // FNV-1a GENESIS HASH
  // ══════════════════════════════════════════════════════════════════════

  func computeGenesisHash(beat : Nat) : Text {
    let offset : Nat = 2166136261;
    let prime  : Nat = 16777619;
    let seed   = ((offset ^ beat) * prime) ^ 6; // "CORPUS".size() = 6
    let hash   = (seed * prime) % 4294967296;
    "CORPUS-GENESIS-" # hash.toText()
  };

  // ══════════════════════════════════════════════════════════════════════
  // ENERGY COMPUTATION
  // energyLevel = PHI_INV × success_rate
  // ══════════════════════════════════════════════════════════════════════

  func computeEnergy() : Float {
    let total = executionCount + errorCount;
    if (total == 0) { return Phi.PHI_INV };
    Phi.PHI_INV * executionCount.toFloat() / total.toFloat()
  };

  // ══════════════════════════════════════════════════════════════════════
  // PROCESS ONE TASK — called each heartbeat
  // CONFUCIUS: right action — one task at a time, complete before next
  // ══════════════════════════════════════════════════════════════════════

  func processNextTask() {
    if (taskQueue.size() == 0) { return };

    let task = taskQueue[0];
    // Dequeue: shift queue left
    taskQueue := Array.tabulate<Text>(taskQueue.size() - 1, func(i) { taskQueue[i + 1] });

    let taskId = "TASK-" # beatCount.toText() # "-" # executionCount.toText();
    let result = "EXECUTED[" # taskId # "]:" # task;

    // Store result (ring buffer max 100)
    let entry : TaskResult = { taskId; result; completedAt = beatCount };
    if (taskResults.size() >= 100) {
      taskResults := Array.tabulate<TaskResult>(100, func(i) {
        if (i < 99) taskResults[i + 1] else entry
      });
    } else {
      taskResults := taskResults.concat([entry]);
    };

    executionCount += 1;
    lastExecution  := result;
    energyLevel    := computeEnergy();
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms sovereign cardiac cycle
  // ══════════════════════════════════════════════════════════════════════

  let _heartbeatTimer = Timer.recurringTimer<system>(
    #nanoseconds(873_000_000),
    func() : async () {
      let nowNs = Time.now();
      lastLatencyMs := if (lastBeatNs > 0) { (nowNs - lastBeatNs) / 1_000_000 } else { 873 };
      lastBeatNs := nowNs;

      if (genesisHash == "") {
        genesisHash := computeGenesisHash(beatCount);
      };

      beatCount += 1;
      processNextTask();

      // AEGIS: if energy degraded, apply correction
      if (energyLevel < Phi.PHI_INV) {
        energyLevel := Phi.PHI_INV;
      };
    }
  );

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC QUERIES
  // ══════════════════════════════════════════════════════════════════════

  public query func reportHealth() : async HealthReport {
    let total     = executionCount + errorCount;
    let errorRate = if (total > 0) { errorCount.toFloat() / total.toFloat() } else { 0.0 };
    let score     = (1.0 - errorRate) * Phi.PHI_INV;
    {
      organType   = "CORPUS";
      healthScore = score;
      cycles      = beatCount;
      messages    = executionCount;
      errors      = errorCount;
      latencyMs   = lastLatencyMs;
      timestamp   = Time.now();
    }
  };

  public query func getCorpusState() : async CorpusState {
    {
      genesisHash;
      beatCount;
      executionCount;
      lastExecution;
      taskQueue;
      energyLevel;
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC UPDATES
  // ══════════════════════════════════════════════════════════════════════

  /// execute — adds task to queue, returns taskId
  /// MAXIMUM QUANTUM LAW L45: full task is queued, never partial
  public func execute(task : Text) : async Text {
    if (task.size() == 0) {
      errorCount += 1;
      return "EMPTY_TASK"
    };
    // Energy gate: CORPUS needs sufficient energy to accept work
    if (energyLevel < Phi.PHI_INV * 0.5) {
      return "ENERGY_GATE_CLOSED[" # debug_show(energyLevel) # "]"
    };

    let taskId = "TASK-" # beatCount.toText() # "-" # taskQueue.size().toText();
    taskQueue := taskQueue.concat([task]);
    taskId
  };

  /// getTaskResult — returns result for a given taskId if available
  public query func getTaskResult(taskId : Text) : async ?Text {
    let found = taskResults.find(func(r : TaskResult) : Bool { r.taskId == taskId });
    switch (found) {
      case (?r) { ?r.result };
      case null { null };
    }
  };

};
