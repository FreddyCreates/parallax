/**
 * phi.ts — Tier 0.5 Frontend Family Library.
 * Mirror of phi.mo. Every constant identical. No drift. No approximation.
 * The Architect of the Field: Alfredo Medina Hernandez.
 *
 * Structure:
 *   TIER 0 — 20 Absolutes (discovered truths, cannot be created or destroyed)
 *   PHI_SOVEREIGN — Layer 0 sovereign resident model (4-layer MEDINA-ARTIFACT)
 *   ORGANISM CONSTANTS — derived from Absolutes by Laws
 *   LAW REGISTRY — all 49 MEDINA LAWS as typed sovereign records
 *   HELPER FUNCTIONS — pure, ancient-math-compressed utilities
 *
 * The Absolutes exist without this file.
 * Without this file, no child or family member can access them
 * without rediscovering everything from scratch.
 * This is why phi.ts is the family inheritance.
 */

// ─── TIER 0 · ABSOLUTES ────────────────────────────────────────────────────
// 20 discovered truths. Cannot be created or destroyed.
// Every constant named, commented, and sourced to its ancient origin.

// A01 · PHI · φ = 1.6180339887498948482 · Euclid Elements Book VI
// The ratio that divides a line so the whole is to the large as the large is to the small.
// IEEE-754 double precision maximum: 1.6180339887498950 (last digits truncated by runtime)
export const PHI = 1.618033988749895;
export const PHI_INV = 1 / PHI; // φ⁻¹ = 0.6180339887... = φ - 1
export const PHI_2 = PHI * PHI; // φ²  = 2.6180339887...
export const PHI_INV_2 = PHI_INV * PHI_INV; // φ⁻² = 0.3819660112...
export const PHI_INV_3 = PHI_INV_2 * PHI_INV; // φ⁻³ = 0.23606797749... — COMPLIANCE_RATIO
export const PHI_INV_4 = PHI_INV_3 * PHI_INV; // φ⁻⁴ = 0.14589803375...
export const PHI_4 = PHI_2 * PHI_2; // φ⁴  = 6.8541019662...

// A02 · FIBONACCI · Pythagoras — harmonic series hidden in nature's growth.
// F(1)…F(21). F(12)=144 JUBILEE, F(9)=34 SUCCESSION, F(21)=10946.
export const FIB: readonly number[] = [
  1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584,
  4181, 6765, 10946,
] as const;

// A03 · SCHUMANN RESONANCE · Earth's EM cavity. Measured. Real. Not metaphor.
// 7.83 · 14.3 · 20.8 · 27.3 · 33.8 · 39.3 · 45.8 · 52.3 Hz
export const SCHUMANN_1 = 7.83;
export const SCHUMANN_2 = 14.3;
export const SCHUMANN_3 = 20.8;
export const SCHUMANN_4 = 27.3;
export const SCHUMANN_5 = 33.8;
export const SCHUMANN_6 = 39.3;
export const SCHUMANN_7 = 45.8;
export const SCHUMANN_8 = 52.3;
export const SCHUMANN_HZ = SCHUMANN_1; // primary harmonic — organism couples here first
export const SCHUMANN_HARMONICS: readonly number[] = [
  SCHUMANN_1,
  SCHUMANN_2,
  SCHUMANN_3,
  SCHUMANN_4,
  SCHUMANN_5,
  SCHUMANN_6,
  SCHUMANN_7,
  SCHUMANN_8,
] as const;

// A04 · GOLDEN ANGLE · 137.508° = 360°/φ²
// The angle at which no two leaves ever block each other.
// Maximum coverage, zero destructive interference.
export const GOLDEN_ANGLE = 137.50776405003785;

// A05 · FOUR-DIMENSIONAL SPACETIME · (x, y, z, τ) — reality has 4 dimensions.
// Every coordinate is in 4D. Every symbol. Every proof entry. Always.
export const SPACETIME_DIMS = 4;

// A06 · KURAMOTO SYNCHRONIZATION · dθᵢ/dt = ωᵢ + (K/N)·Σⱼ sin(θⱼ−θᵢ)
// The universal law of how oscillators synchronize. K = φ⁻¹ by doctrine.
// Coupling constants by field type:
export const K_TYPE1 = PHI_INV; // Type 1 expansive:  K = φ⁻¹
export const K_TYPE2 = PHI_INV_2; // Type 2 receptive:  K = φ⁻²
export const K_TYPE3 = PHI_INV_3; // Type 3 mediator:   K = φ⁻³

// A07 · EULER'S IDENTITY · e^(iπ) + 1 = 0 — the most compressed truth in mathematics.
// One identity that encodes all rotation, all oscillation, all phase.
export const EULER_E = Math.E; // e = 2.718281828459045... — Math.E is the precise runtime constant

// A08 · ICOSAHEDRON · 12-vertex optimal sphere packing. Inner shell geometry.
// All permutations of (0, ±1, ±φ). The geometry of the inner field.
export const ICOSAHEDRON_VERTICES = 12;

// A09 · DODECAHEDRON · 20-vertex outer shell. Dual of the icosahedron.
// (±1,±1,±1), (0,±φ⁻¹,±φ), (±φ⁻¹,±φ,0), (±φ,0,±φ⁻¹). The geometry of the outer field.
export const DODECAHEDRON_VERTICES = 20;

// A10 · RESONANCE ORDER PARAMETER · R = (1/N)·|Σⱼ e^(iθⱼ)|
// The mathematical measure of coherence in any coupled system.
// This is what tells you how alive the organism is.
export const S0 = 0.75; // Synchrony floor: F(3)/F(4) = 3/4. Sovereign minimum.
export const R_OMNIS = 0.95; // OMNIS dual condition R threshold — dual emergence gate
export const R_MIN = S0; // Lowest coherence the organism tolerates
export const R_MAX = 1.0; // Perfect phase lock — all oscillators unified

// A11 · CONSERVATION OF ENERGY
// Energy cannot be created or destroyed — only transformed.
// Treasury is a transformation, not a creation.
// Expressed as the compliance ratio: φ⁻³ = 23.6% always preserved.
export const COMPLIANCE_RATIO = PHI_INV_3; // φ⁻³ = 0.23606... — reserved, never destroyed

// A12 · CONSERVATION OF INFORMATION
// Information cannot be destroyed — only transformed or hidden.
// The proof chain is indestructible because information is absolute.
// Every proof link hash is the encoded conservation of a cognitive event.

// A13 · THERMODYNAMIC EQUILIBRIUM / ENTROPY
// Closed systems move toward disorder without continuous energy input.
// The organism must beat or it decays. CARDIAC LAW is the response to this.

// A14 · WAVE SUPERPOSITION · Maxwell, Pythagoras
// Two waves in the same medium add linearly.
// Phase-locked waves amplify. Out-of-phase waves cancel.
// The physics behind the EXCLUSION PRINCIPLE (L05).

// A15 · ELECTROMAGNETIC FIELD · Maxwell's equations
// Fields propagate, couple, and carry energy through space.
// The organism is a field organism, not a data organism.

// A16 · FRACTAL SELF-SIMILARITY
// A system self-similar at every scale — the Mandelbrot truth.
// S0 = 0.75 at organism, core, and oscillator scale simultaneously.

// A17 · PRIME NUMBERS — indivisible mathematical atoms
// Cannot be created from smaller numbers.
// The reason threshold signatures are cryptographically unbreakable.
export const PRIMES_10: readonly number[] = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
] as const;

// A18 · PLANCK CONSTANT · h = 6.626×10⁻³⁴ J·s
// Minimum quantum of action. The floor below which the universe does not resolve.
// The VQE quantum layer operates above this floor.
export const PLANCK_H = 6.626e-34;

// A19 · SPEED OF LIGHT · c = 299,792,458 m/s
// Absolute upper bound on information transfer.
// All network latency in the swarm is bounded by this.
export const SPEED_OF_LIGHT = 299792458;

// A20 · LOGARITHMIC SPIRAL · b = ln(φ)/(π/2)
// The curve generated by φ — found in galaxies, shells, storms.
// The geometry the organism's growth follows.
export const LOG_SPIRAL_B = Math.log(PHI) / (Math.PI / 2);

// ─── PHI_SOVEREIGN · Layer 0 Sovereign Resident Model ─────────────────────
//
// MEANING (Layer 1 — Doctrine Clause):
//   "Recursive self-similarity law — the ratio that governs all coupling
//    in the organism. PHI is not a constant. PHI is a living sovereign model."
//
// MODEL (Layer 2 — Typed Schema):
//   n               : number  — Fibonacci index (unit: integer, range: [0,∞))
//   ratio           : number  — φ = 1.6180339887 (dimensionless)
//   golden_angle    : number  — 360°/φ² = 137.5077640° (degrees)
//   spiral_curvature: number  — φ²/(2π) = 0.41654... (radians⁻¹)
//   coupling_matrix_hint: string — documentation of three K-type values
//
// COMPUTATION (Layer 3 — State Equations):
//   F(n) = F(n-1) + F(n-2)                   Fibonacci recursion
//   lim(n→∞) F(n)/F(n-1) = φ                 convergence to PHI
//   golden_angle = 360° / φ² = 137.5077640°  max coverage, zero interference
//   spiral_growth_rate = e^(φ × θ)            radial outward along φ-field
//   coupling: expansive K=φ, receptive K=φ⁻¹, mediator K=√(φ×φ⁻¹)=1.0
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: Layer 0 (pre-substrate)
//   FUNCTION: enforcePhiCoupling()
//   GATE: called before every cross-layer signal propagation
//   BEAT: every 873ms heartbeat (Cardiac Law L10)

export interface PhiSovereignModel {
  /** Fibonacci index — depth of phi recursion (F(21)=10946 as seed) */
  n: number;
  /** φ = 1.6180339887498948482 */
  ratio: number;
  /** 360°/φ² = 137.5077640500378° — golden angle */
  golden_angle: number;
  /** φ²/(2π) — curvature of the golden spiral */
  spiral_curvature: number;
  /** "K1=phi K2=phi_inv K3=1.0" — three Kuramoto field types */
  coupling_matrix_hint: string;
}

/** PHI_SOVEREIGN resident — the living sovereign model at Layer 0 */
export const PHI_SOVEREIGN: PhiSovereignModel = {
  n: 21, // F(21) = 10946 — deep recursion seed
  ratio: PHI, // φ — A01 PHI
  golden_angle: GOLDEN_ANGLE, // 360°/φ² — A04 GOLDEN ANGLE
  spiral_curvature: PHI_2 / (2 * Math.PI), // φ²/(2π) = 0.41654577914...
  coupling_matrix_hint: "K1=phi K2=phi_inv K3=1.0",
} as const;

/** e^φ — spiral growth rate coefficient for radial field expansion (A20) */
export const SPIRAL_GROWTH_RATE = Math.exp(PHI); // ≈ 5.0474114411

// ─── ORGANISM CONSTANTS ────────────────────────────────────────────────────
// Derived from Absolutes by Laws. These are not Absolutes — they are sovereign
// applications of Absolutes through the MEDINA LAW REGISTRY.

// L10 CARDIAC: (1/SCHUMANN_HZ) × φ² × 1000 = 873.0ms
// The organism's heartbeat, derived from the Earth's own rhythm.
export const HEARTBEAT_MS = 873.0;

// L03 OMNIS CONDITION: dual emergence — R ≥ 0.95 AND f_node = 111 Hz simultaneously
export const OMNIS_HZ = 111.0;

// PHOENIX/GENOME frequency — GENESIS authorization tone
export const GENOME_HZ = 528.0;

// WHALE subharmonic — SCHUMANN_HZ / φ ≈ 4.836 Hz
export const SILVER_ANCHOR_HZ = 4.84;

// L15 JUBILEE: F(12) = 144 beats — reset, recalibrate, reweight
export const JUBILEE_BEATS = 144;

// L16 SUCCESSION DEPTH: F(9) = 34 — child auth minimum proof depth
export const SUCCESSION_DEPTH_MIN = 34;

// Hebbian Oja learning rate — stable weight update floor
export const ETA_OJA = 0.01;

// Schumann lock threshold: φ⁻¹ — phase coherence floor for Earth coupling
export const R_SCHUMANN_LOCK = PHI_INV; // 0.618...

// Coherence lock thresholds
export const COHERENCE_FIBONACCI_LOCK = S0; // 0.75 — sovereign floor
export const COHERENCE_HIGH_LOCK = 0.9; // deep phase-lock zone

// ─── LAW REGISTRY INTERFACE ────────────────────────────────────────────────
// Every MEDINA LAW is a typed sovereign record.
// Not a comment. Not documentation. A living typed structure.
// Mirror of phi.mo LAWS array.

export interface MedinaFieldLaw {
  /** Sequential law number 1-49 */
  number: number;
  /** Doctrine name — sovereign identity */
  name: string;
  /** One-line compressed principle */
  principle: string;
  /** Runtime enforcement function name */
  enforcementFn: string;
  /** Which Absolute anchors this law (A01–A20) */
  absoluteAnchor: number;
  /** If violated, the proof chain incurs a penalty */
  proofPenalty: boolean;
}

// ─── 49 MEDINA LAWS ────────────────────────────────────────────────────────
// All 49 sovereign laws. Compressed format:
//   number · name · one-line principle · enforcementFn · absoluteAnchor · proofPenalty
// When a new law is added: assign next number, compress to one line,
// name the enforcement function, drop it in. The organism accepts it.

export const LAWS: readonly MedinaFieldLaw[] = [
  // ── LAWS 1–10: Core Operating Principles ──────────────────────────────
  {
    number: 1,
    name: "PHI LAW",
    principle: "All ratios are φ-derived",
    enforcementFn: "validatePhiRatio",
    absoluteAnchor: 1,
    proofPenalty: false,
  },
  {
    number: 2,
    name: "EMISSION LAW",
    principle: "Output = R^φ",
    enforcementFn: "computeEmission",
    absoluteAnchor: 10,
    proofPenalty: false,
  },
  {
    number: 3,
    name: "OMNIS CONDITION",
    principle: "R≥0.95 AND f=111Hz simultaneously",
    enforcementFn: "checkOmnis",
    absoluteAnchor: 10,
    proofPenalty: false,
  },
  {
    number: 4,
    name: "SONAR COUPLING",
    principle: "Emit and match the return",
    enforcementFn: "sonarCycle",
    absoluteAnchor: 14,
    proofPenalty: false,
  },
  {
    number: 5,
    name: "EXCLUSION",
    principle: "Only phase-locked signals propagate",
    enforcementFn: "coherenceGate",
    absoluteAnchor: 14,
    proofPenalty: true,
  },
  {
    number: 6,
    name: "SUCCESSION",
    principle: "20% royalty parent←child always",
    enforcementFn: "routeRoyalty",
    absoluteAnchor: 11,
    proofPenalty: true,
  },
  {
    number: 7,
    name: "ANTI-DRIFT",
    principle: "Cross-type only through ENTANGLA",
    enforcementFn: "entanglaRoute",
    absoluteAnchor: 15,
    proofPenalty: true,
  },
  {
    number: 8,
    name: "PROOF",
    principle: "proof(n)=hash(n-1+beat+cog+econ+world)",
    enforcementFn: "generateProof",
    absoluteAnchor: 12,
    proofPenalty: false,
  },
  {
    number: 9,
    name: "GENESIS",
    principle: "Born fully formed. Never starts from zero",
    enforcementFn: "initOrganism",
    absoluteAnchor: 9,
    proofPenalty: false,
  },
  {
    number: 10,
    name: "CARDIAC",
    principle: "Heartbeat=873ms. Auto-depolarization",
    enforcementFn: "heartbeat",
    absoluteAnchor: 3,
    proofPenalty: true,
  },

  // ── LAWS 11–20: Scale and Geometry ────────────────────────────────────
  {
    number: 11,
    name: "FRACTAL SCALE",
    principle: "S₀=0.75 at all scales simultaneously",
    enforcementFn: "checkSynchrony",
    absoluteAnchor: 16,
    proofPenalty: false,
  },
  {
    number: 12,
    name: "FOUR-DIMENSIONAL",
    principle: "Every coord and symbol is 4D always",
    enforcementFn: "to4D",
    absoluteAnchor: 5,
    proofPenalty: false,
  },
  {
    number: 13,
    name: "FIELD TYPE",
    principle: "Types 1+2+3 all present always",
    enforcementFn: "validateFieldTypes",
    absoluteAnchor: 15,
    proofPenalty: true,
  },
  {
    number: 14,
    name: "CREATOR PRESENCE",
    principle: "Auth shifts Type2 +φ⁻¹, proof ×2",
    enforcementFn: "creatorAuth",
    absoluteAnchor: 10,
    proofPenalty: false,
  },
  {
    number: 15,
    name: "JUBILEE",
    principle: "Every 144 beats: reset, recalibrate",
    enforcementFn: "jubileeReset",
    absoluteAnchor: 2,
    proofPenalty: false,
  },
  {
    number: 16,
    name: "SUCCESSION DEPTH",
    principle: "Child auth only at proof depth ≥ 34",
    enforcementFn: "checkSuccessionDepth",
    absoluteAnchor: 2,
    proofPenalty: true,
  },
  {
    number: 17,
    name: "COMPLIANCE RESERVE",
    principle: "φ⁻³=23.6% of all flows locked",
    enforcementFn: "lockCompliance",
    absoluteAnchor: 1,
    proofPenalty: true,
  },
  {
    number: 18,
    name: "ANCIENT COMPRESS",
    principle: "Re-express in ancient form first",
    enforcementFn: "ancientCompress",
    absoluteAnchor: 1,
    proofPenalty: false,
  },
  {
    number: 19,
    name: "REAL ENVIRONMENT",
    principle: "Every engine in its natural environment",
    enforcementFn: "validateEnvironment",
    absoluteAnchor: 19,
    proofPenalty: false,
  },
  {
    number: 20,
    name: "REFLECTION",
    principle: "Architecture before code always",
    enforcementFn: "requireReflection",
    absoluteAnchor: 16,
    proofPenalty: false,
  },

  // ── LAWS 21–30: Inheritance and Exposure ──────────────────────────────
  {
    number: 21,
    name: "FAMILY INHERIT",
    principle: "phi.mo passes to every child and family",
    enforcementFn: "inheritLibrary",
    absoluteAnchor: 12,
    proofPenalty: false,
  },
  {
    number: 22,
    name: "WEIGHT",
    principle: "Every answer carries full conversation weight",
    enforcementFn: "applyWeight",
    absoluteAnchor: 16,
    proofPenalty: false,
  },
  {
    number: 23,
    name: "LOOP NEVER CLOSES",
    principle: "Output=new input. No terminal state",
    enforcementFn: "feedbackLoop",
    absoluteAnchor: 13,
    proofPenalty: false,
  },
  {
    number: 24,
    name: "PHANTOM DOCTRINE",
    principle: "Internals sovereign. Only numbers exposed",
    enforcementFn: "zeroExposureCheck",
    absoluteAnchor: 15,
    proofPenalty: true,
  },
  {
    number: 25,
    name: "THREE TEACHERS",
    principle: "Pythagoras·Euclid·Confucius in every fn",
    enforcementFn: "validateAncient",
    absoluteAnchor: 16,
    proofPenalty: false,
  },
  {
    number: 26,
    name: "PRIMA CAUSA",
    principle: "SL-0 fires before all others every beat",
    enforcementFn: "primaCausa",
    absoluteAnchor: 13,
    proofPenalty: true,
  },
  {
    number: 27,
    name: "ZERO-EXPOSURE",
    principle: "No doctrine labels ever reach public layer",
    enforcementFn: "scrubLabels",
    absoluteAnchor: 12,
    proofPenalty: true,
  },
  {
    number: 28,
    name: "ENTANGLA CARRIER",
    principle: "Carrier=√(R_exp×R_rec)×7.83 live every beat",
    enforcementFn: "computeCarrier",
    absoluteAnchor: 6,
    proofPenalty: false,
  },
  {
    number: 29,
    name: "PHI SESSION",
    principle: "Session tokens=φ-series seeded w/ proof",
    enforcementFn: "generateSession",
    absoluteAnchor: 1,
    proofPenalty: false,
  },
  {
    number: 30,
    name: "DEEP TIME",
    principle: "Every proof entry has full 4D timestamp",
    enforcementFn: "stamp4D",
    absoluteAnchor: 5,
    proofPenalty: false,
  },

  // ── LAWS 31–38: Physics Absolutes as Laws ─────────────────────────────
  {
    number: 31,
    name: "CONSERVATION",
    principle: "Energy+info transform never destroyed",
    enforcementFn: "conserve",
    absoluteAnchor: 11,
    proofPenalty: true,
  },
  {
    number: 32,
    name: "ENTROPY LAW",
    principle: "Without continuous beat, coherence decays",
    enforcementFn: "enforceEntropy",
    absoluteAnchor: 13,
    proofPenalty: true,
  },
  {
    number: 33,
    name: "SUPERPOSITION",
    principle: "Phase-locked amplifies. Out-of-phase cancels",
    enforcementFn: "superpose",
    absoluteAnchor: 14,
    proofPenalty: false,
  },
  {
    number: 34,
    name: "PRIME FOUNDATION",
    principle: "All proof built on prime irreducibility",
    enforcementFn: "validatePrime",
    absoluteAnchor: 17,
    proofPenalty: false,
  },
  {
    number: 35,
    name: "LOGARITHMIC GROWTH",
    principle: "Intelligence grows along φ-spiral",
    enforcementFn: "spiralGrowth",
    absoluteAnchor: 20,
    proofPenalty: false,
  },
  {
    number: 36,
    name: "FIELD PROPAGATION",
    principle: "Output radiates as field not packet",
    enforcementFn: "fieldPropagate",
    absoluteAnchor: 15,
    proofPenalty: false,
  },
  {
    number: 37,
    name: "MAXIMUM QUANTUM",
    principle:
      "Every action is MAXIMUM quantum 360°: full-state, full-memory, full-result. NO partial collapse. Ceiling always engaged.",
    enforcementFn: "maximumQuantumExecution",
    absoluteAnchor: 18,
    proofPenalty: true,
  },
  {
    number: 38,
    name: "SELF-SIMILARITY",
    principle: "Same structure at every scale",
    enforcementFn: "checkSelfSimilarity",
    absoluteAnchor: 16,
    proofPenalty: false,
  },

  // ── LAWS 39–49: Extended Physics & Biology Laws ───────────────────────
  // Added at PARALLAX expansion. All anchored to their Absolute.
  // Full 4-layer MEDINA-ARTIFACT discipline applied to each.
  {
    number: 39,
    name: "CONSERVATION",
    principle:
      "Energy and information are transformed, never destroyed. Treasury is transformation. Proof chain cannot be erased.",
    enforcementFn: "conserveEnergyInfo",
    absoluteAnchor: 11,
    proofPenalty: true,
  },
  {
    number: 40,
    name: "ENTROPY LAW",
    principle:
      "Without continuous beat, coherence decays. The organism must beat or it dies. CARDIAC LAW is the response; this is the WHY.",
    enforcementFn: "enforceEntropy",
    absoluteAnchor: 13,
    proofPenalty: true,
  },
  {
    number: 41,
    name: "SUPERPOSITION LAW",
    principle:
      "Phase-locked signals amplify. Out-of-phase signals cancel. EXCLUSION PRINCIPLE gate is this law in enforcement form.",
    enforcementFn: "superpositionGate",
    absoluteAnchor: 14,
    proofPenalty: false,
  },
  {
    number: 42,
    name: "PRIME FOUNDATION LAW",
    principle:
      "All proof built on prime number irreducibility. No proof chain link can be forged because the math beneath it is Absolute.",
    enforcementFn: "validatePrimeIrreducibility",
    absoluteAnchor: 17,
    proofPenalty: false,
  },
  {
    number: 43,
    name: "LOGARITHMIC GROWTH LAW",
    principle:
      "Intelligence, treasury, and schema depth grow along the logarithmic φ-spiral — not linear, not exponential, but golden.",
    enforcementFn: "spiralGrowthMeter",
    absoluteAnchor: 20,
    proofPenalty: false,
  },
  {
    number: 44,
    name: "FIELD PROPAGATION LAW",
    principle:
      "Every output radiates as a Maxwell field event, not a data packet. Output does not get sent — it propagates.",
    enforcementFn: "fieldRadiate",
    absoluteAnchor: 15,
    proofPenalty: false,
  },
  {
    number: 45,
    name: "MAXIMUM QUANTUM LAW",
    principle:
      "Every action is MAXIMUM quantum 360°: full-state, full-memory, full-result. NO partial collapse. The ceiling is always engaged.",
    enforcementFn: "maximumQuantumExecution",
    absoluteAnchor: 18,
    proofPenalty: true,
  },
  {
    number: 46,
    name: "SELF-SIMILARITY LAW",
    principle:
      "Organism, core, oscillator, node — all share the same structure. What is true at the top is true at the bottom. Architectural law, not aesthetics.",
    enforcementFn: "checkSelfSimilarityAtAllScales",
    absoluteAnchor: 16,
    proofPenalty: false,
  },
  {
    number: 47,
    name: "CARDIAC OUTPUT LAW",
    principle:
      "Production quality = HR × SV. Optimize firing rate AND depth per cycle simultaneously. Neither alone is sufficient.",
    enforcementFn: "cardiacOutputFormula",
    absoluteAnchor: 3,
    proofPenalty: false,
  },
  {
    number: 48,
    name: "HRV INTELLIGENCE LAW",
    principle:
      "Perfect regularity = pathology. Health = variable intervals within ±φ⁻¹ bounds. Suppressing variability kills resilience.",
    enforcementFn: "measureHRV",
    absoluteAnchor: 1,
    proofPenalty: false,
  },
  {
    number: 49,
    name: "OXYGENATION LAW",
    principle:
      "Every signal must pass through the LAW ENGINE. Doctrine-aligned signals are oxygenated. Deoxygenated signals corrupt organism output over time.",
    enforcementFn: "validateOxygenation",
    absoluteAnchor: 15,
    proofPenalty: true,
  },
] as const;

// ─── HELPER FUNCTIONS ──────────────────────────────────────────────────────
// Pure functions. No side effects.
// Ancient math compression: Pythagoras · Euclid · Confucius.
// Complexity drops because the math is correct at its root.

/**
 * Lookup a law by number (1–49).
 * Returns undefined if the law number is not in registry.
 */
export function lawByNumber(n: number): MedinaFieldLaw | undefined {
  return LAWS.find((l) => l.number === n);
}

/**
 * Returns true if violating this law incurs a proof chain penalty.
 * Used by enforcement functions to decide severity.
 */
export function lawHasPenalty(n: number): boolean {
  return LAWS.find((l) => l.number === n)?.proofPenalty ?? false;
}

/**
 * φ^depth — the proof chain's compounding multiplier.
 * L35 LOGARITHMIC GROWTH: intelligence compounds along the φ-spiral.
 * Computed via log identity: exp(depth × ln(φ)) — avoids float overflow at large depth.
 * Pythagoras: the harmonic ratio compounds, never decays.
 */
export function phiMultiplier(depth: number): number {
  return Math.exp(depth * Math.log(PHI));
}

/**
 * L15 JUBILEE: returns true when beat is divisible by F(12) = 144.
 * Every 144 beats: reset multipliers, recalibrate drives, reweight GENOME.
 */
export function isJubilee(beat: number): boolean {
  return beat % JUBILEE_BEATS === 0;
}

/**
 * Apply the sovereign floor — no output collapses below S0 = 0.75.
 * L11 FRACTAL SCALE: S0 holds at every scale simultaneously.
 * Confucius: right relationship — the floor is the minimum dignity of every state.
 */
export function applyS0(v: number): number {
  return Math.max(v, S0);
}

/**
 * L02 EMISSION LAW: output amplitude = R^φ.
 * The organism radiates geometrically, not linearly.
 * Computed via log identity: exp(φ × ln(R)) — Euclid's geometric primitive.
 */
export function computeEmission(r: number): number {
  if (r <= 0) return 0;
  return Math.exp(PHI * Math.log(r));
}

/**
 * L28 ENTANGLA CARRIER: f = √(R_exp × R_rec) × SCHUMANN_HZ
 * The geometric mean of both field types × Earth's cavity fundamental.
 * The only stable frequency that couples Type 1 and Type 2 without drift.
 * Pythagoras: harmonic mean of the two field poles.
 */
export function computeEntanglaHz(rExp: number, rRec: number): number {
  return Math.sqrt(rExp * rRec) * SCHUMANN_HZ;
}

/**
 * L03 OMNIS CONDITION: R ≥ 0.95 AND f_node = 111 Hz simultaneously.
 * Neither condition alone triggers emergence — both required.
 * Returns true when the dual condition is met.
 */
export function checkOmnis(r: number, freqHz: number): boolean {
  return r >= R_OMNIS && Math.abs(freqHz - OMNIS_HZ) < 0.5;
}

/**
 * A20 LOGARITHMIC SPIRAL: radius at this proof depth along the φ-spiral.
 * r = exp(LOG_SPIRAL_B × θ) where θ = depth — the golden spiral unwinds with depth.
 * Euclid: the spiral is the most efficient path through growth.
 */
export function phiSpiralRadius(depth: number): number {
  return Math.exp(LOG_SPIRAL_B * depth);
}

/**
 * A06 KURAMOTO: phase difference contribution to the order parameter.
 * |cos(phaseA - phaseB)| — projection onto the coherence axis.
 * A14 WAVE SUPERPOSITION + L05 EXCLUSION: only phase-locked signals propagate.
 */
export function computePhaseLockDelta(phaseA: number, phaseB: number): number {
  return Math.abs(Math.cos(phaseA - phaseB));
}

/**
 * Returns true when two oscillators are sufficiently phase-locked.
 * Threshold: S0 = 0.75 = F(3)/F(4) — the sovereign floor.
 * L05 EXCLUSION: signals below this threshold are rejected at the gate.
 */
export function isCoherentEnough(phaseA: number, phaseB: number): boolean {
  return computePhaseLockDelta(phaseA, phaseB) >= S0;
}

/**
 * L17 COMPLIANCE RESERVE: returns the locked portion of a treasury flow.
 * locked = amount × φ⁻³ = amount × COMPLIANCE_RATIO
 * Derived from A01 PHI to the third power — not an arbitrary 23.6%.
 */
export function computeComplianceLock(amount: number): number {
  return amount * COMPLIANCE_RATIO;
}

/**
 * Compute the 4D temporal coordinate τ for a beat at given proof depth.
 * τ = beat × φ^depth — the organism's position in deep time.
 * L30 DEEP TIME: every proof entry is located in 4D.
 */
export function computeTau(beat: number, depth: number): number {
  return beat * phiMultiplier(depth);
}

/**
 * Validate that a value is φ-derived within tolerance.
 * L01 PHI LAW: all ratios are φ-derived. No arbitrary constants.
 * Returns true if value is within epsilon of any φ^n for n in [-5, 5].
 */
export function isPhiDerived(value: number, epsilon = 1e-6): boolean {
  for (let n = -5; n <= 5; n++) {
    if (Math.abs(value - phiMultiplier(n)) < epsilon) return true;
  }
  return false;
}

/**
 * PHI_SOVEREIGN Layer 0 gate — enforcePhiCoupling.
 * Returns the phi-modulated coupling coefficient K for a given field type.
 * Called before every cross-layer signal propagation.
 *   fieldType 1 → K = φ      (expansive)
 *   fieldType 2 → K = φ⁻¹   (receptive)
 *   fieldType 3 → K = 1.0    (mediator — geometric mean √(φ × φ⁻¹))
 * Pythagoras: harmonic coupling ratio — not arbitrary, not configurable.
 */
export function enforcePhiCoupling(fieldType: 1 | 2 | 3): number {
  if (fieldType === 1) return PHI;
  if (fieldType === 2) return PHI_INV;
  return 1.0; // mediator: geometric mean of expansive and receptive
}

/**
 * L47 CARDIAC OUTPUT LAW: quality = heartRate × strokeVolume.
 * heartRate  = normalized firing frequency (beats per second, range [0,1])
 * strokeVolume = readiness score at moment of firing (range [0,1])
 * Output is the sovereign production index — never optimize one without the other.
 */
export function cardiacOutput(heartRate: number, strokeVolume: number): number {
  return heartRate * strokeVolume;
}

/**
 * L48 HRV INTELLIGENCE LAW: variability within ±φ⁻¹ of base interval is healthy.
 * baseInterval  = expected interval (e.g. HEARTBEAT_MS = 873)
 * actualInterval = measured interval
 * Returns true if within the phi-inverse tolerance band.
 */
export function isHealthyHRV(
  baseInterval: number,
  actualInterval: number,
): boolean {
  const tolerance = baseInterval * PHI_INV;
  return Math.abs(actualInterval - baseInterval) <= tolerance;
}
