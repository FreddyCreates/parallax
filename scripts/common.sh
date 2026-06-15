#!/usr/bin/env bash
set -euo pipefail
set -E

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMON_DIR/.." && pwd)"
STATE_DIR="$REPO_ROOT/.script-state"
mkdir -p "$STATE_DIR"

if [[ -t 1 ]]; then
  COLOR_GREEN='\033[0;32m'
  COLOR_RED='\033[0;31m'
  COLOR_BLUE='\033[0;34m'
  COLOR_YELLOW='\033[1;33m'
  COLOR_RESET='\033[0m'
else
  COLOR_GREEN=''
  COLOR_RED=''
  COLOR_BLUE=''
  COLOR_YELLOW=''
  COLOR_RESET=''
fi

SUCCESS_ICON='✅'
ERROR_ICON='❌'
INFO_ICON='▸'

DRY_RUN=0
VERBOSE=0
FORCE=0
YES=0
SHOW_HELP=0
CURRENT_STEP=0
TOTAL_STEPS=0
ROLLBACK_RAN=0
STARTED_AT="$(date +%s)"
CURRENT_SCRIPT="${0##*/}"
REMAINING_ARGS=()
FORWARDED_COMMON_ARGS=()
ROLLBACK_ACTIONS=()

parse_common_args() {
  REMAINING_ARGS=()
  FORWARDED_COMMON_ARGS=()

  while (($#)); do
    case "$1" in
      -n|--dry-run)
        DRY_RUN=1
        FORWARDED_COMMON_ARGS+=("$1")
        ;;
      -v|--verbose)
        VERBOSE=1
        FORWARDED_COMMON_ARGS+=("$1")
        ;;
      -f|--force)
        FORCE=1
        FORWARDED_COMMON_ARGS+=("$1")
        ;;
      -y|--yes)
        YES=1
        FORWARDED_COMMON_ARGS+=("$1")
        ;;
      -h|--help)
        SHOW_HELP=1
        ;;
      --)
        shift
        while (($#)); do
          REMAINING_ARGS+=("$1")
          shift
        done
        break
        ;;
      *)
        REMAINING_ARGS+=("$1")
        ;;
    esac
    shift || true
  done
}

log_info() {
  printf '%b%s%b %s\n' "$COLOR_BLUE" "$INFO_ICON" "$COLOR_RESET" "$*"
}

log_success() {
  printf '%b%s%b %s\n' "$COLOR_GREEN" "$SUCCESS_ICON" "$COLOR_RESET" "$*"
}

log_warn() {
  printf '%b%s%b %s\n' "$COLOR_YELLOW" "$INFO_ICON" "$COLOR_RESET" "$*"
}

log_error() {
  printf '%b%s%b %s\n' "$COLOR_RED" "$ERROR_ICON" "$COLOR_RESET" "$*" >&2
}

fail() {
  log_error "$*"
  exit 1
}

set_total_steps() {
  TOTAL_STEPS="$1"
  CURRENT_STEP=0
}

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  if (( TOTAL_STEPS > 0 )); then
    log_info "[$CURRENT_STEP/$TOTAL_STEPS] $*"
  else
    log_info "$*"
  fi
}

ensure_repo_root() {
  cd "$REPO_ROOT"
}

require_commands() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if ((${#missing[@]} == 0)); then
    return 0
  fi

  if (( DRY_RUN )); then
    log_warn "Skipping runtime dependency enforcement in dry-run mode: ${missing[*]}"
    return 0
  fi

  fail "Missing required command(s): ${missing[*]}"
}

ensure_dir() {
  local target="$1"
  if [[ -d "$target" ]]; then
    return 0
  fi
  if (( DRY_RUN )); then
    log_info "[dry-run] mkdir -p '$target'"
  else
    mkdir -p "$target"
  fi
}

run() {
  local command="$1"
  if (( DRY_RUN )); then
    log_info "[dry-run] $command"
    return 0
  fi
  if (( VERBOSE )); then
    log_info "$command"
  fi
  bash -lc "cd '$REPO_ROOT' && $command"
}

run_in_dir() {
  local directory="$1"
  shift
  local command="$*"
  if (( DRY_RUN )); then
    log_info "[dry-run] (cd '$directory' && $command)"
    return 0
  fi
  if (( VERBOSE )); then
    log_info "(cd '$directory' && $command)"
  fi
  bash -lc "cd '$REPO_ROOT/$directory' && $command"
}

capture_command() {
  local command="$1"
  local placeholder="${2:-dry-run-placeholder}"
  if (( DRY_RUN )); then
    printf '%b%s%b [dry-run] %s\n' "$COLOR_BLUE" "$INFO_ICON" "$COLOR_RESET" "$command" >&2
    printf '%s\n' "$placeholder"
    return 0
  fi
  bash -lc "cd '$REPO_ROOT' && $command"
}

run_script() {
  local script_name="$1"
  shift || true
  local script_path="$COMMON_DIR/$script_name"
  local cmd=(bash "$script_path")
  if ((${#FORWARDED_COMMON_ARGS[@]})); then
    cmd+=("${FORWARDED_COMMON_ARGS[@]}")
  fi
  if (($#)); then
    cmd+=("$@")
  fi

  if (( DRY_RUN )); then
    log_info "[dry-run] invoking ${cmd[*]}"
  fi

  "${cmd[@]}"
}

safe_backup_name() {
  local target="$1"
  printf '%s' "${target#/}" | tr '/' '_'
}

backup_path() {
  local target="$1"
  local safe_name backup
  safe_name="$(safe_backup_name "$target")"
  backup="$STATE_DIR/${CURRENT_SCRIPT}.${safe_name}.$(date +%s).bak"

  if [[ -e "$target" ]]; then
    if (( DRY_RUN )); then
      log_info "[dry-run] backup '$target' -> '$backup'"
    else
      cp -R "$target" "$backup"
    fi
    register_rollback "rm -rf '$target' && cp -R '$backup' '$target'"
  else
    register_rollback "rm -rf '$target'"
  fi
}

register_rollback() {
  ROLLBACK_ACTIONS+=("$*")
}

rollback_on_exit() {
  local exit_code=$?
  if (( exit_code == 0 || ROLLBACK_RAN == 1 )); then
    return 0
  fi

  ROLLBACK_RAN=1
  if ((${#ROLLBACK_ACTIONS[@]})); then
    log_warn "Failure detected. Running rollback actions..."
    local idx
    for ((idx=${#ROLLBACK_ACTIONS[@]}-1; idx>=0; idx--)); do
      local action="${ROLLBACK_ACTIONS[idx]}"
      if (( DRY_RUN )); then
        log_info "[dry-run] rollback: $action"
      else
        bash -lc "cd '$REPO_ROOT' && $action" || log_error "Rollback action failed: $action"
      fi
    done
  else
    log_warn "Failure detected. No rollback actions were registered."
  fi
}

trap rollback_on_exit EXIT

write_frontend_env() {
  local backend_host="$1"
  local backend_canister_id="$2"
  local project_id="$3"
  local ii_origin="$4"
  local env_file="$REPO_ROOT/src/frontend/env.json"

  backup_path "$env_file"
  if (( DRY_RUN )); then
    log_info "[dry-run] write '$env_file' with backend_canister_id=$backend_canister_id"
    return 0
  fi

  cat > "$env_file" <<EOF
{
  "backend_host": "$backend_host",
  "backend_canister_id": "$backend_canister_id",
  "project_id": "$project_id",
  "ii_derivation_origin": "$ii_origin"
}
EOF
}

finish_script() {
  local message="$1"
  local duration
  duration=$(( $(date +%s) - STARTED_AT ))
  log_success "$message (${duration}s)"
}
