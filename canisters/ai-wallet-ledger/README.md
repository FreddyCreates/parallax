# PARALLAX AI Wallet Ledger Canister

Production-code Motoko authority for AI wallet persistence and alpha-safe policy evaluation.

This canister persists:

- `AiWallet`
- `AiWalletPolicy`
- `AiWalletCommand`
- `AiWalletPolicyEvaluation`
- `AiWalletReceipt`
- `AiWalletDailyUsage`

It enforces alpha-blocked boundaries:

- no live money movement,
- no live broker routing,
- no custody/private-key handling,
- no autonomous live AI trading,
- no AI self-approval above threshold.

## Canister files

```text
canisters/ai-wallet-ledger/src/Main.mo
canisters/ai-wallet-ledger/src/Types.mo
canisters/ai-wallet-ledger/src/Policy.mo
canisters/ai-wallet-ledger/src/Receipts.mo
canisters/ai-wallet-ledger/src/Bench.mo
```

## Core methods

```motoko
createAiWallet(input)
getAiWallet(walletId)
listAiWallets(cursor, limit)
submitAiWalletCommand(command)
evaluateAiWalletCommand(commandId)
getAiWalletCommand(commandId)
getAiWalletEvaluation(commandId)
appendAiWalletReceipt(receipt)
listAiWalletReceipts(walletId, cursor, limit)
getAiWalletDailyUsage(walletId, day)
pauseAiWallet(walletId, reason)
resumeAiWallet(walletId, reason)
haltAiWallet(walletId, reason)
recordBenchmark(input)
getVersion()
```

## Production posture

This is alpha-production code: persistent state, explicit contracts, deterministic policy decisions, append-only receipts, and query pagination. It does not enable live funds or broker execution.
