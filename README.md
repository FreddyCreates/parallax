<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/parallax-logo.svg">
  <source media="(prefers-color-scheme: light)" srcset="assets/parallax-logo-dark.svg">
  <img alt="PARALLAX Exchange Clearinghouse" src="assets/parallax-logo.svg" width="680">
</picture>

<br />

[![CI](https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse/actions/workflows/ci.yml/badge.svg)](https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse/actions/workflows/ci.yml)
[![ICP](https://img.shields.io/badge/ICP-Motoko-29abe2?style=flat-square)](https://internetcomputer.org/)
[![Ethereum](https://img.shields.io/badge/Ethereum-Solidity-627EEA?style=flat-square)](contracts/)
[![React](https://img.shields.io/badge/Frontend-React_19-61DAFB?style=flat-square&logo=react&logoColor=black)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/Language-TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Research](https://img.shields.io/badge/Research-Receipts_+_Charters-8B5CF6?style=flat-square)](research/)

# PARALLAX

### AI-native financial infrastructure for wallets, trading, clearing, settlement receipts, and governed multi-ledger execution.

[Platform Blueprint](docs/PARALLAX_PLATFORM_SURFACE.md) · [Architecture](#platform-architecture) · [First Vertical Slice](#first-vertical-slice) · [Repository Map](#repository-map) · [Deployment Posture](#deployment-posture)

</div>

---

<div align="center">
  <img alt="PARALLAX Platform Architecture" src="assets/parallax-platform-infographic.svg" width="100%">
</div>

---

## What PARALLAX is

**PARALLAX** is a product surface for building a paper-first, proof-forward financial operating system. The platform combines wallet operations, simulated trading, risk-gated execution, clearinghouse receipts, payment flows, research minting, and operator governance into one coherent stack.

The current posture is intentionally conservative: **paper trading, testnet contracts, simulated balances, and receipt-backed proof flows first**. Live money movement, live broker execution, custody, regulated exchange activity, and fund operations require separate legal, security, compliance, and operational readiness gates.

## Product surfaces

| Surface | Role | First usable capability |
|---|---|---|
| **Wallet** | Identity, accounts, balances, keys, ledger views | Internet Identity plus paper/testnet balances |
| **Trade** | Order ticket, books, fills, market views | Paper order entry into a real backend contract |
| **Clearinghouse** | Matching, netting, settlement records | Fill and settlement receipt generation |
| **Pay** | Transfers, requests, invoices, remittance workflows | Internal paper transfer with receipt trail |
| **AI Execution** | Signals, strategy proposals, guarded automation | Signal cards that require operator approval |
| **Research Mint** | Papers, benchmarks, artifact records | Research metadata to proof artifact receipt |
| **Proof Room** | Audit exports, release manifests, Merkle records | Query and export receipts |
| **Governance** | Roles, policies, emergency halt, upgrade posture | Admin halt/resume and role-gated actions |

## Platform architecture

```mermaid
flowchart TD
    A[Apps: Web Control Tower / Mobile Wallet / Desktop Operator / API] --> B[Application Services]
    B --> C[Wallet Service]
    B --> D[Trading Service]
    B --> E[Payment Service]
    B --> F[Research Mint]
    C --> G[Risk + Policy Gate]
    D --> G
    E --> G
    F --> G
    G --> H[Order Matching + Transfer Engine]
    H --> I[Clearinghouse + Paper Ledger]
    I --> J[Receipt Ledger]
    J --> K[Proof Room + Audit Export]
    I --> L[ICP Canisters]
    I --> M[Ethereum/Testnet Contracts]
    I --> N[Future Chain Adapters]
```

## First vertical slice

Build one undeniable product loop before expanding the system:

```text
Wallet Login -> Paper Order -> Risk Gate -> Match -> Settle -> Receipt -> Proof Export
```

Acceptance criteria:

- user signs in with an identity provider,
- paper balance is visible,
- order ticket submits to the backend contract,
- halted pairs reject orders,
- accepted orders emit receipts,
- matched orders emit settlement receipts,
- receipts survive reload,
- operator can export proof records,
- tests cover invalid orders, duplicate orders, unauthorized halt, halted pair rejection, full fills, partial fills, and receipt pagination.

## Runtime stack

| Layer | Current trunk | Expansion path |
|---|---|---|
| Frontend | React, TypeScript, Vite | mobile wallet, desktop operator, SDK app shells |
| Backend authority | ICP/Motoko canisters | additional canisters by surface and domain |
| Contract interface | Candid | generated bindings and typed SDKs |
| External contracts | Solidity/Ethereum testnet contracts | guarded adapters and chain-specific modules |
| Data/proof | append-only receipt records | Merkle roots, export bundles, audit manifests |
| Operators | local Docker and developer workflows | Cloudflare, observability, release gates |
| AI workers | research and simulation modules | isolated strategy workers with no direct live execution |

## Repository map

```text
apps/        product applications: web, mobile, desktop, operator surfaces
canisters/   ICP/Motoko authority, wallet, clearinghouse, ledger modules
contracts/   Ethereum/testnet contracts and external chain adapters
packages/    shared SDK, UI, types, receipts, policy libraries
services/    API, wallet, payment, risk, clearing, indexing services
workers/     strategy, simulation, benchmark, research, and indexing jobs
docs/        architecture, deployment, operator, protocol, and product docs
infra/       Docker, CI, Cloudflare, observability, deployment definitions
research/    whitepapers, charters, benchmark reports, release packets
```

## Contracts and command families

Every user or machine action should be represented by an explicit contract object before execution.

| Contract | Purpose |
|---|---|
| `WalletCommand` | account, identity, and balance operations |
| `TransferCommand` | internal transfer and payment intent |
| `OrderCommand` | paper/testnet order entry |
| `RiskDecision` | accepted/rejected decision with reason codes |
| `FillReceipt` | matched order record |
| `SettlementReceipt` | clearing and ledger record |
| `OperatorActionReceipt` | halt, resume, role, and policy actions |
| `ResearchArtifactReceipt` | paper, benchmark, and artifact minting record |
| `GovernancePolicy` | role, mode, and system boundary rules |
| `SystemMode` | local, paper, testnet, restricted-live, live |

## Deployment posture

| Stage | Description | Allowed actions |
|---|---|---|
| **Local** | developer machine and local canisters | paper orders, fixtures, local receipts |
| **Testnet** | public test canisters and external testnet contracts | testnet assets, demos, proof exports |
| **Closed alpha** | controlled users and operator review | paper trading, testnet transfers, research receipts |
| **Production candidate** | security, legal, compliance, and observability gate | no live funds without external validation |
| **Live** | regulated, audited, monitored, insured posture | only after complete readiness review |

## Development

```bash
git clone https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse.git
cd PARALLAX-Exchange-Clearinghouse
npm install
npm run dev
```

Docker path:

```bash
docker compose up
```

Test path:

```bash
npm test
npm run typecheck
```

> The exact commands may differ by package boundary as the monorepo is consolidated. Treat failing tests as the highest-priority product gate before adding live surfaces.

## Documentation

- [Platform Surface Blueprint](docs/PARALLAX_PLATFORM_SURFACE.md)
- [Product Architecture](docs/PRODUCT_ARCHITECTURE.md)
- [Platform Federation](docs/PARALLAX_PLATFORM_FEDERATION.md)
- [Launch Packet](docs/PARALLAX_MAJOR_RUN.md)
- [Token Registry](config/tokens/parallax.tokens.json)

## Public language boundary

Use precise language:

- AI-native financial infrastructure,
- paper-first trading surface,
- multi-ledger wallet architecture,
- receipt-backed settlement research,
- testnet-ready platform,
- governed execution layer.

Avoid unproven claims:

- guaranteed settlement,
- live HFT fund,
- production bank replacement,
- risk-free trading,
- externally audited status,
- real money movement.

## Near-term roadmap

1. **Control Tower MVP**: wallet login, paper balances, paper order, risk gate, fill receipt, proof export.
2. **Wallet + Pay MVP**: internal transfer command, simulated ledger, payment receipt, account history.
3. **Testnet contracts**: token registry, Solidity testnet deployment scripts, ICP canister interfaces.
4. **Proof Room**: receipt search, export bundles, Merkle root generation, release manifests.
5. **Research Mint**: paper metadata, benchmark packet records, artifact receipts.
6. **Operator governance**: role policy, emergency halt, upgrade checklist, compliance boundary.

## Status

PARALLAX is being consolidated into a real product platform. The immediate priority is to turn the existing research and code surfaces into a working app loop with tests, receipts, and clear deployment boundaries.

