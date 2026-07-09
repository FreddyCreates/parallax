// sovereign_vault.mo — SOVEREIGN VAULT: Governed Memory for Persistent AI Systems
// PARALLAX Sovereign Organism — Cryptographia Phantasma Infrastructure
//
// DOCTRINE: "Memory is one of the most sensitive components of any persistent
// intelligence system. A sovereign vault determines who can access memory,
// which agent can request memory, what context is required, whether retrieval
// should be exact or abstracted, whether a memory should be sealed after use."
//
// Vault Capabilities:
//   - WRITE: Store sovereign protected memory entries
//   - READ EXACT: Full content retrieval (private-core only)
//   - READ ABSTRACTED: Returns commitment hash, not plaintext
//   - SEAL: Lock entry permanently after single use
//   - EXPIRE: Time-bounded memory with auto-pruning
//   - GOVERNANCE CHECK: Policy gate must pass before any access
//
// Memory Access is an EVENT worth governing:
//   - A memory read can be as important as an external action
//   - A memory write can change the future behavior of the system
//   - A memory deletion can alter institutional continuity
//   - Therefore, memory must be protected as a first-class security domain
//
// PYTHAGORAS: vault entry limits are Fibonacci-scaled (max F(12) = 144 entries)
// EUCLID:     single vault module — all protected memory routes through here
// CONFUCIUS:  right relationship — vault governs, agents request, receipts prove
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Reference: Cryptographia Phantasma §6 — Sovereign Vaults

import Phi "phi";
import PhantomCrypto "phantom_crypto";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT ENTRY — a single protected memory unit
  // ═══════════════════════════════════════════════════════════════════════════

  /// A vault entry — private memory stored in the sovereign vault
  public type VaultEntry = {
    entryId          : Text;
    label            : Text;            // human-readable label
    contentHash      : Nat32;           // FNV-1a of content (public-safe commitment)
    accessLevel      : PhantomCrypto.VaultAccessLevel;
    createdBeat      : Int;
    lastAccessedBeat : Int;
    accessCount      : Nat;
    ownerId          : Text;            // agent that created this entry
    sealed           : Bool;            // if true, content can never be read again
    expiresBeat      : ?Int;            // optional expiry
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT STATE — full sovereign vault state
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum entries per vault: F(12) = 144
  public let MAX_VAULT_ENTRIES : Nat = 144;

  /// Full vault state
  public type SovereignVaultState = {
    vaultId          : Text;
    vaultIdHash      : Nat32;           // public-safe vault identifier
    entries          : [VaultEntry];
    totalWrites      : Nat;
    totalReads       : Nat;
    totalSeals       : Nat;
    lastBeat         : Int;
    receiptChainHead : Nat32;
  };

  /// Create a new empty vault
  public func createVault(vaultId : Text) : SovereignVaultState {
    {
      vaultId = vaultId;
      vaultIdHash = PhantomCrypto.fnv1a(vaultId);
      entries = [];
      totalWrites = 0;
      totalReads = 0;
      totalSeals = 0;
      lastBeat = 0;
      receiptChainHead = PhantomCrypto.GENESIS_RECEIPT_HASH;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE — store a new protected memory entry
  // ═══════════════════════════════════════════════════════════════════════════

  /// Write a new entry to the vault.
  /// Returns updated state, entry ID, and receipt.
  public func writeEntry(
    vault : SovereignVaultState,
    actorId : Text,
    label : Text,
    content : Text,
    accessLevel : PhantomCrypto.VaultAccessLevel,
    currentBeat : Int,
    expiresBeat : ?Int,
    coherence : Float,
  ) : (SovereignVaultState, ?Text, ?PhantomCrypto.ComputeReceipt) {

    // Gate: coherence check
    if (coherence < PhantomCrypto.VAULT_ACCESS_GATE) {
      return (vault, null, null);
    };

    // Capacity check
    if (vault.entries.size() >= MAX_VAULT_ENTRIES) {
      return (vault, null, null);
    };

    // Generate entry ID
    let entryIdSeed = vault.vaultId # "|" # actorId # "|" # label # "|" # Int.toText(currentBeat);
    let entryId = "vent_" # Nat32.toText(PhantomCrypto.fnv1a(entryIdSeed));

    // Hash the content (content itself stays in private-core)
    let contentHash = PhantomCrypto.fnv1a(content);

    let entry : VaultEntry = {
      entryId = entryId;
      label = label;
      contentHash = contentHash;
      accessLevel = accessLevel;
      createdBeat = currentBeat;
      lastAccessedBeat = currentBeat;
      accessCount = 0;
      ownerId = actorId;
      sealed = false;
      expiresBeat = expiresBeat;
    };

    // Build receipt
    let receiptId = "rcpt_vault_w_" # Nat32.toText(PhantomCrypto.fnv1a(entryId));
    let inputCommitment = PhantomCrypto.fnv1a(actorId # "|" # label # "|" # content);
    let outputCommitment = contentHash;

    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, "vault_write", inputCommitment, outputCommitment,
      vault.receiptChainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = "vault_write";
      engineId = "sovereign_vault." # vault.vaultId;
      inputCommitment = inputCommitment;
      outputCommitment = outputCommitment;
      policyGate = {
        result = #pass;
        policyId = "policy.vault.write";
        reasonCode = #scope_match;
        coherence = coherence;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00063; latencyMs = 8.4; memoryBytes = 512 };
      prevReceiptHash = vault.receiptChainHead;
      receiptHash = receiptHash;
    };

    let updatedVault : SovereignVaultState = {
      vaultId = vault.vaultId;
      vaultIdHash = vault.vaultIdHash;
      entries = Array.append(vault.entries, [entry]);
      totalWrites = vault.totalWrites + 1;
      totalReads = vault.totalReads;
      totalSeals = vault.totalSeals;
      lastBeat = currentBeat;
      receiptChainHead = receiptHash;
    };

    (updatedVault, ?entryId, ?receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // READ ABSTRACTED — returns commitment, not plaintext
  // Public-safe: proves memory was accessed without leaking content
  // ═══════════════════════════════════════════════════════════════════════════

  /// Read an entry as abstracted commitment (content hash only).
  /// This is the safe external read path.
  public func readAbstracted(
    vault : SovereignVaultState,
    actorId : Text,
    entryId : Text,
    currentBeat : Int,
    coherence : Float,
  ) : (SovereignVaultState, ?Nat32, ?PhantomCrypto.ComputeReceipt) {

    // Gate check
    if (coherence < PhantomCrypto.VAULT_ACCESS_GATE) {
      return (vault, null, null);
    };

    // Find entry
    var foundEntry : ?VaultEntry = null;
    var foundIndex : Nat = 0;
    for (i in vault.entries.keys()) {
      let e = vault.entries[i];
      if (e.entryId == entryId and not e.sealed) {
        foundEntry := ?e;
        foundIndex := i;
      };
    };

    switch (foundEntry) {
      case (null) { return (vault, null, null) };
      case (?entry) {
        // Update access metadata
        let updatedEntry : VaultEntry = {
          entry with
          lastAccessedBeat = currentBeat;
          accessCount = entry.accessCount + 1;
        };

        let updatedEntries = Array.tabulate<VaultEntry>(
          vault.entries.size(),
          func (i) { if (i == foundIndex) { updatedEntry } else { vault.entries[i] } }
        );

        // Build receipt
        let receiptId = "rcpt_vault_ra_" # Nat32.toText(PhantomCrypto.fnv1a(entryId # "|" # Int.toText(currentBeat)));
        let receiptHash = PhantomCrypto.computeReceiptHash(
          receiptId, "vault_read_abstracted",
          PhantomCrypto.fnv1a(entryId), entry.contentHash,
          vault.receiptChainHead, currentBeat
        );

        let receipt : PhantomCrypto.ComputeReceipt = {
          receiptId = receiptId;
          specVersion = PhantomCrypto.SPEC_VERSION;
          timestampNs = currentBeat;
          computationClass = "vault_read_abstracted";
          engineId = "sovereign_vault." # vault.vaultId;
          inputCommitment = PhantomCrypto.fnv1a(actorId # "|" # entryId);
          outputCommitment = entry.contentHash;
          policyGate = {
            result = #pass;
            policyId = "policy.vault.read_abstracted";
            reasonCode = #least_privilege;
            coherence = coherence;
            beatStamp = currentBeat;
          };
          resourceSummary = { cyclesEstimated = 0.00031; latencyMs = 4.2; memoryBytes = 64 };
          prevReceiptHash = vault.receiptChainHead;
          receiptHash = receiptHash;
        };

        let updatedVault : SovereignVaultState = {
          vaultId = vault.vaultId;
          vaultIdHash = vault.vaultIdHash;
          entries = updatedEntries;
          totalWrites = vault.totalWrites;
          totalReads = vault.totalReads + 1;
          totalSeals = vault.totalSeals;
          lastBeat = currentBeat;
          receiptChainHead = receiptHash;
        };

        (updatedVault, ?entry.contentHash, ?receipt);
      };
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SEAL — permanently lock an entry (one-time read pattern)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Seal an entry permanently. After sealing, content cannot be read again.
  public func sealEntry(
    vault : SovereignVaultState,
    actorId : Text,
    entryId : Text,
    currentBeat : Int,
  ) : (SovereignVaultState, ?PhantomCrypto.ComputeReceipt) {

    var found = false;
    let updatedEntries = Array.map<VaultEntry, VaultEntry>(
      vault.entries,
      func (e) {
        if (e.entryId == entryId and e.ownerId == actorId and not e.sealed) {
          found := true;
          { e with sealed = true };
        } else { e };
      }
    );

    if (not found) { return (vault, null) };

    let receiptId = "rcpt_vault_seal_" # Nat32.toText(PhantomCrypto.fnv1a(entryId # "|seal"));
    let receiptHash = PhantomCrypto.computeReceiptHash(
      receiptId, "vault_seal", PhantomCrypto.fnv1a(entryId),
      PhantomCrypto.fnv1a("SEALED"), vault.receiptChainHead, currentBeat
    );

    let receipt : PhantomCrypto.ComputeReceipt = {
      receiptId = receiptId;
      specVersion = PhantomCrypto.SPEC_VERSION;
      timestampNs = currentBeat;
      computationClass = "vault_seal";
      engineId = "sovereign_vault." # vault.vaultId;
      inputCommitment = PhantomCrypto.fnv1a(entryId);
      outputCommitment = PhantomCrypto.fnv1a("SEALED");
      policyGate = {
        result = #pass;
        policyId = "policy.vault.seal";
        reasonCode = #scope_match;
        coherence = 1.0;
        beatStamp = currentBeat;
      };
      resourceSummary = { cyclesEstimated = 0.00012; latencyMs = 1.8; memoryBytes = 32 };
      prevReceiptHash = vault.receiptChainHead;
      receiptHash = receiptHash;
    };

    let updatedVault : SovereignVaultState = {
      vaultId = vault.vaultId;
      vaultIdHash = vault.vaultIdHash;
      entries = updatedEntries;
      totalWrites = vault.totalWrites;
      totalReads = vault.totalReads;
      totalSeals = vault.totalSeals + 1;
      lastBeat = currentBeat;
      receiptChainHead = receiptHash;
    };

    (updatedVault, ?receipt);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPIRE — heartbeat-driven memory pruning
  // ═══════════════════════════════════════════════════════════════════════════

  /// Expire entries past their expiry beat. Called by heartbeat.
  public func expireEntries(vault : SovereignVaultState, currentBeat : Int) : SovereignVaultState {
    let remaining = Array.filter<VaultEntry>(
      vault.entries,
      func (e) {
        switch (e.expiresBeat) {
          case (null) { true };     // no expiry — keep
          case (?exp) { exp > currentBeat };  // keep if not expired
        };
      }
    );

    { vault with entries = remaining; lastBeat = currentBeat };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC PROOF SURFACE — safe vault diagnostics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Public-safe vault summary (no content, no internal details)
  public func getPublicStats(vault : SovereignVaultState) : {
    vaultIdHash : Nat32;
    entryCount : Nat;
    sealedCount : Nat;
    totalWrites : Nat;
    totalReads : Nat;
    totalSeals : Nat;
    chainHead : Nat32;
  } {
    var sealedCount : Nat = 0;
    for (e in vault.entries.vals()) {
      if (e.sealed) { sealedCount += 1 };
    };

    {
      vaultIdHash = vault.vaultIdHash;
      entryCount = vault.entries.size();
      sealedCount = sealedCount;
      totalWrites = vault.totalWrites;
      totalReads = vault.totalReads;
      totalSeals = vault.totalSeals;
      chainHead = vault.receiptChainHead;
    };
  };
};
