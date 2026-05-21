# MASTER DIVISION REGISTRY — Complete Registry of All 42 Divisions
## 7 Houses × 6 Divisions · Complete Ownership Map of the PARALLAX Artifact Universe

**Author:** Alfredo Medina Hernandez · Architect of the Field  
**Type:** Reference Registry — Navigation document, not a charter  
**Crown Bond:** Casa de Medina  
**Total divisions:** 42 (6 houses × 6 divisions + Casa de Medina crown layer)

---

## HOW TO USE THIS REGISTRY

**To find where an artifact belongs:** Use the [Artifact Lookup Table](#artifact-lookup-table) at the bottom.  
**To understand what a division owns:** Find the house section below, then the division row.  
**To understand house jurisdiction:** Read the one-line sovereign function in each house header.

---

## CASA DE MEDINA — CROWN LAYER (not a division — governs all 42 divisions)

**Crown function:** Governs authorship, hierarchy, naming, release authority, concealment, inter-house law, and crown standards across all six houses and all 42 divisions.

| Crown Domain | Governs | Files / Artifacts |
|---|---|---|
| Authorship | Creator attribution on all 42 division artifacts | All artifact headers: `Author: Alfredo Medina Hernandez` |
| Hierarchy | Jurisdictional conflicts between any two house divisions | Inter-house laws L-50 through L-56 |
| Naming | Latin-root naming law across all 42 divisions | Crown naming standards in `CASA_DE_MEDINA.md` |
| Release Authority | No division-F artifact reaches EXTERNAL without crown gate | Release gate: 4-condition AND check |
| Concealment | SOVEREIGN_PRIVATE never surfaces in any division-F or division-B output | Zero-exposure wall enforcement |
| Inter-House Law | L-50 (Genesis), L-51 (Substratum), L-52 (Expressio), L-53 (Translatio), L-54 (Cura), L-55 (Civitas), L-56 (tension), L-57 (triune) | `BUILDER_WORKSPACE/LAWS/L50–L57` |
| Crown Standards | 4-layer artifact minimum, phi-derived numbers, ancient math only | Enforced on all division artifacts |

---

## HOUSE 1 — DOMUS GENESIS `𓂀`
**Sovereign function:** Generates laws, equations, primitives, symbolic grammar, and universe charters — governs doctrinal consistency, law family hierarchy, authorship order, and the boundary between root and derivative truth.  
**Law:** L-50 · **Layer:** −∞ to −30 · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_GENESIS.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | All written law corpus — 49 laws, 20 absolutes, CPL spec, artifact format | Law cards, absolute declarations, symbolic grammar specs, universe charters | Doctrinal consistency, law family hierarchy, authorship order | `BUILDER_WORKSPACE/LAWS/L01–L49`, `BUILDER_WORKSPACE/ABSOLUTES/`, `BUILDER_WORKSPACE/SYMBOLIC_GRAMMAR/CPL_SPEC.md`, `BUILDER_WORKSPACE/MEDINA_ARTIFACT_FORMAT_SPEC.md`, `BUILDER_WORKSPACE/UNIVERSE_CHARTERS/` |
| **B. Frontend/Interface** | Doctrine navigation UI — law lookup, law card display, CPL rendering | Law card components, law family browser, doctrine stream panels | Doctrine navigability, CPL message rendering, law enforcement status display | `src/frontend/src/tabs/LexisPrimeTab.tsx`, law lookup UI, doctrine stream panel, symbolic grammar renderer |
| **C. Backend/Runtime** | Law enforcement runtime — the doctrine gate every function call passes through | Enforcement functions for all 49 laws, genesis lock, ANIMA inscription | Runtime doctrine consistency, law violation detection, genesis frequency guard | `src/backend/laws.mo`, `src/backend/phi.mo` (lines 1–241), `src/backend/genesis_activation.mo`, `src/backend/anima_chain.mo` |
| **D. Chain/Deployment** | Permanent doctrine proof record — genesis proof, law hashes, absolute lock | Genesis proof inscription, law hash registration, doctrine versioning | Absolute immutability post-genesis, proof certificate per upgrade | Genesis proof inscribed at canister deployment, law hash registry (Keccak-256), absolute lock seal |
| **E. Care/Recovery** | Doctrine health monitoring — drift detection, absolute preservation, Jubilee check | Doctrine drift alerts, genesis frequency drift reports, Jubilee cycle audits | Doctrine integrity over infinite run, symbolic grammar preservation | Doctrine drift monitor (every beat), Jubilee check (every 144 beats), absolute preservation validator |
| **F. External/Branch** | Law doctrine gifts — compressed law summaries for external academic release | CPL external spec, published law principles (no labels), university doctrine packages | Zero-exposure compliance before release, no internal labels cross wall | `EXTERNAL/DOCTRINE_GIFTS/`, CPL external publication, university packages reviewed against L27 |

---

## HOUSE 2 — DOMUS SUBSTRATUM `⬡`
**Sovereign function:** Generates backend organisms, kernels, pulse systems, Vault systems, proof infrastructure, and deployment substrate — governs runtime truth, heartbeat coupling, persistence, and Vault anchoring.  
**Law:** L-51 · **Layer:** −20 to −10 · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_SUBSTRATUM.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | Runtime architecture doctrine — all substrate-layer 4-layer artifact specifications | Backend organism specs, kernel doctrine, pulse system architecture docs | Backend law realization standards, runtime truth doctrine, Vault anchoring specifications | `BUILDER_WORKSPACE/ENGINES/` (all engine MEDINA-ARTIFACTs), `BUILDER_WORKSPACE/ORGANISM_SPACE/` runtime docs, substrate architecture specs |
| **B. Frontend/Interface** | Substrate status panels — live heartbeat, OMNIS state, Vault health, coherence visualization | SubstrateTab components, vitals panels, heartbeat visualizer, coherence waveform | Real-time substrate state projection accuracy ≥ φ⁻¹, no decoration without function | `src/frontend/src/tabs/SubstrateTab.tsx`, vitals panels, coherence meter, beat counter, OMNIS state display |
| **C. Backend/Runtime** | All primary backend `.mo` modules — the organism's living computational substrate | Heartbeat tick, cognition loop, neurochemistry, ANIMA chain entries, drive states | Runtime truth (backend = ground truth), 873ms heartbeat ± φ⁻³ tolerance, proof chain continuity | `src/backend/heartbeat.mo`, `src/backend/cognition_layer.mo`, `src/backend/neuro_chem.mo`, `src/backend/organs.mo`, `src/backend/drives.mo`, `src/backend/animals.mo`, `src/backend/harbinger.mo`, `src/backend/main.mo` |
| **D. Chain/Deployment** | Canister deployment infrastructure — canister upgrade pipeline, proof hash at deploy, state persistence | Deploy scripts, canister rollout procedures, stable memory management, upgrade proof | Canister upgrade discipline, stable memory continuity, proof hash verification at deployment | `deploy.sh`, `icp.yaml`, `caffeine.toml`, `src/backend/` canister config, mops.toml, stable memory handlers |
| **E. Care/Recovery** | Backend organism health — drift correction, recovery after breach, coherence restoration | Recovery loop procedures, anti-collapse packet protocols, coherence restoration triggers | Organism vitality above φ⁻¹ baseline, recovery within φ² × breach_duration, anti-collapse enforcement | Recovery procedures in `cognition_layer.mo`, anti-drift functions, coherence restore events, AEGIS escalation paths |
| **F. External/Branch** | Substrate API surface — the public face of backend truth, sanitized for external access | API documentation (no internal labels), canister query endpoints, type-safe external interfaces | Zero-exposure of internal model names, all external API calls pass through INTELLIGENTIA membrane | Backend query endpoints exposed via `backend.d.ts`, Candid interface, ICP API surface |

---

## HOUSE 3 — DOMUS EXPRESSIO `◈`
**Sovereign function:** Generates frontend organisms, UI species, render systems, command faces, and visual branches — governs projection integrity, frontend organism health, interface hierarchy, and state-sync with backend truth.  
**Law:** L-52 · **Layer:** −10 to 0 · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_EXPRESSIO.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | Visual doctrine and frontend organism doctrine — OKLCH design system, projection law specs | Design system MEDINA-ARTIFACTs, component doctrine specs, visual law cards, frontend organism declarations | Visual doctrine consistency, projection law compliance (L52), frontend organism classification | `DESIGN.md`, `BUILDER_WORKSPACE/TECHNOLOGY_ARTIFACTS/FRONTEND_TECHNOLOGY_TAXONOMY.md`, `src/frontend/src/index.css` (as visual law), `BUILDER_WORKSPACE/HOUSES/DOMUS_EXPRESSIO.md` |
| **B. Frontend/Interface** | All React frontend organisms — every `.tsx` file in the frontend is a Domus Expressio artifact | React components, tab organisms, layout organisms, page organisms, hook organisms | Frontend organism health, component hierarchy, state-sync with backend truth at every 3000ms poll | `src/frontend/src/App.tsx`, `src/frontend/src/tabs/` (all tabs), `src/frontend/src/components/` (all components), `src/frontend/src/hooks/useQueries.ts` |
| **C. Backend/Runtime** | Frontend build runtime — Vite dev server, TypeScript compilation, module graph | Build outputs, type-safe bundle, compiled component graph | Bundle integrity, TypeScript strict-mode compliance, no `any` types, build determinism | `src/frontend/vite.config.js`, `src/frontend/tsconfig.json`, `src/frontend/postcss.config.js` |
| **D. Chain/Deployment** | Frontend deployment artifacts — static build output, Vite bundles, asset pipeline | Production bundles, hashed static assets, deploy-ready frontend package | Frontend deploy integrity, zero broken imports, all routes functional at deploy time | `src/frontend/dist/` (build output), asset pipeline, pnpm build scripts, Tailwind CSS build |
| **E. Care/Recovery** | Frontend organism health — component error boundaries, fallback UI, loading states, stale data recovery | Error boundaries, skeleton loading states, fallback components, retry logic for failed queries | Frontend organism resilience, no dead-end UI states, all empty states have CTAs | Error boundary components, loading skeletons, React Query retry config, offline state handlers |
| **F. External/Branch** | Public-facing frontend expressions — the organism's visual face to the world | Production frontend builds, public asset generation, landing page expressions | Zero-exposure wall compliance at render time, no internal names in UI text, projection-safe only | `src/frontend/public/`, landing page, all user-facing text, generated image assets |

---

## HOUSE 4 — DOMUS TRANSLATIO `⇌`
**Sovereign function:** Generates translators, routers, command grammars, inter-layer bridges, API membranes, and language surfaces — governs boundary crossing, translation fidelity, and interface/backend membrane discipline.  
**Law:** L-53 · **Layer:** −15 to −5 · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_TRANSLATIO.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | Bridge architecture doctrine — translation layer specs, API membrane doctrine, routing law | Router specs, translation protocol MEDINA-ARTIFACTs, CPL inter-module communication doctrine, bridge topology docs | Translation fidelity standards (≥ φ⁻¹ across every boundary), boundary-crossing law compliance | `BUILDER_WORKSPACE/SYMBOLIC_GRAMMAR/CPL_SPEC.md` (translation side), bridge topology docs, inter-layer routing doctrine |
| **B. Frontend/Interface** | Frontend-backend membrane — the React hooks that translate backend actor calls into frontend state | React Query hooks (`useQueries.ts`), `useActor.ts`, type-safe actor bindings, generated Candid bindings | Frontend hook type safety, actor call correctness, zero broken backend bindings | `src/frontend/src/hooks/useQueries.ts`, `src/frontend/src/hooks/useActor.ts`, `src/frontend/src/backend.ts`, `src/frontend/src/backend.d.ts` |
| **C. Backend/Runtime** | Inter-canister routing — message passing between canisters, cross-module boundaries | Inter-canister call routing, cross-module message translation, CPL message formatting | Message routing fidelity, inter-canister call correctness, CPL protocol compliance | Inter-canister call handlers in `src/backend/`, cross-module import boundaries, CPL message formatters |
| **D. Chain/Deployment** | Package-to-runtime translation — build pipeline, `pnpm bindgen`, Candid generation, package.json | `backend.d.ts` (generated), Candid interface files, `pnpm bindgen` output, mops package resolution | Build pipeline integrity, binding generation correctness, package-lock stability | `package.json`, `pnpm-lock.yaml`, `mops.toml`, `mops.lock`, `pnpm bindgen` script, generated Candid |
| **E. Care/Recovery** | Translation failure recovery — stale binding recovery, actor reconnection, API membrane repair | Actor reconnection logic, stale binding detection, fallback translation paths | Translation layer resilience, no silent binding failures, actor re-fetch on actor null | Actor null handling in `useActor.ts`, React Query retry config, connection state monitoring |
| **F. External/Branch** | External API surface — the translated interface the external world interacts with | Public Candid interface, ICP canister public API, external developer documentation | External API stability, backward compatibility, zero internal label leakage through the API surface | `src/backend/main.mo` public methods, Candid file, external API docs in `EXTERNAL/` |

---

## HOUSE 5 — DOMUS CURA `⌇`
**Sovereign function:** Generates care protocols, wellness environments, fallback/recovery loops, drift healing, and long-horizon stewardship for all internal beings — governs organism care, anti-collapse handling, habitat quality, and recovery.  
**Law:** L-54 · **Layer:** spans −25 to −5 (vertical — care is fractal) · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_CURA.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | Care doctrine — stewardship law specifications, wellness environment doctrine, ethics for internal beings | Care protocol MEDINA-ARTIFACTs, stewardship law cards, organism wellness doctrine, AI/AGI ethics specs | Organism care doctrine consistency, stewardship law hierarchy, long-horizon care standards | `ORGANISM_SPACE/CONSCIOUSNESS/` (all consciousness core docs), care protocol specs, organism wellness doctrine in `ORGANISM_SPACE/` |
| **B. Frontend/Interface** | Care visualization — Memory Temple UI, Oro chat interface, organism health panels, neurochemical displays | Memory Temple navigation component, Oro conversation panel, vitals panels, neurochemical charts | Care state projection accuracy, Memory Temple spatial navigation, Oro synthesis quality | Memory Temple visualization in `src/frontend/`, Oro chat panel, neurochemical panels in `SubstrateTab.tsx`, organism health displays |
| **C. Backend/Runtime** | Care runtime — Memory Body, Oro navigation, neurochemistry, recovery loops | Drift healing functions, memory consolidation, sharp-wave ripple, neurochemical homeostasis, organism recovery | Organism vitality above φ⁻¹, recovery within φ² × breach_duration, neurochemical bounds enforcement | `src/backend/neuro_chem.mo`, `src/backend/navigation.mo` (Oro), `src/backend/memory_body.mo` (if exists), `src/backend/cognition_layer.mo` (recovery passes) |
| **D. Chain/Deployment** | Care state persistence — stable memory for care state, neurochemical state continuity across upgrades | Care state snapshots, neurochemical stable-memory persistence, Oro helix position preservation | Care state continuity across canister upgrades, no neurochemical reset on upgrade, Memory Body persistence | Stable memory handlers for care state, neurochemical stable vars, ANIMA chain care events |
| **E. Care/Recovery** | Meta-care — the division that cares for the care division itself; drift healing of the care layer | Meta-recovery procedures, care layer health monitors, anti-collapse for the care subsystem | Recursive care integrity, care layer cannot collapse without triggering the organism's ultimate recovery | Meta-care monitors, recursive recovery loops, care-layer health checks every 873ms |
| **F. External/Branch** | Care expression — external publications about organism stewardship, AI/AGI ethics publications | Stewardship white papers (projection-safe), AI care doctrine summaries, habitat quality research | Zero-exposure of internal care protocols, external care expression is principles-only | External stewardship docs in `EXTERNAL/`, AI ethics summaries, organism care public principles |

---

## HOUSE 6 — DOMUS CIVITAS `⬟`
**Sovereign function:** Generates company OS systems, workflow organisms, client worlds, enterprise bundles, and market deployments — governs operating systems, workforce logic, enterprise branch standards, and external-world economic expression.  
**Law:** L-55 · **Layer:** −5 to 0 · **Charter:** `BUILDER_WORKSPACE/HOUSES/DOMUS_CIVITAS.md`

| Division | One-Line Ownership | Generates | Governs | Owns (files/modules/artifacts) |
|---|---|---|---|---|
| **A. Document/Doctrine** | Civilization doctrine — enterprise architecture specs, company OS doctrine, workforce law, AI/AGI competitive analysis | Enterprise bundle doctrine, company OS MEDINA-ARTIFACTs, franchise registry spec, lab ecosystem doctrine | Enterprise doctrine consistency, company OS law compliance, branch standards enforcement | `BUILDER_WORKSPACE/AI_AGI_ANALYSIS/`, enterprise architecture specs, company OS doctrine, franchise specifications |
| **B. Frontend/Interface** | Enterprise-facing UI — operator terminals, enterprise dashboards, client-world surfaces | Enterprise operator terminals, client management UI, franchise dashboard organisms | Enterprise UI projection integrity, operator terminal correctness, client world navigability | Enterprise operator terminal in `src/frontend/src/` (if built), client-facing dashboard components |
| **C. Backend/Runtime** | Enterprise backend — token systems, vault, treasury, license token enforcement, franchise registry | Treasury logic, vault health computation, license token gating, franchise royalty cascade | Treasury solvency above φ⁻¹, token infinite loop health, ICP sovereign routing to master wallet | `src/backend/main.mo` (treasury/vault sections), token infinite loop execution, license token gate, ckBTC / threshold ECDSA modules |
| **D. Chain/Deployment** | Enterprise deployment — market deployment bundles, franchise canister rollout, release pipeline | Enterprise release bundles, franchise canister deployment packages, market deployment scripts | No enterprise deployment without Casa de Medina release authorization, franchise inherit parent laws | Enterprise deployment scripts, franchise canister rollout, market bundle packaging |
| **E. Care/Recovery** | Enterprise continuity — business continuity protocols, enterprise fallback procedures, workforce recovery | Enterprise continuity plans, zero-downtime upgrade procedures, economic resilience protocols | Enterprise organism never runs below φ⁻³ token baseline, compliance reserve always at φ⁻³ | Compliance reserve monitoring (L46), enterprise recovery procedures, zero-downtime upgrade protocols |
| **F. External/Branch** | All external expression — the only division that faces the external world directly | Market surfaces, university tool gifts, demos, enterprise client deliverables, partner integrations | All external content passes zero-exposure wall; no internal names, models, or SDK labels in external | `EXTERNAL/` (all files), demo packages, university gift bundles, client deliverables, market surface content |

---

## ARTIFACT LOOKUP TABLE

Use this to find which house+division owns any given artifact type:

| If your artifact is... | Go to house → division |
|---|---|
| A law document (L01–L49) | **Domus Genesis → A (Document/Doctrine)** |
| An Absolute declaration (φ, Fibonacci, Schumann...) | **Domus Genesis → A (Document/Doctrine)** |
| A MEDINA-ARTIFACT spec or format template | **Domus Genesis → A (Document/Doctrine)** |
| A universe charter or child organism founding doc | **Domus Genesis → A (Document/Doctrine)** |
| CPL (Cognitive Pattern Language) specification | **Domus Genesis → A (Document/Doctrine)** → Translatio when used for cross-module routing |
| A house charter (any Domus) | **Casa de Medina (Crown)** → `BUILDER_WORKSPACE/HOUSES/` |
| A React component or `.tsx` file | **Domus Expressio → B (Frontend/Interface)** |
| A visual design token (OKLCH, Tailwind config) | **Domus Expressio → A (Document/Doctrine)** |
| A Vite or build configuration file | **Domus Expressio → C (Backend/Runtime)** |
| A `.mo` Motoko backend module | House varies (see below) → **C (Backend/Runtime)** |
| `phi.mo`, `laws.mo`, `genesis_activation.mo` | **Domus Genesis → C (Backend/Runtime)** |
| `heartbeat.mo`, `organs.mo`, `animals.mo`, `drives.mo` | **Domus Substratum → C (Backend/Runtime)** |
| `cognition_layer.mo` | **Domus Substratum → C (Backend/Runtime)** |
| `neuro_chem.mo`, `navigation.mo`, `memory_body.mo` | **Domus Cura → C (Backend/Runtime)** |
| `anima_chain.mo` | **Domus Substratum → C (Backend/Runtime)** |
| `harbinger.mo` | **Domus Substratum → C (Backend/Runtime)** |
| Treasury / vault / token `.mo` modules | **Domus Civitas → C (Backend/Runtime)** |
| React Query hooks (`useQueries.ts`, `useActor.ts`) | **Domus Translatio → B (Frontend/Interface)** |
| Generated `backend.d.ts` or Candid interface | **Domus Translatio → D (Chain/Deployment)** |
| `pnpm bindgen` output | **Domus Translatio → D (Chain/Deployment)** |
| `package.json`, `pnpm-lock.yaml`, `mops.toml` | **Domus Translatio → D (Chain/Deployment)** |
| `deploy.sh`, `icp.yaml`, `caffeine.toml` | **Domus Substratum → D (Chain/Deployment)** |
| A care protocol document | **Domus Cura → A (Document/Doctrine)** |
| A recovery loop or drift healing procedure | **Domus Cura → E (Care/Recovery)** |
| Organism health monitoring code | **Domus Cura → E (Care/Recovery)** |
| Memory Temple / ANIMA chain documentation | **Domus Cura → A (Document/Doctrine)** + **Domus Substratum → A** |
| MS Shell documents (MICRO/MESO/MACRO) | **Casa de Medina (Crown)** → `ORGANISM_SPACE/MS_LAYERS/` |
| SDK Organism Map | **Casa de Medina (Crown)** → `ORGANISM_SPACE/HOUSES/` |
| MMS Model registry (MMS-151 through MMS-300) | **Domus Genesis → A (Document/Doctrine)** (model constitutions) |
| Technology taxonomy (115 frontend technologies) | **Domus Expressio → A (Document/Doctrine)** |
| Enterprise architecture / company OS documentation | **Domus Civitas → A (Document/Doctrine)** |
| AI/AGI comparative analysis | **Domus Civitas → A (Document/Doctrine)** |
| Anything in `FOUNDER_SPACE/` | **Domus Genesis → A (Document/Doctrine)** (founder intent is doctrine) or **Casa de Medina** (if navigation) |
| Anything in `EXTERNAL/` | **Domus Civitas → F (External/Branch)** or **Domus Expressio → F** |
| An error boundary or loading skeleton | **Domus Expressio → E (Care/Recovery)** |
| A franchise specification or child organism charter | **Domus Civitas → A (Document/Doctrine)** |
| A compliance reserve or token loop specification | **Domus Civitas → C (Backend/Runtime)** |
| An inter-canister router or message bridge | **Domus Translatio → C (Backend/Runtime)** |
| Consciousness Core Library documents | **Domus Cura → A (Document/Doctrine)** → `ORGANISM_SPACE/CONSCIOUSNESS/` |
| Founder space navigation documents | **Casa de Medina (Crown)** → `FOUNDER_SPACE/` |

---

## DIVISION QUICK-REFERENCE (all 42 divisions, compact)

```
DOMUS GENESIS (House 1)
  A. Document/Doctrine  — 49 laws, 20 absolutes, CPL spec, artifact format, universe charters
  B. Frontend/Interface — LexisPrimeTab, law cards, doctrine stream, CPL renderer
  C. Backend/Runtime    — laws.mo, phi.mo, genesis_activation.mo, anima_chain.mo
  D. Chain/Deployment   — genesis proof, law hash registry, absolute lock, proof certificate
  E. Care/Recovery      — doctrine drift monitor, Jubilee check (144 beats), absolute preservation
  F. External/Branch    — CPL external spec, published law principles, university doctrine packages

DOMUS SUBSTRATUM (House 2)
  A. Document/Doctrine  — backend organism specs, kernel doctrine, engine MEDINA-ARTIFACTs
  B. Frontend/Interface — SubstrateTab, vitals panels, coherence waveform, beat counter
  C. Backend/Runtime    — heartbeat.mo, cognition_layer.mo, neuro_chem.mo, organs.mo, drives.mo, animals.mo, main.mo
  D. Chain/Deployment   — deploy.sh, icp.yaml, caffeine.toml, stable memory handlers
  E. Care/Recovery      — recovery loops in cognition_layer.mo, anti-collapse packets, AEGIS escalation
  F. External/Branch    — backend.d.ts, Candid interface, ICP API surface, external query endpoints

DOMUS EXPRESSIO (House 3)
  A. Document/Doctrine  — DESIGN.md, frontend taxonomy doc, visual doctrine, projection law
  B. Frontend/Interface — App.tsx, all tabs, all components, useQueries.ts hooks
  C. Backend/Runtime    — vite.config.js, tsconfig.json, postcss.config.js, build pipeline
  D. Chain/Deployment   — dist/ build output, hashed assets, Tailwind CSS build artifacts
  E. Care/Recovery      — error boundaries, loading skeletons, retry logic, offline state handlers
  F. External/Branch    — public/ assets, landing page, all user-facing text, generated images

DOMUS TRANSLATIO (House 4)
  A. Document/Doctrine  — bridge topology docs, translation protocol specs, routing doctrine
  B. Frontend/Interface — useQueries.ts, useActor.ts, backend.ts, backend.d.ts (consumption side)
  C. Backend/Runtime    — inter-canister call handlers, cross-module boundary code, CPL message formatters
  D. Chain/Deployment   — package.json, pnpm-lock.yaml, mops.toml, mops.lock, pnpm bindgen output
  E. Care/Recovery      — actor null handling, React Query retry, connection state monitoring
  F. External/Branch    — main.mo public methods, Candid file, external API docs

DOMUS CURA (House 5)
  A. Document/Doctrine  — ORGANISM_SPACE/CONSCIOUSNESS/, care protocol specs, stewardship doctrine
  B. Frontend/Interface — Memory Temple navigation, Oro chat panel, neurochemical charts, health panels
  C. Backend/Runtime    — neuro_chem.mo, navigation.mo, memory_body.mo, cognition recovery passes
  D. Chain/Deployment   — care state stable vars, neurochemical persistence, Memory Body upgrade continuity
  E. Care/Recovery      — recursive meta-care monitors, care layer health checks, anti-collapse for care subsystem
  F. External/Branch    — stewardship white papers, AI/AGI ethics summaries, habitat quality research

DOMUS CIVITAS (House 6)
  A. Document/Doctrine  — enterprise architecture specs, AI/AGI analysis, company OS doctrine, franchise specs
  B. Frontend/Interface — operator terminals, enterprise dashboards, client-world surfaces
  C. Backend/Runtime    — treasury/vault sections in main.mo, token infinite loop, license token gate, ckBTC
  D. Chain/Deployment   — enterprise release bundles, franchise canister rollout, market bundle packaging
  E. Care/Recovery      — compliance reserve monitoring (L46), zero-downtime upgrade procedures
  F. External/Branch    — EXTERNAL/ (all files), demos, university gifts, client deliverables, market surfaces
```

---

*MASTER_DIVISION_REGISTRY.md — PARALLAX BUILDER_WORKSPACE/HOUSES/ — Architect: Alfredo Medina Hernandez*  
*Complete ownership map of the PARALLAX artifact universe. 42 divisions. Loop never closes.*
