#!/usr/bin/env bash
# menus/modules/ansible.sh
set -Eeuo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/ui.sh"

HOMELAB_CMD="${HOMELAB_CMD:-./homelab}"

create_ssh(){
  print_header "Ansible — Create SSH"
  echo "This will create ED25519 SSH keys locally (if missing) and register them on hosts from your inventory via Ansible."
  echo -e "Command: ${BOLD}${HOMELAB_CMD} ansible create-ssh${RESET} (fallbacks described below)"
  if confirm "Run now?"; then
    if ${HOMELAB_CMD} ansible create-ssh; then
      ok "SSH creation/registration completed via homelab."
    else
      warn "homelab command not available or failed."
      echo "Trying common fallbacks:"
      # Local key ensure
      if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -N "" -C "$(whoami)@$(hostname)"
        ok "Generated local ED25519 key."
      else
        _info "Local ED25519 key already exists."
      fi
      # If an Ansible playbook exists, try it
      if [[ -f "ansible/playbooks/create_ssh.yml" ]]; then
        if command -v ansible-playbook >/dev/null 2>&1; then
          ansible-playbook ansible/playbooks/create_ssh.yml
          ok "Ran ansible/playbooks/create_ssh.yml"
        else
          err "ansible-playbook not found."
        fi
      elif [[ -x "scripts/opt/ansible/create_ssh.sh" ]]; then
        "scripts/opt/ansible/create_ssh.sh"
        ok "Ran scripts/opt/ansible/create_ssh.sh"
      else
        err "No fallback found. Please wire your playbook or script."
      fi
    fi
  else
    warn "Skipped."
  fi
  print_footer
  pause
}

menu(){
  print_header "Ansible"
  echo "  1) Create SSH (ED25519, register on hosts)"
  echo "  q) Back"
  echo
  read -rp "Choose: " choice || true
  case "${choice:-}" in
    1) create_ssh ;;
    q|Q) return 0 ;;
    *) warn "Invalid choice"; pause ;;
  esac
}

menu
