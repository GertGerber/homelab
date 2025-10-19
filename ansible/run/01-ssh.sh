#!/usr/bin/env bash
set -Eeuo pipefail

# ───────── Start Comman functions - Required by every file to run independent ──────────────────────────────────────
# *******************************************************************************************************************
# ── Set Project ROOT Folder ────────────────────────────────────────────────────────────────────
# find_root: find project / repo root from anywhere

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

# ── Run env.sh ────────────────────────────────────────────────────────────────────
# Where to put the stamp file (XDG-friendly fallback to ~/.cache)
_hl_cache_root=${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-"$HOME/.cache"}}
_hl_stamp_dir="$_hl_cache_root/homelab2"
_hl_stamp_file="$_hl_stamp_dir/activated.$USER.$(uname -n)"

# Has env.sh already been activated in this environment?
hl_was_activated() {
    [ "${HOMELAB_ACTIVATED-}" = "1" ] || [ -f "$_hl_stamp_file" ]
}

if hl_was_activated
  then 
    echo "env.sh already applied"
  else
    ${ROOT_DIR}/scripts/lib/env.sh
fi

# *******************************************************************************************************************
# ─────────── END Comman functions - Required by every file to run independent ──────────────────────────────────────

# log_info "Create and distribute ssh keys"
ansible-playbook -i ./inventories/production/hosts.ini ./playbooks/01-ssh.yml \
  -e ssh_authorize_target_user=ubuntu
