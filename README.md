# PARRALAX-AIHFTFUND

## Sovereign AI-Native Financial Execution Infrastructure

PARRALAX-AIHFTFUND is a production-grade, multi-language financial execution infrastructure for agent-driven trading across crypto, blockchain assets, fiat, equities, currencies, AI tokens, NFTs, and internal digital assets — built with HFT protocols, fund charters, risk gates, governance rails, compute receipts, and autonomous market operations.

---

## Technology Stack

| Layer | Language | Purpose |
|-------|----------|---------|
| **Execution Engine** | Rust | Low-latency HFT order routing, risk gates, execution receipts |
| **Trading Infrastructure** | Python | Agents, signals, market data, paper trading, strategy engine |
| **Dashboard** | React (TypeScript) | Fund operations UI, monitoring, agent control |
| **On-Chain** | Solidity / Rust (Solana) | Token contracts, NFTs, receipt anchoring |
| **Data** | PostgreSQL + Redis | Positions, receipts, market data, message queue |
| **API** | FastAPI (Python) | REST + WebSocket gateway |
| **Infrastructure** | Docker + Kubernetes | Multi-service orchestration |

---

## Project Structure

```
PARRALAX-AIHFTFUND/
├── rust/                          # Rust HFT execution engine
│   └── execution-engine/          # Order routing, risk gates, receipts
├── python/                        # Python trading infrastructure
│   └── parralax/
│       ├── agents/                # Signal, Risk, Execution agents
│       ├── market_data/           # Crypto + Equity adapters
│       ├── paper_trading/         # Paper trading simulation engine
│       └── registry/              # Protocol + Agent registries
├── src/frontend/                  # React dashboard
├── CHARTER.md                     # Fund charter
├── GOVERNANCE.md                  # Governance framework
├── RISK.md                        # Risk management charter
├── SECURITY.md                    # Security policy
├── EXECUTION_PROTOCOL.md          # Order execution protocol
├── COMPUTE_RECEIPT_PROTOCOL.md    # Proof-of-execution receipts
├── TOKEN_PROTOCOL.md              # Internal token system
├── NFT_PROTOCOL.md                # NFT digital assets
├── TREASURY_PROTOCOL.md           # Treasury management
├── AGENT_AUTHORITY_CHARTER.md     # Agent permissions
├── ASSET_ISSUANCE_CHARTER.md      # Digital asset issuance
├── COMPLIANCE_BOUNDARY.md         # Regulatory boundaries
└── ROADMAP.md                     # Development phases
```

---

## Quick Start

### Rust Execution Engine
```bash
cd rust/execution-engine
cargo build --release
cargo run
```

### Python Trading Infrastructure
```bash
cd python
pip install -e ".[dev]"
python -m parralax
```

### React Dashboard
```bash
cd src/frontend
pnpm install
pnpm dev
```

### Docker (Full Stack)
```bash
docker-compose up -d
```

---

## Core Principles

1. **Build real financial machinery** — Not toy bots or research exercises
2. **Govern every agent** — Authority levels, kill switches, approval gates
3. **Prove every action** — Immutable compute receipts for all operations
4. **Control every risk** — Multi-layer risk gates before execution
5. **Preserve trader sovereignty** — Human operator retains ultimate authority
6. **Expand across every asset layer** — Crypto, equities, forex, tokens, NFTs

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
│              │  ENGINE      │                             │
│  Signal      │  Order Router│  Token (ERC-20)            │
│  Risk        │  Risk Gates  │  NFT (ERC-721)             │
│  Execution   │  Receipts    │  Receipt Anchor            │
│  Governor    │  Fill Engine │  Governance                │
├──────────────┴──────────────┴───────────────────────────┤
│  POSTGRESQL       │  REDIS          │  S3 ARCHIVE        │
│  (Ledger/Receipts)│  (Cache/Queue)  │  (Cold Storage)    │
└───────────────────┴─────────────────┴────────────────────┘
```

---

## Status

**Phase 1 — Foundation: COMPLETE**

See [ROADMAP.md](./ROADMAP.md) for full development phases.

---

## License

MIT
