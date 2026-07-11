#!/usr/bin/env bash
set -euo pipefail

CANISTER="${CANISTER:-ai_wallet_ledger}"
DFX_NETWORK="${DFX_NETWORK:-local}"
OWNER="$(dfx identity get-principal)"
CONTROLLER="$OWNER"

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

echo "[ai-wallet-ledger] deploying canister"
dfx deploy --network "$DFX_NETWORK" "$CANISTER"

echo "[ai-wallet-ledger] checking version"
VERSION_OUTPUT="$(call getVersion '()')"
require_contains "$VERSION_OUTPUT" "0.2.0-alpha.0" "version"

echo "[ai-wallet-ledger] creating wallet"
CREATE_OUTPUT="$(call createAiWallet "(record { agentId = \"agent.integration.001\"; displayName = \"Integration Agent Wallet\"; ownerPrincipal = principal \"$OWNER\"; controllerPrincipal = principal \"$CONTROLLER\"; mode = variant { paper }; policy = null; metadata = vec { record { \"lane\"; \"integration\" } } })")"
require_contains "$CREATE_OUTPUT" "variant { ok" "wallet creation"
WALLET_ID="$(echo "$CREATE_OUTPUT" | sed -n 's/.*walletId = "\([^"]*\)".*/\1/p' | head -n 1)"
if [[ -z "$WALLET_ID" ]]; then
  echo "FAIL: could not parse wallet id" >&2
  echo "$CREATE_OUTPUT" >&2
  exit 1
fi

echo "[ai-wallet-ledger] rendering control tower read model"
CONTROL_OUTPUT="$(call getControlTowerAiWallets '(null, opt 10)')"
require_contains "$CONTROL_OUTPUT" "$WALLET_ID" "control tower read model"

echo "[ai-wallet-ledger] testing pause gate"
PAUSE_OUTPUT="$(call pauseAiWallet "(\"$WALLET_ID\", \"integration pause\")")"
require_contains "$PAUSE_OUTPUT" "variant { ok" "pause result"
PAUSED_COMMAND_ID="cmd-paused-001"
call submitAiWalletCommand "(record { commandId = \"$PAUSED_COMMAND_ID\"; walletId = \"$WALLET_ID\"; agentId = \"agent.integration.001\"; kind = variant { order }; mode = variant { paper }; asset = \"PXICP\"; amount = 100_000_000; priceE8s = opt 10_000_000_000; counterparty = opt \"paper-market\"; requestedBy = principal \"$OWNER\"; humanApprovalId = opt \"approval-001\"; approvedBy = opt principal \"$OWNER\"; memo = opt \"paused rejection\"; createdAt = 0 })" >/dev/null
PAUSED_EVAL="$(call evaluateAiWalletCommand "(\"$PAUSED_COMMAND_ID\")")"
require_contains "$PAUSED_EVAL" "wallet_paused" "paused evaluation"

RESUME_OUTPUT="$(call resumeAiWallet "(\"$WALLET_ID\", \"integration resume\")")"
require_contains "$RESUME_OUTPUT" "variant { ok" "resume result"

echo "[ai-wallet-ledger] testing daily limit"
LIMIT_COMMAND_ID="cmd-limit-001"
call submitAiWalletCommand "(record { commandId = \"$LIMIT_COMMAND_ID\"; walletId = \"$WALLET_ID\"; agentId = \"agent.integration.001\"; kind = variant { order }; mode = variant { paper }; asset = \"PXICP\"; amount = 100_000_000_000_000; priceE8s = opt 10_000_000_000; counterparty = opt \"paper-market\"; requestedBy = principal \"$OWNER\"; humanApprovalId = opt \"approval-002\"; approvedBy = opt principal \"$OWNER\"; memo = opt \"daily limit rejection\"; createdAt = 0 })" >/dev/null
LIMIT_EVAL="$(call evaluateAiWalletCommand "(\"$LIMIT_COMMAND_ID\")")"
require_contains "$LIMIT_EVAL" "daily_limit_exceeded" "daily limit evaluation"

echo "[ai-wallet-ledger] testing live block"
LIVE_COMMAND_ID="cmd-live-001"
call submitAiWalletCommand "(record { commandId = \"$LIVE_COMMAND_ID\"; walletId = \"$WALLET_ID\"; agentId = \"agent.integration.001\"; kind = variant { order }; mode = variant { live }; asset = \"PXICP\"; amount = 100_000_000; priceE8s = opt 10_000_000_000; counterparty = opt \"paper-market\"; requestedBy = principal \"$OWNER\"; humanApprovalId = opt \"approval-003\"; approvedBy = opt principal \"$OWNER\"; memo = opt \"live block\"; createdAt = 0 })" >/dev/null
LIVE_EVAL="$(call evaluateAiWalletCommand "(\"$LIVE_COMMAND_ID\")")"
require_contains "$LIVE_EVAL" "live_mode_blocked" "live mode evaluation"
require_contains "$LIVE_EVAL" "live_money_movement_blocked" "live money movement evaluation"
require_contains "$LIVE_EVAL" "live_broker_routing_blocked" "live broker routing evaluation"
require_contains "$LIVE_EVAL" "autonomous_live_ai_trading_blocked" "autonomous live trading evaluation"

echo "[ai-wallet-ledger] testing AI signal approval to paper order"
SIGNAL_OUTPUT="$(call pipeAiSignalApprovalToPaperOrder "(\"$WALLET_ID\", \"sig-integration-001\", \"PXICP\", 100_000_000, 10_000_000_000, opt \"approval-signal-001\")")"
require_contains "$SIGNAL_OUTPUT" "variant { ok" "signal approval pipe"

echo "[ai-wallet-ledger] testing receipt pagination"
RECEIPTS_PAGE_ONE="$(call listAiWalletReceipts "(\"$WALLET_ID\", null, opt 2)")"
require_contains "$RECEIPTS_PAGE_ONE" "nextCursor" "receipt page one"
RECEIPTS_GLOBAL="$(call listGlobalReceipts '(null, opt 10)')"
require_contains "$RECEIPTS_GLOBAL" "$WALLET_ID" "global receipts"

echo "[ai-wallet-ledger] testing halt gate"
HALT_OUTPUT="$(call haltAiWallet "(\"$WALLET_ID\", \"integration halt\")")"
require_contains "$HALT_OUTPUT" "variant { ok" "halt result"
HALTED_COMMAND_ID="cmd-halted-001"
call submitAiWalletCommand "(record { commandId = \"$HALTED_COMMAND_ID\"; walletId = \"$WALLET_ID\"; agentId = \"agent.integration.001\"; kind = variant { order }; mode = variant { paper }; asset = \"PXICP\"; amount = 100_000_000; priceE8s = opt 10_000_000_000; counterparty = opt \"paper-market\"; requestedBy = principal \"$OWNER\"; humanApprovalId = opt \"approval-004\"; approvedBy = opt principal \"$OWNER\"; memo = opt \"halted rejection\"; createdAt = 0 })" >/dev/null
HALTED_EVAL="$(call evaluateAiWalletCommand "(\"$HALTED_COMMAND_ID\")")"
require_contains "$HALTED_EVAL" "wallet_halted" "halted evaluation"

echo "[ai-wallet-ledger] recording benchmark receipt"
BENCH_OUTPUT="$(call recordBenchmark '(record { name = "policy-evaluation"; suite = "ai-wallet-ledger"; iterations = 100; totalLatencyNanos = 1000000; maxLatencyNanos = 15000; minLatencyNanos = 7000; notes = "integration synthetic benchmark receipt" })')"
require_contains "$BENCH_OUTPUT" "policy-evaluation" "benchmark receipt"

echo "PASS: AI wallet ledger integration tests completed"
