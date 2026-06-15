#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/sync-datasets.sh [options]
# Synchronise generated datasets into service-specific fixture directories for integration and local testing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/sync-datasets.sh [options]

Synchronise generated datasets into service-specific fixture directories for integration and local testing.

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

SOURCE_DIR="${REMAINING_ARGS[0]:-data/test}"
TARGET_A="${REMAINING_ARGS[1]:-services/ai-service/tests/fixtures}"
TARGET_B="${REMAINING_ARGS[2]:-python/tests/fixtures}"
set_total_steps 4

step "Ensuring source dataset directory exists"
if [[ ! -d "$REPO_ROOT/$SOURCE_DIR" ]]; then
  run_script generate-test-data.sh
fi

step "Preparing AI service fixture directory"
ensure_dir "$REPO_ROOT/$TARGET_A"
backup_path "$REPO_ROOT/$TARGET_A"

step "Preparing trading fixture directory"
ensure_dir "$REPO_ROOT/$TARGET_B"
backup_path "$REPO_ROOT/$TARGET_B"

step "Synchronising datasets"
if command -v rsync >/dev/null 2>&1; then
  run "rsync -a --delete '$SOURCE_DIR/' '$TARGET_A/'"
  run "rsync -a --delete '$SOURCE_DIR/' '$TARGET_B/'"
else
  run "rm -rf '$TARGET_A' '$TARGET_B' && mkdir -p '$TARGET_A' '$TARGET_B' && cp -R '$SOURCE_DIR'/.' '$TARGET_A' && cp -R '$SOURCE_DIR'/.' '$TARGET_B'"
fi

finish_script "Datasets synchronised"
