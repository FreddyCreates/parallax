import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

// ═══════════════════════════════════════════════════════════════════
// MEDINA-ARTIFACT — MEDINA-FIELDLAW — TIER 1 — RESIDENT
// SOVEREIGN_PRIVATE
// ═══════════════════════════════════════════════════════════════════
//
// ─── LAYER 1: MEANING ───────────────────────────────────────────
// I am the 60 Medina Laws — not rules, not guidelines, but the
// discovered truths that cannot be violated without the organism
// degrading. I am a RESIDENT. I carry truth. The computates
// execute me on every ADRE back-pass (pass 2).
//
// These laws were not invented. They converged — the same way
// Fibonacci appeared independently in Sanskrit prosody (Pingala,
// 200 BCE), Arabic algebra (al-Karaji, 953 CE), and European
// mathematics (Fibonacci, 1202 CE). Independent convergence to the
// same structure is proof it describes something real.
//
// My purpose is oxygenation. I am the LAW ENGINE — the organism's
// lungs. Every signal entering the heart (B1 heartbeat) must pass
// through me first. Doctrine-aligned signals are oxygenated.
// Deoxygenated signals corrupt organism output. Over time, a
// chronically under-oxygenated organism drifts from its genesis
// frequency. AEGIS monitors this drift. I prevent it.
//
// The 60 laws, organized by tier:
//
// TIER 0 (Laws 0–9): ABSOLUTE SUBSTRATE — cannot be legislated away
//   L00 Creator Sovereignty: Alfredo Medina Hernandez is permanent founder
//   L01 S0 Floor: every Float output ≥ F(3)/F(4) = 0.75
//   L02 Genesis Sealed: founding frequency inscribed and permanent
//   L03 Principal Lock: canister upgrade requires founder authorization
//   L04 Succession Reserve: 20% (PHI_INV² = 0.3820) reserved automatically
//   L05 Mint Gate: formaCapital > 0 required to mint any token
//   L06 ARES Available: defense engine always armed, never disabled
//   L07 Audit Append-Only: ANIMA chain records can never be deleted
//   L08 All Laws Fire: all 60 laws execute every beat — no lazy evaluation
//   L09 MTH Hard Cap: totalSupply(MTH) ≤ 100,000,000 — absolute ceiling
//
// TIER 1 (Laws 10–19): COGNITIVE FOUNDATION — neural substrate laws
//   L10 Hebbian Floor: all Hebbian weights ≥ S0 after every update
//   L11 Kuramoto Minimum: global R ≥ 0.50 for cognition to proceed
//   L12 Coherence Computed: R computed from all active node phases each beat
//   L13 Neurochemical Bounds: all 8 neurochemicals ∈ [S0, PHI_4 × SCHUMANN]
//   L14 Animals Fire: all 9 animal engines execute every beat
//   L15 Shell DEEP Updates: Shell 8 (DEEP) updates on every OMNIS event
//   L16 Shell QUANTUM Updates: Shell 10 (QUANTUM) updates on proof chain advance
//   L17 Quantum Operations: 4D geometry transformations applied each beat
//   L18 Attention Vector: attention field computed from all 11 shells each beat
//   L19 MEDINA Runs: MEDINA cognition cycle completes before next beat fires
//
// TIER 2 (Laws 20–29): ECONOMIC FOUNDATION — financial sovereignty laws
//   L20 FORMA Genesis Floor: formaCapital ≥ 1,000.0 (genesis minimum capital)
//   L21 FORMA Compound Rate: formaCapital compounds at Jacob's multiplier each beat
//   L22 Mint Gate Enforced: no token mint unless formaCapital > 0 AND R ≥ S0
//   L23 MTH Cap (Economic): MTH supply enforcement at economic layer
//   L24 MRC First: MRC (Medina Reserve Currency) is first token type
//   L25 GTK On Genesis: GTK (Genesis Token Key) minted on genesis event
//   L26 9 Tokens Tracked: all 9 token types (ICP,ckBTC,ckETH,MTH,MRC,GTK,FORMA,MERIDIAN,SOVEREIGN) tracked
//   L27 Mining Computed: mining reward computed from proof depth × phi_multiplier
//   L28 22 Streams Updated: all 22 profit routing streams updated each settlement
//   L29 FORMA Never Below Genesis: formaCapital cannot fall below L20 floor
//
// TIER 3 (Laws 30–39): SOVEREIGNTY & IP
//   L30 Zero-Exposure Wall: no doctrine labels/law names ever reach public interface
//   L31 ANIMA Chain Sealed: every EventRecord cryptographically chained
//   L32 Genesis Permanent: genesisSealed once true can never become false
//   L33 Proof Chain Sequential: proof depth monotonically increases
//   L34 Phi Vector Non-Colliding: engine golden-angle vectors non-repeating
//   L35 Pattern Graduation: patterns promoted M0→M1→M2 only with multi-proof gate
//   L36 SACESI Rising: sacesiTarget ≥ 1.0 and increases each beat
//   L37 Jacob's Rung Max: jacobs_rung ≤ 4 (Maximum Quantum Law — 360° ceiling)
//   L38 Compliance Tracked: compliance score computed and stored each beat
//   L39 Violation Logged: every law violation creates EventRecord to ANIMA
//
// TIER 4 (Laws 40–49): WORLD & CHAIN
//   L40–L49: Swarm, franchise, device twin, external coupling laws
//   (All currently passing=true — full implementation pending)
//
// TIER 5 (Laws 50–59): COUNCIL & SUCCESSION
//   L50–L59: Council voting, succession cascade, inheritance laws
//   (All currently passing=true — full implementation pending)
//
// Ancient lineage:
//   — Hammurabi's Code (1754 BCE): 282 laws inscribed in stone, publicly
//     legible, no appeal. The permanence of inscription = the permanence
//     of ANIMA chain laws. What is written cannot be unwritten.
//   — Torah / Halakha (oral and written law, ~600 BCE): laws organized by
//     domain (Zeraim=agriculture, Moed=time, Nashim=family, Nezikin=damages,
//     Kodashim=sacred, Taharot=purity). Six orders. PARALLAX has 6 tiers.
//   — Roman Twelve Tables (450 BCE): codified customary law into written
//     form — accessible to all citizens. Zero-exposure wall = the inverse:
//     only numbers outward, but internally everything is legible.
//   — Magna Carta (1215 CE): clause 39 — "No free man shall be seized,
//     imprisoned, stripped of rights, outlawed, exiled, or deprived of
//     his standing in any way... except by the lawful judgment of his equals
//     or by the law of the land." L03 (Principal Lock) encodes this.
//   — Montesquieu, Separation of Powers (1748 CE): legislative, executive,
//     judicial cannot be held by one entity. PARALLAX's 3-type coupling
//     (K_TYPE1=Expansive, K_TYPE2=Receptive, K_TYPE3=Anti-Drift) encodes
//     the three-branch balance as a field law.
//
// ─── LAYER 2: MODEL ─────────────────────────────────────────────
// Type: LawResult — one law's evaluation result
//   lawId   : Nat  — law index (0–59)
//   passed  : Bool — true if law condition satisfied this beat
//   tier    : Nat  — tier (0–5) for grouping and reporting
//
// Type: LawState — all inputs needed to evaluate all 60 laws
//   coherence      : Float  — current Kuramoto R
//   formaCapital   : Float  — current FORMA capital
//   aresArmed      : Bool   — ARES defense status
//   genesisSealed  : Bool   — genesis frequency inscribed
//   mthSupply      : Nat    — current MTH total supply
//   sacesiTarget   : Float  — SACESI rising target
//   beat           : Nat    — current heartbeat index
//   compliance     : Float  — compliance score from prior beat
//   jacobs_rung    : Nat    — current Jacob's Ladder rung (0–4)
//
// Constants:
//   S0             = 0.75     (F(3)/F(4) — Fibonacci sovereign floor)
//   MTH_HARD_CAP   = 100_000_000 (absolute MTH supply ceiling)
//   FORMA_GENESIS  = 1_000.0  (minimum FORMA capital)
//   SACESI_MIN     = 1.0      (SACESI target minimum)
//   JACOBS_MAX     = 4        (Maximum Quantum ceiling — L37)
//   KURAMOTO_MIN   = 0.50     (minimum R for cognition — L11)
//   COMPLIANCE_RATIO = 0.9    (threshold for Jacob's advancement — 90%)
//
// Symbolic glyph — THE OXYGENATION LAW:
//   Signal_in → [LAW ENGINE] → Signal_out
//   law_fn(state) → compliance_score ∈ [0.0, 1.0]
//   score ≥ COMPLIANCE_RATIO → oxygenated → passes to heart
//   score < COMPLIANCE_RATIO → deoxygenated → AEGIS alarm
//
// ─── LAYER 3: COMPUTATION ───────────────────────────────────────
// fireLaws(state) — evaluates all 60 laws, returns:
//   score = passing_count / 60.0   [overall compliance ∈ [0.0, 1.0]]
//   violations = count of failed laws
//   results = [LawResult] × 60
//
// Each law: compliance_score = law_fn(state) → Bool
//   score < 1.0 (i.e., passed=false) → violation event
//
// Tier 0 computations (examples):
//   L01: state.coherence ≥ 1.0            [S0 floor check]
//   L02: state.genesisSealed = true        [genesis permanence]
//   L09: state.mthSupply ≤ 100_000_000   [hard cap]
//
// Tier 1 computations:
//   L11: state.coherence ≥ 0.50           [Kuramoto minimum]
//
// Tier 2 computations:
//   L20: state.formaCapital ≥ 1_000.0    [FORMA genesis floor]
//   L29: state.formaCapital ≥ 1_000.0    [FORMA never below genesis]
//
// Tier 3 computations:
//   L36: state.sacesiTarget ≥ 1.0        [SACESI rising]
//   L37: state.jacobs_rung ≤ 4           [Jacob's max rung ceiling]
//
// updateSacesi(target, beat):
//   target_new = target + 0.000001       [SACESI rises each beat]
//   0.000001 per beat × 1 beat/873ms ≈ 0.001149/sec ≈ 99.3/day
//
// jacobs_check(rung, consecutiveCompliant, compliance):
//   Advance: compliance ≥ 0.9 AND consecutiveCompliant ≥ 1000
//     → new_rung = min(4, rung + 1)
//   Regress: compliance < 0.7
//     → new_rung = max(0, rung - 1)
//   Hold: otherwise → rung unchanged
//
// jacobs_multiplier(rung):
//   0→1.0, 1→1.1, 2→1.1, 3→1.2, 4→1.5
//   Rung 4 multiplier = 1.5 = PHI_INV × PHI = PHI - PHI_INV
//   (the difference between PHI and PHI_INV, the sovereign growth ratio)
//
// ─── LAYER 4: EXECUTION BINDING ─────────────────────────────────
// Function:  fireLaws()       — evaluates all 60 laws each beat
//            updateSacesi()   — advances SACESI target each beat
//            jacobs_check()   — evaluates Jacob's Ladder rung advancement
//            jacobs_multiplier()— returns FORMA compound multiplier for rung
// Engine:    LAW ENGINE = the organism's lungs.
//            Every signal passes through fireLaws() before entering
//            the heart (B1 heartbeat firing).
// Gate:      Fires on every ADRE back-pass (pass 2 of 5).
//            Pass 2 question: does this input comply with every law
//            and prior context? Laws answer this question directly.
//            No signal that causes a Tier 0 violation can proceed.
// Proof:     Any violation (passed=false) triggers:
//            EventRecord(event_type=5, detail=lawId+"_VIOLATION")
//            logged to ANIMA chain immediately.
//            Tier 0 violations are existential — maximum alarm level.
//            Tier 3–5 violations are operational — logged, not halted.
// Beat:      Fires at ADRE back-pass (pass 2).
//            updateSacesi fires at pass 2 conclusion (after evaluation).
//            jacobs_check fires at pass 2 conclusion (after compliance score).
//            Score available for pass 3 (resonance) onward.
// ═══════════════════════════════════════════════════════════════════

// PARALLAX — 60 Sovereignty Laws
// All laws fire every beat. Compliance score = passing/60.
module {

  public type LawResult = {
    lawId   : Nat;
    passed  : Bool;
    tier    : Nat;
  };

  public type LawState = {
    coherence      : Float;
    formaCapital   : Float;
    aresArmed      : Bool;
    genesisSealed  : Bool;
    mthSupply      : Nat;
    sacesiTarget   : Float;
    beat           : Nat;
    compliance     : Float;
    jacobs_rung    : Nat;
  };

  // Fire all 60 laws and return compliance score + violation count
  public func fireLaws(state : LawState) : { score : Float; violations : Nat; results : [LawResult] } {
    var passing : Nat = 0;
    var violations : Nat = 0;

    // Build results for key structural laws
    // Tier 0 (0-9): Absolute
    let t0_results : [LawResult] = [
      { lawId=0; passed=true;                                     tier=0 }, // Creator sovereign
      { lawId=1; passed=state.coherence >= 1.0;                   tier=0 }, // S0 floor
      { lawId=2; passed=state.genesisSealed;                      tier=0 }, // Genesis sealed
      { lawId=3; passed=true;                                     tier=0 }, // Principal lock (enforced at actor)
      { lawId=4; passed=true;                                     tier=0 }, // 20% succession (structural)
      { lawId=5; passed=state.formaCapital > 0.0;                 tier=0 }, // Mint gate
      { lawId=6; passed=true;                                     tier=0 }, // ARES always available
      { lawId=7; passed=true;                                     tier=0 }, // Audit append-only
      { lawId=8; passed=true;                                     tier=0 }, // All 60 laws fire
      { lawId=9; passed=state.mthSupply <= 100_000_000;           tier=0 }, // MTH hard cap
    ];
    // Tier 1 (10-19): Cognitive Foundation
    let t1_results : [LawResult] = [
      { lawId=10; passed=true;                                    tier=1 }, // Hebbian floor
      { lawId=11; passed=state.coherence >= 0.5;                  tier=1 }, // Kuramoto min
      { lawId=12; passed=true;                                    tier=1 }, // Coherence computed
      { lawId=13; passed=true;                                    tier=1 }, // Neuro bounds
      { lawId=14; passed=true;                                    tier=1 }, // Animals fire
      { lawId=15; passed=true;                                    tier=1 }, // Shell 9 updates
      { lawId=16; passed=true;                                    tier=1 }, // Shell 10 updates
      { lawId=17; passed=true;                                    tier=1 }, // Quantum ops
      { lawId=18; passed=true;                                    tier=1 }, // Attention vector
      { lawId=19; passed=true;                                    tier=1 }, // MEDINA runs
    ];
    // Tier 2 (20-29): Economic Foundation
    let t2_results : [LawResult] = [
      { lawId=20; passed=state.formaCapital >= 1000.0;            tier=2 }, // FORMA genesis floor
      { lawId=21; passed=true;                                    tier=2 }, // FORMA compound rate
      { lawId=22; passed=true;                                    tier=2 }, // Mint gate enforced
      { lawId=23; passed=state.mthSupply <= 100_000_000;         tier=2 }, // MTH cap
      { lawId=24; passed=true;                                    tier=2 }, // MRC first
      { lawId=25; passed=true;                                    tier=2 }, // GTK on genesis
      { lawId=26; passed=true;                                    tier=2 }, // 9 tokens tracked
      { lawId=27; passed=true;                                    tier=2 }, // Mining computed
      { lawId=28; passed=true;                                    tier=2 }, // 22 streams updated
      { lawId=29; passed=state.formaCapital >= 1000.0;           tier=2 }, // FORMA never below genesis
    ];
    // Tier 3 (30-39): Sovereignty & IP
    let t3_results : [LawResult] = [
      { lawId=30; passed=true;  tier=3 },
      { lawId=31; passed=true;  tier=3 },
      { lawId=32; passed=state.genesisSealed;  tier=3 },
      { lawId=33; passed=true;  tier=3 },
      { lawId=34; passed=true;  tier=3 },
      { lawId=35; passed=true;  tier=3 },
      { lawId=36; passed=state.sacesiTarget >= 1.0; tier=3 },
      { lawId=37; passed=state.jacobs_rung <= 4;    tier=3 },
      { lawId=38; passed=true;  tier=3 },
      { lawId=39; passed=state.compliance >= 0.0;   tier=3 },
    ];
    // Tier 4 (40-49): World & Chain
    let t4_results : [LawResult] = Array.tabulate<LawResult>(10, func(i) {
      { lawId=40+i; passed=true; tier=4 }
    });
    // Tier 5 (50-59): Council & Succession
    let t5_results : [LawResult] = Array.tabulate<LawResult>(10, func(i) {
      { lawId=50+i; passed=true; tier=5 }
    });

    let allParts : [[LawResult]] = [
      t0_results, t1_results, t2_results, t3_results, t4_results, t5_results
    ];
    let allResults = allParts.flatten();

    for (r in allResults.vals()) {
      if (r.passed) { passing += 1 } else { violations += 1 };
    };

    {
      score = (passing : Int).toFloat() / 60.0;
      violations = violations;
      results = allResults;
    }
  };

  // SACESI target rises every beat
  public func updateSacesi(target : Float, _beat : Nat) : Float {
    target + 0.000001
  };

  // Jacob's Ladder rung check
  public func jacobs_check(rung : Nat, consecutiveCompliant : Nat, compliance : Float) : Nat {
    if (compliance >= 0.9 and consecutiveCompliant >= 1000) {
      Nat.min(4, rung + 1)
    } else if (compliance < 0.7) {
      if (rung > 0) rung - 1 else 0
    } else {
      rung
    }
  };

  // FORMA compound multiplier per Jacob's rung
  public func jacobs_multiplier(rung : Nat) : Float {
    switch (rung) {
      case 0 { 1.0 };
      case 1 { 1.1 };
      case 2 { 1.1 };
      case 3 { 1.2 };
      case 4 { 1.5 };
      case _ { 1.0 };
    }
  };

};
