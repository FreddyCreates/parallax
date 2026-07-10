# PARALLAX Product Showcase Gate

This gate defines when PARALLAX is ready to show as a product surface.

## Showcase-ready means

The platform can be shown as an alpha product when it demonstrates a coherent loop:

```text
AI Agent
-> AI Wallet
-> Multi-Ledger Registry
-> Token-Economics Policy
-> Cloudflare Edge Gateway
-> Tunnel/Core Service
-> Risk Gate
-> Paper/Testnet Settlement
-> Receipt Ledger
-> Proof Export
```

## Required showcase gates

| Gate | Required evidence |
|---|---|
| Product landing surface | README and architecture docs match the current product |
| AI wallet | TypeScript package and C/C++ interface present |
| Multi-ledger registry | `config/ledgers/parallax.multiledger.ecosystem.json` validates |
| Token economics | `config/tokenomics/parallax.agent-tokenomics.json` validates |
| Cloudflare Worker | Worker package with health and registry routes exists |
| Tunnel plan | cloudflared config and Docker templates exist |
| Mutation auth | Worker requires bearer auth for mutating routes |
| Alpha safety | live/restricted-live modes rejected in edge policy |
| Native worker path | C/C++ package builds with CMake locally/CI |
| Receipt posture | every mutating product loop has a receipt requirement |
| Public boundary | no live money, broker, custody, bank, yield, or audit claims |

## Not showcase-ready until

- Worker is deployed to a Cloudflare preview or custom domain.
- Tunnel connects a private origin successfully.
- Control Tower consumes Worker routes.
- At least one paper/testnet command path produces a receipt visible in UI.
- CI passes for JS/TS, native C/C++, and product manifest validation.

## Demo story

Show this sequence:

1. Open PARALLAX Control Tower.
2. Show alpha status and public boundary.
3. Show ledgers and token classes from Worker route.
4. Create or select AI-agent wallet.
5. Submit paper/testnet command.
6. Show edge policy decision.
7. Route to core service through tunnel.
8. Show receipt and proof export.

## Current state

The repo has the product architecture, AI wallet, native interface, multi-ledger registry, token economics registry, Worker gateway, tunnel templates, and validation script.

The platform is not yet showcase-ready until live Cloudflare deployment, tunnel verification, Control Tower binding, and receipt-visible command flow are complete.
