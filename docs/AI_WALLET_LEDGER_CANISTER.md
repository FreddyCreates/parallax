# PARALLAX AI Wallet Ledger Canister

Version: `0.2.0-alpha.0`

This is the ICP/Motoko persistence authority for PARALLAX AI-agent wallets.

## Production code boundary

This slice intentionally adds no TypeScript production code.

Implemented production code is Motoko plus a vanilla Control Tower render surface.

## Persisted records

The canister persists:

- `AiWallet`
- `AiWalletPolicy`
- `AiWalletCommand`
- `AiWalletPolicyEvaluation`
- `AiWalletReceipt`
- `AiWalletDailyUsage`
- `BenchmarkReceipt`

## Blocked capabilities

The canister and policy engine block:

- live money movement,
- live broker routing,
- custody/private keys,
- autonomous live AI trading,
- AI self-approval above threshold.

These are not comments only; they exist as reason codes and policy fields.

## Core canister path

```text
canisters/ai-wallet-ledger/src/Main.mo
```

## Deploy

```bash
dfx deploy ai_wallet_ledger
```

Root script:

```bash
pnpm icp:ai-wallet:deploy
```

## Integration tests

```bash
bash canisters/ai-wallet-ledger/tests/integration.sh
```

Root script:

```bash
pnpm icp:ai-wallet:test
```

Coverage:

- wallet creation,
- Control Tower read model,
- pause rejection,
- resume,
- daily limit rejection,
- live mode rejection,
- AI signal approval to policy-gated paper order,
- wallet receipt pagination,
- global receipt pagination,
- halt rejection,
- benchmark receipt recording.

## Control Tower read model

The canister exposes:

```motoko
getControlTowerAiWallets(cursor : ?Nat, limit : ?Nat)
```

This returns wallet records directly from stable canister state.

## AI signal to paper order

The canister exposes:

```motoko
pipeAiSignalApprovalToPaperOrder(walletId, signalId, asset, amount, priceE8s, humanApprovalId)
```

This creates a paper order command, evaluates it through policy, emits a receipt, and updates daily usage only if approved.

## Global receipt ledger path

The canister exposes:

```motoko
listGlobalReceipts(cursor : ?Nat, limit : ?Nat)
```

All AI wallet creation, evaluation, pause, resume, halt, and benchmark actions can produce receipt records.

## Benchmark receipts

The canister exposes:

```motoko
recordBenchmark(input)
listBenchmarks(cursor, limit)
```

Benchmark numbers must be recorded after real local or CI runs. The repo includes a baseline benchmark contract, not a performance claim.

## Showcase status

This slice is backend-foundation-ready. It is not full showcase-ready until:

1. the Motoko canister compiles and deploys in CI/local,
2. integration tests pass against local dfx,
3. Control Tower read model renders real wallets,
4. AI signal-to-order flow emits receipts,
5. receipt pagination is visible in the product UI.
