#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/cleanup-old-data.sh [options]
# Remove stale generated exports, fixtures, and script-state backups that exceed the configured retention period.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/cleanup-old-data.sh [options]

Remove stale generated exports, fixtures, and script-state backups that exceed the configured retention period.

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

RETENTION_DAYS="${REMAINING_ARGS[0]:-14}"
set_total_steps 3

step "Cleaning stale data exports"
run "find data/exports -type f -mtime +$RETENTION_DAYS -print -delete 2>/dev/null || true"

step "Cleaning stale generated test data"
run "find data/test -type f -mtime +$RETENTION_DAYS -print -delete 2>/dev/null || true"

step "Cleaning stale script backups"
run "find .script-state -type f -name '*.bak' -mtime +$RETENTION_DAYS -print -delete 2>/dev/null || true"

finish_script "Old generated data cleaned"
