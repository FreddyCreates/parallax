#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-all.sh [options]
# Run backend, frontend, integration, security, and performance validation workflows in sequence.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-all.sh [options]

Run backend, frontend, integration, security, and performance validation workflows in sequence.

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

set_total_steps 5

step "Running backend validation"
run_script test-backend.sh

step "Running frontend tests"
run_script test-frontend.sh

step "Running integration tests"
run_script test-integration.sh

step "Running security validation"
run_script test-security.sh

step "Running performance validation"
run_script test-performance.sh

finish_script "Full platform test suite completed"
