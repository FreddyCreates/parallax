#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-frontend.sh [options]
# Install frontend dependencies, typecheck the application, and execute the Vitest suite.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-frontend.sh [options]

Install frontend dependencies, typecheck the application, and execute the Vitest suite.

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
set_total_steps 3

step "Installing frontend dependencies"
run_in_dir "src/frontend" "pnpm install --prefer-offline"

step "Typechecking frontend"
run_in_dir "src/frontend" "pnpm typecheck"

step "Running frontend tests"
run_in_dir "src/frontend" "pnpm test"

finish_script "Frontend tests completed"
