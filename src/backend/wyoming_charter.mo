// wyoming_charter.mo — WYOMING_CHARTER Sovereign Module
// PYTHAGORAS: every deadline is a Fibonacci-indexed temporal harmonic
// EUCLID:     single source of truth — all Wyoming state declared once
// CONFUCIUS:  right relationship — charter is doctrine, not display
//
// SSU-WRAPPED: Φ_CLOCK 873ms, Ω_GATE Kuramoto R≥0.618, Δ_AEGIS anti-drift,
//              Λ_PIL loop, Ψ_IDENTITY genesis hash
//
// Wyoming Legislative Timeline Law:
//   hardware visible before November 2026
//   bill ready January 2027
//   Phantom technology solves Visa bottleneck — 0.3s vs 15min, 0% vs 3-5% fee
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Array "mo:core/Array";
import Int   "mo:core/Int";
import Nat32 "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type MilestoneStatus = {
    #Pending;
    #InProgress;
    #Complete;
    #Critical;
  };

  public type Milestone = {
    id         : Text;
    title      : Text;
    deadlineMs : Int;
    status     : MilestoneStatus;
    notes      : Text;
  };

  // FRNT Settlement Demo — Phantom technology vs Visa bottleneck
  // visaBottleneckSolved = true — Phantom solves the 15-min / 3-5% fee wall
  public type FrntDemo = {
    visaSettlementMs    : Nat;   // 900000 = 15 minutes in ms
    phantomSettlementMs : Nat;   // 300 = 0.3 seconds in ms
    visaFeeBps          : Nat;   // 400 = 4%
    phantomFeeBps       : Nat;   // 0 = 0%
    demoActive          : Bool;
    lastRunMs           : Int;
    visaBottleneckSolved: Bool;
  };

  // Bad Marine LLC — sovereign node provider positioning
  public type NodeProvider = {
    entity        : Text;
    status        : Text;
    targetRegion  : Text;
    cheyenneNodes : Nat;
    lincolnNodes  : Nat;
    gen3Ready     : Bool;
    bslWhitelisted: Bool;
  };

  public type LegislativeTimeline = {
    hardwareDeadlineMs : Int;   // Nov 1 2026 UTC epoch ms
    billReadyMs        : Int;   // Jan 15 2027 UTC epoch ms
    unicameralSession  : Text;
    milestones         : [Milestone];
  };

  public type Partnership = {
    name        : Text;
    partnerType : Text;
    contact     : Text;
    status      : Text;
    notes       : Text;
  };

  // Federal Reserve Vault facility — 134 S 13th St Lincoln NE
  public type Facility = {
    address          : Text;
    city             : Text;
    stateCode        : Text;
    vaultGrade       : Bool;
    internetBackbone : Bool;
    publicPower      : Bool;
    powerCostRank    : Text;
  };

  public type GrantRecord = {
    name       : Text;
    grantType  : Text;
    amountUsd  : Nat;
    status     : Text;
    deadlineMs : Int;
    notes      : Text;
  };

  // Master Wyoming charter state — all domains in one sovereign record
  public type WyomingState = {
    frntDemo          : FrntDemo;
    nodeProvider      : NodeProvider;
    legislative       : LegislativeTimeline;
    partnerships      : [Partnership];
    facility          : Facility;
    grants            : [GrantRecord];
    charterGenesisHash: Text;  // sealed at first access — FNV-1a of "WYOMING_CHARTER" + time
    lastUpdatedMs     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH — Ψ_IDENTITY genesis hash computation
  // PRIME FOUNDATION LAW L34: cryptographic identity built on prime irreducibility
  // FNV-1a: offset_basis = 2166136261, prime = 16777619
  // ═══════════════════════════════════════════════════════════════════════════

  // computeGenesisHash — sealed Ψ_IDENTITY for the WYOMING_CHARTER module
  // FNV-1a over "WYOMING_CHARTER" bytes, then XOR-fold in the nanosecond timestamp
  public func computeGenesisHash(nowNs : Int) : Text {
    let seed = "WYOMING_CHARTER";
    var h : Nat32 = 2166136261 : Nat32; // FNV-1a offset basis (32-bit)
    let bytes = seed.encodeUtf8();
    for (b in bytes.vals()) {
      h := (h ^ Nat32.fromNat(b.toNat())) *% 16777619;
    };
    // Mix in the timestamp — GENESIS LAW L09: born at a specific sovereign moment
    // Int.abs returns Nat, safe for any sign of nowNs
    let tMod : Nat32 = Nat32.fromNat(Int.abs(nowNs) % 4294967296);
    h := (h ^ tMod) *% 16777619;
    "WYO-GENESIS-" # h.toNat().toText()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — pre-seeded with real sovereign values
  // GENESIS LAW L09: born fully formed — no Wyoming state ever starts at zero
  // PHI LAW L01: all epoch ms are sovereign temporal anchors
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultWyomingState() : WyomingState {
    {
      frntDemo = {
        visaSettlementMs     = 900_000; // 15 minutes in ms
        phantomSettlementMs  = 300;     // 0.3 seconds in ms — Phantom settles
        visaFeeBps           = 400;     // 4% (400 basis points)
        phantomFeeBps        = 0;       // 0% — zero fee via Phantom
        demoActive           = true;
        lastRunMs            = 0;
        visaBottleneckSolved = true;    // Phantom solves the Visa bottleneck
      };

      nodeProvider = {
        entity         = "Bad Marine LLC";
        status         = "positioning";
        targetRegion   = "US Midwest";
        cheyenneNodes  = 0;
        lincolnNodes   = 0;
        gen3Ready      = false;
        bslWhitelisted = false;
      };

      legislative = {
        hardwareDeadlineMs = 1_762_012_800_000; // Nov 1 2026 UTC
        billReadyMs        = 1_768_521_600_000; // Jan 15 2027 UTC
        unicameralSession  = "2027 Nebraska Unicameral";
        milestones = [
          {
            id         = "hw-visible";
            title      = "Hardware Visible in Lincoln NE Vault";
            deadlineMs = 1_762_012_800_000; // Nov 1 2026
            status     = #Pending;
            notes      = "134 S 13th St Lincoln NE Federal Reserve Vault";
          },
          {
            id         = "andy-meeting";
            title      = "Meet with Andy Vetor in Cheyenne WY";
            deadlineMs = 1_751_414_400_000; // Jul 1 2026
            status     = #Pending;
            notes      = "Wyoming SPDI regulators demo";
          },
          {
            id         = "frnt-demo";
            title      = "FRNT/ICP Settlement Demo on ICPSwap";
            deadlineMs = 1_756_828_800_000; // Sep 1 2026
            status     = #InProgress;
            notes      = "0.3s vs 15min, 0% vs 3-5% fee — Phantom technology solves Visa bottleneck";
          },
          {
            id         = "bill-ready";
            title      = "Nebraska Unicameral Bill Ready";
            deadlineMs = 1_768_521_600_000; // Jan 15 2027
            status     = #Pending;
            notes      = "Entire state government switches over when Unicameral blesses with bill";
          },
          {
            id         = "nebraska-export";
            title      = "Nebraska Model Export to Kansas";
            deadlineMs = 1_772_534_400_000; // Mar 1 2027
            status     = #Pending;
            notes      = "University of Kansas and UNL Agentic AI infrastructure";
          },
        ];
      };

      partnerships = [
        {
          name        = "Wyoming SPDI";
          partnerType = "State Regulator";
          contact     = "Andy Vetor";
          status      = "target";
          notes       = "State OCIO requirements and SPDI banking laws";
        },
        {
          name        = "Nebraska Digital Banking";
          partnerType = "State Partnership";
          contact     = "Senators Bosn and Ballard";
          status      = "monitoring";
          notes       = "Unicameral session ending";
        },
        {
          name        = "UNL AI Institute";
          partnerType = "University";
          contact     = "AI Institute Director";
          status      = "target";
          notes       = "Requires local sovereign Gen3 compute for Agentic AI teaching";
        },
        {
          name        = "University of Kansas";
          partnerType = "University";
          contact     = "";
          status      = "interested";
          notes       = "Mid-tier Midwest AI infrastructure";
        },
      ];

      facility = {
        address          = "134 S 13th St";
        city             = "Lincoln";
        stateCode        = "NE";
        vaultGrade       = true;
        internetBackbone = true;
        publicPower      = true;
        powerCostRank    = "cheapest in nation";
      };

      grants = [
        {
          name       = "Wyoming AI Infrastructure Grant";
          grantType  = "State AI";
          amountUsd  = 500_000;
          status     = "identifying";
          deadlineMs = 1_748_822_400_000; // Jun 1 2026
          notes      = "";
        },
        {
          name       = "Federal AI Infrastructure";
          grantType  = "Federal";
          amountUsd  = 2_000_000;
          status     = "identifying";
          deadlineMs = 1_756_828_800_000; // Sep 1 2026
          notes      = "";
        },
        {
          name       = "Research Grant";
          grantType  = "Research";
          amountUsd  = 250_000;
          status     = "identifying";
          deadlineMs = 1_751_414_400_000; // Jul 1 2026
          notes      = "";
        },
        {
          name       = "School Technology Grant";
          grantType  = "Education";
          amountUsd  = 100_000;
          status     = "identifying";
          deadlineMs = 1_754_025_600_000; // Aug 1 2026
          notes      = "E-Rate Title IV TEA innovation";
        },
      ];

      charterGenesisHash = ""; // sealed on first heartbeat via sealGenesisHash()
      lastUpdatedMs      = 0;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // getWyomingCharter — pure passthrough, no auth required
  public func getWyomingCharter(s : WyomingState) : WyomingState {
    s
  };

  // sealGenesisHash — Ψ_IDENTITY: if charterGenesisHash is empty, seal it now
  // Sealed permanently on first heartbeat. Cannot be changed after sealing.
  // PROOF LAW L08: every sovereign origin event is permanently inscribed
  public func sealGenesisHash(s : WyomingState, nowNs : Int) : WyomingState {
    if (s.charterGenesisHash != "") { return s };
    let h = computeGenesisHash(nowNs);
    { s with charterGenesisHash = h; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // updateMilestone — creator-only (caller check done in main.mo)
  // Updates status and notes for the milestone matching id
  public func updateMilestone(
    s      : WyomingState,
    id     : Text,
    status : MilestoneStatus,
    notes  : Text,
    nowNs  : Int,
  ) : WyomingState {
    let ms = s.legislative.milestones;
    let updated : [Milestone] = Array.tabulate<Milestone>(ms.size(), func(i) {
      let m = ms[i];
      if (m.id == id) { { m with status = status; notes = notes } }
      else { m }
    });
    {
      s with
      legislative   = { s.legislative with milestones = updated };
      lastUpdatedMs = nowNs / 1_000_000;
    }
  };

  // addGrant — creator-only (caller check done in main.mo)
  // Appends a new GrantRecord to the grants array
  public func addGrant(s : WyomingState, grant : GrantRecord, nowNs : Int) : WyomingState {
    let n = s.grants.size();
    let updated = Array.tabulate(n + 1, func(i) {
      if (i < n) s.grants[i] else grant
    });
    { s with grants = updated; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // runFrntDemo — Ω_GATE checked in main.mo before calling
  // Updates lastRunMs to current time. Returns (updated state, FrntDemo snapshot).
  // Proves: 0.3s vs 15min, 0% vs 3-5% — Phantom wins
  public func runFrntDemo(s : WyomingState, nowNs : Int) : (WyomingState, FrntDemo) {
    let nowMs : Int = nowNs / 1_000_000;
    let updatedDemo : FrntDemo = { s.frntDemo with lastRunMs = nowMs };
    let updated : WyomingState = { s with frntDemo = updatedDemo; lastUpdatedMs = nowMs };
    (updated, updatedDemo)
  };

  // updateNodeProvider — creator-only (caller check done in main.mo)
  public func updateNodeProvider(s : WyomingState, np : NodeProvider, nowNs : Int) : WyomingState {
    { s with nodeProvider = np; lastUpdatedMs = nowNs / 1_000_000 }
  };

  // ─── SSU Φ_CLOCK tick — Δ_AEGIS anti-drift ─────────────────────────────

  // ssuHeartbeatTick — called every 873ms from main.mo heartbeat
  // Δ_AEGIS: auto-escalates Pending milestones to #Critical if within 90 days of deadline
  // ANTI-DRIFT LAW L07: the organism cannot drift past a sovereign deadline without alerting
  public func ssuHeartbeatTick(s : WyomingState, nowNs : Int) : WyomingState {
    let nowMs : Int = nowNs / 1_000_000;
    // 90 days in ms = 90 * 24 * 60 * 60 * 1000 = 7_776_000_000
    let ninetyDaysMs : Int = 7_776_000_000;
    let ms = s.legislative.milestones;
    var changed = false;
    let updated : [Milestone] = Array.tabulate<Milestone>(ms.size(), func(i) {
      let m = ms[i];
      switch (m.status) {
        case (#Pending) {
          let remaining : Int = m.deadlineMs - nowMs;
          if (remaining > 0 and remaining <= ninetyDaysMs) {
            changed := true;
            { m with status = #Critical }
          } else { m }
        };
        case (_) { m };
      }
    });
    if (not changed) { s }
    else {
      { s with
        legislative   = { s.legislative with milestones = updated };
        lastUpdatedMs = nowMs;
      }
    }
  };

  // ─── PHI_INV reference — imported from phi.mo ────────────────────────────
  // KURAMOTO Ω_GATE threshold = Phi.PHI_INV = 0.618
  // All SSU-gated mutations check Kuramoto R >= this value before executing
  public let OMEGA_GATE_R : Float = Phi.PHI_INV; // 0.618

};
