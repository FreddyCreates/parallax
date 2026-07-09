# 🔒 Trust Boundaries

> Security model, custody assumptions, and trust boundaries for the PARALLAX Exchange Clearinghouse.

---

## Overview

PARALLAX operates as a **non-custodial decentralized exchange** on the Internet Computer Protocol. Understanding trust boundaries is critical for users, developers, and liquidity providers interacting with the system.

---

## Trust Model Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TRUST BOUNDARY MAP                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  USER LAYER (You control)                                           │
│  ├── Internet Identity / Principal ID                               │
│  ├── Wallet balances (on-canister)                                  │
│  └── Order placement decisions                                      │
│                                                                     │
│  ─────────── Trust Boundary ───────────                             │
│                                                                     │
│  PROTOCOL LAYER (Canister code — verifiable, deterministic)         │
│  ├── Order matching engine (phantom_exchange.mo)                    │
│  ├── Settlement & netting (phantom_clearinghouse.mo)                │
│  ├── Token factory & balances (token_factory.mo)                    │
│  └── AI artifact registry (ai_artifact_registry.mo)                 │
│                                                                     │
│  ─────────── Trust Boundary ───────────                             │
│                                                                     │
│  INFRASTRUCTURE LAYER (ICP subnet consensus)                        │
│  ├── Subnet replication (13-node BFT consensus)                     │
│  ├── Canister execution (deterministic Wasm)                        │
│  ├── Orthogonal persistence (automatic state management)            │
│  └── Chain-key cryptography (threshold ECDSA/EdDSA)                 │
│                                                                     │
│  ─────────── Trust Boundary ───────────                             │
│                                                                     │
│  EXTERNAL LAYER (Third-party chains)                                │
│  ├── Bitcoin (ckBTC bridge — threshold signatures)                  │
│  ├── Ethereum (ckETH bridge — chain-key crypto)                     │
│  └── Future bridges (trust varies by implementation)                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## What You Trust

### 1. Internet Computer Protocol (ICP Subnet)
- **Consensus**: 13+ node BFT consensus per subnet
- **Determinism**: Canister code executes identically on all replicas
- **Persistence**: State is replicated; no single point of failure
- **Upgrades**: Canister controllers can upgrade code (see Governance below)

### 2. Canister Code (Verifiable)
- All PARALLAX canisters are written in **Motoko** (compiled to Wasm)
- Source code is open on GitHub — anyone can audit
- Canister Wasm hash can be verified against source compilation
- Matching engine logic is deterministic and reproducible

### 3. Chain-Key Bridges (ckBTC, ckETH)
- Operated by the **NNS** (Network Nervous System) — ICP's decentralized governance
- Threshold-signature cryptography (no single custodian)
- Bridge security is bounded by ICP subnet consensus assumptions

### 4. The PARALLAX Organism (Protocol Team)
- Currently controls canister upgrade keys
- Publishes all code changes publicly before deployment
- Path to decentralization via SNS (see [Roadmap](./ROADMAP.md))

---

## What You Do NOT Trust

| Component | Why It's Trustless |
|-----------|-------------------|
| Gas fee payment | Protocol pays all canister cycles — user never pays |
| Order matching | Deterministic price-time priority — no MEV, no front-running |
| Settlement | Automatic every 873ms — no manual intervention |
| Balance custody | Balances live in canister memory, controlled by your principal |
| Counterparty risk | Central counterparty guarantee — protocol is counterparty |

---

## Custody Model

### Your Assets
- **Deposited assets** are held in PARALLAX canisters, accessible only via your Internet Identity principal
- **No third-party custody** — the canister code is the custodian
- **Withdrawal** is permissionless — you can withdraw at any time without approval

### Canister-Level Security
- Canisters can only be upgraded by designated controllers
- Controller key management follows multi-sig patterns
- Future: SNS governance will control canister upgrades

---

## MEV Protection

PARALLAX has **structural MEV protection**:

1. **No mempool** — ICP canisters process messages in consensus-determined order
2. **No front-running** — validators cannot reorder within a block
3. **Deterministic matching** — same inputs always produce same outputs
4. **Batch settlement** — all trades in a heartbeat settle simultaneously

---

## Upgrade Trust & Governance Path

### Current State (Pre-SNS)
- Protocol team holds canister controller keys
- All upgrades are published on GitHub before deployment
- Community can audit any proposed change

### Future State (Post-SNS)
- Canister control transfers to SNS DAO
- Token holders vote on all upgrades
- No single party can modify protocol unilaterally
- See [Roadmap](./ROADMAP.md) for timeline

---

## Attack Surface & Mitigations

| Attack Vector | Mitigation |
|---------------|------------|
| Canister exploit | Open-source audit, deterministic Wasm, subnet consensus |
| Bridge failure (ckBTC/ckETH) | NNS-governed threshold signatures, ICP consensus |
| Controller key compromise | Multi-sig, future SNS transfer |
| ICP subnet failure | 13-node BFT; subnet would need >1/3 malicious nodes |
| Frontend compromise | Frontend is convenience layer; canister is source of truth |
| Oracle manipulation | No external oracles for core matching — purely on-chain order book |

---

## Recommendations for Users

1. **Verify canister IDs** before interacting — confirm against official sources
2. **Use Internet Identity** with hardware security keys for maximum security
3. **Start with small amounts** to test the system before committing significant capital
4. **Monitor GitHub** for canister upgrade announcements
5. **Understand bridge risks** — ckBTC/ckETH have different trust assumptions than native ICP

---

## Audit Status

| Component | Status | Notes |
|-----------|--------|-------|
| Core matching engine | Internal review | Community audit planned |
| Settlement logic | Internal review | Community audit planned |
| Token factory | Internal review | — |
| Frontend | N/A | Not security-critical (canister is truth) |
| ckBTC/ckETH bridges | DFINITY-audited | Part of ICP infrastructure |

---

*Security is not a feature — it's the foundation. Verify, don't trust.*
