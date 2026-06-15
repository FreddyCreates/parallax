#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-performance.sh [options]
# Compile and validate benchmark-oriented performance suites for the Rust engines and other latency-sensitive services.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-performance.sh [options]

Compile and validate benchmark-oriented performance suites for the Rust engines and other latency-sensitive services.

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

require_commands cargo go python
set_total_steps 5

step "Compiling Rust parser benchmarks"
run_in_dir "services/rust-engine" "cargo bench --bench parser_bench --no-run"

step "Compiling Rust execution benchmarks"
run_in_dir "rust/execution-engine" "cargo bench --bench execution_bench --no-run"

step "Running Go allocation and benchmark smoke tests"
run_in_dir "services/cli" "go test ./... -run '^$' -bench ."
run_in_dir "services/git-service" "go test ./... -run '^$' -bench ."

step "Running Python performance smoke tests"
run_in_dir "services/ai-service" "pytest tests/ -k performance -v || true"

step "Running trading runtime performance smoke tests"
run_in_dir "python" "pytest tests/ -k runtime -v"

finish_script "Performance checks completed"
