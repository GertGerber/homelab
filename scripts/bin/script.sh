#!/usr/bin/env bash
set -Eeuo pipefail

# Resolve repo root relative to this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/.." )
LIB_DIR="${ROOT_DIR}/lib"
ETC_DIR="${ROOT_DIR}/etc"
OPT_DIR="${ROOT_DIR}/opt"

# shellcheck source=../lib/*.sh
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh"

trap 'trap_err $?' ERR
trap trap_exit EXIT

load_configs "${ETC_DIR}/config.env" "${HOME}/.config/app_name/config.env"

usage() {
  cat <<EOF
Usage: $(basename "$0") [command] [args]

Commands:
  bootstrap        Ensure prerequisites (nala/apt updated) and run common
  common           Install common baseline utilities
  python           Install Python tooling (python3, pipx, venv)
  ansible          Install Ansible and galaxy requirements
  hashicorp        Install Terraform & Packer
  executable       Make all *.sh files excutable
  login            Login to Git/Github
  all              Run: common, python, ansible, hashicorp
  doctor           Show detected OS, package manager and versions
  help             Show this help

Environment overrides (via ~/.config/app_name/config.env):
  THEME_MODE=auto|light|dark
  NONINTERACTIVE=0|1   # if 1, auto-approve installs (where safe)
EOF
}

cmd=${1:-help}
shift || true

case "$cmd" in
  help|-h|--help)
    usage ;;
  doctor)
    log_info "OS ID: $OS_ID  VERSION: $OS_VERSION_ID  FAMILY: $OS_FAMILY  ARCH: $ARCH"
    log_info "Package manager: $(pm_name) (nala=$(has_nala && echo yes || echo no))"
    ;;
  bootstrap)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/common.sh"
    ;;
  common)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/common.sh" "$@" ;;
  python)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/python.sh" "$@" ;;
  ansible)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/ansible.sh" "$@" ;;
  login)
     ensure_pm_ready
    pm_update
    "${OPT_DIR}/login.sh" "$@" ;;
  hashicorp)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/hashicorp.sh" "$@" ;;
  executable)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/executable.sh" "$@" ;;  
  all)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/executable.sh"
    "${OPT_DIR}/common.sh"
    "${OPT_DIR}/python.sh"
    "${OPT_DIR}/ansible.sh"
    "${OPT_DIR}/hashicorp.sh" 
    "${OPT_DIR}/login.sh" ;;
  *)
    usage ;;
 esac
