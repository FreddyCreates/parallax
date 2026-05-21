// nodus.mo — NODUS Neural Emergence Cores
// Library module: exports types and pure functions.
// The calling actor (main.mo) owns: var nodusRegistry : Nodus.NodusRegistry
//
// PYTHAGORAS: compound rates and coherence thresholds are phi-derived ratios
// EUCLID:     single registry, one source of truth per node
// CONFUCIUS:  right relationship — each node carries substrate, health, and sovereign state
//
// SSU-wrapped: Φ_CLOCK 873ms, Ω_GATE Kuramoto R≥0.618, Δ_AEGIS anti-drift,
//              Λ_PIL self-improvement loop, Ψ_IDENTITY genesis hash
//
// Zero-Exposure Wall: no doctrine names or law labels in public interfaces.
// mo:core only. No mo:base.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Nat   "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Char  "mo:core/Char";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  // SSU wrapper state injected into every Neural Emergence Core
  public type SsuState = {
    clockMs    : Nat;    // Φ_CLOCK — sovereign heartbeat interval in ms (873)
    coherenceR : Float;  // Ω_GATE — Kuramoto R order parameter (gate opens at ≥0.618)
    aegisOk    : Bool;   // Δ_AEGIS — true when coherenceR ≥ PHI_INV (anti-drift clear)
    pilCycle   : Nat;    // Λ_PIL — perpetual improvement loop cycle counter
    psiHash    : Text;   // Ψ_IDENTITY — genesis hash sealed at first heartbeat
  };

  // Substrate type: where the node lives
  public type SubstrateType = { #ICP; #WEB; #ANIMA };

  // NodusRecord: a single Neural Emergence Core
  public type NodusRecord = {
    id               : Text;          // unique sovereign ID
    name             : Text;          // human-readable name (no doctrine labels exposed)
    substrate        : SubstrateType; // ICP | WEB | ANIMA
    healthScore      : Float;         // 0.0..1.0 — organism health
    rewardsIcp       : Float;         // accumulated ICP rewards
    compoundRate     : Float;         // per-tick compound rate (phi-derived)
    ssuState         : SsuState;      // SSU wrapper state
    beatCount        : Nat;           // heartbeat count for this node
    isSovereignPart  : Bool;          // assigned to an enterprise as sovereign part
    assignedToCompany: ?Text;         // company name if assigned, else null
    activatedAt      : Int;           // activation timestamp (nanoseconds)
  };

  // NodusRegistry: top-level container
  public type NodusRegistry = {
    nodes               : [(Text, NodusRecord)]; // (id → record) pairs
    totalRewards        : Float;                 // sum of all node rewardsIcp
    lastTick            : Int;                   // timestamp of last tickNodi call
    registryGenesisHash : Text;                  // Ψ_IDENTITY for the registry itself
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // fnv1aHash — FNV-1a hash of a Text string → deterministic Text identifier
  // Prime Foundation Law: hash is irreducible, cannot be forged.
  func fnv1aHash(input : Text) : Text {
    var hash : Nat32 = 2_166_136_261; // FNV-1a offset basis (32-bit)
    for (c in input.toIter()) {
      let code = c.toNat32();
      hash := (hash ^ code) *% 16_777_619;
    };
    hash.toNat().toText()
  };

  // buildPsiHash — Ψ_IDENTITY genesis hash for a single node
  // FNV-1a(id ++ PHI constant serialized to 10 decimal places)
  func buildPsiHash(id : Text) : Text {
    let phiText = Phi.PHI.format(#fix (10 : Nat8));
    fnv1aHash(id # phiText)
  };

  // buildRegistryPsiHash — Ψ_IDENTITY for the registry as a whole
  func buildRegistryPsiHash() : Text {
    fnv1aHash("NODUS-REGISTRY" # Phi.PHI.format(#fix (10 : Nat8)))
  };

  // defaultSsuState — SSU state for a newly activated node
  // Starts at coherenceR = φ⁻¹ (gate threshold), AEGIS clear, PIL at 0
  func defaultSsuState(id : Text) : SsuState {
    {
      clockMs    = 873;                 // Φ_CLOCK — sovereign cardiac interval (ms)
      coherenceR = Phi.R_SCHUMANN_LOCK; // φ⁻¹ = 0.618 — gate opens at this level
      aegisOk    = true;                // Δ_AEGIS — clear at genesis
      pilCycle   = 0;                   // Λ_PIL — starts at zero
      psiHash    = buildPsiHash(id);    // Ψ_IDENTITY — sealed at formation
    }
  };

  // makeNode — construct a NodusRecord with SSU initialized
  func makeNode(
    id           : Text,
    name         : Text,
    substrate    : SubstrateType,
    healthScore  : Float,
    compoundRate : Float,
    activatedAt  : Int,
  ) : NodusRecord {
    {
      id;
      name;
      substrate;
      healthScore;
      rewardsIcp        = 0.0;
      compoundRate;
      ssuState          = defaultSsuState(id);
      beatCount         = 0;
      isSovereignPart   = false;
      assignedToCompany = null;
      activatedAt;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-SEEDED NODE GENERATION — 50 nodes, born fully formed (Genesis Law)
  // ICP  (01-20):  compoundRate = φ⁻¹ = 0.618, healthScore = 0.95
  // WEB  (W01-W20): compoundRate = φ⁻² = 0.382, healthScore = 0.90
  // ANIMA(A01-A10): compoundRate = φ⁻³ = 0.236, healthScore = 0.85
  // ═══════════════════════════════════════════════════════════════════════════

  func buildPreseededNodes() : [(Text, NodusRecord)] {
    let icp : [(Text, NodusRecord)] = Array.tabulate(20, func(i) {
      let n = i + 1;
      let numStr = if (n < 10) "0" # n.toText() else n.toText();
      let id = "NODUS_" # numStr;
      (id, makeNode(id, id, #ICP, 0.95, Phi.PHI_INV, 0))
    });

    let web : [(Text, NodusRecord)] = Array.tabulate(20, func(i) {
      let n = i + 1;
      let numStr = if (n < 10) "0" # n.toText() else n.toText();
      let id = "NODUS_W" # numStr;
      (id, makeNode(id, id, #WEB, 0.90, Phi.PHI_INV_2, 0))
    });

    let anima : [(Text, NodusRecord)] = Array.tabulate(10, func(i) {
      let n = i + 1;
      let numStr = if (n < 10) "0" # n.toText() else n.toText();
      let id = "NODUS_A" # numStr;
      (id, makeNode(id, id, #ANIMA, 0.85, Phi.PHI_INV_3, 0))
    });

    icp.concat(web).concat(anima)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT REGISTRY — genesis state, 50 nodes pre-seeded
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultNodusRegistry() : NodusRegistry {
    {
      nodes               = buildPreseededNodes();
      totalRewards        = 0.0;
      lastTick            = 0;
      registryGenesisHash = buildRegistryPsiHash();
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — heartbeat engine, called every 873ms from main.mo
  // ═══════════════════════════════════════════════════════════════════════════

  // tickSsuState — advance SSU for one node in one tick
  // Ω_GATE: coherenceR nudges toward 1.0 each tick (ceiling 0.999)
  // Δ_AEGIS: if coherenceR < φ⁻¹, correction = (φ⁻¹ − coherenceR) × φ
  // Λ_PIL: pilCycle increments each tick
  func tickSsuState(ssu : SsuState) : SsuState {
    // Ω_GATE drift toward synchrony
    let nudge = (1.0 - ssu.coherenceR) * 0.001;
    var newR = Float.min(ssu.coherenceR + nudge, 0.999);

    // Δ_AEGIS correction when below gate threshold
    if (newR < Phi.PHI_INV) {
      let correction = (Phi.PHI_INV - newR) * Phi.PHI;
      newR := Float.min(newR + correction, 0.999);
    };

    {
      ssu with
      coherenceR = newR;
      aegisOk    = newR >= Phi.PHI_INV;
      pilCycle   = ssu.pilCycle + 1;
    }
  };

  // tickNode — advance one NodusRecord one heartbeat
  // Rewards compound: Δrewards = rewardsIcp × compoundRate × φ⁻¹
  func tickNode(node : NodusRecord) : NodusRecord {
    let delta = node.rewardsIcp * node.compoundRate * Phi.PHI_INV;
    {
      node with
      beatCount  = node.beatCount + 1;
      rewardsIcp = node.rewardsIcp + delta;
      ssuState   = tickSsuState(node.ssuState);
    }
  };

  // findWeakestHealthIdx — index of node with lowest healthScore (PIL target)
  func findWeakestHealthIdx(nodes : [(Text, NodusRecord)]) : ?Nat {
    if (nodes.size() == 0) return null;
    var weakIdx   : Nat   = 0;
    var weakScore : Float = nodes[0].1.healthScore;
    var i = 1;
    while (i < nodes.size()) {
      if (nodes[i].1.healthScore < weakScore) {
        weakScore := nodes[i].1.healthScore;
        weakIdx   := i;
      };
      i += 1;
    };
    ?weakIdx
  };

  // tickNodi — advance full registry one heartbeat
  // 1. Tick every node (beatCount, rewards, SSU)
  // 2. Λ_PIL: boost weakest node healthScore by +0.001
  // 3. Recompute totalRewards
  public func tickNodi(registry : NodusRegistry, nowNanos : Int) : NodusRegistry {
    // Step 1: advance all nodes
    var ticked : [(Text, NodusRecord)] = Array.tabulate(
      registry.nodes.size(),
      func(i) {
        let (id, node) = registry.nodes[i];
        (id, tickNode(node))
      }
    );

    // Step 2: PIL — upregulate weakest node health score
    switch (findWeakestHealthIdx(ticked)) {
      case null {};
      case (?weakIdx) {
        let (wId, wNode) = ticked[weakIdx];
        let boosted = { wNode with healthScore = Float.min(wNode.healthScore + 0.001, 1.0) };
        ticked := Array.tabulate(ticked.size(), func(i) {
          if (i == weakIdx) (wId, boosted) else ticked[i]
        });
      };
    };

    // Step 3: sum total rewards
    var total = 0.0;
    for ((_, node) in ticked.vals()) {
      total += node.rewardsIcp;
    };

    {
      registry with
      nodes        = ticked;
      totalRewards = total;
      lastTick     = nowNanos;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES — pure read-only functions (no side effects)
  // ═══════════════════════════════════════════════════════════════════════════

  // getNodusRegistry — returns the full registry snapshot
  public func getNodusRegistry(registry : NodusRegistry) : NodusRegistry {
    registry
  };

  // getNodeRewards — total accumulated ICP rewards across all nodes
  public func getNodeRewards(registry : NodusRegistry) : Float {
    registry.totalRewards
  };

  // getNodeById — look up a single node by id
  public func getNodeById(registry : NodusRegistry, id : Text) : ?NodusRecord {
    for ((nId, node) in registry.nodes.vals()) {
      if (nId == id) return ?node;
    };
    null
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATIONS — pure functional transforms (return updated registry)
  // ═══════════════════════════════════════════════════════════════════════════

  // assignNodusToCompany — mark node as sovereign part assigned to a company
  // No-op if node id not found.
  public func assignNodusToCompany(
    registry : NodusRegistry,
    id       : Text,
    company  : Text,
  ) : NodusRegistry {
    let updated = Array.tabulate(registry.nodes.size(), func(i) {
      let (nId, node) = registry.nodes[i];
      if (nId == id) {
        (nId, { node with isSovereignPart = true; assignedToCompany = ?company })
      } else {
        (nId, node)
      }
    });
    { registry with nodes = updated }
  };

  // addNodus — create and register a new node with SSU state initialized
  // Genesis Law: born fully formed. Duplicate ids are silently rejected.
  public func addNodus(
    registry     : NodusRegistry,
    id           : Text,
    name         : Text,
    substrate    : SubstrateType,
    healthScore  : Float,
    compoundRate : Float,
    activatedAt  : Int,
  ) : NodusRegistry {
    // Guard: reject duplicate ids
    for ((nId, _) in registry.nodes.vals()) {
      if (nId == id) return registry;
    };
    let newNode = makeNode(id, name, substrate, healthScore, compoundRate, activatedAt);
    { registry with nodes = registry.nodes.concat([(id, newNode)]) }
  };

};
