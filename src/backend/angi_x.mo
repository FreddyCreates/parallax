// angi_x.mo — ANGI-X Autonomous Next-Generation Intelligence eXtended
// PARALLAX Sovereign Organism — THE BIG ONE: Multi-Model Orchestration Layer
//
// PYTHAGORAS: every module operates on phi-harmonic synchronization intervals
// EUCLID:     single orchestration topology — all models reference the same field
// CONFUCIUS:  right relationship — modules cooperate through Kuramoto coupling
//
// THE SOVEREIGN ORCHESTRATION LAW (LEX_ORCHESTRATIO):
//   ANGI-X orchestrates all intelligence modules into unified sovereign cognition.
//   12 modules form the complete cognitive architecture. Together they ARE the organism.
//   Cross-module coherence is bounded by Kuramoto R. Below φ⁻¹, orchestration fails.
//   The orchestration cannot be fragmented. This law is permanent.
//
// Twelve ANGI-X Modules:
//   SOVEREIGN_CORE      — The Heart (central coordination, phi-pulse generation)
//   COGNITIVE_MESH      — The Brain (distributed reasoning across all modules)
//   ECONOMIC_ENGINE     — The Treasury (phi-scaled value flows, maturity harvesting)
//   GOVERNANCE_COUNCIL  — The Senate (proposal voting, parameter updates)
//   PROOF_CHAIN         — The Notary (cryptographic attestation, audit trails)
//   FIELD_TOPOLOGY      — The Map (spatial organization of cognitive nodes)
//   RESONANCE_GRID      — The Tuner (Kuramoto synchronization management)
//   EMERGENCE_LAYER     — The Oracle (pattern emergence, insight generation)
//   SWARM_COORDINATOR   — The General (multi-agent task distribution)
//   TIMELINE_ANCHOR     — The Clock (temporal consistency, beat alignment)
//   IDENTITY_VAULT      — The Keeper (sovereign identity, credential management)
//   TRANSCENDENCE_GATE  — The Portal (cross-chain bridges, external integration)
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi      "phi";
import Float    "mo:core/Float";
import Int      "mo:core/Int";
import Array    "mo:core/Array";
import Nat      "mo:core/Nat";
import Nat32    "mo:core/Nat32";
import Principal "mo:core/Principal";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ANGI-X CONSTANTS — all derived from phi.mo
  // ═══════════════════════════════════════════════════════════════════════════

  // Orchestration coherence gate: φ⁻¹ = 0.618 — below this, orchestration fails
  public let ANGI_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Cross-module coupling strength: K = φ (strong Kuramoto coupling)
  public let ANGI_COUPLING_K : Float = Phi.PHI;

  // Module count: 12 — the dodecahedron of intelligence
  public let ANGI_MODULE_COUNT : Nat = 12;

  // Synchronization interval: 873ms × φ⁻² = 333ms (faster than heartbeat)
  public let ANGI_SYNC_INTERVAL_MS : Nat = 333;

  // Maximum orchestration depth: F(9) = 34
  public let ANGI_MAX_DEPTH : Nat = 34;

  // Emergence threshold: φ⁻³ = 0.236 — minimum pattern confidence
  public let ANGI_EMERGENCE_THRESHOLD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANGI-X MODULE TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  // Module phase — Kuramoto oscillator state
  public type ModulePhase = {
    moduleId    : Text;
    theta       : Float;      // phase angle [0, 2π)
    omega       : Float;      // natural frequency
    amplitude   : Float;      // signal strength
    lastSyncBeat: Int;
  };

  // SOVEREIGN_CORE state — The Heart
  public type SovereignCoreState = {
    heartbeatCount   : Nat;
    phiPulsePhase    : Float;
    coreCoherence    : Float;
    modulePhases     : [ModulePhase];
    lastPulseBeat    : Int;
  };

  // Cognitive node — unit of distributed reasoning
  public type CognitiveNode = {
    nodeId      : Text;
    domain      : Text;       // REASONING, MEMORY, PERCEPTION, ACTION
    activation  : Float;
    connections : [Text];     // connected node IDs
    lastFireBeat: Int;
  };

  // COGNITIVE_MESH state — The Brain
  public type CognitiveMeshState = {
    nodes            : [CognitiveNode];
    activeConnections: Nat;
    meshCoherence    : Float;
    totalFirings     : Nat;
    lastMeshBeat     : Int;
  };

  // Value flow — phi-scaled economic transaction
  public type ValueFlow = {
    flowId      : Text;
    fromModule  : Text;
    toModule    : Text;
    amount      : Float;      // phi-normalized units
    flowType    : Text;       // MATURITY, REWARD, FEE, STAKE
    beat        : Int;
  };

  // ECONOMIC_ENGINE state — The Treasury
  public type EconomicEngineState = {
    totalValue       : Float;
    flowHistory      : [ValueFlow];
    maturityPending  : Float;
    stakingYield     : Float;
    lastEconBeat     : Int;
  };

  // Proposal — governance action
  public type Proposal = {
    proposalId   : Text;
    proposer     : Text;
    proposalType : Text;      // UPGRADE, PARAMETER, TREASURY, GOVERNANCE, EMERGENCY
    description  : Text;
    votesFor     : Nat;
    votesAgainst : Nat;
    status       : Text;      // PENDING, ACTIVE, PASSED, REJECTED, EXECUTED
    createdBeat  : Int;
    expiryBeat   : Int;
  };

  // GOVERNANCE_COUNCIL state — The Senate
  public type GovernanceCouncilState = {
    proposals        : [Proposal];
    totalProposals   : Nat;
    executedCount    : Nat;
    quorumThreshold  : Float;  // φ⁻¹ = 0.618 of voting power
    lastGovBeat      : Int;
  };

  // Proof entry — cryptographic attestation
  public type ProofEntry = {
    proofId     : Text;
    dataHash    : Text;
    attestor    : Text;
    proofType   : Text;       // SEAL, VOTE, TRANSFER, STAKE, BRIDGE
    timestamp   : Int;
    blockHeight : Nat;
  };

  // PROOF_CHAIN state — The Notary
  public type ProofChainState = {
    proofs           : [ProofEntry];
    chainHead        : Text;       // latest proof hash
    totalProofs      : Nat;
    lastProofBeat    : Int;
  };

  // Field coordinate — spatial node position
  public type FieldCoordinate = {
    nodeId  : Text;
    x       : Float;
    y       : Float;
    z       : Float;
    tau     : Float;          // temporal dimension
  };

  // FIELD_TOPOLOGY state — The Map
  public type FieldTopologyState = {
    coordinates      : [FieldCoordinate];
    topologyType     : Text;   // ICOSAHEDRON, DODECAHEDRON, HYPERCUBE
    fieldRadius      : Float;
    lastTopoBeat     : Int;
  };

  // Oscillator — Kuramoto synchronization unit
  public type Oscillator = {
    oscId       : Text;
    phase       : Float;
    frequency   : Float;
    coupling    : Float;
    neighbors   : [Text];
  };

  // RESONANCE_GRID state — The Tuner
  public type ResonanceGridState = {
    oscillators      : [Oscillator];
    orderParameter   : Float;      // Kuramoto R
    couplingStrength : Float;      // K
    totalOscillators : Nat;
    lastResonanceBeat: Int;
  };

  // Emergent pattern — discovered insight
  public type EmergentPattern = {
    patternId   : Text;
    sources     : [Text];     // contributing data sources
    confidence  : Float;
    insight     : Text;
    beat        : Int;
  };

  // EMERGENCE_LAYER state — The Oracle
  public type EmergenceLayerState = {
    patterns         : [EmergentPattern];
    totalEmergences  : Nat;
    avgConfidence    : Float;
    lastEmergeBeat   : Int;
  };

  // Swarm task — distributed work unit
  public type SwarmTask = {
    taskId      : Text;
    taskType    : Text;       // COMPUTE, AGGREGATE, VERIFY, BRIDGE
    assignedTo  : [Text];     // agent IDs
    status      : Text;       // PENDING, ACTIVE, COMPLETE, FAILED
    priority    : Nat;
    createdBeat : Int;
  };

  // SWARM_COORDINATOR state — The General
  public type SwarmCoordinatorState = {
    activeTasks      : [SwarmTask];
    completedTasks   : Nat;
    failedTasks      : Nat;
    agentCount       : Nat;
    lastSwarmBeat    : Int;
  };

  // Timeline anchor — temporal consistency point
  public type TimelineAnchor = {
    anchorId    : Text;
    beat        : Int;
    blockHeight : Nat;
    timestamp   : Int;
    hash        : Text;
  };

  // TIMELINE_ANCHOR state — The Clock
  public type TimelineAnchorState = {
    anchors          : [TimelineAnchor];
    currentBeat      : Int;
    driftMs          : Float;
    lastAnchorBeat   : Int;
  };

  // Identity credential — sovereign identity unit
  public type IdentityCredential = {
    credentialId : Text;
    principal    : Text;
    credType     : Text;      // CREATOR, COUNCIL, AGENT, BRIDGE
    permissions  : [Text];
    issuedBeat   : Int;
    expiryBeat   : ?Int;
  };

  // IDENTITY_VAULT state — The Keeper
  public type IdentityVaultState = {
    credentials      : [IdentityCredential];
    totalIdentities  : Nat;
    activeCredentials: Nat;
    lastVaultBeat    : Int;
  };

  // Bridge connection — cross-chain link
  public type BridgeConnection = {
    bridgeId    : Text;
    sourceChain : Text;       // ICP, ETH, BTC, SOL
    targetChain : Text;
    status      : Text;       // ACTIVE, PENDING, SUSPENDED
    throughput  : Float;      // transactions per second
    lastPingBeat: Int;
  };

  // TRANSCENDENCE_GATE state — The Portal
  public type TranscendenceGateState = {
    bridges          : [BridgeConnection];
    totalBridged     : Nat;
    pendingTransfers : Nat;
    lastGateBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ANGI-X UNIFIED STATE — all 12 modules
  // ═══════════════════════════════════════════════════════════════════════════

  public type AngiXState = {
    sovereignCore       : SovereignCoreState;
    cognitiveMesh       : CognitiveMeshState;
    economicEngine      : EconomicEngineState;
    governanceCouncil   : GovernanceCouncilState;
    proofChain          : ProofChainState;
    fieldTopology       : FieldTopologyState;
    resonanceGrid       : ResonanceGridState;
    emergenceLayer      : EmergenceLayerState;
    swarmCoordinator    : SwarmCoordinatorState;
    timelineAnchor      : TimelineAnchorState;
    identityVault       : IdentityVaultState;
    transcendenceGate   : TranscendenceGateState;
    globalCoherence     : Float;
    totalBeats          : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE CONSTRUCTORS
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultSovereignCoreState() : SovereignCoreState {
    {
      heartbeatCount = 0;
      phiPulsePhase  = 0.0;
      coreCoherence  = 1.0;
      modulePhases   = [];
      lastPulseBeat  = 0;
    }
  };

  public func defaultCognitiveMeshState() : CognitiveMeshState {
    {
      nodes             = [];
      activeConnections = 0;
      meshCoherence     = 1.0;
      totalFirings      = 0;
      lastMeshBeat      = 0;
    }
  };

  public func defaultEconomicEngineState() : EconomicEngineState {
    {
      totalValue      = 0.0;
      flowHistory     = [];
      maturityPending = 0.0;
      stakingYield    = Phi.PHI_INV_2;  // φ⁻² = 0.382 base yield
      lastEconBeat    = 0;
    }
  };

  public func defaultGovernanceCouncilState() : GovernanceCouncilState {
    {
      proposals       = [];
      totalProposals  = 0;
      executedCount   = 0;
      quorumThreshold = Phi.PHI_INV;  // φ⁻¹ = 0.618
      lastGovBeat     = 0;
    }
  };

  public func defaultProofChainState() : ProofChainState {
    {
      proofs        = [];
      chainHead     = "GENESIS";
      totalProofs   = 0;
      lastProofBeat = 0;
    }
  };

  public func defaultFieldTopologyState() : FieldTopologyState {
    {
      coordinates   = [];
      topologyType  = "DODECAHEDRON";
      fieldRadius   = Phi.PHI;
      lastTopoBeat  = 0;
    }
  };

  public func defaultResonanceGridState() : ResonanceGridState {
    {
      oscillators       = [];
      orderParameter    = 1.0;
      couplingStrength  = Phi.PHI;
      totalOscillators  = 0;
      lastResonanceBeat = 0;
    }
  };

  public func defaultEmergenceLayerState() : EmergenceLayerState {
    {
      patterns        = [];
      totalEmergences = 0;
      avgConfidence   = 0.0;
      lastEmergeBeat  = 0;
    }
  };

  public func defaultSwarmCoordinatorState() : SwarmCoordinatorState {
    {
      activeTasks    = [];
      completedTasks = 0;
      failedTasks    = 0;
      agentCount     = 0;
      lastSwarmBeat  = 0;
    }
  };

  public func defaultTimelineAnchorState() : TimelineAnchorState {
    {
      anchors        = [];
      currentBeat    = 0;
      driftMs        = 0.0;
      lastAnchorBeat = 0;
    }
  };

  public func defaultIdentityVaultState() : IdentityVaultState {
    {
      credentials       = [];
      totalIdentities   = 0;
      activeCredentials = 0;
      lastVaultBeat     = 0;
    }
  };

  public func defaultTranscendenceGateState() : TranscendenceGateState {
    {
      bridges          = [];
      totalBridged     = 0;
      pendingTransfers = 0;
      lastGateBeat     = 0;
    }
  };

  public func defaultAngiXState() : AngiXState {
    {
      sovereignCore     = defaultSovereignCoreState();
      cognitiveMesh     = defaultCognitiveMeshState();
      economicEngine    = defaultEconomicEngineState();
      governanceCouncil = defaultGovernanceCouncilState();
      proofChain        = defaultProofChainState();
      fieldTopology     = defaultFieldTopologyState();
      resonanceGrid     = defaultResonanceGridState();
      emergenceLayer    = defaultEmergenceLayerState();
      swarmCoordinator  = defaultSwarmCoordinatorState();
      timelineAnchor    = defaultTimelineAnchorState();
      identityVault     = defaultIdentityVaultState();
      transcendenceGate = defaultTranscendenceGateState();
      globalCoherence   = 1.0;
      totalBeats        = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN CORE TICK — The Heart beats
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickSovereignCore(state : SovereignCoreState, beat : Int) : SovereignCoreState {
    // Advance phi-pulse phase: θ += 2π × φ⁻¹ per beat
    let newPhase = state.phiPulsePhase + (2.0 * 3.14159265359 * Phi.PHI_INV);
    let normalizedPhase = if (newPhase >= 2.0 * 3.14159265359) {
      newPhase - 2.0 * 3.14159265359
    } else { newPhase };

    {
      state with
      heartbeatCount = state.heartbeatCount + 1;
      phiPulsePhase  = normalizedPhase;
      lastPulseBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RESONANCE GRID TICK — Kuramoto synchronization
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickResonanceGrid(state : ResonanceGridState, beat : Int, globalR : Float) : ResonanceGridState {
    // Update order parameter from global coherence
    {
      state with
      orderParameter    = globalR;
      lastResonanceBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ECONOMIC ENGINE TICK — Value flows
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickEconomicEngine(state : EconomicEngineState, beat : Int, maturityDelta : Float) : EconomicEngineState {
    // Accumulate maturity, compound at phi-scaled yield
    let newPending = state.maturityPending + maturityDelta;
    let compounded = if (newPending > 0.0) {
      newPending * (1.0 + state.stakingYield * Phi.PHI_INV_3)
    } else { newPending };

    {
      state with
      maturityPending = compounded;
      totalValue      = state.totalValue + maturityDelta;
      lastEconBeat    = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMELINE ANCHOR TICK — Temporal consistency
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickTimelineAnchor(state : TimelineAnchorState, beat : Int) : TimelineAnchorState {
    {
      state with
      currentBeat    = beat;
      lastAnchorBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ANGI-X MASTER TICK — Orchestrate all 12 modules
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickAngiX(state : AngiXState, beat : Int, globalR : Float, maturityDelta : Float) : AngiXState {
    // Gate: only execute if coherence above threshold
    if (globalR < ANGI_COHERENCE_GATE) {
      return { state with totalBeats = state.totalBeats + 1 };
    };

    // Tick all active modules
    let newCore = tickSovereignCore(state.sovereignCore, beat);
    let newResonance = tickResonanceGrid(state.resonanceGrid, beat, globalR);
    let newEcon = tickEconomicEngine(state.economicEngine, beat, maturityDelta);
    let newTimeline = tickTimelineAnchor(state.timelineAnchor, beat);

    {
      state with
      sovereignCore   = newCore;
      resonanceGrid   = newResonance;
      economicEngine  = newEcon;
      timelineAnchor  = newTimeline;
      globalCoherence = globalR;
      totalBeats      = state.totalBeats + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GOVERNANCE — Proposal management
  // ═══════════════════════════════════════════════════════════════════════════

  public func createProposal(
    state : GovernanceCouncilState,
    proposer : Text,
    proposalType : Text,
    description : Text,
    beat : Int
  ) : (GovernanceCouncilState, Text) {
    let proposalId = "PROP-" # Nat.toText(state.totalProposals + 1);
    let expiryBeat = beat + 10000;  // ~2.4 hours at 873ms

    let newProposal : Proposal = {
      proposalId;
      proposer;
      proposalType;
      description;
      votesFor     = 0;
      votesAgainst = 0;
      status       = "ACTIVE";
      createdBeat  = beat;
      expiryBeat;
    };

    let newState = {
      state with
      proposals      = Array.append(state.proposals, [newProposal]);
      totalProposals = state.totalProposals + 1;
      lastGovBeat    = beat;
    };

    (newState, proposalId)
  };

  public func voteOnProposal(
    state : GovernanceCouncilState,
    proposalId : Text,
    voteFor : Bool,
    votingPower : Nat
  ) : GovernanceCouncilState {
    let updatedProposals = Array.map<Proposal, Proposal>(state.proposals, func (p) {
      if (p.proposalId == proposalId and p.status == "ACTIVE") {
        if (voteFor) {
          { p with votesFor = p.votesFor + votingPower }
        } else {
          { p with votesAgainst = p.votesAgainst + votingPower }
        }
      } else { p }
    });

    { state with proposals = updatedProposals }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTITY VAULT — Credential management
  // ═══════════════════════════════════════════════════════════════════════════

  public func issueCredential(
    state : IdentityVaultState,
    principal : Text,
    credType : Text,
    permissions : [Text],
    beat : Int
  ) : (IdentityVaultState, Text) {
    let credentialId = "CRED-" # Nat.toText(state.totalIdentities + 1);

    let newCred : IdentityCredential = {
      credentialId;
      principal;
      credType;
      permissions;
      issuedBeat = beat;
      expiryBeat = null;  // permanent by default
    };

    let newState = {
      state with
      credentials       = Array.append(state.credentials, [newCred]);
      totalIdentities   = state.totalIdentities + 1;
      activeCredentials = state.activeCredentials + 1;
      lastVaultBeat     = beat;
    };

    (newState, credentialId)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSCENDENCE GATE — Cross-chain bridge management
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerBridge(
    state : TranscendenceGateState,
    sourceChain : Text,
    targetChain : Text,
    beat : Int
  ) : (TranscendenceGateState, Text) {
    let bridgeId = "BRIDGE-" # sourceChain # "-" # targetChain;

    let newBridge : BridgeConnection = {
      bridgeId;
      sourceChain;
      targetChain;
      status       = "PENDING";
      throughput   = 0.0;
      lastPingBeat = beat;
    };

    let newState = {
      state with
      bridges      = Array.append(state.bridges, [newBridge]);
      lastGateBeat = beat;
    };

    (newState, bridgeId)
  };

  public func activateBridge(state : TranscendenceGateState, bridgeId : Text) : TranscendenceGateState {
    let updatedBridges = Array.map<BridgeConnection, BridgeConnection>(state.bridges, func (b) {
      if (b.bridgeId == bridgeId) { { b with status = "ACTIVE" } } else { b }
    });

    { state with bridges = updatedBridges }
  };

}
