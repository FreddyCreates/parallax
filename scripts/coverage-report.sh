#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/coverage-report.sh [options]
# Generate code-coverage reports for the frontend and Python services and store the artifacts under coverage/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/coverage-report.sh [options]

Generate code-coverage reports for the frontend and Python services and store the artifacts under coverage/.

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

require_commands pnpm python
set_total_steps 4

step "Preparing coverage output directory"
ensure_dir "$REPO_ROOT/coverage"

step "Collecting frontend coverage"
run_in_dir "src/frontend" "pnpm install --prefer-offline && pnpm exec vitest run --coverage.enabled true --coverage.reporter=text --coverage.reporter=lcov"

step "Collecting AI service coverage"
run_in_dir "services/ai-service" "pip install -e '.[dev]' && pytest tests/ --cov=app --cov-report=term-missing --cov-report=xml:$REPO_ROOT/coverage/ai-service.xml"

step "Collecting trading package coverage"
run_in_dir "python" "pip install -e '.[dev]' && pytest tests/ --cov=parralax --cov-report=term-missing --cov-report=xml:$REPO_ROOT/coverage/trading-python.xml"

finish_script "Coverage report generation completed"
