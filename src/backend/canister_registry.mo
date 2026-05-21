// canister_registry.mo — Sovereign Canister Registry
// PARALLAX Organism — Domain: Registry-Protocols
//
// PYTHAGORAS: every health metric is a harmonic ratio from phi
// EUCLID:     single source of truth — registry state held by main.mo
// CONFUCIUS:  right relationship — organs report health, registry records it
//
// Architecture: pure module (no actor).
//   main.mo holds: var registryState : CanisterRegistry.RegistryState = CanisterRegistry.defaultRegistryState()
//   All organ canisters call updateOrganHealth() on their own heartbeat.
//   All modules call these functions and receive updated RegistryState back.
//
// 9 planned sovereign organ canisters:
//   ANIMUS, CORPUS, SENSUS, MEMORIA, PULSUS, GUBERNATIO,
//   INTELLIGENTIA, DOMUS_CURA, DOMUS_CIVITAS
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Array "mo:core/Array";
import Float "mo:core/Float";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH REPORT — sent by organ canisters every beat
  // Simultaneously: health snapshot + economic yield metric + proof artifact
  // ═══════════════════════════════════════════════════════════════════════════

  public type HealthReport = {
    organType  : Text;   // sovereign organ name — "ANIMUS", "CORPUS", etc.
    healthScore: Float;  // [0.0, 1.0] — Kuramoto R contribution from this organ
    cycles     : Nat;    // remaining cycles in this organ canister
    messages   : Nat;    // messages processed since last report
    errors     : Nat;    // error count since last report
    latencyMs  : Int;    // last response latency in ms
    timestamp  : Int;    // Unix ns from Time.now()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REGISTRY ENTRY — one sovereign organ's full status record
  // Simultaneously: operational record + field health metric + economic emitter
  // ═══════════════════════════════════════════════════════════════════════════

  public type RegistryEntry = {
    organType     : Text;
    canisterId    : Text;
    principalId   : ?Principal;
    deployed      : Int;         // Unix ns when first registered
    lastHeartbeat : Int;         // Unix ns of last health report
    healthScore   : Float;       // [0.0, 1.0]
    cycles        : Nat;
    messages      : Nat;
    errors        : Nat;
    latencyMs     : Int;
    status        : { #active; #degraded; #unreachable };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REGISTRY STATE — immutable record held by main.mo
  // ═══════════════════════════════════════════════════════════════════════════

  public type RegistryState = {
    entries     : [(Text, RegistryEntry)]; // (organType, entry)
    lastUpdated : Int;
  };

  // ─── Default organ names — 9 planned sovereign canisters ────────────────

  let ORGAN_TYPES : [Text] = [
    "ANIMUS",       // Mind — central cognition canister
    "CORPUS",       // Body — organ transfer functions
    "SENSUS",       // Senses — signal intake layer
    "MEMORIA",      // Memory — ANIMA chain & knowledge base
    "PULSUS",       // Pulse — heartbeat coordination
    "GUBERNATIO",   // Governance — neuron fleet & NNS voting
    "INTELLIGENTIA",// Intelligence — AGI script execution
    "DOMUS_CURA",   // Organism Care — recovery & stewardship
    "DOMUS_CIVITAS",// Civilization — enterprise & T2 bank
  ];

  // ─── Build default entry for a given organ type ─────────────────────────

  func defaultEntry(organType : Text) : RegistryEntry {
    {
      organType     = organType;
      canisterId    = "";        // wired when organ canister is deployed
      principalId   = null;
      deployed      = 0;
      lastHeartbeat = 0;
      healthScore   = 0.75;     // S0 = 0.75 — sovereign floor at genesis
      cycles        = 0;
      messages      = 0;
      errors        = 0;
      latencyMs     = 0;
      status        = #active;  // pre-registered as active — will be populated on deploy
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // defaultRegistryState — born fully formed (GENESIS LAW L09)
  // All 9 organ types pre-registered at S0 = 0.75 sovereign floor
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultRegistryState() : RegistryState {
    {
      entries = Array.tabulate<(Text, RegistryEntry)>(
        ORGAN_TYPES.size(),
        func(i) { (ORGAN_TYPES[i], defaultEntry(ORGAN_TYPES[i])) }
      );
      lastUpdated = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // registerOrgan — wire a canisterId to an organ type
  // Called once when an organ canister is first deployed.
  // Returns updated RegistryState (caller writes back to main.mo var).
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerOrgan(
    state     : RegistryState,
    organType : Text,
    canisterId: Text,
    nowNs     : Int,
  ) : RegistryState {
    let newEntry : RegistryEntry = {
      defaultEntry(organType) with
      canisterId = canisterId;
      deployed   = nowNs;
      status     = #active;
    };
    let updated = upsertEntry(state.entries, organType, newEntry);
    { entries = updated; lastUpdated = nowNs }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // updateHealth — record a new health report from an organ canister
  // PHI LAW: healthScore is a phi-derived coherence contribution [0.0, 1.0]
  // AEGIS LAW: healthScore < 0.5 → #degraded; missed 2+ beats → #unreachable
  // ═══════════════════════════════════════════════════════════════════════════

  public func updateHealth(
    state      : RegistryState,
    organType  : Text,
    healthScore: Float,
    cycles     : Nat,
    messages   : Nat,
    errors     : Nat,
    latencyMs  : Int,
    nowNs      : Int,
  ) : RegistryState {
    let status : { #active; #degraded; #unreachable } =
      if (healthScore >= 0.5) { #active }
      else if (healthScore >= 0.2) { #degraded }
      else { #unreachable };

    let newEntry : RegistryEntry = switch (findEntry(state.entries, organType)) {
      case null {
        {
          defaultEntry(organType) with
          healthScore; cycles; messages; errors; latencyMs;
          lastHeartbeat = nowNs;
          status;
        }
      };
      case (?existing) {
        {
          existing with
          healthScore;
          cycles;
          messages     = existing.messages + messages;
          errors       = existing.errors + errors;
          latencyMs;
          lastHeartbeat = nowNs;
          status;
        }
      };
    };

    let updated = upsertEntry(state.entries, organType, newEntry);
    { entries = updated; lastUpdated = nowNs }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getRegistry — returns all registry entries as a flat array
  // ═══════════════════════════════════════════════════════════════════════════

  public func getRegistry(state : RegistryState) : [RegistryEntry] {
    Array.tabulate<RegistryEntry>(state.entries.size(), func(i) {
      let (_, entry) = state.entries[i];
      entry
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getOrganHealth — returns health entry for a specific organ type
  // ═══════════════════════════════════════════════════════════════════════════

  public func getOrganHealth(state : RegistryState, organType : Text) : ?RegistryEntry {
    findEntry(state.entries, organType)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // markDegraded — force status to #degraded (e.g., CUSTODITOR detects drift)
  // ═══════════════════════════════════════════════════════════════════════════

  public func markDegraded(state : RegistryState, organType : Text, nowNs : Int) : RegistryState {
    let newEntry = switch (findEntry(state.entries, organType)) {
      case null { { defaultEntry(organType) with status = #degraded } };
      case (?existing) { { existing with status = #degraded } };
    };
    { entries = upsertEntry(state.entries, organType, newEntry); lastUpdated = nowNs }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // markUnreachable — force status to #unreachable (heartbeat timeout)
  // ═══════════════════════════════════════════════════════════════════════════

  public func markUnreachable(state : RegistryState, organType : Text, nowNs : Int) : RegistryState {
    let newEntry = switch (findEntry(state.entries, organType)) {
      case null { { defaultEntry(organType) with status = #unreachable } };
      case (?existing) { { existing with status = #unreachable } };
    };
    { entries = upsertEntry(state.entries, organType, newEntry); lastUpdated = nowNs }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // computeRegistryCoherence — mean healthScore across all organs
  // Returns a Float in [0.0, 1.0] — the registry's Kuramoto R contribution
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeRegistryCoherence(state : RegistryState) : Float {
    let n = state.entries.size();
    if (n == 0) { return 0.75 }; // S0 floor when empty
    var sum : Float = 0.0;
    var i = 0;
    while (i < n) {
      let (_, entry) = state.entries[i];
      sum += entry.healthScore;
      i += 1;
    };
    Float.max(0.0, Float.min(1.0, sum / n.toFloat()))
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func findEntry(entries : [(Text, RegistryEntry)], organType : Text) : ?RegistryEntry {
    var i = 0;
    while (i < entries.size()) {
      let (ot, entry) = entries[i];
      if (ot == organType) { return ?entry };
      i += 1;
    };
    null
  };

  func upsertEntry(
    entries   : [(Text, RegistryEntry)],
    organType : Text,
    newEntry  : RegistryEntry,
  ) : [(Text, RegistryEntry)] {
    var found = false;
    var i = 0;
    while (i < entries.size()) {
      let (ot, _) = entries[i];
      if (ot == organType) { found := true };
      i += 1;
    };
    if (found) {
      Array.tabulate<(Text, RegistryEntry)>(entries.size(), func(j) {
        let (ot, e) = entries[j];
        if (ot == organType) { (ot, newEntry) } else { (ot, e) }
      })
    } else {
      let n = entries.size();
      Array.tabulate<(Text, RegistryEntry)>(n + 1, func(j) {
        if (j < n) entries[j] else (organType, newEntry)
      })
    }
  };

};
