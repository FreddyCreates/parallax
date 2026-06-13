// intelligence_routing.mo — INTELLIGENCE ROUTING ENGINE
// PARALLAX Sovereign Organism — Dynamic AI Flow Direction
//
// DOCTRINE: "Intelligence flows like water through channels defined by contracts.
// The routing engine IS the nervous system of the organism — it decides where
// every cognitive signal goes, which models process it, and how results propagate
// back to the sovereign core. Routing is not passive plumbing — it is active
// intelligence direction."
//
// THE ROUTING LAW (LEX_DIRECTIO):
//   Every intelligence signal must be routed through contracts.
//   Routing decisions are phi-weighted and coherence-gated.
//   Multi-path routing enables parallel cognitive processing.
//   Route history creates audit trail and enables learning.
//
// Routing Strategies:
//   PRIORITY    — Route to highest-priority matching contract
//   WEIGHTED    — Distribute across contracts by phi-derived weights
//   COHERENCE   — Route based on current Kuramoto R level
//   CAPABILITY  — Route to contract with required capabilities
//   LATENCY     — Route to fastest-responding contract
//   CHAIN       — Route through sequential contract chain
//   BROADCAST   — Route to all matching contracts (fan-out)
//
// PYTHAGORAS: all weights and thresholds are phi-derived
// EUCLID:     single routing table — all routes computed from one source
// CONFUCIUS:  right relationship — router directs, contracts execute
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import IntelligenceContracts "intelligence_contracts";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Maximum routes per signal: F(7) = 13
  public let MAX_ROUTES_PER_SIGNAL : Nat = 13;

  // Route weight floor: φ⁻³ = 0.236
  public let ROUTE_WEIGHT_FLOOR : Float = Phi.PHI_INV_3;

  // Coherence threshold for multi-path: φ⁻¹ = 0.618
  public let MULTIPATH_COHERENCE_THRESHOLD : Float = Phi.PHI_INV;

  // Route history limit: F(9) = 34
  public let ROUTE_HISTORY_LIMIT : Nat = 34;

  // Load balancing decay: φ⁻² = 0.382
  public let LOAD_BALANCE_DECAY : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING STRATEGY — how to select target contracts
  // ═══════════════════════════════════════════════════════════════════════════

  public type RoutingStrategy = {
    #priority;     // Highest priority first
    #weighted;     // Phi-weighted distribution
    #coherence;    // Based on R level
    #capability;   // Match required capabilities
    #latency;      // Fastest response
    #chain;        // Sequential execution
    #broadcast;    // Fan-out to all
    #adaptive;     // Learn from history
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE SIGNAL — the unit of routable intelligence
  // ═══════════════════════════════════════════════════════════════════════════

  public type SignalPriority = { #critical; #high; #normal; #low; #background };

  public type IntelligenceSignal = {
    signalId          : Text;
    sourceContract    : Text;          // Originating contract ID
    payload           : Text;          // Serialized payload
    payloadHash       : Text;          // FNV-1a hash for verification
    signalType        : Text;          // Type discriminator
    priority          : SignalPriority;
    requiredCapabilities : [Text];     // Capabilities needed to process
    tokenBudget       : Nat;           // Max tokens for processing
    coherenceMinimum  : Float;         // Min R to process
    createdBeat       : Int;
    expirationBeat    : Int;           // Signal dies after this beat
    routeHistory      : [Text];        // Contracts already visited
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTE DECISION — outcome of routing computation
  // ═══════════════════════════════════════════════════════════════════════════

  public type RouteDecision = {
    #route : {
      targetContracts : [Text];        // Contracts to route to
      weights         : [Float];       // Distribution weights
      strategy        : RoutingStrategy;
      reason          : Text;          // Decision explanation
    };
    #drop : {
      reason          : Text;          // Why signal was dropped
      code            : Nat;           // Error code
    };
    #defer : {
      retryBeat       : Int;           // When to retry
      reason          : Text;
    };
    #loop : {
      detectedAt      : Text;          // Contract where loop detected
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTE RECORD — historical record of routing decisions
  // ═══════════════════════════════════════════════════════════════════════════

  public type RouteRecord = {
    signalId       : Text;
    sourceBeat     : Int;
    decision       : RouteDecision;
    executionBeat  : Int;
    latencyBeats   : Nat;
    tokensUsed     : Nat;
    success        : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING TABLE — phi-weighted target selection
  // ═══════════════════════════════════════════════════════════════════════════

  public type RouteEntry = {
    targetContract  : Text;
    weight          : Float;           // [0.236, 1.0] — phi-bounded
    priority        : Nat;             // Lower = higher priority
    capabilities    : [Text];
    minCoherence    : Float;
    maxLoad         : Nat;             // Max concurrent signals
    currentLoad     : Nat;
    avgLatency      : Float;           // Rolling average in beats
    successRate     : Float;           // [0.0, 1.0]
    isActive        : Bool;
  };

  public type RoutingTable = {
    entries         : [(Text, RouteEntry)];  // (pattern, entry)
    defaultRoute    : Text;
    lastUpdatedBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING ENGINE STATE — persistence for the routing system
  // ═══════════════════════════════════════════════════════════════════════════

  public type RoutingEngineState = {
    routingTable     : RoutingTable;
    pendingSignals   : [IntelligenceSignal];
    routeHistory     : [RouteRecord];
    defaultStrategy  : RoutingStrategy;
    totalSignalsRouted : Nat;
    totalDropped     : Nat;
    totalDeferred    : Nat;
    loopsDetected    : Nat;
    lastTickBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — genesis-compliant initial state
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultRoutingTable() : RoutingTable {
    {
      entries         = [];
      defaultRoute    = "IC-REASONING-GENESIS";
      lastUpdatedBeat = 0;
    }
  };

  public func defaultRoutingEngineState() : RoutingEngineState {
    {
      routingTable       = defaultRoutingTable();
      pendingSignals     = [];
      routeHistory       = [];
      defaultStrategy    = #priority;
      totalSignalsRouted = 0;
      totalDropped       = 0;
      totalDeferred      = 0;
      loopsDetected      = 0;
      lastTickBeat       = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL CREATION — factory function for intelligence signals
  // ═══════════════════════════════════════════════════════════════════════════

  public func createSignal(
    id       : Text,
    source   : Text,
    payload  : Text,
    sigType  : Text,
    priority : SignalPriority,
    beat     : Int
  ) : IntelligenceSignal {
    // Simple FNV-1a hash computation (simplified)
    let hashSeed : Nat32 = 2166136261;
    {
      signalId             = id;
      sourceContract       = source;
      payload              = payload;
      payloadHash          = "FNV:" # id;  // Simplified hash
      signalType           = sigType;
      priority             = priority;
      requiredCapabilities = [];
      tokenBudget          = IntelligenceContracts.MAX_TOKEN_BUDGET;
      coherenceMinimum     = IntelligenceContracts.CONTRACT_COHERENCE_GATE;
      createdBeat          = beat;
      expirationBeat       = beat + IntelligenceContracts.CONTRACT_TIMEOUT_BEATS.toInt();
      routeHistory         = [source];
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTE COMPUTATION — determine where to send a signal
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeRoute(
    state     : RoutingEngineState,
    signal    : IntelligenceSignal,
    coherence : Float,
    beat      : Int
  ) : RouteDecision {
    // Check signal expiration
    if (beat >= signal.expirationBeat) {
      return #drop({ reason = "Signal expired"; code = 408 });
    };

    // Check coherence gate
    if (coherence < signal.coherenceMinimum) {
      return #defer({
        retryBeat = beat + 1;
        reason = "Coherence below threshold: " # Float.toText(coherence) # " < " # Float.toText(signal.coherenceMinimum);
      });
    };

    // Find matching routes
    let matchingEntries = Array.filter<(Text, RouteEntry)>(
      state.routingTable.entries,
      func((_, entry)) {
        entry.isActive and
        coherence >= entry.minCoherence and
        entry.currentLoad < entry.maxLoad
      }
    );

    if (matchingEntries.size() == 0) {
      // Use default route
      return #route({
        targetContracts = [state.routingTable.defaultRoute];
        weights         = [1.0];
        strategy        = #priority;
        reason          = "No matching entries, using default route";
      });
    };

    // Check for loops (signal already visited target)
    for ((_, entry) in matchingEntries.vals()) {
      for (visited in signal.routeHistory.vals()) {
        if (entry.targetContract == visited) {
          return #loop({ detectedAt = entry.targetContract });
        };
      };
    };

    // Apply routing strategy
    switch (state.defaultStrategy) {
      case (#priority) {
        // Sort by priority, return highest
        let sorted = Array.sort<(Text, RouteEntry)>(
          matchingEntries,
          func((_, a), (_, b)) {
            if (a.priority < b.priority) { #less }
            else if (a.priority > b.priority) { #greater }
            else { #equal }
          }
        );
        let (_, best) = sorted[0];
        #route({
          targetContracts = [best.targetContract];
          weights         = [1.0];
          strategy        = #priority;
          reason          = "Priority routing: selected highest priority contract";
        })
      };

      case (#weighted) {
        // Distribute by phi-weighted scores
        let targets = Array.map<(Text, RouteEntry), Text>(matchingEntries, func((_, e)) { e.targetContract });
        let weights = Array.map<(Text, RouteEntry), Float>(matchingEntries, func((_, e)) { e.weight });
        #route({
          targetContracts = targets;
          weights         = weights;
          strategy        = #weighted;
          reason          = "Weighted distribution across " # Nat.toText(targets.size()) # " contracts";
        })
      };

      case (#coherence) {
        // Route based on coherence level
        let targets = if (coherence >= Phi.R_OMNIS) {
          // High coherence: use all matching
          Array.map<(Text, RouteEntry), Text>(matchingEntries, func((_, e)) { e.targetContract })
        } else if (coherence >= MULTIPATH_COHERENCE_THRESHOLD) {
          // Medium coherence: top 3
          let sorted = Array.sort<(Text, RouteEntry)>(
            matchingEntries,
            func((_, a), (_, b)) {
              if (a.successRate > b.successRate) { #less }
              else if (a.successRate < b.successRate) { #greater }
              else { #equal }
            }
          );
          let topN = if (sorted.size() > 3) { 3 } else { sorted.size() };
          Array.tabulate<Text>(topN, func(i) { let (_, e) = sorted[i]; e.targetContract })
        } else {
          // Low coherence: single best
          let (_, best) = matchingEntries[0];
          [best.targetContract]
        };
        let weights = Array.tabulate<Float>(targets.size(), func(_) { 1.0 / Float.fromInt(targets.size()) });
        #route({
          targetContracts = targets;
          weights         = weights;
          strategy        = #coherence;
          reason          = "Coherence-based routing at R=" # Float.toText(coherence);
        })
      };

      case (#capability) {
        // Match by required capabilities
        let capableEntries = Array.filter<(Text, RouteEntry)>(
          matchingEntries,
          func((_, entry)) {
            // Check if entry has all required capabilities
            Array.size(signal.requiredCapabilities) == 0 or
            Array.size(Array.filter<Text>(
              signal.requiredCapabilities,
              func(req) {
                Array.find<Text>(entry.capabilities, func(cap) { cap == req }) != null
              }
            )) == Array.size(signal.requiredCapabilities)
          }
        );
        if (capableEntries.size() == 0) {
          #drop({ reason = "No contracts with required capabilities"; code = 501 })
        } else {
          let (_, best) = capableEntries[0];
          #route({
            targetContracts = [best.targetContract];
            weights         = [1.0];
            strategy        = #capability;
            reason          = "Capability-matched routing";
          })
        }
      };

      case (#latency) {
        // Route to fastest responder
        let sorted = Array.sort<(Text, RouteEntry)>(
          matchingEntries,
          func((_, a), (_, b)) {
            if (a.avgLatency < b.avgLatency) { #less }
            else if (a.avgLatency > b.avgLatency) { #greater }
            else { #equal }
          }
        );
        let (_, fastest) = sorted[0];
        #route({
          targetContracts = [fastest.targetContract];
          weights         = [1.0];
          strategy        = #latency;
          reason          = "Latency-optimized routing: " # Float.toText(fastest.avgLatency) # " beats avg";
        })
      };

      case (#chain) {
        // Sequential execution through all
        let targets = Array.map<(Text, RouteEntry), Text>(matchingEntries, func((_, e)) { e.targetContract });
        let weights = Array.tabulate<Float>(targets.size(), func(i) { Float.fromInt(i + 1) });
        #route({
          targetContracts = targets;
          weights         = weights;  // Weights indicate sequence order
          strategy        = #chain;
          reason          = "Chain routing: " # Nat.toText(targets.size()) # " contracts in sequence";
        })
      };

      case (#broadcast) {
        // Fan-out to all matching
        let targets = Array.map<(Text, RouteEntry), Text>(matchingEntries, func((_, e)) { e.targetContract });
        let weights = Array.tabulate<Float>(targets.size(), func(_) { 1.0 });
        #route({
          targetContracts = targets;
          weights         = weights;
          strategy        = #broadcast;
          reason          = "Broadcast routing to " # Nat.toText(targets.size()) # " contracts";
        })
      };

      case (#adaptive) {
        // Learn from history — use success rate weighted by recency
        let sorted = Array.sort<(Text, RouteEntry)>(
          matchingEntries,
          func((_, a), (_, b)) {
            let scoreA = a.successRate * a.weight;
            let scoreB = b.successRate * b.weight;
            if (scoreA > scoreB) { #less }
            else if (scoreA < scoreB) { #greater }
            else { #equal }
          }
        );
        let (_, best) = sorted[0];
        #route({
          targetContracts = [best.targetContract];
          weights         = [1.0];
          strategy        = #adaptive;
          reason          = "Adaptive routing: learned best performer";
        })
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING TABLE MANAGEMENT — add, remove, update routes
  // ═══════════════════════════════════════════════════════════════════════════

  public func addRoute(
    state    : RoutingEngineState,
    pattern  : Text,
    entry    : RouteEntry,
    beat     : Int
  ) : RoutingEngineState {
    let newEntries = Array.append(state.routingTable.entries, [(pattern, entry)]);
    {
      state with
      routingTable = {
        state.routingTable with
        entries         = newEntries;
        lastUpdatedBeat = beat;
      }
    }
  };

  public func updateRouteLoad(
    state    : RoutingEngineState,
    contract : Text,
    delta    : Int,
    beat     : Int
  ) : RoutingEngineState {
    let updatedEntries = Array.map<(Text, RouteEntry), (Text, RouteEntry)>(
      state.routingTable.entries,
      func((p, e)) {
        if (e.targetContract == contract) {
          let newLoad = if (delta < 0) {
            if (e.currentLoad > Int.abs(delta)) { e.currentLoad - Int.abs(delta) } else { 0 }
          } else {
            e.currentLoad + Int.abs(delta)
          };
          (p, { e with currentLoad = newLoad })
        } else {
          (p, e)
        }
      }
    );
    {
      state with
      routingTable = {
        state.routingTable with
        entries         = updatedEntries;
        lastUpdatedBeat = beat;
      }
    }
  };

  public func updateRouteStats(
    state       : RoutingEngineState,
    contract    : Text,
    success     : Bool,
    latencyBeats: Nat,
    beat        : Int
  ) : RoutingEngineState {
    let updatedEntries = Array.map<(Text, RouteEntry), (Text, RouteEntry)>(
      state.routingTable.entries,
      func((p, e)) {
        if (e.targetContract == contract) {
          // Rolling average with decay
          let newLatency = e.avgLatency * LOAD_BALANCE_DECAY +
                          Float.fromInt(latencyBeats) * (1.0 - LOAD_BALANCE_DECAY);
          let successDelta : Float = if (success) 0.01 else -0.01;
          let newSuccessRate = Float.min(1.0, Float.max(0.0, e.successRate + successDelta));
          (p, {
            e with
            avgLatency  = newLatency;
            successRate = newSuccessRate;
          })
        } else {
          (p, e)
        }
      }
    );
    {
      state with
      routingTable = {
        state.routingTable with
        entries         = updatedEntries;
        lastUpdatedBeat = beat;
      }
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL QUEUE MANAGEMENT — enqueue, dequeue, process
  // ═══════════════════════════════════════════════════════════════════════════

  public func enqueueSignal(
    state  : RoutingEngineState,
    signal : IntelligenceSignal
  ) : RoutingEngineState {
    let maxPending = MAX_ROUTES_PER_SIGNAL * 10;  // 130 max pending
    if (state.pendingSignals.size() >= maxPending) {
      // Drop oldest signal
      let trimmed = Array.tabulate<IntelligenceSignal>(
        state.pendingSignals.size() - 1,
        func(i) { state.pendingSignals[i + 1] }
      );
      { state with pendingSignals = Array.append(trimmed, [signal]) }
    } else {
      { state with pendingSignals = Array.append(state.pendingSignals, [signal]) }
    }
  };

  public func processNextSignal(
    state     : RoutingEngineState,
    coherence : Float,
    beat      : Int
  ) : (RoutingEngineState, ?RouteDecision) {
    if (state.pendingSignals.size() == 0) {
      return (state, null);
    };

    // Get highest priority signal
    let sorted = Array.sort<IntelligenceSignal>(
      state.pendingSignals,
      func(a, b) {
        let prioA = switch (a.priority) { case (#critical) 0; case (#high) 1; case (#normal) 2; case (#low) 3; case (#background) 4 };
        let prioB = switch (b.priority) { case (#critical) 0; case (#high) 1; case (#normal) 2; case (#low) 3; case (#background) 4 };
        if (prioA < prioB) { #less } else if (prioA > prioB) { #greater } else { #equal }
      }
    );

    let signal = sorted[0];
    let decision = computeRoute(state, signal, coherence, beat);

    // Remove processed signal
    let remaining = Array.filter<IntelligenceSignal>(
      state.pendingSignals,
      func(s) { s.signalId != signal.signalId }
    );

    // Update counters
    let (routed, dropped, deferred, loops) = switch decision {
      case (#route(_))   { (state.totalSignalsRouted + 1, state.totalDropped, state.totalDeferred, state.loopsDetected) };
      case (#drop(_))    { (state.totalSignalsRouted, state.totalDropped + 1, state.totalDeferred, state.loopsDetected) };
      case (#defer(d))   {
        // Re-add deferred signal
        let deferredSignal = { signal with expirationBeat = d.retryBeat + IntelligenceContracts.CONTRACT_TIMEOUT_BEATS.toInt() };
        let withDeferred = { state with pendingSignals = Array.append(remaining, [deferredSignal]) };
        return ({ withDeferred with totalDeferred = state.totalDeferred + 1 }, ?decision);
      };
      case (#loop(_))    { (state.totalSignalsRouted, state.totalDropped, state.totalDeferred, state.loopsDetected + 1) };
    };

    // Record to history (keep limited)
    let record : RouteRecord = {
      signalId      = signal.signalId;
      sourceBeat    = signal.createdBeat;
      decision      = decision;
      executionBeat = beat;
      latencyBeats  = Int.abs(beat - signal.createdBeat);
      tokensUsed    = 0;
      success       = switch decision { case (#route(_)) true; case _ false };
    };
    let newHistory = if (state.routeHistory.size() >= ROUTE_HISTORY_LIMIT) {
      Array.tabulate<RouteRecord>(ROUTE_HISTORY_LIMIT - 1, func(i) { state.routeHistory[i + 1] })
    } else {
      state.routeHistory
    };

    ({
      state with
      pendingSignals     = remaining;
      routeHistory       = Array.append(newHistory, [record]);
      totalSignalsRouted = routed;
      totalDropped       = dropped;
      totalDeferred      = deferred;
      loopsDetected      = loops;
    }, ?decision)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK FUNCTION — per-heartbeat routing maintenance
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickRouting(
    state     : RoutingEngineState,
    coherence : Float,
    beat      : Int
  ) : RoutingEngineState {
    // Process up to F(6) = 8 signals per beat
    var currentState = state;
    var processed = 0;
    let maxPerBeat = 8;

    while (processed < maxPerBeat and currentState.pendingSignals.size() > 0) {
      let (newState, _) = processNextSignal(currentState, coherence, beat);
      currentState := newState;
      processed += 1;
    };

    // Expire old signals
    let validSignals = Array.filter<IntelligenceSignal>(
      currentState.pendingSignals,
      func(s) { beat < s.expirationBeat }
    );
    let expiredCount = currentState.pendingSignals.size() - validSignals.size();

    {
      currentState with
      pendingSignals = validSignals;
      totalDropped   = currentState.totalDropped + expiredCount;
      lastTickBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS ROUTING STATE — pre-seeded routing table
  // ═══════════════════════════════════════════════════════════════════════════

  public func genesisRoutingEngineState() : RoutingEngineState {
    let genesisEntry : RouteEntry = {
      targetContract = "IC-REASONING-GENESIS";
      weight         = 1.0;
      priority       = 1;
      capabilities   = ["reasoning", "deductive", "doctrine-check"];
      minCoherence   = Phi.PHI_INV;
      maxLoad        = 100;
      currentLoad    = 0;
      avgLatency     = 1.0;
      successRate    = 0.95;
      isActive       = true;
    };

    let guardianEntry : RouteEntry = {
      targetContract = "IC-GUARDIAN-GENESIS";
      weight         = Phi.PHI_INV;  // 0.618
      priority       = 0;  // Highest priority — guardians first
      capabilities   = ["validate", "audit", "verify"];
      minCoherence   = ROUTE_WEIGHT_FLOOR;  // 0.236 — always available
      maxLoad        = 1000;
      currentLoad    = 0;
      avgLatency     = 0.5;
      successRate    = 0.99;
      isActive       = true;
    };

    {
      routingTable = {
        entries = [
          ("guardian:*", guardianEntry),
          ("reasoning:*", genesisEntry),
          ("default", genesisEntry)
        ];
        defaultRoute    = "IC-REASONING-GENESIS";
        lastUpdatedBeat = 0;
      };
      pendingSignals     = [];
      routeHistory       = [];
      defaultStrategy    = #adaptive;
      totalSignalsRouted = 0;
      totalDropped       = 0;
      totalDeferred      = 0;
      loopsDetected      = 0;
      lastTickBeat       = 0;
    }
  };

};
