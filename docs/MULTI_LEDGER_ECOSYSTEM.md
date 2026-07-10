# PARALLAX Multi-Ledger Ecosystem

PARALLAX is moving from a wallet-only surface into a multi-ledger AI-agent economy.

This layer defines how AI agents, paper/testnet assets, internal credits, settlement paths, and proof receipts operate across multiple ledger authorities without pretending the alpha has live money movement.

## Source of truth

```text
config/ledgers/parallax.multiledger.ecosystem.json
```

## Ledger classes

| Ledger | Mode | Purpose |
|---|---:|---|
| `parallax-paper-ledger` | paper | simulated balances, paper orders, paper transfers, alpha settlement receipts |
| `icp-local-ledger` | testnet | ICP local/test canister integration for wallet, receipt, governance, and settlement contracts |
| `ethereum-testnet-ledger` | testnet | EVM testnet contracts and adapter experiments |
| `agent-credit-ledger` | paper | internal credits for agent work, research minting, compute, and proof artifacts |

## Agent wallet classes

| Class | Purpose | Ledgers |
|---|---|---|
| `agent-operator-wallet` | agent proposes orders, transfers, governance-reviewed actions | paper, ICP test/local |
| `agent-research-wallet` | agent mints research artifacts and proof objects | agent-credit, paper |
| `agent-strategy-wallet` | agent proposes strategy simulations and paper trades | paper, Ethereum testnet |

## Settlement paths

### Paper order to receipt

```text
ai-wallet-service
-> risk-policy-gate
-> matching-engine
-> clearinghouse-service
-> receipt-ledger
```

### Agent credit mint

```text
research-mint-service
-> agent-credit-ledger
-> receipt-ledger
-> proof-room
```

### Testnet contract experiment

```text
chain-adapter-service
-> risk-policy-gate
-> ethereum-testnet-ledger
-> receipt-ledger
```

## Alpha gates

The multi-ledger ecosystem is only valid when these gates hold:

- no live money movement,
- no live broker routing,
- no mainnet bridge in alpha,
- all agent commands are policy evaluated,
- all state transitions emit receipts,
- edge gateway auth is required for mutation,
- tunnel origin is locked down,
- public claims match evidence.

## Product meaning

This becomes the economic backbone of PARALLAX:

```text
AI Agent
-> AI Wallet
-> Ledger Authority
-> Risk Policy Gate
-> Settlement Path
-> Receipt Ledger
-> Proof Room
```

The product can showcase:

- AI agents with wallets,
- internal credit movement,
- paper trades,
- testnet adapter readiness,
- receipt-backed settlement,
- operator-governed execution,
- Cloudflare edge access.

## Not alpha-allowed

Do not claim or enable:

- real user funds,
- live broker routing,
- mainnet bridge,
- bank or money transmitter status,
- guaranteed settlement,
- security-token sale,
- externally audited status.

## Next implementation gates

1. Render ledgers and token classes in the Control Tower.
2. Store the multi-ledger manifest in the backend authority layer.
3. Pipe Cloudflare Worker `/v1/ledgers` into the frontend.
4. Add canister-backed ledger state.
5. Add receipt export for every ledger mutation.
6. Add agent-credit issuance receipts.
7. Add testnet contract adapter receipts.
