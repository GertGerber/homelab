#!/usr/bin/env bash
set -Eeuo pipefail

# scripts/lib/env.sh
# Purpose: define project-wide variables
# Usage: source this file at the top of any script.

# ── Track variables to clear them ────────────────────────────────────────────────────────────────────
# Have your project’s env.sh register every var it sets, so you can cleanly undo it later:
# scripts/etc/env.sh (POSIX sh)

# Internal registries
: "${_PROJECT_VARS:=}"
: "${_PROJECT_PATH_DIRS:=}"
: "${_PROJECT_ALIAS_NAMES:=}"
: "${_PROJECT_FUNC_NAMES:=}"

project_export() {
    # export NAME=VALUE
    # Usage: project_export NAME VALUE
    name=$1; shift
    value=$1
    # shellcheck disable=SC2163 # (for shells with shellcheck)
    export "$name=$value"
    _PROJECT_VARS="$_PROJECT_VARS $name"
}

project_path_prepend() {
    dir=$1
    case ":$PATH:" in
        *":$dir:"*) : ;;               # already present
        *) PATH="$dir:$PATH"; export PATH; _PROJECT_PATH_DIRS="$_PROJECT_PATH_DIRS $dir" ;;
    esac
}

project_alias() {
    name=$1; shift
    alias "$name=$*"
    _PROJECT_ALIAS_NAMES="$_PROJECT_ALIAS_NAMES $name"
}

# (Optional) track functions if your /bin/sh supports them
project_function_register() {
    _PROJECT_FUNC_NAMES="$_PROJECT_FUNC_NAMES $*"
}

# ---- Your project vars go here ----
# project_export HOMELAB_ROOT "$(find_root homelab menus ansible scripts 2>/dev/null || printf /)"
# project_export HOMELAB_MODE "dev"
# project_path_prepend "$HOME/.local/bin"
# project_alias hl='sh "$HOMELAB_ROOT/scripts/bin/homelab"'
# # If you defined functions: project_function_register my_func another_func
# ----------------------------------

# Deactivate: undo everything set above
project_deactivate() {
    # Unset exported vars
    for name in $_PROJECT_VARS; do unset "$name"; done
    unset _PROJECT_VARS

    # Remove PATH entries we added (order-preserving)
    for d in $_PROJECT_PATH_DIRS; do
        # strip ":d" and "d:" and lone "d"
        PATH=$(printf '%s' "$PATH" \
          | awk -v RS=: -v ORS=: -v drop="$d" 'NF{ if ($0!=drop) printf "%s", $0 ORS }' \
          | sed 's/^://; s/:$//')
    done
    export PATH
    unset _PROJECT_PATH_DIRS

    # Unalias project aliases
    for a in $_PROJECT_ALIAS_NAMES; do unalias "$a" 2>/dev/null || true; done
    unset _PROJECT_ALIAS_NAMES

    # Unset registered functions (if shell supports)
    for f in $_PROJECT_FUNC_NAMES; do unset -f "$f" 2>/dev/null || true; done
    unset _PROJECT_FUNC_NAMES

    # Optionally clear PS1 tweaks or other state here

    # Also remove this function itself to be tidy
    unset project_deactivate project_export project_path_prepend project_alias project_function_register 2>/dev/null || true
}

# Convenience alias
alias homelab_deactivate='project_deactivate'

# ── Set Project ROOT Folder ────────────────────────────────────────────────────────────────────
# find_root: find project / repo root from anywhere

find_root() {
  local cwd="$PWD"
  local markers=( \
    ".git" ".gitignore" "package.json" "pyproject.toml" "setup.cfg" "requirements.txt" \
    "Makefile" "Dockerfile" "ansible.cfg" "ansible" "scripts" "menus" "README.md" \
    ".projectroot" ".repo" \
  )
  # allow caller to add more markers
  if [ "$#" -gt 0 ]; then
    markers=("$@" "${markers[@]}")
  fi

  # 1) If inside git repo prefer git top-level (fast & reliable)
  if command -v git >/dev/null 2>&1; then
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
      printf '%s\n' "$git_root"
      return 0
    fi
  fi

  # 2) Walk up looking for markers
  local dir="$cwd"
  while true; do
    for m in "${markers[@]}"; do
      if [ -e "$dir/$m" ]; then
        printf '%s\n' "$dir"
        return 0
      fi
    done

    # stop at filesystem root
    if [ "$dir" = "/" ] || [ -z "$dir" ]; then
      break
    fi

    # move up
    dir=$(dirname "$dir")
  done

  # 3) Not found - fallback (echo / and non-zero return so caller can tell)
  printf '/\n'
  return 1
}


# Ensure $ROOT_DIR is defined even under 'set -u'
: "${ROOT_DIR:=}"

if [ -z "$ROOT_DIR" ] || [ "$ROOT_DIR" = "/" ]; then
    if ROOT_DIR=$(find_root homelab menus ansible scripts 2>/dev/null); then
        :
    else
        ROOT_DIR="/"
        echo "project root not found, using $ROOT_DIR (fallback)"
        # handle fallback...
    fi
fi

# ── Set Project Folders ────────────────────────────────────────────────────────────────────
export SCRIPTS_DIR="${ROOT_DIR}/scripts"
export LIB_DIR="${SCRIPTS_DIR}/lib"
export MENUS_DIR="${ROOT_DIR}/menus"
export ANSIBLE_DIR="${ROOT_DIR}/ansible"
export PACKER_DIR="${ROOT_DIR}/packer"
export TERRAFORM_DIR="${ROOT_DIR}/terraform"


# ── Load common functions from /scripts/lib ────────────────────────────────────────────────────────────────────
# shellcheck source=./colors.sh
# shellcheck source=./log.sh
# shellcheck source=./os.sh
# shellcheck source=./pm.sh
# shellcheck source=./utils.sh
for _lib in env.sh colors.sh log.sh os.sh pm.sh utils.sh; do
  # Only source if present (keeps things flexible)
  [[ -f "${LIB_DIR}/${_lib}" ]] && source "${LIB_DIR}/${_lib}"
done

# ── Load optional trap helpers ────────────────────────────────────────────────────────────────────
# Don’t enable traps automatically (that’s the caller’s job);
# provide helpers instead so callers can opt-in.
enable_standard_traps() {
  # requires trap_err and trap_exit to be defined in your libs (e.g., log.sh)
  trap 'trap_err $?' ERR
  trap trap_exit EXIT
}
enable_standard_traps

# ── Create indicator that env.sh was run - prevent rerun ────────────────────────────────────────────────────────────────────
# --- Activation indicator -----------------------------------------------

# Where to put the stamp file (XDG-friendly fallback to ~/.cache)
_hl_cache_root=${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-"$HOME/.cache"}}
_hl_stamp_dir="$_hl_cache_root/homelab2"
_hl_stamp_file="$_hl_stamp_dir/activated.$USER.$(uname -n)"

# Has env.sh already been activated in this environment?
hl_was_activated() {
    [ "${HOMELAB_ACTIVATED-}" = "1" ] || [ -f "$_hl_stamp_file" ]
}

# Write the activation indicator (idempotent)
hl_mark_activated() {
    [ -d "$_hl_stamp_dir" ] || mkdir -p "$_hl_stamp_dir" 2>/dev/null || :
    # Optional: include useful context in the stamp
    {
        printf 'when=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
        printf 'user=%s\n' "${USER-unknown}"
        printf 'host=%s\n' "$(uname -n 2>/dev/null || echo unknown)"
        printf 'shell_pid=%s\n' "$$"
        printf 'root=%s\n' "${HOMELAB_ROOT-}"
    } >"$_hl_stamp_file" 2>/dev/null || :
    HOMELAB_ACTIVATED=1; export HOMELAB_ACTIVATED
    HOMELAB_ACTIVATION_FILE="$_hl_stamp_file"; export HOMELAB_ACTIVATION_FILE
}

# Remove the indicator (use inside your deactivate function)
hl_clear_activation() {
    [ -f "$_hl_stamp_file" ] && rm -f "$_hl_stamp_file" 2>/dev/null || :
    unset HOMELAB_ACTIVATED HOMELAB_ACTIVATION_FILE
}


# Finally mark as activated
hl_mark_activated

