#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/rollback.sh [options]
# Restore the latest backup created by the deployment and data scripts for a specific file or directory path.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/rollback.sh [options]

Restore the latest backup created by the deployment and data scripts for a specific file or directory path.

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

TARGET_PATH="${REMAINING_ARGS[0]:-src/frontend/env.json}"
EXPLICIT_BACKUP="${REMAINING_ARGS[1]:-}"
set_total_steps 2

step "Resolving rollback source"
SAFE_NAME="$(safe_backup_name "$REPO_ROOT/$TARGET_PATH")"
if [[ -n "$EXPLICIT_BACKUP" ]]; then
  BACKUP_PATH="$EXPLICIT_BACKUP"
elif compgen -G "$REPO_ROOT/.script-state/*.${SAFE_NAME}.*.bak" >/dev/null; then
  BACKUP_PATH="$(ls -1t "$REPO_ROOT/.script-state"/*.${SAFE_NAME}.*.bak | head -n 1)"
else
  fail "No backup found for $TARGET_PATH"
fi

step "Restoring backup"
if (( DRY_RUN )); then
  log_info "[dry-run] rm -rf '$REPO_ROOT/$TARGET_PATH' && cp -R '$BACKUP_PATH' '$REPO_ROOT/$TARGET_PATH'"
else
  rm -rf "$REPO_ROOT/$TARGET_PATH"
  cp -R "$BACKUP_PATH" "$REPO_ROOT/$TARGET_PATH"
fi

finish_script "Rollback completed"
