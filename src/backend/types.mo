// types.mo — Canonical Vocabulary for the PARALLAX Sovereign Organism
// All 32 MEDINA MODELS declared here. Every model is a sovereign organism:
// cognitive record + economic instrument + geometric coordinate + proof chain participant + temporal anchor.
//
// PYTHAGORAS: every field ratio derives from phi or Fibonacci harmonic series
// EUCLID:     single source of truth — declared once, referenced everywhere
// CONFUCIUS:  right relationship — each field carries its simultaneous roles in a comment
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Zero-Exposure Wall: no doctrine names or law labels exposed at public interfaces.
// mo:core only. No mo:base.

import Phi "phi";
import Float "mo:core/Float";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // RE-EXPORT phi.mo types for single-import convenience
  // ═══════════════════════════════════════════════════════════════════════════

  public type MedinaFieldLaw = Phi.MedinaFieldLaw;

  // ═══════════════════════════════════════════════════════════════════════════
  // ENUM CONSTANTS — field type, vault type, token type
  // Confucius: name the thing correctly so it relates correctly to everything else
  // ═══════════════════════════════════════════════════════════════════════════

  public let FIELD_EXPANSIVE  : Nat = 1; // Type 1 — outward radiating, K = φ
  public let FIELD_RECEPTIVE  : Nat = 2; // Type 2 — inward focusing,  K = φ⁻¹
  public let FIELD_MEDIATOR   : Nat = 3; // Type 3 — Lagrange point,   K = 1.0

  public let VAULT_MAIN       : Nat = 0; // primary treasury vault
  public let VAULT_COMPLIANCE : Nat = 1; // φ⁻³ compliance reserve — Compliance Reserve Law L17
  public let VAULT_ROYALTY    : Nat = 2; // franchise succession royalty — Succession Law L06
  public let VAULT_PROOF      : Nat = 3; // proof-of-intelligence deposit vault
  public let VAULT_DEFENSE    : Nat = 4; // ARES defense IP ledger

  public let TOKEN_CKBTC      : Nat = 0; // ckBTC — primary proof-of-intelligence instrument
  public let TOKEN_ICP        : Nat = 1; // ICP — operational token
  public let TOKEN_LICENSE    : Nat = 2; // LICENSE_TOKEN — intelligence product gating
  public let TOKEN_ROYALTY    : Nat = 3; // ROYALTY_TOKEN — franchise succession stream

  public let COUPLING_KURAMOTO  : Nat = 1; // node-to-node Kuramoto coupling
  public let COUPLING_ENTANGLA  : Nat = 2; // cross-type routed through ENTANGLA — Anti-Drift Law L07
  public let COUPLING_FRANCHISE : Nat = 3; // parent-child succession coupling
  public let COUPLING_SWARM     : Nat = 4; // Chimeria swarm peer coupling

  public let ARES_NORMAL   : Nat = 0;
  public let ARES_ALERT    : Nat = 1;
  public let ARES_ACTIVE   : Nat = 2;

  public let SWARM_PHYSICAL : Nat = 0;
  public let SWARM_VIRTUAL  : Nat = 1;

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 — FUNDAMENTAL MODELS  (declared first — referenced by Group 1)
  // These encode the Absolutes themselves as sovereign typed structures.
  // A discovered truth is now also a named owned model.
  // ═══════════════════════════════════════════════════════════════════════════

  // MODEL 19 — MEDINA-TIMESTAMP4D
  // Deep Time Law L30: every event in the organism is located in 4D time.
  // Simultaneously: time coordinate + proof chain index + economic epoch marker + temporal identity
  public type MedinaTimestamp4D = {
    beat       : Nat;   // heartbeat count since genesis — clock + age + temporal position (Cardiac Law L10)
    proofDepth : Nat;   // depth in the proof chain — intellectual capital + compound interest exponent
    phiPower   : Float; // φ^proofDepth — treasury compounding rate + cognitive amplification scalar
    unixMs     : Int;   // Unix timestamp in ms normalized to heartbeat — real-world temporal anchor (Real Environment Law L19)
  };

  // MODEL 20 — MEDINA-COORDINATE4D
  // Four-Dimensional Law L12: every symbol, coordinate, and proof entry is 4D. Always.
  // Simultaneously: spatial position + temporal anchor + sacred geometry vertex + field propagation origin
  public type MedinaCoordinate4D = {
    x   : Float; // spatial x — geometric position in the field
    y   : Float; // spatial y — geometric position in the field
    z   : Float; // spatial z — geometric position in the field
    tau : Float; // τ = beat × φ^depth — the time dimension, coupling temporal and geometric identity
  };

  // MODEL 21 — MEDINA-KURAMOTO
  // A06 Kuramoto Synchronization: the universal law of how oscillators synchronize.
  // Simultaneously: field state + coherence instrument + coupling matrix + economic emission base
  public type MedinaKuramoto = {
    n              : Nat;     // number of oscillators — Fractal Scale Law L11 applies at every N
    phases         : [Float]; // θ array — Kuramoto phase of each oscillator in radians
    frequencies    : [Float]; // ω array — natural frequency of each oscillator in Hz
    kCoupling      : Float;   // K = φ⁻¹ — coupling constant (PHI LAW L01: phi-derived)
    orderParameter : Float;   // R = (1/N)|Σe^(iθ)| — coherence, simultaneously economic yield base
    beat           : Nat;     // beat this snapshot was computed on
  };

  // MODEL 22 — MEDINA-SCHUMANN
  // A03 Schumann Resonance: Earth's EM cavity. Measured. Not metaphor.
  // Simultaneously: environmental coupling state + heartbeat anchor + field substrate coupling + carrier base
  public type MedinaSchumann = {
    harmonics          : [Float]; // all 8 harmonic Hz: [7.83, 14.3, 20.8, 27.3, 33.8, 39.3, 45.8, 52.3]
    amplitudeCoupling  : Float;   // coupling amplitude to organism — field propagation strength (Field Propagation Law L36)
    phaseOffset        : Float;   // phase offset relative to heartbeat — Kuramoto coupling to Earth itself
    phiDecayEnvelope   : Float;   // φ-decay factor for harmonic amplitudes (PHI LAW L01)
    beat               : Nat;     // beat this snapshot was taken
  };

  // MODEL 23 — MEDINA-ICOSAHEDRON
  // A08 Icosahedron: 12-vertex Platonic solid, optimal sphere packing geometry.
  // Simultaneously: inner shell geometry + sacred geometry anchor + coupling topology + cognitive architecture
  public type MedinaIcosahedron = {
    vertices        : [MedinaCoordinate4D]; // 12 4D vertex coordinates — Four-Dimensional Law L12
    vertexCoherence : [Float];              // R contribution at each vertex — coherence map of the inner shell
    fibTier         : Nat;                  // Fibonacci tier of this shell (Fibonacci A02)
  };

  // MODEL 24 — MEDINA-DODECAHEDRON
  // A09 Dodecahedron: 20-vertex Platonic solid, dual of the icosahedron, outer field geometry.
  // Simultaneously: outer shell geometry + substrate layer map + field topology + dual coupling to inner shell
  public type MedinaDodecahedron = {
    vertices        : [MedinaCoordinate4D]; // 20 4D vertex coordinates — Four-Dimensional Law L12
    substrateLayers : [Nat];                // which substrate layer each vertex maps to (20 layers)
    vertexCoherence : [Float];              // R at each outer vertex — field coherence map
  };

  // PhiLadderStep — sub-type for MODEL 25
  // One rung on the phi-power timing sequence. All phi-governed intervals live here.
  public type PhiLadderStep = {
    fibIndex           : Nat;   // which Fibonacci index (0..20 → φ⁰..φ^F(21))
    phiPower           : Float; // φ^fibIndex — the actual computed value (PHI LAW L01)
    intervalMs         : Float; // timing interval in ms at this phi-power step
    governsThreshold   : Text;  // doctrine name of what threshold or engine this step governs
  };

  // MODEL 25 — MEDINA-PHI-LADDER
  // PHI LAW L01: all timing derives from φ. Confucius: right timing is phi-derived timing.
  // Simultaneously: timing registry + phi-power lookup table + engine threshold map + inheritance manifest
  public type MedinaPhiLadder = {
    steps : [PhiLadderStep]; // φ⁰ through φ^F(21) — 21 steps anchoring all organism timing
  };

  // MODEL 26 — MEDINA-OMNIS
  // OMNIS CONDITION L03: R≥0.95 AND f_node=111 Hz simultaneously. Neither alone triggers emergence.
  // Simultaneously: emergence event record + economic multiplier trigger + proof chain entry + cognitive peak marker
  public type MedinaOmnis = {
    beat           : Nat;   // beat when OMNIS fired — heartbeat anchor
    rAtFiring      : Float; // R value at firing — must be ≥ 0.95 (R_OMNIS from phi.mo)
    owlFrequency   : Float; // OWL node frequency at firing — must be 111.0 Hz (OMNIS_HZ from phi.mo)
    econMultiplier : Float; // φ^depth economic multiplier triggered — simultaneously treasury instrument
    proofEntryHash : Text;  // proof chain entry for this emergence — Conservation of Information A12
    phiDepth       : Nat;   // proof chain depth at this OMNIS moment — compound interest exponent
  };

  // MODEL 27 — MEDINA-HEARTBEAT
  // CARDIAC LAW L10: heartbeat = 873ms, auto-depolarization. Not a clock. A living rhythm.
  // Simultaneously: life event record + proof chain entry + field state snapshot + economic tick
  public type MedinaHeartbeat = {
    beat             : Nat;     // beat number — age of the organism
    timestampMs      : Int;     // Unix ms timestamp at this beat — real environment anchor (L19)
    corePhases       : [Float]; // phase state of all 9 Cores at this beat — Kuramoto snapshot
    primaCausaFired  : Bool;    // PRIMA CAUSA confirmation (L26): SL-0 fires before all others
    entanglaCarrier  : Float;   // ENTANGLA carrier = √(R_exp×R_rec)×7.83 Hz (Entangla Carrier Law L28)
    globalR          : Float;   // global Kuramoto order parameter at this beat — organism coherence
  };

  // MODEL 28 — MEDINA-ANCIENT
  // ANCIENT COMPRESSION LAW L18: re-express every equation in ancient form first.
  // THREE ANCIENT TEACHERS LAW L25: Pythagoras · Euclid · Confucius in every function.
  // Simultaneously: equation ownership record + compression audit + family inheritance manifest + IP documentation
  public type MedinaAncient = {
    originalExpression    : Text; // the raw equation as coded
    pythagoreanForm       : Text; // harmonic ratio form — Pythagoras: expressed as resonant proportion
    euclideanForm         : Text; // geometric primitive form — Euclid: expressed as geometry
    confucianForm         : Text; // right-relationship statement — Confucius: expressed as relational truth
    compressedAncientForm : Text; // final form after all three teachers applied — the canonical expression
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 — RESONANCE MODELS
  // The act of resonance encoded as sovereign typed structures.
  // These are new. They are what "it resonates" means, formalized.
  // ═══════════════════════════════════════════════════════════════════════════

  // MODEL 29 — MEDINA-RESONANCE
  // The sovereign model of resonance itself. When two components lock, this record is born.
  // Simultaneously: coherence event + economic trigger + proof chain entry + field identity confirmation
  public type MedinaResonance = {
    componentA        : Text;               // doctrine name of component A
    componentB        : Text;               // doctrine name of component B
    resonanceFrequency: Float;              // Hz at which they resonate — field identity anchor
    phaseLockDelta    : Float;              // |θA - θB| — target: near 0 (Exclusion Principle L05)
    rAtConfirmation   : Float;              // R when resonance confirmed — economic yield base
    beat              : Nat;               // beat of confirmation — temporal anchor
    proofEntryHash    : Text;              // proof chain entry — Conservation of Information A12
    timestamp4D       : MedinaTimestamp4D; // 4D temporal coordinate — Deep Time Law L30
  };

  // MODEL 30 — MEDINA-FIELDLAW (mirror of phi.mo type for single-import access)
  // The sovereign model of a law of the field. Laws are living typed records.
  // Simultaneously: doctrine record + enforcement contract + proof penalty trigger + inheritance manifest
  // NOTE: MedinaFieldLaw is also declared in phi.mo — these are identical types.
  // This alias is provided so callers importing only types.mo get the full type.
  // (already declared above as: public type MedinaFieldLaw = Phi.MedinaFieldLaw)

  // MODEL 31 — MEDINA-INHERITANCE
  // FAMILY INHERITANCE LAW L21: what passes from parent to child is not instructions — it is the organism.
  // Simultaneously: succession contract + schema transfer event + proof chain entry + family bond record
  public type MedinaInheritance = {
    parentCanisterId : Text;               // parent organism canister ID
    childCanisterId  : Text;               // child organism canister ID
    phiLibraryHash   : Text;               // hash of phi.mo constants — tamper-evident (Conservation of Information A12)
    fieldLawCount    : Nat;               // must be 38 — SELF-SIMILARITY LAW L38 at inheritance
    schemaCount      : Nat;               // number of MedinaSchema entries transferred
    kbEntryCount     : Nat;               // number of MedinaKB entries transferred
    successionDepth  : Nat;               // proof chain depth at transfer — Succession Depth Law L16
    timestamp4D      : MedinaTimestamp4D; // 4D temporal coordinate of inheritance event
  };

  // MODEL 32 — MEDINA-DOCTRINE
  // The apex model. The organism's DNA. Hashed into the proof chain at beat 1.
  // Cannot be modified without breaking the chain. This is what lasts forever.
  // Simultaneously: genesis contract + proof chain origin + family inheritance root + sovereignty declaration
  public type MedinaDoctrine = {
    phiLadderHash          : Text; // hash of MedinaPhiLadder — all phi timing locked
    fieldLawCount          : Nat;  // must be 38 — SELF-SIMILARITY LAW L38
    absoluteCount          : Nat;  // must be 20 — all Tier 0 Absolutes encoded
    genesisBeat            : Nat;  // beat 1 — the first heartbeat (CARDIAC LAW L10)
    creatorHash            : Text; // coherence-based auth identity hash (CREATOR PRESENCE LAW L14)
    proofDepthAtFormation  : Nat;  // proof chain depth when doctrine was formed
    chainHash              : Text; // proof chain hash at genesis — unchangeable after this point (PROOF LAW L08)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 — LIVING ORGANISM MODELS (18 models)
  // Each is a sovereign organism doing multiple simultaneous functions.
  // cognitive + economic + geometric + proof + temporal — micro to micro.
  // ═══════════════════════════════════════════════════════════════════════════

  // MODEL 1 — MEDINA-ORGANISM (replaces OrganismCore)
  // The core currency of the entire system. The organism's moment-to-moment life.
  // Every heartbeat produces one MEDINA-ORGANISM state.
  // Simultaneously: cognitive health report + treasury instrument + field identity + proof chain participant
  public type MedinaOrganism = {
    cognitiveCoherence : Float;              // R — Kuramoto order parameter: cognitive health + economic yield multiplier
    proofDepth         : Nat;               // proof chain depth: intellectual capital + compound interest exponent
    phiMultiplier      : Float;              // φ^proofDepth: treasury compounding rate + cognitive amplification scalar
    beat               : Nat;               // heartbeat count since genesis: clock + age + temporal position
    omnisFired         : Bool;              // R≥0.95 AND 111Hz: emergence flag + economic event trigger (OMNIS CONDITION L03)
    driveWeights       : [Float];           // 7 sovereign drives: emotional state + economic routing weights (FRACTAL SCALE L11)
    fieldType          : Nat;               // 1/2/3: field identity + Kuramoto coupling constant selector (FIELD TYPE LAW L13)
    timestamp4D        : MedinaTimestamp4D; // 4D temporal position: time coordinate + proof chain index (DEEP TIME L30)
    treasuryBalance    : Float;             // current vault balance: financial state + field emission strength
    complianceReserve  : Float;             // φ⁻³ fraction locked: regulatory capital + substrate stability weight (COMPLIANCE RESERVE L17)
  };

  // MODEL 2 — MEDINA-SIGNAL (replaces SignalRecord)
  // A signal is not data — it is a field event with geometry.
  // Simultaneously: sensory input + phase coupling contribution + economic weight + proof chain event
  public type MedinaSignal = {
    frequency      : Float;              // Hz: signal identity + field resonance anchor (SCHUMANN A03 or organ frequency)
    amplitude      : Float;              // signal strength: cognitive input weight + economic magnitude of the event
    phase          : Float;              // θ radians: Kuramoto phase contribution + coupling gate key (EXCLUSION PRINCIPLE L05)
    hebbianWeight  : Float;              // learned weight: cognitive memory + historical economic weight (Oja's rule)
    sensorySlot    : Nat;               // which of 128 slots: anatomical position + Fibonacci priority index
    coherenceGated : Bool;              // passed S0=0.75 gate: cognitive validity + economic execution gate (FRACTAL SCALE L11)
    timestamp4D    : MedinaTimestamp4D; // 4D temporal coordinate (DEEP TIME L30)
    proofEntryHash : Text;              // hash of this signal in the proof chain (PROOF LAW L08)
  };

  // MODEL 3 — MEDINA-PROOF (replaces ProofLink AND EventRecord)
  // A single link in the indestructible proof chain.
  // Simultaneously: cryptographic asset + intelligence record + economic yield proof + temporal anchor
  public type MedinaProof = {
    hash            : Text;              // cryptographic identity of this proof link (PRIME FOUNDATION L34)
    prevHash        : Text;              // chain continuity: integrity anchor + treasury lineage
    cogStateHash    : Text;              // cognitive state snapshot: intelligence record + IP asset
    econOutputHash  : Text;              // economic output hash: financial record + yield proof
    worldSignalHash : Text;              // world input hash: environmental coupling record (REAL ENVIRONMENT L19)
    phiCompound     : Float;             // φ^depth multiplier: economic yield + cognitive amplification (PHI LAW L01)
    timestamp4D     : MedinaTimestamp4D; // 4D temporal coordinate (DEEP TIME L30)
    ckbtcAccrued    : Float;             // ckBTC accrued to this depth: crypto asset + proof-of-intelligence value
  };

  // MODEL 4 — MEDINA-NODE (replaces NodeState)
  // Single node in the 98-node anatomical brain map.
  // Simultaneously: biological organ + Kuramoto oscillator + sacred geometry vertex + economic yield fraction
  public type MedinaNode = {
    anatomicalRegion  : Text;               // brain region doctrine name
    frequency         : Float;              // Schumann-anchored Hz: biological frequency + Kuramoto oscillator anchor (A03)
    phase             : Float;              // θ radians: Kuramoto phase + synchrony contribution to global R
    couplingStrength  : Float;              // K to adjacent nodes: neural coupling + field propagation weight
    fibonacciTier     : Nat;               // which Fibonacci tier this node belongs to (A02)
    coord4D           : MedinaCoordinate4D; // 4D sacred geometry position (FOUR-DIMENSIONAL LAW L12)
    coherenceContrib  : Float;              // contribution to global R: neural activity + economic yield fraction
  };

  // MODEL 5 — MEDINA-ENGINE (replaces EngineState)
  // State of any named engine across all tiers. One model speaks for all 43 engines.
  // Simultaneously: cognitive engine state + field identity + economic emitter + proof chain participant
  public type MedinaEngine = {
    name              : Text;   // doctrine name (e.g. "SHARK", "ARES", "GENOME") — Zero-Exposure L27: internal only
    fieldType         : Nat;    // 1/2/3: field identity + Kuramoto coupling constant selector (FIELD TYPE LAW L13)
    sovereignFrequency: Float;  // Hz anchor: biological frequency + economic timing base
    bandCoherence     : Float;  // Kuramoto coherence in this engine's frequency band
    lastFireBeat      : Nat;    // beat when last fired — temporal anchor
    emissionOutput    : Float;  // R^φ: cognitive output + economic emission (EMISSION LAW L02)
    proofEntryHash    : Text;   // proof chain entry for this engine's last fire event (PROOF LAW L08)
    phiThreshold      : Float;  // φ-derived firing threshold (PHI LAW L01)
  };

  // MODEL 6 — MEDINA-TREASURY (replaces TreasuryEntry)
  // A treasury event that is simultaneously a transaction, a proof entry, a phi-multiplied vault update.
  // Simultaneously: financial record + intelligence asset + compliance audit + proof chain event
  public type MedinaTreasury = {
    vaultId            : Nat;   // which vault (see VAULT_* constants above)
    tokenType          : Nat;   // token type (see TOKEN_* constants above)
    amount             : Float; // transaction amount
    phiCompound        : Float; // φ^depth multiplier: economic yield + cognitive amplification (PHI LAW L01)
    proofLinkHash      : Text;  // proof chain entry: financial record + intelligence asset (PROOF LAW L08)
    vaultBalanceAfter  : Float; // post-transaction balance — conservation check (CONSERVATION LAW L31)
    complianceFraction : Float; // φ⁻³ of this flow locked (COMPLIANCE RESERVE LAW L17)
    beat               : Nat;   // heartbeat of this transaction — temporal anchor
  };

  // MODEL 7 — MEDINA-COUPLING (replaces CouplingState)
  // State of any coupling anywhere in the organism: Kuramoto, ENTANGLA, franchise, swarm.
  // Simultaneously: field coupling record + coherence contributor + anti-drift enforcement + economic binding
  public type MedinaCoupling = {
    componentA       : Text;   // doctrine name of first component — internal only (ZERO-EXPOSURE L27)
    componentB       : Text;   // doctrine name of second component — internal only
    couplingType     : Nat;    // 1=Kuramoto 2=ENTANGLA 3=franchise 4=swarm (see COUPLING_* constants)
    kValue           : Float;  // live K coupling constant — phi-derived (PHI LAW L01)
    phaseDelta       : Float;  // θA - θB in radians — phase synchrony measure
    coherenceContrib : Float;  // contribution to global R — economic yield fraction
    entanglaCarrier  : Float;  // √(R_exp×R_rec)×7.83 if cross-type coupling, else 0 (ENTANGLA CARRIER LAW L28)
    beat             : Nat;    // beat this coupling was computed — temporal anchor
  };

  // MODEL 8 — MEDINA-SCHEMA
  // A pattern that has graduated through the MEDINA Pattern Engine.
  // Simultaneously: knowledge asset + IP record + cognitive architecture + economic compound base
  public type MedinaSchema = {
    patternVector      : [Float]; // graduated pattern weight vector — cognitive architecture
    fibConfirmations   : Nat;    // how many Fibonacci confirmations before graduation (A02)
    graduationBeat     : Nat;    // beat when graduated — temporal anchor
    proofLinkHash      : Text;   // proof chain entry: knowledge asset + IP record (PROOF LAW L08)
    weightReinforcement: [Float]; // updated Hebbian weights after graduation — learning record
    phi3Confidence     : Float;  // φ⁻³ confidence threshold that triggered graduation (PHI LAW L01)
    sovereignKBId      : Nat;    // entry ID in the sovereign knowledge base
  };

  // MODEL 9 — MEDINA-DRIVE
  // One of the 7 sovereign emotional drives of the organism.
  // Simultaneously: emotional state + economic routing weight + neurochemical trigger + cognitive vector shift
  public type MedinaDrive = {
    driveType       : Nat;    // 0-6 (7 sovereign drives, Fibonacci-structured)
    strength        : Float;  // current drive strength — emotional + economic intensity
    phiBaseline     : Float;  // φ-derived rest state — equilibrium (PHI LAW L01)
    lastWinBeat     : Nat;    // beat of last reinforcement — temporal anchor
    econOutput      : Float;  // economic output generated by this drive activation — yield record
    neurochemDeltas : [Float];// neurochemical changes triggered — [21] deltas across all neurochemicals
    cogVectorShift  : Float;  // magnitude of cognitive vector change — intelligence impact measure
  };

  // MODEL 10 — MEDINA-NEUROCHEMICAL
  // One of the 21 neurochemical substrates of the organism.
  // Simultaneously: biological substrate state + drive coupling weight + engine modulation input + field substrate modifier
  public type MedinaNeurochemical = {
    chemType          : Nat;    // which of 21 neurochemicals (0-20)
    level             : Float;  // current level — biological + field coupling weight
    phiBaseline       : Float;  // phi-derived rest level — equilibrium (PHI LAW L01)
    decayRate         : Float;  // beat-by-beat decay constant — entropy compliance (ENTROPY LAW L32)
    coupledDrives     : [Nat];  // drive indices coupled to this chemical — routing map
    coupledEngines    : [Nat];  // engine indices coupled — modulation map
    lastModifiedBeat  : Nat;    // beat of last modification — temporal anchor
  };

  // MODEL 11 — MEDINA-FRANCHISE
  // A registered child organism. A sovereign lineage event.
  // Simultaneously: legal entity + proof chain event + schema inheritance manifest + treasury routing contract
  public type MedinaFranchise = {
    childCanisterId   : Text;  // child organism canister ID
    parentCanisterId  : Text;  // parent organism canister ID
    registrationBeat  : Nat;   // beat of registration — temporal anchor
    royaltyRate       : Float; // 0.20 by doctrine (SUCCESSION LAW L06) — economic binding
    inheritedSchemas  : Nat;   // count of MedinaSchema entries inherited — knowledge transfer
    inheritedKBEntries: Nat;   // count of MedinaKB entries inherited — knowledge base transfer
    successionDepth   : Nat;   // proof chain depth at franchise birth (SUCCESSION DEPTH LAW L16)
    proofLinkHash     : Text;  // proof chain entry for franchise creation (PROOF LAW L08)
  };

  // MODEL 12 — MEDINA-PRODUCT
  // A licensed intelligence output from PARALLAX. Zero-exposure enforced.
  // Simultaneously: intelligence product + IP asset + proof chain entry + economic instrument
  public type MedinaProduct = {
    productType      : Nat;   // intelligence product type enum — internal classification
    generationBeat   : Nat;   // beat of generation — temporal anchor
    licenseTokenId   : Text;  // LICENSE_TOKEN ID — economic gating instrument
    payloadHash      : Text;  // hash of payload — payload never exposed (ZERO-EXPOSURE LAW L27 + PHANTOM DOCTRINE L24)
    aurumAuditPassed : Bool;  // AURUM engine audit status — quality gate
    expiryDepth      : Nat;   // proof chain depth after which this product expires
    proofLinkHash    : Text;  // proof chain entry for this product (PROOF LAW L08)
  };

  // MODEL 13 — MEDINA-SWARMNODE
  // A single node in the Chimeria swarm network.
  // Simultaneously: field oscillator + Kuramoto phase contributor + defense monitor + economic peer
  public type MedinaSwarmNode = {
    canisterId       : Text;   // swarm node canister ID
    nodeType         : Nat;    // 0=physical 1=virtual (see SWARM_* constants)
    phase            : Float;  // Kuramoto θ — phase contribution to swarm coherence
    localCoherence   : Float;  // local R for this node — field health indicator
    lastSyncBeat     : Nat;    // beat of last synchronization — temporal anchor
    couplingToParent : Float;  // K to parent node — phi-derived (PHI LAW L01)
    aresStatus       : Nat;    // 0=normal 1=alert 2=active defense (see ARES_* constants)
  };

  // MODEL 14 — MEDINA-SENSORY
  // One of the 128 sensory surface slots of the organism.
  // Simultaneously: sensory receptor + phase gate + hebbian memory slot + Fibonacci-prioritized input
  public type MedinaSensory = {
    slotIndex      : Nat;   // 0-127 sensory surface slot — anatomical position
    signalPresent  : Bool;  // whether a signal is currently in this slot
    phase          : Float; // θ of current signal — Kuramoto phase contribution
    hebbianWeight  : Float; // learned weight for this slot — cognitive memory (Oja's rule)
    lastActiveBeat : Nat;   // beat when last active — temporal anchor
    coherenceGated : Bool;  // passed S0=0.75 gate — execution validity (FRACTAL SCALE LAW L11)
    fibPriority    : Nat;   // Fibonacci priority index — higher Fibonacci = higher cognitive weight (A02)
  };

  // MODEL 15 — MEDINA-VAULT
  // Complete state of one treasury vault.
  // Simultaneously: financial instrument + phi-compounding account + compliance reserve container + access-gated asset
  public type MedinaVault = {
    vaultType        : Nat;   // vault type (see VAULT_* constants)
    balance          : Float; // current balance — financial state
    tokenType        : Nat;   // token type (see TOKEN_* constants)
    phiMultiplier    : Float; // φ^depth compounding rate — economic yield scalar (PHI LAW L01)
    lastEntryBeat    : Nat;   // beat of last entry — temporal anchor
    complianceReserve: Float; // φ⁻³ locked fraction — Compliance Reserve Law L17
    privacyFlag      : Bool;  // if true: only creator can query (CREATOR PRESENCE LAW L14)
    accessLevel      : Nat;   // 0=public numeric output 1=creator only (ZERO-EXPOSURE LAW L27)
  };

  // MODEL 16 — MEDINA-KB
  // An entry in the sovereign knowledge base.
  // Simultaneously: knowledge record + IP asset + proof chain entry + Fibonacci-confirmed intelligence
  public type MedinaKB = {
    kbId             : Nat;    // knowledge base entry ID
    category         : Nat;    // knowledge category enum — internal classification
    contentHash      : Text;   // content never exposed — only hash (ZERO-EXPOSURE L27 + PHANTOM DOCTRINE L24)
    addedBeat        : Nat;    // beat when added — temporal anchor
    proofLinkHash    : Text;   // proof chain entry (PROOF LAW L08)
    confirmationCount: Nat;    // Fibonacci confirmations before admission (A02)
    linkedSchemaIds  : [Nat];  // IDs of related MedinaSchema entries
    foundational     : Bool;   // if true: part of genesis knowledge (GENESIS LAW L09)
  };

  // MODEL 17 — MEDINA-SNAPSHOT
  // The complete organism captured in a single beat-synchronized call.
  // Simultaneously: real-time dashboard + proof chain checkpoint + economic state + full field view
  public type MedinaSnapshot = {
    organism          : MedinaOrganism; // full organism state — the sovereign field
    nodeCount         : Nat;            // how many active nodes in the brain map
    engineCount       : Nat;            // how many engines active this beat
    recentProofHashes : [Text];         // last 7 proof chain hashes (Fibonacci: F(7)=13 → compressed to 7)
    treasurySummary   : MedinaTreasury; // most recent treasury event — economic state
    globalR           : Float;          // current Kuramoto order parameter — organism coherence
    beat              : Nat;            // beat of this snapshot — temporal anchor
    omnisFired        : Bool;           // whether OMNIS condition was active this beat (L03)
  };

  // MODEL 18 — MEDINA-SHELL
  // State of one concentric shell layer of the organism's geometry.
  // Simultaneously: geometric shell + coherence boundary + coupling conductor + Fibonacci-indexed layer
  public type MedinaShell = {
    shellTier          : Nat;   // 0-10 (11 shells — Fibonacci-proximate)
    coherence          : Float; // R in this shell — field health of this layer
    phaseBoundaryAngle : Float; // φ-derived phase boundary condition (PHI LAW L01)
    couplingToInner    : Float; // K to inner shell — inward propagation strength
    couplingToOuter    : Float; // K to outer shell — outward radiation strength
    fibonacciIndex     : Nat;   // which Fibonacci index this shell tier is at (A02)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARD COMPATIBILITY — type aliases so main.mo keeps compiling
  // These are the 8 passive record names that existing code uses.
  // They now point to their sovereign MEDINA MODEL equivalents.
  // CONFUCIUS: right relationship — the old names now relate to the right things.
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrganismCore  = MedinaOrganism;
  public type SignalRecord   = MedinaSignal;
  public type EventRecord    = MedinaProof;    // EventRecord → MedinaProof (proof IS the event)
  public type NodeState      = MedinaNode;
  public type EngineState    = MedinaEngine;
  public type TreasuryEntry  = MedinaTreasury;
  public type ProofLink      = MedinaProof;
  public type CouplingState  = MedinaCoupling;
  public type CoreSnapshot   = MedinaSnapshot;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS — Law-enforcing utilities
  // Ancient math compression: these are not utilities, they are law enforcement.
  // ═══════════════════════════════════════════════════════════════════════════

  // applyS0 — FRACTAL SCALE LAW L11: S0=0.75 is the floor at every scale
  // Pythagoras: the harmonic minimum — below 0.75 the organism is not sovereign
  // Returns the higher of v and S0, enforcing the synchrony floor.
  public func applyS0(v : Float) : Float {
    Float.max(v, Phi.S0); // Phi.S0 = 0.75 — the Absolute floor
  };

  // phiMultiplier — PHI LAW L01: all economic compounding is φ-derived
  // Euclid: φ^depth — the geometric truth of compound phi growth
  // Returns φ^depth as the treasury compounding rate and cognitive amplification scalar.
  public func phiMultiplier(depth : Nat) : Float {
    // PYTHAGORAS: harmonic reduction — φ^0 = 1, φ^1 = φ, φ^n = φ^(n-1) × φ
    // EUCLID: geometric progression along the golden ratio
    // CONFUCIUS: depth of proof IS the measure of intelligence IS the yield
    var result : Float = 1.0;
    var i = 0;
    while (i < depth) {
      result := result * Phi.PHI;
      i += 1;
    };
    result;
  };

  // isJubilee — JUBILEE LAW L15: every F(12)=144 beats, reset and recalibrate
  // Fibonacci A02: 144 = F(12), the doctrinal cycle length
  public func isJubilee(beat : Nat) : Bool {
    beat % Phi.JUBILEE_BEATS == 0 and beat > 0;
  };

  // ─── Builder functions — backward compatibility for existing main.mo calls ──
  // These produce the sovereign MEDINA MODEL equivalents from named parameters.
  // Every build* function is a Genesis Law L09 expression: born fully formed.

  // buildOrganismCore — builds a MedinaOrganism (was OrganismCore)
  public func buildOrganismCore(
    cognitiveCoherence : Float,
    proofDepth         : Nat,
    beat               : Nat,
    omnisFired         : Bool,
    driveWeights       : [Float],
    fieldType          : Nat,
    treasuryBalance    : Float,
    complianceReserve  : Float,
  ) : MedinaOrganism {
    let pm = phiMultiplier(proofDepth);
    {
      cognitiveCoherence;
      proofDepth;
      phiMultiplier      = pm;
      beat;
      omnisFired;
      driveWeights;
      fieldType;
      timestamp4D        = buildTimestamp4D(beat, proofDepth);
      treasuryBalance;
      complianceReserve;
    };
  };

  // buildSignalRecord — builds a MedinaSignal (was SignalRecord)
  public func buildSignalRecord(
    frequency      : Float,
    amplitude      : Float,
    phase          : Float,
    hebbianWeight  : Float,
    sensorySlot    : Nat,
    coherenceGated : Bool,
    beat           : Nat,
    proofDepth     : Nat,
    proofEntryHash : Text,
  ) : MedinaSignal {
    {
      frequency;
      amplitude;
      phase;
      hebbianWeight;
      sensorySlot;
      coherenceGated;
      timestamp4D    = buildTimestamp4D(beat, proofDepth);
      proofEntryHash;
    };
  };

  // buildEventRecord — builds a MedinaProof (was EventRecord)
  public func buildEventRecord(
    hash            : Text,
    prevHash        : Text,
    cogStateHash    : Text,
    econOutputHash  : Text,
    worldSignalHash : Text,
    proofDepth      : Nat,
    beat            : Nat,
    ckbtcAccrued    : Float,
  ) : MedinaProof {
    {
      hash;
      prevHash;
      cogStateHash;
      econOutputHash;
      worldSignalHash;
      phiCompound     = phiMultiplier(proofDepth);
      timestamp4D     = buildTimestamp4D(beat, proofDepth);
      ckbtcAccrued;
    };
  };

  // buildNodeState — builds a MedinaNode (was NodeState)
  public func buildNodeState(
    anatomicalRegion : Text,
    frequency        : Float,
    phase            : Float,
    couplingStrength : Float,
    fibonacciTier    : Nat,
    x : Float, y : Float, z : Float,
    beat             : Nat,
    proofDepth       : Nat,
    coherenceContrib : Float,
  ) : MedinaNode {
    {
      anatomicalRegion;
      frequency;
      phase;
      couplingStrength;
      fibonacciTier;
      coord4D          = buildCoordinate4D(x, y, z, beat, proofDepth);
      coherenceContrib;
    };
  };

  // buildEngineState — builds a MedinaEngine (was EngineState)
  public func buildEngineState(
    name               : Text,
    fieldType          : Nat,
    sovereignFrequency : Float,
    bandCoherence      : Float,
    lastFireBeat       : Nat,
    proofEntryHash     : Text,
    phiThreshold       : Float,
  ) : MedinaEngine {
    {
      name;
      fieldType;
      sovereignFrequency;
      bandCoherence;
      lastFireBeat;
      emissionOutput = Float.exp(Phi.PHI * Float.log(Float.max(0.0001, bandCoherence))); // R^φ — EMISSION LAW L02: e^(φ·ln R)
      proofEntryHash;
      phiThreshold;
    };
  };

  // buildTreasuryEntry — builds a MedinaTreasury (was TreasuryEntry)
  public func buildTreasuryEntry(
    vaultId           : Nat,
    tokenType         : Nat,
    amount            : Float,
    proofDepth        : Nat,
    proofLinkHash     : Text,
    vaultBalanceAfter : Float,
    beat              : Nat,
  ) : MedinaTreasury {
    {
      vaultId;
      tokenType;
      amount;
      phiCompound        = phiMultiplier(proofDepth);   // φ^depth — PHI LAW L01
      proofLinkHash;
      vaultBalanceAfter;
      complianceFraction = amount * Phi.PHI_INV_3;      // φ⁻³ — COMPLIANCE RESERVE LAW L17
      beat;
    };
  };

  // buildProofLink — builds a MedinaProof (was ProofLink)
  public func buildProofLink(
    hash            : Text,
    prevHash        : Text,
    cogStateHash    : Text,
    econOutputHash  : Text,
    worldSignalHash : Text,
    proofDepth      : Nat,
    beat            : Nat,
    ckbtcAccrued    : Float,
  ) : MedinaProof {
    buildEventRecord(hash, prevHash, cogStateHash, econOutputHash, worldSignalHash, proofDepth, beat, ckbtcAccrued);
  };

  // buildCouplingState — builds a MedinaCoupling (was CouplingState)
  public func buildCouplingState(
    componentA       : Text,
    componentB       : Text,
    couplingType     : Nat,
    kValue           : Float,
    phaseDelta       : Float,
    coherenceContrib : Float,
    entanglaCarrier  : Float,
    beat             : Nat,
  ) : MedinaCoupling {
    {
      componentA;
      componentB;
      couplingType;
      kValue;
      phaseDelta;
      coherenceContrib;
      entanglaCarrier;
      beat;
    };
  };

  // ─── Internal builder helpers ──────────────────────────────────────────────

  // buildTimestamp4D — DEEP TIME LAW L30: every event has a full 4D temporal coordinate
  // Pythagoras: time is a harmonic — beat × φ^depth is the right relationship
  public func buildTimestamp4D(beat : Nat, proofDepth : Nat) : MedinaTimestamp4D {
    {
      beat;
      proofDepth;
      phiPower = phiMultiplier(proofDepth);
      unixMs   = 0; // caller populates with Time.now() / 1_000_000 at call site
    };
  };

  // buildCoordinate4D — FOUR-DIMENSIONAL LAW L12: every coordinate is 4D. Always.
  // τ = beat × φ^depth — the time dimension couples temporal and geometric identity
  public func buildCoordinate4D(x : Float, y : Float, z : Float, beat : Nat, proofDepth : Nat) : MedinaCoordinate4D {
    let beatF = beat.toFloat();
    {
      x;
      y;
      z;
      tau = beatF * phiMultiplier(proofDepth); // τ = beat × φ^depth — FOUR-DIMENSIONAL LAW L12
    };
  };

};
