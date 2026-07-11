# PARALLAX Universal Trading Launch Platform

Version: `0.4.0-alpha.0`

This slice turns PARALLAX from an ICP-only exchange foundation into a multi-chain launch platform surface for public wallets, broad asset discovery, paper/testnet trading routes, and policy-gated finance agents.

## What this is

A production-facing launch shell for:

- EVM chains: Ethereum, Base, Arbitrum, Optimism, Polygon, BNB Chain, Avalanche, Linea;
- Solana;
- Bitcoin read/sign-message routes;
- Cosmos / Osmosis / Injective;
- Sui;
- Aptos;
- Polkadot;
- TRON;
- ICP.

## What this is not yet

This is not a live exchange launch approval.

Blocked until gates pass:

- live money movement;
- broker routing;
- custody/private-key handling;
- autonomous live AI trading;
- mainnet route execution;
- public central-counterparty guarantee claims.

## Public wallet posture

PARALLAX integrates external wallets only. Users sign inside their own wallet. PARALLAX must never ask for:

- private keys;
- seed phrases;
- mnemonics;
- custody credentials.

Initial wallet registry:

- MetaMask;
- WalletConnect / Reown AppKit path;
- Coinbase Wallet;
- Phantom;
- Rabby;
- Rainbow;
- Trust Wallet;
- Ledger;
- OKX Wallet;
- Binance Wallet;
- Backpack;
- Solflare;
- Keplr;
- Leap;
- Xverse;
- UniSat;
- Plug;
- Stoic;
- NFID.

## Front-end surface

```text
apps/universal-trading/index.html
apps/universal-trading/app.js
apps/universal-trading/styles.css
```

The launch surface detects injected EVM wallets, EIP-6963 providers, Phantom/Solana providers, and Plug ICP providers where available. The route preview queues only a paper route.

## Registries

```text
config/chains/parallax.chain-registry.json
config/wallets/parallax.wallet-registry.json
config/assets/parallax.launch-asset-universe.json
config/agents/parallax.finance-agent-world.json
```

## Agent deployment world

Finance agents are allowed only in paper/testnet lanes until governance and compliance gates approve further capability.

Agent templates:

- market maker agent;
- risk sentinel agent;
- cross-chain research agent;
- liquidity router agent;
- AI artifact market analyst;
- compliance receipt auditor.

Required controls:

- AI wallet;
- AI wallet policy;
- human approval thresholds;
- global receipt ledger;
- benchmark receipts;
- operator halt.

## Validation

```bash
pnpm launch:validate
```

This checks chain coverage, wallet coverage, asset coverage, agent templates, front-end IDs, wallet detection code, and blocked live-risk boundaries.

## Showcase status

This is showcase-surface-ready after static validation passes. It is not live-trading-ready until:

1. wallet connection tests pass across target browsers;
2. canister deploys pass;
3. paper/testnet route receipts are visible;
4. security review passes;
5. compliance and market-operator review passes;
6. liquidity and bridge policies are approved;
7. real benchmark receipts are recorded.
