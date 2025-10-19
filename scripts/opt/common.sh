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

log_info "Installing common baseline packages"

# Core CLI utilities commonly useful on Ubuntu/Debian
BASE_PKGS=(
  curl git gh ca-certificates gnupg lsb-release apt-transport-https
  build-essential unzip zip tar jq bash-completion software-properties-common
)

pm_install "${BASE_PKGS[@]}"

# Enable gh completion if available
if command -v gh >/dev/null 2>&1; then
  ensure_dir "$HOME/.config/gh"
  log_success "GitHub CLI installed"
fi

log_success "Common baseline installed"