#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/validate-deployment.sh [options]
# Validate deployment prerequisites, generated configuration, and optional health endpoints before or after a release.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/validate-deployment.sh [options]

Validate deployment prerequisites, generated configuration, and optional health endpoints before or after a release.

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
require_commands python curl
set_total_steps 4

step "Validating generated backend and frontend artifacts"
run "test -f src/backend/dist/backend.did"
run "test -f src/frontend/package.json"

step "Validating frontend environment configuration"
if [[ -f "$REPO_ROOT/src/frontend/env.json" ]]; then
  run "python - <<'PY'
import json
from pathlib import Path
path = Path('src/frontend/env.json')
required = ['backend_host', 'backend_canister_id', 'project_id']
data = json.loads(path.read_text(encoding='utf-8'))
missing = [key for key in required if not data.get(key)]
if missing:
    raise SystemExit(f'Missing frontend env keys: {missing}')
print('env.json looks valid')
PY"
else
  log_warn "src/frontend/env.json does not exist yet; deploy scripts will generate it."
fi

step "Validating docker compose configuration"
if command -v docker >/dev/null 2>&1; then
  run "docker compose config -q"
else
  log_warn "docker is not installed; skipping docker compose validation."
fi

step "Running health checks when an endpoint is available"
if [[ -n "$CUSTOM_URL" ]]; then
  run_script health-check.sh "$ENVIRONMENT" "$CUSTOM_URL"
else
  run_script health-check.sh "$ENVIRONMENT"
fi

finish_script "Deployment validation completed"
