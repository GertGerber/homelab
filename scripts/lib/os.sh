#!/usr/bin/env bash
set -Eeuo pipefail

# Defaults
OS_ID="unknown"
OS_VERSION_ID=""
OS_FAMILY="unknown"
ARCH="$(uname -m)"

# Prefer /etc/os-release when present
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  # Some distros quote VERSION_ID; strip quotes safely
  OS_ID="${ID:-unknown}"
  OS_VERSION_ID="${VERSION_ID:-}"
fi

# macOS (no /etc/os-release)
if [[ "${OS_ID}" == "unknown" ]]; then
  if uname -s | grep -qi '^darwin$'; then
    OS_ID="macos"
    OS_FAMILY="darwin"
    OS_VERSION_ID="$(sw_vers -productVersion 2>/dev/null || echo "")"
  fi
fi

# WSL detection (optional, helpful)
if [[ "$OS_ID" != "unknown" ]] && grep -qi 'microsoft' /proc/version 2>/dev/null; then
  OS_ID="${OS_ID}-wsl"
fi

# Normalize family
case "${OS_ID}" in
  ubuntu|debian|raspbian|linuxmint|elementary*)
    OS_FAMILY="debian"
    ;;
  fedora|rhel|centos|rocky|almalinux|ol|oracle)
    OS_FAMILY="rhel"
    ;;
  arch|manjaro|endeavouros|arco*)
    OS_FAMILY="arch"
    ;;
  opensuse*|sles)
    OS_FAMILY="suse"
    ;;
  macos|darwin)
    OS_FAMILY="darwin"
    ;;
  *)
    # If we have ID_LIKE from /etc/os-release, try mapping that
    if [[ -n "${ID_LIKE:-}" ]]; then
      case "${ID_LIKE}" in
        *debian*) OS_FAMILY="debian" ;;
        *rhel*|*fedora*) OS_FAMILY="rhel" ;;
        *arch*) OS_FAMILY="arch" ;;
        *suse*) OS_FAMILY="suse" ;;
      esac
    fi
    ;;
esac

# Export for consumers
export OS_ID OS_VERSION_ID OS_FAMILY ARCH
