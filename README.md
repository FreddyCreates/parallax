<p align="center">
  <img src="./assets/banner.svg" alt="PARRALAX AI HFT FUND" width="100%"/>
</p>

<p align="center">
  <strong>Sovereign AI-Native Financial Execution Infrastructure</strong>
</p>

<p align="center">
  <a href="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/actions/workflows/ci.yml"><img src="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/actions/workflows/ci.yml/badge.svg" alt="CI/CD Pipeline"></a>
  <a href="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/actions/workflows/python-publish.yml"><img src="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/actions/workflows/python-publish.yml/badge.svg" alt="Python Publish"></a>
  <a href="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND"><img src="https://img.shields.io/github/stars/ItsNotAILABS/PARRALAX-AIHFTFUND?style=social" alt="Stars"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Rust-HFT_Engine-orange?logo=rust&logoColor=white" alt="Rust">
  <img src="https://img.shields.io/badge/Python-Trading_AI-3776AB?logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/TypeScript-Dashboard-3178C6?logo=typescript&logoColor=white" alt="TypeScript">
  <img src="https://img.shields.io/badge/Go-Services-00ADD8?logo=go&logoColor=white" alt="Go">
  <img src="https://img.shields.io/badge/Ruby-Rails_API-CC342D?logo=ruby&logoColor=white" alt="Ruby">
  <img src="https://img.shields.io/badge/Motoko-On--Chain-6B25C9?logo=dfinity&logoColor=white" alt="Motoko">
  <img src="https://img.shields.io/badge/Solidity-Contracts-363636?logo=solidity&logoColor=white" alt="Solidity">
  <img src="https://img.shields.io/badge/Docker-Orchestration-2496ED?logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Kubernetes-Deploy-326CE5?logo=kubernetes&logoColor=white" alt="Kubernetes">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Production_Grade-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/Architecture-Multi--Agent-blueviolet" alt="Architecture">
  <img src="https://img.shields.io/badge/Execution-Sub--Millisecond-ff6b35" alt="Execution">
  <img src="https://img.shields.io/badge/Assets-Multi--Class-gold" alt="Assets">
</p>

---

## 🏛️ What is PARRALAX?

**PARRALAX-AIHFTFUND** is a complete, sovereign financial operating system powered by artificial intelligence. It trades, manages risk, issues assets, governs operations, and executes across every major financial market — all autonomously, all under your control.

This isn't a library. It isn't a trading bot. It's a **full financial infrastructure** — the same kind of architecture that powers hedge funds, market makers, and institutional trading desks — made accessible to anyone.

> **Think of it as:** Your own AI-powered hedge fund infrastructure. One install. Full control. Every market.

---

## 🎯 Who Is This For?

| You are... | PARRALAX gives you... |
|---|---|
| **A trader** | AI agents that execute your strategies 24/7 across crypto, stocks, forex, and more |
| **A fund operator** | Complete fund infrastructure with governance, risk controls, and compliance rails |
| **A developer** | Production-grade APIs, SDKs, and a modular architecture to build on |
| **An investor** | Transparent, auditable execution with immutable compute receipts |
| **A builder** | A platform to launch your own financial products, tokens, and digital assets |

---

## ⚡ What Can It Do?

<table>
<tr>
<td width="50%">

### 📈 Trade Every Market
- Crypto (spot & futures)
- Equities & stocks
- Foreign exchange
- AI tokens & digital assets
- NFTs & programmable assets
- Internal fund tokens

</td>
<td width="50%">

### 🤖 AI Agents Work For You
- Signal detection agents
- Risk management agents
- Execution agents
- Governor agents (oversight)
- Portfolio optimization
- Multi-agent coordination

</td>
</tr>
<tr>
<td width="50%">

### 🛡️ Enterprise-Grade Security
- Multi-layer risk gates
- Kill switches (per-agent & system)
- Human approval gates
- Authority levels & permissions
- Compliance boundaries
- Immutable audit trail

</td>
<td width="50%">

### 🏦 Full Fund Operations
- Treasury management
- Asset issuance (tokens, NFTs)
- Governance protocols
- Performance attribution
- Regulatory compliance
- On-chain receipts

</td>
</tr>
</table>

---

## 🚀 Getting Started

### Option 1: One-Command Launch (Docker)

The fastest way to get the full platform running:

```bash
git clone https://github.com/ItsNotAILABS/PARRALAX-AIHFTFUND.git
cd PARRALAX-AIHFTFUND
docker-compose up -d
```

That's it. The entire platform — trading engine, AI agents, dashboard, API, database — all running.

**Open the Dashboard:** [http://localhost:3000](http://localhost:3000)  
**API Gateway:** [http://localhost:8000/docs](http://localhost:8000/docs)

---

### Option 2: Individual Services

<details>
<summary><strong>🦀 Rust HFT Execution Engine</strong> — Sub-millisecond order routing</summary>

```bash
cd rust/execution-engine
cargo build --release
cargo run
```

The execution engine handles order routing, risk gates, fill execution, and compute receipts at HFT speeds.

</details>

<details>
<summary><strong>🐍 Python Trading Infrastructure</strong> — AI agents & strategies</summary>

```bash
cd python
pip install -e ".[dev]"
python -m parralax
```

Includes signal agents, risk agents, execution orchestrators, market data adapters, paper trading, and strategy engines.

</details>

<details>
<summary><strong>⚛️ React Dashboard</strong> — Fund operations UI</summary>

```bash
cd src/frontend
pnpm install
pnpm dev
```

Real-time monitoring, agent control, portfolio views, and fund operations — all in one interface.

</details>

<details>
<summary><strong>🔧 CLI Tool</strong> — Command-line operations</summary>

```bash
cd services/cli
go build -o parralax ./...
./parralax --help
```

Manage agents, view positions, trigger actions, and monitor the system from your terminal.

</details>

<details>
<summary><strong>🧠 AI Service</strong> — Intelligence layer (FastAPI)</summary>

```bash
cd services/ai-service
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

Full actuary suite, trading strategies, financial language engines (FIX, FpML, SWIFT, ISDA CDM, XBRL, ISO 20022).

</details>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACES                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────┐ │
│  │  Dashboard  │  │    CLI     │  │    API     │  │  VS Code Ext │ │
│  └────────────┘  └────────────┘  └────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│                         API GATEWAY (FastAPI)                        │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│  AI AGENTS   │  EXECUTION   │  ON-CHAIN    │  FUND OPERATIONS       │
│  ──────────  │  ENGINE      │  LAYER       │  ──────────────        │
│  Signal      │  ──────────  │  ──────────  │  Treasury              │
│  Risk        │  Order Router│  ICP Canistr │  Governance            │
│  Execution   │  Risk Gates  │  ERC-20/721  │  Compliance            │
│  Governor    │  Fill Engine │  Receipts    │  Asset Issuance        │
│  Portfolio   │  Receipts    │  DeFi Bridge │  Performance           │
├──────────────┴──────────────┴──────────────┴────────────────────────┤
│  PERSISTENCE    │  MESSAGING      │  COMPUTE          │  INFRA      │
│  PostgreSQL     │  Redis/Celery   │  ALOHA I Protocol │  Docker/K8s │
│  S3 Archive     │  WebSocket      │  Phantom Engines  │  CI/CD      │
└─────────────────┴─────────────────┴───────────────────┴─────────────┘
```

---

## 📊 Technology Stack

| Layer | Technology | What It Does |
|-------|-----------|--------------|
| **Execution Core** | Rust | Sub-millisecond order routing, risk gates, HFT engine |
| **Trading Intelligence** | Python | AI agents, signals, strategies, market data, backtesting |
| **Web Dashboard** | React + TypeScript | Real-time fund operations UI |
| **Backend Services** | Go + Rails + FastAPI | Git operations, REST APIs, business logic |
| **On-Chain** | Motoko (ICP) + Solidity | Smart contracts, token factory, on-chain state |
| **Data** | PostgreSQL + Redis | Ledger, positions, cache, message queue |
| **Infrastructure** | Docker + Kubernetes | Multi-service orchestration, auto-scaling |
| **Financial Protocols** | FIX, FpML, SWIFT, XBRL | Industry-standard financial messaging |

---

## 🧠 AI & Intelligence Systems

PARRALAX includes multiple AI subsystems that work together:

- **ALOHA I** — Autonomous Liquid Orchestration & Harmonic Arbitrage Intelligence (10 protocol models)
- **Phantom Engines** — 30+ specialized trading intelligence modules (volatility, sentiment, neural, fractal, microstructure, etc.)
- **Signal Fusion** — Multi-model signal aggregation with confidence scoring
- **Cognitive Market Making** — Adaptive spread and inventory management
- **Neural Portfolio** — AI-driven portfolio construction and rebalancing
- **Entropic Risk** — Information-theoretic risk measurement
- **Swarm Execution** — Distributed execution across venues

---

## 🔐 Security & Governance

Every action in PARRALAX is governed, audited, and controlled:

| Control | Description |
|---------|-------------|
| **Risk Gates** | Multi-layer checks before any trade executes |
| **Kill Switches** | Instant halt — per-agent or system-wide |
| **Authority Levels** | Observer → Proposer → Executor → Governor progression |
| **Compute Receipts** | Immutable proof of every operation |
| **Compliance Boundary** | Regulatory guardrails built into the protocol |
| **Human Override** | You always retain ultimate authority |

📄 See [SECURITY.md](./SECURITY.md) · [GOVERNANCE.md](./GOVERNANCE.md) · [RISK.md](./RISK.md) · [COMPLIANCE_BOUNDARY.md](./COMPLIANCE_BOUNDARY.md)

---

## 📂 Repository Structure

```
PARRALAX-AIHFTFUND/
├── rust/execution-engine/     # 🦀 HFT execution engine (Rust)
├── python/parralax/           # 🐍 Trading AI & strategy engines
├── src/
│   ├── frontend/              # ⚛️  React dashboard
│   └── backend/               # 🧠 On-chain canisters (Motoko/ICP)
├── services/
│   ├── ai-service/            # 🤖 AI intelligence layer (FastAPI)
│   ├── rails-api/             # 💎 Business logic API (Rails)
│   ├── rust-engine/           # ⚙️  Core computation engine
│   ├── git-service/           # 📦 Git operations (Go)
│   ├── cli/                   # 🔧 Command-line interface (Go)
│   └── vscode-extension/      # 🖥️  VS Code integration
├── k8s/                       # ☸️  Kubernetes manifests
├── monitoring/                # 📊 Observability configs
├── docs/                      # 📚 Documentation
├── CHARTER.md                 # 🏛️  Fund charter
├── GOVERNANCE.md              # ⚖️  Governance framework
├── RISK.md                    # 🛡️  Risk management
├── ROADMAP.md                 # 🗺️  Development roadmap
└── docker-compose.yml         # 🐳 One-command full stack
```

---

## 📋 Protocol & Charter Documents

PARRALAX operates under a comprehensive set of governance documents:

| Document | Purpose |
|----------|---------|
| [CHARTER.md](./CHARTER.md) | Core fund charter and mission |
| [GOVERNANCE.md](./GOVERNANCE.md) | Decision-making framework |
| [RISK.md](./RISK.md) | Risk management protocols |
| [EXECUTION_PROTOCOL.md](./EXECUTION_PROTOCOL.md) | Order execution rules |
| [TOKEN_PROTOCOL.md](./TOKEN_PROTOCOL.md) | Internal token system |
| [NFT_PROTOCOL.md](./NFT_PROTOCOL.md) | Digital asset NFTs |
| [TREASURY_PROTOCOL.md](./TREASURY_PROTOCOL.md) | Treasury operations |
| [COMPUTE_RECEIPT_PROTOCOL.md](./COMPUTE_RECEIPT_PROTOCOL.md) | Proof-of-execution |
| [AGENT_AUTHORITY_CHARTER.md](./AGENT_AUTHORITY_CHARTER.md) | Agent permissions |
| [ASSET_ISSUANCE_CHARTER.md](./ASSET_ISSUANCE_CHARTER.md) | Asset creation rules |
| [COMPLIANCE_BOUNDARY.md](./COMPLIANCE_BOUNDARY.md) | Regulatory boundaries |

---

## 🗺️ Roadmap

| Phase | Status | Focus |
|-------|--------|-------|
| **Phase 1** — Foundation | ✅ Complete | Core architecture, protocols, charters |
| **Phase 2** — Simulation | 🔄 In Progress | Paper trading, backtesting, signal agents |
| **Phase 3** — Digital Assets | 📋 Planned | Token models, NFTs, asset registry |
| **Phase 4** — Broker Integration | 📋 Planned | Alpaca, Binance, IB, DEX adapters |
| **Phase 5** — Agent Authority | 📋 Planned | Progressive autonomy, learning, kill switches |
| **Phase 6** — Fund Operations | 📋 Planned | Full dashboard, treasury, compliance |
| **Phase 7** — Autonomous Ops | 📋 Planned | Multi-agent coordination, cross-market |

📄 Full details: [ROADMAP.md](./ROADMAP.md)

---

## 🧪 Development

### Prerequisites

- **Docker** (recommended) — for one-command setup
- **Rust** 1.75+ — for the execution engine
- **Python** 3.11+ — for trading infrastructure
- **Node.js** 16+ & pnpm — for the dashboard
- **Go** 1.22+ — for services and CLI

### Running Tests

```bash
# Rust execution engine
cd rust/execution-engine && cargo test --all-features

# Python trading AI
cd python && pip install -e ".[dev]" && pytest tests/ -v

# AI service
cd services/ai-service && pip install -e ".[dev]" && pytest tests/ -v

# Go services
cd services/git-service && go test ./... -v -race
cd services/cli && go test ./... -v

# Full CI (runs everything)
# Triggered automatically on push to main/develop
```

### CI/CD Pipeline

The repository runs a comprehensive CI/CD pipeline on every push:

- ✅ Rust engine — build, test, clippy
- ✅ Rust HFT engine — build, test
- ✅ Go git service — build, test, vet
- ✅ Go CLI — build, test
- ✅ Python AI service — lint, typecheck, test, integration
- ✅ Python trading — lint, test, strategy verification
- ✅ Rails API — setup, test
- ✅ Integration tests — cross-service validation
- ✅ Docker build — all services containerized
- ✅ Kubernetes deploy — production orchestration

---

## 🤝 Contributing

We welcome contributions. Please review:

1. [GOVERNANCE.md](./GOVERNANCE.md) — How decisions are made
2. [SECURITY.md](./SECURITY.md) — Security policies
3. [AGENTS.md](./AGENTS.md) — Agent development guidelines

---

## 📄 License

[MIT License](./LICENSE) — Copyright © 2026

---

<p align="center">
  <img src="./assets/logo.svg" alt="PARRALAX" width="400"/>
</p>

<p align="center">
  <strong>Built for sovereignty. Engineered for execution. Powered by intelligence.</strong>
</p>

<p align="center">
  <sub>PARRALAX-AIHFTFUND — Sovereign AI-Native Financial Infrastructure</sub>
</p>
