#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-backend.sh [options]
# Validate the Motoko backend by installing dependencies, typechecking, and rebuilding the canister artifacts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-backend.sh [options]

Validate the Motoko backend by installing dependencies, typechecking, and rebuilding the canister artifacts.

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

require_commands mops
set_total_steps 3

step "Installing Motoko dependencies"
run "mops install"

step "Typechecking backend"
run "mops check --fix"

step "Building backend artifacts"
run "mops build"

finish_script "Backend validation completed"
