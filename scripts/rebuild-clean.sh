#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/rebuild-clean.sh [options]
# Remove generated build artifacts, caches, and compiled outputs, then perform a clean rebuild of the platform.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/rebuild-clean.sh [options]

Remove generated build artifacts, caches, and compiled outputs, then perform a clean rebuild of the platform.

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

set_total_steps 3

step "Removing generated build artifacts"
run "rm -rf src/backend/dist src/frontend/dist services/vscode-extension/out services/rust-engine/target rust/execution-engine/target"
run "find services src python rust -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true"

step "Rebuilding the platform"
run_script build-all.sh

step "Refreshing generated bindings after clean build"
run_script generate-bindings.sh

finish_script "Clean rebuild completed"
