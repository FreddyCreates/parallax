# PARALLAX AI Wallet Alpha

This document defines the first real PARALLAX wallet layer for AI agents.

The AI wallet is not a scaffold. It is a domain package with typed contracts, policy evaluation, command builders, receipt generation, and tests. It is still alpha-gated: paper/testnet only until custody, audit, compliance, and backend persistence gates are complete.

## Purpose

AI wallets let approved agents hold controlled paper/testnet balances, propose orders, create internal transfer intents, and register research mint actions without giving an AI unrestricted custody or live execution power.

## Package

```text
src/ai-wallet/
```

Package name:

```text
@parallax/ai-wallet
```

Validation command:

```bash
pnpm alpha:wallet
```

## What is implemented

| Capability | Status |
|---|---|
| deterministic AI wallet creation | implemented |
| policy-gated command evaluation | implemented |
| paper/testnet mode enforcement | implemented |
| live mode blocking | implemented |
| asset allowlists | implemented |
| counterparty allowlists | implemented |
| command notional limits | implemented |
| daily notional limits | implemented |
| human approval thresholds | implemented |
| command builders | implemented |
| receipt factory | implemented |
| receipt chain verifier | implemented |
| unit tests | implemented |
| canister persistence | next gate |
| global receipt ledger integration | next gate |
| frontend AI wallet tab | next gate |

## Contract model

### `AiWallet`

Represents a wallet assigned to an AI agent.

Required fields:

- `id`
- `agentId`
- `displayName`
- `ownerPrincipal`
- `controllerPrincipal`
- `status`
- `mode`
- `policy`
- `balances`
- `createdAt`
- `updatedAt`
- `metadata`

### `AiWalletPolicy`

Controls what the AI wallet may do.

Policy fields include:

- allowed modes,
- allowed command kinds,
- allowed assets,
- allowed counterparties,
- maximum command notional,
- daily notional limit,
- human approval threshold,
- command kinds requiring human approval,
- scopes,
- live-mode block flag.

### `AiWalletCommand`

Represents a requested action before execution.

Supported command kinds:

- `transfer`
- `order`
- `research_mint`
- `approve_signal`
- `cancel_order`
- `operator_note`

### `AiWalletPolicyEvaluation`

The policy engine returns:

- decision: `approved`, `rejected`, or `requires_human_approval`,
- reason codes,
- command notional,
- projected daily notional,
- policy id and version,
- evaluation timestamp.

### `AiWalletReceipt`

Receipts are emitted for wallet creation, policy evaluation, approval, rejection, human-approval-required status, pause, and halt.

## Alpha safety boundaries

The AI wallet must not:

- custody private keys,
- move real user money,
- route live broker orders,
- approve itself above human approval threshold,
- execute live without operator approval,
- skip receipts,
- hide live-mode blocking.

## Default alpha policy

| Rule | Value |
|---|---|
| allowed modes | `paper`, `testnet` |
| blocked modes | `restricted_live`, `live` |
| allowed assets | `PXUSD`, `PXICP`, `PXAI`, `PXGPU`, `PXETH` |
| allowed counterparties | `internal`, `paper-market`, `research-mint`, `operator` |
| max command notional | 10,000 |
| daily notional limit | 50,000 |
| human approval threshold | 2,500 |

## Wallet scopes

### `paper-trade`

For paper-market orders and signal-approved orders.

Allowed command kinds:

- `order`
- `cancel_order`
- `approve_signal`

### `internal-pay`

For internal paper/testnet transfers.

Allowed command kinds:

- `transfer`

### `research-mint`

For research artifact receipts.

Allowed command kinds:

- `research_mint`
- `operator_note`

## First backend integration gate

The next canister work should persist:

```text
AiWallet
AiWalletPolicy
AiWalletCommand
AiWalletPolicyEvaluation
AiWalletReceipt
AiWalletDailyUsage
```

Minimum canister methods:

```text
createAiWallet(input)
getAiWallet(walletId)
listAiWallets(ownerPrincipal)
evaluateAiWalletCommand(command)
appendAiWalletReceipt(receipt)
getAiWalletReceipts(walletId, cursor)
pauseAiWallet(walletId)
haltAiWallet(walletId)
```

## First frontend integration gate

Build an `AI Wallets` surface inside the Control Tower.

Minimum sections:

- AI wallet list,
- wallet status,
- policy summary,
- balances,
- command preview,
- policy decision output,
- reason codes,
- receipt chain,
- live-mode blocked banner.

## First product loop

```text
Create AI Wallet
-> Assign paper/testnet policy
-> Agent proposes command
-> Policy evaluates command
-> Human approval required if threshold is crossed
-> Receipt emitted
-> Approved paper command routes to trading/pay/research flow
```

## Production meaning

For alpha, "production ready" means the wallet rules are explicit, typed, testable, and enforced before integration. It does not mean live custody or real money movement is enabled.

The wallet becomes live-production eligible only after:

- security review,
- custody model review,
- legal/compliance review,
- canister persistence tests,
- receipt-ledger integration,
- operator halt tests,
- external audit or equivalent review,
- deployment runbook approval.
