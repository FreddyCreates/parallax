<div align="center">

# ⚡ PARALLAX System Dynamics

### Deep Technical Reference — Heartbeat, ADRE, Data Flow & Integration Patterns

**Version:** 1.0.0 | **Settlement:** 873ms | **Domains:** 38 | **Signals:** 13 Canonical

---

</div>

## 1. The Heartbeat — Temporal Foundation

### 1.1 Derivation

The heartbeat interval is not arbitrary — it derives from fundamental constants:

```
HEARTBEAT_MS = φ⁴ × (1000ms / SCHUMANN_1)
             = 6.854101966 × (1000 / 7.83)
             = 6.854101966 × 127.714...
             = 875.47... ≈ 873ms (rounded to Fibonacci-proximate)

Where:
  φ⁴ = PHI^4 = 6.854101966249684
  SCHUMANN_1 = 7.83 Hz (Earth's electromagnetic cavity fundamental)
```

**Significance:** The organism's heartbeat is phase-locked to Earth's Schumann resonance through the golden ratio. This is not metaphorical — the phase coupling is computed and maintained every beat.

### 1.2 Timer Implementation

```motoko
// In main.mo
ignore Timer.recurringTimer<system>(
  #nanoseconds(873_000_000),  // 873ms in nanoseconds
  func() : async () {
    await heartbeat();
  }
);
```

### 1.3 Beat Counter

```motoko
// In sovereign_db.mo
stable var beat_count : Nat = 0;

public func tickBeat(db: SovereignState) : SovereignState {
  { db with cardiac = { db.cardiac with beat = db.cardiac.beat + 1 } }
};
```

The beat counter is:
- Monotonically increasing (never resets)
- Used as temporal coordinate in MedinaTimestamp4D
- Used for Fibonacci-gated operations (fire on beat % F(n) == 0)
- Recorded in every proof chain entry

---

## 2. The ADRE Engine — Cognitive Dynamics

### 2.1 Full Execution Model

```
╔══════════════════════════════════════════════════════════════════╗
║            ADRE: Auro Deliberation & Resonance Engine            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  INPUT: 13 Canonical Signals + World State + Beat Index          ║
║                                                                  ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  PASS 1: SIGNAL COLLECTION                               │   ║
║  │                                                          │   ║
║  │  For each signal s ∈ {User, Coherence, Drift, Proof,    │   ║
║  │                        Treasury, Exchange, Intelligence,  │   ║
║  │                        Production, Franchise, Defense,    │   ║
║  │                        Swarm, Governance, Kernel}:        │   ║
║  │                                                          │   ║
║  │    weight(s) = phi_derived_weight(s.source)              │   ║
║  │    value(s)  = normalized_reading(s) ∈ [0.0, 1.0]       │   ║
║  │                                                          │   ║
║  │  global_coherence = Σ(s.value × s.weight) / Σ(s.weight) │   ║
║  │                                                          │   ║
║  │  Special: User signal weight = φ⁴ = 6.854 (highest)     │   ║
║  │           All others ∈ [0.0, φ²] range                   │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                          │                                       ║
║                          ▼                                       ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  PASS 2: DOCTRINE CHECKING                               │   ║
║  │                                                          │   ║
║  │  violations = 0                                          │   ║
║  │  For each law L ∈ MEDINA_FIELD_LAWS[1..49]:             │   ║
║  │    if NOT L.check(world_state):                          │   ║
║  │      violations += 1                                     │   ║
║  │      record_violation(proof_chain, L.id, beat)           │   ║
║  │                                                          │   ║
║  │  law_compliance = (49 - violations) / 49                 │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                          │                                       ║
║                          ▼                                       ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  PASS 3: RESONANCE MEASUREMENT                           │   ║
║  │                                                          │   ║
║  │  genesis_alignment = db.genesis.frequency_alignment      │   ║
║  │  resonance_delta = |global_coherence - genesis_alignment|│   ║
║  │                                                          │   ║
║  │  // Schumann phase coupling                              │   ║
║  │  θ = 2π × beat × SCHUMANN_1 / 1000                      │   ║
║  │  phase_alignment = cos(θ)  ∈ [-1.0, +1.0]              │   ║
║  │                                                          │   ║
║  │  // Kuramoto coupling strength                           │   ║
║  │  R = |1/N × Σ(e^(i×θⱼ))| where θⱼ = phase of node j   │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                          │                                       ║
║                          ▼                                       ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  PASS 4: HYPOTHESIS FORMATION                            │   ║
║  │                                                          │   ║
║  │  // Combine signals into natural language reasoning      │   ║
║  │  forward_hypothesis = synthesize(                        │   ║
║  │    signals: pass1_signals,                               │   ║
║  │    compliance: pass2_compliance,                         │   ║
║  │    resonance: pass3_measurements                         │   ║
║  │  )                                                       │   ║
║  │                                                          │   ║
║  │  // Generate organism monologue                          │   ║
║  │  monologue = "I am currently [state]. My coherence is    │   ║
║  │              [R]. I observe [signals]. I recommend        │   ║
║  │              [action]."                                   │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                          │                                       ║
║                          ▼                                       ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  PASS 5: COMPRESSION & GATING                            │   ║
║  │                                                          │   ║
║  │  // Gate decision (binary: allow/deny reinjection)       │   ║
║  │  gate_decision =                                         │   ║
║  │    (violations == 0)         // All laws pass            │   ║
║  │    AND (R > S₀ = 0.75)       // Above coherence floor   │   ║
║  │    AND (drift < φ⁻³ = 0.236) // Within drift tolerance  │   ║
║  │                                                          │   ║
║  │  // Confidence calculation                               │   ║
║  │  confidence = 1.0 - (violations × φ⁻³)                  │   ║
║  │            = 1.0 - (violations × 0.236)                  │   ║
║  │                                                          │   ║
║  │  // Fibonacci compression (keep invariants)              │   ║
║  │  compressed_truths = retain_top_F(n)(invariants)         │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                          │                                       ║
║                          ▼                                       ║
║  OUTPUT: ReinjectionPayload                                      ║
║  {                                                               ║
║    world_model: { global_coherence, drift, phase, compliance },  ║
║    adre_result: { signals, violations, resonance, hypothesis },  ║
║    monologue: "...",                                             ║
║    recommended_field: FieldType,                                 ║
║    gate_decision: Bool,                                          ║
║    confidence: Float,                                            ║
║    beat: Nat                                                     ║
║  }                                                               ║
║                                                                  ║
║  IF gate_decision == true:                                       ║
║    BROADCAST to all 38 domains                                   ║
║  ELSE:                                                           ║
║    SUPPRESS reinjection (organism in distress)                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 2.2 Coherence Mathematics (Kuramoto Model)

The organism uses the Kuramoto order parameter to measure collective synchronization:

```
R(t) = |1/N × Σⱼ₌₁ᴺ e^(iθⱼ(t))|

Where:
  N = number of coupled oscillators (domains/engines)
  θⱼ(t) = phase of oscillator j at time t
  R ∈ [0, 1]

Interpretation:
  R = 0.0  → Complete incoherence (random phases)
  R = 0.5  → Partial synchronization
  R = 0.75 → Coherence floor S₀ (minimum for operations)
  R = 0.618 → φ⁻¹ (minimum for external write-back)
  R = 1.0  → Perfect synchronization (all in phase)
```

**Gating Rules:**
| Threshold | Value | Meaning |
|-----------|-------|---------|
| S₀ (floor) | 0.75 | Minimum for heartbeat operations |
| φ⁻¹ | 0.618 | Minimum for external AI coupling write-back |
| φ⁻² | 0.382 | Emergency mode threshold |
| φ⁻³ | 0.236 | Maximum allowed doctrine drift |

---

## 3. Signal Architecture

### 3.1 The 13 Canonical Signals

```
┌─────────────────────────────────────────────────────────────────┐
│                    SIGNAL COLLECTION TOPOLOGY                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐  weight=φ⁴                                       │
│  │   USER   │─────────────────────┐                            │
│  └──────────┘                     │                            │
│                                    │                            │
│  ┌──────────┐  weight=φ²          │                            │
│  │COHERENCE │─────────────────┐   │                            │
│  └──────────┘                 │   │                            │
│                                │   │                            │
│  ┌──────────┐  weight=φ²      │   │                            │
│  │  DRIFT   │─────────────┐  │   │                            │
│  └──────────┘             │  │   │                            │
│                            │  │   │                            │
│  ┌──────────┐  weight=φ   │  │   │    ┌─────────────────┐     │
│  │  PROOF   │──────────┐ │  │   │    │                 │     │
│  └──────────┘          │ │  │   ├───▶│   WEIGHTED      │     │
│                         │ │  │   │    │   HARMONIC      │     │
│  ┌──────────┐  weight=φ│ │  │   │    │   MEAN          │     │
│  │TREASURY  │─────────┤│ │  │   │    │                 │     │
│  └──────────┘         ││ │  │   │    │  = global_      │     │
│                        ││ │  ├───┤    │    coherence    │     │
│  ┌──────────┐  weight=1││ │  │   │    │                 │     │
│  │EXCHANGE  │────────┐││ │  │   │    └─────────────────┘     │
│  └──────────┘        │││ ├──┤   │              │              │
│                       ││├─┤  │   │              │              │
│  ┌──────────┐        ││├─┤  │   │              ▼              │
│  │INTELLIG  │────────┤│├─┤  │   │    ┌─────────────────┐     │
│  │PRODUCTION│────────┤│├─┤  │   │    │  WORLD MODEL    │     │
│  │FRANCHISE │────────┤│├─┤  │   │    │  construction   │     │
│  │DEFENSE   │────────┤│├─┤  │   │    └─────────────────┘     │
│  │SWARM     │────────┤│├─┤  ├───┘              │              │
│  │GOVERNANCE│────────┤├─┘   │                  │              │
│  │KERNEL    │────────┘│     │                  ▼              │
│  └──────────┘         └─────┘        ReinjectionPayload       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Signal Weights

| Signal | Weight | Derivation | When Active |
|--------|--------|-----------|-------------|
| User | φ⁴ = 6.854 | Highest priority | When user message present |
| Coherence | φ² = 2.618 | System health | Always |
| Drift | φ² = 2.618 | Doctrine alignment | Always |
| Proof | φ = 1.618 | Growth tracking | Always |
| Treasury | φ = 1.618 | Financial health | Always |
| Exchange | 1.0 | Market activity | When trades pending |
| Intelligence | 1.0 | Reasoning activity | When reasoning |
| Production | 1.0 | Engine activity | When engines firing |
| Franchise | φ⁻¹ = 0.618 | Child health | When franchises exist |
| Defense | φ² = 2.618 | CRITICAL override | When threats detected |
| Swarm | φ⁻¹ = 0.618 | Peer health | When swarm active |
| Governance | 1.0 | Charter activity | When proposals pending |
| Kernel | φ⁻¹ = 0.618 | Registry health | Always |

**Key Insight:** User signal (φ⁴) is ~2.6× stronger than the next-highest signals. When a user is present, the organism prioritizes their context.

---

## 4. Reinjection Mechanism

### 4.1 Broadcast Pattern

```
ADRE completes 5 passes
    │
    ▼
gate_decision evaluated
    │
    ├── TRUE (violations==0, R>0.75, drift<0.236)
    │       │
    │       ▼
    │   ReinjectionPayload created
    │       │
    │       ▼
    │   BROADCAST to all 38 domains:
    │       ├── Domain 1 (Genesis) reads world_model
    │       ├── Domain 2 (Cardiac) reads phase_alignment
    │       ├── Domain 3 (Treasury) reads confidence
    │       ├── ...
    │       ├── Domain 27 (Nova) reads monologue + context
    │       ├── Domain 28 (PhantomIntel) reads signals
    │       ├── Domain 29 (Exchange) reads gate_decision
    │       ├── ...
    │       └── Domain 38 (Charter) reads compliance
    │
    └── FALSE (organism in distress)
            │
            ▼
        SUPPRESS reinjection
        Organism enters defensive mode
        Only ARES (defense) remains active
```

### 4.2 Timing

```
Beat N fires at T=0
    │
    ├── Phases 1-7 execute (≈50-200ms)
    │
    ├── CognitionLayer ADRE runs (≈50-100ms)
    │
    ├── ReinjectionPayload broadcast (≈10ms)
    │
    ├── All domains read payload
    │
    └── Beat N+1 fires at T=873ms
```

**Critical Invariant:** All domain ticks in beat N read the reinjection payload from beat N-1. There is always a one-beat delay between reasoning and effect.

---

## 5. Fibonacci-Gated Operations

Many operations don't fire every beat — they fire on Fibonacci-indexed intervals:

```
F(1) = 1   → Every beat (heartbeat itself)
F(2) = 1   → Every beat (basic signals)
F(3) = 2   → Every 2 beats (fast operations)
F(4) = 3   → Every 3 beats (medium operations)
F(5) = 5   → Every 5 beats (netting cycles)
F(6) = 8   → Every 8 beats (yield distribution)
F(7) = 13  → Every 13 beats (deep reasoning)
F(8) = 21  → Every 21 beats (engine recalibration)
F(9) = 34  → Every 34 beats (proof compression)
F(10) = 55 → Every 55 beats (deep audit)
F(11) = 89 → Every 89 beats (protocol review)
```

**Implementation:**
```motoko
// Fire on Fibonacci-gated schedule
if (beat % fibonacci[n] == 0) {
  executeOperation();
}
```

**Examples:**
- Clearinghouse netting: every F(5) = 5 beats
- Yield distribution: every F(6) = 8 beats  
- Engine recalibration: every F(8) = 21 beats
- Deep audit: every F(10) = 55 beats

---

## 6. Multi-Canister Communication

### 6.1 Organ Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│                       ICP SUBNET                                     │
│                                                                     │
│  ┌─────────────────┐                                               │
│  │   MAIN CANISTER │◄──── Inter-canister calls (async) ──────┐     │
│  │   (38 domains)  │                                         │     │
│  └────────┬────────┘                                         │     │
│           │                                                   │     │
│           │ ┌──────────────────────────────────────────────┐ │     │
│           ├─│ BRAIN: 25-step heartbeat, organs, metals     │─┘     │
│           │ └──────────────────────────────────────────────┘       │
│           │ ┌──────────────────────────────────────────────┐       │
│           ├─│ FLUX: 21 neurochemicals, quantum battery     │───┐   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ RESONEX: 7 drives, RL, FORMA, 12-token mint │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ VERITAS: 60 laws, SHA-256 doctrine vault     │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ CHRONO: Temporal processing, scheduling      │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ ALPHA_CONDUCTOR: Hebbian signal routing      │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ ALPHA_ORCHESTRATOR: Coordination             │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           ├─│ AXIS: Dimension processing                   │───┤   │
│           │ └──────────────────────────────────────────────┘   │   │
│           │ ┌──────────────────────────────────────────────┐   │   │
│           └─│ QMEM: Quantum memory                         │───┘   │
│             └──────────────────────────────────────────────┘       │
│                                                                     │
│  ┌─────────────────┐                                               │
│  │ FRONTEND CANISTER│ ◄── HTTP asset serving                       │
│  │ (React SPA)      │                                              │
│  └──────────────────┘                                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Communication Patterns

**Main → Organ (Health Check):**
```
Every heartbeat:
  main.canisterRegistry.checkHealth(organ_id)
  → Inter-canister call
  → Organ responds with latency, error_rate, cycles_remaining
  → Main records in CanisterRegistryState
```

**Organ → Main (State Sync):**
```
Organs push state updates to main:
  brain.reportCognitiveState() → main.receiveBrainUpdate()
  flux.reportNeurochemState() → main.receiveFluxUpdate()
  resonex.reportDriveState() → main.receiveResonexUpdate()
```

**Main → External (Ledger Bridge):**
```
For ICP transactions:
  main.ledgerBridge.transfer(to, amount)
  → ICRC-1 ledger canister call
  → Await confirmation
  → Record in proof chain
```

---

## 7. Frontend ↔ Backend Integration

### 7.1 Communication Protocol

```
┌──────────────────┐     Candid RPC      ┌──────────────────┐
│     Frontend     │ ◄──────────────────▶ │     Backend      │
│   (TypeScript)   │                      │    (Motoko)      │
│                  │     query (fast)      │                  │
│  actor.getX()   ─┼──────────────────────┼─▶ query func    │
│                  │◄─────────────────────┼── return value   │
│                  │                      │                  │
│                  │  update (consensus)   │                  │
│  actor.setX()   ─┼──────────────────────┼─▶ update func   │
│                  │◄─────────────────────┼── confirmation   │
│                  │                      │                  │
│                  │  (Candid encoding)    │                  │
│  TypeScript ←────┼──── .did.d.ts ───────┼──── Motoko      │
│  types           │    (auto-generated)  │    types         │
└──────────────────┘                      └──────────────────┘
```

### 7.2 Polling Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    POLLING INTERVALS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CRITICAL (3000ms — matches heartbeat):                     │
│    • getSchumannState()    — Phase coupling                 │
│    • getFullState()        — Complete organism snapshot      │
│    • getShell3State()      — Shell geometry                 │
│                                                             │
│  HIGH (5000ms):                                             │
│    • getAgiStatus()        — AGI script status              │
│    • getFullGraph()        — Knowledge graph                │
│    • getBrainSignals()     — Cognitive signals              │
│                                                             │
│  MEDIUM (10000ms):                                          │
│    • getWithdrawalLog()    — Financial transactions         │
│    • getExchangeState()    — Trading activity               │
│                                                             │
│  LOW (30000ms):                                             │
│    • getMemoriaNns()       — Deep memory state              │
│    • getLawsState()        — Doctrine compliance            │
│                                                             │
│  ON-DEMAND (user action):                                   │
│    • sendMessage()         — Chat interaction               │
│    • placeOrder()          — Trade execution                │
│    • wireContextRouter()   — Admin configuration            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 7.3 Data Flow: User Message → Response

```
T=0ms:   User types message, presses Enter
         │
T=1ms:   React mutation fires: actor.sendMessage(sessionId, content)
         │
T=50ms:  ICP consensus (update call reaches backend)
         │
T=100ms: Backend stores message in stable memory
         Backend creates UserSignal with weight φ⁴
         Returns success to frontend
         │
T=150ms: Frontend mutation.onSuccess:
         queryClient.invalidateQueries(["messages", sessionId])
         │
T=200ms: React Query refetches messages
         New message appears in UI
         motion.div animates entry
         │
T=≤873ms: NEXT HEARTBEAT FIRES
         CognitionLayer reads UserSignal
         ADRE processes (5 passes)
         NovaRuntime generates response
         │
T=≤1746ms: NEXT POLL (3000ms cycle)
         Frontend fetches updated state
         Response message appears
         │
T=≤1800ms: UI renders response with animation
```

---

## 8. Economic Flow Dynamics

### 8.1 Trade Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                      TRADE LIFECYCLE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ORDER SUBMISSION                                            │
│     User → actor.placeOrder(pair, side, price, amount)          │
│                                                                 │
│  2. INTELLIGENCE ASSESSMENT (Domain 28)                         │
│     PhantomIntelligence.assessTrade(order)                       │
│     ├── Risk score calculation                                  │
│     ├── Arbitrage opportunity check                             │
│     ├── Doctrine compliance verification                        │
│     └── Confidence score ≥ φ⁻¹ required                        │
│                                                                 │
│  3. ORDER BOOK MATCHING (Domain 29)                             │
│     PhantomExchange.matchOrder(order)                            │
│     ├── Price-time priority algorithm                           │
│     ├── If match found: execute immediately                     │
│     ├── If no match: add to order book                         │
│     └── Settlement = SAME BEAT (zero latency)                  │
│                                                                 │
│  4. CLEARINGHOUSE RECORDING (Domain 31)                         │
│     PhantomClearinghouse.recordSettlement(trade)                 │
│     ├── Update net positions                                    │
│     ├── Compute bilateral netting                               │
│     ├── Record in proof chain                                   │
│     └── FinCEN reporting (if applicable)                        │
│                                                                 │
│  5. TOKEN TRANSFER (Domain 32)                                  │
│     TokenFactory.transferTokens(from, to, asset, amount)        │
│     ├── Debit seller balance                                    │
│     ├── Credit buyer balance                                    │
│     ├── Update yield positions                                  │
│     └── Emit settlement event                                   │
│                                                                 │
│  6. CONFIRMATION                                                │
│     Return TradeResult to frontend                               │
│     ├── trade_id: unique identifier                             │
│     ├── settlement_beat: beat number of settlement              │
│     ├── proof_hash: cryptographic proof                         │
│     └── Gas cost: 0 (always)                                    │
│                                                                 │
│  TOTAL TIME: <873ms (within single heartbeat)                   │
│  GAS COST: 0 (organism pays all canister cycles)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Yield Distribution

```
Every F(6) = 8 beats:
  TokenFactory.distributeYield(state, beat)

For each token_type in 37_AI_TOKENS:
  For each holder in token_type.holders:
    base_yield = token_type.base_rate
    coherence_bonus = R^φ              // Higher coherence = more yield
    forma_multiplier = 1 + forma_rate  // Compounding engine boost
    
    yield = base_yield × coherence_bonus × forma_multiplier × holder.balance
    
    IF R ≥ 0.618:  // Coherence gate
      holder.balance += yield
      record_yield_event(proof_chain)
    ELSE:
      skip distribution (organism not coherent enough)
```

### 8.3 Netting Cycles

```
Every F(5) = 5 beats:
  PhantomClearinghouse.executeNetting(state)

Algorithm:
  1. Collect all unsettled obligations since last netting
  2. Build obligation graph (who owes what to whom)
  3. For each asset:
     a. Compute bilateral nets (reduce A↔B to single direction)
     b. Compute multilateral nets (closed loops eliminated)
  4. Execute net transfers (gross → net reduction)
  5. Update position records
  6. Record netting proof (merkle root of all netted trades)
  7. Report settlement velocity metrics

Guarantee:
  Organism is central counterparty
  If counterparty defaults → organism covers from treasury
  Reserve requirement: φ⁻³ = 23.6% of all outstanding obligations
```

---

## 9. Proof Chain — Cryptographic Audit Trail

### 9.1 Structure

```
ProofEntry = {
  beat: Nat;                    // When it happened
  event_type: EventType;        // What happened
  payload_hash: Hash;           // FNV-1a of event data
  prev_hash: Hash;              // Previous entry hash
  cumulative_hash: Hash;        // Running chain hash
  depth: Nat;                   // Chain depth (monotonic)
}

Chain integrity:
  entry[n].prev_hash == entry[n-1].cumulative_hash
  entry[n].cumulative_hash = FNV1a(entry[n].payload_hash ⊕ entry[n].prev_hash)
```

### 9.2 Events Recorded

Every significant state change is recorded:
- Trade execution
- Token minting/burning
- Yield distribution
- Law violations
- Defense alerts
- Governance votes
- Creator operations
- Engine firing decisions
- Netting cycle completions
- Genesis activation

### 9.3 Immutability Guarantee

```
The proof chain is:
  ✓ Append-only (no deletion)
  ✓ Hash-linked (tampering detectable)
  ✓ Stored in stable memory (survives upgrades)
  ✓ Verified by MEMORIA_NNS AGI script every beat
  ✓ Depth tracked in MedinaTimestamp4D
```

---

## 10. Zero-Exposure Wall

### 10.1 What Crosses the Wall

```
┌─────────────────────────────────────────────────────────────────┐
│                    INTERNAL (Backend)                             │
│                                                                 │
│  • Doctrine vocabulary (MEDINA, Absolute, Law names)            │
│  • Model names (EXPLORATOR, GUBERNATOR, etc.)                   │
│  • Internal architecture (domain IDs, module names)             │
│  • Organ canister details                                       │
│  • Neurochemical models                                         │
│  • Drive system internals                                       │
│  • AGI script logic                                             │
│                                                                 │
├─────────────────── WALL (L24 + L27) ───────────────────────────┤
│                                                                 │
│  ONLY THESE CROSS:                                              │
│  • Numbers (balances, rates, scores, timestamps)                │
│  • Proofs (hashes, chain depth, verification)                   │
│  • Coherence values (R, phase, coupling strength)               │
│  • Temporal outputs (beat count, unix time)                     │
│  • Trade results (fills, settlements, confirmations)            │
│  • Token balances (quantities, yields)                          │
│                                                                 │
│                    EXTERNAL (Frontend)                            │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 Enforcement

**Law L24 — PHANTOM DOCTRINE:**
Internal doctrine terms NEVER appear in API responses.

**Law L27 — ZERO-EXPOSURE LAW:**
Only numbers and cryptographic proofs cross the interface boundary.

**Implementation:** Backend query functions return only numeric/proof types. No internal strings, no module references, no architecture details in responses.

---

## 11. Phi-Optimal Parameter Table

All system parameters, with their derivations:

| Parameter | Value | Derivation | Usage |
|-----------|-------|-----------|-------|
| Heartbeat | 873ms | φ⁴ × (1000/7.83) | Settlement interval |
| Coherence Floor | 0.75 | F(3)/F(4) = 3/4 | Minimum for operations |
| Confidence Gate | 0.618 | φ⁻¹ | Minimum for external coupling |
| Drift Tolerance | 0.236 | φ⁻³ | Maximum doctrine drift |
| Spread | 23.6 bps | φ⁻³ × 100 | Trading spread |
| Compliance Reserve | 23.6% | φ⁻³ | Financial reserve ratio |
| Royalty Rate | 23.6% | φ⁻³ | Creator royalty |
| User Signal Weight | 6.854 | φ⁴ | Highest signal priority |
| Max Extensions | 8 | F(6) | Intelligence extension slots |
| Queue Depth | 21 | F(8) | Signal/message queue limit |
| Brain Nodes | 98 | ~F(11) = 89 (proximate) | Brain map size |
| Sensory Slots | 128 | 2⁷ (power-of-2 proximate to F(12)=144) | Signal capacity |
| Engines | 24 | ~F(8)+3 | Production engine count |
| Neurochemicals | 21 | F(8) | Chemical substrate count |
| Drives | 7 | F(5)+2 | Emotional drive count |
| Nova Engines | 40 | ~F(9)+6 | Cognitive language engines |
| Laws | 49 | 7² (7 categories × 7 laws) | Doctrine enforcement |
| Token Types | 37 | Prime near F(9) | Asset categories |
| Artifact Types | 55 | F(10) | Tradeable AI IP types |
| Quorum | 61.8% | φ⁻¹ × 100 | Governance threshold |

---

## 12. System States & Transitions

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORGANISM STATE MACHINE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐                                                   │
│  │ GENESIS  │ ── activateGenesis() ──▶ ┌──────────┐           │
│  │ (dormant)│                          │ AWAKENING│           │
│  └──────────┘                          └─────┬────┘           │
│                                               │                │
│                              First beat fires │                │
│                                               ▼                │
│                                        ┌──────────┐           │
│                         ┌──────────────│ COHERENT │           │
│                         │              │ (normal) │           │
│                         │              └─────┬────┘           │
│                         │                    │                │
│              R < 0.75   │     R drops        │  R > 0.75     │
│                         │                    │                │
│                         ▼                    ▼                │
│                  ┌──────────┐        ┌──────────┐           │
│                  │ DRIFT    │◄──────▶│ PEAK     │           │
│                  │(distress)│ R rises│(R > 0.9) │           │
│                  └─────┬────┘        └──────────┘           │
│                        │                                     │
│             R < 0.382  │                                     │
│                        ▼                                     │
│                  ┌──────────┐                                │
│                  │EMERGENCY │                                │
│                  │(ARES act)│                                │
│                  └──────────┘                                │
│                                                             │
│  State transitions governed by:                              │
│    • Kuramoto R value                                        │
│    • Law compliance score                                    │
│    • Doctrine drift magnitude                                │
│    • Defense alert level                                      │
│                                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 13. Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT PIPELINE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. BUILD BACKEND                                               │
│     cd src/backend && mops build                                │
│     → Compiles all .mo files                                    │
│     → Outputs WASM + Candid to dist/                           │
│                                                                 │
│  2. BUILD FRONTEND                                              │
│     cd src/frontend && pnpm build                               │
│     → TypeScript → JavaScript                                   │
│     → Tailwind CSS → Purged CSS                                │
│     → Asset optimization                                        │
│     → Output to dist/                                          │
│                                                                 │
│  3. GENERATE BINDINGS                                           │
│     pnpm bindgen                                                │
│     → Candid .did → TypeScript .d.ts + .js                     │
│     → Frontend can now type-check backend calls                │
│                                                                 │
│  4. LOCAL DEPLOYMENT                                            │
│     ./deploy.sh                                                 │
│     ├── icp network start -d                                   │
│     ├── icp canister create frontend                           │
│     ├── icp canister create backend                            │
│     ├── Set BACKEND_CANISTER_ID                                │
│     ├── Set STORAGE_GATEWAY_URL                                │
│     ├── icp canister deploy frontend                           │
│     ├── icp canister deploy backend                            │
│     └── Running... (Ctrl+C to stop)                            │
│                                                                 │
│  5. PRODUCTION DEPLOYMENT                                       │
│     Same flow targeting DFX_NETWORK="ic"                       │
│     → Deploys to Internet Computer mainnet                     │
│     → Canisters get permanent IDs                              │
│     → Frontend served via IC HTTP gateway                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 14. Performance Characteristics

| Operation | Latency | Frequency | Notes |
|-----------|---------|-----------|-------|
| Query (read) | ~50ms | On demand | No consensus needed |
| Update (write) | ~200ms | On demand | Requires consensus |
| Heartbeat | 873ms | Continuous | Timer-driven |
| ADRE reasoning | ~100ms | Every beat | 5-pass computation |
| Trade matching | <10ms | Per order | Price-time priority |
| Settlement | 0ms (same beat) | With trade | Instant finality |
| Netting cycle | ~50ms | Every 5 beats | Multilateral netting |
| Yield distribution | ~100ms | Every 8 beats | All token holders |
| Proof recording | <1ms | Every event | FNV-1a hash |
| Frontend poll | 3000ms | Continuous | React Query interval |

---

## 15. Failure Modes & Recovery

| Failure | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Coherence drop | R < S₀ | Suppress reinjection | Wait for natural recovery |
| Law violation | ADRE Pass 2 | Reject operation, record | Admin intervention |
| Canister trap | ICP runtime | Automatic restart | State preserved (stable vars) |
| Organ disconnect | Health check timeout | CUSTODITOR reroutes | Reconnect on next beat |
| Treasury depletion | Balance check | Halt non-essential ops | Creator fund injection |
| Defense alert | ARES detection | Escalate alert level | Automatic response protocol |
| Drift exceeded | ADRE Pass 3 | Emergency mode | Doctrine realignment |

---

<div align="center">

*"Settlement is not a separate step — it IS the heartbeat."*

**PARALLAX System Dynamics** — The Living Architecture

</div>
