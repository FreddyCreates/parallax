// phantom_memory.mo — PHANTOM MEMORY LATTICE
// PARALLAX Sovereign Organism — Market Memory & Pattern Recognition System
//
// DOCTRINE: "The Phantom Memory Lattice remembers everything the market has ever
// done. Not as raw data — but as PATTERNS, RESONANCES, and ARCHETYPES. It is the
// organism's hippocampus — encoding market events into phi-harmonic memory traces
// that persist across all timeframes and inform all decisions."
//
// PHANTOM MEMORY ARCHITECTURE:
//   PML-001  PATTERN ENCODER          — Encodes market events as memory traces
//   PML-002  RESONANCE DETECTOR       — Finds current events matching past patterns
//   PML-003  ARCHETYPE LIBRARY        — Canonical market pattern archetypes
//   PML-004  TEMPORAL BINDING         — Links events across timeframes
//   PML-005  FORGETTING CURVE         — Phi-derived memory decay (Ebbinghaus)
//   PML-006  CONSOLIDATION ENGINE     — Strengthens repeated patterns
//   PML-007  RECALL INTERFACE         — Fast pattern lookup for decision engines
//
// PYTHAGORAS: memory decay follows phi-harmonic Ebbinghaus curve
// EUCLID:     single memory state — all patterns in PhantomMemoryState
// CONFUCIUS:  right relationship — memory informs, intelligence decides
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  public let MEMORY_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MEMORY_DECAY_PHI : Float = Phi.PHI_INV;      // Decay rate per epoch
  public let CONSOLIDATION_THRESHOLD : Nat = 5;           // Repeats to consolidate
  public let MAX_ACTIVE_PATTERNS : Nat = 233;             // Fibonacci-233
  public let RECALL_SIMILARITY_GATE : Float = Phi.PHI_INV_2; // 0.382 min similarity

  public type PatternType = {
    #priceAction;     // Candlestick/price patterns
    #volumeProfile;   // Volume distribution patterns
    #orderFlow;       // Buy/sell pressure patterns
    #regime;          // Market regime patterns
    #correlation;     // Cross-asset correlation patterns
    #volatility;      // Vol surface patterns
    #fractal;         // Self-similar multi-scale patterns
  };

  public type MemoryTrace = {
    traceId          : Nat;
    patternType      : PatternType;
    encoding         : [Float];    // Vector encoding of the pattern
    strength         : Float;      // [0, 1] — how well remembered
    repetitions      : Nat;        // Times this pattern has occurred
    firstSeenBeat    : Int;
    lastSeenBeat     : Int;
    avgOutcome       : Float;      // What usually follows this pattern
    confidenceInOutcome : Float;   // How reliable the outcome is
    consolidated     : Bool;       // Has it been consolidated to long-term?
  };

  public type PhantomMemoryState = {
    activeTraces      : [MemoryTrace];
    consolidatedCount : Nat;
    totalEncoded      : Nat;
    totalRecalls      : Nat;
    avgRecallAccuracy : Float;
    memoryUtilization : Float;     // Active / MAX_ACTIVE_PATTERNS
    strongestPattern  : ?Nat;      // traceId of strongest current pattern
    memoryCoherence   : Float;
    lastTickBeat      : Int;
    forgottenCount    : Nat;
  };

  public func defaultPhantomMemoryState() : PhantomMemoryState {
    {
      activeTraces      = [];
      consolidatedCount = 0;
      totalEncoded      = 0;
      totalRecalls      = 0;
      avgRecallAccuracy = 0.0;
      memoryUtilization = 0.0;
      strongestPattern  = null;
      memoryCoherence   = Phi.S0;
      lastTickBeat      = 0;
      forgottenCount    = 0;
    }
  };

  public func tickPhantomMemory(state : PhantomMemoryState, beat : Int, kuramotoR : Float) : PhantomMemoryState {
    if (kuramotoR < MEMORY_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Apply Ebbinghaus forgetting curve (phi-derived)
    let decayed = Array.map<MemoryTrace, MemoryTrace>(state.activeTraces, func(trace) {
      let beatsSinceLastSeen = beat - trace.lastSeenBeat;
      let decayFactor = Float.pow(MEMORY_DECAY_PHI, Float.fromInt(beatsSinceLastSeen) / 1000.0);
      let newStrength = trace.strength * decayFactor;
      { trace with strength = newStrength }
    });

    // Filter forgotten traces (below phi^-3 threshold)
    let alive = Array.filter<MemoryTrace>(decayed, func(t) {
      t.strength >= Phi.PHI_INV_3 * 0.1 or t.consolidated
    });

    let forgotten = decayed.size() - alive.size();

    // Find strongest pattern
    var maxStrength : Float = 0.0;
    var strongestId : ?Nat = null;
    for (trace in alive.vals()) {
      if (trace.strength > maxStrength) {
        maxStrength := trace.strength;
        strongestId := ?trace.traceId;
      };
    };

    let utilization = Float.fromInt(alive.size()) / Float.fromInt(MAX_ACTIVE_PATTERNS);
    let newCoherence = state.memoryCoherence * 0.9 + kuramotoR * 0.1;

    {
      state with
      activeTraces      = alive;
      strongestPattern  = strongestId;
      memoryUtilization = utilization;
      memoryCoherence   = newCoherence;
      lastTickBeat      = beat;
      forgottenCount    = state.forgottenCount + forgotten;
    }
  };
}
