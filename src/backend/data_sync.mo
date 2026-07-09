// data_sync.mo — PARALLAX DATA SYNCHRONIZATION FABRIC
// Python market-data pipelines stream into Motoko through phi-governed checkpoints,
// manifests, and coherence-aware bridge acknowledgements.

import Phi "phi";
import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Text "mo:core/Text";
import PythonBridge "python_bridge";

module {

  public let DATA_SYNC_GATE : Float = Phi.PHI_INV;
  public let MAX_SYNC_WORKERS : Nat = 13;
  public let MAX_PENDING_DATASETS : Nat = 34;
  public let MAX_CONFLICTS_TRACKED : Nat = 55;
  public let HEARTBEAT_GRACE_BEATS : Int = 5;

  public type SyncMode = {
    #realtime;
    #historical;
    #snapshot;
    #recovery;
  };

  public type ConflictSeverity = {
    #low;
    #medium;
    #high;
    #critical;
  };

  public type DatasetManifest = {
    dataset : Text;
    schemaVersion : Text;
    partition : Text;
    recordCount : Nat;
    firstTimestampNs : Nat64;
    lastTimestampNs : Nat64;
    contentHash : Text;
    lineageHash : Text;
  };

  public type SyncCheckpoint = {
    checkpointId : Text;
    dataset : Text;
    beat : Int;
    sequence : Nat;
    watermarkNs : Nat64;
    manifestHash : Text;
    compressedBytes : Nat64;
  };

  public type DataConflict = {
    dataset : Text;
    expectedHash : Text;
    observedHash : Text;
    severity : ConflictSeverity;
    beat : Int;
    detail : Text;
  };

  public type SyncWorker = {
    workerId : Text;
    endpoint : Text;
    datasets : [Text];
    coherence : Float;
    lastBeat : Int;
    lagBeats : Nat;
    alive : Bool;
  };

  public type DataSyncState = {
    bridge : PythonBridge.PythonBridgeState;
    workers : [SyncWorker];
    manifests : [DatasetManifest];
    checkpoints : [SyncCheckpoint];
    conflicts : [DataConflict];
    pendingDatasets : [Text];
    syncMode : SyncMode;
    syncHealth : Float;
    lastBeat : Int;
  };

  func containsText(items : [Text], value : Text) : Bool {
    for (item in items.vals()) {
      if (item == value) { return true };
    };
    false
  };

  func withoutDataset(items : [Text], value : Text) : [Text] {
    Array.filter<Text>(items, func(item : Text) : Bool { item != value })
  };

  func syncModeText(mode : SyncMode) : Text {
    switch (mode) {
      case (#realtime) { "realtime" };
      case (#historical) { "historical" };
      case (#snapshot) { "snapshot" };
      case (#recovery) { "recovery" };
    }
  };

  func takeTail<T>(items : [T], count : Nat) : [T] {
    let size = items.size();
    if (size <= count) {
      items
    } else {
      Array.tabulate<T>(count, func(index : Nat) : T {
        items[size - count + index]
      })
    }
  };

  func computeHealth(workers : [SyncWorker], conflicts : [DataConflict]) : Float {
    let workerCount = workers.size();
    let baseHealth = if (workerCount == 0) {
      DATA_SYNC_GATE
    } else {
      Array.foldLeft<SyncWorker, Float>(workers, 0.0, func(acc : Float, worker : SyncWorker) : Float {
        acc + worker.coherence
      }) / Float.fromInt(workerCount)
    };
    let penalty = Float.fromInt(conflicts.size()) * 0.02;
    Float.max(0.0, Float.min(1.0, baseHealth - penalty))
  };

  public func initDataSync() : DataSyncState {
    {
      bridge = PythonBridge.initPythonBridge();
      workers = [];
      manifests = [];
      checkpoints = [];
      conflicts = [];
      pendingDatasets = [];
      syncMode = #snapshot;
      syncHealth = DATA_SYNC_GATE;
      lastBeat = 0;
    }
  };

  public func registerWorker(
    state : DataSyncState,
    workerId : Text,
    endpoint : Text,
    datasets : [Text]
  ) : DataSyncState {
    if (state.workers.size() >= MAX_SYNC_WORKERS) { return state };
    let bridge = PythonBridge.registerPythonWorker(state.bridge, workerId, endpoint, #dataanalysis);
    let worker : SyncWorker = {
      workerId = workerId;
      endpoint = endpoint;
      datasets = datasets;
      coherence = Phi.PHI_INV;
      lastBeat = state.lastBeat;
      lagBeats = 0;
      alive = true;
    };
    let workers = Array.append(state.workers, [worker]);
    {
      bridge = bridge;
      workers = workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = state.conflicts;
      pendingDatasets = state.pendingDatasets;
      syncMode = state.syncMode;
      syncHealth = computeHealth(workers, state.conflicts);
      lastBeat = state.lastBeat;
    }
  };

  public func enqueueDataset(
    state : DataSyncState,
    dataset : Text,
    mode : SyncMode,
    beat : Int,
    coherence : Float,
    doctrineHash : Nat32
  ) : DataSyncState {
    if (coherence < DATA_SYNC_GATE or containsText(state.pendingDatasets, dataset) or state.pendingDatasets.size() >= MAX_PENDING_DATASETS) {
      return state
    };
    let payload = "{\"dataset\":\"" # dataset # "\",\"mode\":\"" # syncModeText(mode) # "\"}";
    let bridge = PythonBridge.sendToPython(state.bridge, "SYNC-" # dataset # "-" # Int.toText(beat), payload, beat, coherence, doctrineHash);
    let pending = Array.append(state.pendingDatasets, [dataset]);
    {
      bridge = bridge;
      workers = state.workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = state.conflicts;
      pendingDatasets = pending;
      syncMode = mode;
      syncHealth = computeHealth(state.workers, state.conflicts);
      lastBeat = beat;
    }
  };

  public func recordManifest(state : DataSyncState, manifest : DatasetManifest) : DataSyncState {
    let manifests = Array.append(
      Array.filter<DatasetManifest>(state.manifests, func(item : DatasetManifest) : Bool {
        item.dataset != manifest.dataset or item.partition != manifest.partition
      }),
      [manifest],
    );
    {
      bridge = state.bridge;
      workers = state.workers;
      manifests = manifests;
      checkpoints = state.checkpoints;
      conflicts = state.conflicts;
      pendingDatasets = state.pendingDatasets;
      syncMode = state.syncMode;
      syncHealth = computeHealth(state.workers, state.conflicts);
      lastBeat = state.lastBeat;
    }
  };

  public func sealCheckpoint(
    state : DataSyncState,
    dataset : Text,
    beat : Int,
    sequence : Nat,
    watermarkNs : Nat64,
    manifestHash : Text,
    compressedBytes : Nat64
  ) : DataSyncState {
    let checkpoint : SyncCheckpoint = {
      checkpointId = "CHK-" # dataset # "-" # Nat.toText(sequence);
      dataset = dataset;
      beat = beat;
      sequence = sequence;
      watermarkNs = watermarkNs;
      manifestHash = manifestHash;
      compressedBytes = compressedBytes;
    };
    {
      bridge = state.bridge;
      workers = state.workers;
      manifests = state.manifests;
      checkpoints = Array.append(state.checkpoints, [checkpoint]);
      conflicts = state.conflicts;
      pendingDatasets = withoutDataset(state.pendingDatasets, dataset);
      syncMode = state.syncMode;
      syncHealth = computeHealth(state.workers, state.conflicts);
      lastBeat = beat;
    }
  };

  public func recordConflict(
    state : DataSyncState,
    dataset : Text,
    expectedHash : Text,
    observedHash : Text,
    severity : ConflictSeverity,
    beat : Int,
    detail : Text
  ) : DataSyncState {
    let conflict : DataConflict = {
      dataset = dataset;
      expectedHash = expectedHash;
      observedHash = observedHash;
      severity = severity;
      beat = beat;
      detail = detail;
    };
    let conflicts = Array.append(state.conflicts, [conflict]);
    let trimmedConflicts = takeTail<DataConflict>(conflicts, MAX_CONFLICTS_TRACKED);
    {
      bridge = state.bridge;
      workers = state.workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = trimmedConflicts;
      pendingDatasets = state.pendingDatasets;
      syncMode = #recovery;
      syncHealth = computeHealth(state.workers, trimmedConflicts);
      lastBeat = beat;
    }
  };

  public func acknowledgeSync(
    state : DataSyncState,
    messageId : Text,
    payload : Text,
    beat : Int,
    coherence : Float,
    doctrineHash : Nat32
  ) : DataSyncState {
    let bridge = PythonBridge.receiveFromPython(state.bridge, messageId, payload, beat, coherence, doctrineHash);
    let workers = Array.map<SyncWorker, SyncWorker>(state.workers, func(worker : SyncWorker) : SyncWorker {
      {
        workerId = worker.workerId;
        endpoint = worker.endpoint;
        datasets = worker.datasets;
        coherence = Float.min(1.0, worker.coherence + Phi.PHI_INV_3);
        lastBeat = beat;
        lagBeats = 0;
        alive = true;
      }
    });
    {
      bridge = bridge;
      workers = workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = state.conflicts;
      pendingDatasets = state.pendingDatasets;
      syncMode = state.syncMode;
      syncHealth = computeHealth(workers, state.conflicts);
      lastBeat = beat;
    }
  };

  public func tickDataSync(state : DataSyncState, currentBeat : Int) : DataSyncState {
    let bridge = PythonBridge.tickPythonBridge(state.bridge, currentBeat);
    let workers = Array.map<SyncWorker, SyncWorker>(state.workers, func(worker : SyncWorker) : SyncWorker {
      let lag = Int.abs(currentBeat - worker.lastBeat);
      let coherencePenalty = if (lag > HEARTBEAT_GRACE_BEATS) { Phi.PHI_INV_3 } else { 0.0 };
      let updatedCoherence = Float.max(0.0, worker.coherence - coherencePenalty);
      {
        workerId = worker.workerId;
        endpoint = worker.endpoint;
        datasets = worker.datasets;
        coherence = updatedCoherence;
        lastBeat = worker.lastBeat;
        lagBeats = lag;
        alive = updatedCoherence >= Phi.PHI_INV_5;
      }
    });
    {
      bridge = bridge;
      workers = workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = state.conflicts;
      pendingDatasets = state.pendingDatasets;
      syncMode = state.syncMode;
      syncHealth = computeHealth(workers, state.conflicts);
      lastBeat = currentBeat;
    }
  };

  public func resolveDataset(state : DataSyncState, dataset : Text) : DataSyncState {
    let conflicts = Array.filter<DataConflict>(state.conflicts, func(conflict : DataConflict) : Bool { conflict.dataset != dataset });
    {
      bridge = state.bridge;
      workers = state.workers;
      manifests = state.manifests;
      checkpoints = state.checkpoints;
      conflicts = conflicts;
      pendingDatasets = withoutDataset(state.pendingDatasets, dataset);
      syncMode = #realtime;
      syncHealth = computeHealth(state.workers, conflicts);
      lastBeat = state.lastBeat;
    }
  };

  public func getSyncDiagnostics(state : DataSyncState) : {
    workerCount : Nat;
    aliveWorkers : Nat;
    pendingDatasets : Nat;
    manifestCount : Nat;
    checkpointCount : Nat;
    conflictCount : Nat;
    syncHealth : Float;
    bridgeCoherence : Float;
  } {
    let alive = Array.filter<SyncWorker>(state.workers, func(worker : SyncWorker) : Bool { worker.alive });
    {
      workerCount = state.workers.size();
      aliveWorkers = alive.size();
      pendingDatasets = state.pendingDatasets.size();
      manifestCount = state.manifests.size();
      checkpointCount = state.checkpoints.size();
      conflictCount = state.conflicts.size();
      syncHealth = state.syncHealth;
      bridgeCoherence = state.bridge.bridgeCoherence;
    }
  };
}
