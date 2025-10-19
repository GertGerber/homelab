#!/usr/bin/env bash
# menus/modules/bash_scripts.sh
set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/ui.sh"

HOMELAB_CMD="${HOMELAB_CMD:-./homelab}"

declare -A OPTIONS=(
  [bootstrap]="Ensure prerequisites (nala/apt updated) and run"
  [common]="Install common baseline utilities"
  [python]="Install Python tooling (python3, pipx, venv)"
  [ansible]="Install Ansible and galaxy requirements"
  [hashicorp]="Install Terraform & Packer"
  [login]="Login to Git/GitHub"
  [all]="Run: common, python, ansible, hashicorp"
  [doctor]="Show detected OS, package manager and versions"
  [help]="Show this help"
)

run_option(){
  local key="$1"
  if [[ -z "${key}" ]]; then err "No option selected"; return 1; fi
  print_header "homelab: ${key} — ${OPTIONS[$key]}"
  echo -e "Command: ${BOLD}${HOMELAB_CMD} ${key}${RESET}"
  if confirm "Run now?"; then
    if ! ${HOMELAB_CMD} "${key}"; then
      err "Command failed. Verify ${HOMELAB_CMD} exists and supports '${key}'."
      return 1
    fi
    ok "Completed: ${key}"
  else
    warn "Skipped."
  fi
  print_footer
  pause
}

menu(){
  local -a entries=()
  for k in "${!OPTIONS[@]}"; do entries+=( "${k}: ${OPTIONS[$k]}" ); done
  IFS=$'\n' entries=($(sort <<<"${entries[*]}")); unset IFS

  print_header "Bash Scripts — ./homelab <option>"
  local i=1
  for e in "${entries[@]}"; do
    printf " %2d) %s\n" "$i" "$e"
    ((i++))
  done
  echo
  read -rp "Choose an option [1-$((i-1))] or 'q' to quit: " choice || true
  [[ "${choice:-}" =~ ^[Qq]$ ]] && return 0
  if [[ "${choice:-}" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<i )); then
    local sel="${entries[choice-1]}"
    local key="${sel%%:*}"
    run_option "${key}"
  else
    warn "Invalid choice."
    pause
  fi
}

menu
