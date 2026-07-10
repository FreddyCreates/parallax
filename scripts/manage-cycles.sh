#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/manage-cycles.sh [options]
# Inspect canister identities and optionally execute a user-supplied cycles top-up template for operational maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/manage-cycles.sh [options]

Inspect canister identities and optionally execute a user-supplied cycles top-up template for operational maintenance.

Options:
  -n, --dry-run   Print the actions without executing them.
  -v, --verbose   Show each command before it runs.
  -f, --force     Allow overwriting generated artifacts when supported.
  -y, --yes       Skip confirmation prompts when supported.
  -h, --help      Show this help message.
EOF
}

parse_common_args "$@"
if (( SHOW_HELP )); then
  usage
  exit 0
fi

ensure_repo_root

ACTION="${REMAINING_ARGS[0]:-status}"
CANISTER="${REMAINING_ARGS[1]:-backend}"
AMOUNT="${REMAINING_ARGS[2]:-}"
ENVIRONMENT="${PARRALAX_CYCLES_ENVIRONMENT:-mainnet}"
require_commands icp
set_total_steps 2

step "Resolving canister identity"
CANISTER_ID="$(capture_command "icp canister settings show --environment $ENVIRONMENT --id-only $CANISTER" "cycles-placeholder-canister-id")"
log_info "Canister $CANISTER resolved to $CANISTER_ID"

step "Executing cycles action"
case "$ACTION" in
  status)
    run "icp canister settings show --environment $ENVIRONMENT $CANISTER"
    ;;
  top-up)
    [[ -n "$AMOUNT" ]] || fail "Provide an amount when using the top-up action."
    [[ -n "${ICP_CYCLES_TOP_UP_TEMPLATE:-}" ]] || fail "Set ICP_CYCLES_TOP_UP_TEMPLATE to the exact top-up command template before running this action."
    TOP_UP_COMMAND="${ICP_CYCLES_TOP_UP_TEMPLATE//\{env\}/$ENVIRONMENT}"
    TOP_UP_COMMAND="${TOP_UP_COMMAND//\{canister\}/$CANISTER}"
    TOP_UP_COMMAND="${TOP_UP_COMMAND//\{canister_id\}/$CANISTER_ID}"
    TOP_UP_COMMAND="${TOP_UP_COMMAND//\{amount\}/$AMOUNT}"
    run "$TOP_UP_COMMAND"
    ;;
  *)
    fail "Unsupported action: $ACTION"
    ;;
esac

finish_script "Cycles management action completed"
