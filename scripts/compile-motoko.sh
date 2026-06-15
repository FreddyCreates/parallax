#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/compile-motoko.sh [options]
# Compile the Motoko canister and verify that the generated candid interface is present.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/compile-motoko.sh [options]

Compile the Motoko canister and verify that the generated candid interface is present.

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

step "Compiling Motoko sources"
run "mops build"

step "Verifying generated candid interface"
run "test -f src/backend/dist/backend.did"

finish_script "Motoko compilation completed"
