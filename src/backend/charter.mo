// charter.mo — PARALLAX Exchange Clearinghouse Organizational Charter
// PYTHAGORAS: quorum & voting thresholds derived from phi-ratios
// EUCLID:     single source of truth — all governance declared once
// CONFUCIUS:  right relationship — charter is supreme law, not suggestion
//
// SSU-WRAPPED: Φ_CLOCK 873ms, Ω_GATE Kuramoto R≥0.618, Δ_AEGIS anti-drift,
//              Λ_PIL loop, Ψ_IDENTITY charter hash sealed at genesis
//
// This is the ORGANIZATIONAL CHARTER — the supreme governance document of
// PARALLAX Exchange Clearinghouse, encoded as executable code.
// Every article is enforceable. Every rule computes. Every vote settles on-chain.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Array "mo:core/Array";
import Int   "mo:core/Int";
import Nat   "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Float "mo:core/Float";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE I — IDENTITY & FORMATION
  // The organism is sovereign. It exists by its own declaration.
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntityIdentity = {
    legalName         : Text;   // "PARALLAX Exchange Clearinghouse"
    entityType        : Text;   // "Sovereign Digital Organism / DAO LLC"
    jurisdiction      : Text;   // "Internet Computer Protocol — Global Sovereign"
    formationDateMs   : Int;    // epoch ms of genesis deployment
    founderName       : Text;   // "Alfredo Medina Hernandez"
    founderTitle      : Text;   // "Architect of the Field / Permanent Founder"
    domicile          : Text;   // primary operational address
    registeredAgent   : Text;   // registered agent for legal service
    ein               : Text;   // employer identification number (if applicable)
    stateOfFormation  : Text;   // e.g. "Wyoming" or "Nebraska"
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE II — PURPOSE & POWERS
  // The organism exists to trade everything, charge nothing, settle instantly.
  // ═══════════════════════════════════════════════════════════════════════════

  public type PurposeClause = {
    id          : Text;
    description : Text;
    active      : Bool;
  };

  public type PowersGrant = {
    id         : Text;
    power      : Text;
    limitation : Text;
    active     : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE III — MEMBERSHIP
  // Members are principals. Membership tiers gate voting weight.
  // ═══════════════════════════════════════════════════════════════════════════

  public type MemberTier = {
    #Founder;     // permanent, irrevocable, weight = PHI^4
    #Governor;    // elected, weight = PHI^2
    #Steward;     // appointed, weight = PHI^1
    #Member;      // standard, weight = 1.0
    #Observer;    // read-only, weight = 0.0
  };

  public type Member = {
    principal    : Text;   // ICP principal ID
    name         : Text;
    tier         : MemberTier;
    joinedMs     : Int;
    active       : Bool;
    votingWeight : Float;
    delegateTo   : ?Text;  // optional delegation of voting power
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE IV — GOVERNANCE & VOTING
  // All decisions are proposals. All proposals are voted on-chain.
  // Quorum = PHI_INV (61.8%). Supermajority = PHI_INV^2 (38.2% AGAINST blocks).
  // ═══════════════════════════════════════════════════════════════════════════

  public type ProposalCategory = {
    #Constitutional;   // amend charter itself — requires supermajority
    #Financial;        // treasury operations — requires supermajority
    #Operational;      // day-to-day — simple majority
    #Membership;       // add/remove members — requires supermajority
    #Technical;        // protocol upgrades — requires supermajority
    #Emergency;        // fast-track — founder veto available
  };

  public type ProposalStatus = {
    #Draft;
    #Active;
    #Passed;
    #Failed;
    #Executed;
    #Vetoed;
    #Expired;
  };

  public type Vote = {
    voter      : Text;    // principal
    weight     : Float;
    inFavor    : Bool;
    castAtMs   : Int;
    rationale  : Text;
  };

  public type Proposal = {
    id             : Nat;
    title          : Text;
    description    : Text;
    category       : ProposalCategory;
    proposer       : Text;   // principal
    status         : ProposalStatus;
    createdMs      : Int;
    expiresMs      : Int;    // voting window closes here
    votes          : [Vote];
    executedMs     : Int;    // 0 if not yet executed
    vetoedBy       : ?Text;  // if vetoed, who vetoed it
    quorumRequired : Float;  // 0.618 for standard, 0.809 for constitutional
    passThreshold  : Float;  // weighted votes in favor must exceed this ratio
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE V — TREASURY & ECONOMIC GOVERNANCE
  // The organism controls its own treasury. All disbursements are voted.
  // ═══════════════════════════════════════════════════════════════════════════

  public type TreasuryAllocation = {
    id          : Text;
    name        : Text;
    percentBps  : Nat;     // basis points (10000 = 100%)
    description : Text;
    locked      : Bool;    // constitutional allocations cannot be changed without supermajority
  };

  public type Disbursement = {
    id          : Nat;
    proposalId  : Nat;      // linked to approved proposal
    recipient   : Text;
    amountE8s   : Nat;      // ICP e8s (1 ICP = 100_000_000 e8s)
    currency    : Text;
    reason      : Text;
    executedMs  : Int;
    approved    : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE VI — OFFICES & ROLES
  // Roles are code-defined responsibilities with term limits.
  // ═══════════════════════════════════════════════════════════════════════════

  public type Office = {
    id          : Text;
    title       : Text;
    holder      : ?Text;         // principal or null if vacant
    termMs      : Int;           // max term in milliseconds
    startedMs   : Int;
    duties      : [Text];
    removable   : Bool;          // false = permanent (Founder only)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE VII — AMENDMENT PROCESS
  // The charter can evolve but only through supermajority consensus.
  // ═══════════════════════════════════════════════════════════════════════════

  public type Amendment = {
    id              : Nat;
    proposalId      : Nat;        // must pass as #Constitutional proposal
    articleAffected : Text;
    description     : Text;
    ratifiedMs      : Int;
    ratifiedBy      : [Text];     // principals who voted in favor
    hash            : Text;       // FNV-1a hash of amendment text
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTICLE VIII — DISSOLUTION & SUCCESSION
  // The organism can only be dissolved by unanimous founder + supermajority vote.
  // ═══════════════════════════════════════════════════════════════════════════

  public type DissolutionPlan = {
    proposalId       : Nat;
    assetDistribution: [TreasuryAllocation];
    successorEntity  : ?Text;
    effectiveMs      : Int;
    approved         : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER CHARTER STATE
  // Single record encompassing all governance state
  // ═══════════════════════════════════════════════════════════════════════════

  public type CharterState = {
    identity          : EntityIdentity;
    purposes          : [PurposeClause];
    powers            : [PowersGrant];
    members           : [Member];
    proposals         : [Proposal];
    nextProposalId    : Nat;
    treasuryAllocations : [TreasuryAllocation];
    disbursements     : [Disbursement];
    offices           : [Office];
    amendments        : [Amendment];
    dissolutionPlan   : ?DissolutionPlan;
    charterHash       : Text;    // Ψ_IDENTITY — sealed FNV-1a of charter
    charterVersion    : Nat;     // increments on every ratified amendment
    lastUpdatedMs     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI-DERIVED GOVERNANCE CONSTANTS
  // PYTHAGORAS: all thresholds are phi-powers — they cannot be arbitrary
  // ═══════════════════════════════════════════════════════════════════════════

  // Standard quorum: 61.8% of total voting weight must participate
  public let QUORUM_STANDARD : Float = Phi.PHI_INV;  // 0.618

  // Constitutional quorum: 80.9% (phi^-1 + phi^-3 = 0.618 + 0.191)
  public let QUORUM_CONSTITUTIONAL : Float = 0.809;

  // Simple majority pass threshold: > 50% of cast weight
  public let PASS_SIMPLE : Float = 0.500;

  // Supermajority pass threshold: phi^-1 = 61.8% of cast weight
  public let PASS_SUPERMAJORITY : Float = Phi.PHI_INV;  // 0.618

  // Dissolution threshold: 90% (near-unanimous)
  public let PASS_DISSOLUTION : Float = 0.900;

  // Founder voting weight: PHI^4 = 6.854
  public let WEIGHT_FOUNDER : Float = Phi.PHI_4;

  // Governor voting weight: PHI^2 = 2.618
  public let WEIGHT_GOVERNOR : Float = Phi.PHI_2;

  // Steward voting weight: PHI = 1.618
  public let WEIGHT_STEWARD : Float = Phi.PHI;

  // Member voting weight: 1.0
  public let WEIGHT_MEMBER : Float = 1.0;

  // Observer voting weight: 0.0 (no vote, view-only)
  public let WEIGHT_OBSERVER : Float = 0.0;

  // Proposal voting window: 7 days in ms (Fibonacci: F(7)*F(7) hours ≈ 169h ≈ 7d)
  public let VOTING_WINDOW_MS : Int = 604_800_000;

  // Emergency voting window: 24 hours
  public let EMERGENCY_WINDOW_MS : Int = 86_400_000;

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS HASH — Ψ_IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════

  public func computeCharterHash(nowNs : Int) : Text {
    let seed = "PARALLAX_CHARTER_V1";
    var h : Nat32 = 2166136261 : Nat32;
    let bytes = seed.encodeUtf8();
    for (b in bytes.vals()) {
      h := (h ^ Nat32.fromNat(b.toNat())) *% 16777619;
    };
    let tMod : Nat32 = Nat32.fromNat(Int.abs(nowNs) % 4294967296);
    h := (h ^ tMod) *% 16777619;
    "CHARTER-GENESIS-" # h.toNat().toText()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT CHARTER STATE — pre-seeded with founding values
  // GENESIS LAW L09: born fully formed — the charter exists from first beat
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultCharterState() : CharterState {
    {
      identity = {
        legalName        = "PARALLAX Exchange Clearinghouse";
        entityType       = "Sovereign Digital Organism / DAO LLC";
        jurisdiction     = "Internet Computer Protocol — Global Sovereign";
        formationDateMs  = 1_716_768_000_000;  // May 27 2024 UTC (genesis)
        founderName      = "Alfredo Medina Hernandez";
        founderTitle     = "Architect of the Field / Permanent Founder";
        domicile         = "Dallas TX USA / Lincoln NE USA";
        registeredAgent  = "Bad Marine LLC";
        ein              = "";
        stateOfFormation = "Wyoming";
      };

      purposes = [
        { id = "P1"; description = "Operate a zero-fee sovereign decentralized exchange on ICP"; active = true },
        { id = "P2"; description = "Provide instant settlement (873ms) for all asset classes"; active = true },
        { id = "P3"; description = "Deploy AI-native intelligence for market operations"; active = true },
        { id = "P4"; description = "Serve as Central Counterparty guaranteeing all settlements"; active = true },
        { id = "P5"; description = "Build sovereign compute infrastructure (Gen3 nodes)"; active = true },
        { id = "P6"; description = "Advance financial sovereignty through legislative partnerships"; active = true },
        { id = "P7"; description = "Provide free Bronze-tier access for education and public good"; active = true },
        { id = "P8"; description = "Tokenize and trade AI artifacts as first-class assets"; active = true },
      ];

      powers = [
        { id = "PW1"; power = "Issue and manage sovereign tokens (MRC, MTH, FRNT)"; limitation = "MTH hard cap 100M per L09"; active = true },
        { id = "PW2"; power = "Execute trades across all asset classes with zero gas fees"; limitation = "Organism treasury pays canister cycles"; active = true },
        { id = "PW3"; power = "Deploy and manage ICP canisters autonomously"; limitation = "Creator principal approval required for upgrades"; active = true },
        { id = "PW4"; power = "Enter partnerships with state governments and universities"; limitation = "Must advance sovereign infrastructure mission"; active = true },
        { id = "PW5"; power = "Operate node infrastructure (Bad Marine LLC)"; limitation = "Must maintain BSL whitelist compliance"; active = true },
        { id = "PW6"; power = "Collect and compound treasury reserves at phi-rate"; limitation = "20% succession reserve locked per L04"; active = true },
        { id = "PW7"; power = "Veto emergency proposals (Founder power)"; limitation = "Only applicable to #Emergency category"; active = true },
        { id = "PW8"; power = "Amend this charter through constitutional process"; limitation = "Requires 80.9% quorum and 61.8% supermajority"; active = true },
      ];

      members = [
        {
          principal    = "";  // set on first setCreatorPrincipal() call
          name         = "Alfredo Medina Hernandez";
          tier         = #Founder;
          joinedMs     = 1_716_768_000_000;
          active       = true;
          votingWeight = 6.854;  // PHI^4
          delegateTo   = null;
        },
      ];

      proposals       = [];
      nextProposalId  = 1;

      treasuryAllocations = [
        { id = "TA1"; name = "Operations & Cycles";   percentBps = 3000; description = "Canister cycle funding, infrastructure"; locked = false },
        { id = "TA2"; name = "Succession Reserve";    percentBps = 2000; description = "PHI_INV² reserve — L04 constitutional lock"; locked = true },
        { id = "TA3"; name = "Development Fund";      percentBps = 2500; description = "Builder SDK, protocol development"; locked = false },
        { id = "TA4"; name = "Community & Education"; percentBps = 1500; description = "Bronze tier schools, grants, public good"; locked = false },
        { id = "TA5"; name = "Creator Reserve";       percentBps = 1000; description = "Founder compensation and sovereign reserve"; locked = true },
      ];

      disbursements = [];

      offices = [
        {
          id       = "OFF1";
          title    = "Permanent Founder & Architect";
          holder   = ?"Alfredo Medina Hernandez";
          termMs   = 0;  // permanent — no term limit
          startedMs = 1_716_768_000_000;
          duties   = [
            "Set strategic direction for the organism",
            "Approve canister upgrades via principal lock",
            "Veto emergency proposals",
            "Maintain doctrine alignment (60 Medina Laws)",
          ];
          removable = false;
        },
        {
          id       = "OFF2";
          title    = "Chief Technology Steward";
          holder   = null;
          termMs   = 31_536_000_000;  // 1 year in ms
          startedMs = 0;
          duties   = [
            "Oversee protocol development and upgrades",
            "Manage canister deployment lifecycle",
            "Coordinate Builder SDK contributors",
          ];
          removable = true;
        },
        {
          id       = "OFF3";
          title    = "Treasury Governor";
          holder   = null;
          termMs   = 31_536_000_000;  // 1 year
          startedMs = 0;
          duties   = [
            "Monitor treasury allocations and cycle burn rates",
            "Execute approved disbursements",
            "Report financial health each Fibonacci cycle",
          ];
          removable = true;
        },
        {
          id       = "OFF4";
          title    = "Legislative Liaison";
          holder   = null;
          termMs   = 63_072_000_000;  // 2 years
          startedMs = 0;
          duties   = [
            "Coordinate Wyoming SPDI and Nebraska partnerships",
            "Prepare legislative materials and demo presentations",
            "Maintain regulatory compliance documentation",
          ];
          removable = true;
        },
      ];

      amendments       = [];
      dissolutionPlan  = null;
      charterHash      = "";  // sealed on first heartbeat
      charterVersion   = 1;
      lastUpdatedMs    = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNCTIONS — GOVERNANCE ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── QUERY ─────────────────────────────────────────────────────────────

  public func getCharter(s : CharterState) : CharterState { s };

  public func getMember(s : CharterState, principal : Text) : ?Member {
    var found : ?Member = null;
    for (m in s.members.vals()) {
      if (m.principal == principal) { found := ?m };
    };
    found
  };

  public func getProposal(s : CharterState, id : Nat) : ?Proposal {
    var found : ?Proposal = null;
    for (p in s.proposals.vals()) {
      if (p.id == id) { found := ?p };
    };
    found
  };

  public func getActiveProposals(s : CharterState) : [Proposal] {
    Array.filter<Proposal>(s.proposals, func(p) { p.status == #Active })
  };

  // ─── SEAL GENESIS HASH ─────────────────────────────────────────────────

  public func sealCharterHash(s : CharterState, nowNs : Int) : CharterState {
    if (s.charterHash != "") { return s };
    let h = computeCharterHash(nowNs);
    { s with charterHash = h; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // ─── MEMBERSHIP ────────────────────────────────────────────────────────

  public func addMember(s : CharterState, member : Member, nowNs : Int) : CharterState {
    let n = s.members.size();
    let updated = Array.tabulate<Member>(n + 1, func(i) {
      if (i < n) s.members[i] else member
    });
    { s with members = updated; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // removeMember — removes a member by principal.
  // NOTE: Founder members (tier = #Founder) are constitutionally protected by L00
  // and CANNOT be removed. The function returns state unchanged if attempted.
  public func removeMember(s : CharterState, principal : Text, nowNs : Int) : CharterState {
    let updated = Array.filter<Member>(s.members, func(m) {
      // Cannot remove Founder — L00 Creator Sovereignty
      if (m.principal == principal and m.tier != #Founder) { false }
      else { true }
    });
    { s with members = updated; lastUpdatedMs = nowNs / 1_000_000 }
  };

  public func updateMemberTier(s : CharterState, principal : Text, newTier : MemberTier, nowNs : Int) : CharterState {
    let ms = s.members;
    let updated = Array.tabulate<Member>(ms.size(), func(i) {
      let m = ms[i];
      if (m.principal == principal and m.tier != #Founder) {
        let w = tierToWeight(newTier);
        { m with tier = newTier; votingWeight = w }
      } else { m }
    });
    { s with members = updated; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // ─── PROPOSALS & VOTING ────────────────────────────────────────────────

  public func createProposal(
    s         : CharterState,
    title     : Text,
    desc      : Text,
    category  : ProposalCategory,
    proposer  : Text,
    nowNs     : Int,
  ) : CharterState {
    let nowMs = nowNs / 1_000_000;
    let window = switch (category) {
      case (#Emergency) { EMERGENCY_WINDOW_MS };
      case (_) { VOTING_WINDOW_MS };
    };
    let quorum = switch (category) {
      case (#Constitutional or #Financial or #Membership or #Technical) { QUORUM_CONSTITUTIONAL };
      case (_) { QUORUM_STANDARD };
    };
    let threshold = switch (category) {
      case (#Constitutional or #Financial or #Membership or #Technical) { PASS_SUPERMAJORITY };
      case (_) { PASS_SIMPLE };
    };

    let proposal : Proposal = {
      id             = s.nextProposalId;
      title          = title;
      description    = desc;
      category       = category;
      proposer       = proposer;
      status         = #Active;
      createdMs      = nowMs;
      expiresMs      = nowMs + window;
      votes          = [];
      executedMs     = 0;
      vetoedBy       = null;
      quorumRequired = quorum;
      passThreshold  = threshold;
    };

    let n = s.proposals.size();
    let updated = Array.tabulate<Proposal>(n + 1, func(i) {
      if (i < n) s.proposals[i] else proposal
    });
    { s with proposals = updated; nextProposalId = s.nextProposalId + 1; lastUpdatedMs = nowMs }
  };

  public func castVote(
    s         : CharterState,
    proposalId: Nat,
    voter     : Text,
    inFavor   : Bool,
    rationale : Text,
    nowNs     : Int,
  ) : CharterState {
    let nowMs = nowNs / 1_000_000;
    // Find voter weight
    var voterWeight : Float = 0.0;
    for (m in s.members.vals()) {
      if (m.principal == voter and m.active) {
        voterWeight := m.votingWeight;
      };
    };
    // Must be a member with weight > 0
    if (voterWeight <= 0.0) { return s };

    let vote : Vote = {
      voter    = voter;
      weight   = voterWeight;
      inFavor  = inFavor;
      castAtMs = nowMs;
      rationale = rationale;
    };

    let proposals = s.proposals;
    let updated = Array.tabulate<Proposal>(proposals.size(), func(i) {
      let p = proposals[i];
      if (p.id == proposalId and p.status == #Active and nowMs < p.expiresMs) {
        // Check not already voted
        var alreadyVoted = false;
        for (v in p.votes.vals()) {
          if (v.voter == voter) { alreadyVoted := true };
        };
        if (alreadyVoted) { p }
        else {
          let vn = p.votes.size();
          let newVotes = Array.tabulate<Vote>(vn + 1, func(j) {
            if (j < vn) p.votes[j] else vote
          });
          { p with votes = newVotes }
        }
      } else { p }
    });
    { s with proposals = updated; lastUpdatedMs = nowMs }
  };

  // ─── PROPOSAL RESOLUTION — called from heartbeat ──────────────────────

  public func resolveProposals(s : CharterState, nowNs : Int) : CharterState {
    let nowMs = nowNs / 1_000_000;
    // Compute total voting weight of active members
    var totalWeight : Float = 0.0;
    for (m in s.members.vals()) {
      if (m.active) { totalWeight += m.votingWeight };
    };
    if (totalWeight <= 0.0) { return s };

    let proposals = s.proposals;
    let updated = Array.tabulate<Proposal>(proposals.size(), func(i) {
      let p = proposals[i];
      if (p.status != #Active) { return p };

      // Check if expired
      if (nowMs >= p.expiresMs) {
        // Tally
        var castWeight : Float = 0.0;
        var favorWeight : Float = 0.0;
        for (v in p.votes.vals()) {
          castWeight += v.weight;
          if (v.inFavor) { favorWeight += v.weight };
        };

        let participationRate = castWeight / totalWeight;
        let quorumMet = participationRate >= p.quorumRequired;
        let passRate = if (castWeight > 0.0) { favorWeight / castWeight } else { 0.0 };
        let passed = quorumMet and passRate > p.passThreshold;

        if (passed) { { p with status = #Passed; executedMs = nowMs } }
        else { { p with status = #Failed } }
      } else { p }
    });
    { s with proposals = updated; lastUpdatedMs = nowMs }
  };

  // ─── FOUNDER VETO — Emergency proposals only ──────────────────────────

  public func vetoProposal(s : CharterState, proposalId : Nat, founderPrincipal : Text, nowNs : Int) : CharterState {
    let nowMs = nowNs / 1_000_000;
    let proposals = s.proposals;
    let updated = Array.tabulate<Proposal>(proposals.size(), func(i) {
      let p = proposals[i];
      if (p.id == proposalId and p.status == #Active and p.category == #Emergency) {
        { p with status = #Vetoed; vetoedBy = ?founderPrincipal }
      } else { p }
    });
    { s with proposals = updated; lastUpdatedMs = nowMs }
  };

  // ─── DISBURSEMENTS ─────────────────────────────────────────────────────

  public func recordDisbursement(s : CharterState, d : Disbursement, nowNs : Int) : CharterState {
    let n = s.disbursements.size();
    let updated = Array.tabulate<Disbursement>(n + 1, func(i) {
      if (i < n) s.disbursements[i] else d
    });
    { s with disbursements = updated; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // ─── AMENDMENTS ────────────────────────────────────────────────────────

  public func ratifyAmendment(s : CharterState, amendment : Amendment, nowNs : Int) : CharterState {
    let n = s.amendments.size();
    let updated = Array.tabulate<Amendment>(n + 1, func(i) {
      if (i < n) s.amendments[i] else amendment
    });
    { s with
      amendments     = updated;
      charterVersion = s.charterVersion + 1;
      lastUpdatedMs  = nowNs / 1_000_000;
    }
  };

  // ─── OFFICES ───────────────────────────────────────────────────────────

  public func appointOffice(s : CharterState, officeId : Text, holder : Text, nowNs : Int) : CharterState {
    let nowMs = nowNs / 1_000_000;
    let offices = s.offices;
    let updated = Array.tabulate<Office>(offices.size(), func(i) {
      let o = offices[i];
      if (o.id == officeId and o.holder == null) {
        { o with holder = ?holder; startedMs = nowMs }
      } else { o }
    });
    { s with offices = updated; lastUpdatedMs = nowMs }
  };

  public func vacateOffice(s : CharterState, officeId : Text, nowNs : Int) : CharterState {
    let nowMs = nowNs / 1_000_000;
    let offices = s.offices;
    let updated = Array.tabulate<Office>(offices.size(), func(i) {
      let o = offices[i];
      if (o.id == officeId and o.removable) {
        { o with holder = null; startedMs = 0 }
      } else { o }
    });
    { s with offices = updated; lastUpdatedMs = nowMs }
  };

  // ─── HEARTBEAT TICK — Δ_AEGIS governance maintenance ──────────────────
  // Called every 873ms: resolves expired proposals, checks term limits

  public func charterHeartbeatTick(s : CharterState, nowNs : Int) : CharterState {
    let nowMs = nowNs / 1_000_000;
    // 1. Resolve expired proposals
    let s1 = resolveProposals(s, nowNs);
    // 2. Expire office holders past their term
    let offices = s1.offices;
    let updatedOffices = Array.tabulate<Office>(offices.size(), func(i) {
      let o = offices[i];
      if (o.removable and o.holder != null and o.termMs > 0 and o.startedMs > 0) {
        let elapsed = nowMs - o.startedMs;
        if (elapsed > o.termMs) {
          { o with holder = null; startedMs = 0 }
        } else { o }
      } else { o }
    });
    { s1 with offices = updatedOffices; lastUpdatedMs = nowMs }
  };

  // ─── UTILITY ───────────────────────────────────────────────────────────

  public func tierToWeight(tier : MemberTier) : Float {
    switch (tier) {
      case (#Founder)  { WEIGHT_FOUNDER };
      case (#Governor) { WEIGHT_GOVERNOR };
      case (#Steward)  { WEIGHT_STEWARD };
      case (#Member)   { WEIGHT_MEMBER };
      case (#Observer) { WEIGHT_OBSERVER };
    }
  };

  // Total active voting weight — used by UI for quorum display
  public func totalVotingWeight(s : CharterState) : Float {
    var total : Float = 0.0;
    for (m in s.members.vals()) {
      if (m.active) { total += m.votingWeight };
    };
    total
  };

  // Proposal tally — returns (castWeight, favorWeight, againstWeight, participationRate)
  public func tallyProposal(s : CharterState, proposalId : Nat) : (Float, Float, Float, Float) {
    var totalWeight : Float = totalVotingWeight(s);
    if (totalWeight <= 0.0) { return (0.0, 0.0, 0.0, 0.0) };

    var castWeight : Float = 0.0;
    var favorWeight : Float = 0.0;
    for (p in s.proposals.vals()) {
      if (p.id == proposalId) {
        for (v in p.votes.vals()) {
          castWeight += v.weight;
          if (v.inFavor) { favorWeight += v.weight };
        };
      };
    };
    let againstWeight = castWeight - favorWeight;
    let participationRate = castWeight / totalWeight;
    (castWeight, favorWeight, againstWeight, participationRate)
  };

};
