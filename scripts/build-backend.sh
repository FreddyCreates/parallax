#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/build-backend.sh [options]
# Install Motoko dependencies, typecheck the backend, and build the canister artifacts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/build-backend.sh [options]

Install Motoko dependencies, typecheck the backend, and build the canister artifacts.

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

step "Typechecking Motoko backend"
run "mops check --fix"

step "Building backend canister"
run "mops build"

finish_script "Backend build completed"
