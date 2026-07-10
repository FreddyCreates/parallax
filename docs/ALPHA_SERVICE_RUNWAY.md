# PARALLAX Alpha Service Runway

This document turns the PARALLAX platform into an alpha-grade service system. It defines the service map, operator gates, build order, and readiness posture required before any public alpha claim.

## Alpha posture

PARALLAX alpha is **paper/testnet-first**.

Allowed:

- paper orders,
- simulated balances,
- testnet contracts,
- internal transfer receipts,
- research artifact receipts,
- operator-reviewed AI signals,
- receipt export,
- governance halt/resume.

Not allowed in alpha:

- live broker order routing,
- live user money movement,
- custody promises,
- production exchange claims,
- bank or money-transmitter claims,
- guaranteed settlement claims,
- unreviewed AI auto-execution.

## Service planes

| Plane | Services | Alpha objective |
|---|---|---|
| User surface | Identity Authority | identity, role, and operator context |
| Ledger | Wallet, Pay, Clearinghouse, Chain Adapter | paper/testnet balances, transfers, settlement |
| Execution | Market Data, Trading, Matching, AI Signal | paper order flow and operator-reviewed signals |
| Proof | Receipt Ledger | append-only receipts and export |
| Governance | Risk Policy Gate, Governance, Compliance Boundary | mode control, halt, disclosures, release gates |
| Research | Research Mint | papers, charters, and benchmarks as proof artifacts |
| Ops | Ops Control Plane, Notification | health, readiness, alerts, deployment posture |

## Alpha build order

### Gate 1 — Service catalog and validation

- Source of truth: `config/services/parallax.alpha.services.json`
- Validator: `scripts/validate-alpha-services.mjs`
- Frontend registry: `src/frontend/src/config/parallaxAlphaServices.ts`

Exit criteria:

- manifest parses,
- every service has contracts, capabilities, boundaries, dependencies, and exposed methods,
- all dependencies point to known services,
- required alpha gates exist.

### Gate 2 — Control Tower service status

Build the operator surface that shows:

- required services,
- optional services,
- plane grouping,
- alpha gates,
- blocked live actions,
- service dependency graph,
- receipt coverage status.

Exit criteria:

- `getAlphaReadinessSummary()` renders in the frontend,
- every alpha gate is visible,
- every service shows `purpose`, `contracts`, `dependencies`, and `mustNotDo` boundaries.

### Gate 3 — Paper order loop

Wire the first execution loop:

```text
Identity -> Wallet -> Trading -> Risk Gate -> Matching -> Clearinghouse -> Receipt Ledger -> Proof Room
```

Exit criteria:

- paper balance visible,
- paper order accepted or rejected with reason code,
- matched order emits fill receipt,
- settlement emits settlement receipt,
- halted pair rejects order,
- receipt export works.

### Gate 4 — Pay loop

Wire the first internal paper transfer loop:

```text
Identity -> Wallet -> Pay -> Risk Gate -> Clearinghouse -> Receipt Ledger
```

Exit criteria:

- sender and receiver paper accounts visible,
- transfer command previews fees/mode/risk decision,
- transfer receipt persists,
- live money movement is clearly blocked.

### Gate 5 — AI signal loop

Wire AI signal flow as a protected proposal system:

```text
Market Data -> AI Signal -> Risk Gate -> Operator Review -> Paper Order
```

Exit criteria:

- signal card has confidence and reason codes,
- operator approval is required,
- approved signal creates only paper/testnet order intent,
- rejected signal emits receipt.

### Gate 6 — Research mint loop

Wire research artifacts into the proof system:

```text
Research Paper / Charter / Benchmark -> Research Mint -> Receipt Ledger -> Proof Room
```

Exit criteria:

- artifact metadata validates,
- hash or content reference recorded,
- research receipt emitted,
- public claims boundary visible.

## Alpha contract families

| Contract | Required fields |
|---|---|
| `IdentitySession` | principal, role, session status, created time |
| `WalletAccount` | account id, owner principal, network mode, balances |
| `TransferCommand` | source, destination, asset, amount, mode, memo |
| `OrderCommand` | pair, side, order type, price, quantity, time-in-force, caller |
| `RiskDecision` | decision, reason codes, policy version, evaluated state |
| `FillReceipt` | fill id, order ids, pair, quantity, price, timestamp |
| `SettlementReceipt` | settlement id, ledger deltas, mode, actor, receipt link |
| `OperatorActionReceipt` | action, actor, role, target, before, after |
| `ResearchArtifactReceipt` | artifact id, artifact type, hash/reference, issuer, timestamp |
| `ServiceHealth` | service id, status, mode, last check, dependency status |

## Service readiness rubric

| Level | Meaning |
|---|---|
| 0 | named only |
| 1 | contract defined |
| 2 | mock or fixture works |
| 3 | backend method exists |
| 4 | frontend consumes method |
| 5 | receipt emitted |
| 6 | tests cover success and failure |
| 7 | observable in Ops Control Plane |
| 8 | alpha-ready |

A service is not alpha-ready until it reaches level 8.

## Operator surfaces to build

### Alpha Ops

- service status cards,
- dependency graph,
- alpha gate list,
- blocked live-action audit,
- deployment mode banner,
- release readiness checklist.

### Wallet

- paper balances,
- testnet accounts,
- transfer preview,
- transfer receipt.

### Trade

- paper market list,
- order book,
- order ticket,
- risk decision output,
- fill receipts.

### Proof Room

- receipt search,
- receipt detail,
- export JSON,
- Merkle draft placeholder.

### Governance

- pair halt,
- system halt,
- policy list,
- operator action receipts.

## Validation commands

```bash
pnpm alpha:validate
pnpm typecheck
pnpm test
```

Alpha validation does not replace runtime tests. It ensures the service architecture remains explicit and bounded while implementation catches up.

## Next implementation slice

Build `AlphaOpsTab` in the frontend using `src/frontend/src/config/parallaxAlphaServices.ts`.

Minimum UI sections:

- Alpha readiness summary,
- required services,
- optional services,
- service plane grouping,
- alpha gates,
- blocked live actions,
- first vertical slice progress.

## Release boundary

A PARALLAX alpha release can be announced only when:

- alpha service manifest validates,
- first vertical slice works locally,
- no live money movement is enabled,
- no live broker routing is enabled,
- every state transition emits a receipt,
- README and docs state paper/testnet posture,
- failing tests are either fixed or listed as blockers.
