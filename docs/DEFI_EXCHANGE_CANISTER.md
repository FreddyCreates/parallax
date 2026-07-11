# PARALLAX DeFi Exchange Canister

Version: `0.3.0-alpha.0`

This slice converts the PARALLAX DeFi market docs into a Motoko exchange canister and market catalog.

## Production-code boundary

No TypeScript production code is added in this slice.

Implemented code is Motoko plus shell integration tests and JSON product manifests.

## What this implements

- five market categories,
- sovereign markets,
- crypto markets,
- 37 AI-token symbols,
- AI artifact markets,
- creator markets,
- disabled planned bridge pairs,
- fixed-point e8s pricing and quantities,
- price-time matching model,
- order placement,
- order cancellation,
- cancel-all,
- order book query,
- recent trades query,
- ticker query,
- receipt ledger,
- benchmark receipts.

## Canister path

```text
canisters/defi-exchange/src/Main.mo
```

## Market catalog

```text
config/markets/parallax.defi.markets.json
canisters/defi-exchange/src/Markets.mo
```

## API methods

```motoko
getVersion()
get_all_pairs()
list_pairs(cursor, limit)
get_pair(pairId)
place_order(args)
cancel_order(orderId)
cancel_all_orders(pairId)
get_order_book(pairId)
get_recent_trades(pairId, limit)
get_ticker(pairId)
get_open_orders(pairId)
get_trade_history(pairId, limit)
list_receipts(cursor, limit)
record_benchmark(input)
list_benchmarks(cursor, limit)
```

## Alpha boundaries

The exchange is alpha paper/testnet infrastructure.

Blocked:

- live money movement,
- live broker routing,
- custody/private keys,
- mainnet bridge claims without evidence,
- live central-counterparty guarantee claims.

## Market specs

| Parameter | Value |
|---|---:|
| Tick size | `0.0001` / `10_000 e8s` |
| Min order | `0.001` / `100_000 e8s` |
| Settlement interval | `873ms` |
| Max open orders | `100` per principal per pair |
| Maker fee | `0 bps` |
| Taker fee | `5 bps` |

## Deploy

```bash
dfx deploy defi_exchange
```

Root script:

```bash
pnpm defi:deploy
```

## Integration test

```bash
bash canisters/defi-exchange/tests/integration.sh
```

Root script:

```bash
pnpm defi:test
```

## Benchmark receipt

```bash
dfx canister call defi_exchange record_benchmark '(record { name = "place-order-match"; suite = "defi-exchange"; iterations = 100; totalLatencyNanos = 1000000; maxLatencyNanos = 15000; minLatencyNanos = 7000; notes = "local run" })'
```

## Showcase status

Not showcase-ready until:

1. `dfx deploy defi_exchange` passes.
2. integration test passes.
3. Control Tower renders market catalog and order book from the canister.
4. receipt pagination is visible in the UI.
5. benchmark receipts are recorded from a real run.
