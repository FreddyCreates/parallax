# PARALLAX AI Agent Token Economics

PARALLAX token economics start as internal accounting, testnet assets, and receipt-backed credits.

This is not a public token sale, not a bank product, not a custody product, and not live money movement. It is the alpha economic design for AI-agent work, paper trading, compute accounting, and research proof.

## Source of truth

```text
config/tokenomics/parallax.agent-tokenomics.json
```

## Token classes

| Symbol | Class | Mode | Purpose |
|---|---|---:|---|
| `PXUSD` | paper stable unit | paper | simulated unit of account for paper trading and transfers |
| `PXICP` | ICP test unit | testnet | ICP canister and ledger integration experiments |
| `PXETH` | EVM test unit | testnet | Ethereum testnet adapter experiments |
| `PXAI` | agent work credit | paper | internal accounting for agent work and research minting |
| `PXGPU` | compute credit | paper | internal compute budget for simulations and native worker runs |
| `PXCRED` | receipt credit | paper | receipt-backed internal credit for tasks, artifacts, and governance work |

## Economic loops

### Agent work to credit

```text
Agent task
-> operator policy
-> receipt ledger
-> PXCRED internal credit
```

### Compute to PXGPU burn

```text
Simulation/native worker run
-> compute budget check
-> PXGPU burn
-> benchmark receipt
```

### Research mint to PXAI

```text
Research artifact
-> artifact hash
-> claim boundary check
-> research receipt
-> PXAI internal work unit
```

### Paper trade to settlement

```text
AI wallet command
-> risk decision
-> paper match
-> settlement receipt
```

## Governance rules

- Tokens are alpha internal or testnet only.
- Agent wallets cannot self-approve above threshold.
- Receipt ledger is the source of truth for internal credit mints.
- Mainnet or live economic claims require a new governance gate.
- Public language must state no real money movement in alpha.

## Product-facing language

Use:

- internal agent credits,
- paper/testnet token economics,
- receipt-backed work units,
- compute accounting,
- AI-agent wallet economy,
- governed settlement research.

Avoid:

- investment token,
- guaranteed yield,
- bank replacement,
- live stablecoin,
- redeemable asset,
- public security token,
- real cash movement.

## Next gates

1. Add token economics to the Control Tower.
2. Add operator controls for internal credit issuance.
3. Add receipt-backed PXAI/PXGPU/PXCRED mint and burn events.
4. Add simulation statements for agent PnL without claiming live results.
5. Add canister interface for token class registry.
6. Add Worker routes for token class lookup and policy checks.
