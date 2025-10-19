#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/.." )
LIB_DIR="${ROOT_DIR}/lib"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh"

if [[ "$OS_FAMILY" != debian ]]; then
  log_warn "HashiCorp repo setup currently implemented for Debian/Ubuntu family only"
fi

log_info "Configuring HashiCorp apt repo (if missing)"

if [[ -n ${WSL_DISTRO_NAME:-} ]]; then
  log_warn "WSL detected; repo keys may behave differently"
fi

# Add HashiCorp official repo
if ! grep -q '^deb .*hashicorp' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo_if_needed gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  # shellcheck disable=SC2155
  release=$(lsb_release -cs)
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo_if_needed tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
else
  log_info "HashiCorp repo already present"
fi

pm_update
pm_install terraform packer

log_success "HashiCorp tools installed"