# PARALLAX Platform Federation

Generated: 2026-07-09 UTC

## Purpose

This document combines the discovered Parallax surfaces into one platform architecture. The consolidation trunk is `ItsNotAILABS/PARALLAX-Exchange-Clearinghouse`. The sibling surfaces become engines, packages, adapters, or governance inputs instead of competing trunks.

## Discovered Surfaces

| Surface | Repository | Role In Unified Platform |
| --- | --- | --- |
| PARALLAX Exchange Clearinghouse | `ItsNotAILABS/PARALLAX-Exchange-Clearinghouse` | ICP/Motoko exchange, token factory, clearinghouse, wallet/trading frontend, settlement authority |
| PARRALAX AIHFTFUND | `ItsNotAILABS/PARRALAX-AIHFTFUND` | financial execution infrastructure, AI trading engines, HFT execution, risk, fund operations, APIs, multi-market strategy |
| Chimeria Defense | `ItsNotAILABS/Chimeria` | defense organism, compliance controls, cryptographic posture, access hierarchy, organism security doctrine |
| CloudColony research/token surfaces | `ItsNotAILABS/cloudcolony` PR evidence | research minting, computation token vault, permanent ownership records, IP chain, citation economy |
| PRODUCTION release surfaces | `ItsNotAILABS/PRODUCTION-` PR evidence | release ledger, Zenodo/publication pipeline, SDKs, dashboards, proof packaging |

## Trunk Decision

The exchange clearinghouse repo should become the main PARALLAX product trunk because it already owns ICP/Motoko backend, exchange and clearinghouse domains, token factory, wallet/trading tabs, public docs, and DFINITY frontend bindings.

AIHFTFUND should not replace it. AIHFTFUND should feed strategy, execution, quantitative, risk, and fund-operation engines into the clearinghouse.

## Whole Platform Shape

PARALLAX becomes seven coordinated product planes:

1. Wallet and identity plane
2. Trading and exchange plane
3. Clearinghouse and ledger plane
4. AI execution and fund operations plane
5. Research/IP tokenization plane
6. Defense, compliance, and access plane
7. Proof, release, and certification plane

## Module Merge Map

| Incoming Surface | Extract | Target In Exchange Clearinghouse |
| --- | --- | --- |
| AIHFTFUND | Rust HFT execution model | `services/execution-engine/` later, bridge-gated |
| AIHFTFUND | Python quantitative engines | `services/ai-service/` or external compute engine |
| AIHFTFUND | fund operation dashboard concepts | `src/frontend/src/tabs/FundOpsTab.tsx` |
| AIHFTFUND | regulatory boundary matrix | `docs/compliance/` |
| Chimeria | compliance control posture | `docs/security/CHIMERIA_SECURITY_MODEL.md` |
| Chimeria | access hierarchy | wallet/admin role model |
| Chimeria | post-quantum and crypto posture | proof and custody security roadmap |
| CloudColony | research mint | `src/backend/research_mint.mo` or separate canister |
| CloudColony | computation vault | AI artifact ownership and receipt chain |
| PRODUCTION | release ledger | `docs/proof/RELEASE_LEDGER.md` |

## Platform Runtime

```text
User / Operator
  -> React Platform Console
  -> Motoko canister authority
  -> bridge runtime
  -> ledger adapters / execution engines / AI engines
  -> Motoko adjudication
  -> receipt chain
  -> proof and release ledger
```

## Product Tabs

The platform console should expose Wallet, Trade, Transfer, Markets, Clearinghouse, AI Execution, Fund Ops, Research Mint, Receipts, Risk, Compliance, and Admin.

## Vertical Slices

1. `Identity -> Wallet -> Internal transfer -> Ledger journal -> Receipt -> Clearinghouse view`
2. `Trade intent -> Risk gate -> Order book -> Fill -> Settlement hold -> Receipt`
3. `AI signal -> Risk gate -> Protected order intent -> Human/Policy approval -> Execution receipt`
4. `Research packet -> IP hash -> token mint intent -> registry entry -> citation receipt`

## Defense Layer From Chimeria

Chimeria contributes no-drop security posture, compliance immutability, anti-exfiltration gates, access hierarchy, coherence-gated coupling, and immutable audit trail.

In PARALLAX, this becomes adapter pause controls, custody risk tiering, admin access roles, audit receipt immutability, compliance mode per product surface, and model/agent approval gates.

## Production Upgrade Path

1. Import this federation map into the PR.
2. Convert platform manifest into frontend navigation and route metadata.
3. Add internal wallet transfer slice with ledger journal.
4. Add paper trading slice with clearinghouse receipt.
5. Add AIHFTFUND engine adapter as read-only signal provider.
6. Add Research Mint as artifact-token module.
7. Add Chimeria security/compliance gates around adapters.
8. Add release/proof ledger from PRODUCTION patterns.

## Proof Rule

No platform surface is production until it has typed intent, idempotency key, state snapshot hash, custody mode, risk tier, receipt id, audit proof, replay test, and quarantine path.
