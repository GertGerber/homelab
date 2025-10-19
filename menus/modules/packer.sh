#!/usr/bin/env bash
# menus/modules/packer.sh
set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/ui.sh"

HOMELAB_CMD="${HOMELAB_CMD:-./homelab}"

menu(){
  print_header "Packer"
  echo "  1) Install / Update Packer (via homelab hashicorp)"
  echo "  2) packer init (current dir)"
  echo "  3) packer build (current dir)"
  echo "  q) Back"
  echo
  read -rp "Choose: " choice || true
  case "${choice:-}" in
    1) ${HOMELAB_CMD} hashicorp || err "homelab hashicorp failed"; pause ;;
    2) packer init . || err "packer init failed"; pause ;;
    3) packer build . || err "packer build failed"; pause ;;
    q|Q) return 0 ;;
    *) warn "Invalid choice"; pause ;;
  esac
}

menu
