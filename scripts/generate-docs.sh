#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/generate-docs.sh [options]
# Generate an operational inventory document that summarises scripts, services, and runtime entrypoints for maintainers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/generate-docs.sh [options]

Generate an operational inventory document that summarises scripts, services, and runtime entrypoints for maintainers.

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

OUTPUT_PATH="${REMAINING_ARGS[0]:-docs/generated/platform-operations.md}"
require_commands python
set_total_steps 3

step "Preparing output path"
ensure_dir "$(dirname "$REPO_ROOT/$OUTPUT_PATH")"
backup_path "$REPO_ROOT/$OUTPUT_PATH"

step "Generating operations document"
if (( DRY_RUN )); then
  log_info "[dry-run] write generated operations guide to $OUTPUT_PATH"
else
  python - <<PY
from pathlib import Path
from datetime import datetime, timezone
root = Path("$REPO_ROOT")
services = [
    ('Motoko backend', 'src/backend/main.mo', 'mops build'),
    ('React frontend', 'src/frontend/package.json', 'pnpm build'),
    ('Go CLI', 'services/cli/go.mod', 'go build ./...'),
    ('Go git-service', 'services/git-service/go.mod', 'go build ./...'),
    ('Rust engine', 'services/rust-engine/Cargo.toml', 'cargo build --all-features'),
    ('Rust execution engine', 'rust/execution-engine/Cargo.toml', 'cargo build --all-features'),
    ('AI service', 'services/ai-service/pyproject.toml', 'python main.py'),
    ('Rails API', 'services/rails-api/Gemfile', 'bundle exec rails server -p 3001'),
]
lines = [
    '# Generated PARALLAX Operations Guide',
    '',
    f'Generated: {datetime.now(timezone.utc).isoformat()}',
    '',
    '## Service Inventory',
    '',
]
for name, manifest, command in services:
    lines.extend([f'- **{name}**', f'  - Manifest: `{manifest}`', f'  - Primary command: `{command}`'])
lines.extend(['', '## Script Inventory', ''])
for script in sorted((root / 'scripts').glob('*.sh')):
    lines.append(f'- `{script.name}`')
Path("$REPO_ROOT/$OUTPUT_PATH").write_text('
'.join(lines) + '
', encoding='utf-8')
PY
fi

step "Validating generated document"
run "test -s '$OUTPUT_PATH'"

finish_script "Operations documentation generated"
