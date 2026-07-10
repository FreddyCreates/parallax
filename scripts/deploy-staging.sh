#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/deploy-staging.sh [options]
# Deploy the frontend and backend canisters to a staging ICP environment with staging-safe frontend configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/deploy-staging.sh [options]

Deploy the frontend and backend canisters to a staging ICP environment with staging-safe frontend configuration.

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
ENVIRONMENT="${PARRALAX_STAGING_ENVIRONMENT:-staging}"
BACKEND_HOST="${PARRALAX_STAGING_BACKEND_HOST:-https://staging.icp-api.io}"
PROJECT_ID="${PARRALAX_STAGING_PROJECT_ID:-parralax-aihftfund-staging}"
[[ "$TARGET" =~ ^(all|frontend|backend)$ ]] || fail "Target must be one of: all, frontend, backend"
require_commands icp
set_total_steps 5

step "Building staging artifacts"
run_script build-backend.sh
run_script generate-bindings.sh
if [[ "$TARGET" != "backend" ]]; then
  run_script build-frontend.sh
fi

step "Verifying ICP identity"
run "icp identity whoami"

step "Ensuring staging canisters exist"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp canister create --environment $ENVIRONMENT backend || true"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp canister create --environment $ENVIRONMENT frontend || true"
fi

step "Writing staging frontend environment"
BACKEND_CANISTER_ID="$(capture_command "icp canister settings show --environment $ENVIRONMENT --id-only backend" "staging-backend-canister-id")"
FRONTEND_CANISTER_ID="$(capture_command "icp canister settings show --environment $ENVIRONMENT --id-only frontend" "staging-frontend-canister-id")"
write_frontend_env "$BACKEND_HOST" "$BACKEND_CANISTER_ID" "$PROJECT_ID" "https://${FRONTEND_CANISTER_ID}.icp0.io"

step "Deploying canisters to staging"
if [[ "$TARGET" == "all" || "$TARGET" == "backend" ]]; then
  run "icp deploy --environment $ENVIRONMENT backend"
fi
if [[ "$TARGET" == "all" || "$TARGET" == "frontend" ]]; then
  run "icp deploy --environment $ENVIRONMENT frontend"
fi

finish_script "Staging deployment completed"
