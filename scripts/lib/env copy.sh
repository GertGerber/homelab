# scripts/lib/env.sh
# Purpose: define project-wide paths + load common libs.
# Usage: source this file at the top of any script.

# Guard against double-loading
if [[ -n "${HOMELAB_ENV_LOADED:-}" ]]; then
  return 0
fi
export HOMELAB_ENV_LOADED=1

# --- helpers ---------------------------------------------------------------
# Portable abspath (works on macOS + Linux, avoids `readlink -f`)
_abspath() {
  # cd to the dirname, then print $PWD + basename
  local _p
  _p="$(cd -- "$(dirname -- "$1")" && pwd)/$(basename -- "$1")"
  # normalize potential /./ and /../ segments
  python3 - "$_p" <<'PY' 2>/dev/null || printf '%s\n' "$_p"
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
}

# Try to find repo root:
# 1) If in a git repo, prefer `git rev-parse`
# 2) Otherwise, resolve relative to this file: lib -> scripts -> ROOT
_detect_root() {
  if command -v git >/dev/null 2>&1; then
    if git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel >/dev/null 2>&1; then
      git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel
      return
    fi
  fi
  # scripts/lib/env.sh -> scripts -> root
  local lib_dir
  lib_dir="$(_abspath "${BASH_SOURCE[0]}")"
  lib_dir="$(dirname -- "$lib_dir")"           # .../scripts/lib
  local scripts_dir
  scripts_dir="$(dirname -- "$lib_dir")"       # .../scripts
  printf '%s\n' "$(dirname -- "$scripts_dir")" # repo root
}

# --- paths ----------------------------------------------------------------
export ROOT_DIR="$(_detect_root)"
export SCRIPTS_DIR="${ROOT_DIR}/scripts"
export LIB_DIR="${SCRIPTS_DIR}/lib"
export MENUS_DIR="${ROOT_DIR}/menus"
export ANSIBLE_DIR="${ROOT_DIR}/ansible"
export PACKER_DIR="${ROOT_DIR}/packer"
export TERRAFORM_DIR="${ROOT_DIR}/terraform"
export LIB_DIR="${SCRIPTS_DIR}/lib"

# Put project bins on PATH (optional but handy)
export PATH="${SCRIPTS_DIR}/bin:${PATH}"

# --- load common libs ------------------------------------------------------
# shellcheck source=./colors.sh
# shellcheck source=./log.sh
# shellcheck source=./os.sh
# shellcheck source=./pm.sh
# shellcheck source=./utils.sh
for _lib in colors.sh log.sh os.sh pm.sh utils.sh; do
  # Only source if present (keeps things flexible)
  [[ -f "${LIB_DIR}/${_lib}" ]] && source "${LIB_DIR}/${_lib}"
done

# --- optional trap helpers -------------------------------------------------
# Don’t enable traps automatically (that’s the caller’s job);
# provide helpers instead so callers can opt-in.
enable_standard_traps() {
  # requires trap_err and trap_exit to be defined in your libs (e.g., log.sh)
  trap 'trap_err $?' ERR
  trap trap_exit EXIT
}
