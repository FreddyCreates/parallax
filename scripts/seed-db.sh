#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/seed-db.sh [options]
# Seed the Rails database with deterministic PARALLAX sample data for local development and integration testing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/seed-db.sh [options]

Seed the Rails database with deterministic PARALLAX sample data for local development and integration testing.

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

DATASET_PATH="${REMAINING_ARGS[0]:-data/test/sample-dataset.json}"
require_commands python bundle
set_total_steps 4

step "Ensuring seed dataset exists"
if [[ ! -f "$REPO_ROOT/$DATASET_PATH" ]]; then
  run_script generate-test-data.sh
else
  log_info "Using existing dataset at $DATASET_PATH"
fi

step "Preparing Rails database"
run_in_dir "services/rails-api" "DATABASE_URL=${DATABASE_URL:-mysql2://root:test@127.0.0.1:3306/parralax_test} REDIS_URL=${REDIS_URL:-redis://127.0.0.1:6379} RAILS_ENV=${RAILS_ENV:-development} bundle exec rails db:prepare"

step "Seeding application records"
if (( DRY_RUN )); then
  log_info "[dry-run] seed services/rails-api from $DATASET_PATH"
else
  export PARRALAX_SEED_DATASET="$REPO_ROOT/$DATASET_PATH"
  (
    cd "$REPO_ROOT/services/rails-api"
    DATABASE_URL="${DATABASE_URL:-mysql2://root:test@127.0.0.1:3306/parralax_test}"     REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"     RAILS_ENV="${RAILS_ENV:-development}"     bundle exec rails runner <<'RUBY'
require 'json'
payload = JSON.parse(File.read(ENV.fetch('PARRALAX_SEED_DATASET')))
payload.fetch('users').each do |row|
  user = User.find_or_initialize_by(username: row.fetch('username'))
  user.email = row.fetch('email')
  user.name = row['name']
  user.bio = row['bio']
  user.password = 'ParralaxSeed123!'
  user.password_confirmation = 'ParralaxSeed123!'
  user.save!
end
payload.fetch('repositories').each do |row|
  owner = User.find_by!(username: row.fetch('owner'))
  repo = Repository.find_or_initialize_by(owner: owner, name: row.fetch('name'))
  repo.description = row['description']
  repo.language = row['language']
  repo.private = row['private']
  repo.save!
end
payload.fetch('issues').each do |row|
  repo_owner = User.find_by!(username: row.fetch('repo_owner'))
  repo = Repository.find_by!(owner: repo_owner, name: row.fetch('repo_name'))
  author = User.find_by!(username: row.fetch('author'))
  issue = Issue.find_or_initialize_by(repository: repo, number: row.fetch('number'))
  issue.author = author
  issue.title = row.fetch('title')
  issue.body = row['body']
  issue.state = row.fetch('state', 'open')
  issue.save!
end
payload.fetch('pull_requests').each do |row|
  repo_owner = User.find_by!(username: row.fetch('repo_owner'))
  repo = Repository.find_by!(owner: repo_owner, name: row.fetch('repo_name'))
  author = User.find_by!(username: row.fetch('author'))
  pr = PullRequest.find_or_initialize_by(repository: repo, number: row.fetch('number'))
  pr.author = author
  pr.title = row.fetch('title')
  pr.body = row['body']
  pr.state = row.fetch('state', 'open')
  pr.base_branch = row.fetch('base_branch', 'main')
  pr.head_branch = row.fetch('head_branch', 'seed/generated')
  pr.save!
end
puts 'Seed completed successfully'
RUBY
  )
fi

step "Summarising seeded dataset"
run "python - <<'PY'
import json
from pathlib import Path
payload = json.loads(Path('$DATASET_PATH').read_text(encoding='utf-8'))
print(f"users={len(payload['users'])}, repos={len(payload['repositories'])}, issues={len(payload['issues'])}, prs={len(payload['pull_requests'])}")
PY"

finish_script "Database seed completed"
