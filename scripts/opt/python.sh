#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/.." )
LIB_DIR="${ROOT_DIR}/lib"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh"  # if this defines append_once, the fallback below won't be used

log_info "Installing Python toolchain"

export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR=/usr/local/bin

PY_PKGS=(python3 python3-pip python3-venv pipx)
pm_install "${PY_PKGS[@]}"

# Ensure pipx path
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath || true
  log_success "pipx installed and PATH ensured (restart shell if first time)"
fi

enable_pipx_completion() {
  if ! command -v register-python-argcomplete >/dev/null 2>&1; then
    log_warn "register-python-argcomplete not found; is pipx installed? Skipping completions."
    return 0
  fi

  local shell_name rc line
  shell_name="$(basename "${SHELL:-/bin/bash}")"

  case "$shell_name" in
    bash)
      rc="${HOME}/.bashrc"
      line='command -v register-python-argcomplete >/dev/null && eval "$(register-python-argcomplete pipx)"'
      if append_once "$rc" "$line"; then
        log_info "Enabled pipx completion in ${rc}"
      else
        log_info "pipx completion already present in ${rc}"
      fi
      eval "$(register-python-argcomplete pipx)" || true
      ;;

    zsh)
      rc="${HOME}/.zshrc"
      if append_once "$rc" 'autoload -U bashcompinit && bashcompinit'; then
        log_info "Enabled bashcompinit in ${rc}"
      fi
      line='eval "$(register-python-argcomplete pipx)"'
      if append_once "$rc" "$line"; then
        log_info "Enabled pipx completion in ${rc}"
      else
        log_info "pipx completion already present in ${rc}"
      fi
      autoload -U bashcompinit 2>/dev/null || true
      bashcompinit 2>/dev/null || true
      eval "$(register-python-argcomplete pipx)" || true
      ;;

    fish)
      mkdir -p "${HOME}/.config/fish/completions"
      local target="${HOME}/.config/fish/completions/pipx.fish"
      register-python-argcomplete --shell fish pipx >"$target"
      log_info "Installed pipx completion for fish at ${target}"
      ;;

    tcsh|csh)
      rc="${HOME}/.cshrc"
      line='eval `register-python-argcomplete --shell tcsh pipx`'
      if append_once "$rc" "$line"; then
        log_info "Enabled pipx completion in ${rc}"
      else
        log_info "pipx completion already present in ${rc}"
      fi
      ;;

    *)
      rc="${HOME}/.bashrc"
      line='command -v register-python-argcomplete >/dev/null && eval "$(register-python-argcomplete pipx)"'
      if append_once "$rc" "$line"; then
        log_info "Unknown shell (${shell_name}); added bash-style completion to ${rc}"
      else
        log_info "pipx completion already present in ${rc}"
      fi
      eval "$(register-python-argcomplete pipx)" || true
      ;;
  esac

  log_success "pipx autocompletion enabled (persisted to your ${shell_name} config)"
}

install_pipx_tools() {
  if ! command -v pipx >/dev/null 2>&1; then
    log_error "pipx not found; install pipx first."
    return 1
  fi

  # Ensure ~/.local/bin is on PATH (idempotent).
  python3 -m pipx ensurepath >/dev/null 2>&1 || true

  # Recommended tools
  local tools=(
    uv           # fast installer/venv mgr
    poetry       # packaging & deps
    ruff         # linter/formatter
    black        # formatter
    mypy         # static types
    pre-commit   # git hooks
  )

  # get already-installed packages (short names in first column)
  local installed
  installed="$(pipx list --short 2>/dev/null | awk '{print $1}' || true)"

  for pkg in "${tools[@]}"; do
    if grep -Fxq "$pkg" <<<"$installed"; then
      log_info "pipx: ${pkg} already installed"
    else
      log_info "pipx: installing ${pkg}…"
      if pipx install "$pkg"; then
        log_success "pipx: ${pkg} installed"
      else
        log_warn "pipx: failed to install ${pkg} (continuing)"
      fi
    fi
  done
}

# run extras only if pipx is present
if command -v pipx >/dev/null 2>&1; then
  enable_pipx_completion
  install_pipx_tools
fi

log_success "Python toolchain installed"
