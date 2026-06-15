#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/build-all.sh [options]
# Build the Motoko backend, generated bindings, React frontend, and polyglot services in a single pipeline.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/build-all.sh [options]

Build the Motoko backend, generated bindings, React frontend, and polyglot services in a single pipeline.

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

set_total_steps 4
step "Building Motoko backend"
run_script build-backend.sh

step "Generating frontend bindings"
run_script generate-bindings.sh

step "Building React frontend"
run_script build-frontend.sh

step "Building platform services"
run_script build-services.sh

finish_script "Platform build completed"
