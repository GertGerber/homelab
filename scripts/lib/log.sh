#!/usr/bin/env bash
set -Eeuo pipefail

# requires colors.sh

_timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

_log() {
  local level="$1"; shift
  local palette=$(log_color_for "$level")
  local prefix
  prefix="[$(_timestamp)] ${level^^}:"
  echo -e "$(fg "$palette" "$prefix") $*${reset}"
}

log_info()    { _log INFO    "$@"; }
log_success() { _log SUCCESS "$@"; }
log_warn()    { _log WARN    "$@"; }
log_error()   { _log ERROR   "$@"; }

die() { log_error "$*"; exit 1; }

# Rich error/trace reporting
trap_err() {
  local ec=${1:-$?}
  local i=0
  log_error "Command failed with exit $ec"
  while caller $i >/dev/null 2>&1; do
    local frame; frame=$(caller $i)
    # frame: line func file
    local line func file
    line=$(awk '{print $1}' <<<"$frame")
    func=$(awk '{print $2}' <<<"$frame")
    file=$(awk '{print $3}' <<<"$frame")
    echo -e "$(fg "$(_level_to_palette DIM)" "  at ${file}:${line} in ${func}")${reset}"
    i=$((i+1))
  done
  exit "$ec"
}

trap_exit() {
  local ec=$?
  if [[ $ec -eq 0 ]]; then
    log_success "Done."
  fi
}