#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/export-data.sh [options]
# Export platform data from the Rails application into a portable JSON artifact for backups and analysis.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/export-data.sh [options]

Export platform data from the Rails application into a portable JSON artifact for backups and analysis.

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

OUTPUT_PATH="${REMAINING_ARGS[0]:-data/exports/platform-export.json}"
require_commands python bundle
set_total_steps 3

step "Preparing export destination"
ensure_dir "$(dirname "$REPO_ROOT/$OUTPUT_PATH")"
backup_path "$REPO_ROOT/$OUTPUT_PATH"

step "Exporting platform data"
if (( DRY_RUN )); then
  log_info "[dry-run] export Rails data to $OUTPUT_PATH"
else
  export PARRALAX_EXPORT_PATH="$REPO_ROOT/$OUTPUT_PATH"
  (
    cd "$REPO_ROOT/services/rails-api"
    DATABASE_URL="${DATABASE_URL:-mysql2://root:test@127.0.0.1:3306/parralax_test}"     REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"     RAILS_ENV="${RAILS_ENV:-development}"     bundle exec rails runner <<'RUBY'
require 'json'
require 'pathname'
payload = {
  exported_at: Time.now.utc.iso8601,
  users: User.limit(500).map { |row| row.slice(:id, :username, :email, :name, :created_at, :updated_at) },
  repositories: Repository.limit(500).map { |row| row.slice(:id, :name, :description, :language, :private, :created_at, :updated_at) },
  issues: Issue.limit(500).map { |row| row.slice(:id, :number, :title, :state, :created_at, :updated_at) },
  pull_requests: PullRequest.limit(500).map { |row| row.slice(:id, :number, :title, :state, :base_branch, :head_branch, :created_at, :updated_at) },
}
Pathname.new(ENV.fetch('PARRALAX_EXPORT_PATH')).write(payload.to_json)
puts 'Export complete'
RUBY
  )
fi

step "Validating exported JSON"
run "python -m json.tool '$OUTPUT_PATH' >/dev/null"

finish_script "Data export completed"
