#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/deploy-local.sh [options]
# Deploy the frontend and backend canisters to the local ICP environment with generated local frontend configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/deploy-local.sh [options]

Deploy the frontend and backend canisters to the local ICP environment with generated local frontend configuration.

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

step "Building deployable artifacts"
run_script build-backend.sh
run_script generate-bindings.sh
if [[ "$TARGET" != "backend" ]]; then
  run_script build-frontend.sh
fi

step "Starting local ICP network when needed"
run "icp network start -d || true"

step "Ensuring local canisters exist"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp canister create --environment local backend || true"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp canister create --environment local frontend || true"
fi

step "Writing frontend local environment"
BACKEND_CANISTER_ID="$(capture_command "icp canister settings show --environment local --id-only backend" "local-backend-canister-id")"
FRONTEND_CANISTER_ID="$(capture_command "icp canister settings show --environment local --id-only frontend" "local-frontend-canister-id")"
write_frontend_env "http://127.0.0.1:8000" "$BACKEND_CANISTER_ID" "parralax-aihftfund-local" "http://${FRONTEND_CANISTER_ID}.localhost:8000"

step "Deploying local canisters"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp deploy --environment local backend"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp deploy --environment local frontend"
fi

finish_script "Local deployment completed"
