#!/usr/bin/env bash
# menus/lib/ui.sh - tiny UI toolkit for pretty shell menus
set -Eeuo pipefail

# Try to import project colors if available
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/colors.sh" ]]; then
  # shellcheck source=/dev/null
  source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/colors.sh" || true
fi

# Fallback colors
if ! command -v tput >/dev/null 2>&1; then
  tput() { return 0; }
fi
: "${BOLD:=$(tput bold || true)}"
: "${RESET:=$(tput sgr0 || true)}"
: "${FG_PRIMARY:=$(tput setaf 6 || true)}"
: "${FG_ACCENT:=$(tput setaf 14 || true)}"
: "${FG_OK:=$(tput setaf 2 || true)}"
: "${FG_WARN:=$(tput setaf 3 || true)}"
: "${FG_ERR:=$(tput setaf 1 || true)}"

repeat_char() { printf "%${2}s" "" | tr " " "${1}"; }

hr() { echo -e "${FG_PRIMARY}$(repeat_char "─" "${1:-60}")${RESET}"; }

print_header() {
  local title="${1:-Menu}" width="${2:-66}"
  hr "$width"
  echo -e "${BOLD}${FG_PRIMARY}  ${title}${RESET}"
  hr "$width"
}

print_footer() { hr "${1:-66}"; }

confirm() {
  local prompt="${1:-Proceed?}"
  read -rp "$(echo -e "${FG_ACCENT}${prompt} [y/N]${RESET} ")" ans || true
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

pause() {
  read -rp "$(echo -e "${FG_ACCENT}Press ENTER to continue...${RESET}")" _ || true
}

_info(){ echo -e "${FG_ACCENT}ℹ $*${RESET}"; }
ok(){ echo -e "${FG_OK}✔ $*${RESET}"; }
warn(){ echo -e "${FG_WARN}▲ $*${RESET}"; }
err(){ echo -e "${FG_ERR}✖ $*${RESET}" 1>&2; }
