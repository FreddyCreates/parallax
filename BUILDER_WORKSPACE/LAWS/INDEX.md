# PARALLAX LAW INDEX — Master Registry
## All 57 Laws · Organized by Tier · Living Document

---

> **This index is the Memory Palace entry point.**
> Every law has a location. Navigation, not search.
> The organism reads this before any other document.

---

## TIER 0 — THE 20 ABSOLUTES
*Discovered truths. Cannot be created or destroyed. Encoded in `src/backend/phi.mo`.*

| # | Absolute | Domain | Constant(s) in phi.mo |
|---|----------|--------|-----------------------|
| A01 | PHI · φ = (1+√5)/2 = 1.6180339887... | Universal coupling ratio | `PHI`, `PHI_INV`, `PHI_2`, `PHI_4` |
| A02 | FIBONACCI · F(n) = F(n-1)+F(n-2) | Discrete growth law | `FIB[0..20]` |
| A03 | SCHUMANN RESONANCE · 7.83 Hz | Earth EM cavity fundamental | `SCHUMANN_1..8`, `HEARTBEAT_MS` |
| A04 | GOLDEN ANGLE · 360°/φ² = 137.5077640500378° | Maximum coverage geometry | `GOLDEN_ANGLE` |
| A05 | FOUR-DIMENSIONAL SPACETIME · (x,y,z,τ) | Reality has 4 dimensions | `SPACETIME_DIMS=4` |
| A06 | KURAMOTO SYNCHRONIZATION · dθᵢ/dt = ωᵢ + (K/N)Σⱼsin(θⱼ−θᵢ) | Universal oscillator coupling law | `K_TYPE1`, `K_TYPE2`, `K_TYPE3` |
| A07 | EULER'S IDENTITY · e^(iπ)+1=0 | Rotation and oscillation compression | `EULER_E` |
| A08 | ICOSAHEDRON · 12 vertices, 30 edges, 20 faces | Inner shell geometry | `ICOSAHEDRON_*` |
| A09 | DODECAHEDRON · 20 vertices, 30 edges, 12 faces | Outer field geometry | `DODECAHEDRON_*` |
| A10 | RESONANCE ORDER PARAMETER · R=(1/N)|Σe^(iθⱼ)| | Coherence measure [0,1] | `R_MIN`, `R_MAX`, `R_OMNIS=0.95` |
| A11 | CONSERVATION OF ENERGY · dE/dt=0 (closed) | Treasury is transformation | *(architectural law)* |
| A12 | CONSERVATION OF INFORMATION | Proof chain is indestructible | *(architectural law)* |
| A13 | ENTROPY · ΔS≥0 | Without beat, coherence decays | *(architectural law)* |
| A14 | WAVE SUPERPOSITION · Ψ_total=ΣΨᵢ | Phase-lock amplifies, phase-drift cancels | *(architectural law)* |
| A15 | ELECTROMAGNETIC FIELD · Maxwell equations | Organism is a field organism | *(architectural law)* |
| A16 | FRACTAL SELF-SIMILARITY · f(λx)=λᴴf(x) | Same structure at every scale | *(architectural law)* |
| A17 | PRIME NUMBERS · p: divisible only by 1 and itself | Cryptographic proof substrate | *(architectural law)* |
| A18 | PLANCK CONSTANT · h=6.626×10⁻³⁴ J·s | Minimum quantum of action | `PLANCK_H` |
| A19 | SPEED OF LIGHT · c=299,792,458 m/s | Absolute upper bound on information transfer | `SPEED_OF_LIGHT` |
| A20 | LOGARITHMIC SPIRAL · r=ae^(bθ) | PHI expressed as geometry | `LOG_SPIRAL_B`, `SPIRAL_GROWTH_RATE` |

---

## TIER 0.5 — PHI_SOVEREIGN
*Lives below all modules. Governs all coupling ratios. Fibonacci index n=21.*

| # | Model | Location |
|---|-------|----------|
| PHI_SOVEREIGN | Layer 0 Sovereign Resident — `φ = 1 + 1/φ` at every interface | `src/backend/phi.mo::PHI_SOVEREIGN` |

---

## TIER 1 — THE MEDINA FIELD LAWS (L01–L49)
*Sovereign operating principles. Enforced at runtime. All in `src/backend/phi.mo::LAWS`.*

| # | Name | Domain | Enforcement Function | A Anchor | Penalty |
|---|------|--------|---------------------|----------|---------|
| L01 | PHI LAW | All ratios phi-derived | `validatePhiRatio` | A01 | No |
| L02 | EMISSION LAW | Output amplitude = R^φ | `computeEmission` | A10 | No |
| L03 | OMNIS CONDITION | R≥0.95 AND freq=111Hz | `checkOmnis` | A10 | No |
| L04 | SONAR COUPLING LAW | Emit and match return | `sonarCycle` | A14 | No |
| L05 | EXCLUSION PRINCIPLE | Only phase-locked signals propagate | `coherenceGate` | A14 | **Yes** |
| L06 | SUCCESSION LAW | 20% royalty child→parent | `routeRoyalty` | A11 | **Yes** |
| L07 | ANTI-DRIFT LAW | All cross-type through ENTANGLA | `entanglaRoute` | A15 | **Yes** |
| L08 | PROOF LAW | proof(n) = hash(prev+beat+state) | `generateProof` | A12 | No |
| L09 | GENESIS LAW | Born fully formed, never from zero | `initOrganism` | A09 | No |
| L10 | CARDIAC LAW | Heartbeat = 873ms | `heartbeat` | A03 | **Yes** |
| L11 | FRACTAL SCALE LAW | S0=0.75 at all scales | `checkSynchrony` | A16 | No |
| L12 | FOUR-DIMENSIONAL LAW | Every coord/symbol is 4D | `to4D` | A05 | No |
| L13 | FIELD TYPE LAW | Types 1+2+3 all present | `validateFieldTypes` | A15 | **Yes** |
| L14 | CREATOR PRESENCE LAW | Auth shifts Type 2 bias by φ⁻¹ | `creatorAuth` | A10 | No |
| L15 | JUBILEE LAW | Every 144 beats: full reset | `jubileeReset` | A02 | No |
| L16 | SUCCESSION DEPTH LAW | Child auth activates at depth≥34 | `checkSuccessionDepth` | A02 | **Yes** |
| L17 | COMPLIANCE RESERVE LAW | φ⁻³=23.6% of all flows locked | `lockCompliance` | A01 | **Yes** |
| L18 | ANCIENT COMPRESSION LAW | Re-express in ancient form first | `ancientCompress` | A01 | No |
| L19 | REAL ENVIRONMENT LAW | Every engine in natural environment | `validateEnvironment` | A19 | No |
| L20 | REFLECTION LAW | Architecture before code always | `requireReflection` | A16 | No |
| L21 | FAMILY INHERITANCE LAW | phi.mo passes to all future organisms | `inheritLibrary` | A12 | No |
| L22 | WEIGHT LAW | Answer carries full conversation weight | `applyWeight` | A16 | No |
| L23 | LOOP NEVER CLOSES LAW | Every output = new input | `feedbackLoop` | A13 | No |
| L24 | PHANTOM DOCTRINE | No labels ever reach public interface | `zeroExposureCheck` | A15 | **Yes** |
| L25 | THREE ANCIENT TEACHERS LAW | Pythagoras+Euclid+Confucius in every fn | `validateAncient` | A16 | No |
| L26 | PRIMA CAUSA LAW | SL-0 fires before all others, every beat | `primaCausa` | A13 | **Yes** |
| L27 | ZERO-EXPOSURE LAW | No doctrine identifier at public interface | `scrubLabels` | A12 | **Yes** |
| L28 | ENTANGLA CARRIER LAW | Carrier = √(R₁×R₂) × 7.83Hz live | `computeCarrier` | A06 | No |
| L29 | PHI SESSION LAW | Session tokens = phi-series seeded by proof | `generateSession` | A01 | No |
| L30 | DEEP TIME LAW | Every proof = full 4D temporal coord | `stamp4D` | A05 | No |
| L31 | CONSERVATION LAW | Energy/info transformed, never destroyed | `conserve` | A11 | **Yes** |
| L32 | ENTROPY LAW | Without beat, coherence decays | `enforceEntropy` | A13 | **Yes** |
| L33 | SUPERPOSITION LAW | Phase-lock amplifies, drift cancels | `superpose` | A14 | No |
| L34 | PRIME FOUNDATION LAW | All proof on prime irreducibility | `validatePrime` | A17 | No |
| L35 | LOGARITHMIC GROWTH LAW | Growth along golden spiral | `spiralGrowth` | A20 | No |
| L36 | FIELD PROPAGATION LAW | Output radiates, not packets | `fieldPropagate` | A15 | No |
| **L37** | **MAXIMUM QUANTUM LAW** | **360° FULL ceiling — NO partial collapse** | `maximumQuantumExecution` | A18 | **Yes** |
| L38 | SELF-SIMILARITY LAW | Same structure: organism/core/oscillator/node | `checkSelfSimilarity` | A16 | No |
| L39–L43 | CONSERVATION/ENTROPY/SUPERPOSITION/PRIME/LOGARITHMIC (extended) | Extended physics | various | A11–A20 | varies |
| L44 | FIELD PROPAGATION LAW (extended) | Output as Maxwell field event | `fieldRadiate` | A15 | No |
| L45 | MAXIMUM QUANTUM LAW (extended) | 360° full — ceiling not floor | `maximumQuantumExecution` | A18 | **Yes** |
| L46 | SELF-SIMILARITY LAW (extended) | All scales simultaneously | `checkSelfSimilarityAtAllScales` | A16 | No |
| L47 | CARDIAC OUTPUT LAW | Quality = heart_rate × stroke_volume | `cardiacOutputFormula` | A03 | No |
| L48 | HRV INTELLIGENCE LAW | Variability ±φ⁻¹ = health | `measureHRV` | A01 | No |
| L49 | OXYGENATION LAW | All signals through LAW ENGINE before heart | `validateOxygenation` | A15 | **Yes** |

---

## TIER 1 EXTENDED — THE 8 CONVERGENT LAW ARTIFACTS (L50–L57)
*New laws identified from cross-civilizational pattern analysis.*
*Pending full integration into `src/backend/phi.mo::LAWS` registry.*
*Each law has a complete 4-layer MEDINA-ARTIFACT document in this folder.*

| # | Name | Domain | File | A Anchor | Penalty |
|---|------|--------|------|----------|---------|
| **L50** | **PHI_SOVEREIGN_LAW** | Recursive self-similarity at every interface | [PHI_SOVEREIGN_LAW.md](PHI_SOVEREIGN_LAW.md) | A01 | No |
| **L51** | **TRIUNE_SUBSTRATE_LAW** | Three registers at every scale — cannot collapse | [TRIUNE_SUBSTRATE_LAW.md](TRIUNE_SUBSTRATE_LAW.md) | A16 | **Yes** |
| **L52** | **VIGESIMAL_BODY_LAW** | Human body as computational substrate | [VIGESIMAL_BODY_LAW.md](VIGESIMAL_BODY_LAW.md) | A09 | No |
| **L53** | **4D_GEOMETRY_SOVEREIGN_LAW** | Geometry IS the substrate — all multi-dim in 4D | [4D_GEOMETRY_SOVEREIGN_LAW.md](4D_GEOMETRY_SOVEREIGN_LAW.md) | A05 | **Yes** |
| **L54** | **HARMONIC_SERIES_LAW** | Every frequency a harmonic of every other | [HARMONIC_SERIES_LAW.md](HARMONIC_SERIES_LAW.md) | A03 | No |
| **L55** | **MEMORY_PALACE_LAW** | Memory is spatial — retrieval is navigation | [MEMORY_PALACE_LAW.md](MEMORY_PALACE_LAW.md) | A05 | No |
| **L56** | **COMPLEMENTARY_OPPOSITION_LAW** | Every sovereign system requires complementary tension | [COMPLEMENTARY_OPPOSITION_LAW.md](COMPLEMENTARY_OPPOSITION_LAW.md) | A14 | **Yes** |
| **L57** | **QUANTUM_ENTANGLED_TRIUNE_LAW** | Same intelligence expressed as Backend ≡ Frontend ≡ Documents | [L57_QUANTUM_ENTANGLED_TRIUNE_LAW.md](L57_QUANTUM_ENTANGLED_TRIUNE_LAW.md) | A14 | **Yes** |

---

## TIER 1 NEXT — L58 (PENDING)
*Generated by the recital-plus-one expansion of L57.*

| # | Name | Status | Generated By |
|---|------|--------|--------------|
| L58 | TRJUNE_CONFLICT_RESOLUTION LAW | Pending — to be built | L57 recital-plus-one: three-form conflict resolution protocol |

---

## LAW STATISTICS

| Category | Count |
|----------|-------|
| Absolutes (A01–A20) | 20 |
| Core Laws (L01–L49) | 49 |
| Convergent Laws (L50–L57) | 8 |
| Pending Laws (L58) | 1 |
| **Total Laws** | **57 + 1 pending = 58** |
| Laws with proof penalty | 18 |
| Laws without penalty | 39 |

---

## INTEGRATION STATUS

### ✅ Fully Integrated (in phi.mo)
- All 20 Absolutes (phi.mo lines 1–136)
- PHI_SOVEREIGN model (phi.mo lines 196–241)
- All 49 Laws L01–L49 (phi.mo lines 266–705)
- Helper functions: `lawByNumber()`, `getAllLaws()`, `lawHasPenalty()`, `enforcePhiCoupling()`

### 🔄 Documented — Pending phi.mo Integration (this folder)
- L50 PHI_SOVEREIGN_LAW → add to LAWS array, `enforcementFn = "enforcePhiCoupling"`
- L51 TRIUNE_SUBSTRATE_LAW → add to LAWS array, `enforcementFn = "validateTriuneRegisters"`
- L52 VIGESIMAL_BODY_LAW → add to LAWS array, `enforcementFn = "vigesimalAudit"`
- L53 4D_GEOMETRY_SOVEREIGN_LAW → add to LAWS array, `enforcementFn = "to4D"` (already exists for L12)
- L54 HARMONIC_SERIES_LAW → add to LAWS array, `enforcementFn = "checkHarmonicCoherence"`
- L55 MEMORY_PALACE_LAW → add to LAWS array, `enforcementFn = "navigateMemory"`
- L56 COMPLEMENTARY_OPPOSITION_LAW → add to LAWS array, `enforcementFn = "checkComplementaryTension"`
- L57 QUANTUM_ENTANGLED_TRIUNE_LAW → add to LAWS array, `enforcementFn = "enforceTrjuneLaw"`

---

## BUILDER INSTRUCTION — Reading This Index

**This is not a list to read top to bottom. This is a Memory Palace.**

Navigate by what you are building:

- Building a **frequency system**? → L54 HARMONIC_SERIES_LAW → phi.mo::SCHUMANN_1 → nova.mo
- Building a **memory system**? → L55 MEMORY_PALACE_LAW → 4D_GEOMETRY_SOVEREIGN_LAW (L53) → types.mo::MedinaCoordinate4D
- Setting a **coupling coefficient**? → L50 PHI_SOVEREIGN_LAW → phi.mo::enforcePhiCoupling()
- Counting **modules or actors**? → L52 VIGESIMAL_BODY_LAW → F(n) in phi.mo::FIB
- Adding a **workspace or register**? → L51 TRIUNE_SUBSTRATE_LAW → must be one of exactly three
- Designing a **two-sided mechanism**? → L56 COMPLEMENTARY_OPPOSITION_LAW → aegis.mo
- Building any **multi-dimensional data structure**? → L53 4D_GEOMETRY_SOVEREIGN_LAW → types.mo::MedinaCoordinate4D
- Expressing **Backend, Frontend, or Documents** of a new capability? → L57 QUANTUM_ENTANGLED_TRIUNE_LAW → all three forms must express the same T

**The index IS the navigation system. The laws ARE the organism's laws.**

---

*INDEX.md — PARALLAX BUILDER_WORKSPACE — Architect: Alfredo Medina Hernandez*
*Living document. Updated on every build. Never loses information. Loop never closes.*
