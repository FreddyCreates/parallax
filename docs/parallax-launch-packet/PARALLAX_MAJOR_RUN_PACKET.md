# PARALLAX Major Run Packet

Generated: 2026-07-09 UTC

## Activated Internal Brains

CODEX, ABSB, STRU, RTMX, PHAI, TEST, BENC, SUIT, PORT, SIGNAL, LAWX, WRLD, SUCC, SACE.

## Connected Surface Interpretation

PARALLAX is already shaped as an ICP/Motoko sovereign exchange and clearinghouse with a React/TypeScript frontend. The next build should not flatten ICP, Ethereum, wallets, payments, trading, and AI assets into one undifferentiated app. The correct pattern is sovereign state authority plus bounded ledger adapters.

## Frequency / Pressure Read

The pressure is expansion pressure: tests are reportedly failing while the platform needs tokens, wallet, multi-ledger transfer, trading, and documentation. The coherence move is to separate immediate test repair from architecture expansion. Tests need reproducible logs or clone access. Platform expansion can proceed through contract canon and scaffolds now.

## Test Triage

The cloud container could not clone `ItsNotAILABS/PARALLAX-Exchange-Clearinghouse` because outbound GitHub clone returned `CONNECT tunnel failed, response 403`. The GitHub connector could still inspect files.

Likely repo commands:

```bash
cd src/frontend && pnpm test
cd src/frontend && pnpm typecheck
cd src/frontend && pnpm check
cd src/backend && mops check --fix
cd src/backend && mops build
pnpm build
```

Most likely failure surfaces:

- Generated Candid bindings drift from React tab usage.
- Vitest lacks mocked DFINITY actor/auth state.
- Biome flags generated or imported frontend files.
- Motoko domain imports or orthogonal persistence shapes drift as backend domains expand.
- `pnpm bindgen` fails when `src/backend/dist/backend.did` is missing.

Next concrete repair gate: provide CI logs, allow clone access, or paste failing command output.

## Platform Charter

PARALLAX is a sovereign exchange and clearinghouse platform that unifies AI assets, tokenized compute, crypto assets, wallet identity, money transfer, trading, and settlement under one authority-preserving runtime.

Motoko canisters on ICP own durable state, identity gates, ledger intent, settlement adjudication, token factory policy, and final commit. Bridge runtimes transport and validate. External ledgers execute only through adapter contracts. Frontend surfaces never become settlement authority.

## Token Classes

- `PXICP`: ICP-native platform utility token for fees, routing priority, and governance staking.
- `PXAI`: AI artifact and model marketplace unit.
- `PXGPU`: compute-time claim token.
- `PXUSD`: stable transfer accounting unit, adapter-backed and not production-ready until reserve, compliance, and issuer paths are settled.
- `PXETH`: Ethereum adapter representation, bridge-controlled and not sovereign truth.

## Multi-Ledger Architecture

| Layer | Owner | Authority |
| --- | --- | --- |
| ICP canister core | Motoko | Durable truth, identity, settlement adjudication |
| Bridge runtime | TypeScript / Node or Python | Transport, queues, retries, adapter calls, validation |
| Ethereum adapter | TypeScript + EVM libraries | External transaction preparation and observation |
| Wallet surface | React / TypeScript | User intent and display only |
| Trading surface | React / TypeScript | Order intent and market data display |
| Proof/audit layer | Schemas + receipt chain | Replay, provenance, traceability |

Runtime flow:

1. Wallet signs or authenticates session.
2. User submits transfer, token, or order intent.
3. Frontend sends normalized intent to ICP canister or bridge ingress.
4. Motoko records authoritative intent with `trace_id`, `intent_id`, `principal`, `state_snapshot_hash`, and policy status.
5. Bridge dispatches approved work to the relevant ledger adapter.
6. Adapter returns result with finality/proof metadata.
7. Bridge validates replay, idempotency, schema shape, and provenance.
8. Motoko adjudicates and commits final state or quarantines the result.
9. Receipt chain records user-visible proof.

## Wallet, Trading, Transfer App

First screen should be the usable PARALLAX console, not a marketing page:

- left rail: Wallet, Trade, Transfer, Assets, Clearinghouse, Receipts, Admin
- top status: identity, network, canister status, bridge status, risk mode
- main panel: selected workflow
- right panel: balances, open orders, pending transfers, recent receipts

Wallet workflows:

- connect Internet Identity
- connect Ethereum wallet
- view ICP, ckBTC, ckETH, PXICP, PXAI, PXGPU, PXUSD, PXETH
- show custody mode per balance
- show pending settlement holds
- show receipts and proofs

Trading workflows:

- market selector
- order book
- limit / market / protected swap intent
- estimated route and settlement venue
- pre-trade risk gate
- order submission
- fill receipt

Money transfer workflows:

- choose source asset and chain
- enter recipient principal or address
- validate recipient format
- estimate route, fee, time, and finality
- submit transfer intent
- display status: authorized, submitted, observed, settled, quarantined

## Chain Adapter Contract

Required capabilities:

- `chain_id`
- `adapter_id`
- `supported_assets`
- `custody_modes`
- `finality_rule`
- `estimate_fee`
- `validate_address`
- `prepare_transfer`
- `submit_transaction`
- `observe_transaction`
- `decode_event`
- `build_provenance`

Hard rules:

1. Adapters may not mutate Motoko state.
2. Adapters must include `trace_id`, `intent_id`, `adapter_id`, `idempotency_key`, and `observed_at`.
3. Adapters must reject expired intents.
4. Adapters must not convert pending external events into settled PARALLAX state.
5. Adapters must make finality criteria explicit.
6. Adapters must be pausable by sovereign policy.

## Custody Boundary

Custody modes:

- `non_custodial`: user wallet signs directly.
- `canister_vault`: ICP canister-controlled asset custody.
- `adapter_escrow`: external ledger escrow controlled by an adapter policy.
- `observed_only`: PARALLAX tracks external state but does not custody.

Quarantine conditions:

- mismatched amount
- mismatched asset
- stale state snapshot
- duplicate idempotency key
- duplicate completion token
- unknown chain id
- unsupported custody mode
- finality not reached
- adapter signature invalid
- principal or address mismatch

## Test + Benchmark Matrix

| Surface | Test | Expected Result |
| --- | --- | --- |
| Schema | missing `trace_id` | rejects |
| Schema | invalid custody mode | rejects |
| Replay | duplicate completion token | only first valid completion adjudicates |
| Replay | duplicate idempotency key with different payload | quarantines |
| Replay | stale `state_snapshot_hash` | rejects before adapter dispatch |
| Adapter | timeout | remains pending or quarantines by timeout policy |
| Adapter | insufficient Ethereum confirmations | does not settle |
| Wallet | invalid principal | blocks submission |
| Wallet | invalid Ethereum address | blocks submission |
| Trading | market order with no liquidity | rejects |
| Trading | stale price route | requotes |
| Clearinghouse | settlement evidence conflicts with Motoko state | quarantines |

## Native Suite Opportunity

This packet becomes the shared contract canon for:

- PARALLAX exchange console
- token factory
- multi-ledger wallet
- money transfer app
- bridge runtime
- clearinghouse proof suite
- research and governance documents

## Proof Signal

Every ledger action must carry `trace_id`, `intent_id`, `idempotency_key`, `state_snapshot_hash`, adapter provenance, finality rule, and receipt output. Production claims require tests for replay, duplicate callback, stale state, malformed adapter output, timeout, and quarantine.

## Monitor Next

1. Reproduce failing tests from clone or CI logs.
2. Add these packet files to repo docs.
3. Wire token registry seed into token factory read path.
4. Add adapter interfaces under a bridge/runtime package.
5. Build wallet/trading/transfer console against typed intents.
6. Add replay/idempotency/quarantine tests before enabling Ethereum or stable transfer flows.
