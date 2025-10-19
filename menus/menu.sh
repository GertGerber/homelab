#!/usr/bin/env bash
# /menus/menu.sh — entrypoint for interactive menus
set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/ui.sh"

# Allow the user/project to override where ./homelab lives.
# By default, we assume the menu sits at repo root next to scripts/.
if [[ -x "./scripts/bin/homelab" ]]; then
  export HOMELAB_CMD="${HOMELAB_CMD:-./scripts/bin/homelab}"
else
  export HOMELAB_CMD="${HOMELAB_CMD:-./homelab}"
fi

main_menu(){
  while true; do
    clear || true
    print_header "Homelab Main Menu"
    echo "  1) Ansible"
    echo "  2) Bash Scripts (./homelab <option>)"
    echo "  3) Packer"
    echo "  4) Terraform"
    echo "  q) Quit"
    echo
    read -rp "Choose: " choice || true
    case "${choice:-}" in
      1) "${SCRIPT_DIR}/modules/ansible.sh" ;;
      2) "${SCRIPT_DIR}/modules/bash_scripts.sh" ;;
      3) "${SCRIPT_DIR}/modules/packer.sh" ;;
      4) "${SCRIPT_DIR}/modules/terraform.sh" ;;
      q|Q) break ;;
      *) warn "Invalid choice"; pause ;;
    esac
  done
}

main_menu
