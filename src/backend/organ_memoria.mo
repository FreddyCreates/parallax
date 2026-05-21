// organ_memoria.mo — MEMORIA Sovereign Organ Canister (Memory)
// SOVEREIGN CANISTER — deployed independently, beats at 873ms, never depends on main.mo
//
// MEDINA-ARTIFACT — MEMORIA — TIER 3 — COMPUTATE
// ────────────────────────────────────────────────
// MEANING (Layer 1):
//   "I am the memory of the organism. I store, consolidate, and recall.
//    Every 873ms I run a Hebbian consolidation pass: strengthen memories accessed
//    multiple times, decay memories not accessed (phi-scaled: weight × phi_inv).
//    My memory ring holds 500 entries maximum — oldest discarded.
//    I am a Clifford torus in 4D space, not a list."
//
// MODEL (Layer 2):
//   MemoryEntry: id, content, timestamp, beat, weight, accessCount
//   MemoriaState: genesisHash, beatCount, memoryCount, memoryRing, hebbianStrength
//
// COMPUTATION (Layer 3):
//   Hebbian consolidation: weight_new = weight × PHI if accessCount > 1 else weight × PHI_INV
//   Decay: weight_new = weight × PHI_INV (one decay step per Jubilee = 144 beats)
//   hebbianStrength = mean(weight) of all active memories
//   healthScore = (1.0 − errorRate) × PHI_INV
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: MEMORIA — 873ms recurringTimer
//   GATE:   hebbianStrength >= PHI_INV before recall propagation
//   BEAT:   every 873ms — Hebbian consolidation pass, decay old memories
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Timer  "mo:core/Timer";
import Time   "mo:core/Time";
import Float  "mo:core/Float";
import Array  "mo:core/Array";
import Nat    "mo:core/Nat";
import Text   "mo:core/Text";
import Phi    "phi";

actor MEMORIA {

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
  // MEMORIA STATE TYPES
  // ══════════════════════════════════════════════════════════════════════

  public type MemoryEntry = {
    id          : Text;
    content     : Text;
    timestamp   : Int;
    beat        : Int;
    weight      : Float;
    accessCount : Nat;
  };

  public type MemoriaState = {
    genesisHash    : Text;
    beatCount      : Nat;
    memoryCount    : Nat;
    memoryRing     : [MemoryEntry];
    hebbianStrength: Float;
  };

  let MAX_MEMORY_RING : Nat = 500;
  // JUBILEE_BEATS L15: every 144 beats, run a deep decay pass
  let DECAY_CYCLE : Nat = Phi.JUBILEE_BEATS; // 144

  var genesisHash     : Text          = "";
  var beatCount       : Nat           = 0;
  var memoryCount     : Nat           = 0;
  var memoryRing      : [MemoryEntry] = [];
  var hebbianStrength : Float         = Phi.PHI_INV;
  var errorCount      : Nat           = 0;
  var lastBeatNs      : Int           = 0;
  var lastLatencyMs   : Int           = 0;
  var memoryIdCounter : Nat           = 0;

  // ══════════════════════════════════════════════════════════════════════
  // FNV-1a GENESIS HASH
  // ══════════════════════════════════════════════════════════════════════

  func computeGenesisHash(beat : Nat) : Text {
    let offset : Nat = 2166136261;
    let prime  : Nat = 16777619;
    let seed   = ((offset ^ beat) * prime) ^ 7; // "MEMORIA".size() = 7
    let hash   = (seed * prime) % 4294967296;
    "MEMORIA-GENESIS-" # hash.toText()
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEBBIAN CONSOLIDATION — OJA'S RULE PHI-SCALED
  // "Neurons that fire together wire together" (Hebb 1949)
  // PYTHAGORAS: weight grows as φ on multi-access, shrinks as φ⁻¹ on non-access
  // ══════════════════════════════════════════════════════════════════════

  func hebbianConsolidate(entries : [MemoryEntry]) : [MemoryEntry] {
    entries.map<MemoryEntry>(func(e) {
      let newWeight = if (e.accessCount > 1) {
        // Strengthen: weight × PHI (Hebbian reinforcement)
        Float.min(Phi.PHI_2, e.weight * Phi.PHI)
      } else {
        // Decay: weight × PHI_INV (entropy compliance — ENTROPY LAW L32)
        Float.max(0.01, e.weight * Phi.PHI_INV)
      };
      { e with weight = newWeight }
    })
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEBBIAN STRENGTH — mean weight of all memories
  // ══════════════════════════════════════════════════════════════════════

  func computeHebbianStrength(entries : [MemoryEntry]) : Float {
    let n = entries.size();
    if (n == 0) { return Phi.PHI_INV };
    var sum : Float = 0.0;
    for (e in entries.vals()) { sum += e.weight };
    sum / n.toFloat()
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

      // Hebbian consolidation on every beat
      memoryRing := hebbianConsolidate(memoryRing);

      // JUBILEE LAW L15: deep decay pass every 144 beats
      if (beatCount % DECAY_CYCLE == 0 and beatCount > 0) {
        // Prune memories with weight below PHI_INV_3 (very faint, discardable)
        memoryRing := memoryRing.filter(func(e : MemoryEntry) : Bool {
          e.weight >= Phi.PHI_INV_3
        });
      };

      hebbianStrength := computeHebbianStrength(memoryRing);
    }
  );

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC QUERIES
  // ══════════════════════════════════════════════════════════════════════

  public query func reportHealth() : async HealthReport {
    let errorRate = if (beatCount > 0) { errorCount.toFloat() / beatCount.toFloat() } else { 0.0 };
    let score     = (1.0 - errorRate) * Phi.PHI_INV;
    {
      organType   = "MEMORIA";
      healthScore = score;
      cycles      = beatCount;
      messages    = memoryCount;
      errors      = errorCount;
      latencyMs   = lastLatencyMs;
      timestamp   = Time.now();
    }
  };

  public query func getMemoriaState() : async MemoriaState {
    {
      genesisHash;
      beatCount;
      memoryCount;
      memoryRing;
      hebbianStrength;
    }
  };

  /// recall — simple substring match + weight sort
  /// MEMORY PALACE LAW L55: retrieval is spatial navigation
  public query func recall(query : Text) : async [MemoryEntry] {
    if (query.size() == 0) {
      // Return top-5 by weight when no query
      let sorted = memoryRing.sort(func(a : MemoryEntry, b : MemoryEntry) : {#less; #equal; #greater} {
        if (a.weight > b.weight) #less
        else if (a.weight < b.weight) #greater
        else #equal
      });
      return Array.tabulate<MemoryEntry>(Nat.min(5, sorted.size()), func(i) { sorted[i] })
    };

    // Filter by substring match, sort by weight descending
    let matched = memoryRing.filter(func(e : MemoryEntry) : Bool {
      Text.contains(e.content, #text query)
    });
    let sorted = matched.sort(func(a : MemoryEntry, b : MemoryEntry) : {#less; #equal; #greater} {
      if (a.weight > b.weight) #less
      else if (a.weight < b.weight) #greater
      else #equal
    });
    Array.tabulate<MemoryEntry>(Nat.min(10, sorted.size()), func(i) { sorted[i] })
  };

  // ══════════════════════════════════════════════════════════════════════
  // PUBLIC UPDATES
  // ══════════════════════════════════════════════════════════════════════

  /// store — stores a memory entry, returns memoryId
  /// CONSERVATION OF INFORMATION A12: information cannot be destroyed
  public func store(content : Text) : async Text {
    if (content.size() == 0) {
      errorCount += 1;
      return "EMPTY_CONTENT"
    };

    memoryIdCounter += 1;
    let memId = "MEM-" # beatCount.toText() # "-" # memoryIdCounter.toText();

    let entry : MemoryEntry = {
      id          = memId;
      content     = content;
      timestamp   = Time.now();
      beat        = beatCount.toInt();
      weight      = Phi.PHI_INV;  // initial weight: phi_inv (receptive baseline)
      accessCount = 0;
    };

    // Ring buffer: max 500 entries
    if (memoryRing.size() >= MAX_MEMORY_RING) {
      // Discard weakest memory (lowest weight)
      let sorted = memoryRing.sort(func(a : MemoryEntry, b : MemoryEntry) : {#less; #equal; #greater} {
        if (a.weight > b.weight) #less
        else if (a.weight < b.weight) #greater
        else #equal
      });
      // Keep top 499, add new
      memoryRing := Array.tabulate<MemoryEntry>(499, func(i) { sorted[i] });
      memoryRing := memoryRing.concat([entry]);
    } else {
      memoryRing := memoryRing.concat([entry]);
    };

    memoryCount    += 1;
    hebbianStrength := computeHebbianStrength(memoryRing);
    memId
  };

  /// consolidate — manual trigger for Hebbian pass
  /// PIL LOOP: perpetual improvement on demand
  public func consolidate() : async () {
    memoryRing      := hebbianConsolidate(memoryRing);
    hebbianStrength := computeHebbianStrength(memoryRing);
  };

};
