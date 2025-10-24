#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/.." )
LIB_DIR="${ROOT_DIR}/lib"
ETC_DIR="${ROOT_DIR}/etc"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh"

log_info "Installing Ansible via pipx"

export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR=/usr/local/bin

pm_install python3-pip python3-venv pipx

if command -v pipx >/dev/null 2>&1; then
  pipx install --include-deps ansible || true
  pipx upgrade ansible || true
else
  log_warn "pipx not available; falling back to system ansible"
  pm_install ansible
fi

# install community.proxmox runtime deps into the ansible pipx venv
# Ensure the ansible pipx venv has pip + proxmox deps
ANSIBLE_PY="$(pipx environment --value PIPX_HOME 2>/dev/null || echo /opt/pipx)/venvs/ansible/bin/python"
if [ -x "$ANSIBLE_PY" ]; then
  "$ANSIBLE_PY" -m ensurepip --upgrade || true
  "$ANSIBLE_PY" -m pip install -U proxmoxer requests || true
fi



if command -v ansible-galaxy >/dev/null 2>&1; then
  if [[ -f "${ETC_DIR}/ansible/requirements.yml" ]]; then
    log_info "Installing Ansible Galaxy requirements"
    ansible-galaxy install -r "${ETC_DIR}/ansible/requirements.yml" --force
  else
    log_warn "No galaxy requirements file at ${ETC_DIR}/ansible/requirements.yml"
  fi
fi

cat >/etc/profile.d/pipx.sh <<'EOF'
# Ensure pipx-installed apps are on PATH
if [ -d "$HOME/.local/bin" ] ; then
  PATH="$PATH:$HOME/.local/bin"
fi
EOF


log_success "Ansible setup complete"