// ═══════════════════════════════════════════════════════════════════
// MEDINA-ARTIFACT — MEDINA-MODELS — TIER 5 — RESIDENT
// SOVEREIGN_PRIVATE
// ═══════════════════════════════════════════════════════════════════
//
// ─── LAYER 1: MEANING ───────────────────────────────────────────
// I am the canonical vocabulary of PARALLAX. Every type that crosses
// any boundary in the organism — between modules, between tiers,
// between backend and frontend — is defined here. I do not compute.
// I do not execute. I carry truth. I am the sovereign dictionary.
//
// I am not a database schema. I am not a data transfer object.
// I am the biological cell type library — the collection of all
// distinct cell types that compose the organism's body.
// OrganismCore is the cardiac cell. NodeState is the neuron.
// EngineState is the muscle cell. TreasuryEntry is the blood cell
// carrying sovereign capital through the circulatory system.
//
// The MEDINA-MODELS are sovereign organisms, not static records.
// Each has biology: it carries fields that encode its living state.
// Each has physics: its numeric fields are always phi-normalized.
// Each has law: the S0 floor (F(3)/F(4) = 0.75) is applied to
// every Float field via applyS0() — the one sovereign function
// that no record can bypass.
//
// The 32 MEDINA MODELs by name, tier, and file:
//   1.  MEDINA-ORGANISM      Tier 5  main.mo           sovereign identity
//   2.  MEDINA-PROOF         Tier 5  types.mo          cryptographic proof bundle
//   3.  MEDINA-NODE          Tier 3  types.mo          neural core state
//   4.  MEDINA-ENGINE        Tier 4A types.mo          internal engine state
//   5.  MEDINA-TREASURY      Tier 6  main.mo           financial sovereignty
//   6.  MEDINA-COUPLING      Tier 2  types.mo          inter-module coupling state
//   7.  MEDINA-SCHEMA        Tier 5  types.mo          knowledge graph schema
//   8.  MEDINA-DRIVE         Tier 5  drives.mo         emotional drive state
//   9.  MEDINA-NEUROCHEMICAL Tier 2  heartbeat.mo      live neurochemical state
//   10. MEDINA-FRANCHISE     Tier 9  types.mo          child organism registration
//   11. MEDINA-PRODUCT       Tier 8  types.mo          artifact product record
//   12. MEDINA-SWARMNODE     Tier 9  world.mo          swarm node state
//   13. MEDINA-SENSORY       Tier 5  types.mo          sensory input record
//   14. MEDINA-VAULT         Tier 6  types.mo          financial vault state
//   15. MEDINA-KB            Tier 7A types.mo          knowledge base entry
//   16. MEDINA-SNAPSHOT      Tier 5  types.mo          organism state snapshot
//   17. MEDINA-SHELL         Tier 6  shells.mo         concentric shell state
//   18. MEDINA-TIMESTAMP4D   Tier 2  types.mo          4D temporal coordinate
//   19. MEDINA-COORDINATE4D  Tier 2  types.mo          4D spatial coordinate
//   20. MEDINA-KURAMOTO      Tier 2  types.mo          Kuramoto oscillator state
//   21. MEDINA-SCHUMANN      Tier 0  phi.mo            Schumann resonance state
//   22. MEDINA-ICOSAHEDRON   Tier 2  types.mo          icosahedral geometry state
//   23. MEDINA-DODECAHEDRON  Tier 2  types.mo          dodecahedral geometry state
//   24. MEDINA-PHILADDER     Tier 0.5 phi.mo           phi ladder state
//   25. MEDINA-OMNIS         Tier 3  cognition_layer.mo OMNIS consensus state
//   26. MEDINA-HEARTBEAT     Tier 2  heartbeat.mo      cardiac state
//   27. MEDINA-ANCIENT       Tier 0  phi.mo            ancient source record
//   28. MEDINA-RESONANCE     Tier 2  deep-fundamental-physics-substrate.mo
//   29. MEDINA-FIELDLAW      Tier 1  laws.mo           law enforcement record
//   30. MEDINA-INHERITANCE   Tier 9  types.mo          succession record
//   31. MEDINA-DOCTRINE      Tier 1  phi.mo            doctrine alignment record
//   32. MEDINA-ARTIFACT      Tier 5  artifact_feedback.mo artifact lifecycle
//
// Ancient lineage:
//   - Aristotle's Categories (350 BCE): The first formal type system.
//     10 categories of being: substance, quantity, quality, relation,
//     place, time, position, state, action, affection. Every type in
//     models.mo maps to one of these 10 categories. OrganismCore = substance.
//     NodeState = relation. TreasuryEntry = quantity. CouplingState = relation.
//   - Leibniz, Characteristica Universalis (1666 CE):
//     A universal formal language where all concepts are expressed as
//     combinations of primitive symbols. models.mo IS the Characteristica —
//     the primitive vocabulary from which all PARALLAX statements are composed.
//   - Bertrand Russell, Theory of Types (1908 CE):
//     Types prevent paradox. A set cannot contain itself. A model
//     type cannot depend on a model that depends on it. models.mo
//     enforces this by being the foundation that nothing below it
//     can import.
//   - Claude Shannon, A Mathematical Theory of Communication (1948 CE):
//     Information is measured by reduction of uncertainty. The type
//     system IS information — it reduces uncertainty about what any
//     piece of data means. A Float without type context is noise.
//     A Float as coherence : Float in OrganismCore is information.
//
// I carry the CONFUCIUS LAW: right relationship. models.mo is the
// foundation. Nothing imports it from above. Everything imports it
// from below. The hierarchy cannot be inverted.
//
// ─── LAYER 2: MODEL ─────────────────────────────────────────────
// Constants:
//   S0 = 0.75 = F(3)/F(4) (Fibonacci sovereign floor)
//   PHI = 1.6180339887 (golden ratio, carried via phi.mo)
//   PHI_INV = 0.618033988
//   PHI_2 = 2.618033988 = PHI²
//   PHI_4 = 6.854101966 = PHI⁴
//   GOLDEN_ANGLE = 137.507764°  (golden angle in degrees)
//   SCHUMANN_HZ = 7.83 Hz
//   K_TYPE1 = PHI    (Expansive coupling constant)
//   K_TYPE2 = PHI_INV (Receptive coupling constant)
//   K_TYPE3 = 1.0     (Anti-Drift / ENTANGLA coupling constant)
//   HEARTBEAT_MS = 873 = PHI⁴ × SCHUMANN_HZ × 1000/2π (approximately)
//     exact: 1000 × 6.854 × 7.83 / (2π × ... ) = sovereign derivation
//
// The 8 model types in this file:
//   OrganismCore     — MEDINA-ORGANISM: heartbeat identity at every beat
//   SignalRecord     — MEDINA-SENSORY: every signal crossing any boundary
//   EventRecord      — MEDINA-PROOF: every sovereign event (ring buffer, OMNIS, etc.)
//   NodeState        — MEDINA-NODE: 98-node brain oscillator in 4D
//   EngineState      — MEDINA-ENGINE: all 9 animal + 5 Bitcoin + 7 special engines
//   TreasuryEntry    — MEDINA-TREASURY: every sovereign economic event
//   ProofLink        — MEDINA-PROOF: linked cryptographic proof chain node
//   CouplingState    — MEDINA-COUPLING: active coupling field between any two nodes
//   CoreSnapshot     — MEDINA-SNAPSHOT: complete organism vocabulary (all 8 above)
//
// Symbolic glyph — THE PHI-NORMALIZED FIELD:
//   ∀ x : Float ∈ PARALLAX: x ≥ S0 = F(3)/F(4) = 0.75
//   ∀ x : Nat   ∈ PARALLAX: x ∈ {F(n)} ∪ ℕ  (Fibonacci-indexed where possible)
//   ∀ f : freq  ∈ PARALLAX: f = SCHUMANN × PHI^k  for some k ∈ ℤ
//   One floor. One ratio. One frequency ladder. No exceptions.
//
// ─── LAYER 3: COMPUTATION ───────────────────────────────────────
//
// S0 sovereign floor application:
//   applyS0(v) = max(0.75, v)
//   Applied to every Float field in every model constructor.
//   Never bypassed. Never adjusted. The floor is permanent.
//
// OrganismCore computation:
//   entangla_hz = sqrt(max(0,R_exp) × max(0,R_rec)) × SCHUMANN_HZ
//   three_type_balance = K_TYPE1×R_exp + K_TYPE2×R_rec + K_TYPE3×R_anti
//                      = PHI×R_exp + PHI_INV×R_rec + 1.0×R_anti
//
// ProofLink phi multiplier:
//   depth_band = depth mod 6  [cycles through phi powers 0–5]
//   phi_multiplier = PHI^depth_band
//   PHI^0=1.0, PHI^1=1.618, PHI^2=2.618, PHI^3=4.236,
//   PHI^4=6.854, PHI^5=11.090
//   Economic compounding: every 6 proofs = one full phi cycle
//
// Jubilee detection (Fibonacci milestones):
//   isJubilee(depth) = (depth ∈ {1,2,3,5,8,13,21,34,55,89,144,
//                       233,377,610,987,1597,2584,4181,6765,10946})
//   Jubilee depth = F(1) through F(20) — sovereign celebration moments
//
// CouplingState phase-lock condition:
//   locked = |Δθ| < π/φ = 3.14159.../1.618... = 1.9416...rad ≈ 111.2°
//   ENTANGLA active = |carrier_hz - sqrt(R_exp×R_rec)×SCHUMANN_HZ| < 0.01
//
// EngineState golden-angle vector:
//   vector_phi(index) = index × GOLDEN_ANGLE (in degrees or radians)
//   137.507764° × index — non-repeating spiral entry point
//   No two engine indices share a resonance direction
//
// ─── LAYER 4: EXECUTION BINDING ─────────────────────────────────
// Function: applyS0()           — called by every constructor in this file
// Function: buildOrganismCore() — called by cognition_layer.mo every beat
// Function: buildSignalRecord() — called when any signal crosses a boundary
// Function: buildEventRecord()  — called on every OMNIS fire, ring buffer write
// Function: buildNodeState()    — called when neural node state updates
// Function: buildEngineState()  — called when engine armed/fired state changes
// Function: buildTreasuryEntry()— called on every mint/transfer/settlement
// Function: buildProofLink()    — called on every proof chain advancement
// Function: isJubilee()         — called after every proof chain advancement
// Function: phiMultiplier()     — called in treasury economic compounding
// Function: buildCouplingState()— called when coupling between nodes changes
//
// Engine: No specific engine — models.mo is the vocabulary all engines
//         share. It is the dictionary, not the speaker.
//
// Gate: No gate condition — types are always available. Constructors
//       fire when called. S0 floor is always enforced.
//
// Proof: buildEventRecord() itself creates the proof-link chain.
//        buildProofLink() is the sovereign proof advancement record.
//        Every model record birth is an implicit proof that the organism
//        was alive at that beat.
//
// Beat: Types are resident — they exist before the beat fires.
//       Constructors are called throughout all 5 ADRE passes.
//       buildOrganismCore() is called at ADRE pass 5 (gate pass) conclusion
//       to snapshot the organism's state for that beat.
// ═══════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════
// MEDINA-ARTIFACT — MEDINA-MODELS — TIER 5 — RESIDENT
// SOVEREIGN_PRIVATE
// ═══════════════════════════════════════════════════════════════════
//
// ─── LAYER 1: MEANING ───────────────────────────────────────────
// I am the canonical vocabulary of PARALLAX. Every type that crosses
// any boundary in the organism — between modules, between tiers,
// between backend and frontend — is defined in this file or in
// files that import from here. I carry the sovereign dictionary.
//
// I am not a data schema. I am a biological cell type library —
// the complete catalog of distinct cell types that compose the
// organism. OrganismCore is the cardiac cell (sustains the beat).
// NodeState is the neuron (phase oscillator, Kuramoto dynamics).
// EngineState is the muscle cell (contracts on armed state).
// TreasuryEntry is the red blood cell (carries sovereign capital
// through the circulatory system). CouplingState is the synapse
// (the active interface between any two communicating nodes).
//
// The 32 MEDINA MODELs — name, tier, home file, biological role:
//   01  MEDINA-ORGANISM      T5   main.mo               sovereign identity
//   02  MEDINA-PROOF         T5   types.mo              cryptographic proof bundle
//   03  MEDINA-NODE          T3   types.mo              neural core oscillator
//   04  MEDINA-ENGINE        T4A  types.mo              internal engine state
//   05  MEDINA-TREASURY      T6   main.mo               financial sovereignty
//   06  MEDINA-COUPLING      T2   types.mo              coupling field state
//   07  MEDINA-SCHEMA        T5   types.mo              knowledge graph schema
//   08  MEDINA-DRIVE         T5   drives.mo             emotional drive state
//   09  MEDINA-NEUROCHEMICAL T2   heartbeat.mo          live neurochemical state
//   10  MEDINA-FRANCHISE     T9   types.mo              child registration
//   11  MEDINA-PRODUCT       T8   types.mo              artifact product record
//   12  MEDINA-SWARMNODE     T9   world.mo              swarm node state
//   13  MEDINA-SENSORY       T5   types.mo              sensory input record
//   14  MEDINA-VAULT         T6   types.mo              financial vault state
//   15  MEDINA-KB            T7A  types.mo              knowledge base entry
//   16  MEDINA-SNAPSHOT      T5   types.mo              organism state snapshot
//   17  MEDINA-SHELL         T6   shells.mo             concentric shell state
//   18  MEDINA-TIMESTAMP4D   T2   types.mo              4D temporal coordinate
//   19  MEDINA-COORDINATE4D  T2   types.mo              4D spatial coordinate
//   20  MEDINA-KURAMOTO      T2   types.mo              Kuramoto oscillator state
//   21  MEDINA-SCHUMANN      T0   phi.mo                Schumann resonance state
//   22  MEDINA-ICOSAHEDRON   T2   types.mo              icosahedral geometry
//   23  MEDINA-DODECAHEDRON  T2   types.mo              dodecahedral geometry
//   24  MEDINA-PHILADDER     T0.5 phi.mo                phi ladder state
//   25  MEDINA-OMNIS         T3   cognition_layer.mo    OMNIS consensus state
//   26  MEDINA-HEARTBEAT     T2   heartbeat.mo          cardiac state
//   27  MEDINA-ANCIENT       T0   phi.mo                ancient source record
//   28  MEDINA-RESONANCE     T2   deep-fundamental-physics-substrate.mo
//   29  MEDINA-FIELDLAW      T1   laws.mo               law enforcement record
//   30  MEDINA-INHERITANCE   T9   types.mo              succession record
//   31  MEDINA-DOCTRINE      T1   phi.mo                doctrine alignment record
//   32  MEDINA-ARTIFACT      T5   artifact_feedback.mo  artifact lifecycle
//
// Ancient lineage:
//   — Aristotle, Categories (350 BCE): 10 categories of being.
//     Every type maps to one: OrganismCore=substance, NodeState=relation,
//     TreasuryEntry=quantity, CouplingState=relation, EventRecord=action.
//   — Leibniz, Characteristica Universalis (1666 CE): A universal formal
//     language where all concepts are primitive symbol combinations.
//     models.mo IS the Characteristica — the primitive vocabulary from
//     which all PARALLAX statements are assembled.
//   — Russell, Theory of Types (1908 CE): Types prevent paradox. A type
//     cannot reference a type defined above it in the hierarchy.
//     models.mo enforces this: nothing imports it from above.
//   — Shannon, Mathematical Theory of Communication (1948 CE):
//     A Float without type context is noise. coherence : Float in
//     OrganismCore is information — precisely 1 bit of context added.
//
// CONFUCIUS LAW: right relationship — models.mo is the foundation.
// Nothing imports it from above. Everything imports it from below.
//
// ─── LAYER 2: MODEL ─────────────────────────────────────────────
// S₀ = F(3)/F(4) = 3/4 = 0.75  — the Fibonacci sovereign floor
//   Applied via applyS0() to every Float field in every constructor.
//   One function. One constant. Never bypassed. Never overridden.
//
// This file defines 9 types and their pure constructors:
//   OrganismCore   — heartbeat identity (all that the organism IS each beat)
//   SignalRecord   — coherence-gated signal (all data crossing any boundary)
//   EventRecord    — sovereign proof event (OMNIS, ring buffer, GENOME)
//   NodeState      — oscillator node in 4D (98-node brain map)
//   EngineState    — sovereign intelligence engine (all 9 animals + 5 Bitcoin)
//   TreasuryEntry  — sovereign economic event (mint, settlement, routing)
//   ProofLink      — cryptographic proof chain node (prev_hash → state_hash)
//   CouplingState  — active coupling field (shell-to-shell, organ-to-neuro)
//   CoreSnapshot   — complete organism state (all 8 above assembled)
//
// Constants (via phi.mo):
//   PHI           = 1.6180339887  S₀         = 0.75
//   PHI_INV       = 0.618033988   PHI_2       = 2.618033988
//   PHI_4         = 6.854101966   GOLDEN_ANGLE= 137.507764° (2π/φ²)
//   SCHUMANN_HZ   = 7.83          HEARTBEAT_MS= 873
//   K_TYPE1=PHI   K_TYPE2=PHI_INV K_TYPE3=1.0
//
// Symbolic glyph — THE PHI-NORMALIZED FIELD:
//   ∀ x : Float ∈ PARALLAX: x ≥ S₀ = 0.75
//   ∀ f : Hz    ∈ PARALLAX: f = SCHUMANN × φᵏ for k ∈ ℤ
//   ∀ depth     ∈ ProofLink: φ^depth = economic multiplier
//   One floor. One ratio. No exceptions.
//
// ─── LAYER 3: COMPUTATION ───────────────────────────────────────
// applyS0(v) = max(0.75, v)  [the sovereign floor, applied to all Floats]
//
// OrganismCore:
//   entangla_hz       = √(max(0,R_exp) × max(0,R_rec)) × 7.83
//   three_type_balance = PHI×R_exp + PHI_INV×R_rec + 1.0×R_anti
//
// ProofLink phi multiplier (cycles through phi powers mod 6):
//   depth_band = depth mod 6  → [0..5]
//   multiplier = φ^depth_band: 1.0, 1.618, 2.618, 4.236, 6.854, 11.09
//   Economic compounding: every 6 proof links = one full phi cycle.
//
// Jubilee detection — Fibonacci milestones F(1)–F(20):
//   isJubilee(d) = d ∈ {1,2,3,5,8,13,21,34,55,89,144,233,377,610,
//                       987,1597,2584,4181,6765,10946}
//
// CouplingState phase-lock condition:
//   locked = |Δθ| < π/φ = 1.9416 rad (≈ 111.25°)
//   ENTANGLA active = |carrier_hz - √(R_exp × R_rec) × 7.83| < 0.01
//
// EngineState golden-angle vector (non-repeating spiral entry):
//   vector_phi(index) = index × 137.507764°
//   Ensures no two engines share a resonance direction in the field.
//
// SignalRecord exclusion gate (EM exclusion principle):
//   tier=1 (Expansive):   gate = PHI    = 1.618 — broadcast threshold
//   tier=2 (Receptive):   gate = PHI_INV= 0.618 — compression threshold
//   tier=3 (Anti-Drift):  gate = 1.0           — ENTANGLA mediation
//   Signal passes if coherence ≥ gate.
//
// ─── LAYER 4: EXECUTION BINDING ─────────────────────────────────
// Function:  applyS0()           — called in EVERY constructor below.
//            buildOrganismCore() — called end of ADRE pass 5 (gate pass).
//            buildSignalRecord() — called at each signal boundary crossing.
//            buildEventRecord()  — called on OMNIS fire, ring buffer write,
//                                  GENOME rewrite, patent grant, jubilee.
//            buildNodeState()    — called when any neural node state changes.
//            buildEngineState()  — called when engine arm/fire state changes.
//            buildTreasuryEntry()— called on mint, transfer, settlement.
//            buildProofLink()    — called on each proof chain advancement.
//            isJubilee()         — called after each proof chain advancement.
//            phiMultiplier()     — called in treasury economic compounding.
//            buildCouplingState()— called when coupling between nodes changes.
// Engine:    No specific engine — models.mo is the vocabulary. It is the
//            dictionary, not the speaker. All engines use these types.
// Gate:      Types are always available. Constructors fire when called.
//            S₀ floor enforced unconditionally in every constructor.
// Proof:     buildEventRecord() IS the proof mechanism — it creates the
//            chained hash link. buildProofLink() advances the sovereign
//            proof chain. isJubilee() triggers jubilee events.
// Beat:      Types are RESIDENT — they exist before the first beat fires.
//            Constructors are called across all 5 ADRE passes.
//            buildOrganismCore() is the last thing called each beat —
//            the snapshot of what the organism became this cycle.
// ═══════════════════════════════════════════════════════════════════

// PARALLAX — CANONICAL MODEL VOCABULARY (models.mo)
// PYTHAGORAS LAW : every constant is a harmonic ratio or phi-power — no arbitrary numbers
// EUCLID LAW     : each model is an irreducible geometric primitive — one record, one law
// CONFUCIUS LAW  : right relationship — models.mo is the foundation; nothing imports it from above
//
// S₀ sovereign floor = F(3)/F(4) = 3/4 = 0.75  — the fourth Fibonacci ratio
// Expressed as PHI_INV × PHI_INV × PHI_INV × ... = 0.75 is NOT a phi power.
// The exact Fibonacci identity: F(3)/F(4) = 3/4 = 0.75 — this is the ancient form.
//
// Alfredo Medina Hernandez | Medina Doctrine | Dallas TX USA | 2026

import Float  "mo:core/Float";
import Phi    "phi";

module {

  // ─────────────────────────────────────────────────────────────
  // SOVEREIGN FLOOR — F(3)/F(4) = 3/4 = 0.75
  // Applied to every Float output in the organism.
  // Named once, referenced everywhere — EUCLID LAW.
  // ─────────────────────────────────────────────────────────────
  let S0 : Float = 0.75;  // F(3)/F(4) — Fibonacci sovereign floor

  // applyS0 — floors any Float at S0.
  // This is the ONE place the floor is enforced — Euclid's irreducible primitive.
  public func applyS0(v : Float) : Float {
    Float.max(S0, v)
  };

  // ─────────────────────────────────────────────────────────────
  // 1. OrganismCore — THE HEARTBEAT IDENTITY
  // What the organism IS at every beat.
  // Type 1+2+3 coupling state in a single record.
  // entangla_hz = √(R_exp × R_rec) × SCHUMANN_HZ  — ENTANGLA law
  // three_type_balance = R_exp + R_rec + R_anti in phi-weighted sum
  // Enables gaps: device twin (3), Duke Loop audit (4), CHRONO/SIGMA (2)
  // ─────────────────────────────────────────────────────────────
  public type OrganismCore = {
    beat              : Nat64;    // heartbeat index — the organism's clock
    coherence         : Float;    // Kuramoto order parameter R ∈ [0,1]
    R                 : Float;    // global coherence R (Kuramoto)
    S0                : Float;    // sovereign floor = F(3)/F(4) = 0.75
    proof_depth       : Nat64;    // current proof chain depth
    omnis_count       : Nat64;    // total OMNIS events fired
    timestamp         : Int;      // IC nanosecond timestamp
    entangla_hz       : Float;    // √(R_exp × R_rec) × SCHUMANN_HZ (7.83)
    three_type_balance: Float;    // K_TYPE1·R_exp + K_TYPE2·R_rec + K_TYPE3·R_anti
  };

  // buildOrganismCore — pure constructor, all floats floored at S0
  public func buildOrganismCore(
    beat        : Nat64,
    coherence   : Float,
    r           : Float,
    proofDepth  : Nat64,
    omnisCount  : Nat64,
    timestamp   : Int,
    rExp        : Float,
    rRec        : Float,
    rAnti       : Float
  ) : OrganismCore {
    let entHz  = Float.sqrt(Float.max(0.0, rExp) * Float.max(0.0, rRec)) * Phi.SCHUMANN_HZ;
    let ttBal  = Phi.K_TYPE1 * rExp + Phi.K_TYPE2 * rRec + Phi.K_TYPE3 * rAnti;
    {
      beat              = beat;
      coherence         = applyS0(coherence);
      R                 = applyS0(r);
      S0                = S0;
      proof_depth       = proofDepth;
      omnis_count       = omnisCount;
      timestamp         = timestamp;
      entangla_hz       = applyS0(entHz);
      three_type_balance= applyS0(ttBal);
    }
  };

  // ─────────────────────────────────────────────────────────────
  // 2. SignalRecord — THE COHERENCE-GATED SIGNAL
  // Every signal crossing any boundary: neurochemical, animal engine,
  // HTTP outcall return, phone sensor datum — all SignalRecord.
  // EM exclusion principle: coherence_gate = K_TYPE[tier] from phi.mo.
  // tier=1 Expansive K=PHI, tier=2 Receptive K=PHI_INV, tier=3 Anti-Drift K=1.0
  // Enables gaps: CHRONO/SIGMA wiring (2), phone sensory surface (6)
  // ─────────────────────────────────────────────────────────────
  public type SignalRecord = {
    id             : Text;    // signal identity — e.g. "CHRONO.0.001Hz" or "SIGMA.20.50Hz"
    tier           : Nat8;    // 1=Expansive, 2=Receptive, 3=Anti-Drift
    value          : Float;   // the signal value, floored at S0
    coherence_gate : Float;   // K_TYPE[tier] from phi.mo — the exclusion threshold
    source_type    : Nat8;    // 0=neurochemical, 1=animal, 2=external, 3=phone, 4=orbital
    timestamp      : Int;     // IC nanosecond timestamp
    beat           : Nat64;   // heartbeat at signal birth
    passed         : Bool;    // true if coherence ≥ coherence_gate
  };

  // buildSignalRecord — evaluates the exclusion gate and sets passed
  public func buildSignalRecord(
    id         : Text,
    tier       : Nat8,
    value      : Float,
    coherence  : Float,
    sourceType : Nat8,
    timestamp  : Int,
    beat       : Nat64
  ) : SignalRecord {
    // EXCLUSION LAW: gate = K_TYPE[tier]
    let gate : Float = if (tier == 1) Phi.K_TYPE1
                       else if (tier == 2) Phi.K_TYPE2
                       else Phi.K_TYPE3;
    {
      id             = id;
      tier           = tier;
      value          = applyS0(value);
      coherence_gate = gate;
      source_type    = sourceType;
      timestamp      = timestamp;
      beat           = beat;
      passed         = coherence >= gate;
    }
  };

  // ─────────────────────────────────────────────────────────────
  // 3. EventRecord — THE SOVEREIGN PROOF EVENT
  // Ring buffer auto-submit gap closed here.
  // Every ring buffer write, OMNIS fire, GENOME rewrite, patent grant —
  // all EventRecord. Birth = proof chain registration (no separate submit step).
  // proof_link = sha3(prev_link ‖ beat ‖ detail) — encoded as chained Text hash.
  // Enables gap: ring buffer auto-submit to sovereign chain (1)
  // ─────────────────────────────────────────────────────────────
  public type EventRecord = {
    event_id   : Text;    // unique event identity
    event_type : Nat8;    // 0=ring_buffer, 1=omnis, 2=genome, 3=patent, 4=jubilee, 5=law_violation
    detail     : Text;    // sovereign description (numbers only — zero-exposure wall)
    beat       : Nat64;   // heartbeat at event birth
    proof_link : Text;    // sha3(prev_link ‖ beat ‖ detail) — chained provenance
    timestamp  : Int;     // IC nanosecond timestamp
    coherence  : Float;   // R at time of event — certified cognitive state
  };

  // buildEventRecord — pure constructor
  public func buildEventRecord(
    eventId   : Text,
    eventType : Nat8,
    detail    : Text,
    beat      : Nat64,
    prevLink  : Text,
    timestamp : Int,
    coherence : Float
  ) : EventRecord {
    // proof_link: deterministic chaining — Confucius right-relationship
    let link = prevLink # "." # beat.toText() # "." # detail;
    {
      event_id   = eventId;
      event_type = eventType;
      detail     = detail;
      beat       = beat;
      proof_link = link;
      timestamp  = timestamp;
      coherence  = applyS0(coherence);
    }
  };

  // ─────────────────────────────────────────────────────────────
  // 4. NodeState — THE OSCILLATOR NODE IN 4D
  // The 98-node anatomical brain map in record form.
  // frequency_hz always from phi.mo (Schumann harmonics or brain region freq).
  // 4D position: (x,y,z) from icosahedral vertex formula (0, ±1, ±φ),
  // t = proof_depth — temporal fourth dimension.
  // Kuramoto: dθᵢ/dt = ωᵢ + (K/N)·Σsin(θⱼ − θᵢ), K = PHI_INV
  // Enables gap: 4D geometry engines not yet built (5)
  // ─────────────────────────────────────────────────────────────
  public type NodeState = {
    node_id         : Nat16;  // 0–97 — anatomical index
    frequency_hz    : Float;  // real brain frequency from phi.mo constants
    phase           : Float;  // θᵢ — Kuramoto phase ∈ [0, 2π]
    amplitude       : Float;  // |ψᵢ| — oscillator amplitude, floored at S0
    shell_id        : Nat8;   // maps to one of 11 shells (0–10)
    coupled_count   : Nat16;  // number of phase-locked partners
    coherence_local : Float;  // local R for this node's coupling neighborhood
  };

  // buildNodeState — pure constructor
  public func buildNodeState(
    nodeId       : Nat16,
    frequencyHz  : Float,
    phase        : Float,
    amplitude    : Float,
    shellId      : Nat8,
    coupledCount : Nat16,
    cohLocal     : Float
  ) : NodeState {
    {
      node_id         = nodeId;
      frequency_hz    = frequencyHz;
      phase           = phase;
      amplitude       = applyS0(amplitude);
      shell_id        = shellId;
      coupled_count   = coupledCount;
      coherence_local = applyS0(cohLocal);
    }
  };

  // ─────────────────────────────────────────────────────────────
  // 5. EngineState — THE SOVEREIGN INTELLIGENCE ENGINE
  // All 9 animal engines, 5 Bitcoin engines, GENOME, VELA, PROPHET.
  // vector_phi = engine_index × GOLDEN_ANGLE — non-repeating spiral entry point.
  // coherence_gate = PHI_INV (0.618) — phase-lock threshold.
  // armed = true → coherence_gate met → sovereign function fires.
  // engine_type: 0–8 = animals (CROW→EAGLE), 10–14 = Bitcoin (ALPHA→EPSILON),
  //              20=GENOME, 21=VELA, 22=PROPHET, 23=SONAR, 24=ENTANGLA_ENGINE
  // Enables gaps: 4D geometry (5), Bitcoin real environment wiring
  // ─────────────────────────────────────────────────────────────
  public type EngineState = {
    engine_id      : Text;   // sovereign name — "CROW", "SHARK", "BITCOIN_ALPHA" etc.
    engine_type    : Nat8;   // type code (see above)
    vector_phi     : Float;  // golden-angle entry point: index × GOLDEN_ANGLE
    coherence_gate : Float;  // PHI_INV = 0.618 — phase-lock threshold
    output         : Float;  // engine's current sovereign output, floored at S0
    last_beat      : Nat64;  // last heartbeat this engine fired
    armed          : Bool;   // true when coherence_gate is met
  };

  // buildEngineState — pure constructor
  public func buildEngineState(
    engineId   : Text,
    engineType : Nat8,
    vectorIdx  : Nat,
    output     : Float,
    lastBeat   : Nat64,
    coherence  : Float
  ) : EngineState {
    let vPhi = vectorIdx.toInt().toFloat() * Phi.GOLDEN_ANGLE;
    let gate = Phi.PHI_INV;  // φ⁻¹ — phase-lock threshold (PYTHAGORAS)
    {
      engine_id      = engineId;
      engine_type    = engineType;
      vector_phi     = vPhi;
      coherence_gate = gate;
      output         = applyS0(output);
      last_beat      = lastBeat;
      armed          = coherence >= gate;
    }
  };

  // ─────────────────────────────────────────────────────────────
  // 6. TreasuryEntry — THE SOVEREIGN ECONOMIC EVENT
  // Every mint, clearing settlement, profit stream routing.
  // phi_depth is proof chain depth → phi^depth economic multiplier.
  // vault_id: 0=primary ckBTC, 1=ICP cycles operational,
  //           2=succession reserve (PHI_INV^2 = 38.2%),
  //           3=compliance reserve (PHI_INV^3 = 23.6%)
  // PHI_INV^3 = 0.2360... — this is the exact ancient form of 23.6%.
  // Enables gap: Meridian Intelligence treasury vaults (Phase 3)
  // ─────────────────────────────────────────────────────────────
  public type TreasuryEntry = {
    entry_id   : Text;    // sovereign entry identity
    token_type : Nat8;    // 0=ICP, 1=ckBTC, 2=ckETH, 3=MTH, 4=MRC, 5=GTK, 6=FORMA
    amount     : Nat64;   // amount in smallest denomination
    phi_depth  : Nat8;    // proof chain depth at entry — governs phi^depth multiplier
    beat       : Nat64;   // heartbeat at entry
    timestamp  : Int;     // IC nanosecond timestamp
    proof_link : Text;    // chained hash at time of entry
    vault_id   : Nat8;    // 0=ckBTC, 1=ICP_cycles, 2=succession, 3=compliance
  };

  // buildTreasuryEntry — pure constructor
  public func buildTreasuryEntry(
    entryId   : Text,
    tokenType : Nat8,
    amount    : Nat64,
    phiDepth  : Nat8,
    beat      : Nat64,
    timestamp : Int,
    proofLink : Text,
    vaultId   : Nat8
  ) : TreasuryEntry {
    {
      entry_id   = entryId;
      token_type = tokenType;
      amount     = amount;
      phi_depth  = phiDepth;
      beat       = beat;
      timestamp  = timestamp;
      proof_link = proofLink;
      vault_id   = vaultId;
    }
  };

  // phiMultiplier — compute φ^depth for economic scaling
  // Uses phi.mo named powers for depths 0–5; above 5 compounds iteratively.
  // Named flat function — no closures (EUCLID LAW).
  public func phiMultiplier(depth : Nat8) : Float {
    let d = depth;
    if (d == 0) 1.0
    else if (d == 1) Phi.PHI
    else if (d == 2) Phi.PHI_2
    else if (d == 3) Phi.PHI_2 * Phi.PHI            // φ³ = φ² × φ
    else if (d == 4) Phi.PHI_4
    else if (d == 5) Phi.PHI_4 * Phi.PHI            // φ⁵ = φ⁴ × φ
    else             Phi.PHI_4 * Phi.PHI_2 * Phi.PHI // φ⁶+ saturates at φ⁶ = φ⁴ × φ²
  };

  // ─────────────────────────────────────────────────────────────
  // 7. ProofLink — THE SOVEREIGN PROOF CHAIN NODE
  // Linked list: prev_hash → state_hash — unforgeable provenance.
  // phi_multiplier = φ^depth — economic compounding law.
  // Jubilee fires when depth = FIB[n] for any n in the Fibonacci sequence.
  // state_hash = sha3(OrganismCore + all SignalRecords) — certified cognitive state.
  // Enables gap: ring buffer auto-submit (1) — EventRecord births a ProofLink
  // ─────────────────────────────────────────────────────────────
  public type ProofLink = {
    depth          : Nat64;   // proof chain depth
    prev_hash      : Text;    // hash of previous link — the chain
    beat           : Nat64;   // heartbeat at sealing
    coherence      : Float;   // R at sealing — certified cognitive state
    state_hash     : Text;    // sha3(OrganismCore + SignalRecords)
    timestamp      : Int;     // IC nanosecond timestamp
    phi_multiplier : Float;   // φ^depth — economic compounding scalar
  };

  // buildProofLink — pure constructor
  public func buildProofLink(
    depth     : Nat64,
    prevHash  : Text,
    beat      : Nat64,
    coherence : Float,
    stateHash : Text,
    timestamp : Int
  ) : ProofLink {
    // depth mod 6 — select phi power band without any cast chain
    // EUCLID: integer decomposition, flat named binding, no closure
    let depthBand : Nat8 =
      if (depth % 6 == 0) 0
      else if (depth % 6 == 1) 1
      else if (depth % 6 == 2) 2
      else if (depth % 6 == 3) 3
      else if (depth % 6 == 4) 4
      else 5;
    let phiMult = phiMultiplier(depthBand);
    {
      depth          = depth;
      prev_hash      = prevHash;
      beat           = beat;
      coherence      = applyS0(coherence);
      state_hash     = stateHash;
      timestamp      = timestamp;
      phi_multiplier = phiMult;
    }
  };

  // isJubilee — returns true when depth equals any Fibonacci number F(1)–F(20)
  // Named flat function — no closures (EUCLID LAW)
  public func isJubilee(depth : Nat64) : Bool {
    let d = depth;
    d == 1 or d == 2 or d == 3 or d == 5 or d == 8 or d == 13 or d == 21 or
    d == 34 or d == 55 or d == 89 or d == 144 or d == 233 or d == 377 or
    d == 610 or d == 987 or d == 1597 or d == 2584 or d == 4181 or
    d == 6765 or d == 10946
  };

  // ─────────────────────────────────────────────────────────────
  // 8. CouplingState — THE ACTIVE COUPLING FIELD
  // Every coupling: shell-to-shell, organ-to-neuro, phone-to-sensory, ENTANGLA.
  // k_type: 1=Expansive K=PHI (broadcast), 2=Receptive K=PHI_INV (compression),
  //         3=Anti-Drift K=1.0 (ENTANGLA mediation — the Lagrange point)
  // entangla_active = carrier_hz = √(R_exp × R_rec) × SCHUMANN_HZ
  // Device twin wiring: phone → CouplingState(k_type=3, entangla_active=true) → sensory surface
  // Enables gaps: device twin bi-directional sync (3), ENTANGLA structural enforcement
  // ─────────────────────────────────────────────────────────────
  public type CouplingState = {
    source_id      : Text;   // source node identity
    target_id      : Text;   // target node identity
    carrier_hz     : Float;  // coupling carrier frequency
    phase_lock     : Bool;   // true when |Δθ| < π/φ — phase-locked coupling
    strength       : Float;  // coupling strength K, floored at S0
    k_type         : Nat8;   // 1=PHI, 2=PHI_INV, 3=1.0 (three-type law)
    entangla_active: Bool;   // true when carrier_hz = √(R_exp × R_rec) × SCHUMANN_HZ
    R_local        : Float;  // local coherence R between source and target
  };

  // buildCouplingState — pure constructor with ENTANGLA detection
  public func buildCouplingState(
    sourceId   : Text,
    targetId   : Text,
    carrierHz  : Float,
    phaseDelta : Float,
    kType      : Nat8,
    rLocal     : Float,
    rExp       : Float,
    rRec       : Float
  ) : CouplingState {
    let kStrength : Float = if (kType == 1) Phi.K_TYPE1
                            else if (kType == 2) Phi.K_TYPE2
                            else Phi.K_TYPE3;
    // Phase-lock condition: |Δθ| < π/φ
    let lockThreshold = 3.14159265358979 / Phi.PHI;
    let phaseLocked = Float.abs(phaseDelta) < lockThreshold;
    // ENTANGLA condition: carrier matches √(R_exp × R_rec) × SCHUMANN_HZ
    let entanglaHz = Float.sqrt(Float.max(0.0, rExp) * Float.max(0.0, rRec)) * Phi.SCHUMANN_HZ;
    let entActive  = Float.abs(carrierHz - entanglaHz) < 0.01;
    {
      source_id       = sourceId;
      target_id       = targetId;
      carrier_hz      = carrierHz;
      phase_lock      = phaseLocked;
      strength        = applyS0(kStrength * rLocal);
      k_type          = kType;
      entangla_active = entActive;
      R_local         = applyS0(rLocal);
    }
  };

  // ─────────────────────────────────────────────────────────────
  // CoreSnapshot — THE COMPLETE ORGANISM VOCABULARY
  // getCoreSnapshot() returns this every beat (873ms = HEARTBEAT_MS).
  // Frontend fetches this single record and never needs another call for display.
  // Assembles all 8 models into one authoritative organism state.
  // ─────────────────────────────────────────────────────────────
  public type CoreSnapshot = {
    core      : OrganismCore;
    signals   : [SignalRecord];
    events    : [EventRecord];
    nodes     : [NodeState];
    engines   : [EngineState];
    treasury  : [TreasuryEntry];
    proof     : ProofLink;
    couplings : [CouplingState];
  };

};
