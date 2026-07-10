#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/generate-test-data.sh [options]
# Generate deterministic sample users, repositories, issues, and pull requests for local testing and demos.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/generate-test-data.sh [options]

Generate deterministic sample users, repositories, issues, and pull requests for local testing and demos.

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

COUNT="${REMAINING_ARGS[0]:-12}"
OUTPUT_PATH="${REMAINING_ARGS[1]:-data/test/sample-dataset.json}"
require_commands python
set_total_steps 3

step "Preparing output directory"
ensure_dir "$(dirname "$REPO_ROOT/$OUTPUT_PATH")"
backup_path "$REPO_ROOT/$OUTPUT_PATH"

step "Generating deterministic dataset"
if (( DRY_RUN )); then
  log_info "[dry-run] generate $COUNT records into $OUTPUT_PATH"
else
  python - <<PY
import json
import random
from pathlib import Path

count = int(${COUNT})
random.seed(42)
users = []
repos = []
issues = []
pull_requests = []

for idx in range(1, count + 1):
    username = f"quant{idx:02d}"
    repo_name = f"alpha-{idx:02d}"
    users.append({
        "username": username,
        "email": f"{username}@parralax.ai",
        "name": f"Quant Engineer {idx}",
        "bio": "Synthetic seed user generated for platform testing.",
    })
    repos.append({
        "owner": username,
        "name": repo_name,
        "description": f"Synthetic strategy repository {idx}",
        "language": random.choice(["Rust", "Python", "TypeScript", "Motoko"]),
        "private": bool(idx % 3 == 0),
    })
    issues.append({
        "repo_owner": username,
        "repo_name": repo_name,
        "author": username,
        "number": 1,
        "title": f"Synthetic issue {idx}",
        "body": "Validate seeded issue workflows.",
        "state": "open",
    })
    pull_requests.append({
        "repo_owner": username,
        "repo_name": repo_name,
        "author": username,
        "number": 1,
        "title": f"Synthetic PR {idx}",
        "body": "Validate seeded pull-request workflows.",
        "state": "open",
        "base_branch": "main",
        "head_branch": f"feature/synthetic-{idx}",
    })

payload = {
    "generated_at": "1970-01-01T00:00:00Z",
    "count": count,
    "users": users,
    "repositories": repos,
    "issues": issues,
    "pull_requests": pull_requests,
}
Path("$REPO_ROOT/$OUTPUT_PATH").write_text(json.dumps(payload, indent=2) + "
", encoding="utf-8")
PY
fi

step "Validating generated dataset"
run "python -m json.tool '$OUTPUT_PATH' >/dev/null"

finish_script "Test dataset generated"
