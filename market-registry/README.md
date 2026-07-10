# PARALLAX Market Registry

Machine-readable market registry for PARALLAX Exchange.

Primary file:

```text
market-registry/parallax_markets.json
```

The registry separates live activation from documentation intent. A pair can appear in the registry as `planned` or `research` without being live on a deployed exchange canister.

## Status values

| Status | Meaning |
|---|---|
| `research` | Concept under bridge, token, governance, or risk review |
| `planned` | Intended pair or asset type awaiting implementation and activation |
| `testnet` | Implemented in local or test deployment |
| `mainnet` | Activated on mainnet canister set |
| `deprecated` | Retired or blocked from new listing |

## Required activation gates

A market is not mainnet-active until all of the following exist:

1. Backend pair registration.
2. Frontend display support.
3. Risk parameter review.
4. Liquidity and market-maker plan.
5. Deposit/withdrawal or internal-settlement route.
6. Integration tests.
7. Governance or operator approval receipt.
8. Mainnet canister release receipt.
