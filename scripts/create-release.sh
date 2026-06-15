#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/create-release.sh [options]
# Build release artifacts, package them under releases/, and optionally publish a GitHub release for the current revision.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/create-release.sh [options]

Build release artifacts, package them under releases/, and optionally publish a GitHub release for the current revision.

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

VERSION="${REMAINING_ARGS[0]:-$(git rev-parse --short HEAD)}"
PUBLISH=0
for arg in "${REMAINING_ARGS[@]}"; do
  if [[ "$arg" == "--publish" ]]; then
    PUBLISH=1
  fi
done
set_total_steps 5

step "Validating git working tree"
run "git diff --quiet --ignore-submodules HEAD --"

step "Building release artifacts"
run_script build-all.sh
run_script test-all.sh

step "Preparing release directory"
ensure_dir "$REPO_ROOT/releases/$VERSION"
backup_path "$REPO_ROOT/releases/$VERSION"

step "Packaging repository snapshot"
run "git archive --format=tar.gz -o 'releases/$VERSION/parralax-$VERSION.tar.gz' HEAD"
run "cp src/backend/dist/backend.did 'releases/$VERSION/' 2>/dev/null || true"

step "Publishing GitHub release when requested"
if (( PUBLISH )); then
  require_commands gh
  run "gh release create '$VERSION' 'releases/$VERSION/parralax-$VERSION.tar.gz' --generate-notes"
else
  log_info "Skipping GitHub release publishing. Pass --publish to upload the packaged release."
fi

finish_script "Release workflow completed"
