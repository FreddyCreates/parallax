#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/format-code.sh [options]
# Apply repository formatting and auto-fix steps using the tools already configured in each language ecosystem.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/format-code.sh [options]

Apply repository formatting and auto-fix steps using the tools already configured in each language ecosystem.

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

require_commands pnpm mops python go cargo bundle
set_total_steps 7

step "Formatting Motoko and workspace code"
run "mops check --fix"
run "pnpm fix"

step "Formatting frontend"
run_in_dir "src/frontend" "pnpm fix"

step "Formatting Python code"
run_in_dir "services/ai-service" "pip install -e '.[dev]' && ruff format . && ruff check --fix ."
run_in_dir "python" "pip install -e '.[dev]' && ruff format . && ruff check --fix ."

step "Formatting Go services"
run_in_dir "services/cli" "go fmt ./..."
run_in_dir "services/git-service" "go fmt ./..."

step "Formatting Rust services"
run_in_dir "services/rust-engine" "cargo fmt --all"
run_in_dir "rust/execution-engine" "cargo fmt --all"

step "Formatting Rails API"
run_in_dir "services/rails-api" "bundle exec rubocop -A || bundle exec rubocop"

step "Rebuilding generated bindings after formatting"
run_script generate-bindings.sh

finish_script "Code formatting completed"
