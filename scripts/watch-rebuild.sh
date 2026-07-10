#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/watch-rebuild.sh [options]
# Watch the selected source tree and rebuild the affected component whenever files change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/watch-rebuild.sh [options]

Watch the selected source tree and rebuild the affected component whenever files change.

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

SCOPE="${REMAINING_ARGS[0]:-all}"
INTERVAL="${PARRALAX_WATCH_INTERVAL:-3}"
case "$SCOPE" in
  backend) WATCH_PATHS=(src/backend) ; REBUILD_SCRIPT="build-backend.sh" ;;
  frontend) WATCH_PATHS=(src/frontend) ; REBUILD_SCRIPT="build-frontend.sh" ;;
  services) WATCH_PATHS=(services rust python) ; REBUILD_SCRIPT="build-services.sh" ;;
  all) WATCH_PATHS=(src services rust python) ; REBUILD_SCRIPT="build-all.sh" ;;
  *) fail "Unsupported scope: $SCOPE" ;;
esac

set_total_steps 2
step "Performing initial rebuild"
run_script "$REBUILD_SCRIPT"

step "Watching for changes every ${INTERVAL}s"
if (( DRY_RUN )); then
  log_info "[dry-run] monitor ${WATCH_PATHS[*]} and rerun $REBUILD_SCRIPT when content changes"
  finish_script "Watch mode plan generated"
  exit 0
fi

snapshot() {
  find "${WATCH_PATHS[@]}" -type f \( -name '*.mo' -o -name '*.ts' -o -name '*.tsx' -o -name '*.go' -o -name '*.py' -o -name '*.rs' -o -name '*.rb' \) -print0     | sort -z     | xargs -0 sha256sum 2>/dev/null     | sha256sum     | awk '{print $1}'
}

LAST_SNAPSHOT="$(snapshot)"
log_info "Watching ${WATCH_PATHS[*]} for changes. Press Ctrl+C to stop."
while true; do
  sleep "$INTERVAL"
  CURRENT_SNAPSHOT="$(snapshot)"
  if [[ "$CURRENT_SNAPSHOT" != "$LAST_SNAPSHOT" ]]; then
    log_info "Change detected; rebuilding via $REBUILD_SCRIPT"
    bash "$SCRIPT_DIR/$REBUILD_SCRIPT" "${FORWARDED_COMMON_ARGS[@]}"
    LAST_SNAPSHOT="$CURRENT_SNAPSHOT"
  fi
done
