#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/typecheck-all.sh [options]
# Run type-safety and static validation checks across Motoko, TypeScript, Python, Rust, Go, and the extension codebase.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/typecheck-all.sh [options]

Run type-safety and static validation checks across Motoko, TypeScript, Python, Rust, Go, and the extension codebase.

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

require_commands mops pnpm cargo go python
set_total_steps 9

step "Typechecking Motoko backend"
run "mops install && mops check --fix"

step "Typechecking workspace TypeScript packages"
run "pnpm typecheck"

step "Typechecking frontend"
run_in_dir "src/frontend" "pnpm typecheck"

step "Checking Rust collaboration engine"
run_in_dir "services/rust-engine" "cargo check --all-features"

step "Checking Rust execution engine"
run_in_dir "rust/execution-engine" "cargo check --all-features"

step "Validating Go CLI compilation"
run_in_dir "services/cli" "go build ./..."

step "Validating Go git-service compilation"
run_in_dir "services/git-service" "go build ./..."

step "Typechecking Python services"
run_in_dir "services/ai-service" "pip install -e '.[dev]' && mypy app/ --ignore-missing-imports"
run_in_dir "python" "pip install -e '.[dev]' && mypy parralax"

step "Compiling VS Code extension for TS validation"
run_in_dir "services/vscode-extension" "pnpm install --prefer-offline && pnpm run compile"

finish_script "Typecheck suite completed"
