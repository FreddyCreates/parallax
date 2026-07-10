#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/run-dev-server.sh [options]
# Start the PARALLAX development server stack for one service or the full docker-compose environment.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/run-dev-server.sh [options]

Start the PARALLAX development server stack for one service or the full docker-compose environment.

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

TARGET="${REMAINING_ARGS[0]:-all}"
set_total_steps 1

case "$TARGET" in
  all)
    require_commands docker
    step "Starting full docker-compose stack"
    run "docker compose up --build"
    ;;
  frontend)
    require_commands pnpm
    step "Starting frontend dev server"
    run_in_dir "src/frontend" "pnpm dev --host 0.0.0.0"
    ;;
  ai-service)
    require_commands python
    step "Starting AI service dev server"
    run_in_dir "services/ai-service" "python main.py"
    ;;
  rails-api)
    require_commands bundle
    step "Starting Rails API dev server"
    run_in_dir "services/rails-api" "bundle exec rails server -p 3001 -b 0.0.0.0"
    ;;
  trading-api)
    require_commands python
    step "Starting trading API dev server"
    run_in_dir "python" "uvicorn parralax.api:app --host 0.0.0.0 --port 8000 --reload"
    ;;
  *)
    fail "Unsupported target: $TARGET"
    ;;
esac

finish_script "Development server command completed"
