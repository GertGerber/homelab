#!/usr/bin/env bash
set -Eeuo pipefail

# requires log.sh

sudo_if_needed() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

ensure_dir() { local d="$1"; [[ -d "$d" ]] || mkdir -p "$d"; }
ensure_owns() {
  # ensure_owns <path> [owner]
  local path="$1" owner="${2:-${SUDO_USER:-$USER}}"
  sudo_if_needed chown -R "$owner":"$owner" "$path"
}

load_configs() {
  # precedence: system-wide then user overrides
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      # shellcheck source=/dev/null
      . "$f"
      log_info "Loaded config: $f"
    fi
  done
}

append_once() {
  # append_once <file> <line>
  local file="$1" line="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -Fqx -- "$line" "$file" 2>/dev/null; then
    printf '%s\n' "$line" >>"$file"
    return 0
  fi
  return 1
}