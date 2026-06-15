#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/lint-all.sh [options]
# Run repository linting and static quality gates across Motoko, TypeScript, Python, Go, Rust, and Rails code.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/lint-all.sh [options]

Run repository linting and static quality gates across Motoko, TypeScript, Python, Go, Rust, and Rails code.

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
set_total_steps 8

step "Linting Motoko backend"
run "mops check --fix"

step "Linting root workspace"
run "pnpm check"

step "Linting frontend"
run_in_dir "src/frontend" "pnpm check"

step "Linting Python services"
run_in_dir "services/ai-service" "pip install -e '.[dev]' && ruff check . && mypy app/ --ignore-missing-imports"
run_in_dir "python" "pip install -e '.[dev]' && ruff check ."

step "Linting Go services"
run_in_dir "services/cli" "go vet ./..."
run_in_dir "services/git-service" "go vet ./..."

step "Linting Rust services"
run_in_dir "services/rust-engine" "cargo clippy --all-features -- -D warnings"
run_in_dir "rust/execution-engine" "cargo clippy --all-features -- -D warnings"

step "Linting Rails API"
run_in_dir "services/rails-api" "bundle exec rubocop"

step "Linting VS Code extension via compile check"
run_in_dir "services/vscode-extension" "pnpm install --prefer-offline && pnpm run compile"

finish_script "Lint suite completed"
