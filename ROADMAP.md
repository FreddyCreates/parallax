# ROADMAP.md

## PARRALAX-AIHFTFUND Development Roadmap

### Version 1.0

---

## Phase 1 — Foundation ✅ (Current)

- [x] Define charter (CHARTER.md)
- [x] Define repo identity (README.md)
- [x] Create protocol registry (Python: `parralax.registry.protocol_registry`)
- [x] Create agent registry (Python: `parralax.registry.agent_registry`)
- [x] Create risk charter (RISK.md)
- [x] Create governance charter (GOVERNANCE.md)
- [x] Create asset issuance charter (ASSET_ISSUANCE_CHARTER.md)
- [x] Define compute receipt structure (COMPUTE_RECEIPT_PROTOCOL.md)
- [x] Build Rust HFT execution engine (`rust/execution-engine/`)
- [x] Build Python agent framework (`python/parralax/agents/`)
- [x] Define market data adapters (`python/parralax/market_data/`)

---

## Phase 2 — Simulation and Paper Execution

- [ ] Build paper trading engine (`python/parralax/paper_trading/`)
- [ ] Add market data adapters (crypto: CCXT, equity: Alpaca)
- [ ] Create signal agents (momentum, mean reversion, breakout)
- [ ] Create risk agents (exposure monitoring, loss limits)
- [ ] Create receipt logging (PostgreSQL + append-only ledger)
- [ ] Add strategy memory (agent post-trade learning)
- [ ] Build test portfolios (multi-asset simulation)
- [ ] Backtesting framework with historical data

---

## Phase 3 — Digital Asset Infrastructure

- [ ] Define internal token models (PFT, PCC, PSS, PGV)
- [ ] Define NFT models (strategy records, agent certificates)
- [ ] Create asset registry (PostgreSQL + on-chain anchoring)
- [ ] Create issuance protocol (mint, burn, transfer)
- [ ] Add governance records (NFT-based governance history)
- [ ] Add proof receipts for asset creation

---

## Phase 4 — Broker / Exchange Integration

- [ ] Add Alpaca adapter (equities + crypto)
- [ ] Add Binance adapter (spot + futures)
- [ ] Add Interactive Brokers adapter (multi-asset)
- [ ] Add Uniswap/DEX adapter (on-chain tokens)
- [ ] Add order routing (smart routing by latency/fee/liquidity)
- [ ] Add fill reconciliation (venue ↔ internal ledger)
- [ ] Add execution receipts (immutable proof chain)

---

## Phase 5 — Agent Authority Expansion

- [ ] Promote agents from observer to proposer (criteria-based)
- [ ] Add human approval gates (configurable thresholds)
- [ ] Add guarded execution (sandbox → live progression)
- [ ] Add capital limits (per-agent, per-strategy)
- [ ] Add kill switches (per-agent + system-wide)
- [ ] Add post-trade memory (learning from outcomes)

---

## Phase 6 — Sovereign Fund Operating Layer

- [ ] Create fund operating dashboard (React)
- [ ] Add treasury management (multi-pool accounting)
- [ ] Add strategy allocation (portfolio-level)
- [ ] Add agent governance (monitoring + control)
- [ ] Add performance records (attribution + benchmarking)
- [ ] Add audit exports (compliance reporting)
- [ ] Add internal asset accounting (double-entry)

---

## Phase 7 — Advanced Autonomous Market Operations

- [ ] Multi-agent strategy coordination
- [ ] AI-token governance
- [ ] Cross-market arbitrage logic
- [ ] On-chain/off-chain execution bridge
- [ ] Autonomous treasury balancing
- [ ] Adaptive agent permissions
- [ ] Protocol-governed market operations

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Execution Engine | **Rust** | Low-latency order routing, risk gates, HFT core |
| Trading Logic | **Python** | Agents, signals, strategy, market data, backtesting |
| Dashboard | **React** (TypeScript) | Fund operations UI, monitoring, control |
| Data Store | PostgreSQL + Redis | Positions, receipts, market data cache |
| Message Queue | Redis/Celery | Async agent communication |
| On-Chain | Solidity/Rust (Solana) | Token contracts, receipt anchoring |
| API | FastAPI (Python) | REST + WebSocket for all services |
| Infrastructure | Docker + Kubernetes | Multi-service orchestration |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    REACT DASHBOARD                        │
├─────────────────────────────────────────────────────────┤
│                    FASTAPI GATEWAY                        │
├──────────────┬──────────────┬───────────────────────────┤
│  PYTHON      │  RUST        │  ON-CHAIN                  │
│  AGENTS      │  EXECUTION   │  CONTRACTS                 │
│  ─────────   │  ENGINE      │  ──────────                │
│  Signal      │  ──────────  │  Token (ERC-20)            │
│  Risk        │  Order Router│  NFT (ERC-721)             │
│  Execution   │  Risk Gates  │  Receipt Anchor            │
│  Governor    │  Receipts    │  Governance                │
├──────────────┴──────────────┴───────────────────────────┤
│  POSTGRESQL  │  REDIS       │  S3 ARCHIVE                │
│  (Ledger)    │  (Cache/MQ)  │  (Cold Storage)            │
└──────────────┴──────────────┴───────────────────────────┘
```
