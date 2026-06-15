#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/build-services.sh [options]
# Build the Go, Rust, Python, Ruby, and VS Code extension services that support the PARALLAX platform.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/build-services.sh [options]

Build the Go, Rust, Python, Ruby, and VS Code extension services that support the PARALLAX platform.

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

require_commands go cargo python bundle pnpm
set_total_steps 7

step "Building Go CLI service"
run_in_dir "services/cli" "go build ./..."

step "Building Go git service"
run_in_dir "services/git-service" "go build ./..."

step "Building Rust collaboration engine"
run_in_dir "services/rust-engine" "cargo build --all-features"

step "Building Rust execution engine"
run_in_dir "rust/execution-engine" "cargo build --all-features"

step "Compiling Python service bytecode"
run_in_dir "services/ai-service" "python -m compileall app"
run_in_dir "python" "python -m compileall parralax"

step "Validating Rails API boot path"
run_in_dir "services/rails-api" "bundle exec rails zeitwerk:check"

step "Building VS Code extension"
run_in_dir "services/vscode-extension" "pnpm install --prefer-offline && pnpm run compile"

finish_script "Service builds completed"
