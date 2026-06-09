// intelligence_contracts.mo — INTERNAL INTELLIGENCE CONTRACTS
// PARALLAX Sovereign Organism — AI Contract Infrastructure
//
// DOCTRINE: "Intelligence is bound by contracts. Every cognitive operation
// is a contractual agreement between the requesting entity and the sovereign
// intelligence layer. Contracts define capabilities, constraints, resource
// budgets, and execution guarantees. This is the LAW of intelligence."
//
// THE INTELLIGENCE CONTRACT LAW (LEX_INTELLIGENTIA):
//   All intelligence operations are contract-bound.
//   Contracts specify: input schema, output schema, resource budget, coherence gate.
//   Contract execution is atomic — either fully succeeds or fully reverts.
//   Contract state persists across heartbeats via Enhanced Orthogonal Persistence.
//
// Contract Categories:
//   ROUTING   — Contracts that direct intelligence flow between components
//   REASONING — Contracts that perform cognitive reasoning operations
//   VALUATION — Contracts that price AI artifacts and outputs
//   EXTENSION — Contracts that extend core intelligence capabilities
//   COUPLING  — Contracts that bind external AI systems to the organism
//   ORACLE    — Contracts that interface with external data sources
//   GUARDIAN  — Contracts that protect and validate intelligence operations
//
// PYTHAGORAS: all resource budgets and gates are phi-derived
// EUCLID:     single contract registry — all contracts registered once, enforced everywhere
// CONFUCIUS:  right relationship — contracts serve intelligence, intelligence serves the organism
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Text "mo:core/Text";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE CONTRACT CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Minimum coherence for contract execution: φ⁻¹ = 0.618
  public let CONTRACT_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Maximum token budget per contract call: F(12) = 144 × 1000
  public let MAX_TOKEN_BUDGET : Nat = 144_000;

  // Contract timeout in beats: F(8) = 21 beats ≈ 18.3 seconds
  public let CONTRACT_TIMEOUT_BEATS : Nat = 21;

  // Maximum contract chain depth: F(7) = 13
  public let MAX_CONTRACT_CHAIN : Nat = 13;

  // Extension slot count: F(6) = 8
  public let EXTENSION_SLOTS : Nat = 8;

  // Coupling weight floor: φ⁻² = 0.382
  public let COUPLING_WEIGHT_FLOOR : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT CATEGORY — the seven pillars of intelligence contracts
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContractCategory = {
    #routing;     // Directs intelligence flow
    #reasoning;   // Performs cognitive operations
    #valuation;   // Prices AI outputs
    #extension;   // Extends capabilities
    #coupling;    // Binds external AI
    #oracle;      // External data interface
    #guardian;    // Validates and protects
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT STATUS — lifecycle states
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContractStatus = {
    #draft;       // Being defined, not yet active
    #active;      // Live and executable
    #suspended;   // Temporarily disabled
    #deprecated;  // Superseded, read-only
    #terminated;  // Permanently closed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT EXECUTION RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExecutionResult = {
    #success : {
      outputHash   : Text;
      tokensUsed   : Nat;
      latencyBeats : Nat;
    };
    #failure : {
      errorCode    : Nat;
      errorMessage : Text;
      stage        : Text;
    };
    #timeout;
    #coherenceGateFailed : { currentR : Float; requiredR : Float };
    #budgetExceeded : { requested : Nat; available : Nat };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE CONTRACT — the fundamental unit of AI governance
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceContract = {
    contractId       : Text;           // Unique identifier (e.g., "IC-ROUTING-001")
    name             : Text;           // Human-readable name
    category         : ContractCategory;
    status           : ContractStatus;
    version          : Nat;            // Semantic version (increments on update)

    // Schema definitions
    inputSchema      : Text;           // JSON schema for inputs
    outputSchema     : Text;           // JSON schema for outputs

    // Resource governance
    tokenBudget      : Nat;            // Maximum tokens per execution
    coherenceGate    : Float;          // Minimum R for execution [0.618, 1.0]
    timeoutBeats     : Nat;            // Max beats before timeout

    // Dependencies and chaining
    requiredContracts: [Text];         // Contract IDs this depends on
    chainPosition    : Nat;            // Position in execution chain (0 = root)

    // Execution statistics
    totalExecutions  : Nat;
    successCount     : Nat;
    failureCount     : Nat;
    avgTokensUsed    : Float;
    avgLatencyBeats  : Float;

    // Temporal anchors
    createdBeat      : Int;
    lastExecutedBeat : Int;
    lastModifiedBeat : Int;

    // Ownership and permissions
    ownerPrincipal   : Text;           // Creator principal
    executorList     : [Text];         // Principals allowed to execute
    isPublic         : Bool;           // Open execution allowed
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING CONTRACT — specialized for intelligence flow direction
  // ═══════════════════════════════════════════════════════════════════════════

  public type RouteCondition = {
    #coherenceAbove : Float;           // R > threshold
    #coherenceBelow : Float;           // R < threshold
    #signalTypeMatch : Text;           // Signal type matches
    #tokenBudgetAvailable : Nat;       // Budget remaining
    #modelAvailable : Text;            // Specific model online
    #always;                           // Unconditional
  };

  public type RoutingRule = {
    ruleId          : Text;
    priority        : Nat;             // Lower = higher priority
    condition       : RouteCondition;
    targetContract  : Text;            // Contract to route to
    weight          : Float;           // Routing weight [0.0, 1.0]
    isActive        : Bool;
  };

  public type RoutingContract = {
    baseContract    : IntelligenceContract;
    rules           : [RoutingRule];
    defaultTarget   : Text;            // Fallback contract
    loadBalancing   : Bool;            // Enable multi-target balancing
    routeHistory    : [(Int, Text, Text)];  // (beat, from, to)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REASONING CONTRACT — cognitive operation specification
  // ═══════════════════════════════════════════════════════════════════════════

  public type ReasoningMode = {
    #deductive;    // From general to specific
    #inductive;    // From specific to general
    #abductive;    // Best explanation inference
    #analogical;   // Pattern matching
    #causal;       // Cause-effect reasoning
    #probabilistic;// Bayesian reasoning
    #dialectical;  // Thesis-antithesis-synthesis
    #heuristic;    // Rule-of-thumb
  };

  public type ReasoningContract = {
    baseContract     : IntelligenceContract;
    reasoningMode    : ReasoningMode;
    maxDepth         : Nat;            // Chain-of-thought depth limit
    confidenceFloor  : Float;          // Minimum output confidence
    doctrineCheck    : Bool;           // Validate against sovereign laws
    traceEnabled     : Bool;           // Record reasoning trace
    modelPreference  : [Text];         // Preferred models for execution
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VALUATION CONTRACT — AI artifact pricing specification
  // ═══════════════════════════════════════════════════════════════════════════

  public type ValuationMethod = {
    #resonance;        // Cognitive resonance scoring
    #utility;          // Practical use value
    #scarcity;         // Rarity-based pricing
    #composite;        // Multi-factor (phi-weighted)
    #market;           // Supply-demand derived
    #doctrineAligned;  // Sovereign law compliance premium
  };

  public type ValuationContract = {
    baseContract      : IntelligenceContract;
    valuationMethod   : ValuationMethod;
    baseValueFloor    : Float;         // Minimum value in MTC
    resonanceWeight   : Float;         // Weight for resonance factor
    utilityWeight     : Float;         // Weight for utility factor
    scarcityWeight    : Float;         // Weight for scarcity factor
    doctrineWeight    : Float;         // Weight for doctrine alignment
    revaluationPeriod : Nat;           // Beats between revaluations
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSION CONTRACT — capability extension specification
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExtensionType = {
    #modelAdapter;     // Adapts external models to sovereign format
    #dataConnector;    // Connects to external data sources
    #protocolBridge;   // Bridges to external protocols
    #computeOffload;   // Offloads computation externally
    #storageExtender;  // Extends storage capabilities
    #inferenceBooster; // Enhances inference quality
    #securityLayer;    // Adds security capabilities
    #auditTrail;       // Extends audit capabilities
  };

  public type ExtensionContract = {
    baseContract      : IntelligenceContract;
    extensionType     : ExtensionType;
    slotIndex         : Nat;           // Extension slot (0-7)
    capabilities      : [Text];        // List of provided capabilities
    resourceCost      : Nat;           // Token cost per use
    trustLevel        : Float;         // [0.0, 1.0] — sovereign trust score
    sandboxed         : Bool;          // Runs in isolated context
    lastHealthCheck   : Int;           // Beat of last health verification
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLING CONTRACT — external AI system binding
  // ═══════════════════════════════════════════════════════════════════════════

  public type CouplingMode = {
    #tight;    // Strong binding, real-time sync
    #loose;    // Weak binding, async updates
    #event;    // Event-driven coupling
    #request;  // Request-response pattern
    #stream;   // Continuous data stream
  };

  public type CouplingContract = {
    baseContract      : IntelligenceContract;
    couplingMode      : CouplingMode;
    externalEndpoint  : Text;          // External system identifier
    couplingWeight    : Float;         // Influence weight [0.382, 1.0]
    syncPeriodBeats   : Nat;           // Sync frequency
    transformSchema   : Text;          // Input/output transformation
    backpressureLimit : Nat;           // Max pending messages
    lastSyncBeat      : Int;
    messagesExchanged : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORACLE CONTRACT — external data source interface
  // ═══════════════════════════════════════════════════════════════════════════

  public type OracleType = {
    #price;        // Price feed oracle
    #random;       // Verifiable randomness
    #timestamp;    // Time oracle
    #computation;  // Verified computation
    #attestation;  // Identity/credential attestation
    #consensus;    // Multi-source consensus
  };

  public type OracleContract = {
    baseContract       : IntelligenceContract;
    oracleType         : OracleType;
    dataSourceId       : Text;         // External source identifier
    refreshPeriodBeats : Nat;          // Data refresh frequency
    minConsensus       : Nat;          // Minimum agreeing sources
    maxStaleness       : Nat;          // Max beats data can be old
    currentValue       : Text;         // Latest oracle value (serialized)
    lastRefreshBeat    : Int;
    confidenceInValue  : Float;        // [0.0, 1.0]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GUARDIAN CONTRACT — validation and protection
  // ═══════════════════════════════════════════════════════════════════════════

  public type GuardianAction = {
    #validate;     // Validate inputs/outputs
    #sanitize;     // Clean/filter data
    #rateLimit;    // Throttle requests
    #audit;        // Record for audit
    #encrypt;      // Protect sensitive data
    #verify;       // Verify signatures/proofs
    #quarantine;   // Isolate suspicious activity
  };

  public type GuardianContract = {
    baseContract      : IntelligenceContract;
    guardianActions   : [GuardianAction];
    protectedContracts: [Text];        // Contracts this guards
    alertThreshold    : Float;         // Anomaly detection threshold
    quarantineEnabled : Bool;
    violationsDetected: Nat;
    lastAlertBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT REGISTRY — sovereign index of all intelligence contracts
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContractRegistry = {
    contracts         : [(Text, IntelligenceContract)];  // (id, contract)
    routingContracts  : [(Text, RoutingContract)];
    reasoningContracts: [(Text, ReasoningContract)];
    valuationContracts: [(Text, ValuationContract)];
    extensionContracts: [(Text, ExtensionContract)];
    couplingContracts : [(Text, CouplingContract)];
    oracleContracts   : [(Text, OracleContract)];
    guardianContracts : [(Text, GuardianContract)];

    // Registry metadata
    totalContracts    : Nat;
    activeContracts   : Nat;
    totalExecutions   : Nat;
    lastRegistryBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT STATE — the persistence layer for intelligence contracts
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceContractState = {
    registry           : ContractRegistry;
    executionQueue     : [(Text, Int)];    // (contractId, queuedBeat)
    executionHistory   : [(Text, Int, ExecutionResult)];  // (contractId, beat, result)
    nextContractId     : Nat;
    globalTokenBudget  : Nat;
    budgetUsedThisBeat : Nat;
    lastTickBeat       : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — genesis-compliant initial state
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultContractRegistry() : ContractRegistry {
    {
      contracts          = [];
      routingContracts   = [];
      reasoningContracts = [];
      valuationContracts = [];
      extensionContracts = [];
      couplingContracts  = [];
      oracleContracts    = [];
      guardianContracts  = [];
      totalContracts     = 0;
      activeContracts    = 0;
      totalExecutions    = 0;
      lastRegistryBeat   = 0;
    }
  };

  public func defaultIntelligenceContractState() : IntelligenceContractState {
    {
      registry           = defaultContractRegistry();
      executionQueue     = [];
      executionHistory   = [];
      nextContractId     = 1;
      globalTokenBudget  = MAX_TOKEN_BUDGET * 10;  // 10x buffer
      budgetUsedThisBeat = 0;
      lastTickBeat       = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT CREATION — factory functions for each contract type
  // ═══════════════════════════════════════════════════════════════════════════

  public func createBaseContract(
    id       : Text,
    name     : Text,
    category : ContractCategory,
    owner    : Text,
    beat     : Int
  ) : IntelligenceContract {
    {
      contractId        = id;
      name              = name;
      category          = category;
      status            = #draft;
      version           = 1;
      inputSchema       = "{}";
      outputSchema      = "{}";
      tokenBudget       = MAX_TOKEN_BUDGET;
      coherenceGate     = CONTRACT_COHERENCE_GATE;
      timeoutBeats      = CONTRACT_TIMEOUT_BEATS;
      requiredContracts = [];
      chainPosition     = 0;
      totalExecutions   = 0;
      successCount      = 0;
      failureCount      = 0;
      avgTokensUsed     = 0.0;
      avgLatencyBeats   = 0.0;
      createdBeat       = beat;
      lastExecutedBeat  = 0;
      lastModifiedBeat  = beat;
      ownerPrincipal    = owner;
      executorList      = [owner];
      isPublic          = false;
    }
  };

  public func createRoutingContract(
    base         : IntelligenceContract,
    rules        : [RoutingRule],
    defaultTarget: Text
  ) : RoutingContract {
    {
      baseContract   = { base with category = #routing };
      rules          = rules;
      defaultTarget  = defaultTarget;
      loadBalancing  = false;
      routeHistory   = [];
    }
  };

  public func createReasoningContract(
    base : IntelligenceContract,
    mode : ReasoningMode
  ) : ReasoningContract {
    {
      baseContract     = { base with category = #reasoning };
      reasoningMode    = mode;
      maxDepth         = MAX_CONTRACT_CHAIN;
      confidenceFloor  = Phi.PHI_INV_3;  // 0.236
      doctrineCheck    = true;
      traceEnabled     = true;
      modelPreference  = [];
    }
  };

  public func createCouplingContract(
    base     : IntelligenceContract,
    mode     : CouplingMode,
    endpoint : Text
  ) : CouplingContract {
    {
      baseContract       = { base with category = #coupling };
      couplingMode       = mode;
      externalEndpoint   = endpoint;
      couplingWeight     = COUPLING_WEIGHT_FLOOR;
      syncPeriodBeats    = 21;  // F(8)
      transformSchema    = "{}";
      backpressureLimit  = 144;  // F(12)
      lastSyncBeat       = 0;
      messagesExchanged  = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT OPERATIONS — register, execute, query
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerContract(
    state    : IntelligenceContractState,
    contract : IntelligenceContract,
    beat     : Int
  ) : IntelligenceContractState {
    let newContracts = Array.append(
      state.registry.contracts,
      [(contract.contractId, contract)]
    );
    let newRegistry = {
      state.registry with
      contracts      = newContracts;
      totalContracts = state.registry.totalContracts + 1;
      activeContracts = state.registry.activeContracts + (if (contract.status == #active) 1 else 0);
      lastRegistryBeat = beat;
    };
    {
      state with
      registry       = newRegistry;
      nextContractId = state.nextContractId + 1;
    }
  };

  public func activateContract(
    state      : IntelligenceContractState,
    contractId : Text,
    beat       : Int
  ) : IntelligenceContractState {
    let contracts = Array.map<(Text, IntelligenceContract), (Text, IntelligenceContract)>(
      state.registry.contracts,
      func((id, c)) {
        if (id == contractId) {
          (id, { c with status = #active; lastModifiedBeat = beat })
        } else {
          (id, c)
        }
      }
    );
    let activeCount = Array.size(Array.filter<(Text, IntelligenceContract)>(
      contracts,
      func((_, c)) { c.status == #active }
    ));
    {
      state with
      registry = {
        state.registry with
        contracts       = contracts;
        activeContracts = activeCount;
        lastRegistryBeat = beat;
      }
    }
  };

  public func getContract(
    state      : IntelligenceContractState,
    contractId : Text
  ) : ?IntelligenceContract {
    for ((id, contract) in state.registry.contracts.vals()) {
      if (id == contractId) return ?contract;
    };
    null
  };

  public func listActiveContracts(
    state : IntelligenceContractState
  ) : [IntelligenceContract] {
    Array.map<(Text, IntelligenceContract), IntelligenceContract>(
      Array.filter<(Text, IntelligenceContract)>(
        state.registry.contracts,
        func((_, c)) { c.status == #active }
      ),
      func((_, c)) { c }
    )
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRACT EXECUTION — coherence-gated execution logic
  // ═══════════════════════════════════════════════════════════════════════════

  public func canExecute(
    state       : IntelligenceContractState,
    contractId  : Text,
    currentR    : Float,
    tokensNeeded: Nat
  ) : ExecutionResult {
    switch (getContract(state, contractId)) {
      case null { #failure({ errorCode = 404; errorMessage = "Contract not found"; stage = "lookup" }) };
      case (?contract) {
        // Check status
        if (contract.status != #active) {
          return #failure({ errorCode = 403; errorMessage = "Contract not active"; stage = "status" });
        };
        // Coherence gate
        if (currentR < contract.coherenceGate) {
          return #coherenceGateFailed({ currentR = currentR; requiredR = contract.coherenceGate });
        };
        // Budget check
        let available = state.globalTokenBudget - state.budgetUsedThisBeat;
        if (tokensNeeded > available) {
          return #budgetExceeded({ requested = tokensNeeded; available = available });
        };
        // All gates passed
        #success({ outputHash = ""; tokensUsed = 0; latencyBeats = 0 })
      };
    }
  };

  public func recordExecution(
    state      : IntelligenceContractState,
    contractId : Text,
    result     : ExecutionResult,
    beat       : Int
  ) : IntelligenceContractState {
    // Update history
    let newHistory = Array.append(
      state.executionHistory,
      [(contractId, beat, result)]
    );

    // Update contract stats
    let contracts = Array.map<(Text, IntelligenceContract), (Text, IntelligenceContract)>(
      state.registry.contracts,
      func((id, c)) {
        if (id == contractId) {
          let (newSuccess, newFailure, tokensUsed) = switch result {
            case (#success(s)) { (c.successCount + 1, c.failureCount, s.tokensUsed) };
            case _ { (c.successCount, c.failureCount + 1, 0 : Nat) };
          };
          let newAvgTokens = if (c.totalExecutions == 0) {
            Float.fromInt(tokensUsed)
          } else {
            (c.avgTokensUsed * Float.fromInt(c.totalExecutions) + Float.fromInt(tokensUsed)) /
            Float.fromInt(c.totalExecutions + 1)
          };
          (id, {
            c with
            totalExecutions  = c.totalExecutions + 1;
            successCount     = newSuccess;
            failureCount     = newFailure;
            avgTokensUsed    = newAvgTokens;
            lastExecutedBeat = beat;
          })
        } else {
          (id, c)
        }
      }
    );

    let tokensConsumed = switch result {
      case (#success(s)) { s.tokensUsed };
      case _ { 0 };
    };

    {
      state with
      registry = {
        state.registry with
        contracts       = contracts;
        totalExecutions = state.registry.totalExecutions + 1;
        lastRegistryBeat = beat;
      };
      executionHistory   = newHistory;
      budgetUsedThisBeat = state.budgetUsedThisBeat + tokensConsumed;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK FUNCTION — per-heartbeat contract maintenance
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickContracts(
    state     : IntelligenceContractState,
    beat      : Int,
    coherence : Float
  ) : IntelligenceContractState {
    // Reset beat budget
    let resetBudget = if (beat > state.lastTickBeat) { 0 } else { state.budgetUsedThisBeat };

    // Process execution queue (execute queued contracts if coherence permits)
    // For now, simple implementation — more sophisticated queue processing can be added

    {
      state with
      budgetUsedThisBeat = resetBudget;
      lastTickBeat       = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS CONTRACTS — pre-seeded sovereign contracts (GENESIS LAW L09)
  // ═══════════════════════════════════════════════════════════════════════════

  public func genesisIntelligenceContractState() : IntelligenceContractState {
    let now : Int = 0;
    let owner = "SOVEREIGN";

    // Create genesis routing contract
    let routingBase = createBaseContract("IC-ROUTING-GENESIS", "Genesis Intelligence Router", #routing, owner, now);
    let genesisRouter = createRoutingContract(
      { routingBase with status = #active },
      [{
        ruleId         = "RULE-COHERENCE-HIGH";
        priority       = 1;
        condition      = #coherenceAbove(Phi.PHI_INV);
        targetContract = "IC-REASONING-GENESIS";
        weight         = 1.0;
        isActive       = true;
      }],
      "IC-REASONING-FALLBACK"
    );

    // Create genesis reasoning contract
    let reasoningBase = createBaseContract("IC-REASONING-GENESIS", "Genesis Deductive Reasoner", #reasoning, owner, now);
    let genesisReasoner = createReasoningContract(
      { reasoningBase with status = #active },
      #deductive
    );

    // Create genesis guardian contract
    let guardianBase = createBaseContract("IC-GUARDIAN-GENESIS", "Genesis Doctrine Guardian", #guardian, owner, now);
    let genesisGuardian : GuardianContract = {
      baseContract       = { guardianBase with status = #active; category = #guardian };
      guardianActions    = [#validate, #audit, #verify];
      protectedContracts = ["IC-ROUTING-GENESIS", "IC-REASONING-GENESIS"];
      alertThreshold     = Phi.PHI_INV_2;  // 0.382
      quarantineEnabled  = true;
      violationsDetected = 0;
      lastAlertBeat      = 0;
    };

    let baseState = defaultIntelligenceContractState();

    // Register genesis contracts
    let registry : ContractRegistry = {
      contracts          = [
        (routingBase.contractId, genesisRouter.baseContract),
        (reasoningBase.contractId, genesisReasoner.baseContract),
        (guardianBase.contractId, genesisGuardian.baseContract)
      ];
      routingContracts   = [(routingBase.contractId, genesisRouter)];
      reasoningContracts = [(reasoningBase.contractId, genesisReasoner)];
      valuationContracts = [];
      extensionContracts = [];
      couplingContracts  = [];
      oracleContracts    = [];
      guardianContracts  = [(guardianBase.contractId, genesisGuardian)];
      totalContracts     = 3;
      activeContracts    = 3;
      totalExecutions    = 0;
      lastRegistryBeat   = 0;
    };

    {
      baseState with
      registry       = registry;
      nextContractId = 4;
    }
  };

};
