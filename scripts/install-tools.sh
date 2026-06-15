#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/install-tools.sh [options]
# Check for required developer tooling and optionally install the user-space tools that can be bootstrapped safely.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install-tools.sh [options]

Check for required developer tooling and optionally install the user-space tools that can be bootstrapped safely.

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

AUTO_INSTALL=0
for arg in "${REMAINING_ARGS[@]}"; do
  if [[ "$arg" == "--auto-install" ]]; then
    AUTO_INSTALL=1
  fi
done
set_total_steps 4

step "Checking core language toolchains"
for tool in git curl python go cargo ruby node npm corepack; do
  if command -v "$tool" >/dev/null 2>&1; then
    log_success "$tool is installed"
  else
    log_warn "$tool is missing"
  fi
done

step "Checking platform-specific tools"
for tool in pnpm mops bundle icp docker; do
  if command -v "$tool" >/dev/null 2>&1; then
    log_success "$tool is installed"
  else
    log_warn "$tool is missing"
  fi
done

step "Bootstrapping safe user-space tools when requested"
if (( AUTO_INSTALL )); then
  if ! command -v pnpm >/dev/null 2>&1; then
    run "corepack enable && corepack prepare pnpm@latest --activate"
  fi
  if ! command -v mops >/dev/null 2>&1; then
    run "npm install -g ic-mops"
  fi
  if ! command -v bundle >/dev/null 2>&1; then
    run "gem install bundler"
  fi
else
  log_info "Run this script with --auto-install to bootstrap pnpm, mops, and bundler when the host supports it."
fi

step "Printing manual install guidance for heavyweight tools"
log_info "Install docker, icp-cli, Go, Rust, Ruby, or Node with your preferred system package manager if they are still missing."

finish_script "Tool inspection completed"
