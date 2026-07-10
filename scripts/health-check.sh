#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/health-check.sh [options]
# Probe local or remote PARALLAX endpoints and fail fast when any required service is unavailable.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/health-check.sh [options]

Probe local or remote PARALLAX endpoints and fail fast when any required service is unavailable.

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

ENVIRONMENT="${REMAINING_ARGS[0]:-local}"
CUSTOM_URL="${REMAINING_ARGS[1]:-}"
TIMEOUT_SECONDS="${PARRALAX_HEALTH_TIMEOUT:-10}"
require_commands curl

check_url() {
  local name="$1"
  local url="$2"
  step "Checking $name"
  run "curl --fail --silent --show-error --max-time $TIMEOUT_SECONDS '$url' >/dev/null"
}

if [[ -n "$CUSTOM_URL" ]]; then
  set_total_steps 1
  check_url "custom endpoint" "$CUSTOM_URL"
  finish_script "Health check completed"
  exit 0
fi

case "$ENVIRONMENT" in
  local)
    set_total_steps 5
    check_url "Git service" "http://127.0.0.1:8082/health"
    check_url "AI service" "http://127.0.0.1:8084/health"
    check_url "Trading API" "http://127.0.0.1:8000/health"
    check_url "Dashboard" "http://127.0.0.1:3000"
    check_url "ICP gateway" "http://127.0.0.1:8000"
    ;;
  mainnet|staging|canary)
    BACKEND_CANISTER_ID="${BACKEND_CANISTER_ID:-}"
    FRONTEND_CANISTER_ID="${FRONTEND_CANISTER_ID:-}"
    if [[ -z "$BACKEND_CANISTER_ID" && -f "$REPO_ROOT/src/frontend/env.json" ]]; then
      BACKEND_CANISTER_ID="$(python - <<'PY'
import json
from pathlib import Path
path = Path('src/frontend/env.json')
print(json.loads(path.read_text(encoding='utf-8')).get('backend_canister_id', ''))
PY)"
    fi
    [[ -n "$BACKEND_CANISTER_ID" ]] || fail "Set BACKEND_CANISTER_ID or generate src/frontend/env.json first."
    set_total_steps 2
    check_url "Backend canister" "https://${BACKEND_CANISTER_ID}.raw.icp0.io"
    if [[ -n "$FRONTEND_CANISTER_ID" ]]; then
      check_url "Frontend canister" "https://${FRONTEND_CANISTER_ID}.icp0.io"
    else
      step "Skipping frontend canister check"
      log_warn "FRONTEND_CANISTER_ID is not set; only backend health was checked."
    fi
    ;;
  *)
    fail "Unsupported environment: $ENVIRONMENT"
    ;;
esac

finish_script "Health check completed"
