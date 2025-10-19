#!/usr/bin/env bash
set -Eeuo pipefail

# Directories
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/../.." )
LIB_DIR="${ROOT_DIR}/scripts/lib"

# Shell libraries
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh" || true

: "${NONINTERACTIVE:=0}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [git|gh|all]

Handles developer logins and identity setup.

Subcommands:
  git   Configure global Git identity (user.name, user.email) if not already set
  gh    Authenticate GitHub CLI via personal access token if not already authenticated
  all   Run both steps (default)

Environment (optional):
  GIT_USER_NAME   Preseed for Git user.name (used if NONINTERACTIVE=1 or no TTY)
  GIT_USER_EMAIL  Preseed for Git user.email
  GITHUB_TOKEN    Preseed for gh auth (only used when not already authenticated)

EOF
}

ensure_tool() {
  local bin="$1"
  local pkg="${2:-$1}"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log_warn "$bin not found; attempting install ($pkg)"
    pm_install "$pkg" || { log_error "Failed to install $pkg"; return 1; }
  fi
}

already_has_git_identity() {
  git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1
}

configure_git_identity() {
  ensure_tool git git || return 1

  if already_has_git_identity; then
    local name email
    name="$(git config --global user.name || true)"
    email="$(git config --global user.email || true)"
    log_info "Git identity already configured: ${name:-<unset>} <${email:-unset}>"
    return 0
  fi

  local name="${GIT_USER_NAME:-}"
  local email="${GIT_USER_EMAIL:-}"

  if [[ "$NONINTERACTIVE" -eq 1 || ! -t 0 ]]; then
    if [[ -z "$name" || -z "$email" ]]; then
      log_error "NONINTERACTIVE=1 but GIT_USER_NAME/GIT_USER_EMAIL not provided."
      return 1
    fi
  else
    if [[ -z "$name" ]]; then
      read -r -p "Enter Git user.name: " name
    fi
    if [[ -z "$email" ]]; then
      read -r -p "Enter Git user.email: " email
    fi
  fi

  if [[ -z "$name" || -z "$email" ]]; then
    log_error "Git identity not set (name or email empty)."
    return 1
  fi

  log_info "Configuring global Git identity"
  git config --global user.name "$name"
  git config --global user.email "$email"
  log_success "Git identity set to: $name <$email>"
}

is_gh_authenticated() {
  if ! command -v gh >/dev/null 2>&1; then
    return 1
  fi
  if gh auth status >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

authenticate_gh() {
  local host="${1:-github.com}"

  # 0) preflight
  if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI (gh) is not installed or not on PATH."
    return 1
  fi

  # 1) Already authenticated?
if gh auth status -h github.com &>/dev/null; then
  # Try to extract the account name from the status output
  acct="$(
    gh auth status -h github.com 2>/dev/null \
      | awk -F 'account ' '/Logged in to/ {print $2}' \
      | awk '{print $1}'
  )"

  if [[ -n "$acct" ]]; then
    log_info "Already logged in GitHub (account: ${acct})"
  else
    log_info "Already logged in GitHub"
  fi
  return 0
fi

  log_info "GitHub CLI is not authenticated for $host."

  # 2) try token-based auth first (env var or prompt)
  local _tkn="${GITHUB_TOKEN:-}"
  if [[ -z "${_tkn}" ]]; then
    if [[ -t 0 && -z "${CI:-}" ]]; then
      read -rsp "Paste your GitHub Personal Access Token (input hidden) or press Enter to skip: " _tkn
      echo
    fi
  fi

  if [[ -n "${_tkn}" ]]; then
    if (( ${#_tkn} < 20 )); then
      log_warn "Token looks unusually short; double-check if login fails."
    fi

    if printf '%s' "${_tkn}" | gh auth login \
          --hostname "$host" \
          --git-protocol https \
          --with-token >/dev/null; then
      unset _tkn
      gh auth setup-git --hostname "$host" >/dev/null 2>&1 || true
      if gh auth status -h "$host" &>/dev/null; then
        log_success "GitHub CLI authentication successful (token)."
        return 0
      fi
    else
      log_warn "Token-based login failed."
    fi
    unset _tkn
  else
    log_info "No token provided; will try manual login if possible."
  fi

  # 3) fallback: manual interactive login (only if TTY is available)
  if [[ -t 0 && -t 1 && -z "${CI:-}" ]]; then
    log_info "Starting interactive 'gh auth login' wizard…"
    # Let gh prompt you; you can choose browser/device flow as needed
    if gh auth login --hostname "$host" --git-protocol https; then
      gh auth setup-git --hostname "$host" >/dev/null 2>&1 || true
      if gh auth status -h "$host" &>/dev/null; then
        log_success "GitHub CLI authentication successful (manual)."
        return 0
      fi
    fi
    log_error "Interactive login did not complete successfully."
    return 1
  fi

  # 4) non-interactive environments (no TTY/CI)
  log_error "Cannot start manual login in a non-interactive environment."
  log_info "Provide a token in \$GITHUB_TOKEN or run locally with a TTY:"
  log_info "  export GITHUB_TOKEN=YOUR_TOKEN && ${BASH_SOURCE[0]##*/}   # or re-run your wrapper"
  log_info "  gh auth login --hostname $host --with-token < <(printf '%s' \"\$GITHUB_TOKEN\")"
  return 1
}


main() {
  local cmd="${1:-all}"
  case "$cmd" in
    git) configure_git_identity ;;
    gh)  authenticate_gh ;;
    all) configure_git_identity; authenticate_gh ;;
    -h|--help|help) usage ;;
    *) log_error "Unknown subcommand: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
