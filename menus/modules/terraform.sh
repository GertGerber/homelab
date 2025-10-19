#!/usr/bin/env bash
# menus/modules/terraform.sh
set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/ui.sh"

HOMELAB_CMD="${HOMELAB_CMD:-./homelab}"

menu(){
  print_header "Terraform"
  echo "  1) Install / Update Terraform (via homelab hashicorp)"
  echo "  2) terraform init (current dir)"
  echo "  3) terraform plan (current dir)"
  echo "  q) Back"
  echo
  read -rp "Choose: " choice || true
  case "${choice:-}" in
    1) ${HOMELAB_CMD} hashicorp || err "homelab hashicorp failed"; pause ;;
    2) terraform init || err "terraform init failed"; pause ;;
    3) terraform plan || err "terraform plan failed"; pause ;;
    q|Q) return 0 ;;
    *) warn "Invalid choice"; pause ;;
  esac
}

menu
