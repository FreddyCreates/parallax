#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test-security.sh [options]
# Run dependency, application, and framework-level security checks using the repository tooling that already exists in CI and manifests.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-security.sh [options]

Run dependency, application, and framework-level security checks using the repository tooling that already exists in CI and manifests.

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

require_commands pnpm python bundle
set_total_steps 4

step "Auditing Node workspace dependencies"
run "pnpm audit --audit-level high"

step "Verifying Python dependency integrity"
run_in_dir "services/ai-service" "pip install -e '.[dev]' && python -m pip check"
run_in_dir "python" "pip install -e '.[dev]' && python -m pip check"

step "Running Rails static security scan"
run_in_dir "services/rails-api" "bundle exec brakeman -q -w2"

step "Checking committed secrets patterns in key runtime files"
run "! grep -RInE '(AKIA|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|api[_-]?key[[:space:]]*=)' services src python .github --exclude-dir=node_modules --exclude-dir=.git"

finish_script "Security checks completed"
