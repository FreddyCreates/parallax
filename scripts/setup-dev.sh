#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/setup-dev.sh [options]
# Install repository dependencies for Node, Motoko, Python, Ruby, Go, Rust, and the VS Code extension in a repeatable order.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/setup-dev.sh [options]

Install repository dependencies for Node, Motoko, Python, Ruby, Go, Rust, and the VS Code extension in a repeatable order.

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

require_commands pnpm mops python bundle go cargo
set_total_steps 8

step "Installing root workspace dependencies"
run "pnpm install --prefer-offline"

step "Installing frontend dependencies"
run_in_dir "src/frontend" "pnpm install --prefer-offline"

step "Installing Motoko dependencies"
run "mops install"

step "Installing AI service dependencies"
run_in_dir "services/ai-service" "pip install -e '.[dev]'"

step "Installing trading package dependencies"
run_in_dir "python" "pip install -e '.[dev]'"

step "Installing Rails gems"
run_in_dir "services/rails-api" "bundle install"

step "Downloading Go and Rust dependencies"
run_in_dir "services/cli" "go mod download"
run_in_dir "services/git-service" "go mod download"
run_in_dir "services/rust-engine" "cargo fetch"
run_in_dir "rust/execution-engine" "cargo fetch"

step "Installing VS Code extension dependencies"
run_in_dir "services/vscode-extension" "pnpm install --prefer-offline"

finish_script "Developer environment setup completed"
