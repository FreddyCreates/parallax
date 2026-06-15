#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/debug-canister.sh [options]
# Inspect canister settings, resolve canister identifiers, and execute user-supplied debug templates for advanced troubleshooting.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/debug-canister.sh [options]

Inspect canister settings, resolve canister identifiers, and execute user-supplied debug templates for advanced troubleshooting.

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

ACTION="${REMAINING_ARGS[0]:-settings}"
CANISTER="${REMAINING_ARGS[1]:-backend}"
PAYLOAD="${REMAINING_ARGS[2]:-}"
ENVIRONMENT="${PARRALAX_DEBUG_ENVIRONMENT:-local}"
require_commands icp
set_total_steps 2

step "Resolving canister identity"
CANISTER_ID="$(capture_command "icp canister settings show --environment $ENVIRONMENT --id-only $CANISTER" "debug-placeholder-canister-id")"
log_info "Canister $CANISTER resolved to $CANISTER_ID"

step "Executing debug action"
case "$ACTION" in
  id)
    printf '%s
' "$CANISTER_ID"
    ;;
  settings|status)
    run "icp canister settings show --environment $ENVIRONMENT $CANISTER"
    ;;
  call|logs)
    [[ -n "$PAYLOAD" ]] || fail "Provide a payload or method name for the $ACTION action."
    TEMPLATE_VAR="ICP_CANISTER_${ACTION^^}_TEMPLATE"
    TEMPLATE_VALUE="${!TEMPLATE_VAR:-}"
    [[ -n "$TEMPLATE_VALUE" ]] || fail "Set $TEMPLATE_VAR to the exact command template before running this action."
    DEBUG_COMMAND="${TEMPLATE_VALUE//\{env\}/$ENVIRONMENT}"
    DEBUG_COMMAND="${DEBUG_COMMAND//\{canister\}/$CANISTER}"
    DEBUG_COMMAND="${DEBUG_COMMAND//\{canister_id\}/$CANISTER_ID}"
    DEBUG_COMMAND="${DEBUG_COMMAND//\{payload\}/$PAYLOAD}"
    run "$DEBUG_COMMAND"
    ;;
  *)
    fail "Unsupported action: $ACTION"
    ;;
esac

finish_script "Canister debug action completed"
