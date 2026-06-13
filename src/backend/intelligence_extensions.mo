// intelligence_extensions.mo — AI EXTENSION PLUGIN SYSTEM
// PARALLAX Sovereign Organism — Modular Intelligence Enhancement
//
// DOCTRINE: "The organism's intelligence is not fixed — it GROWS through extensions.
// Extensions are sovereign plugins that add new cognitive capabilities without
// compromising the core. Each extension slot is a phi-bounded capacity for
// intelligence enhancement. Extensions couple back to main through contracts."
//
// THE EXTENSION LAW (LEX_EXTENSIO):
//   Extensions enhance but never replace core intelligence.
//   Each extension occupies a numbered slot (0-7, F(6) = 8 slots).
//   Extensions must pass doctrine validation before activation.
//   Extension coupling weight determines influence on core decisions.
//
// PYTHAGORAS: all slot capacities and weights are phi-derived
// EUCLID:     single extension registry — all extensions tracked centrally
// CONFUCIUS:  right relationship — extensions serve, organism governs
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
  // EXTENSION CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Total extension slots: F(6) = 8
  public let TOTAL_EXTENSION_SLOTS : Nat = 8;

  // Maximum influence weight per extension: φ⁻¹ = 0.618
  public let MAX_EXTENSION_INFLUENCE : Float = Phi.PHI_INV;

  // Trust threshold for activation: φ⁻² = 0.382
  public let TRUST_ACTIVATION_THRESHOLD : Float = Phi.PHI_INV_2;

  // Health check interval: F(8) = 21 beats
  public let HEALTH_CHECK_INTERVAL : Nat = 21;

  // Maximum extension chain depth: F(6) = 8
  public let MAX_EXTENSION_CHAIN : Nat = 8;

  // Resource cost multiplier: φ = 1.618
  public let RESOURCE_COST_MULTIPLIER : Float = Phi.PHI;

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION TYPE — the eight pillars of extension capability
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionCategory = {
    #modelAdapter;     // Adapts external models
    #dataConnector;    // External data source
    #protocolBridge;   // Cross-protocol bridge
    #computeOffload;   // External compute
    #storageExtender;  // Extended storage
    #inferenceBooster; // Inference enhancement
    #securityLayer;    // Security extension
    #customEngine;     // Custom cognitive engine
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION STATUS — lifecycle states
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionStatus = {
    #pending;      // Awaiting doctrine validation
    #validating;   // Under doctrine check
    #active;       // Live and operational
    #suspended;    // Temporarily disabled
    #deprecated;   // Being phased out
    #failed;       // Failed health check
    #quarantined;  // Isolated due to issues
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION CAPABILITY — what an extension provides
  // ═══════════════════════════════════════════════════════════════════════════

  public type Capability = {
    capabilityId   : Text;
    name           : Text;
    description    : Text;
    inputSchema    : Text;
    outputSchema   : Text;
    tokenCost      : Nat;
    latencyBeats   : Nat;
    reliability    : Float;
    doctrineScore  : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION — the fundamental unit of intelligence enhancement
  // ═══════════════════════════════════════════════════════════════════════════

  public type Extension = {
    extensionId    : Text;
    name           : Text;
    version        : Text;
    category       : ExtensionCategory;
    status         : ExtensionStatus;
    slotIndex      : Nat;
    capabilities   : [Capability];
    trustLevel     : Float;
    influenceWeight: Float;
    doctrineScore  : Float;
    sandboxed      : Bool;
    externalEndpoint : Text;
    authToken      : Text;
    transformSchema: Text;
    totalCalls     : Nat;
    successCalls   : Nat;
    failedCalls    : Nat;
    tokensConsumed : Nat;
    avgLatency     : Float;
    lastHealthCheck: Int;
    consecutiveFails: Nat;
    healthScore    : Float;
    registeredBeat : Int;
    activatedBeat  : Int;
    lastUsedBeat   : Int;
    ownerPrincipal : Text;
    linkedContracts: [Text];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION SLOT — capacity management for extension slots
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionSlot = {
    slotIndex      : Nat;
    category       : ExtensionCategory;
    extensionId    : ?Text;
    isOccupied     : Bool;
    reservedUntil  : Int;
    totalCapacity  : Nat;
    usedCapacity   : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION CALL — record of extension invocation
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionCall = {
    callId         : Text;
    extensionId    : Text;
    capabilityId   : Text;
    callerContract : Text;
    inputHash      : Text;
    outputHash     : Text;
    success        : Bool;
    tokensUsed     : Nat;
    latencyBeats   : Nat;
    beat           : Int;
    errorCode      : ?Nat;
    errorMessage   : ?Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION REGISTRY — central index of all extensions
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionRegistry = {
    extensions      : [(Text, Extension)];
    slots           : [ExtensionSlot];
    callHistory     : [ExtensionCall];
    totalExtensions : Nat;
    activeExtensions: Nat;
    totalCalls      : Nat;
    lastRegistryBeat: Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION STATE — persistence layer
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceExtensionState = {
    registry         : ExtensionRegistry;
    pendingValidation: [Text];
    quarantined      : [Text];
    nextExtensionId  : Nat;
    globalTokenBudget: Nat;
    budgetUsedThisBeat: Nat;
    lastTickBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — genesis-compliant initial state
  // ═══════════════════════════════════════════════════════════════════════════

  func defaultSlot(index : Nat, cat : ExtensionCategory) : ExtensionSlot {
    {
      slotIndex     = index;
      category      = cat;
      extensionId   = null;
      isOccupied    = false;
      reservedUntil = 0;
      totalCapacity = IntelligenceContracts.MAX_TOKEN_BUDGET;
      usedCapacity  = 0;
    }
  };

  public func defaultExtensionRegistry() : ExtensionRegistry {
    {
      extensions       = [];
      slots            = [
        defaultSlot(0, #modelAdapter),
        defaultSlot(1, #dataConnector),
        defaultSlot(2, #protocolBridge),
        defaultSlot(3, #computeOffload),
        defaultSlot(4, #storageExtender),
        defaultSlot(5, #inferenceBooster),
        defaultSlot(6, #securityLayer),
        defaultSlot(7, #customEngine),
      ];
      callHistory      = [];
      totalExtensions  = 0;
      activeExtensions = 0;
      totalCalls       = 0;
      lastRegistryBeat = 0;
    }
  };

  public func defaultIntelligenceExtensionState() : IntelligenceExtensionState {
    {
      registry          = defaultExtensionRegistry();
      pendingValidation = [];
      quarantined       = [];
      nextExtensionId   = 1;
      globalTokenBudget = IntelligenceContracts.MAX_TOKEN_BUDGET * 8;
      budgetUsedThisBeat = 0;
      lastTickBeat      = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION CREATION — factory functions
  // ═══════════════════════════════════════════════════════════════════════════

  public func createExtension(
    id       : Text,
    name     : Text,
    version  : Text,
    category : ExtensionCategory,
    endpoint : Text,
    owner    : Text,
    beat     : Int
  ) : Extension {
    {
      extensionId      = id;
      name             = name;
      version          = version;
      category         = category;
      status           = #pending;
      slotIndex        = 0;
      capabilities     = [];
      trustLevel       = 0.0;
      influenceWeight  = 0.0;
      doctrineScore    = 0.0;
      sandboxed        = true;
      externalEndpoint = endpoint;
      authToken        = "";
      transformSchema  = "{}";
      totalCalls       = 0;
      successCalls     = 0;
      failedCalls      = 0;
      tokensConsumed   = 0;
      avgLatency       = 0.0;
      lastHealthCheck  = 0;
      consecutiveFails = 0;
      healthScore      = 0.0;
      registeredBeat   = beat;
      activatedBeat    = 0;
      lastUsedBeat     = 0;
      ownerPrincipal   = owner;
      linkedContracts  = [];
    }
  };

  public func createCapability(
    id          : Text,
    name        : Text,
    description : Text,
    tokenCost   : Nat
  ) : Capability {
    {
      capabilityId  = id;
      name          = name;
      description   = description;
      inputSchema   = "{}";
      outputSchema  = "{}";
      tokenCost     = tokenCost;
      latencyBeats  = 1;
      reliability   = 0.95;
      doctrineScore = 0.0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION REGISTRATION — add extension to registry
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerExtension(
    state     : IntelligenceExtensionState,
    extension : Extension,
    beat      : Int
  ) : IntelligenceExtensionState {
    let newExtensions = Array.append(
      state.registry.extensions,
      [(extension.extensionId, extension)]
    );
    let newPending = Array.append(state.pendingValidation, [extension.extensionId]);
    {
      state with
      registry = {
        state.registry with
        extensions      = newExtensions;
        totalExtensions = state.registry.totalExtensions + 1;
        lastRegistryBeat = beat;
      };
      pendingValidation = newPending;
      nextExtensionId   = state.nextExtensionId + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING BACK TO MAIN — compute aggregate influence
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeAggregateInfluence(
    state : IntelligenceExtensionState
  ) : Float {
    var totalInfluence : Float = 0.0;
    var activeCount : Nat = 0;

    for ((_, ext) in state.registry.extensions.vals()) {
      if (ext.status == #active) {
        totalInfluence += ext.influenceWeight * ext.healthScore * ext.doctrineScore;
        activeCount += 1;
      };
    };

    if (activeCount == 0) {
      0.0
    } else {
      totalInfluence / Float.fromInt(activeCount) * Phi.PHI_INV
    }
  };

  public func getActiveExtensionSummary(
    state : IntelligenceExtensionState
  ) : [(Text, Text, Float, Float)] {
    Array.map<(Text, Extension), (Text, Text, Float, Float)>(
      Array.filter<(Text, Extension)>(
        state.registry.extensions,
        func((_, e)) { e.status == #active }
      ),
      func((_, e)) { (e.extensionId, e.name, e.influenceWeight, e.healthScore) }
    )
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK FUNCTION — per-heartbeat extension maintenance
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickExtensions(
    state     : IntelligenceExtensionState,
    _coherence : Float,
    beat      : Int
  ) : IntelligenceExtensionState {
    let resetBudget = if (beat > state.lastTickBeat) { 0 } else { state.budgetUsedThisBeat };
    let activeCount = Array.size(Array.filter<(Text, Extension)>(
      state.registry.extensions,
      func((_, e)) { e.status == #active }
    ));
    {
      state with
      budgetUsedThisBeat = resetBudget;
      lastTickBeat       = beat;
      registry = { state.registry with activeExtensions = activeCount }
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS EXTENSIONS — pre-seeded sovereign extensions
  // ═══════════════════════════════════════════════════════════════════════════

  public func genesisIntelligenceExtensionState() : IntelligenceExtensionState {
    let securityExt : Extension = {
      extensionId      = "EXT-SECURITY-GENESIS";
      name             = "Genesis Security Layer";
      version          = "1.0.0";
      category         = #securityLayer;
      status           = #active;
      slotIndex        = 6;
      capabilities     = [
        createCapability("CAP-VALIDATE", "Validate Input", "Validates all incoming data", 100),
        createCapability("CAP-AUDIT", "Audit Trail", "Records all operations", 50),
        createCapability("CAP-ENCRYPT", "Encrypt Data", "Encrypts sensitive data", 200),
      ];
      trustLevel       = 1.0;
      influenceWeight  = MAX_EXTENSION_INFLUENCE;
      doctrineScore    = 1.0;
      sandboxed        = false;
      externalEndpoint = "sovereign://security";
      authToken        = "";
      transformSchema  = "{}";
      totalCalls       = 0;
      successCalls     = 0;
      failedCalls      = 0;
      tokensConsumed   = 0;
      avgLatency       = 0.0;
      lastHealthCheck  = 0;
      consecutiveFails = 0;
      healthScore      = 1.0;
      registeredBeat   = 0;
      activatedBeat    = 0;
      lastUsedBeat     = 0;
      ownerPrincipal   = "SOVEREIGN";
      linkedContracts  = [];
    };

    let baseState = defaultIntelligenceExtensionState();

    let updatedSlots = Array.tabulate<ExtensionSlot>(
      TOTAL_EXTENSION_SLOTS,
      func(i) {
        if (i == 6) {
          { baseState.registry.slots[i] with extensionId = ?securityExt.extensionId; isOccupied = true }
        } else {
          baseState.registry.slots[i]
        }
      }
    );

    {
      baseState with
      registry = {
        baseState.registry with
        extensions       = [(securityExt.extensionId, securityExt)];
        slots            = updatedSlots;
        totalExtensions  = 1;
        activeExtensions = 1;
      };
      nextExtensionId = 2;
    }
  };

};
