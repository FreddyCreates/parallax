# PARALLAX Launch Packet

Generated: 2026-07-09 UTC

This packet starts the next PARALLAX build run: ICP token path, multi-ledger adapter law, wallet/trading/payment console, test triage, and proof gates.

## Grounded Evidence

- Root README describes PARALLAX as an ICP/Motoko exchange clearinghouse with React/TypeScript frontend, token factory, exchange, clearinghouse, AI assets, trading, docs, and notebooks.
- `src/backend/main.mo` contains live domains for `PhantomExchange`, `PhantomClearinghouse`, `TokenFactory`, `SovereignVault`, `ReceiptChain`, `PhantomKeying`, `PredictionMarket`, and `QuantTrading`.
- `src/frontend/package.json` declares React 19, Vite, TypeScript, Vitest, Biome, DFINITY libraries, Zustand, TanStack Query, Three.js, and Radix UI.
- Local test reproduction is currently blocked because the cloud container could inspect through the GitHub connector but could not clone the repo over the network.

## Files In This Packet

- `PARALLAX_MAJOR_RUN_PACKET.md`: architecture, charter, test triage, proof gates, and build sequence.
- `chain-adapter.ts`: typed adapter boundary for ICP, Ethereum, and external ledgers.
- `token-registry.seed.json`: initial token-class seed for PXICP, PXAI, PXGPU, PXUSD, and PXETH.

## Production Rule

ICP/Motoko remains the settlement authority. Ethereum, stablecoin rails, wallets, and external ledgers are adapters. They submit evidence to PARALLAX; they do not become PARALLAX truth.
