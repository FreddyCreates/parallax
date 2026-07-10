#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/deploy-mainnet.sh [options]
# Deploy the frontend and backend canisters to ICP mainnet using the repository ICP workflow and production frontend configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/deploy-mainnet.sh [options]

Deploy the frontend and backend canisters to ICP mainnet using the repository ICP workflow and production frontend configuration.

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

TARGET="${REMAINING_ARGS[0]:-all}"
[[ "$TARGET" =~ ^(all|frontend|backend)$ ]] || fail "Target must be one of: all, frontend, backend"
require_commands icp
set_total_steps 5

step "Building production artifacts"
run_script build-backend.sh
run_script generate-bindings.sh
if [[ "$TARGET" != "backend" ]]; then
  run_script build-frontend.sh
fi

step "Verifying ICP identity"
run "icp identity whoami"

step "Ensuring mainnet canisters exist"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp canister create --environment mainnet backend || true"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp canister create --environment mainnet frontend || true"
fi

step "Writing production frontend environment"
BACKEND_CANISTER_ID="$(capture_command "icp canister settings show --environment mainnet --id-only backend" "mainnet-backend-canister-id")"
FRONTEND_CANISTER_ID="$(capture_command "icp canister settings show --environment mainnet --id-only frontend" "mainnet-frontend-canister-id")"
write_frontend_env "https://icp-api.io" "$BACKEND_CANISTER_ID" "parralax-aihftfund" "https://${FRONTEND_CANISTER_ID}.icp0.io"

step "Deploying canisters to mainnet"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp deploy --environment mainnet backend"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp deploy --environment mainnet frontend"
fi

finish_script "Mainnet deployment completed"
