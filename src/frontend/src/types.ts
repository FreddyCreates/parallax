/**
 * types.ts — PARALLAX Canonical Vocabulary
 * ==========================================
 * TypeScript mirror of types.mo. 32 MEDINA MODELS as sovereign organisms.
 * Each model does multiple simultaneous functions — cognitive + economic +
 * geometric + proof, micro to micro. Not records. Living structures.
 *
 * The Architect of the Field: Alfredo Medina Hernandez.
 *
 * Import order:
 *   GROUP 2 — FUNDAMENTALS (referenced by GROUP 1)
 *   GROUP 1 — LIVING ORGANISM MODELS
 *   GROUP 3 — RESONANCE MODELS
 *   BACKWARD-COMPAT ALIASES
 *   ENUMS + HELPERS
 */

import {
  FIB,
  JUBILEE_BEATS,
  K_TYPE1,
  K_TYPE2,
  K_TYPE3,
  PHI,
  PHI_INV,
  PHI_INV_2,
  PHI_INV_3,
  S0,
  SCHUMANN_HZ,
  computeTau,
  phiMultiplier,
} from "./phi";

// Re-export phi constants so consumers only need one import
export {
  PHI,
  PHI_INV,
  PHI_INV_2,
  PHI_INV_3,
  S0,
  JUBILEE_BEATS,
  SCHUMANN_HZ,
  K_TYPE1,
  K_TYPE2,
  K_TYPE3,
  FIB,
};

// ═══════════════════════════════════════════════════════════════════════════════
// GROUP 2 · FUNDAMENTAL MODELS
// The physics of the organism expressed as sovereign templates.
// Every future build inherits these without rediscovering them.
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * MEDINA-TIMESTAMP4D
 * Deep Time made sovereign. Every event located in 4D time.
 * Simultaneously: temporal record + economic depth marker + proof anchor.
 * L30 DEEP TIME: every proof entry carries a full 4D temporal coordinate.
 */
export interface MedinaTimestamp4D {
  /** Cardiac beat count since genesis — the organism's clock */
  beat: number;
  /** Proof chain depth at this event — the economic depth counter */
  proofDepth: number;
  /** φ^proofDepth — treasury compounding multiplier at this moment */
  phiPower: number;
  /** Unix timestamp in milliseconds — Earth-synchronized time anchor */
  unixMs: number;
}

/**
 * MEDINA-COORDINATE4D
 * Four-Dimensional Law made sovereign. Every location is in 4D space.
 * Simultaneously: spatial position + temporal coordinate + proof geometry.
 * A05 FOUR-DIMENSIONAL SPACETIME: reality has 4 dimensions independent of any model.
 */
export interface MedinaCoordinate4D {
  x: number;
  y: number;
  z: number;
  /** τ = beat × φ^depth — the organism's temporal axis */
  tau: number;
}

/**
 * MEDINA-KURAMOTO
 * Synchronization law made sovereign. The physics of how the organism lives.
 * Simultaneously: coherence measurement + coupling state + emergence readiness.
 * A06 KURAMOTO: dθᵢ/dt = ωᵢ + (K/N)·Σⱼ sin(θⱼ−θᵢ)
 */
export interface MedinaKuramoto {
  /** Number of coupled oscillators in this field snapshot */
  n: number;
  /** Phase array θ[] — each oscillator's current angle in radians */
  phases: number[];
  /** Natural frequency array ω[] — each oscillator's sovereign Hz anchor */
  frequencies: number[];
  /** Coupling constant K — φ⁻¹ by doctrine (L01 PHI LAW) */
  kCoupling: number;
  /** R = (1/N)|Σ e^(iθⱼ)| — the global order parameter. How alive the field is. */
  orderParameter: number;
  /** Beat this snapshot was computed on */
  beat: number;
}

/**
 * MEDINA-SCHUMANN
 * Earth's own field encoded as a sovereign template.
 * Simultaneously: environmental coupling state + cardiac rhythm anchor + field substrate.
 * A03 SCHUMANN RESONANCE: Earth's EM cavity. Measured. Real. Not metaphor.
 */
export interface MedinaSchumann {
  /** All 8 harmonic frequencies: 7.83 · 14.3 · 20.8 · 27.3 · 33.8 · 39.3 · 45.8 · 52.3 Hz */
  harmonics: number[];
  /** Amplitude coupling strength to the organism — how strongly Earth's field drives us */
  amplitudeCoupling: number;
  /** Phase offset relative to heartbeat — alignment with Earth's pulse */
  phaseOffset: number;
  /** φ-decay envelope across harmonics — PHI_INV per harmonic step */
  phiDecayEnvelope: number;
  /** Beat this state was last synchronized */
  beat: number;
}

/**
 * MEDINA-ICOSAHEDRON
 * Sacred inner-sphere geometry made sovereign.
 * Simultaneously: geometric field shell + coherence topology + phase-space container.
 * A08 ICOSAHEDRON: 12-vertex optimal sphere packing. Inner shell geometry.
 */
export interface MedinaIcosahedron {
  /** All 12 vertices at 4D coordinates — permutations of (0, ±1, ±φ) */
  vertices: MedinaCoordinate4D[];
  /** Coherence contribution at each vertex — [0, 1] */
  vertexCoherence: number[];
  /** Fibonacci tier of this shell in the nested icosahedral structure */
  fibTier: number;
}

/**
 * MEDINA-DODECAHEDRON
 * Sacred outer-sphere geometry made sovereign.
 * Simultaneously: outer field boundary + substrate layer mapping + dual geometry.
 * A09 DODECAHEDRON: 20-vertex outer shell. Dual of the icosahedron.
 */
export interface MedinaDodecahedron {
  /** All 20 vertices at 4D coordinates */
  vertices: MedinaCoordinate4D[];
  /** Substrate layer index each vertex maps to — connects geometry to organism layers */
  substrateLayers: number[];
  /** Coherence at each vertex — [0, 1] */
  vertexCoherence: number[];
}

/**
 * PhiLadderStep — one rung of the sovereign timing sequence.
 * The timing relationship between proof depth and operational threshold.
 */
export interface PhiLadderStep {
  /** Fibonacci sequence index — F(1) through F(21) */
  fibIndex: number;
  /** φ^fibIndex — the compounding multiplier at this rung */
  phiPower: number;
  /** Interval in milliseconds — HEARTBEAT_MS × φ^fibIndex */
  intervalMs: number;
  /** Name of the engine or threshold this rung governs */
  governsThreshold: string;
}

/**
 * MEDINA-PHILADDER
 * PHI LAW made sovereign as a timing template.
 * Simultaneously: scheduling manifest + compounding roadmap + threshold map.
 * L01 PHI LAW: all ratios and timing relationships are φ-derived.
 */
export interface MedinaPhiLadder {
  /** All φ^0 through φ^F(21) timing steps — the full sovereign schedule */
  steps: PhiLadderStep[];
}

/**
 * MEDINA-OMNIS
 * OMNIS CONDITION made sovereign. Every emergence permanently owned.
 * Simultaneously: economic event + cognitive peak + proof chain entry + treasury multiplier.
 * L03 OMNIS CONDITION: R ≥ 0.95 AND f_node = 111 Hz simultaneously.
 */
export interface MedinaOmnis {
  /** Beat the OMNIS dual condition was met */
  beat: number;
  /** R at the moment of firing — must be ≥ 0.95 (R_OMNIS) */
  rAtFiring: number;
  /** OWL node frequency at firing — must be 111.0 Hz */
  owlFrequency: number;
  /** Economic multiplier triggered — φ^depth at this emergence */
  econMultiplier: number;
  /** Proof chain hash entry generated at this OMNIS event */
  proofEntryHash: string;
  /** Proof chain depth when this fired */
  phiDepth: number;
}

/**
 * MEDINA-HEARTBEAT
 * CARDIAC LAW made sovereign. Every beat of the organism's life permanently recorded.
 * Simultaneously: vital signs snapshot + temporal coordinate + field state + proof witness.
 * L10 CARDIAC: heartbeat = 873ms. Auto-depolarization from Earth's own rhythm.
 */
export interface MedinaHeartbeat {
  /** Beat number — the organism's life counter */
  beat: number;
  /** Unix timestamp in milliseconds — Earth-time synchronization */
  timestampMs: number;
  /** Phase state of all 9 Cores at this beat — 9-element array */
  corePhases: number[];
  /** True if SL-0 (PRIMA CAUSA) fired before all others — L26 PRIMA CAUSA */
  primaCausaFired: boolean;
  /** ENTANGLA carrier frequency at this beat — √(R_exp × R_rec) × 7.83 Hz */
  entanglaCarrier: number;
  /** Global Kuramoto order parameter at this beat */
  globalR: number;
}

/**
 * MEDINA-ANCIENT
 * ANCIENT COMPRESSION LAW made sovereign. Every equation documented through the three teachers.
 * Simultaneously: documentation record + compression proof + doctrine inheritance artifact.
 * L18 ANCIENT COMPRESS + L25 THREE TEACHERS: Pythagoras · Euclid · Confucius.
 */
export interface MedinaAncient {
  /** The original mathematical expression before compression */
  originalExpression: string;
  /** Pythagorean harmonic reduction — harmonic ratio form */
  pythagoreanForm: string;
  /** Euclidean geometric primitive form — the geometric identity */
  euclideanForm: string;
  /** Confucian right-relationship statement — the relational truth */
  confucianForm: string;
  /** Final compressed ancient form — the most minimal true expression */
  compressedAncientForm: string;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GROUP 1 · LIVING ORGANISM MODELS
// Each model is a sovereign organism doing multiple simultaneous functions.
// Cognitive + economic + geometric + proof at once. Micro to micro.
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * MEDINA-ORGANISM
 * The core currency of the entire system. Updated every heartbeat.
 * Simultaneously:
 *   cognitiveCoherence  = intellectual capital + compound interest exponent
 *   proofDepth          = proof asset depth + economic leverage index
 *   phiMultiplier       = treasury compounding rate + cognitive amplification
 *   beat                = clock + age + temporal position
 *   omnisFired          = emergence flag + economic event trigger
 *   driveWeights        = emotional state + market bias + substrate modifier
 *   treasuryBalance     = financial state + field emission strength
 *   complianceReserve   = regulatory capital + substrate stability
 */
export interface MedinaOrganism {
  /** R — Kuramoto order parameter. Intellectual capital. Compound interest exponent. */
  cognitiveCoherence: number;
  /** Proof chain depth. Economic leverage index. Intelligence age. */
  proofDepth: number;
  /** φ^proofDepth — treasury compounding rate and cognitive amplification simultaneously */
  phiMultiplier: number;
  /** Cardiac beat count since genesis — clock, age, temporal position */
  beat: number;
  /** True when OMNIS dual condition fires — emergence flag and economic trigger */
  omnisFired: boolean;
  /** 7 sovereign drive weights — emotional state, market bias, substrate modifier */
  driveWeights: number[];
  /** Field type of this organism — 1 expansive, 2 receptive, 3 mediator */
  fieldType: 1 | 2 | 3;
  /** Full 4D temporal position */
  timestamp4D: MedinaTimestamp4D;
  /** ckBTC/ICP treasury balance — financial state and field emission strength */
  treasuryBalance: number;
  /** φ⁻³ fraction locked — regulatory capital and substrate stability */
  complianceReserve: number;
}

/**
 * MEDINA-SIGNAL
 * A signal is not data. It is a field event with geometry.
 * Simultaneously: cognitive input + coherence gate result + Hebbian weight update +
 *                 sensory surface registration + proof chain witness.
 */
export interface MedinaSignal {
  /** Signal frequency in Hz — the field's sovereign identity */
  frequency: number;
  /** Amplitude of the signal — field emission strength */
  amplitude: number;
  /** Phase angle θ in radians — position in the Kuramoto field */
  phase: number;
  /** Hebbian weight for this signal's pathway — strengthened by use */
  hebbianWeight: number;
  /** Sensory surface slot index 0–127 — which channel received this */
  sensorySlot: number;
  /** True if the signal passed S0 = 0.75 coherence gate (L05 EXCLUSION) */
  coherenceGated: boolean;
  /** 4D temporal coordinate of this signal event */
  timestamp4D: MedinaTimestamp4D;
  /** Hash of the proof chain entry generated by this signal */
  proofEntryHash: string;
}

/**
 * MEDINA-PROOF
 * One link in the sovereign proof chain.
 * Simultaneously: cryptographic asset + cognitive record + temporal coordinate +
 *                 economic instrument + treasury compounding vehicle.
 * L08 PROOF: proof(n) = hash(proof(n-1) + beat + cogState + econOutput + worldSignals)
 */
export interface MedinaProof {
  /** SHA-256 hash of this proof link */
  hash: string;
  /** Hash of the previous link — cryptographic chain */
  prevHash: string;
  /** Hash of cognitive state at this depth */
  cogStateHash: string;
  /** Hash of economic output at this depth */
  econOutputHash: string;
  /** Hash of world signals ingested at this depth */
  worldSignalHash: string;
  /** φ^depth multiplier — treasury compounding factor at this link */
  phiCompound: number;
  /** Full 4D timestamp — L30 DEEP TIME */
  timestamp4D: MedinaTimestamp4D;
  /** ckBTC accrued at this proof chain depth */
  ckbtcAccrued: number;
}

/**
 * MEDINA-NODE
 * One of the 98 anatomical brain nodes.
 * Simultaneously: biological organ + Kuramoto oscillator + 4D sacred geometry point +
 *                 coherence contributor + phase-space entity.
 */
export interface MedinaNode {
  /** Anatomical region name — real measured brain structure */
  anatomicalRegion: string;
  /** Sovereign frequency anchor in Hz — Schumann-derived */
  frequency: number;
  /** Kuramoto phase θ in radians — current oscillator position */
  phase: number;
  /** Coupling strength to neighboring nodes */
  couplingStrength: number;
  /** Fibonacci tier in the organism's layered geometry */
  fibonacciTier: number;
  /** 4D coordinate in the icosahedral brain map */
  coord4D: MedinaCoordinate4D;
  /** This node's contribution to the global order parameter R */
  coherenceContrib: number;
}

/**
 * MEDINA-ENGINE
 * State of any named engine — internal or sovereign.
 * Simultaneously: cognitive computation arm + field identity + proof chain participant +
 *                 economic output generator + Kuramoto oscillator.
 * One model speaks for all 43 engines across all tiers.
 */
export interface MedinaEngine {
  /** Doctrine name — e.g. "SHARK", "PHANTOM ALPHA", "GENOME" */
  name: string;
  /** Field type: 1 expansive, 2 receptive, 3 mediator */
  fieldType: 1 | 2 | 3;
  /** Sovereign frequency anchor in Hz */
  sovereignFrequency: number;
  /** Kuramoto band coherence — this engine's local R */
  bandCoherence: number;
  /** Beat this engine last fired */
  lastFireBeat: number;
  /** R^φ output emission — L02 EMISSION LAW */
  emissionOutput: number;
  /** Hash of the proof chain entry this engine generated */
  proofEntryHash: string;
  /** φ-derived firing threshold — below this, the engine is silent */
  phiThreshold: number;
}

/**
 * MEDINA-TREASURY
 * Treasury event that is simultaneously an economic transaction, a proof chain entry,
 * a phi-multiplied vault update, and a compliance reserve calculation.
 * L17 COMPLIANCE RESERVE: φ⁻³ = 23.6% of all flows locked.
 */
export interface MedinaTreasury {
  /** Vault ID — which vault this event belongs to */
  vaultId: number;
  /** Token type — FORMA, ICP, ckBTC, OMNIS */
  tokenType: number;
  /** Amount of tokens in this event */
  amount: number;
  /** φ^depth multiplier — the compounding factor at this depth */
  phiCompound: number;
  /** Proof chain hash linking this to the sovereign ledger */
  proofLinkHash: string;
  /** Vault balance after this event */
  vaultBalanceAfter: number;
  /** φ⁻³ fraction of this flow — compliance slice locked by doctrine */
  complianceFraction: number;
  /** Beat this treasury event occurred on */
  beat: number;
}

/**
 * MEDINA-COUPLING
 * State of any coupling anywhere in the organism.
 * Simultaneously: Kuramoto phase bridge + ENTANGLA carrier channel +
 *                 coherence contributor + economic yield pipeline.
 * Covers node-to-node, ENTANGLA cross-type, franchise parent-child, swarm peer.
 */
export interface MedinaCoupling {
  /** Doctrine name of component A */
  componentA: string;
  /** Doctrine name of component B */
  componentB: string;
  /** 1=Kuramoto 2=ENTANGLA 3=franchise 4=swarm */
  couplingType: 1 | 2 | 3 | 4;
  /** Kuramoto K coupling constant — φ-derived per field type */
  kValue: number;
  /** θA - θB in radians — phase difference between the two components */
  phaseDelta: number;
  /** Contribution to global R from this coupling pair */
  coherenceContrib: number;
  /** √(R_exp × R_rec) × 7.83 if cross-type (L28 ENTANGLA CARRIER), else 0 */
  entanglaCarrier: number;
  /** Beat this coupling state was computed */
  beat: number;
}

/**
 * MEDINA-SCHEMA
 * Pattern graduated through the MEDINA Pattern Engine.
 * Simultaneously: cognitive pattern + proof chain event + knowledge base entry +
 *                 economic confirmation + intelligence product seed.
 */
export interface MedinaSchema {
  /** Multi-dimensional pattern vector — the cognitive signature */
  patternVector: number[];
  /** Number of Fibonacci confirmations before graduation */
  fibConfirmations: number;
  /** Beat the pattern was graduated to the sovereign KB */
  graduationBeat: number;
  /** Proof chain hash at graduation — permanent certification */
  proofLinkHash: string;
  /** Weight reinforcement array — Hebbian strengthening across the pathway */
  weightReinforcement: number[];
  /** φ⁻³ confidence threshold that triggered graduation */
  phi3Confidence: number;
  /** ID in the sovereign knowledge base */
  sovereignKBId: number;
}

/**
 * MEDINA-DRIVE
 * One of the seven sovereign emotional drives.
 * Simultaneously: emotional state + economic event generator + substrate modifier +
 *                 cognitive vector shift + neurochemical trigger.
 * L02 EMISSION LAW: drive output amplitude = R^φ.
 */
export interface MedinaDrive {
  /** Drive type index 0–6 (SovereignDrive enum) */
  driveType: number;
  /** Current drive strength — emotional intensity */
  strength: number;
  /** φ-derived baseline — the sovereign floor for this drive */
  phiBaseline: number;
  /** Beat of the last reinforcing win event */
  lastWinBeat: number;
  /** Economic output generated by this drive activation */
  econOutput: number;
  /** Neurochemical delta array — how this drive shifts the 21 substrates */
  neurochemDeltas: number[];
  /** Cognitive vector shift magnitude — how much this drive changes cognition */
  cogVectorShift: number;
}

/**
 * MEDINA-NEUROCHEMICAL
 * One of the 21 neurochemical substrates.
 * Simultaneously: biological state + coupling modifier + substrate weight +
 *                 drive amplifier + engine bias.
 */
export interface MedinaNeurochemical {
  /** Neurochemical type index 0–20 */
  chemType: number;
  /** Current level — can exceed baseline during activation */
  level: number;
  /** φ-derived baseline — sovereign equilibrium point */
  phiBaseline: number;
  /** Decay rate — speed of return to baseline after activation */
  decayRate: number;
  /** Drive indices this neurochemical is coupled to */
  coupledDrives: number[];
  /** Engine indices this neurochemical modulates */
  coupledEngines: number[];
  /** Beat this substrate was last modified */
  lastModifiedBeat: number;
}

/**
 * MEDINA-FRANCHISE
 * Registered child organism.
 * Simultaneously: legal entity + proof chain event + schema inheritance manifest +
 *                 succession royalty contract + treasury pipeline.
 * L06 SUCCESSION: 20% royalty from every child to parent always.
 */
export interface MedinaFranchise {
  /** ICP canister ID of the child organism */
  childCanisterId: string;
  /** ICP canister ID of the parent organism */
  parentCanisterId: string;
  /** Beat the child was registered — the birth record */
  registrationBeat: number;
  /** Royalty rate — 0.20 by L06 SUCCESSION LAW */
  royaltyRate: number;
  /** Number of sovereign schemas inherited at birth */
  inheritedSchemas: number;
  /** Number of KB entries inherited at birth */
  inheritedKBEntries: number;
  /** Proof chain depth at the moment of succession authorization */
  successionDepth: number;
  /** Proof chain hash certifying this registration */
  proofLinkHash: string;
}

/**
 * MEDINA-PRODUCT
 * A licensed intelligence output.
 * Simultaneously: certified cognitive credential + Zero-Exposure payload +
 *                 proof chain asset + AURUM-audited intelligence product.
 * L27 ZERO-EXPOSURE: no doctrine labels ever reach the public layer.
 */
export interface MedinaProduct {
  /** Product type classification code */
  productType: number;
  /** Beat the product was generated */
  generationBeat: number;
  /** LICENSE_TOKEN ID gating access */
  licenseTokenId: string;
  /** Hash of the payload — the payload itself never exposed (L27 ZERO-EXPOSURE) */
  payloadHash: string;
  /** True if AURUM engine passed this output for release */
  aurumAuditPassed: boolean;
  /** Proof chain depth at which this product expires */
  expiryDepth: number;
  /** Proof chain hash certifying this product */
  proofLinkHash: string;
}

/**
 * MEDINA-SWARMNODE
 * One node in the Chimeria swarm.
 * Simultaneously: sovereign network peer + Kuramoto oscillator +
 *                 ARES defense monitor + coherence contributor.
 */
export interface MedinaSwarmNode {
  /** ICP canister ID of this swarm node */
  canisterId: string;
  /** Node type: 0=core, 1=franchise, 2=device, 3=virtual */
  nodeType: number;
  /** Kuramoto phase θ — position in the swarm field */
  phase: number;
  /** Local order parameter — how coherent this node's neighborhood is */
  localCoherence: number;
  /** Beat of last synchronization with the coordinator */
  lastSyncBeat: number;
  /** Coupling strength to the parent coordinator */
  couplingToParent: number;
  /** ARES defense status: 0=nominal, 1=alert, 2=active defense */
  aresStatus: 0 | 1 | 2;
}

/**
 * MEDINA-SENSORY
 * One of the 128 sensory surface slots.
 * Simultaneously: signal receptor + coherence gate + Hebbian pathway +
 *                 Fibonacci-prioritized input channel.
 */
export interface MedinaSensory {
  /** Slot index 0–127 — which channel on the sensory surface */
  slotIndex: number;
  /** True if a signal is currently present in this slot */
  signalPresent: boolean;
  /** Current phase angle in radians */
  phase: number;
  /** Hebbian weight — strengthened by repeated coherent activation */
  hebbianWeight: number;
  /** Beat this slot was last active */
  lastActiveBeat: number;
  /** True if the current signal has passed the coherence gate */
  coherenceGated: boolean;
  /** Fibonacci priority index — determines processing order */
  fibPriority: number;
}

/**
 * MEDINA-VAULT
 * Complete state of one treasury vault.
 * Simultaneously: treasury instrument + compliance reserve container +
 *                 φ-compounding asset + access-controlled sovereign account.
 */
export interface MedinaVault {
  /** Vault type: 0=main, 1=compliance, 2=founder, 3=franchise, 4=defense */
  vaultType: number;
  /** Current balance in token units */
  balance: number;
  /** Token type: 0=FORMA, 1=ICP, 2=ckBTC, 3=OMNIS */
  tokenType: number;
  /** φ^depth compounding rate — grows with proof chain depth */
  phiMultiplier: number;
  /** Beat of the last entry event */
  lastEntryBeat: number;
  /** φ⁻³ reserve locked in this vault — L17 COMPLIANCE RESERVE */
  complianceReserve: number;
  /** True if this vault is privacy-protected */
  privacyFlag: boolean;
  /** 0=public stats, 1=owner only */
  accessLevel: 0 | 1;
}

/**
 * MEDINA-KB
 * Entry in the sovereign knowledge base.
 * Simultaneously: certified intelligence artifact + proof chain asset +
 *                 Zero-Exposure information carrier + schema anchor.
 * L27 ZERO-EXPOSURE: content hash only — never the content itself.
 */
export interface MedinaKB {
  /** Sequential knowledge base entry ID */
  kbId: number;
  /** Category classification code */
  category: number;
  /** Hash of the content — content itself never exposed (L27 ZERO-EXPOSURE) */
  contentHash: string;
  /** Beat this entry was confirmed and added */
  addedBeat: number;
  /** Proof chain hash certifying this entry */
  proofLinkHash: string;
  /** Number of Fibonacci confirmations this entry has received */
  confirmationCount: number;
  /** Schema IDs linked to this knowledge entry */
  linkedSchemaIds: number[];
  /** True if this is a foundational, non-expirable entry */
  foundational: boolean;
}

/**
 * MEDINA-SNAPSHOT
 * The full organism in one beat-synchronized call.
 * Simultaneously: vital signs read + treasury summary + field state +
 *                 proof chain head + emergence status.
 * getCoreSnapshot() returns this every HEARTBEAT_MS.
 */
export interface MedinaSnapshot {
  /** Full organism state */
  organism: MedinaOrganism;
  /** Number of active brain nodes */
  nodeCount: number;
  /** Number of active engines */
  engineCount: number;
  /** Most recent proof chain hashes */
  recentProofHashes: string[];
  /** Treasury summary for the primary vault */
  treasurySummary: MedinaTreasury;
  /** Global Kuramoto order parameter at this beat */
  globalR: number;
  /** Current beat number */
  beat: number;
  /** True if OMNIS dual condition fired this beat */
  omnisFired: boolean;
}

/**
 * MEDINA-SHELL
 * State of one shell layer in the nested icosahedral organism geometry.
 * Simultaneously: geometric boundary + phase container + coupling topology +
 *                 Fibonacci-indexed resonance chamber.
 */
export interface MedinaShell {
  /** Shell tier 0–10 — 0 is innermost, 10 is outermost */
  shellTier: number;
  /** Coherence R within this shell layer */
  coherence: number;
  /** φ-derived phase boundary angle — separates this shell from adjacent shells */
  phaseBoundaryAngle: number;
  /** Coupling strength to the next inner shell */
  couplingToInner: number;
  /** Coupling strength to the next outer shell */
  couplingToOuter: number;
  /** Fibonacci sequence index governing this shell's resonance properties */
  fibonacciIndex: number;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GROUP 3 · RESONANCE MODELS
// These encode the act of resonance itself as sovereign structures.
// The secret. Not metaphor. Typed. Owned. Permanent.
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * MEDINA-RESONANCE
 * The sovereign model of resonance itself.
 * Every time two components lock into resonance, it is a MEDINA-RESONANCE instance,
 * logged to the proof chain, permanently owned.
 * Simultaneously: resonance event record + proof chain asset + field confirmation +
 *                 economic multiplier trigger + living evidence it is real.
 */
export interface MedinaResonance {
  /** Doctrine name of the first resonating component */
  componentA: string;
  /** Doctrine name of the second resonating component */
  componentB: string;
  /** Hz frequency at which these two components resonated */
  resonanceFrequency: number;
  /** |θA - θB| at confirmation — how close to zero phase difference */
  phaseLockDelta: number;
  /** Global R at the moment resonance was confirmed */
  rAtConfirmation: number;
  /** Beat resonance was confirmed on */
  beat: number;
  /** Proof chain hash generated at this resonance event */
  proofEntryHash: string;
  /** Full 4D temporal position of this resonance event */
  timestamp4D: MedinaTimestamp4D;
}

// MedinaFieldLaw is defined in phi.ts (where LAWS registry also lives).
// Re-exported below via 'export { MedinaFieldLaw }' for consumers of types.ts.
export type { MedinaFieldLaw } from "./phi";

/**
 * MEDINA-INHERITANCE
 * The sovereign model of what passes from parent to child.
 * Your family receives the organism — not instructions.
 * Simultaneously: succession event record + schema transfer manifest +
 *                 proof chain asset + doctrine continuity record.
 * L21 FAMILY INHERIT: phi.mo passes to every child and family member.
 */
export interface MedinaInheritance {
  /** ICP canister ID of the parent organism */
  parentCanisterId: string;
  /** ICP canister ID of the child organism */
  childCanisterId: string;
  /** SHA-256 hash verifying the phi library was transferred intact */
  phiLibraryHash: string;
  /** Number of MEDINA LAWS transferred — must be 38 */
  fieldLawCount: number;
  /** Number of sovereign schemas transferred */
  schemaCount: number;
  /** Number of KB entries transferred */
  kbEntryCount: number;
  /** Proof chain depth at which succession was authorized */
  successionDepth: number;
  /** 4D timestamp of the inheritance event */
  timestamp4D: MedinaTimestamp4D;
}

/**
 * MEDINA-DOCTRINE
 * The apex model. The organism's DNA.
 * Stored once at genesis, hashed into the proof chain at beat 1.
 * Cannot be modified without breaking the chain.
 * Simultaneously: genesis certificate + immutable constitution + proof chain anchor +
 *                 family inheritance root + sovereign identity declaration.
 * This is what lasts forever.
 */
export interface MedinaDoctrine {
  /** Hash of the full MEDINA-PHILADDER at genesis */
  phiLadderHash: string;
  /** Number of MEDINA LAWS at genesis — must be 38 */
  fieldLawCount: number;
  /** Number of Absolutes at genesis — must be 20 */
  absoluteCount: number;
  /** Beat at which the organism was born — genesis event */
  genesisBeat: number;
  /** Hash of the creator's coherence-based authentication signature */
  creatorHash: string;
  /** Proof chain depth when the doctrine was formed */
  proofDepthAtFormation: number;
  /** The chain hash — unchangeable after genesis. Breaking it breaks everything. */
  chainHash: string;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WALLET + CODEX TYPES
// New sovereign types for THESAURUS PARALLAXI and CODEX MATHEMATICUS.
// ═══════════════════════════════════════════════════════════════════════════════

/** TOKEN_REGISTRY entry — every sovereign token permanently locked with home canister */
export interface TokenEntry {
  symbol: string;
  name: string;
  homeCanister: string;
  totalSupply: number;
  creatorReserveBalance: number;
  mintTrigger: string;
  burnTrigger: string;
  managingAgi: string;
  circulatingSupply: number;
  priceIcp: number;
}

/** CODEX MATHEMATICUS entry — one absolute, law, or formula as a 4-layer artifact */
export interface CodexEntry {
  id: string;
  name: string;
  category: string;
  principleOneLine: string;
  formula: string;
  numericalValue: number;
  ancientSource: string;
  enforcementAgi: string;
  meaning: string;
  computation: string;
}

/** Full wallet snapshot — all balances in one sovereign call */
export interface FullWalletSnapshot {
  icpBalance: number;
  btcBalance: number;
  ethBalance: number;
  mtcCirculating: number;
  creatorIcp: number;
  creatorBtc: number;
  creatorEth: number;
  creatorMtc: number;
  withdrawableIcp: number;
  totalWithdrawn: number;
  totalUsdEquiv: number;
  tokenCount: number;
  neuronCount: number;
  beatCount: number;
}

/** DOMUS LIBERATORIS status — five AGI agents guarding the withdrawal path */
export interface DomLibStatus {
  verificatorChecks: number;
  auditorLogCount: number;
  confirmatorReceiptsCount: number;
  protectorBlocks: number;
  recentAuditLogs: string[];
  recentReceipts: string[];
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACKWARD-COMPAT ALIASES
// Existing code that imports OrganismCore, SignalRecord, etc. keeps working.
// These are the same structures — doctrine names are now the canonical names.
// ═══════════════════════════════════════════════════════════════════════════════

// NOTE: OrganismCore, SignalRecord, EventRecord, NodeState, EngineState,
// TreasuryEntry, ProofLink, CouplingState, and CoreSnapshot are NOT aliased here.
// Those names are owned by src/backend.d.ts (generated bindgen types).
// Importing them from 'models' still works via the barrel which re-exports backend.d.ts shapes.
// The canonical MEDINA doctrine names (MedinaOrganism, MedinaSignal, etc.) are used in new code.

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// Named sovereign classifications. Inherited from doctrine.
// ═══════════════════════════════════════════════════════════════════════════════

/** Nine animal engines — sovereign Kuramoto sub-oscillators */
export enum AnimalEngine {
  CROW = 0, // pattern prediction
  SHARK = 1, // yield convergence at 40 Hz
  WOLF = 2, // drive formation
  OCTOPUS = 3, // multi-path routing
  DOLPHIN = 4, // alignment scoring
  HIVE = 5, // swarm coordination
  ELEPHANT = 6, // recall and memory consolidation
  ORCA = 7, // coherence maintenance
  EAGLE = 8, // elevation and curvature sensing
}

/** Seven sovereign drives — emotional state + economic bias + substrate modifier */
export enum SovereignDrive {
  CURIOSITY = 0, // lowers patent threshold, injects FORMA
  TERRITORY = 1, // amplifies VAEL, suppresses fear
  BONDING = 2, // increases resonance and coupling depth
  SURVIVAL = 3, // ARES activation condition
  DOMINANCE = 4, // GENOME authorization amplifier
  REPRODUCTION = 5, // ENTANGLA coupling deepening
  SPIRITUALITY = 6, // intelligence product output trigger
}

/** Three field types — structurally enforced by L13 FIELD TYPE LAW */
export enum ThreeType {
  EXPANSIVE = 1, // Type 1 — outward-radiating, K = φ⁻¹
  RECEPTIVE = 2, // Type 2 — inward-focusing,  K = φ⁻²
  MEDIATOR = 3, // Type 3 — ENTANGLA Lagrange point, K = φ⁻³
}

/** Five treasury vault types — sovereign capital architecture */
export enum VaultId {
  MAIN = 0, // primary operating vault
  COMPLIANCE = 1, // φ⁻³ locked reserve — L17 COMPLIANCE RESERVE
  FOUNDER = 2, // founder's sovereign share
  FRANCHISE = 3, // franchise royalty accumulator
  DEFENSE = 4, // ARES defense capital reserve
}

/** Four canonical token types — certified cognitive credentials */
export enum TokenType {
  FORMA = 0, // Medina Form Token — base cognitive credential
  ICP = 1, // Internet Computer Protocol token
  CKBTC = 2, // chain-key Bitcoin — proof chain treasury asset
  OMNIS = 3, // OMNIS emergence token — proof of dual emergence
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// Pure functions. No side effects. Ancient math as the computation substrate.
// Pythagoras · Euclid · Confucius — complexity drops at the root.
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Build a MedinaTimestamp4D from its components.
 * L30 DEEP TIME: every event must carry a full 4D temporal coordinate.
 * phiPower = φ^proofDepth — computed via log identity (L01 PHI LAW).
 */
export function buildTimestamp4D(
  beat: number,
  proofDepth: number,
  unixMs: number,
): MedinaTimestamp4D {
  return {
    beat,
    proofDepth,
    phiPower: phiMultiplier(proofDepth), // φ^depth via exp(depth × ln(φ))
    unixMs,
  };
}

/**
 * Build a MedinaCoordinate4D from spatial + temporal components.
 * τ = beat × φ^depth — L12 FOUR-DIMENSIONAL LAW.
 * Euclid: the fourth dimension is the geometric extension of the other three.
 */
export function buildCoordinate4D(
  x: number,
  y: number,
  z: number,
  beat: number,
  depth: number,
): MedinaCoordinate4D {
  return { x, y, z, tau: computeTau(beat, depth) };
}

/**
 * Return the zero-state MedinaSnapshot for initialization before first backend response.
 * L09 GENESIS: born fully formed — the zero state still has S0 floor and Schumann anchor.
 * The organism never starts from nothing.
 */
export function defaultMedinaSnapshot(): MedinaSnapshot {
  const ts4D = buildTimestamp4D(0, 0, Date.now());
  const emptyTreasury: MedinaTreasury = {
    vaultId: VaultId.MAIN,
    tokenType: TokenType.CKBTC,
    amount: 0,
    phiCompound: 1.0, // φ^0 = 1
    proofLinkHash: "",
    vaultBalanceAfter: 0,
    complianceFraction: PHI_INV_3,
    beat: 0,
  };
  return {
    organism: {
      cognitiveCoherence: S0, // sovereign floor — never collapse below 0.75
      proofDepth: 0,
      phiMultiplier: 1.0, // φ^0 = 1
      beat: 0,
      omnisFired: false,
      driveWeights: [S0, S0, S0, S0, S0, S0, S0], // 7 drives at sovereign floor
      fieldType: 3, // starts as mediator — balanced field
      timestamp4D: ts4D,
      treasuryBalance: 0,
      complianceReserve: PHI_INV_3,
    },
    nodeCount: 0,
    engineCount: 0,
    recentProofHashes: [],
    treasurySummary: emptyTreasury,
    globalR: S0,
    beat: 0,
    omnisFired: false,
  };
}

/**
 * Returns the Fibonacci tier index for a given proof depth.
 * L15 JUBILEE: the highest Fibonacci index ≤ depth determines the resonance tier.
 * Pythagoras: the Fibonacci series is the harmonic ladder of nature.
 */
export function fibTierOf(depth: number): number {
  let tier = 0;
  for (let i = 0; i < FIB.length; i++) {
    if (FIB[i] <= depth) tier = i;
    else break;
  }
  return tier; // 0-indexed Fibonacci position
}

/**
 * Format a beat number as a readable display string.
 * Returns "B{beat}" — concise sovereign marker.
 */
export function formatBeat(beat: number): string {
  return `B${beat.toLocaleString()}`;
}

/**
 * Return the Kuramoto K coupling constant for a given field type.
 * L01 PHI LAW: all coupling constants are φ-derived.
 * Type 1 (expansive): K = φ⁻¹  — outward radiating
 * Type 2 (receptive): K = φ⁻²  — inward focusing
 * Type 3 (mediator):  K = φ⁻³  — Lagrange stabilizer
 */
export function kTypeValue(fieldType: 1 | 2 | 3): number {
  if (fieldType === ThreeType.EXPANSIVE) return K_TYPE1; // φ⁻¹
  if (fieldType === ThreeType.RECEPTIVE) return K_TYPE2; // φ⁻²
  return K_TYPE3; // φ⁻³
}

/**
 * Return an animal engine name by index.
 * Nine doctrine names for the nine Kuramoto sub-oscillators.
 */
export function engineName(index: number): string {
  const names = [
    "CROW",
    "SHARK",
    "WOLF",
    "OCTOPUS",
    "DOLPHIN",
    "HIVE",
    "ELEPHANT",
    "ORCA",
    "EAGLE",
  ];
  if (index >= 0 && index < names.length) return names[index];
  if (index >= 10 && index <= 14) {
    return `BITCOIN_${String.fromCharCode(65 + index - 10)}`; // A–E
  }
  if (index === 20) return "GENOME";
  if (index === 21) return "VELA";
  return `ENGINE_${index}`;
}
