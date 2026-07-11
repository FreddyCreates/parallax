#!/usr/bin/env bash
set -euo pipefail

CANISTER="${CANISTER:-defi_exchange}"
DFX_NETWORK="${DFX_NETWORK:-local}"

require_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: expected $label to contain $needle" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

call() {
  dfx canister --network "$DFX_NETWORK" call "$CANISTER" "$@"
}

echo "[defi-exchange] deploying canister"
dfx deploy --network "$DFX_NETWORK" "$CANISTER"

echo "[defi-exchange] checking version"
VERSION_OUTPUT="$(call getVersion '()')"
require_contains "$VERSION_OUTPUT" "0.3.0-alpha.0" "version"

echo "[defi-exchange] checking market catalog"
PAIRS_OUTPUT="$(call get_all_pairs '()')"
require_contains "$PAIRS_OUTPUT" "GTK_ICP" "sovereign market"
require_contains "$PAIRS_OUTPUT" "BTC_ICP" "crypto market"
require_contains "$PAIRS_OUTPUT" "AICPU_ICP" "AI token market"
require_contains "$PAIRS_OUTPUT" "AIMDL_MTC" "AI artifact market"
require_contains "$PAIRS_OUTPUT" "CREATOR_ICP" "creator market"

PAIR_PAGE="$(call list_pairs '(null, opt 10)')"
require_contains "$PAIR_PAGE" "nextCursor" "pair pagination"

echo "[defi-exchange] rejecting disabled planned market"
DISABLED_OUTPUT="$(call place_order '(record { pairId = "SOL_ICP"; side = variant { buy }; orderType = variant { limit }; priceE8s = opt 1_000_000; quantityE8s = 100_000; clientOrderId = opt "disabled-001"; memo = opt "disabled market" })')"
require_contains "$DISABLED_OUTPUT" "market_disabled" "disabled market rejection"

echo "[defi-exchange] rejecting invalid tick"
TICK_OUTPUT="$(call place_order '(record { pairId = "BTC_ICP"; side = variant { buy }; orderType = variant { limit }; priceE8s = opt 1_000_001; quantityE8s = 100_000; clientOrderId = opt "tick-001"; memo = opt "tick violation" })')"
require_contains "$TICK_OUTPUT" "tick_size_violation" "tick violation"

echo "[defi-exchange] placing resting sell"
SELL_OUTPUT="$(call place_order '(record { pairId = "BTC_ICP"; side = variant { sell }; orderType = variant { limit }; priceE8s = opt 4_500_000_000; quantityE8s = 200_000_000; clientOrderId = opt "sell-001"; memo = opt "resting sell" })')"
require_contains "$SELL_OUTPUT" "variant { ok" "sell order"

echo "[defi-exchange] placing crossing buy"
BUY_OUTPUT="$(call place_order '(record { pairId = "BTC_ICP"; side = variant { buy }; orderType = variant { limit }; priceE8s = opt 4_500_000_000; quantityE8s = 100_000_000; clientOrderId = opt "buy-001"; memo = opt "crossing buy" })')"
require_contains "$BUY_OUTPUT" "fills" "buy fills"
require_contains "$BUY_OUTPUT" "receiptId" "order receipt"

echo "[defi-exchange] checking order book and ticker"
BOOK_OUTPUT="$(call get_order_book '("BTC_ICP")')"
require_contains "$BOOK_OUTPUT" "BTC_ICP" "order book"
TICKER_OUTPUT="$(call get_ticker '("BTC_ICP")')"
require_contains "$TICKER_OUTPUT" "lastPriceE8s" "ticker"
TRADES_OUTPUT="$(call get_recent_trades '("BTC_ICP", 10)')"
require_contains "$TRADES_OUTPUT" "fillId" "recent trades"

echo "[defi-exchange] checking receipts"
RECEIPTS_OUTPUT="$(call list_receipts '(null, opt 20)')"
require_contains "$RECEIPTS_OUTPUT" "defi-rcpt" "receipt ledger"

echo "[defi-exchange] recording benchmark"
BENCH_OUTPUT="$(call record_benchmark '(record { name = "place-order-match"; suite = "defi-exchange"; iterations = 100; totalLatencyNanos = 1000000; maxLatencyNanos = 15000; minLatencyNanos = 7000; notes = "integration synthetic benchmark receipt" })')"
require_contains "$BENCH_OUTPUT" "place-order-match" "benchmark receipt"

echo "PASS: DeFi exchange integration tests completed"
