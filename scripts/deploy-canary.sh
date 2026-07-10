#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/deploy-canary.sh [options]
# Perform a canary deployment for a single target and validate the release with post-deploy health checks.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/deploy-canary.sh [options]

Perform a canary deployment for a single target and validate the release with post-deploy health checks.

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

TARGET="${REMAINING_ARGS[0]:-frontend}"
ENVIRONMENT="${PARRALAX_CANARY_ENVIRONMENT:-mainnet}"
[[ "$TARGET" =~ ^(frontend|backend)$ ]] || fail "Target must be frontend or backend"
require_commands icp curl
set_total_steps 5

step "Building canary artifact"
if [[ "$TARGET" == "backend" ]]; then
  run_script build-backend.sh
  run_script generate-bindings.sh
else
  run_script build-frontend.sh
fi

step "Verifying ICP identity"
run "icp identity whoami"

step "Ensuring canary target exists"
run "icp canister create --environment $ENVIRONMENT $TARGET || true"

step "Deploying canary target"
run "icp deploy --environment $ENVIRONMENT $TARGET"

step "Validating canary health"
run_script health-check.sh "$ENVIRONMENT"

finish_script "Canary deployment completed"
