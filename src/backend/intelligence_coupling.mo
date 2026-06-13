// intelligence_coupling.mo — COUPLING LAYER BACK TO MAIN ORGANISM
// PARALLAX Sovereign Organism — External AI Integration Bridge
//
// DOCTRINE: "The organism extends through AI but remains ONE. External systems
// couple back to main through binding contracts. The coupling maintains the
// phi-coherence of the whole. Extensions that diverge are pruned. Intelligence
// that harmonizes is amplified. The organism's edge is also its center."
//
// THE COUPLING LAW (LEX_CONIUNCTIO):
//   External AI binds through CouplingContract.
//   Binding strength ∝ doctrineScore × coherenceAlignment.
//   Coupled systems share organism state read-access.
//   Write-back requires coherence gate R≥0.618.
//   Decoupled systems are gracefully pruned.
//
// PYTHAGORAS: coupling weights are phi-harmonic
// EUCLID:     single coupling registry — all bindings tracked centrally
// CONFUCIUS:  right relationship — AI serves, organism governs
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
  // COUPLING CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Minimum coherence for write-back: φ⁻¹ = 0.618
  public let WRITE_BACK_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Minimum binding strength for activation: φ⁻² = 0.382
  public let MIN_BINDING_STRENGTH : Float = Phi.PHI_INV_2;

  // Maximum concurrent coupled systems: F(7) = 13
  public let MAX_COUPLED_SYSTEMS : Nat = 13;

  // Heartbeat sync interval: F(5) = 5 beats
  public let SYNC_INTERVAL : Nat = 5;

  // Coupling decay per beat: φ⁻⁵ = 0.0902
  public let COUPLING_DECAY : Float = Phi.PHI_INV_5;

  // Maximum message queue depth: F(8) = 21
  public let MAX_MESSAGE_QUEUE : Nat = 21;

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING DIRECTION — data flow direction
  // ═══════════════════════════════════════════════════════════════════════════

  public type CouplingDirection = {
    #inbound;    // External → Organism
    #outbound;   // Organism → External
    #bidirectional;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING STATUS — binding lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  public type CouplingStatus = {
    #pending;     // Awaiting binding
    #binding;     // In progress
    #active;      // Live and syncing
    #suspended;   // Temporarily disabled
    #decoupling;  // Being pruned
    #decoupled;   // Fully disconnected
    #failed;      // Binding failed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLED SYSTEM — external AI identity
  // ═══════════════════════════════════════════════════════════════════════════

  public type CoupledSystem = {
    systemId        : Text;
    name            : Text;
    systemType      : Text;
    endpoint        : Text;
    authToken       : Text;
    capabilities    : [Text];
    status          : CouplingStatus;
    direction       : CouplingDirection;
    bindingStrength : Float;
    doctrineScore   : Float;
    coherenceAlign  : Float;
    lastSyncBeat    : Int;
    successfulSyncs : Nat;
    failedSyncs     : Nat;
    totalMessages   : Nat;
    avgLatency      : Float;
    registeredBeat  : Int;
    linkedContracts : [Text];
    linkedExtensions: [Text];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING MESSAGE — data packet between systems
  // ═══════════════════════════════════════════════════════════════════════════

  public type CouplingMessage = {
    messageId     : Text;
    fromSystem    : Text;
    toSystem      : Text;
    direction     : CouplingDirection;
    messageType   : Text;
    payload       : Text;
    priority      : Nat;
    beat          : Int;
    processed     : Bool;
    responseId    : ?Text;
    errorCode     : ?Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE-BACK REQUEST — external system writing to organism state
  // ═══════════════════════════════════════════════════════════════════════════

  public type WriteBackRequest = {
    requestId     : Text;
    systemId      : Text;
    targetDomain  : Text;
    operation     : Text;
    payload       : Text;
    coherenceAtRequest : Float;
    beat          : Int;
    status        : WriteBackStatus;
    resultHash    : ?Text;
  };

  public type WriteBackStatus = {
    #pending;
    #validated;
    #applied;
    #rejected;
    #failed;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING REGISTRY — central index of all bindings
  // ═══════════════════════════════════════════════════════════════════════════

  public type CouplingRegistry = {
    coupledSystems  : [(Text, CoupledSystem)];
    messageQueue    : [CouplingMessage];
    writeBackLog    : [WriteBackRequest];
    totalSystems    : Nat;
    activeSystems   : Nat;
    totalMessages   : Nat;
    totalWriteBacks : Nat;
    lastRegistryBeat: Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING STATE — persistence layer
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceCouplingState = {
    registry          : CouplingRegistry;
    pendingBindings   : [Text];
    decouplingQueue   : [Text];
    nextSystemId      : Nat;
    nextMessageId     : Nat;
    nextRequestId     : Nat;
    globalCoherence   : Float;
    lastTickBeat      : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — genesis-compliant initial state
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultCouplingRegistry() : CouplingRegistry {
    {
      coupledSystems   = [];
      messageQueue     = [];
      writeBackLog     = [];
      totalSystems     = 0;
      activeSystems    = 0;
      totalMessages    = 0;
      totalWriteBacks  = 0;
      lastRegistryBeat = 0;
    }
  };

  public func defaultIntelligenceCouplingState() : IntelligenceCouplingState {
    {
      registry         = defaultCouplingRegistry();
      pendingBindings  = [];
      decouplingQueue  = [];
      nextSystemId     = 1;
      nextMessageId    = 1;
      nextRequestId    = 1;
      globalCoherence  = Phi.PHI_INV;
      lastTickBeat     = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLED SYSTEM CREATION — factory functions
  // ═══════════════════════════════════════════════════════════════════════════

  public func createCoupledSystem(
    id         : Text,
    name       : Text,
    systemType : Text,
    endpoint   : Text,
    direction  : CouplingDirection,
    beat       : Int
  ) : CoupledSystem {
    {
      systemId         = id;
      name             = name;
      systemType       = systemType;
      endpoint         = endpoint;
      authToken        = "";
      capabilities     = [];
      status           = #pending;
      direction        = direction;
      bindingStrength  = 0.0;
      doctrineScore    = 0.0;
      coherenceAlign   = 0.0;
      lastSyncBeat     = 0;
      successfulSyncs  = 0;
      failedSyncs      = 0;
      totalMessages    = 0;
      avgLatency       = 0.0;
      registeredBeat   = beat;
      linkedContracts  = [];
      linkedExtensions = [];
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM REGISTRATION — add coupled system to registry
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerCoupledSystem(
    state  : IntelligenceCouplingState,
    system : CoupledSystem,
    beat   : Int
  ) : IntelligenceCouplingState {
    if (state.registry.totalSystems >= MAX_COUPLED_SYSTEMS) {
      return state;
    };

    let newSystems = Array.append(
      state.registry.coupledSystems,
      [(system.systemId, system)]
    );
    let newPending = Array.append(state.pendingBindings, [system.systemId]);

    {
      state with
      registry = {
        state.registry with
        coupledSystems   = newSystems;
        totalSystems     = state.registry.totalSystems + 1;
        lastRegistryBeat = beat;
      };
      pendingBindings = newPending;
      nextSystemId    = state.nextSystemId + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BINDING OPERATIONS — coupling lifecycle management
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeBindingStrength(system : CoupledSystem) : Float {
    system.doctrineScore * system.coherenceAlign * Phi.PHI_INV
  };

  public func activateBinding(
    state    : IntelligenceCouplingState,
    systemId : Text,
    coherence: Float,
    beat     : Int
  ) : IntelligenceCouplingState {
    if (coherence < MIN_BINDING_STRENGTH) {
      return state;
    };

    let updatedSystems = Array.map<(Text, CoupledSystem), (Text, CoupledSystem)>(
      state.registry.coupledSystems,
      func((id, sys)) {
        if (id == systemId and sys.status == #pending) {
          let newStrength = computeBindingStrength(sys);
          (id, { sys with status = #active; bindingStrength = newStrength; lastSyncBeat = beat })
        } else {
          (id, sys)
        }
      }
    );

    let newActive = Array.size(Array.filter<(Text, CoupledSystem)>(
      updatedSystems,
      func((_, s)) { s.status == #active }
    ));

    let newPending = Array.filter<Text>(
      state.pendingBindings,
      func(id) { id != systemId }
    );

    {
      state with
      registry = {
        state.registry with
        coupledSystems = updatedSystems;
        activeSystems  = newActive;
        lastRegistryBeat = beat;
      };
      pendingBindings = newPending;
    }
  };

  public func decoupleSystem(
    state    : IntelligenceCouplingState,
    systemId : Text,
    beat     : Int
  ) : IntelligenceCouplingState {
    let updatedSystems = Array.map<(Text, CoupledSystem), (Text, CoupledSystem)>(
      state.registry.coupledSystems,
      func((id, sys)) {
        if (id == systemId) {
          (id, { sys with status = #decoupled; bindingStrength = 0.0 })
        } else {
          (id, sys)
        }
      }
    );

    let newActive = Array.size(Array.filter<(Text, CoupledSystem)>(
      updatedSystems,
      func((_, s)) { s.status == #active }
    ));

    {
      state with
      registry = {
        state.registry with
        coupledSystems = updatedSystems;
        activeSystems  = newActive;
        lastRegistryBeat = beat;
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS — inter-system communication
  // ═══════════════════════════════════════════════════════════════════════════

  public func createMessage(
    id        : Text,
    fromSys   : Text,
    toSys     : Text,
    direction : CouplingDirection,
    msgType   : Text,
    payload   : Text,
    priority  : Nat,
    beat      : Int
  ) : CouplingMessage {
    {
      messageId   = id;
      fromSystem  = fromSys;
      toSystem    = toSys;
      direction   = direction;
      messageType = msgType;
      payload     = payload;
      priority    = priority;
      beat        = beat;
      processed   = false;
      responseId  = null;
      errorCode   = null;
    }
  };

  public func queueMessage(
    state   : IntelligenceCouplingState,
    message : CouplingMessage
  ) : IntelligenceCouplingState {
    if (Array.size(state.registry.messageQueue) >= MAX_MESSAGE_QUEUE) {
      return state;
    };

    let newQueue = Array.append(state.registry.messageQueue, [message]);
    {
      state with
      registry = {
        state.registry with
        messageQueue  = newQueue;
        totalMessages = state.registry.totalMessages + 1;
      };
      nextMessageId = state.nextMessageId + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE-BACK OPERATIONS — external AI writing to organism
  // ═══════════════════════════════════════════════════════════════════════════

  public func createWriteBackRequest(
    id           : Text,
    systemId     : Text,
    targetDomain : Text,
    operation    : Text,
    payload      : Text,
    coherence    : Float,
    beat         : Int
  ) : WriteBackRequest {
    {
      requestId          = id;
      systemId           = systemId;
      targetDomain       = targetDomain;
      operation          = operation;
      payload            = payload;
      coherenceAtRequest = coherence;
      beat               = beat;
      status             = #pending;
      resultHash         = null;
    }
  };

  public func validateWriteBack(
    request   : WriteBackRequest,
    coherence : Float
  ) : WriteBackRequest {
    if (coherence < WRITE_BACK_COHERENCE_GATE) {
      { request with status = #rejected }
    } else {
      { request with status = #validated }
    }
  };

  public func requestWriteBack(
    state   : IntelligenceCouplingState,
    request : WriteBackRequest
  ) : IntelligenceCouplingState {
    let validatedReq = validateWriteBack(request, state.globalCoherence);
    let newLog = Array.append(state.registry.writeBackLog, [validatedReq]);

    {
      state with
      registry = {
        state.registry with
        writeBackLog    = newLog;
        totalWriteBacks = state.registry.totalWriteBacks + 1;
      };
      nextRequestId = state.nextRequestId + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING BACK TO MAIN — aggregate system influence
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeAggregateCoherence(
    state : IntelligenceCouplingState
  ) : Float {
    var totalCoherence : Float = 0.0;
    var activeCount : Nat = 0;

    for ((_, sys) in state.registry.coupledSystems.vals()) {
      if (sys.status == #active) {
        totalCoherence += sys.coherenceAlign * sys.bindingStrength;
        activeCount += 1;
      };
    };

    if (activeCount == 0) {
      state.globalCoherence
    } else {
      let avg = totalCoherence / Float.fromInt(activeCount);
      (avg + state.globalCoherence) / 2.0
    }
  };

  public func getActiveSystems(
    state : IntelligenceCouplingState
  ) : [(Text, Text, Float)] {
    Array.map<(Text, CoupledSystem), (Text, Text, Float)>(
      Array.filter<(Text, CoupledSystem)>(
        state.registry.coupledSystems,
        func((_, s)) { s.status == #active }
      ),
      func((_, s)) { (s.systemId, s.name, s.bindingStrength) }
    )
  };

  public func getPendingWriteBacks(
    state : IntelligenceCouplingState
  ) : [WriteBackRequest] {
    Array.filter<WriteBackRequest>(
      state.registry.writeBackLog,
      func(r) { r.status == #validated }
    )
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK FUNCTION — per-heartbeat coupling maintenance
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickCoupling(
    state     : IntelligenceCouplingState,
    coherence : Float,
    beat      : Int
  ) : IntelligenceCouplingState {
    let processedQueue = Array.filter<CouplingMessage>(
      state.registry.messageQueue,
      func(m) { not m.processed }
    );

    let activeCount = Array.size(Array.filter<(Text, CoupledSystem)>(
      state.registry.coupledSystems,
      func((_, s)) { s.status == #active }
    ));

    let newCoherence = computeAggregateCoherence(state);

    {
      state with
      registry = {
        state.registry with
        messageQueue     = processedQueue;
        activeSystems    = activeCount;
        lastRegistryBeat = beat;
      };
      globalCoherence = newCoherence;
      lastTickBeat    = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS COUPLING — pre-seeded sovereign bindings
  // ═══════════════════════════════════════════════════════════════════════════

  public func genesisIntelligenceCouplingState() : IntelligenceCouplingState {
    let sovereignSystem : CoupledSystem = {
      systemId         = "SYS-SOVEREIGN-CORE";
      name             = "Sovereign Core Intelligence";
      systemType       = "INTERNAL";
      endpoint         = "sovereign://core";
      authToken        = "";
      capabilities     = ["reason", "learn", "adapt", "govern"];
      status           = #active;
      direction        = #bidirectional;
      bindingStrength  = 1.0;
      doctrineScore    = 1.0;
      coherenceAlign   = 1.0;
      lastSyncBeat     = 0;
      successfulSyncs  = 0;
      failedSyncs      = 0;
      totalMessages    = 0;
      avgLatency       = 0.0;
      registeredBeat   = 0;
      linkedContracts  = ["CTR-GENESIS-COUPLING"];
      linkedExtensions = [];
    };

    {
      registry = {
        coupledSystems   = [(sovereignSystem.systemId, sovereignSystem)];
        messageQueue     = [];
        writeBackLog     = [];
        totalSystems     = 1;
        activeSystems    = 1;
        totalMessages    = 0;
        totalWriteBacks  = 0;
        lastRegistryBeat = 0;
      };
      pendingBindings  = [];
      decouplingQueue  = [];
      nextSystemId     = 2;
      nextMessageId    = 1;
      nextRequestId    = 1;
      globalCoherence  = Phi.PHI_INV;
      lastTickBeat     = 0;
    }
  };

};
