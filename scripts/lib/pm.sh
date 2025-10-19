#!/usr/bin/env bash
set -Eeuo pipefail

# requires log.sh, os.sh, utils.sh

has_cmd() { command -v "$1" >/dev/null 2>&1; }
has_nala() { has_cmd nala; }

pm_name() { if has_nala; then echo nala; else echo apt; fi }

ensure_pm_ready() {
  if [[ "$OS_FAMILY" == debian ]]; then
    if ! has_nala; then
      log_info "nala not found; installing (using apt)"
      sudo_if_needed apt-get update
      sudo_if_needed apt-get install -y nala
    fi
  else
    log_warn "Unsupported OS family '$OS_FAMILY' for nala/apt. Extend pm.sh for your distro."
  fi
}

pm_update() {
  if has_nala; then
    log_info "Updating package lists (nala update)"
    sudo_if_needed nala update
  else
    log_info "Updating package lists (apt-get update)"
    sudo_if_needed apt-get update
  fi
}

pm_upgrade() {
  if has_nala; then
    log_info "Upgrading packages (nala upgrade -y)"
    sudo_if_needed nala upgrade -y
  else
    log_info "Upgrading packages (apt-get upgrade -y)"
    sudo_if_needed apt-get upgrade -y
  fi
}

pm_install() {
  # usage: pm_install pkg1 pkg2 ...
  local pkgs=("$@")
  if (( ${#pkgs[@]} == 0 )); then return 0; fi
  if has_nala; then
    log_info "Installing: ${pkgs[*]} (nala install -y)"
    sudo_if_needed nala install -y "${pkgs[@]}"
  else
    log_info "Installing: ${pkgs[*]} (apt-get install -y)"
    sudo_if_needed apt-get install -y "${pkgs[@]}"
  fi
}