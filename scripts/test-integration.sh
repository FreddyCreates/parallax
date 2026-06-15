#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-integration.sh [options]
# Execute the cross-service integration workflow used by CI, including generated bindings, frontend build, Rails DB prep, and AI integration tests.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-integration.sh [options]

Execute the cross-service integration workflow used by CI, including generated bindings, frontend build, Rails DB prep, and AI integration tests.

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

require_commands pnpm python bundle mops
set_total_steps 7

step "Installing workspace dependencies"
run "pnpm install --prefer-offline"

step "Building backend and bindings"
run_script build-backend.sh
run_script generate-bindings.sh

step "Building frontend for integration"
run_in_dir "src/frontend" "pnpm install --prefer-offline && pnpm typecheck && pnpm build"

step "Installing Python AI service dependencies"
run_in_dir "services/ai-service" "pip install -e '.[dev]'"

step "Installing Python trading dependencies"
run_in_dir "python" "pip install -e '.[dev]'"

step "Preparing Rails integration database"
run_in_dir "services/rails-api" "DATABASE_URL=${DATABASE_URL:-mysql2://root:test@127.0.0.1:3306/parralax_test} REDIS_URL=${REDIS_URL:-redis://127.0.0.1:6379} RAILS_ENV=${RAILS_ENV:-test} bundle exec rails db:create db:migrate"

step "Running AI service integration tests"
run_in_dir "services/ai-service" "DATABASE_URL=${DATABASE_URL:-mysql2://root:test@127.0.0.1:3306/parralax_test} REDIS_URL=${REDIS_URL:-redis://127.0.0.1:6379} pytest tests/integration/ -v --tb=short"

finish_script "Integration tests completed"
