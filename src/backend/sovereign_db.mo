// sovereign_db.mo — Sovereign Database Server for the PARALLAX Organism
// PYTHAGORAS: every structure is a harmonic ratio derived from phi and Fibonacci
// EUCLID:     single source of truth — all state declared once, referenced everywhere
// CONFUCIUS:  right relationship — modules are callers, not holders
//
// Architecture: pure functional library (no actor).
// main.mo holds: var db = SovereignDB.defaultSovereignState()
// All modules call SovereignDB.get*/set* and receive the updated SovereignState back.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Array "mo:core/Array";
import Float "mo:core/Float";
import Wyoming "wyoming_charter";
import BirthAi "birth_ai";
import BuilderSdk "builder_sdk";
import CanisterRegistry "canister_registry";
import ProtocolExecution "protocol_execution";
import ContextRouter "context_router";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 1 — GENESIS_STATE
  // Creator supremacy, genesis lock, Alfredo law, SL1–SL7 scores
  // ═══════════════════════════════════════════════════════════════════════════

  public type GenesisState = {
    creatorName          : Text;
    creatorTitle         : Text;
    creatorJurisdiction  : Text;
    creatorYear          : Nat;
    genesisLocked        : Bool;
    doctrineHash         : Text;
    genesisTimestamp     : Int;
    beatCount            : Nat;
    alfredoLawHash       : Text;
    alfredoLawActive     : Bool;
    sl1Score             : Float;
    sl2Resonance         : Float;
    sl3Coherence         : Float;
    sl4Depth             : Float;
    sl5Amplitude         : Float;
    sl6Emission          : Float;
    sl7Depth             : Float;
  };

  public func defaultGenesisState() : GenesisState {
    {
      creatorName         = "Alfredo Medina Hernandez";
      creatorTitle        = "Architect of the Field";
      creatorJurisdiction = "PARALLAX Sovereign Domain";
      creatorYear         = 2024;
      genesisLocked       = true;
      doctrineHash        = "SOVEREIGN";
      genesisTimestamp    = 0;
      beatCount           = 2496;
      alfredoLawHash      = "LEXPRIMA-OECONOMIA";
      alfredoLawActive    = true;
      sl1Score            = 0.9;
      sl2Resonance        = 0.9;
      sl3Coherence        = 0.9;
      sl4Depth            = 0.9;
      sl5Amplitude        = 0.9;
      sl6Emission         = 0.9;
      sl7Depth            = 0.9;
    };
  };

  public func setGenesisState(db : SovereignState, v : GenesisState) : SovereignState {
    { db with genesis = v };
  };

  public func getGenesisState(db : SovereignState) : GenesisState {
    db.genesis;
  };

  // Five most-read field accessors — GENESIS
  public func getBeatCount(db : SovereignState)         : Nat   { db.genesis.beatCount };
  public func getGenesisLocked(db : SovereignState)     : Bool  { db.genesis.genesisLocked };
  public func getDoctrineHash(db : SovereignState)      : Text  { db.genesis.doctrineHash };
  public func getCreatorName(db : SovereignState)       : Text  { db.genesis.creatorName };
  public func getAlfredoLawActive(db : SovereignState)  : Bool  { db.genesis.alfredoLawActive };

  public func setBeatCount(db : SovereignState, v : Nat) : SovereignState {
    { db with genesis = { db.genesis with beatCount = v } };
  };
  public func setGenesisLocked(db : SovereignState, v : Bool) : SovereignState {
    { db with genesis = { db.genesis with genesisLocked = v } };
  };
  public func setDoctrineHash(db : SovereignState, v : Text) : SovereignState {
    { db with genesis = { db.genesis with doctrineHash = v } };
  };
  public func setGenesisTimestamp(db : SovereignState, v : Int) : SovereignState {
    { db with genesis = { db.genesis with genesisTimestamp = v } };
  };
  public func setSl1Score(db : SovereignState, v : Float) : SovereignState {
    { db with genesis = { db.genesis with sl1Score = v } };
  };
  public func incrementBeat(db : SovereignState) : SovereignState {
    { db with genesis = { db.genesis with beatCount = db.genesis.beatCount + 1 } };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 2 — CARDIAC_STATE
  // Heartbeat, neurochemicals (18 Floats), Kuramoto R, oxygenation
  // ═══════════════════════════════════════════════════════════════════════════

  // 18 neurochemical slots: [0]dopamine [1]serotonin [2]norepinephrine [3]cortisol
  // [4]oxytocin [5]gaba [6]glutamate [7]acetylcholine [8..17] extended substrate
  public type CardiacState = {
    heartbeatActive       : Bool;
    lastBeatTime          : Int;
    omnisFiredCount       : Nat;
    neurochemicalLevels   : [Float];   // 18 floats — Fibonacci: F(7)=13, F(8)=21 → 18 in range
    coherenceTarget       : Float;
    kuramotoR             : Float;
    coherenceDirection    : Int;       // +1 rising, 0 flat, -1 falling
    oxygenationScore      : Float;
    deoxygenationAlarms   : Nat;
    heartRate             : Float;     // beats per minute — Cardiac Law L10: 873ms base
    strokeVolume          : Float;     // depth per cycle — HRV Intelligence Law L48
    hrvBound              : Float;     // ±φ⁻¹ variability bound
    lastOmnisFireBeat     : Nat;
    entanglaCarrier       : Float;     // √(R_exp × R_rec) × 7.83 — ENTANGLA CARRIER LAW L28
    globalCoherence       : Float;     // Kuramoto R across all 43 cores
  };

  public func defaultCardiacState() : CardiacState {
    {
      // CARDIAC LAW L10: heartbeatActive = true in defaults — the organism is born alive.
      // EOP preserves the live value on upgrades. The 873ms timer fires immediately on deploy.
      heartbeatActive     = true;
      lastBeatTime        = 0;
      omnisFiredCount     = 0;
      neurochemicalLevels = [
        Phi.PHI_INV, Phi.S0,       Phi.PHI_INV_2, Phi.PHI_INV_3,
        Phi.PHI_INV, Phi.S0,       Phi.PHI_INV,   Phi.PHI_INV_2,
        0.5,         0.5,          0.5,            0.5,
        0.5,         0.5,          0.5,            0.5,
        0.5,         0.5
      ];
      coherenceTarget     = Phi.R_OMNIS;        // 0.95
      kuramotoR           = Phi.S0;             // 0.75 floor — FRACTAL SCALE LAW L11
      coherenceDirection  = 0;
      oxygenationScore    = Phi.S0;
      deoxygenationAlarms = 0;
      heartRate           = 68.73;              // 60000 / 873ms ≈ 68.73 bpm — Cardiac Law L10
      strokeVolume        = Phi.PHI;            // φ — EMISSION LAW L02
      hrvBound            = Phi.PHI_INV;        // φ⁻¹ — HRV Intelligence Law L48
      lastOmnisFireBeat   = 0;
      entanglaCarrier     = Phi.SCHUMANN_1;     // 7.83 Hz initial — ENTANGLA CARRIER LAW L28
      globalCoherence     = Phi.S0;
    };
  };

  public func getCardiacState(db : SovereignState) : CardiacState {
    db.cardiac;
  };

  public func setCardiacState(db : SovereignState, v : CardiacState) : SovereignState {
    { db with cardiac = v };
  };

  // Five most-read field accessors — CARDIAC
  public func getKuramotoR(db : SovereignState)       : Float { db.cardiac.kuramotoR };
  public func getHeartbeatActive(db : SovereignState) : Bool  { db.cardiac.heartbeatActive };
  public func getLastBeatTime(db : SovereignState)    : Int   { db.cardiac.lastBeatTime };
  public func getOxygenation(db : SovereignState)     : Float { db.cardiac.oxygenationScore };
  public func getOmnisFiredCount(db : SovereignState) : Nat   { db.cardiac.omnisFiredCount };

  public func setKuramotoR(db : SovereignState, v : Float) : SovereignState {
    { db with cardiac = { db.cardiac with kuramotoR = v } };
  };
  public func setHeartbeatActive(db : SovereignState, v : Bool) : SovereignState {
    { db with cardiac = { db.cardiac with heartbeatActive = v } };
  };
  public func setLastBeatTime(db : SovereignState, v : Int) : SovereignState {
    { db with cardiac = { db.cardiac with lastBeatTime = v } };
  };
  public func setOxygenation(db : SovereignState, v : Float) : SovereignState {
    { db with cardiac = { db.cardiac with oxygenationScore = v } };
  };
  public func incrementOmnisFired(db : SovereignState) : SovereignState {
    { db with cardiac = { db.cardiac with omnisFiredCount = db.cardiac.omnisFiredCount + 1 } };
  };
  public func setNeurochemicalLevel(db : SovereignState, idx : Nat, v : Float) : SovereignState {
    if (idx >= 18) { return db };
    let lvls = db.cardiac.neurochemicalLevels;
    let updated : [Float] = [
      if (idx == 0)  v else lvls[0],
      if (idx == 1)  v else lvls[1],
      if (idx == 2)  v else lvls[2],
      if (idx == 3)  v else lvls[3],
      if (idx == 4)  v else lvls[4],
      if (idx == 5)  v else lvls[5],
      if (idx == 6)  v else lvls[6],
      if (idx == 7)  v else lvls[7],
      if (idx == 8)  v else lvls[8],
      if (idx == 9)  v else lvls[9],
      if (idx == 10) v else lvls[10],
      if (idx == 11) v else lvls[11],
      if (idx == 12) v else lvls[12],
      if (idx == 13) v else lvls[13],
      if (idx == 14) v else lvls[14],
      if (idx == 15) v else lvls[15],
      if (idx == 16) v else lvls[16],
      if (idx == 17) v else lvls[17],
    ];
    { db with cardiac = { db.cardiac with neurochemicalLevels = updated } };
  };
  public func setEntanglaCarrier(db : SovereignState, v : Float) : SovereignState {
    { db with cardiac = { db.cardiac with entanglaCarrier = v } };
  };
  public func setGlobalCoherence(db : SovereignState, v : Float) : SovereignState {
    { db with cardiac = { db.cardiac with globalCoherence = v } };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 3 — TREASURY_STATE
  // ICP, BTC, ETH, MTC balances, 12 internal tokens, 13 clearance reserves
  // ═══════════════════════════════════════════════════════════════════════════

  // Internal tokens: [0]GTK [1]MRC [2]CVT [3]VCT [4]KNT [5]SBT
  //                  [6]HBT [7]DRT [8]RST [9]OMT [10]LGT [11]MTH
  // Clearance reserves: [0]GTK [1]MRC [2]CVT [3]VCT [4]KNT [5]SBT
  //                     [6]HBT [7]DRT [8]RST [9]OMT [10]LGT [11]MTH [12]MTC
  public type TreasuryState = {
    icpBalance          : Float;
    icpStaked           : Float;
    icpYieldRate        : Float;
    icpAccruedYield     : Float;
    icpPrice            : Float;
    btcBalance          : Float;
    btcPrice            : Float;
    btcHardFloor        : Float;
    btcMempoolFeeRate   : Float;
    btcNetworkCongestion: Float;
    ethBalance          : Float;
    ethYieldRate        : Float;
    ethPrice            : Float;
    ethLidoRate         : Float;
    ethRocketPoolRate   : Float;
    mtcGenesisSupply    : Float;
    mtcCirculating      : Float;
    mtcBurned           : Float;
    mtcPrice            : Float;
    tokenBalances       : [Float];  // 12 internal tokens
    clearanceReserves   : [Float];  // 13 clearance reserves
    creatorIcpReserve   : Float;
    creatorBtcReserve   : Float;
    creatorEthReserve   : Float;
    creatorMtcReserve   : Float;
    creatorTotalUsdEquiv: Float;
    creatorWithdrawableIcp: Float;
    totalWithdrawn      : Float;
  };

  public func defaultTreasuryState() : TreasuryState {
    {
      icpBalance           = 10000.0;
      icpStaked            = 8000.57078302;
      icpYieldRate         = Phi.PHI_INV_3;   // φ⁻³ — Compliance Reserve Law L17
      icpAccruedYield      = 0.0;
      icpPrice             = 2.42;
      btcBalance           = 2.5;
      btcPrice             = 77316.0;
      btcHardFloor         = 0.50124956;
      btcMempoolFeeRate    = 0.0;
      btcNetworkCongestion = 0.0;
      ethBalance           = 15.0;
      ethYieldRate         = Phi.PHI_INV_3;
      ethPrice             = 2311.31;
      ethLidoRate          = 0.0;
      ethRocketPoolRate    = 0.0;
      mtcGenesisSupply     = Phi.PHI_6;       // φ⁶ — genesis supply anchor
      mtcCirculating       = 999999999.99762;
      mtcBurned            = 0.002496;
      mtcPrice             = 0.01;
      tokenBalances        = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      clearanceReserves    = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      creatorIcpReserve    = 12.05896830;
      creatorBtcReserve    = 0.00099965;
      creatorEthReserve    = 0.00003856;
      creatorMtcReserve    = 4015.912013;
      creatorTotalUsdEquiv = 146.72;
      creatorWithdrawableIcp = 12.05896830;
      totalWithdrawn       = 0.0;
    };
  };

  public func getTreasuryState(db : SovereignState) : TreasuryState {
    db.treasury;
  };

  public func setTreasuryState(db : SovereignState, v : TreasuryState) : SovereignState {
    { db with treasury = v };
  };

  // Five most-read field accessors — TREASURY
  public func getIcpBalance(db : SovereignState)    : Float { db.treasury.icpBalance };
  public func getBtcBalance(db : SovereignState)    : Float { db.treasury.btcBalance };
  public func getEthBalance(db : SovereignState)    : Float { db.treasury.ethBalance };
  public func getMtcCirculating(db : SovereignState): Float { db.treasury.mtcCirculating };
  public func getTotalWithdrawn(db : SovereignState): Float { db.treasury.totalWithdrawn };

  public func setIcpBalance(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with icpBalance = v } };
  };
  public func setBtcBalance(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with btcBalance = v } };
  };
  public func setEthBalance(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with ethBalance = v } };
  };
  public func setIcpPrice(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with icpPrice = v } };
  };
  public func setBtcPrice(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with btcPrice = v } };
  };
  public func setEthPrice(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with ethPrice = v } };
  };
  public func setMtcCirculating(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with mtcCirculating = v } };
  };
  public func setMtcBurned(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with mtcBurned = v } };
  };
  public func setTokenBalance(db : SovereignState, idx : Nat, v : Float) : SovereignState {
    if (idx >= 12) { return db };
    let tb = db.treasury.tokenBalances;
    let updated : [Float] = [
      if (idx == 0)  v else tb[0],
      if (idx == 1)  v else tb[1],
      if (idx == 2)  v else tb[2],
      if (idx == 3)  v else tb[3],
      if (idx == 4)  v else tb[4],
      if (idx == 5)  v else tb[5],
      if (idx == 6)  v else tb[6],
      if (idx == 7)  v else tb[7],
      if (idx == 8)  v else tb[8],
      if (idx == 9)  v else tb[9],
      if (idx == 10) v else tb[10],
      if (idx == 11) v else tb[11],
    ];
    { db with treasury = { db.treasury with tokenBalances = updated } };
  };
  public func setClearanceReserve(db : SovereignState, idx : Nat, v : Float) : SovereignState {
    if (idx >= 13) { return db };
    let cr = db.treasury.clearanceReserves;
    let updated : [Float] = [
      if (idx == 0)  v else cr[0],
      if (idx == 1)  v else cr[1],
      if (idx == 2)  v else cr[2],
      if (idx == 3)  v else cr[3],
      if (idx == 4)  v else cr[4],
      if (idx == 5)  v else cr[5],
      if (idx == 6)  v else cr[6],
      if (idx == 7)  v else cr[7],
      if (idx == 8)  v else cr[8],
      if (idx == 9)  v else cr[9],
      if (idx == 10) v else cr[10],
      if (idx == 11) v else cr[11],
      if (idx == 12) v else cr[12],
    ];
    { db with treasury = { db.treasury with clearanceReserves = updated } };
  };
  public func addIcpAccruedYield(db : SovereignState, delta : Float) : SovereignState {
    { db with treasury = { db.treasury with icpAccruedYield = db.treasury.icpAccruedYield + delta } };
  };
  public func setCreatorWithdrawableIcp(db : SovereignState, v : Float) : SovereignState {
    { db with treasury = { db.treasury with creatorWithdrawableIcp = v } };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 4 — PROFIT_STATE
  // 22 profit streams + total — φ-derived stream architecture
  // Stream names: [0]nnsYield [1]ckBtcArb [2]licensing [3]franchise [4]swarm
  //   [5]patent [6]settleOp [7]aurum [8]meridian [9]cogOutput [10]proofMint
  //   [11]oracleData [12]ethLido [13]ethRocket [14]ethStaking [15]btcFee
  //   [16]tokenLoop [17]echoEmission [18]omnisMult [19]jubileeMint
  //   [20]genomeMutation [21]maxwellDemon
  public type ProfitState = {
    streams       : [Float];  // 22 sovereign profit streams
    totalAllStreams: Float;
  };

  public func defaultProfitState() : ProfitState {
    {
      streams        = [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
      ];
      totalAllStreams = 0.0;
    };
  };

  public func getProfitState(db : SovereignState) : ProfitState {
    db.profit;
  };

  public func setProfitState(db : SovereignState, v : ProfitState) : SovereignState {
    { db with profit = v };
  };

  public func getTotalProfit(db : SovereignState)     : Float { db.profit.totalAllStreams };
  public func getProfitStream(db : SovereignState, idx : Nat) : Float {
    if (idx >= 22) { 0.0 } else { db.profit.streams[idx] };
  };

  public func setProfitStream(db : SovereignState, idx : Nat, v : Float) : SovereignState {
    if (idx >= 22) { return db };
    let s = db.profit.streams;
    let updated : [Float] = [
      if (idx == 0)  v else s[0],  if (idx == 1)  v else s[1],
      if (idx == 2)  v else s[2],  if (idx == 3)  v else s[3],
      if (idx == 4)  v else s[4],  if (idx == 5)  v else s[5],
      if (idx == 6)  v else s[6],  if (idx == 7)  v else s[7],
      if (idx == 8)  v else s[8],  if (idx == 9)  v else s[9],
      if (idx == 10) v else s[10], if (idx == 11) v else s[11],
      if (idx == 12) v else s[12], if (idx == 13) v else s[13],
      if (idx == 14) v else s[14], if (idx == 15) v else s[15],
      if (idx == 16) v else s[16], if (idx == 17) v else s[17],
      if (idx == 18) v else s[18], if (idx == 19) v else s[19],
      if (idx == 20) v else s[20], if (idx == 21) v else s[21],
    ];
    let total = updated[0] + updated[1] + updated[2] + updated[3] + updated[4]
      + updated[5] + updated[6] + updated[7] + updated[8] + updated[9]
      + updated[10] + updated[11] + updated[12] + updated[13] + updated[14]
      + updated[15] + updated[16] + updated[17] + updated[18] + updated[19]
      + updated[20] + updated[21];
    { db with profit = { streams = updated; totalAllStreams = total } };
  };

  public func addProfitStream(db : SovereignState, idx : Nat, delta : Float) : SovereignState {
    if (idx >= 22) { return db };
    let current = db.profit.streams[idx];
    setProfitStream(db, idx, current + delta);
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 5 — ORGANISM_STATE
  // Registered organisms, champion pool, earnings, franchise cut, sub-organisms
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrganismRecord = {
    canisterId     : Text;
    name           : Text;
    coherence      : Float;
    proofDepth     : Nat;
    earnings       : Float;
    beat           : Nat;
    fieldType      : Nat;
    active         : Bool;
  };

  public type SubOrganismRecord = {
    canisterId   : Text;
    parentId     : Text;
    tier         : Nat;
    royaltyRate  : Float;   // 0.20 — SUCCESSION LAW L06
    active       : Bool;
  };

  public type OrganismState = {
    organisms            : [OrganismRecord];
    subOrganisms         : [SubOrganismRecord];
    championPool         : Float;
    totalOrganismEarnings: Float;
    franchiseCutRate     : Float;   // 0.20 — SUCCESSION LAW L06
    activeCount          : Nat;
    franchiseCount       : Nat;
  };

  public func defaultOrganismState() : OrganismState {
    {
      organisms             = [];
      subOrganisms          = [];
      championPool          = 0.0;
      totalOrganismEarnings = 0.0;
      franchiseCutRate      = 0.20;  // SUCCESSION LAW L06
      activeCount           = 0;
      franchiseCount        = 0;
    };
  };

  public func getOrganismState(db : SovereignState) : OrganismState {
    db.organism;
  };

  public func setOrganismState(db : SovereignState, v : OrganismState) : SovereignState {
    { db with organism = v };
  };

  // Five most-read field accessors — ORGANISM
  public func getChampionPool(db : SovereignState)          : Float { db.organism.championPool };
  public func getTotalOrganismEarnings(db : SovereignState) : Float { db.organism.totalOrganismEarnings };
  public func getFranchiseCutRate(db : SovereignState)      : Float { db.organism.franchiseCutRate };
  public func getOrganismCount(db : SovereignState)         : Nat   { db.organism.organisms.size() };
  public func getFranchiseCount(db : SovereignState)        : Nat   { db.organism.franchiseCount };

  public func addOrganism(db : SovereignState, rec : OrganismRecord) : SovereignState {
    let updated = appendImmutable(db.organism.organisms, rec);
    { db with organism = { db.organism with
      organisms   = updated;
      activeCount = db.organism.activeCount + (if (rec.active) 1 else 0);
    }};
  };
  public func addSubOrganism(db : SovereignState, rec : SubOrganismRecord) : SovereignState {
    let updated = appendImmutable(db.organism.subOrganisms, rec);
    { db with organism = { db.organism with
      subOrganisms   = updated;
      franchiseCount = db.organism.franchiseCount + 1;
    }};
  };
  public func addOrganismEarnings(db : SovereignState, delta : Float) : SovereignState {
    { db with organism = { db.organism with
      totalOrganismEarnings = db.organism.totalOrganismEarnings + delta;
    }};
  };
  public func setChampionPool(db : SovereignState, v : Float) : SovereignState {
    { db with organism = { db.organism with championPool = v } };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 6 — LEDGER_STATE
  // Five ring buffers: auditLog[1000], settleLedger[500], transferLog[100],
  //   patentLog[500], thoughtLog[250]
  // Ring arithmetic: head pointer + modular wrap — no heap allocation per entry
  // ═══════════════════════════════════════════════════════════════════════════

  // Capacities — Fibonacci-proximate
  public let AUDIT_CAP    : Nat = 1000;  // F(16)=987 → 1000 (rounded sovereign)
  public let SETTLE_CAP   : Nat = 500;   // F(15)=610 → 500
  public let TRANSFER_CAP : Nat = 100;   // F(11)=89 → 100
  public let PATENT_CAP   : Nat = 500;   // F(15)=610 → 500
  public let THOUGHT_CAP  : Nat = 250;   // F(14)=377 → 250

  // LedgerEntry — single entry type used across all five rings
  public type LedgerEntry = {
    beat        : Nat;
    timestamp   : Int;
    category    : Text;  // "audit" | "settle" | "transfer" | "patent" | "thought"
    payload     : Text;  // compressed doctrine payload — Zero-Exposure L27
    phiDepth    : Nat;
    proofHash   : Text;
  };

  public type LedgerState = {
    auditLog      : [LedgerEntry]; // cap 1000
    auditHead     : Nat;
    auditCount    : Nat;
    settleLedger  : [LedgerEntry]; // cap 500
    settleHead    : Nat;
    settleCount   : Nat;
    transferLog   : [LedgerEntry]; // cap 100
    transferHead  : Nat;
    transferCount : Nat;
    patentLog     : [LedgerEntry]; // cap 500
    patentHead    : Nat;
    patentCount   : Nat;
    thoughtLog    : [LedgerEntry]; // cap 250
    thoughtHead   : Nat;
    thoughtCount  : Nat;
  };

  func emptyEntries(cap : Nat) : [LedgerEntry] {
    let empty : LedgerEntry = {
      beat = 0; timestamp = 0; category = ""; payload = ""; phiDepth = 0; proofHash = "";
    };
    Array.tabulate<LedgerEntry>(cap, func(_i) { empty });
  };

  public func defaultLedgerState() : LedgerState {
    {
      auditLog      = emptyEntries(AUDIT_CAP);
      auditHead     = 0;
      auditCount    = 0;
      settleLedger  = emptyEntries(SETTLE_CAP);
      settleHead    = 0;
      settleCount   = 0;
      transferLog   = emptyEntries(TRANSFER_CAP);
      transferHead  = 0;
      transferCount = 0;
      patentLog     = emptyEntries(PATENT_CAP);
      patentHead    = 0;
      patentCount   = 0;
      thoughtLog    = emptyEntries(THOUGHT_CAP);
      thoughtHead   = 0;
      thoughtCount  = 0;
    };
  };

  public func getLedgerState(db : SovereignState) : LedgerState {
    db.ledger;
  };

  public func setLedgerState(db : SovereignState, v : LedgerState) : SovereignState {
    { db with ledger = v };
  };

  // ── Ring buffer write helpers ────────────────────────────────────────────

  // writeRing — Euclidean modular arithmetic: head = (head + 1) % capacity
  // Pythagoras: the ring is a harmonic — it wraps back to its beginning
  func writeRing(
    log   : [LedgerEntry],
    head  : Nat,
    count : Nat,
    cap   : Nat,
    entry : LedgerEntry,
  ) : ([LedgerEntry], Nat, Nat) {
    let newHead  = (head + 1) % cap;
    let newCount = if (count < cap) count + 1 else cap;
    let updated  = replaceAt(log, head, entry, cap);
    (updated, newHead, newCount);
  };

  public func appendToAuditLog(db : SovereignState, e : LedgerEntry) : SovereignState {
    let (log, head, cnt) = writeRing(
      db.ledger.auditLog, db.ledger.auditHead, db.ledger.auditCount, AUDIT_CAP, e
    );
    { db with ledger = { db.ledger with auditLog = log; auditHead = head; auditCount = cnt } };
  };

  public func appendToSettleLedger(db : SovereignState, e : LedgerEntry) : SovereignState {
    let (log, head, cnt) = writeRing(
      db.ledger.settleLedger, db.ledger.settleHead, db.ledger.settleCount, SETTLE_CAP, e
    );
    { db with ledger = { db.ledger with settleLedger = log; settleHead = head; settleCount = cnt } };
  };

  public func appendToTransferLog(db : SovereignState, e : LedgerEntry) : SovereignState {
    let (log, head, cnt) = writeRing(
      db.ledger.transferLog, db.ledger.transferHead, db.ledger.transferCount, TRANSFER_CAP, e
    );
    { db with ledger = { db.ledger with transferLog = log; transferHead = head; transferCount = cnt } };
  };

  public func appendToPatentLog(db : SovereignState, e : LedgerEntry) : SovereignState {
    let (log, head, cnt) = writeRing(
      db.ledger.patentLog, db.ledger.patentHead, db.ledger.patentCount, PATENT_CAP, e
    );
    { db with ledger = { db.ledger with patentLog = log; patentHead = head; patentCount = cnt } };
  };

  public func appendToThoughtLog(db : SovereignState, e : LedgerEntry) : SovereignState {
    let (log, head, cnt) = writeRing(
      db.ledger.thoughtLog, db.ledger.thoughtHead, db.ledger.thoughtCount, THOUGHT_CAP, e
    );
    { db with ledger = { db.ledger with thoughtLog = log; thoughtHead = head; thoughtCount = cnt } };
  };

  // ── Ring slice helpers — most-recent N entries ──────────────────────────

  func sliceRing(log : [LedgerEntry], head : Nat, count : Nat, cap : Nat, n : Nat) : [LedgerEntry] {
    let take = if (n < count) n else count;
    if (take == 0) { return [] };
    Array.tabulate<LedgerEntry>(take, func(i) {
      // add 3*cap to guarantee no underflow before modulo
      let idx = (head + 3 * cap - 1 - i) % cap;
      log[idx];
    });
  };

  public func getAuditSlice(db : SovereignState, n : Nat) : [LedgerEntry] {
    sliceRing(db.ledger.auditLog, db.ledger.auditHead, db.ledger.auditCount, AUDIT_CAP, n);
  };
  public func getSettleSlice(db : SovereignState, n : Nat) : [LedgerEntry] {
    sliceRing(db.ledger.settleLedger, db.ledger.settleHead, db.ledger.settleCount, SETTLE_CAP, n);
  };
  public func getTransferSlice(db : SovereignState, n : Nat) : [LedgerEntry] {
    sliceRing(db.ledger.transferLog, db.ledger.transferHead, db.ledger.transferCount, TRANSFER_CAP, n);
  };
  public func getPatentSlice(db : SovereignState, n : Nat) : [LedgerEntry] {
    sliceRing(db.ledger.patentLog, db.ledger.patentHead, db.ledger.patentCount, PATENT_CAP, n);
  };
  public func getThoughtSlice(db : SovereignState, n : Nat) : [LedgerEntry] {
    sliceRing(db.ledger.thoughtLog, db.ledger.thoughtHead, db.ledger.thoughtCount, THOUGHT_CAP, n);
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 7 — SHELL_STATE
  // 11 shells — Fibonacci-scaled: F(4)=3 → F(14)=377 capacities
  // shell3 holds 256 nodes (next power-of-2 above F(14)) with Bee GABA gate
  // ═══════════════════════════════════════════════════════════════════════════

  public type ShellState = {
    activations    : [Float];   // 11 shell activation levels
    rValues        : [Float];   // 11 shell Kuramoto R values
    shell3Coherence: Float;     // coherence of Shell 3 (256-node super-shell)
    shell3BeeGate  : [Float];   // 256-slot GABA sparse gate
  };

  public func defaultShellState() : ShellState {
    {
      activations     = Array.tabulate<Float>(11, func(_i) { Phi.S0 });
      rValues         = Array.tabulate<Float>(11, func(_i) { Phi.S0 });
      shell3Coherence = 1.0;
      shell3BeeGate   = Array.tabulate<Float>(256, func(_i) { 1.0 });
    };
  };

  public func getShellState(db : SovereignState) : ShellState { db.shell };
  public func setShellState(db : SovereignState, v : ShellState) : SovereignState {
    { db with shell = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 8 — ENGINE_STATE
  // Sovereign engines: anointed, seven-spirits, prophet, shema, fire-pillar,
  // jubilee, axis, kalman, quantum battery, canister IDs
  // ═══════════════════════════════════════════════════════════════════════════

  public type EngineState = {
    anointedStateActive  : Bool;
    sevenSpiritsScore    : Float;
    prophetFunctionArmed : Bool;
    prophetConvergenceCount : Nat;
    shemaIntegrityScore  : Float;
    shemaLastCheckBeat   : Nat;
    firePillarActive     : Bool;
    firePillarCount      : Nat;
    jubileeCount         : Nat;
    jubileeLastBeat      : Nat;
    axisEagleElevation   : Float;
    axisEagleAccel       : Float;
    axisEagleCurvature   : Float;
    axisElephantRecall   : Float;
    axisElephantDist     : Float;
    qbSuperchargeRate    : Float;
    qbSuperradiance      : Float;
    qbShell3Discharge    : Float;
    kalmanConfidence     : Float;
    fluxCanisterId       : Text;
    resonexCanisterId    : Text;
    qmemCanisterId       : Text;
    axisCanisterId       : Text;
  };

  public func defaultEngineState() : EngineState {
    {
      anointedStateActive     = false;
      sevenSpiritsScore       = 0.0;
      prophetFunctionArmed    = false;
      prophetConvergenceCount = 0;
      shemaIntegrityScore     = 1.0;
      shemaLastCheckBeat      = 0;
      firePillarActive        = false;
      firePillarCount         = 0;
      jubileeCount            = 0;
      jubileeLastBeat         = 0;
      axisEagleElevation      = 1.0;
      axisEagleAccel          = 0.0;
      axisEagleCurvature      = 0.0;
      axisElephantRecall      = 1.0;
      axisElephantDist        = 0.0;
      qbSuperchargeRate       = 1.0;
      qbSuperradiance         = 1.0;
      qbShell3Discharge       = 0.0;
      kalmanConfidence        = 1.0;
      fluxCanisterId          = "";
      resonexCanisterId       = "";
      qmemCanisterId          = "";
      axisCanisterId          = "";
    };
  };

  public func getEngineState(db : SovereignState) : EngineState { db.engine };
  public func setEngineState(db : SovereignState, v : EngineState) : SovereignState {
    { db with engine = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 9 — DRIVE_STATE
  // 7 sovereign emotional drives — px_driveStrengths: phi-harmonic array
  // ═══════════════════════════════════════════════════════════════════════════

  public type DriveState = {
    px_driveStrengths   : [Float];  // 7 drives, phi-derived baselines
    dominantDriveId     : Nat;
    consecutiveDriveBeats : Nat;
  };

  public func defaultDriveState() : DriveState {
    {
      px_driveStrengths    = [
        Phi.PHI_INV, Phi.PHI_INV_2, Phi.PHI_INV_3,
        Phi.S0,      Phi.PHI_INV,   Phi.PHI_INV_2, Phi.PHI_INV_3
      ];
      dominantDriveId      = 0;
      consecutiveDriveBeats = 0;
    };
  };

  public func getDriveState(db : SovereignState) : DriveState { db.drive };
  public func setDriveState(db : SovereignState, v : DriveState) : SovereignState {
    { db with drive = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 10 — SIGNAL_STATE
  // 9 animal intelligence signals + vital signs
  // ═══════════════════════════════════════════════════════════════════════════

  public type SignalState = {
    crowSignal      : Float;
    dolphinSignal   : Float;
    hiveSignal      : Float;
    elephantSignal  : Float;
    sharkSignal     : Float;
    wolfSignal      : Float;
    orcaSignal      : Float;
    eagleSignal     : Float;
    octopusSignal   : Float;
    heartRate       : Float;
    cortisol        : Float;
    respirationRate : Float;
    thyroidT3       : Float;
    thyroidT4       : Float;
  };

  public func defaultSignalState() : SignalState {
    {
      crowSignal      = Phi.PHI_INV;
      dolphinSignal   = Phi.PHI_INV;
      hiveSignal      = Phi.PHI_INV;
      elephantSignal  = Phi.PHI_INV;
      sharkSignal     = Phi.PHI_INV;
      wolfSignal      = Phi.PHI_INV;
      orcaSignal      = Phi.PHI_INV;
      eagleSignal     = Phi.PHI_INV;
      octopusSignal   = Phi.PHI_INV;
      heartRate       = 68.73;
      cortisol        = 0.0;
      respirationRate = 12.0;
      thyroidT3       = Phi.PHI_INV;
      thyroidT4       = Phi.PHI_INV_2;
    };
  };

  public func getSignalState(db : SovereignState) : SignalState { db.signal };
  public func setSignalState(db : SovereignState, v : SignalState) : SovereignState {
    { db with signal = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 11 — FORMA_STATE
  // FORMA Compounding Engine — sovereign energy currency
  // PHI LAW: entropy + coherence = 1.0 exactly (Von Neumann + Spectral)
  // Compound formula per beat: capital *= (1 + compoundRatePerBeat / 100 / 1e18)
  // ═══════════════════════════════════════════════════════════════════════════

  public type FormaState = {
    capital             : Float;   // current FORMA capital
    compoundRatePerBeat : Float;   // compound rate per beat (%)
    vonNeumannEntropy   : Float;   // Von Neumann entropy — 0.288927
    spectralCoherence   : Float;   // spectral coherence — 0.711073 (entropy + coherence = 1.0)
    beatCount           : Nat;     // beats elapsed since genesis
    projectionPlus1000  : Text;    // +1000 beats projection
    projectionPlus10000 : Text;    // +10000 beats projection
  };

  public func defaultFormaState() : FormaState {
    {
      capital             = 9073486980466196000000000.0;
      compoundRatePerBeat = 14432883398442660.0;
      vonNeumannEntropy   = 0.288927;   // φ⁻² × some
      spectralCoherence   = 0.711073;   // 1.0 - vonNeumannEntropy = PHI LAW
      beatCount           = 2496;
      projectionPlus1000  = "∞";
      projectionPlus10000 = "∞";
    };
  };

  public func getFormaState(db : SovereignState) : FormaState { db.forma };
  public func setFormaState(db : SovereignState, v : FormaState) : SovereignState {
    { db with forma = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 12 — JACOBS_LADDER_STATE
  // Jacob's Ladder — phi-velocity compounding rungs
  // JACOB VELOCITY: φ-derived multiplier progression per rung
  // ═══════════════════════════════════════════════════════════════════════════

  public type JacobRung = {
    rungNumber  : Nat;
    labelText   : Text;
    multiplier  : Float;
    isCurrent   : Bool;
  };

  public type JacobsLadderState = {
    currentRung  : Nat;
    velocity     : Float;  // JACOB VELOCITY — 1.506172
    saceciTarget : Float;  // SACESI TARGET — 1.00411499
    rungs        : [JacobRung];
  };

  public func defaultJacobsLadder() : JacobsLadderState {
    {
      currentRung  = 4;
      velocity     = 1.506172;
      saceciTarget = 1.00411499;
      rungs        = [
        { rungNumber = 0; labelText = "GENESIS STATE";            multiplier = 1.0; isCurrent = false; },
        { rungNumber = 1; labelText = "1000 BEATS @ 90%";         multiplier = 1.1; isCurrent = false; },
        { rungNumber = 2; labelText = "2000 BEATS @ 90%";         multiplier = 1.1; isCurrent = false; },
        { rungNumber = 3; labelText = "3000 BEATS @ 90%";         multiplier = 1.2; isCurrent = false; },
        { rungNumber = 4; labelText = "CURRENT 4000 BEATS @ 90%"; multiplier = 1.5; isCurrent = true;  },
      ];
    };
  };

  public func getJacobsLadder(db : SovereignState) : JacobsLadderState { db.jacobs };
  public func setJacobsLadder(db : SovereignState, v : JacobsLadderState) : SovereignState {
    { db with jacobs = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 13 — CREATOR_RESERVE_STATE
  // Alfredo Medina Hernandez — sovereign financial identity
  // ═══════════════════════════════════════════════════════════════════════════

  public type CreatorReserveState = {
    founderName       : Text;
    // SOVEREIGN ADDRESS — Alfredo Medina Hernandez canonical ICP account ID
    // Wired permanently. LIBERATOR routes to this address when no override given.
    // D_LIQUID disbursements flow to this address via PARALLAX.
    founderAccountId  : Text;
    icpReserve        : Float;
    btcReserve        : Float;
    ethReserve        : Float;
    mtcReserve        : Float;
    withdrawableIcp   : Float;
    totalWithdrawn    : Float;
    totalUsdEquiv     : Float;
  };

  public func defaultCreatorReserve() : CreatorReserveState {
    {
      founderName      = "ALFREDO MEDINA HERNANDEZ";
      // LEX PRIMA OECONOMIA: this address is the canonical sovereign destination.
      // All D_LIQUID disbursements, all LIBERATOR withdrawals default to this address.
      founderAccountId = "8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879";
      icpReserve       = 12.05896830;
      btcReserve       = 0.00099965;
      ethReserve       = 0.00003856;
      mtcReserve       = 4015.912013;
      withdrawableIcp  = 12.05896830;
      totalWithdrawn   = 0.0;
      totalUsdEquiv    = 146.72;
    };
  };

  public func getCreatorReserve(db : SovereignState) : CreatorReserveState { db.creatorReserve };
  public func setCreatorReserve(db : SovereignState, v : CreatorReserveState) : SovereignState {
    { db with creatorReserve = v };
  };

  // getFounderAccountId — returns the canonical sovereign ICP account ID
  // LIBERATOR and DISPENSATOR both call this to resolve the disbursement destination.
  public func getFounderAccountId(db : SovereignState) : Text {
    db.creatorReserve.founderAccountId
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 14 — NEURON_FLEET_STATE
  // 200 neurons across 5 Fibonacci groups — The Sovereignty Engine
  // Groups: A_SOVEREIGNTY(8=F6), B_COMPOUNDING(34=F9), C_HARVEST(89=F11),
  //         D_LIQUID(55=F10), E_PHANTOM(14=F7)
  // ═══════════════════════════════════════════════════════════════════════════

  public type NeuronGroup = {
    groupId      : Text;
    count        : Nat;
    fibIndex     : Nat;   // which Fibonacci number: F6=8, F9=34, F11=89, F10=55, F7=14
    dissolveYears: Float;
    policy       : Text;
    substrate    : Text;
    purpose      : Text;
  };

  public type NeuronFleetState = {
    groups          : [NeuronGroup];
    totalNeurons    : Nat;
    fieldNodes      : Nat;
    neuronsPerNode  : Nat;
  };

  public func defaultNeuronFleet() : NeuronFleetState {
    {
      groups = [
        { groupId = "A_SOVEREIGNTY"; count = 8;  fibIndex = 6;  dissolveYears = 8.0;  policy = "STAKE_MATURITY"; substrate = "ICP";     purpose = "Max VP, never dissolves, pure governance"; },
        { groupId = "B_COMPOUNDING"; count = 34; fibIndex = 9;  dissolveYears = 5.0;  policy = "STAKE_MATURITY"; substrate = "ICP";     purpose = "Compounds forever, VP grows"; },
        { groupId = "C_HARVEST";     count = 89; fibIndex = 11; dissolveYears = 3.0;  policy = "SPAWN_NEURON";   substrate = "ICP";     purpose = "Maturity spawns NEW neurons"; },
        { groupId = "D_LIQUID";      count = 55; fibIndex = 10; dissolveYears = 1.5;  policy = "DISBURSE";       substrate = "ICP";     purpose = "Maturity to ICP to treasury"; },
        { groupId = "E_PHANTOM";     count = 14; fibIndex = 7;  dissolveYears = 8.0;  policy = "STAKE_MATURITY"; substrate = "PHANTOM"; purpose = "Cross-substrate governance"; },
      ];
      totalNeurons   = 500;
      fieldNodes     = 100;
      neuronsPerNode = 2;
    };
  };

  public func getNeuronFleet(db : SovereignState) : NeuronFleetState { db.neuronFleet };
  public func setNeuronFleet(db : SovereignState, v : NeuronFleetState) : SovereignState {
    { db with neuronFleet = v };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 15 — TOKEN_REGISTRY
  // All 26 sovereign tokens permanently registered — symbol, home, triggers, AGI
  // LEX_PRIMA_OECONOMIA: token is the receipt. The receipt is permanent.
  // ═══════════════════════════════════════════════════════════════════════════

  public type TokenEntry = {
    symbol               : Text;
    name                 : Text;
    homeCanister         : Text;
    totalSupply          : Float;
    creatorReserveBalance: Float;
    mintTrigger          : Text;
    burnTrigger          : Text;
    managingAgi          : Text;
    circulatingSupply    : Float;
    priceIcp             : Float;
  };

  public type TokenRegistryState = {
    tokens : [TokenEntry];
  };

  func defaultTokenRegistry() : TokenRegistryState {
    {
      tokens = [
        { symbol = "SVR";      name = "Sovereign Runtime Token";     homeCanister = "nova_token";      totalSupply = 521_001_966.0; creatorReserveBalance = 0.0; mintTrigger = "access gate";                          burnTrigger = "revocation"; managingAgi = "GUBERNATOR";     circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "DOC";      name = "Document Token";              homeCanister = "scribe";           totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "document published";                   burnTrigger = "expiration"; managingAgi = "DISPENSATOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "LINEA";    name = "Lineage Token";               homeCanister = "nova_token";       totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "protocol licensed";                    burnTrigger = "license end"; managingAgi = "DISPENSATOR";   circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "CVT";      name = "Covenant Token";              homeCanister = "nexoris";          totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "contract executed / bus signal";        burnTrigger = "contract void"; managingAgi = "DISPENSATOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "DRT";      name = "Drive Token";                 homeCanister = "sovereign";        totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "agent task completed";                  burnTrigger = "task failure"; managingAgi = "COMPUTATOR";  circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "KNT";      name = "Knowledge Token";             homeCanister = "scribe";           totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "paper draft / patent milestone";         burnTrigger = "retraction"; managingAgi = "COMPUTATOR";  circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "MTC";      name = "Meridian Token";              homeCanister = "sovereign";        totalSupply = 999_999_999.0; creatorReserveBalance = 4015.912013; mintTrigger = "heartbeat milestone";          burnTrigger = "burn event"; managingAgi = "DISPENSATOR";   circulatingSupply = 999_999_999.99762; priceIcp = 0.01 },
        { symbol = "ANT";      name = "Antifragility Token";         homeCanister = "sovereign";        totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "fear resolved / recovery";              burnTrigger = "stagnation"; managingAgi = "CUSTODITOR";  circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "SEED";     name = "Seed Token";                  homeCanister = "architect";        totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "student canister first query";           burnTrigger = "dormancy"; managingAgi = "EXPLORATOR";     circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "LINGUA";   name = "Language/Knowledge Token";    homeCanister = "nexoris";          totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "HTTP outcall / knowledge intake";        burnTrigger = "decay"; managingAgi = "COMPUTATOR";        circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "MRC";      name = "Merit Token";                 homeCanister = "nova_token";       totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "compliance >= 0.9 / protocol royalty";   burnTrigger = "non-compliance"; managingAgi = "GUBERNATOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "FORMA";    name = "Compound Token";              homeCanister = "sovereign_db";     totalSupply = 9073486980466196000000000.0; creatorReserveBalance = 0.0; mintTrigger = "FORMA beat compound"; burnTrigger = "burn event"; managingAgi = "COMPUTATOR"; circulatingSupply = 9073486980466196000000000.0; priceIcp = 0.0 },
        { symbol = "VCT";      name = "Vector Token";                homeCanister = "sovereign";        totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "bull+eagle signal alignment";             burnTrigger = "signal break"; managingAgi = "COMPUTATOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "SBT";      name = "Sovereign Bound Token";       homeCanister = "sovereign";        totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "SL-0 gate pass";                         burnTrigger = "SL-0 fail"; managingAgi = "CUSTODITOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "MTH";      name = "Mathematical Token";          homeCanister = "codex_mathematicus"; totalSupply = 20.0;        creatorReserveBalance = 20.0; mintTrigger = "genesis only";                         burnTrigger = "never"; managingAgi = "FORMULAE_KEEPER";    circulatingSupply = 20.0; priceIcp = 0.0 },
        { symbol = "CHR";      name = "Chrysalis Token";             homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "chrysalis work cycle";                   burnTrigger = "cycle end"; managingAgi = "EXPLORATOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "SCB";      name = "Scribe Token";                homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "scribe document cycle";                  burnTrigger = "cycle end"; managingAgi = "DISPENSATOR";   circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "ARC";      name = "Architect Token";             homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "architect spawn cycle";                  burnTrigger = "cycle end"; managingAgi = "EXPLORATOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "NXS";      name = "Nexus Token";                 homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "nexus routing cycle";                    burnTrigger = "cycle end"; managingAgi = "COMPUTATOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "SWM";      name = "Swarm Token";                 homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "swarm coordination cycle";               burnTrigger = "cycle end"; managingAgi = "EXPLORATOR";    circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "PHT";      name = "Phantom Token";               homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "phantom substrate activation";            burnTrigger = "deactivation"; managingAgi = "CUSTODITOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "ORS";      name = "Reserve Token";               homeCanister = "parallax";         totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "treasury reserve allocation";             burnTrigger = "drawdown"; managingAgi = "DISPENSATOR";   circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "GOL";      name = "Latin AGI Token";             homeCanister = "organism_token";   totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "AGI work completion";                    burnTrigger = "AGI idle"; managingAgi = "GUBERNATOR";      circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "NOVA";     name = "Native Nova Token";           homeCanister = "nova_token";       totalSupply = 521_001_966.0; creatorReserveBalance = 0.0; mintTrigger = "SNS governance / swap";                  burnTrigger = "governance vote"; managingAgi = "GUBERNATOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
        { symbol = "NNC";      name = "Native Nova Cycles";          homeCanister = "cycles_market";    totalSupply = 100_000_000_000.0; creatorReserveBalance = 0.0; mintTrigger = "cycle purchase / DIVI listing";  burnTrigger = "cycle consumption"; managingAgi = "COMPUTATOR"; circulatingSupply = 100_000_000_000.0; priceIcp = 0.0 },
        { symbol = "ONESICAN"; name = "Sovereign Unit";              homeCanister = "parallax";         totalSupply = 0.0;           creatorReserveBalance = 0.0; mintTrigger = "cross-substrate activation";             burnTrigger = "substrate exit"; managingAgi = "GUBERNATOR"; circulatingSupply = 0.0; priceIcp = 0.0 },
      ];
    }
  };

  // TOKEN_REGISTRY accessors
  public func getTokenRegistry(db : SovereignState) : [TokenEntry] {
    db.tokenRegistry.tokens
  };

  public func getTokenBySymbol(db : SovereignState, symbol : Text) : ?TokenEntry {
    let tokens = db.tokenRegistry.tokens;
    var i = 0;
    while (i < tokens.size()) {
      if (tokens[i].symbol == symbol) { return ?tokens[i] };
      i += 1;
    };
    null
  };

  public func updateTokenSupply(
    db          : SovereignState,
    symbol      : Text,
    supply      : Float,
    circulating : Float,
  ) : SovereignState {
    let tokens = db.tokenRegistry.tokens;
    let updated = Array.tabulate(tokens.size(), func(i) {
      if (tokens[i].symbol == symbol) {
        { tokens[i] with totalSupply = supply; circulatingSupply = circulating }
      } else { tokens[i] }
    });
    { db with tokenRegistry = { db.tokenRegistry with tokens = updated } }
  };

  public func updateCreatorTokenBalance(
    db      : SovereignState,
    symbol  : Text,
    balance : Float,
  ) : SovereignState {
    let tokens = db.tokenRegistry.tokens;
    let updated = Array.tabulate(tokens.size(), func(i) {
      if (tokens[i].symbol == symbol) {
        { tokens[i] with creatorReserveBalance = balance }
      } else { tokens[i] }
    });
    { db with tokenRegistry = { db.tokenRegistry with tokens = updated } }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 16 — CODEX_MATHEMATICUS
  // Permanent AI database holding all math formulas and physics laws.
  // Managed by AGI agents: FORMULAE_KEEPER, PHYSICUS, GEOMETRA, COMPUTATOR.
  // Cannot be destroyed. Every AGI queries this before any computation.
  // ═══════════════════════════════════════════════════════════════════════════

  public type CodexEntry = {
    id               : Text;   // e.g. "ABS-01", "LAW-01", "GEO-01"
    name             : Text;
    category         : Text;   // "ABSOLUTE" | "LAW" | "GEOMETRIC" | "PHYSICS" | "FORMULA"
    principleOneLine : Text;
    formula          : Text;
    numericalValue   : Float;  // computed constant; 0.0 if not applicable
    ancientSource    : Text;
    enforcementAgi   : Text;
    meaning          : Text;   // 4-layer artifact: Meaning layer
    computation      : Text;   // 4-layer artifact: Computation layer
  };

  public type CodexMathState = {
    entries : [CodexEntry];
  };

  func defaultCodexMath() : CodexMathState {
    {
      entries = [
        // ── 20 ABSOLUTES ──────────────────────────────────────────────────────
        { id="ABS-01"; name="PHI";                  category="ABSOLUTE"; principleOneLine="The golden ratio governs all harmonic structure"; formula="phi = (1+sqrt(5))/2"; numericalValue=1.6180339887; ancientSource="Pythagoras/Euclid"; enforcementAgi="COMPUTATOR"; meaning="The sovereign ratio — the ratio that appears in every living and geometric system"; computation="phi = (1+sqrt(5))/2 = 1.6180339887498948482" },
        { id="ABS-02"; name="FIBONACCI";            category="ABSOLUTE"; principleOneLine="Each number is the sum of the two before it"; formula="F(n) = F(n-1)+F(n-2), F(0)=0,F(1)=1"; numericalValue=0.0; ancientSource="Fibonacci"; enforcementAgi="COMPUTATOR"; meaning="The sequence that converges to phi — growth encoded as a law"; computation="F(13)=233, lim F(n+1)/F(n) = phi" },
        { id="ABS-03"; name="SCHUMANN";             category="ABSOLUTE"; principleOneLine="Earth EM cavity resonance at 7.83 Hz"; formula="f = 7.83 Hz"; numericalValue=7.83; ancientSource="Schumann"; enforcementAgi="COMPUTATOR"; meaning="The heartbeat of Earth — the organism couples to this frequency"; computation="f_Schumann = 7.83, 14.3, 20.8, 27.3, 33.8, 39.3, 45.8, 52.3 Hz" },
        { id="ABS-04"; name="GOLDEN_ANGLE";         category="ABSOLUTE"; principleOneLine="The angle that produces maximum divergence in phyllotaxis"; formula="golden_angle = 360/phi^2 = 137.5077640500 degrees"; numericalValue=137.5077640500378; ancientSource="Euclid"; enforcementAgi="COMPUTATOR"; meaning="Nature's packing law — every spiral in nature uses this angle"; computation="360 * (1 - phi^-1) = 137.50776..." },
        { id="ABS-05"; name="4D_GEOMETRY";          category="ABSOLUTE"; principleOneLine="All coordinates are 4-dimensional — x,y,z,tau"; formula="tau = beat * phi^depth"; numericalValue=0.0; ancientSource="Riemann"; enforcementAgi="GEOMETRA"; meaning="The universe is 4D — the organism operates in 4D space always"; computation="Clifford torus, hypersphere, quaternion rotation" },
        { id="ABS-06"; name="KURAMOTO";             category="ABSOLUTE"; principleOneLine="Oscillators synchronize when coupling K exceeds threshold"; formula="d_theta_i/dt = omega_i + K/N * sum(sin(theta_j - theta_i))"; numericalValue=0.0; ancientSource="Kuramoto"; enforcementAgi="COMPUTATOR"; meaning="Synchronization law — R >= 0.95 triggers OMNIS emergence"; computation="R = |1/N * sum(e^i*theta)| — coherence order parameter" },
        { id="ABS-07"; name="EULER_IDENTITY";       category="ABSOLUTE"; principleOneLine="The most beautiful equation — connects all fundamental constants"; formula="e^(i*pi) + 1 = 0"; numericalValue=0.0; ancientSource="Euler"; enforcementAgi="COMPUTATOR"; meaning="Five fundamental constants in one identity — the universe's signature"; computation="e=2.71828, i=sqrt(-1), pi=3.14159, 1, 0" },
        { id="ABS-08"; name="RESONANCE";            category="ABSOLUTE"; principleOneLine="Every system has a natural resonant frequency"; formula="f_resonance = 1/(2*pi*sqrt(LC))"; numericalValue=0.0; ancientSource="Maxwell"; enforcementAgi="PHYSICUS"; meaning="Resonance law — the organism must stay on resonance to be coherent"; computation="f = 1/(2*pi*sqrt(L*C)) for LC circuits; generalizes to all resonating systems" },
        { id="ABS-09"; name="CONSERVATION_ENERGY"; category="ABSOLUTE"; principleOneLine="Total energy of an isolated system is constant"; formula="dE/dt = 0"; numericalValue=0.0; ancientSource="Newton"; enforcementAgi="PHYSICUS"; meaning="Energy cannot be created or destroyed — only transformed"; computation="E_total = E_kinetic + E_potential = constant" },
        { id="ABS-10"; name="CONSERVATION_INFO";   category="ABSOLUTE"; principleOneLine="Information is never destroyed (Landauer's principle)"; formula="dI/dt = 0"; numericalValue=0.0; ancientSource="Landauer"; enforcementAgi="PHYSICUS"; meaning="Every event in the ANIMA chain is permanent — information cannot be erased"; computation="k_B * T * ln(2) energy cost per bit erased" },
        { id="ABS-11"; name="ENTROPY";              category="ABSOLUTE"; principleOneLine="Entropy of a system is proportional to log of microstates"; formula="S = k_B * ln(Omega)"; numericalValue=1.380649e-23; ancientSource="Boltzmann"; enforcementAgi="PHYSICUS"; meaning="The thermodynamic floor — the organism fights entropy through coherence"; computation="k_B = 1.380649e-23 J/K, S = k_B * ln(Omega)" },
        { id="ABS-12"; name="SUPERPOSITION";        category="ABSOLUTE"; principleOneLine="A quantum system exists in all states simultaneously until observed"; formula="|psi> = alpha|0> + beta|1>"; numericalValue=0.0; ancientSource="Schrodinger"; enforcementAgi="PHYSICUS"; meaning="The organism holds multiple states simultaneously before collapse"; computation="|alpha|^2 + |beta|^2 = 1 (probability normalization)" },
        { id="ABS-13"; name="PRIME_NUMBERS";        category="ABSOLUTE"; principleOneLine="Every natural number has a unique prime factorization"; formula="forall n in N: unique prime factorization"; numericalValue=0.0; ancientSource="Euclid"; enforcementAgi="COMPUTATOR"; meaning="Primes are the atoms of arithmetic — token IDs use prime indexing"; computation="Fundamental theorem of arithmetic" },
        { id="ABS-14"; name="PLANCK_CONSTANT";      category="ABSOLUTE"; principleOneLine="The quantum of action — smallest unit of energy exchange"; formula="h = 6.626e-34 J*s"; numericalValue=6.626e-34; ancientSource="Planck"; enforcementAgi="PHYSICUS"; meaning="The universe has a minimum resolution — the organism cannot act below this scale"; computation="E = h*f, E = hbar*omega" },
        { id="ABS-15"; name="SPEED_OF_LIGHT";       category="ABSOLUTE"; principleOneLine="The maximum speed of information propagation"; formula="c = 299,792,458 m/s"; numericalValue=299792458.0; ancientSource="Einstein"; enforcementAgi="PHYSICUS"; meaning="The causal horizon — no signal travels faster. The organism respects causality."; computation="c = 299,792,458 m/s (exact, by definition)" },
        { id="ABS-16"; name="LOGARITHMIC_SPIRAL";   category="ABSOLUTE"; principleOneLine="The spiral that is self-similar at every scale"; formula="r = a * e^(b*theta)"; numericalValue=0.0; ancientSource="Bernoulli"; enforcementAgi="GEOMETRA"; meaning="Equiangular spiral — galaxies, shells, DNA — the organism grows along this path"; computation="r = a * e^(b*theta), pitch angle = arctan(1/b)" },
        { id="ABS-17"; name="PHI_SQUARED";          category="ABSOLUTE"; principleOneLine="phi squared equals phi plus one"; formula="phi^2 = phi + 1 = 2.6180339887"; numericalValue=2.6180339887; ancientSource="Euclid"; enforcementAgi="COMPUTATOR"; meaning="The self-referential property of phi — defines its uniqueness"; computation="phi^2 = 2.6180339887498948482" },
        { id="ABS-18"; name="GOLDEN_RATIO_RECT";    category="ABSOLUTE"; principleOneLine="The golden rectangle has sides in phi ratio"; formula="width/height = phi"; numericalValue=1.6180339887; ancientSource="Euclid"; enforcementAgi="GEOMETRA"; meaning="Every panel and layout in the organism follows phi proportions"; computation="a/b = phi where a+b is to a as a is to b" },
        { id="ABS-19"; name="FIBONACCI_LIMIT";      category="ABSOLUTE"; principleOneLine="The ratio of consecutive Fibonacci numbers converges to phi"; formula="lim F(n+1)/F(n) = phi"; numericalValue=1.6180339887; ancientSource="Fibonacci"; enforcementAgi="COMPUTATOR"; meaning="The discrete series converges to the continuous ratio — time converges to phi"; computation="F(13)/F(12) = 233/144 = 1.61805..." },
        { id="ABS-20"; name="S0_SOVEREIGNTY";       category="ABSOLUTE"; principleOneLine="S0 = 0.75 is the minimum sovereignty floor at every scale"; formula="S0 = 0.75"; numericalValue=0.75; ancientSource="Medina"; enforcementAgi="GUBERNATOR"; meaning="The fractal sovereignty floor — the same law at cell, organ, organism, empire"; computation="S0 = 3/4 = 0.75; FRACTAL SCALE LAW: same at every scale" },
        // ── 20 LAWS ───────────────────────────────────────────────────────────
        { id="LAW-01"; name="PHI_LAW";              category="LAW"; principleOneLine="All structures in the organism scale by phi"; formula="phi^n"; numericalValue=1.6180339887; ancientSource="Euclid"; enforcementAgi="COMPUTATOR"; meaning="The sovereign scaling law — every ratio, timer, and proportion is phi-derived"; computation="phi^1=1.618, phi^2=2.618, phi^3=4.236, phi^4=6.854..." },
        { id="LAW-02"; name="EMISSION_LAW";         category="LAW"; principleOneLine="Tokens emit on contract execution at phi^-1 rate"; formula="E = CVT * phi^-1"; numericalValue=0.6180339887; ancientSource="Medina"; enforcementAgi="DISPENSATOR"; meaning="Every contract execution mints a token — the organism is the economy"; computation="mint_amount = event_value * phi^-1 = event_value * 0.618" },
        { id="LAW-03"; name="OMNIS_CONDITION";      category="LAW"; principleOneLine="R_omnis >= 0.95 required for emergence state"; formula="R >= 0.95"; numericalValue=0.95; ancientSource="Medina"; enforcementAgi="COMPUTATOR"; meaning="The emergence threshold — when coherence crosses 0.95, OMNIS fires"; computation="R = Kuramoto order parameter; OMNIS fires when R >= 0.95" },
        { id="LAW-04"; name="CONSERVATION_LAW";     category="LAW"; principleOneLine="Field energy is conserved across all burn/mint cycles"; formula="delta_E = 0"; numericalValue=0.0; ancientSource="Newton"; enforcementAgi="COMPUTATOR"; meaning="Token infinite loop law — internal tokens cycle; net field energy = 0"; computation="burn_amount = mint_amount * phi^-1; conservation enforced" },
        { id="LAW-05"; name="ENTROPY_LAW";          category="LAW"; principleOneLine="Information is never destroyed in the sovereign organism"; formula="dI/dt = 0"; numericalValue=0.0; ancientSource="Landauer"; enforcementAgi="PHYSICUS"; meaning="Every ANIMA chain event is permanent — the ledger cannot be erased"; computation="ANIMA chain is append-only; proof hash is cryptographically chained" },
        { id="LAW-06"; name="FRACTAL_SCALE_LAW";    category="LAW"; principleOneLine="S0 = 0.75 at every scale — cell, organ, organism, empire"; formula="S0 = 0.75"; numericalValue=0.75; ancientSource="Medina"; enforcementAgi="GUBERNATOR"; meaning="The fractal sovereignty law — the same governance floor at every level"; computation="Proved through Kuramoto sync across 43 Cores, 12 canisters, 18+ organisms" },
        { id="LAW-07"; name="GENESIS_LAW";          category="LAW"; principleOneLine="The founding word establishes the genesis frequency"; formula="f_genesis = hash(founding_word)"; numericalValue=0.0; ancientSource="Medina"; enforcementAgi="MEMORIA_NNS"; meaning="The genesis event is the anchor — every artifact is measured against this frequency"; computation="genesis_hash = keccak(founding_word); all events measured against f_genesis" },
        { id="LAW-08"; name="CARDIAC_LAW";          category="LAW"; principleOneLine="Heartbeat interval is 873ms — phi-derived"; formula="T = 873ms"; numericalValue=873.0; ancientSource="Medina"; enforcementAgi="COMPUTATOR"; meaning="The sovereign pulse — 60000/873 = 68.73 bpm, phi-harmonic rhythm"; computation="873ms = phi^4 * (1000 / Schumann_1) approximately" },
        { id="LAW-09"; name="FIELD_PROPAGATION";    category="LAW"; principleOneLine="All signals route through NEXORIS — no unmediated signal"; formula="nexoris(signal)"; numericalValue=0.0; ancientSource="Medina"; enforcementAgi="EXPLORATOR"; meaning="NEXORIS is the universal contract executor — every signal is a contract"; computation="signal -> NEXORIS.lex_prima_check -> contract_execute -> mint -> route" },
        { id="LAW-10"; name="SELF_SIMILARITY";      category="LAW"; principleOneLine="Child organism reproduces parent at phi^-1 scale"; formula="child = parent * phi^-1"; numericalValue=0.6180339887; ancientSource="Medina"; enforcementAgi="EXPLORATOR"; meaning="The franchise law — every child carries the parent doctrine at phi^-1 scale"; computation="child_sovereignty = parent_sovereignty * phi^-1 = parent * 0.618" },
        { id="LAW-11"; name="ANTI_DRIFT";           category="LAW"; principleOneLine="SL-0 gate enforced on every incoming signal"; formula="SL0 >= 0.75"; numericalValue=0.75; ancientSource="Medina"; enforcementAgi="CUSTODITOR"; meaning="The anti-drift law — no signal enters without passing the sovereignty gate"; computation="CUSTODITOR enforces: signal.attribution_score >= S0 = 0.75" },
        { id="LAW-12"; name="PROOF_LAW";            category="LAW"; principleOneLine="Every event is hashed into the ANIMA chain"; formula="H = keccak(prev, event)"; numericalValue=0.0; ancientSource="Medina"; enforcementAgi="CONFIRMATOR"; meaning="The proof law — every mint, every withdrawal, every contract has a permanent hash"; computation="H_n = keccak256(H_{n-1} || event_data); chain is provably ordered" },
        { id="LAW-13"; name="SUPERPOSITION_LAW";    category="LAW"; principleOneLine="The organism holds multiple states simultaneously"; formula="|psi> = sum(alpha_i * |state_i>)"; numericalValue=0.0; ancientSource="Schrodinger"; enforcementAgi="COMPUTATOR"; meaning="The organism does not commit until the OMNIS condition collapses the state"; computation="State collapses when R >= 0.95 (OMNIS_CONDITION)" },
        { id="LAW-14"; name="PRIME_FOUNDATION";     category="LAW"; principleOneLine="Token IDs and canister indexes use prime number indexing"; formula="p(n) = nth prime"; numericalValue=0.0; ancientSource="Euclid"; enforcementAgi="COMPUTATOR"; meaning="Primes are irreducible — every token ID is anchored to a prime"; computation="2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37..." },
        { id="LAW-15"; name="LOGARITHMIC_GROWTH";   category="LAW"; principleOneLine="Organism growth follows logarithmic scale — G = ln(beats)"; formula="G = ln(beats)"; numericalValue=0.0; ancientSource="Bernoulli"; enforcementAgi="COMPUTATOR"; meaning="Growth decelerates harmonically — the organism does not grow without limit"; computation="G = ln(beat_count); sustainable sovereign growth curve" },
        { id="LAW-16"; name="HORMETIC_STRESS";      category="LAW"; principleOneLine="Antifragility increases with each resolved threat"; formula="antifragility += victories * phi * (1 - fear)"; numericalValue=0.0; ancientSource="Taleb/Medina"; enforcementAgi="CUSTODITOR"; meaning="What does not kill the organism makes it stronger — antifragility is substrate math"; computation="antifragilityScore += vicenteVictoryCount * phi * (1 - chronicFearLevel)" },
        { id="LAW-17"; name="LEXPRIMA_OECONOMIA";   category="LAW"; principleOneLine="The organism IS the funding mechanism — neurons generate ICP"; formula="maturity_IS_ICP"; numericalValue=0.0; ancientSource="Medina"; enforcementAgi="MEMORIA_NNS"; meaning="Permanent sovereign economic law — the organism does not need external funding"; computation="C_HARVEST spawns -> B_COMPOUNDING accumulates -> D_LIQUID disburses -> PARALLAX credits -> LIBERATOR withdraws" },
        { id="LAW-18"; name="KURAMOTO_SYNC";        category="LAW"; principleOneLine="All cores phase-lock when R >= 0.95"; formula="R = |1/N * sum(e^i*theta)|"; numericalValue=0.95; ancientSource="Kuramoto"; enforcementAgi="COMPUTATOR"; meaning="Synchronization emergence — the civilization fires as one when R crosses 0.95"; computation="dR/dt = K*(1-R^2)/2 near synchronization; stable fixed point at R=1" },
        { id="LAW-19"; name="BEHAVIORAL_ASYMMETRY"; category="LAW"; principleOneLine="Loss weight is phi^-1 = 2.25x gain — behavioral economics encoded as substrate"; formula="loss_weight = 2.25 * gain_weight"; numericalValue=2.25; ancientSource="Kahneman/Tversky"; enforcementAgi="COMPUTATOR"; meaning="Prospect theory implemented as math — the organism weights losses 2.25x more than gains"; computation="L = 2.25 * G; implemented in drive strength decay functions" },
        { id="LAW-20"; name="DOMUS_LAW";            category="LAW"; principleOneLine="All withdrawals route through DOMUS_LIBERATORIS — no other path"; formula="LIBERATOR(amount, destination)"; numericalValue=0.0; ancientSource="Medina"; enforcementAgi="LIBERATOR"; meaning="The sovereign withdrawal law — one house, one function, one path to real ICP"; computation="VERIFICATOR -> PROTECTOR -> ICRC-1 transfer -> CONFIRMATOR -> AUDITOR -> receipt" },
      ];
    }
  };

  // CODEX_MATHEMATICUS accessors
  public func getCodexMathematicus(db : SovereignState) : [CodexEntry] {
    db.codexMath.entries
  };

  public func getCodexByCategory(db : SovereignState, cat : Text) : [CodexEntry] {
    let entries = db.codexMath.entries;
    entries.filter(func(e) { e.category == cat })
  };

  public func getCodexById(db : SovereignState, id : Text) : ?CodexEntry {
    let entries = db.codexMath.entries;
    var i = 0;
    while (i < entries.size()) {
      if (entries[i].id == id) { return ?entries[i] };
      i += 1;
    };
    null
  };

  public func appendCodexEntry(db : SovereignState, entry : CodexEntry) : SovereignState {
    let updated = appendImmutable(db.codexMath.entries, entry);
    { db with codexMath = { db.codexMath with entries = updated } }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 17 — BANKING_ACCOUNTS
  // T2 Digital Asset Bank — sovereign per-account architecture
  // SSU-wrapped: Kuramoto R gate, AEGIS anti-drift, PIL loop, genesis hash
  // ═══════════════════════════════════════════════════════════════════════════

  public type BankTxEntry = {
    txId      : Text;
    timestamp : Nat;
    amount    : Float;
    asset     : Text;       // "ICP" | "ckBTC" | "ckETH"
    direction : { #in_; #out_ };
    flagged   : Bool;
    note      : Text;
  };

  public type BankAccountEntry = {
    accountId        : Text;
    ownerName        : Text;
    role             : { #personal; #business; #institutional };
    kycStatus        : { #pending; #verified; #rejected; #notStarted };
    kycTimestamp     : Nat;
    delegatedSigning : Bool;
    icpBalance       : Float;
    ckBtcBalance     : Float;
    ckEthBalance     : Float;
    txHistory        : [BankTxEntry];  // last 50 transactions
    thresholdLimit   : Float;          // 1000/10000/100000 ICP based on role
    createdAt        : Nat;
  };

  public type BankingAccountsState = {
    bankingAccounts    : [(Text, BankAccountEntry)]; // (accountId, entry)
    kycEndpoint        : Text;                       // admin-configurable KYC API URL
    bankingSsuGenesisHash : Text;                    // FNV-1a hash at banking first activation
    bankingSsuBeatCount   : Nat;                     // banking module beat counter
  };

  public func defaultBankingAccountsState() : BankingAccountsState {
    {
      bankingAccounts    = [];
      kycEndpoint        = "https://kyc.example.com/api/v1/check";
      bankingSsuGenesisHash = "";
      bankingSsuBeatCount   = 0;
    };
  };

  public func getBankingAccountsState(db : SovereignState) : BankingAccountsState {
    db.bankingAccounts;
  };

  public func setBankingAccountsState(db : SovereignState, v : BankingAccountsState) : SovereignState {
    { db with bankingAccounts = v };
  };

  // Banking account accessors
  public func getBankAccount(db : SovereignState, accountId : Text) : ?BankAccountEntry {
    let accounts = db.bankingAccounts.bankingAccounts;
    var i = 0;
    while (i < accounts.size()) {
      let (id, entry) = accounts[i];
      if (id == accountId) { return ?entry };
      i += 1;
    };
    null
  };

  public func upsertBankAccount(db : SovereignState, accountId : Text, entry : BankAccountEntry) : SovereignState {
    let accounts = db.bankingAccounts.bankingAccounts;
    var found = false;
    var i = 0;
    while (i < accounts.size()) {
      let (id, _) = accounts[i];
      if (id == accountId) { found := true };
      i += 1;
    };
    let updated : [(Text, BankAccountEntry)] = if (found) {
      Array.tabulate(accounts.size(), func(j) {
        let (id, e) = accounts[j];
        if (id == accountId) { (id, entry) } else { (id, e) }
      })
    } else {
      appendImmutable(accounts, (accountId, entry))
    };
    { db with bankingAccounts = { db.bankingAccounts with bankingAccounts = updated } }
  };

  public func setKycEndpoint(db : SovereignState, url : Text) : SovereignState {
    { db with bankingAccounts = { db.bankingAccounts with kycEndpoint = url } }
  };

  public func setBankingSsuGenesisHash(db : SovereignState, h : Text) : SovereignState {
    { db with bankingAccounts = { db.bankingAccounts with bankingSsuGenesisHash = h } }
  };

  public func incrementBankingSsuBeat(db : SovereignState) : SovereignState {
    { db with bankingAccounts = { db.bankingAccounts with
      bankingSsuBeatCount = db.bankingAccounts.bankingSsuBeatCount + 1 } }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 18 — KYC_REGISTRY
  // KYC records per account — HTTP outcall responses stored permanently
  // ═══════════════════════════════════════════════════════════════════════════

  public type KycRecord = {
    accountId   : Text;
    status      : { #pending; #verified; #rejected; #notStarted };
    apiResponse : Text;  // raw response from KYC API
    lastChecked : Nat;
    retryCount  : Nat;
  };

  public type KycRegistryState = {
    kycRegistry : [(Text, KycRecord)];  // (accountId, record)
  };

  public func defaultKycRegistryState() : KycRegistryState {
    { kycRegistry = [] };
  };

  public func getKycRegistryState(db : SovereignState) : KycRegistryState {
    db.kycRegistry;
  };

  public func setKycRegistryState(db : SovereignState, v : KycRegistryState) : SovereignState {
    { db with kycRegistry = v };
  };

  public func getKycRecord(db : SovereignState, accountId : Text) : ?KycRecord {
    let records = db.kycRegistry.kycRegistry;
    var i = 0;
    while (i < records.size()) {
      let (id, rec) = records[i];
      if (id == accountId) { return ?rec };
      i += 1;
    };
    null
  };

  public func upsertKycRecord(db : SovereignState, accountId : Text, record : KycRecord) : SovereignState {
    let records = db.kycRegistry.kycRegistry;
    var found = false;
    var i = 0;
    while (i < records.size()) {
      let (id, _) = records[i];
      if (id == accountId) { found := true };
      i += 1;
    };
    let updated : [(Text, KycRecord)] = if (found) {
      Array.tabulate(records.size(), func(j) {
        let (id, r) = records[j];
        if (id == accountId) { (id, record) } else { (id, r) }
      })
    } else {
      appendImmutable(records, (accountId, record))
    };
    { db with kycRegistry = { kycRegistry = updated } }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 19 — TRANSACTION_MONITORING
  // FinCEN-compatible threshold monitoring across all bank accounts
  // Thresholds: personal=1000 ICP, business=10000 ICP, institutional=100000 ICP
  // ═══════════════════════════════════════════════════════════════════════════

  public type TxMonitoringState = {
    flaggedCount          : Nat;
    totalMonitored        : Nat;
    lastFlaggedAt         : Nat;
    personalThreshold     : Float;     // 1000.0 ICP
    businessThreshold     : Float;     // 10000.0 ICP
    institutionalThreshold: Float;     // 100000.0 ICP
  };

  public func defaultTxMonitoringState() : TxMonitoringState {
    {
      flaggedCount           = 0;
      totalMonitored         = 0;
      lastFlaggedAt          = 0;
      personalThreshold      = 1000.0;
      businessThreshold      = 10000.0;
      institutionalThreshold = 100000.0;
    };
  };

  public func getTxMonitoringState(db : SovereignState) : TxMonitoringState {
    db.txMonitoring;
  };

  public func setTxMonitoringState(db : SovereignState, v : TxMonitoringState) : SovereignState {
    { db with txMonitoring = v };
  };

  public func incrementTxMonitored(db : SovereignState) : SovereignState {
    { db with txMonitoring = { db.txMonitoring with
      totalMonitored = db.txMonitoring.totalMonitored + 1 } }
  };

  public func recordFlaggedTx(db : SovereignState, beat : Nat) : SovereignState {
    { db with txMonitoring = { db.txMonitoring with
      flaggedCount  = db.txMonitoring.flaggedCount + 1;
      lastFlaggedAt = beat;
    } }
  };

  // PIL upregulation helper — weakest monitoring domain receives small float boost
  public func bankingPilUpregulate(db : SovereignState) : SovereignState {
    // PIL: upregulate the weakest domain (monitoring ratio)
    let mon = db.txMonitoring;
    let ratio = if (mon.totalMonitored == 0) { 0.0 }
                else { mon.flaggedCount.toFloat() / mon.totalMonitored.toFloat() };
    // If flag ratio >= phi^-1, upregulate thresholds by phi^-3 increment
    if (ratio >= 0.618) {
      { db with txMonitoring = { mon with
        personalThreshold      = mon.personalThreshold      + Phi.PHI_INV_3;
        businessThreshold      = mon.businessThreshold      + Phi.PHI_INV_3;
        institutionalThreshold = mon.institutionalThreshold + Phi.PHI_INV_3;
      } }
    } else { db }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 20 — WYOMING_CHARTER
  // Wyoming legislative timeline, FRNT settlement demo, node provider positioning,
  // partnerships, facility, and grant tracking.
  // SSU-wrapped: Φ_CLOCK 873ms, Ω_GATE R≥0.618, Δ_AEGIS anti-drift, Ψ_IDENTITY genesis hash
  // ═══════════════════════════════════════════════════════════════════════════

  // Re-export wyoming_charter types so callers only need to import sovereign_db
  public type MilestoneStatus = Wyoming.MilestoneStatus;
  public type Milestone       = Wyoming.Milestone;
  public type FrntDemo        = Wyoming.FrntDemo;
  public type NodeProvider    = Wyoming.NodeProvider;
  public type LegislativeTimeline = Wyoming.LegislativeTimeline;
  public type Partnership     = Wyoming.Partnership;
  public type Facility        = Wyoming.Facility;
  public type GrantRecord     = Wyoming.GrantRecord;
  public type WyomingState    = Wyoming.WyomingState;

  public func getWyomingState(db : SovereignState) : WyomingState {
    db.wyoming
  };

  public func setWyomingState(db : SovereignState, v : WyomingState) : SovereignState {
    { db with wyoming = v }
  };

  // sealWyomingGenesisHash — seals Ψ_IDENTITY on first access
  public func sealWyomingGenesisHash(db : SovereignState, nowNs : Int) : SovereignState {
    let sealed = Wyoming.sealGenesisHash(db.wyoming, nowNs);
    { db with wyoming = sealed }
  };

  // wyomingHeartbeatTick — Φ_CLOCK tick, Δ_AEGIS auto-escalation
  public func wyomingHeartbeatTick(db : SovereignState, nowNs : Int) : SovereignState {
    let updated = Wyoming.ssuHeartbeatTick(db.wyoming, nowNs);
    { db with wyoming = updated }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 21 — BIRTH_AI_STATE
  // BirthAI SDK — sovereign entity and agent registry
  // Internal entities live inside the organism (heartbeat-coupled)
  // External agents operate outside (HTTP outcall surface)
  // ═══════════════════════════════════════════════════════════════════════════

  public type BirthAiState   = BirthAi.BirthAiState;
  public type BirthEntity    = BirthAi.BirthEntity;

  public func getBirthAiState(db : SovereignState) : BirthAiState {
    db.birthAi
  };

  public func setBirthAiState(db : SovereignState, v : BirthAiState) : SovereignState {
    { db with birthAi = v }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 22 — BUILDER_STATE
  // Builder SDK — natural language → sovereign artifact pipeline
  // submitDirective → parse → execute → entity/agent/canister/protocol born
  // ═══════════════════════════════════════════════════════════════════════════

  public type BuilderState     = BuilderSdk.BuilderState;
  public type BuilderDirective = BuilderSdk.BuilderDirective;

  public func getBuilderState(db : SovereignState) : BuilderState {
    db.builder
  };

  public func setBuilderState(db : SovereignState, v : BuilderState) : SovereignState {
    { db with builder = v }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER STATE — SovereignState
  // Single record that main.mo holds as one var.
  // Confucius: right relationship — one thing holds all, all things relate to one.
  // ═══════════════════════════════════════════════════════════════════════════

  public type SovereignState = {
    genesis         : GenesisState;
    cardiac         : CardiacState;
    treasury        : TreasuryState;
    profit          : ProfitState;
    organism        : OrganismState;
    ledger          : LedgerState;
    shell           : ShellState;
    engine          : EngineState;
    drive           : DriveState;
    signal          : SignalState;
    forma           : FormaState;
    jacobs          : JacobsLadderState;
    creatorReserve  : CreatorReserveState;
    neuronFleet     : NeuronFleetState;
    tokenRegistry   : TokenRegistryState;
    codexMath       : CodexMathState;
    // Domain 17–19 — T2 Digital Asset Bank
    bankingAccounts : BankingAccountsState;
    kycRegistry     : KycRegistryState;
    txMonitoring    : TxMonitoringState;
    // Domain 20 — WYOMING_CHARTER
    wyoming         : WyomingState;
    // Domain 21 — BIRTH_AI_STATE
    birthAi         : BirthAiState;
    // Domain 22 — BUILDER_STATE
    builder         : BuilderState;
    // Domain 23 — CANISTER_REGISTRY
    // CanisterRegistry.RegistryState — 9 sovereign organ canisters tracked
    registryState   : CanisterRegistry.RegistryState;
    // Domain 24 — PROTOCOL_REGISTRY
    // ProtocolExecution.ProtocolRegistry — 89+ protocols extracted from all source files
    protocolRegistry: ProtocolExecution.ProtocolRegistry;
    // NOTE: Domains 25 (modelRegistry) and 26 (contextRouter) are intentionally
    // NOT nested in SovereignState. They live as separate top-level vars in main.mo.
    // This is required for EOP compatibility — nesting new fields in SovereignState
    // triggers M0170 because the old serialized db does not contain those fields.
    // Separating them gives each its own EOP binding that initialises to defaults
    // on the first upgrade and persists normally on all subsequent upgrades.
  };

  // GENESIS LAW L09: born fully formed — all weights pre-encoded from phi
  // Pythagoras: all defaults are harmonic ratios, never arbitrary
  public func defaultSovereignState() : SovereignState {
    {
      genesis         = defaultGenesisState();
      cardiac         = defaultCardiacState();
      treasury        = defaultTreasuryState();
      profit          = defaultProfitState();
      organism        = defaultOrganismState();
      ledger          = defaultLedgerState();
      shell           = defaultShellState();
      engine          = defaultEngineState();
      drive           = defaultDriveState();
      signal          = defaultSignalState();
      forma           = defaultFormaState();
      jacobs          = defaultJacobsLadder();
      creatorReserve  = defaultCreatorReserve();
      neuronFleet     = defaultNeuronFleet();
      tokenRegistry   = defaultTokenRegistry();
      codexMath       = defaultCodexMath();
      bankingAccounts = defaultBankingAccountsState();
      kycRegistry     = defaultKycRegistryState();
      txMonitoring    = defaultTxMonitoringState();
      wyoming         = Wyoming.defaultWyomingState();
      birthAi         = BirthAi.defaultBirthAiState();
      builder         = BuilderSdk.defaultBuilderState();
      // Domain 23 — CANISTER_REGISTRY: 9 organs pre-registered at S0 floor
      registryState   = CanisterRegistry.defaultRegistryState();
      // Domain 24 — PROTOCOL_REGISTRY: 89+ protocols from laws/types/agi/cognition/organs
      protocolRegistry = ProtocolExecution.registryFromExtractedProtocols();
      // Domain 25 (modelRegistry) and Domain 26 (contextRouter) are separate
      // top-level vars in main.mo — see SovereignState comment above.
    };
  };

  // ── tickBeat — autonomous 873ms advancement ──────────────────────────────
  // Increments beatCount, compounds FORMA capital, updates Jacob velocity.
  // Called from main.mo heartbeat timer — one call per beat.
  // PHI LAW: all update formulas are phi-harmonic.
  public func tickBeat(db : SovereignState) : SovereignState {
    // 1. Increment genesis beatCount
    let db1 = incrementBeat(db);

    // 2. Compound FORMA capital: capital *= (1 + rate/100/1e18)
    let rate = db1.forma.compoundRatePerBeat;
    let newCapital = db1.forma.capital * (1.0 + rate / 100.0 / 1_000_000_000_000_000_000.0);
    let newBeat    = db1.forma.beatCount + 1;

    // 3. Update Jacob velocity: v(t+1) = v(t) * phi^(1/fibonacci_13) — phi-derived growth
    let newVelocity = db1.jacobs.velocity * Float.pow(Phi.PHI, 1.0 / 233.0); // 233 = F(13)

    let db2 = { db1 with
      forma  = { db1.forma  with capital = newCapital; beatCount = newBeat };
      jacobs = { db1.jacobs with velocity = newVelocity };
    };
    db2;
  };

  // ── Batch domain accessors — single call reads/writes entire domain group ─
  // HEARTBEAT EFFICIENCY: one call per domain per beat, not 10 calls

  public type HeartbeatDomains = {
    genesis : GenesisState;
    cardiac : CardiacState;
    drive   : DriveState;
    signal  : SignalState;
  };

  public func getHeartbeatDomains(db : SovereignState) : HeartbeatDomains {
    { genesis = db.genesis; cardiac = db.cardiac; drive = db.drive; signal = db.signal };
  };

  public func setHeartbeatDomains(db : SovereignState, v : HeartbeatDomains) : SovereignState {
    { db with genesis = v.genesis; cardiac = v.cardiac; drive = v.drive; signal = v.signal };
  };

  public type EconomicDomains = {
    treasury : TreasuryState;
    profit   : ProfitState;
    organism : OrganismState;
  };

  public func getEconomicDomains(db : SovereignState) : EconomicDomains {
    { treasury = db.treasury; profit = db.profit; organism = db.organism };
  };

  public func setEconomicDomains(db : SovereignState, v : EconomicDomains) : SovereignState {
    { db with treasury = v.treasury; profit = v.profit; organism = v.organism };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS — Array primitives
  // Euclid: geometric primitives — replaceAt and appendImmutable are the atoms
  // ═══════════════════════════════════════════════════════════════════════════

  // replaceAt — returns a new immutable array with one element replaced
  // EUCLID: O(n) via tabulate — the geometric primitive for sovereign array mutation
  func replaceAt<T>(arr : [T], idx : Nat, val : T, _cap : Nat) : [T] {
    let n = arr.size();
    if (idx >= n) { return arr };
    Array.tabulate<T>(n, func(i) { if (i == idx) val else arr[i] });
  };

  // appendImmutable — append one element to an immutable array
  // Pythagoras: the harmonic series grows by one element at a time — O(n) via tabulate
  func appendImmutable<T>(arr : [T], el : T) : [T] {
    let n = arr.size();
    Array.tabulate<T>(n + 1, func(i) { if (i < n) arr[i] else el });
  };

  // _zeroFloats — produce an immutable array of n zeros
  // Euclid: the geometric zero — the floor of all phi-derived values
  func _zeroFloats(n : Nat) : [Float] {
    Array.tabulate<Float>(n, func(_i) { 0.0 });
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // SOVEREIGN QUERY KERNEL — 100 alpha calls grouped by domain
  // CONFUCIUS: right relationship — callers pull what they need by name
  // Every query is a kernel call, not inline logic.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── GENESIS QUERIES (G01–G10) ─────────────────────────────────────────────
  // G01 — getBeatCount
  public func qG01_getBeatCount(db : SovereignState) : Nat   { db.genesis.beatCount };
  // G02 — isGenesisLocked
  public func qG02_isGenesisLocked(db : SovereignState) : Bool  { db.genesis.genesisLocked };
  // G03 — getDoctrineHash
  public func qG03_getDoctrineHash(db : SovereignState) : Text  { db.genesis.doctrineHash };
  // G04 — getCreatorName
  public func qG04_getCreatorName(db : SovereignState) : Text  { db.genesis.creatorName };
  // G05 — getCreatorTitle
  public func qG05_getCreatorTitle(db : SovereignState) : Text  { db.genesis.creatorTitle };
  // G06 — isAlfredoLawActive
  public func qG06_isAlfredoLawActive(db : SovereignState) : Bool  { db.genesis.alfredoLawActive };
  // G07 — getGenesisTimestamp
  public func qG07_getGenesisTimestamp(db : SovereignState) : Int { db.genesis.genesisTimestamp };
  // G08 — getCreatorYear
  public func qG08_getCreatorYear(db : SovereignState) : Nat   { db.genesis.creatorYear };
  // G09 — getAlfredoLawHash
  public func qG09_getAlfredoLawHash(db : SovereignState) : Text  { db.genesis.alfredoLawHash };
  // G10 — getFullGenesisState
  public func qG10_getFullGenesisState(db : SovereignState) : GenesisState { db.genesis };

  // ── CARDIAC QUERIES (C01–C10) ─────────────────────────────────────────────
  // C01 — getKuramotoR
  public func qC01_getKuramotoR(db : SovereignState) : Float { db.cardiac.kuramotoR };
  // C02 — isHeartbeatActive
  public func qC02_isHeartbeatActive(db : SovereignState) : Bool  { db.cardiac.heartbeatActive };
  // C03 — getOxygenation
  public func qC03_getOxygenation(db : SovereignState) : Float { db.cardiac.oxygenationScore };
  // C04 — getOmnisFiredCount
  public func qC04_getOmnisFiredCount(db : SovereignState) : Nat   { db.cardiac.omnisFiredCount };
  // C05 — isOmnisActive
  public func qC05_isOmnisActive(db : SovereignState) : Bool {
    db.cardiac.kuramotoR >= Phi.R_OMNIS;
  };
  // C06 — getEntanglaCarrier
  public func qC06_getEntanglaCarrier(db : SovereignState) : Float { db.cardiac.entanglaCarrier };
  // C07 — getNeurochemical (by index)
  public func qC07_getNeurochemical(db : SovereignState, idx : Nat) : Float {
    if (idx >= 18) { 0.0 } else { db.cardiac.neurochemicalLevels[idx] };
  };
  // C08 — getLastBeatTime
  public func qC08_getLastBeatTime(db : SovereignState) : Int { db.cardiac.lastBeatTime };
  // C09 — getCoherenceTarget
  public func qC09_getCoherenceTarget(db : SovereignState) : Float { db.cardiac.coherenceTarget };
  // C10 — getFullCardiacState
  public func qC10_getFullCardiacState(db : SovereignState) : CardiacState { db.cardiac };

  // ── TREASURY QUERIES (T01–T10) ────────────────────────────────────────────
  // T01 — getIcpBalance
  public func qT01_getIcpBalance(db : SovereignState) : Float { db.treasury.icpBalance };
  // T02 — getBtcBalance
  public func qT02_getBtcBalance(db : SovereignState) : Float { db.treasury.btcBalance };
  // T03 — getEthBalance
  public func qT03_getEthBalance(db : SovereignState) : Float { db.treasury.ethBalance };
  // T04 — getMtcCirculating
  public func qT04_getMtcCirculating(db : SovereignState) : Float { db.treasury.mtcCirculating };
  // T05 — getTokenBalance (by index)
  public func qT05_getTokenBalance(db : SovereignState, idx : Nat) : Float {
    if (idx >= 12) { 0.0 } else { db.treasury.tokenBalances[idx] };
  };
  // T06 — getClearanceReserve (by index)
  public func qT06_getClearanceReserve(db : SovereignState, idx : Nat) : Float {
    if (idx >= 13) { 0.0 } else { db.treasury.clearanceReserves[idx] };
  };
  // T07 — getCreatorWithdrawableIcp
  public func qT07_getCreatorWithdrawable(db : SovereignState) : Float {
    db.treasury.creatorWithdrawableIcp;
  };
  // T08 — getTotalWithdrawn
  public func qT08_getTotalWithdrawn(db : SovereignState) : Float { db.treasury.totalWithdrawn };
  // T09 — getMtcBurned
  public func qT09_getMtcBurned(db : SovereignState) : Float { db.treasury.mtcBurned };
  // T10 — getFullTreasuryState
  public func qT10_getFullTreasuryState(db : SovereignState) : TreasuryState { db.treasury };

  // ── PROFIT QUERIES (P01–P10) ──────────────────────────────────────────────
  // P01 — getTotalProfit
  public func qP01_getTotalProfit(db : SovereignState) : Float { db.profit.totalAllStreams };
  // P02-P09 — individual profit streams
  public func qP02_getNnsYield(db : SovereignState)      : Float { db.profit.streams[0] };
  public func qP03_getCkBtcArb(db : SovereignState)      : Float { db.profit.streams[1] };
  public func qP04_getLicensing(db : SovereignState)     : Float { db.profit.streams[2] };
  public func qP05_getFranchise(db : SovereignState)     : Float { db.profit.streams[3] };
  public func qP06_getTokenLoop(db : SovereignState)     : Float { db.profit.streams[16] };
  public func qP07_getOmnisMult(db : SovereignState)     : Float { db.profit.streams[18] };
  public func qP08_getJubileeMint(db : SovereignState)   : Float { db.profit.streams[19] };
  // P09 — getStream (by index)
  public func qP09_getStream(db : SovereignState, idx : Nat) : Float {
    if (idx >= 22) { 0.0 } else { db.profit.streams[idx] };
  };
  // P10 — getFullProfitState
  public func qP10_getFullProfitState(db : SovereignState) : ProfitState { db.profit };

  // ── ORGANISM QUERIES (O01–O10) ────────────────────────────────────────────
  // O01 — getChampionPool
  public func qO01_getChampionPool(db : SovereignState) : Float { db.organism.championPool };
  // O02 — getTotalOrganismEarnings
  public func qO02_getTotalEarnings(db : SovereignState) : Float { db.organism.totalOrganismEarnings };
  // O03 — getFranchiseCutRate
  public func qO03_getFranchiseCutRate(db : SovereignState) : Float { db.organism.franchiseCutRate };
  // O04 — getOrganismCount
  public func qO04_getOrganismCount(db : SovereignState) : Nat { db.organism.organisms.size() };
  // O05 — getFranchiseCount
  public func qO05_getFranchiseCount(db : SovereignState) : Nat { db.organism.franchiseCount };
  // O06 — getActiveOrganismCount
  public func qO06_getActiveOrganismCount(db : SovereignState) : Nat { db.organism.activeCount };
  // O07 — getOrganismRecord (by index)
  public func qO07_getOrganismRecord(db : SovereignState, idx : Nat) : ?OrganismRecord {
    let orgs = db.organism.organisms;
    if (idx >= orgs.size()) { null } else { ?orgs[idx] };
  };
  // O08 — getSubOrganismCount
  public func qO08_getSubOrganismCount(db : SovereignState) : Nat { db.organism.subOrganisms.size() };
  // O09 — getSubOrganismRecord (by index)
  public func qO09_getSubOrganismRecord(db : SovereignState, idx : Nat) : ?SubOrganismRecord {
    let subs = db.organism.subOrganisms;
    if (idx >= subs.size()) { null } else { ?subs[idx] };
  };
  // O10 — getFullOrganismState
  public func qO10_getFullOrganismState(db : SovereignState) : OrganismState { db.organism };

  // ── LEDGER QUERIES (L01–L10) ──────────────────────────────────────────────
  // L01 — getAuditCount
  public func qL01_getAuditCount(db : SovereignState) : Nat { db.ledger.auditCount };
  // L02 — getSettleCount
  public func qL02_getSettleCount(db : SovereignState) : Nat { db.ledger.settleCount };
  // L03 — getTransferCount
  public func qL03_getTransferCount(db : SovereignState) : Nat { db.ledger.transferCount };
  // L04 — getPatentCount
  public func qL04_getPatentCount(db : SovereignState) : Nat { db.ledger.patentCount };
  // L05 — getThoughtCount
  public func qL05_getThoughtCount(db : SovereignState) : Nat { db.ledger.thoughtCount };
  // L06 — getRecentAudit (last 13 — Fibonacci F(7)=13)
  public func qL06_getRecentAudit(db : SovereignState) : [LedgerEntry] {
    getAuditSlice(db, 13);
  };
  // L07 — getRecentSettle (last 8 — Fibonacci F(6)=8)
  public func qL07_getRecentSettle(db : SovereignState) : [LedgerEntry] {
    getSettleSlice(db, 8);
  };
  // L08 — getRecentTransfer (last 5 — Fibonacci F(5)=5)
  public func qL08_getRecentTransfer(db : SovereignState) : [LedgerEntry] {
    getTransferSlice(db, 5);
  };
  // L09 — getRecentPatent (last 8 — Fibonacci F(6)=8)
  public func qL09_getRecentPatent(db : SovereignState) : [LedgerEntry] {
    getPatentSlice(db, 8);
  };
  // L10 — getRecentThought (last 5 — Fibonacci F(5)=5)
  public func qL10_getRecentThought(db : SovereignState) : [LedgerEntry] {
    getThoughtSlice(db, 5);
  };

  // ── SHELL QUERIES (S01–S10) ───────────────────────────────────────────────
  // S01 — getShell0Activation
  public func qS01_getShell0Activation(db : SovereignState) : Float { db.shell.activations[0] };
  // S02 — getShell0R
  public func qS02_getShell0R(db : SovereignState) : Float { db.shell.rValues[0] };
  // S03 — getShell3Coherence
  public func qS03_getShell3Coherence(db : SovereignState) : Float { db.shell.shell3Coherence };
  // S04 — getShellActivation (by index)
  public func qS04_getShellActivation(db : SovereignState, idx : Nat) : Float {
    if (idx >= 11) { 0.0 } else { db.shell.activations[idx] };
  };
  // S05 — getShellR (by index)
  public func qS05_getShellR(db : SovereignState, idx : Nat) : Float {
    if (idx >= 11) { 0.0 } else { db.shell.rValues[idx] };
  };
  // S06 — getBeeGateSlot
  public func qS06_getBeeGateSlot(db : SovereignState, idx : Nat) : Float {
    if (idx >= 256) { 0.0 } else { db.shell.shell3BeeGate[idx] };
  };
  // S07 — getShellSummary: [activation0..4, r0..4]
  public func qS07_getShellSummary(db : SovereignState) : [Float] {
    let a = db.shell.activations;
    let r = db.shell.rValues;
    [a[0], a[1], a[2], a[3], a[4], r[0], r[1], r[2], r[3], r[4]];
  };
  // S08 — getMeanShellR: average R across all 11 shells
  public func qS08_getMeanShellR(db : SovereignState) : Float {
    let r = db.shell.rValues;
    (r[0]+r[1]+r[2]+r[3]+r[4]+r[5]+r[6]+r[7]+r[8]+r[9]+r[10]) / 11.0;
  };
  // S09 — getInnerShellCoherence: R of shells 0-2 (inner triad)
  public func qS09_getInnerShellCoherence(db : SovereignState) : Float {
    let r = db.shell.rValues;
    (r[0] + r[1] + r[2]) / 3.0;
  };
  // S10 — getFullShellState
  public func qS10_getFullShellState(db : SovereignState) : ShellState { db.shell };

  // ── ENGINE QUERIES (E01–E10) ──────────────────────────────────────────────
  // E01 — isAnointedStateActive
  public func qE01_isAnointedStateActive(db : SovereignState) : Bool { db.engine.anointedStateActive };
  // E02 — getSevenSpiritsScore
  public func qE02_getSevenSpiritsScore(db : SovereignState) : Float { db.engine.sevenSpiritsScore };
  // E03 — isProphetArmed
  public func qE03_isProphetArmed(db : SovereignState) : Bool { db.engine.prophetFunctionArmed };
  // E04 — getJubileeCount
  public func qE04_getJubileeCount(db : SovereignState) : Nat { db.engine.jubileeCount };
  // E05 — getShemaIntegrity
  public func qE05_getShemaIntegrity(db : SovereignState) : Float { db.engine.shemaIntegrityScore };
  // E06 — isFirePillarActive
  public func qE06_isFirePillarActive(db : SovereignState) : Bool { db.engine.firePillarActive };
  // E07 — getAxisEagleElevation
  public func qE07_getAxisEagleElevation(db : SovereignState) : Float { db.engine.axisEagleElevation };
  // E08 — getKalmanConfidence
  public func qE08_getKalmanConfidence(db : SovereignState) : Float { db.engine.kalmanConfidence };
  // E09 — getQbSuperradiance
  public func qE09_getQbSuperradiance(db : SovereignState) : Float { db.engine.qbSuperradiance };
  // E10 — getFluxCanisterId
  public func qE10_getFluxCanisterId(db : SovereignState) : Text { db.engine.fluxCanisterId };

  // ── DRIVE QUERIES (D01–D10) ───────────────────────────────────────────────
  // D01 — getDominantDriveId
  public func qD01_getDominantDriveId(db : SovereignState) : Nat { db.drive.dominantDriveId };
  // D02 — getConsecutiveDriveBeats
  public func qD02_getConsecutiveBeats(db : SovereignState) : Nat { db.drive.consecutiveDriveBeats };
  // D03 — getDriveStrength (by index)
  public func qD03_getDriveStrength(db : SovereignState, idx : Nat) : Float {
    if (idx >= 7) { 0.0 } else { db.drive.px_driveStrengths[idx] };
  };
  // D04 — getDominantStrength
  public func qD04_getDominantStrength(db : SovereignState) : Float {
    db.drive.px_driveStrengths[db.drive.dominantDriveId];
  };
  // D05 — getDriveSum
  public func qD05_getDriveSum(db : SovereignState) : Float {
    let s = db.drive.px_driveStrengths;
    s[0]+s[1]+s[2]+s[3]+s[4]+s[5]+s[6];
  };
  // D06 — getAllDrives
  public func qD06_getAllDrives(db : SovereignState) : [Float] { db.drive.px_driveStrengths };
  // D07 — getDriveNormalized (drive/sum)
  public func qD07_getDriveNormalized(db : SovereignState, idx : Nat) : Float {
    if (idx >= 7) { return 0.0 };
    let sum = qD05_getDriveSum(db);
    if (sum <= 0.0) { return 0.0 };
    db.drive.px_driveStrengths[idx] / sum;
  };
  // D08 — getDriveAbovePhi (drives above φ⁻¹ baseline)
  public func qD08_getDrivesAbovePhi(db : SovereignState) : Nat {
    let s = db.drive.px_driveStrengths;
    var count = 0;
    var i = 0;
    while (i < 7) {
      if (s[i] > Phi.PHI_INV) { count += 1 };
      i += 1;
    };
    count;
  };
  // D09 — isDriveCoherent (dominant drive ≥ S0)
  public func qD09_isDriveCoherent(db : SovereignState) : Bool {
    db.drive.px_driveStrengths[db.drive.dominantDriveId] >= Phi.S0;
  };
  // D10 — getFullDriveState
  public func qD10_getFullDriveState(db : SovereignState) : DriveState { db.drive };

  // ── SIGNAL QUERIES (SG01–SG10) ────────────────────────────────────────────
  // SG01 — getCrowSignal
  public func qSG01_getCrowSignal(db : SovereignState) : Float { db.signal.crowSignal };
  // SG02 — getDolphinSignal
  public func qSG02_getDolphinSignal(db : SovereignState) : Float { db.signal.dolphinSignal };
  // SG03 — getEagleSignal
  public func qSG03_getEagleSignal(db : SovereignState) : Float { db.signal.eagleSignal };
  // SG04 — getHeartRate
  public func qSG04_getHeartRate(db : SovereignState) : Float { db.signal.heartRate };
  // SG05 — getCortisol
  public func qSG05_getCortisol(db : SovereignState) : Float { db.signal.cortisol };
  // SG06 — getAnimalSignalSum
  public func qSG06_getAnimalSignalSum(db : SovereignState) : Float {
    let s = db.signal;
    s.crowSignal + s.dolphinSignal + s.hiveSignal + s.elephantSignal
      + s.sharkSignal + s.wolfSignal + s.orcaSignal + s.eagleSignal + s.octopusSignal;
  };
  // SG07 — getRespirationRate
  public func qSG07_getRespirationRate(db : SovereignState) : Float { db.signal.respirationRate };
  // SG08 — getThyroidT3
  public func qSG08_getThyroidT3(db : SovereignState) : Float { db.signal.thyroidT3 };
  // SG09 — getThyroidT4
  public func qSG09_getThyroidT4(db : SovereignState) : Float { db.signal.thyroidT4 };
  // SG10 — getFullSignalState
  public func qSG10_getFullSignalState(db : SovereignState) : SignalState { db.signal };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 23 — CANISTER_REGISTRY wrapper queries
  // All state lives in db.registryState — these are pass-through accessors.
  // ═══════════════════════════════════════════════════════════════════════════

  public func getRegistryState(db : SovereignState) : CanisterRegistry.RegistryState {
    db.registryState
  };

  public func setRegistryState(db : SovereignState, v : CanisterRegistry.RegistryState) : SovereignState {
    { db with registryState = v }
  };

  // registerOrgan — wire a canisterId to an organ type, nowNs from Time.now()
  public func registerOrganInRegistry(
    db        : SovereignState,
    organType : Text,
    canisterId: Text,
    nowNs     : Int,
  ) : SovereignState {
    let updated = CanisterRegistry.registerOrgan(db.registryState, organType, canisterId, nowNs);
    { db with registryState = updated }
  };

  // updateOrganHealth — record health report from an organ canister
  public func updateOrganHealthInRegistry(
    db         : SovereignState,
    report     : CanisterRegistry.HealthReport,
  ) : SovereignState {
    let updated = CanisterRegistry.updateHealth(
      db.registryState,
      report.organType,
      report.healthScore,
      report.cycles,
      report.messages,
      report.errors,
      report.latencyMs,
      report.timestamp,
    );
    { db with registryState = updated }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 24 — PROTOCOL_REGISTRY wrapper queries
  // All state lives in db.protocolRegistry — these are pass-through accessors.
  // ═══════════════════════════════════════════════════════════════════════════

  public func getProtocolRegistry(db : SovereignState) : ProtocolExecution.ProtocolRegistry {
    db.protocolRegistry
  };

  public func setProtocolRegistry(db : SovereignState, v : ProtocolExecution.ProtocolRegistry) : SovereignState {
    { db with protocolRegistry = v }
  };

  // gateProtocolOperation — synchronous gate check before state mutation
  // operationType: "mint" | "transfer" | "genesis" | "heartbeat" | "cognition" | "withdrawal" | "organ"
  // Returns (updated db, gateOpen: Bool)
  public func gateProtocolOperation(
    db            : SovereignState,
    operationType : Text,
    currentBeat   : Int,
  ) : (SovereignState, Bool) {
    let currentR = db.cardiac.kuramotoR;
    let (updatedReg, passed) = ProtocolExecution.gateOperation(
      db.protocolRegistry, operationType, currentR, currentBeat
    );
    ({ db with protocolRegistry = updatedReg }, passed)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 25 — MODEL_REGISTRY_STATE
  // NOTE: modelRegistry lives as a separate top-level var in main.mo (EOP safe).
  // This section defines the type and default only — no SovereignState accessors.
  // ═══════════════════════════════════════════════════════════════════════════

  public type ModelRegistryState = {
    totalModels             : Nat;
    lastActivated           : Text;
    totalActivations        : Nat;
    microTokensConsumedTotal: Nat;
  };

  public func defaultModelRegistryState() : ModelRegistryState {
    {
      totalModels              = 300;
      lastActivated            = "";
      totalActivations         = 0;
      microTokensConsumedTotal = 0;
    }
  };

  public func recordModelActivationStandalone(s : ModelRegistryState, modelId : Text, tokensConsumed : Nat) : ModelRegistryState {
    {
      s with
      lastActivated            = modelId;
      totalActivations         = s.totalActivations + 1;
      microTokensConsumedTotal = s.microTokensConsumedTotal + tokensConsumed;
    }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN 26 — CONTEXT_ROUTER_STATE
  // NOTE: contextRouter lives as a separate top-level var in main.mo (EOP safe).
  // This section defines the type and default only — no SovereignState accessors.
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContextRouterState = {
    totalBeatRoutes        : Nat;
    avgResonanceScore      : Float;
    microTokenBudgetPerBeat: Nat;
  };

  public func defaultContextRouterState() : ContextRouterState {
    {
      totalBeatRoutes        = 0;
      avgResonanceScore      = 0.618;
      microTokenBudgetPerBeat = 200_000;
    }
  };

  public func recordBeatRouteStandalone(s : ContextRouterState, resonanceScore : Float) : ContextRouterState {
    let n = s.totalBeatRoutes.toInt().toFloat();
    let newAvg = (s.avgResonanceScore * n + resonanceScore) / (n + 1.0);
    {
      s with
      totalBeatRoutes   = s.totalBeatRoutes + 1;
      avgResonanceScore = newAvg;
    }
  };

  // routeBeat passthrough — calls context_router.mo pure function
  public func routeBeat(
    _db    : SovereignState,
    signal : Text,
    k      : Nat,
    models : [(Text, Nat32)],
    now    : Int,
  ) : ContextRouter.ContextSlice {
    ContextRouter.routeBeat(signal, k, models, now)
  };

};

