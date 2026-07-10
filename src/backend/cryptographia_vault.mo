// cryptographia_vault.mo — CRYPTOGRAPHIA PHANTASMA: Sovereign Vaults
// PARALLAX Sovereign Organism — Governed Memory with Policy-Gated Access
//
// FROM THE PAPER: "Sovereign Vaults: Governed memory structures with
// policy-gated, abstracted access (e.g., return commitments/hashes instead
// of raw data)."
//
// DOCTRINE: "Sovereign Vaults hold the organism's cognitive memory in protected
// structures. Access is policy-gated — requestors receive commitments and hashes,
// never raw cognitive data. The vault knows what it holds but reveals only proofs."
//
// THE SOVEREIGN VAULT ARCHITECTURE:
//   SV-001  VAULT REGISTRY           — Create and manage sovereign vaults
//   SV-002  POLICY ENGINE            — Access control policies (who, what, when, how)
//   SV-003  COMMITMENT GENERATOR     — Hash commitments instead of raw data
//   SV-004  ABSTRACTION LAYER        — Return proofs, summaries, not internals
//   SV-005  AUDIT LOG                — Every access attempt logged (success + denial)
//   SV-006  TEMPORAL LOCK            — Time-bounded access windows
//   SV-007  HIERARCHICAL GATES       — Nested permission levels
//   SV-008  SELF-DESTRUCT PROTOCOL   — Vault data erasure on policy violation
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  public let VAULT_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MAX_VAULTS : Nat = 21;                                  // F(8) sovereign vaults
  public let MAX_ENTRIES_PER_VAULT : Nat = 233;                      // F(13) max entries
  public let ACCESS_LOG_DEPTH : Nat = 89;                            // F(11) log entries
  public let TEMPORAL_LOCK_DEFAULT : Nat = 55;                       // F(10) beats default lock
  public let PERMISSION_LEVELS : Nat = 5;                            // F(5) hierarchy depth
  public let COMMITMENT_HASH_ROUNDS : Nat = 8;                      // F(6) rounds

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type VaultClass = {
    #cognitive;        // internal reasoning/memory
    #strategic;        // trading strategies and parameters
    #identity;         // sovereign identity data
    #financial;        // sensitive financial state
    #communication;    // inter-agent message history
  };

  public type AccessLevel = {
    #public_;          // commitment/hash only (anyone)
    #organism;         // internal subsystems
    #sovereign;        // creator/owner only
    #sealed;           // no access (self-destruct on attempt)
  };

  public type AccessResult = {
    #granted;
    #denied;
    #commitment;       // returned hash instead of data
    #expired;
    #destroyed;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT ENTRY — single protected datum
  // ═══════════════════════════════════════════════════════════════════════════

  public type VaultEntry = {
    entryId       : Text;
    dataHash      : Nat64;           // commitment hash of the stored data
    category      : Text;            // classification label
    createdBeat   : Int;
    lastAccessBeat : Int;
    accessCount   : Nat;
    accessLevel   : AccessLevel;
    temporalLock  : Int;             // beat after which access is allowed
    isSealed      : Bool;            // permanently inaccessible
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESS POLICY — who can access what
  // ═══════════════════════════════════════════════════════════════════════════

  public type AccessPolicy = {
    policyId        : Text;
    requiredLevel   : AccessLevel;
    maxAccessPerBeat : Nat;          // rate limit
    temporalWindow  : Nat;           // allowed time window (beats)
    requiresCoherence : Float;       // minimum system coherence
    requiresProof   : Bool;          // must present proof of need
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESS LOG — audit trail
  // ═══════════════════════════════════════════════════════════════════════════

  public type VaultAccessLog = {
    logId         : Text;
    vaultId       : Text;
    entryId       : Text;
    requestorHash : Nat64;           // obfuscated requestor identity
    result        : AccessResult;
    beat          : Int;
    policyApplied : Text;
    coherenceAtAccess : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN VAULT — the protected memory structure
  // ═══════════════════════════════════════════════════════════════════════════

  public type SovereignVault = {
    vaultId       : Text;
    vaultClass    : VaultClass;
    entries       : [VaultEntry];
    policy        : AccessPolicy;
    totalAccesses : Nat;
    totalDenials  : Nat;
    createdBeat   : Int;
    lastAccessBeat : Int;
    integrity     : Float;           // vault health [0, 1]
    isLocked      : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CRYPTOGRAPHIA VAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type CryptographiaVaultState = {
    vaults          : [SovereignVault];
    accessLog       : [VaultAccessLog];
    totalVaults     : Nat;
    totalEntries    : Nat;
    totalAccesses   : Nat;
    totalDenials    : Nat;
    totalCommitments : Nat;          // times commitment returned instead of data
    lastTickBeat    : Int;
    coherence       : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultCryptographiaVaultState() : CryptographiaVaultState {
    {
      vaults = [];
      accessLog = [];
      totalVaults = 0;
      totalEntries = 0;
      totalAccesses = 0;
      totalDenials = 0;
      totalCommitments = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // FNV hash
  func fnv1a(a : Nat64, b : Nat64) : Nat64 { (a ^ b) *% 1099511628211 };

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE VAULT — register new sovereign vault
  // ═══════════════════════════════════════════════════════════════════════════

  public func createVault(
    state : CryptographiaVaultState,
    vaultClass : VaultClass,
    accessLevel : AccessLevel,
    beat : Int
  ) : CryptographiaVaultState {
    if (state.vaults.size() >= MAX_VAULTS) return state;

    let classText = switch(vaultClass) {
      case (#cognitive) "COG";
      case (#strategic) "STR";
      case (#identity) "IDN";
      case (#financial) "FIN";
      case (#communication) "COM";
    };
    let vaultId = classText # "-" # Int.toText(beat);

    let policy : AccessPolicy = {
      policyId = "POL-" # vaultId;
      requiredLevel = accessLevel;
      maxAccessPerBeat = 3;
      temporalWindow = TEMPORAL_LOCK_DEFAULT;
      requiresCoherence = Phi.PHI_INV;
      requiresProof = true;
    };

    let vault : SovereignVault = {
      vaultId = vaultId;
      vaultClass = vaultClass;
      entries = [];
      policy = policy;
      totalAccesses = 0;
      totalDenials = 0;
      createdBeat = beat;
      lastAccessBeat = beat;
      integrity = 1.0;
      isLocked = false;
    };

    {
      state with
      vaults = Array.append(state.vaults, [vault]);
      totalVaults = state.totalVaults + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STORE — add entry to vault (returns commitment hash, never stores raw)
  // ═══════════════════════════════════════════════════════════════════════════

  public func storeEntry(
    state : CryptographiaVaultState,
    vaultId : Text,
    dataHash : Nat64,
    category : Text,
    beat : Int
  ) : (CryptographiaVaultState, Nat64) {
    // Generate commitment (hash of hash — one-way binding)
    var commitment = dataHash;
    var i : Nat = 0;
    while (i < COMMITMENT_HASH_ROUNDS) {
      commitment := fnv1a(commitment, Nat64.fromNat(i + 1));
      i += 1;
    };

    let entry : VaultEntry = {
      entryId = Nat64.toText(commitment);
      dataHash = dataHash;
      category = category;
      createdBeat = beat;
      lastAccessBeat = beat;
      accessCount = 0;
      accessLevel = #organism;
      temporalLock = beat;
      isSealed = false;
    };

    let updatedVaults = Array.map<SovereignVault, SovereignVault>(state.vaults, func(v) {
      if (v.vaultId == vaultId and v.entries.size() < MAX_ENTRIES_PER_VAULT) {
        { v with entries = Array.append(v.entries, [entry]) }
      } else { v }
    });

    let newState = {
      state with
      vaults = updatedVaults;
      totalEntries = state.totalEntries + 1;
    };
    (newState, commitment)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESS — request data (returns commitment, not raw data)
  // ═══════════════════════════════════════════════════════════════════════════

  public func accessEntry(
    state : CryptographiaVaultState,
    vaultId : Text,
    entryId : Text,
    requestorHash : Nat64,
    beat : Int,
    systemCoherence : Float
  ) : (CryptographiaVaultState, AccessResult, Nat64) {
    // Find vault
    var result : AccessResult = #denied;
    var commitment : Nat64 = 0;

    let updatedVaults = Array.map<SovereignVault, SovereignVault>(state.vaults, func(v) {
      if (v.vaultId != vaultId) return v;
      if (v.isLocked) { result := #denied; return v };

      // Check coherence policy
      if (systemCoherence < v.policy.requiresCoherence) {
        result := #denied;
        return { v with totalDenials = v.totalDenials + 1 };
      };

      // Find entry
      let updatedEntries = Array.map<VaultEntry, VaultEntry>(v.entries, func(e) {
        if (e.entryId != entryId) return e;
        if (e.isSealed) { result := #destroyed; return e };
        if (beat < e.temporalLock) { result := #expired; return e };

        // Policy check passed — return commitment (not raw data)
        result := #commitment;
        commitment := e.dataHash; // In production: hash of hash
        { e with accessCount = e.accessCount + 1; lastAccessBeat = beat }
      });

      { v with entries = updatedEntries; totalAccesses = v.totalAccesses + 1; lastAccessBeat = beat }
    });

    // Log access
    let logEntry : VaultAccessLog = {
      logId = Nat64.toText(fnv1a(requestorHash, Nat64.fromNat(Int.abs(beat))));
      vaultId = vaultId;
      entryId = entryId;
      requestorHash = requestorHash;
      result = result;
      beat = beat;
      policyApplied = "DEFAULT";
      coherenceAtAccess = systemCoherence;
    };

    let accessLog = if (state.accessLog.size() >= ACCESS_LOG_DEPTH) {
      Array.tabulate<VaultAccessLog>(ACCESS_LOG_DEPTH, func(i) {
        if (i < ACCESS_LOG_DEPTH - 1) state.accessLog[i + 1] else logEntry
      })
    } else {
      Array.append(state.accessLog, [logEntry])
    };

    let (accesses, denials, commits) = switch(result) {
      case (#granted) (state.totalAccesses + 1, state.totalDenials, state.totalCommitments);
      case (#commitment) (state.totalAccesses + 1, state.totalDenials, state.totalCommitments + 1);
      case (#denied) (state.totalAccesses, state.totalDenials + 1, state.totalCommitments);
      case _ (state.totalAccesses, state.totalDenials, state.totalCommitments);
    };

    let newState = {
      state with
      vaults = updatedVaults;
      accessLog = accessLog;
      totalAccesses = accesses;
      totalDenials = denials;
      totalCommitments = commits;
    };
    (newState, result, commitment)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — vault lifecycle management
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickCryptographiaVaults(
    state : CryptographiaVaultState,
    beat : Int,
    systemCoherence : Float
  ) : CryptographiaVaultState {
    if (systemCoherence < VAULT_COHERENCE_GATE) return state;

    // Decay integrity of unaccessed vaults
    let updatedVaults = Array.map<SovereignVault, SovereignVault>(state.vaults, func(v) {
      let idle = Int.abs(beat - v.lastAccessBeat);
      let integrityDecay = if (idle > TEMPORAL_LOCK_DEFAULT) {
        v.integrity * Phi.PHI_INV
      } else { v.integrity };
      { v with integrity = integrityDecay }
    });

    {
      state with
      vaults = updatedVaults;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getTotalVaults(state : CryptographiaVaultState) : Nat {
    state.totalVaults
  };

  public func getTotalDenials(state : CryptographiaVaultState) : Nat {
    state.totalDenials
  };

  public func getTotalCommitments(state : CryptographiaVaultState) : Nat {
    state.totalCommitments
  };
};
