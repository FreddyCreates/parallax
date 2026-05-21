# PARALLAX — Orphaned Code Registry

**Date:** 2026-04-06  
**Auditor:** Caffeine AI  
**Purpose:** Pattern 5 Prescription — Document all directories that exist but are NOT registered in `icp.yaml` and NOT deployed. Do not delete. Do not merge until the monolith is stable and earning.

---

## LIVE (Deployed via icp.yaml)

| Directory | Role | Status |
|---|---|---|
| `src/backend/` | Sovereign monolith — all cognitive, economic, defense, and governance logic | **LIVE** |
| `src/frontend/` | React + TypeScript enterprise UI | **LIVE** |

---

## ORPHANED (Not in icp.yaml — Not Deployed)

### `src/veritas/` — DOCTRINE VAULT (680 lines)
- **What it is:** Full sovereign doctrine actor. Stores all 60 laws as stable vars with full text, tier, compliance score. SHA-256 doctrine fingerprinting. Zero public exposure (law text never returned to public callers). Creator-only write access.
- **Why it exists:** Originally designed as a separate canister for the multi-canister federation phase. All 60 laws are currently inlined into `src/backend/laws.mo` instead.
- **Merge plan:** When Phase C (Sovereign Frontier) begins, evaluate whether VERITAS becomes a cross-canister truth oracle or stays merged. Do not delete. Has `canister.yaml`.
- **Status:** STAGED-FOR-FUTURE-MERGE

### `src/brain/` — COGNITIVE CANISTER (2,695 lines across 7 files)
- **What it is:** Full cognitive substrate actor with 6 local modules (shells, organs, metals, neuro_chem, quantum_ops, animals). Designed as the standalone BRAIN canister for multi-canister federation. Has more advanced math than the current monolith versions of these modules.
- **Why it exists:** Built as the future BRAIN canister. The monolith `src/backend/` imported these same module types locally and wired them in.
- **Merge plan:** When multi-canister federation begins, `src/brain/main.mo` becomes the BRAIN canister. The 6 modules may contain newer math than what is live — audit before merge to capture any improvements.
- **Status:** STAGED-FOR-FUTURE-MERGE (highest priority — contains advanced module math)

### `src/qmem/` — QUANTUM MEMORY (257 lines)
- **What it is:** 2048-episode ring buffer actor. 41-dimensional episode vectors: [coherence, shell activations, drive Q-values, token balances, market prices, quantum ops]. Long-term memory store (256 slots). Creator-only seal and wiring functions.
- **Why it exists:** QMEM was designed as a separate memory canister. A partial QMEM implementation is live in the monolith as `px_qmemRing` (128-episode, 4-dimensional only). The standalone actor is more complete.
- **Merge plan:** Phase A — Deep Mind. Merge the 41-dimensional ring into the monolith or activate as a cross-canister memory oracle.
- **Status:** STAGED-FOR-PHASE-A

### `src/axis/` — EAGLE + ELEPHANT ENGINES (242 lines)
- **What it is:** AXIS actor with Eagle (multi-scale EMA-21/55/200/500 over coherence, with acceleration and curvature) and Elephant (deep memory integration, pattern recall) engines. Wires to QMEM canister for deep storage.
- **Why it exists:** Designed as the AXIS temporal intelligence canister. Eagle and Elephant are partially live in the monolith as `px_animalEagle` and `px_animalElephant` (simplified versions).
- **Merge plan:** Phase A — Deep Mind. The full Eagle curvature + Elephant recall is richer than the monolith's current animal engine. Merge the math, not the actor.
- **Status:** STAGED-FOR-PHASE-A

### `src/chrono/` — GENESIS ANCHOR (620 lines)
- **What it is:** CHRONO temporal sovereignty canister. Genesis formation hash, pre-formation hash, purpose hash, beat-at-formation. Designed as the immutable temporal anchor for all canisters in the federation.
- **Why it exists:** Built for multi-canister federation. Genesis anchoring is partially live in the monolith via `chronoFormationHash`, `chronoTimestamp`, `chronoGenesisLocked` stable vars.
- **Merge plan:** Phase C — Sovereign Frontier. CHRONO becomes the federation's temporal root once canisters split.
- **Status:** STAGED-FOR-PHASE-C

### `src/resonex/` — RESONANCE FIELD (594 lines)
- **What it is:** RESONEX coherence resonance canister. Manages cross-canister resonance field, phase coupling, and ECAN FORMA flow distribution.
- **Why it exists:** Designed as the resonance bus for the multi-canister federation. `px_resonexField` in the monolith is a single Float; the full actor is a complete resonance substrate.
- **Merge plan:** Phase B — Sovereign Economy. ECAN FORMA flow logic from this actor should be reviewed and merged into the monolith's FORMA engine.
- **Status:** STAGED-FOR-PHASE-B

### `src/flux/` — FLUX ENGINE (363 lines)
- **What it is:** FLUX state transition canister. Manages quantum state flux, bypass gate, and state transition math.
- **Why it exists:** Designed as the FLUX transition canister for the federation. Bypass gate is live in monolith as `px_bypassGate`.
- **Merge plan:** Evaluate during Phase B. May merge bypass math into quantum_ops.mo.
- **Status:** STAGED-FOR-PHASE-B

---

## MERGE PRIORITY ORDER

1. **Phase A:** `src/qmem/` math → monolith QMEM (41-dim ring), `src/axis/` Eagle curvature + Elephant recall → monolith
2. **Phase B:** `src/resonex/` ECAN FORMA flow math → monolith FORMA engine, `src/flux/` bypass math review
3. **Phase C:** `src/chrono/` → federation temporal root, `src/veritas/` → federation doctrine oracle
4. **Federation:** `src/brain/` → standalone BRAIN canister when monolith splits

---

## RULE

No directory in this registry is to be deleted. No directory is to be registered in `icp.yaml` until the monolith is fully stable and earning. All merge operations must be audited beat-by-beat before deployment.
