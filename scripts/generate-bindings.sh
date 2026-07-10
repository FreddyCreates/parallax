#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/generate-bindings.sh [options]
# Generate frontend actor bindings from the backend candid interface used by the React application.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/generate-bindings.sh [options]

Generate frontend actor bindings from the backend candid interface used by the React application.

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

require_commands pnpm
set_total_steps 2

step "Ensuring backend candid interface exists"
if [[ ! -f "$REPO_ROOT/src/backend/dist/backend.did" ]]; then
  run_script compile-motoko.sh
else
  log_info "Using existing src/backend/dist/backend.did"
fi

step "Generating frontend bindings"
run "pnpm bindgen"

finish_script "Bindings generated"
