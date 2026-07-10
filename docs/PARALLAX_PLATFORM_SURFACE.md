# PARALLAX Platform Surface Blueprint

PARALLAX is organized as a paper-first, proof-forward financial infrastructure platform. The goal of this surface is to make the current clearinghouse, wallet, trading, research, and governance work legible as one executable product instead of a collection of isolated experiments.

## Product thesis

PARALLAX becomes a sovereign financial operating surface for:

- multi-ledger wallet operations,
- simulated and testnet trading,
- risk-gated order flow,
- clearinghouse receipts,
- research artifact minting,
- protocol governance,
- operator-grade proof export.

The platform should not present itself as a live fund, broker, bank, or production exchange until regulatory, custody, security, and external audit boundaries are complete.

## Platform surfaces

| Surface | Purpose | First build slice |
|---|---|---|
| Wallet | Identity, balances, ledger accounts, internal transfers | Internet Identity login plus paper balances |
| Trade | Order ticket, books, fills, market data | Paper order into matching engine |
| Clearinghouse | Settlement, netting, receipts, reconciliation | Fill receipt and settlement receipt log |
| Pay | Transfer, request, invoice, remittance workflow | Internal paper transfer with receipt |
| AI Execution | Signals, strategy proposals, guarded automation | Signal card that cannot execute without operator approval |
| Research Mint | Papers, benchmark artifacts, tokenized research records | Research packet metadata to receipt artifact |
| Proof Room | Audit exports, Merkle roots, release manifests | Downloadable receipt export |
| Governance | Roles, policy gates, emergency halt, upgrade posture | Admin halt/resume and role checks |

## Runtime stack

### Current trunk

- Frontend: React, TypeScript, Vite.
- Backend authority: ICP/Motoko canisters.
- Contracts: Candid interfaces and generated bindings.
- Proof records: append-only receipt records.
- Local operator mode: Docker and local development server.

### Expansion stack

- Ethereum: Solidity contracts for external token experiments and testnet adapters.
- Indexing: service worker, event indexer, and receipt pagination.
- AI workers: strategy simulation and signal generation, isolated from direct live execution.
- Monitoring: Prometheus/Grafana only after metrics are real and contract-bound.

## Repository role model

| Directory | Role |
|---|---|
| `apps/` | Product applications: web, mobile, desktop, operator surfaces |
| `canisters/` | ICP/Motoko authority and ledger canisters |
| `contracts/` | Ethereum and external chain contracts |
| `packages/` | Shared SDK, types, UI, receipts, policy libraries |
| `services/` | API, wallet, payment, risk, clearing, indexing services |
| `workers/` | Strategy, simulation, benchmark, research, and indexing jobs |
| `docs/` | Product, architecture, deployment, operator, and research documentation |
| `infra/` | Docker, CI, Cloudflare, deployment, observability, and IaC |
| `research/` | Whitepapers, charters, benchmark reports, release packets |

## Operator flows

### Paper trade to receipt

1. User signs in.
2. User selects a paper market pair.
3. User submits a paper order.
4. Risk gate evaluates role, mode, pair status, order size, and halt state.
5. Matching engine accepts, rejects, fills, or partially fills the order.
6. Clearinghouse emits order, risk, fill, and settlement receipts.
7. Proof Room displays and exports the receipt trail.

### Internal paper transfer

1. User opens Pay.
2. User selects source and destination paper accounts.
3. Transfer command enters the policy gate.
4. Ledger state updates only in paper/testnet mode.
5. Receipt is written and exportable.

### AI signal with protected execution

1. AI engine proposes a signal.
2. Signal includes confidence, reason codes, source data, and risk flags.
3. Operator reviews the signal.
4. No live execution occurs in v0.
5. Approved paper orders can be submitted through the same risk gate as manual orders.

## Contract boundary

Every command should be represented by a contract object before it reaches execution.

Required command families:

- `WalletCommand`
- `TransferCommand`
- `OrderCommand`
- `RiskDecision`
- `FillReceipt`
- `SettlementReceipt`
- `OperatorActionReceipt`
- `ResearchArtifactReceipt`
- `GovernancePolicy`
- `SystemMode`

## Deployment posture

| Stage | Description | Allowed actions |
|---|---|---|
| Local | Developer machine and local canisters | paper orders, local receipts, test fixtures |
| Testnet | Public test canisters and testnet contracts | testnet assets, public demos, exported receipts |
| Closed alpha | Controlled user access | paper trading, testnet payments, governed pilots |
| Production candidate | Security and compliance gate | no live funds without external validation |
| Live | Regulated, audited, monitored, insured posture | only after legal and operational readiness |

## First vertical slice

The next slice should be:

**Wallet login -> paper order -> risk gate -> match -> settlement receipt -> proof export**

Acceptance criteria:

- user can sign in,
- paper balance is visible,
- order ticket submits to real backend contract,
- halted pairs reject orders,
- accepted order generates a receipt,
- fill generates a settlement receipt,
- receipts survive reload,
- operator can export receipt records,
- tests cover invalid order, duplicate order, halted pair, unauthorized halt, partial fill, full fill, and receipt pagination.

## Public language boundary

Use:

- AI-native financial infrastructure,
- paper-first trading surface,
- multi-ledger wallet architecture,
- receipt-backed settlement research,
- testnet-ready platform,
- governed execution layer.

Avoid until proven:

- guaranteed settlement,
- live HFT fund,
- bank replacement,
- production exchange,
- risk-free trading,
- externally audited claims,
- real money movement.
