# Homelab2 Bash Scaffold

This canvas contains a complete, modular Bash scaffold that matches your requested layout and behaviors.

---

## Repository layout

```
scripts/
  bin/
    homelab                 # Entry point
  lib/
    colors.sh               # Catppuccin colors + helpers (DARK/LIGHT/AUTO)
    log.sh                  # Logging helpers (info/success/warn/err/die)
    os.sh                   # OS detection (ID/Version/Arch)
    pm.sh                   # Package manager helpers (nala-first, apt fallback)
    utils.sh                # Sudo, ownership, config loader, common helpers
  opt/
    common.sh               # Base utilities (curl, git, gh, build tools, etc.)
    python.sh               # Python, pipx, venv setup
    ansible.sh              # Ansible install + galaxy requirements
    hashicorp.sh            # Terraform & Packer (HashiCorp repo)
  etc/
    config.env              # System-wide defaults (safe to version control)
    ansible/
      requirements.yml      # Galaxy roles/collections

~/.config/app_name/
  config.env                # User-specific overrides (NOT in repo)
```

> All scripts are POSIX-ish Bash (requiring bash), use `set -Eeuo pipefail`, colorful logging, strict error handling, and minimal sudo (only when needed). Debian/Ubuntu-family supported out of the box; adding other distros is straightforward in `lib/os.sh` and `lib/pm.sh`.

---

## scripts/bin/homelab

```bash
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
  hashicorp)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/hashicorp.sh" "$@" ;;
  all)
    ensure_pm_ready
    pm_update
    "${OPT_DIR}/common.sh"
    "${OPT_DIR}/python.sh"
    "${OPT_DIR}/ansible.sh"
    "${OPT_DIR}/hashicorp.sh" ;;
  *)
    usage ;;
 esac
```

---

## scripts/lib/colors.sh

```bash
#!/usr/bin/env bash
# Catppuccin palette with LIGHT/DARK/AUTO. Output 24-bit color escapes.
# Provides: color_rgb <NAME>, fg <NAME> [text], bg <NAME> [text], reset

set -Eeuo pipefail

# THEME_MODE: auto|light|dark (overridden via config)
: "${THEME_MODE:=auto}"

# crude auto detection from common envs/terms
_detect_auto_theme() {
  case "${THEME_MODE}" in
    auto)
      if [[ "${GTK_THEME:-}" =~ -dark$ || "${COLORSCHEME:-}" == dark || "${TERM_THEME:-}" == dark ]]; then
        echo dark
      else
        echo light
      fi ;;
    *) echo "${THEME_MODE}" ;;
  esac
}

THEME=$(_detect_auto_theme)

color_rgb() {
  local key=${1^^}
  case "$key" in
    # LATTE (light)
    LATTE:ROSEWATER) echo "220;138;120" ;;  LATTE:FLAMINGO)  echo "221;120;120" ;;
    LATTE:PINK)      echo "234;118;203" ;;  LATTE:MAUVE)     echo "136;57;239"  ;;
    LATTE:RED)       echo "210;15;57"   ;;  LATTE:MAROON)    echo "230;69;83"   ;;
    LATTE:PEACH)     echo "254;100;11"  ;;  LATTE:YELLOW)    echo "223;142;29"  ;;
    LATTE:GREEN)     echo "64;160;43"   ;;  LATTE:TEAL)      echo "23;146;153"  ;;
    LATTE:SKY)       echo "4;165;229"   ;;  LATTE:SAPPHIRE)  echo "32;159;181"  ;;
    LATTE:BLUE)      echo "30;102;245"  ;;  LATTE:LAVENDER)  echo "114;135;253" ;;
    LATTE:TEXT)      echo "76;79;105"   ;;  LATTE:SUBTEXT1)  echo "92;95;119"   ;;
    LATTE:SUBTEXT0)  echo "108;111;133" ;;  LATTE:OVERLAY2)  echo "124;127;147" ;;
    LATTE:OVERLAY1)  echo "140;143;161" ;;  LATTE:OVERLAY0)  echo "156;160;176" ;;
    LATTE:SURFACE2)  echo "172;176;190" ;;  LATTE:SURFACE1)  echo "188;192;204" ;;
    LATTE:SURFACE0)  echo "204;208;218" ;;  LATTE:BASE)      echo "239;241;245" ;;
    LATTE:MANTLE)    echo "230;233;239" ;;  LATTE:CRUST)     echo "220;224;232" ;;
    # FRAPPE
    FRAPPE:ROSEWATER) echo "242;213;207" ;; FRAPPE:FLAMINGO)  echo "238;190;190" ;;
    FRAPPE:PINK)      echo "244;184;228" ;; FRAPPE:MAUVE)     echo "202;158;230" ;;
    FRAPPE:RED)       echo "231;130;132" ;; FRAPPE:MAROON)    echo "234;153;156" ;;
    FRAPPE:PEACH)     echo "239;159;118" ;; FRAPPE:YELLOW)    echo "229;200;144" ;;
    FRAPPE:GREEN)     echo "166;209;137" ;; FRAPPE:TEAL)      echo "129;200;190" ;;
    FRAPPE:SKY)       echo "153;209;219" ;; FRAPPE:SAPPHIRE)  echo "133;193;220" ;;
    FRAPPE:BLUE)      echo "140;170;238" ;; FRAPPE:LAVENDER)  echo "186;187;241" ;;
    FRAPPE:TEXT)      echo "198;208;245" ;; FRAPPE:SUBTEXT1)  echo "181;191;226" ;;
    FRAPPE:SUBTEXT0)  echo "165;173;206" ;; FRAPPE:OVERLAY2)  echo "148;156;187" ;;
    FRAPPE:OVERLAY1)  echo "131;139;167" ;; FRAPPE:OVERLAY0)  echo "115;121;148" ;;
    FRAPPE:SURFACE2)  echo "98;104;128"  ;; FRAPPE:SURFACE1)  echo "81;87;109"   ;;
    FRAPPE:SURFACE0)  echo "65;69;89"    ;; FRAPPE:BASE)      echo "48;52;70"    ;;
    FRAPPE:MANTLE)    echo "41;44;60"    ;; FRAPPE:CRUST)     echo "35;38;52"    ;;
    # MACCHIATO
    MACCHIATO:ROSEWATER) echo "244;219;214" ;; MACCHIATO:FLAMINGO)  echo "240;198;198" ;;
    MACCHIATO:PINK)      echo "245;189;230" ;; MACCHIATO:MAUVE)     echo "198;160;246" ;;
    MACCHIATO:RED)       echo "237;135;150" ;; MACCHIATO:MAROON)    echo "238;153;160" ;;
    MACCHIATO:PEACH)     echo "245;169;127" ;; MACCHIATO:YELLOW)    echo "238;212;159" ;;
    MACCHIATO:GREEN)     echo "166;218;149" ;; MACCHIATO:TEAL)      echo "139;213;202" ;;
    MACCHIATO:SKY)       echo "145;215;227" ;; MACCHIATO:SAPPHIRE)  echo "125;196;228" ;;
    MACCHIATO:BLUE)      echo "138;173;244" ;; MACCHIATO:LAVENDER)  echo "183;189;248" ;;
    MACCHIATO:TEXT)      echo "202;211;245" ;; MACCHIATO:SUBTEXT1)  echo "184;192;224" ;;
    MACCHIATO:SUBTEXT0)  echo "165;173;203" ;; MACCHIATO:OVERLAY2)  echo "147;154;183" ;;
    MACCHIATO:OVERLAY1)  echo "128;135;162" ;; MACCHIATO:OVERLAY0)  echo "110;115;141" ;;
    MACCHIATO:SURFACE2)  echo "91;96;120"   ;; MACCHIATO:SURFACE1)  echo "73;77;100"   ;;
    MACCHIATO:SURFACE0)  echo "54;58;79"    ;; MACCHIATO:BASE)      echo "36;39;58"    ;;
    MACCHIATO:MANTLE)    echo "30;32;48"    ;; MACCHIATO:CRUST)     echo "24;25;38"    ;;
    # MOCHA (dark)
    MOCHA:ROSEWATER) echo "245;224;220" ;;  MOCHA:FLAMINGO)  echo "242;205;205" ;;
    MOCHA:PINK)      echo "245;194;231" ;;  MOCHA:MAUVE)     echo "203;166;247" ;;
    MOCHA:RED)       echo "243;139;168" ;;  MOCHA:MAROON)    echo "235;160;172" ;;
    MOCHA:PEACH)     echo "250;179;135" ;;  MOCHA:YELLOW)    echo "249;226;175" ;;
    MOCHA:GREEN)     echo "166;227;161" ;;  MOCHA:TEAL)      echo "148;226;213" ;;
    MOCHA:SKY)       echo "137;220;235" ;;  MOCHA:SAPPHIRE)  echo "116;199;236" ;;
    MOCHA:BLUE)      echo "137;180;250" ;;  MOCHA:LAVENDER)  echo "180;190;254" ;;
    MOCHA:TEXT)      echo "205;214;244" ;;  MOCHA:SUBTEXT1)  echo "186;194;222" ;;
    MOCHA:SUBTEXT0)  echo "166;173;200" ;;  MOCHA:OVERLAY2)  echo "147;153;178" ;;
    MOCHA:OVERLAY1)  echo "127;132;156" ;;  MOCHA:OVERLAY0)  echo "108;112;134" ;;
    MOCHA:SURFACE2)  echo "88;91;112"   ;;  MOCHA:SURFACE1)  echo "69;71;90"    ;;
    MOCHA:SURFACE0)  echo "49;50;68"    ;;  MOCHA:BASE)      echo "30;30;46"    ;;
    MOCHA:MANTLE)    echo "24;24;37"    ;;  MOCHA:CRUST)     echo "17;17;27"    ;;
    *) echo "255;255;255" ;;
  esac
}

# Map semantic color names to palette entries depending on THEME
_level_to_palette() {
  local level=${1^^}
  case "$THEME:$level" in
    light:INFO) echo "LATTE:BLUE" ;;
    light:SUCCESS) echo "LATTE:GREEN" ;;
    light:WARN) echo "LATTE:YELLOW" ;;
    light:ERROR) echo "LATTE:RED" ;;
    dark:INFO) echo "MOCHA:BLUE" ;;
    dark:SUCCESS) echo "MOCHA:GREEN" ;;
    dark:WARN) echo "MOCHA:YELLOW" ;;
    dark:ERROR) echo "MOCHA:RED" ;;
    *:DIM) [[ $THEME == dark ]] && echo "MOCHA:SUBTEXT0" || echo "LATTE:SUBTEXT0" ;;
    *) [[ $THEME == dark ]] && echo "MOCHA:TEXT" || echo "LATTE:TEXT" ;;
  esac
}

# 24-bit color sequences
_fg_seq() { local rgb; rgb=$(color_rgb "$1"); echo -e "\e[38;2;${rgb}m"; }
_bg_seq() { local rgb; rgb=$(color_rgb "$1"); echo -e "\e[48;2;${rgb}m"; }
reset="\e[0m"

fg() { local name=$1; shift || true; echo -ne "$(_fg_seq "$name")"; [[ $# -gt 0 ]] && { echo -ne "$*"; echo -ne "$reset"; } }
bg() { local name=$1; shift || true; echo -ne "$(_bg_seq "$name")"; [[ $# -gt 0 ]] && { echo -ne "$*"; echo -ne "$reset"; } }

# Public helpers for log module
log_color_for() {
  local level=${1^^}; local palette=$(_level_to_palette "$level"); echo "$palette"
}
```

---

## scripts/lib/log.sh

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# requires colors.sh

_timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

_log() {
  local level="$1"; shift
  local palette=$(log_color_for "$level")
  local prefix
  prefix="[$(_timestamp)] ${level^^}:"
  echo -e "$(fg "$palette" "$prefix") $*${reset}"
}

log_info()    { _log INFO    "$@"; }
log_success() { _log SUCCESS "$@"; }
log_warn()    { _log WARN    "$@"; }
log_error()   { _log ERROR   "$@"; }

die() { log_error "$*"; exit 1; }

# Rich error/trace reporting
trap_err() {
  local ec=${1:-$?}
  local i=0
  log_error "Command failed with exit $ec"
  while caller $i >/dev/null 2>&1; do
    local frame; frame=$(caller $i)
    # frame: line func file
    local line func file
    line=$(awk '{print $1}' <<<"$frame")
    func=$(awk '{print $2}' <<<"$frame")
    file=$(awk '{print $3}' <<<"$frame")
    echo -e "$(fg "$(_level_to_palette DIM)" "  at ${file}:${line} in ${func}")${reset}"
    i=$((i+1))
  done
  exit "$ec"
}

trap_exit() {
  local ec=$?
  if [[ $ec -eq 0 ]]; then
    log_success "Done."
  fi
}
```

---

## scripts/lib/os.sh

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

OS_ID="unknown"; OS_VERSION_ID=""; OS_FAMILY="unknown"; ARCH="$(uname -m)"

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID=${ID:-unknown}
  OS_VERSION_ID=${VERSION_ID:-}
fi

case "$OS_ID" in
  ubuntu|debian|pop|linuxmint) OS_FAMILY="debian" ;;
  *) OS_FAMILY="$OS_ID" ;;
endcase
```

---

## scripts/lib/pm.sh

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# requires log.sh, os.sh, utils.sh

has_cmd() { command -v "$1" >/dev/null 2>&1; }
has_nala() { has_cmd nala; }

pm_name() { if has_nala; then echo nala; else echo apt; fi }

ensure_pm_ready() {
  if [[ "$OS_FAMILY" == debian ]]; then
    if ! has_nala; then
      log_info "nala not found; installing (using apt)"
      sudo_if_needed apt-get update
      sudo_if_needed apt-get install -y nala
    fi
  else
    log_warn "Unsupported OS family '$OS_FAMILY' for nala/apt. Extend pm.sh for your distro."
  fi
}

pm_update() {
  if has_nala; then
    log_info "Updating package lists (nala update)"
    sudo_if_needed nala update
  else
    log_info "Updating package lists (apt-get update)"
    sudo_if_needed apt-get update
  fi
}

pm_upgrade() {
  if has_nala; then
    log_info "Upgrading packages (nala upgrade -y)"
    sudo_if_needed nala upgrade -y
  else
    log_info "Upgrading packages (apt-get upgrade -y)"
    sudo_if_needed apt-get upgrade -y
  fi
}

pm_install() {
  # usage: pm_install pkg1 pkg2 ...
  local pkgs=("$@")
  if (( ${#pkgs[@]} == 0 )); then return 0; fi
  if has_nala; then
    log_info "Installing: ${pkgs[*]} (nala install -y)"
    sudo_if_needed nala install -y "${pkgs[@]}"
  else
    log_info "Installing: ${pkgs[*]} (apt-get install -y)"
    sudo_if_needed apt-get install -y "${pkgs[@]}"
  fi
}
```

---

## scripts/lib/utils.sh

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# requires log.sh

sudo_if_needed() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

ensure_dir() { local d="$1"; [[ -d "$d" ]] || mkdir -p "$d"; }
ensure_owns() {
  # ensure_owns <path> [owner]
  local path="$1" owner="${2:-${SUDO_USER:-$USER}}"
  sudo_if_needed chown -R "$owner":"$owner" "$path"
}

load_configs() {
  # precedence: system-wide then user overrides
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      # shellcheck source=/dev/null
      . "$f"
      log_info "Loaded config: $f"
    fi
  done
}
```

---

## scripts/etc/config.env

```bash
# System-wide defaults; user overrides live in ~/.config/app_name/config.env
THEME_MODE=auto
NONINTERACTIVE=1
```

---

## scripts/opt/common.sh

```bash
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
```

---

## scripts/opt/python.sh

```bash
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

log_info "Installing Python toolchain"

PY_PKGS=(python3 python3-pip python3-venv pipx)
pm_install "${PY_PKGS[@]}"

# Ensure pipx path
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath || true
  log_success "pipx installed and PATH ensured (restart shell if first time)"
fi

log_success "Python toolchain installed"
```

---

## scripts/opt/ansible.sh

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( realpath "${SCRIPT_DIR}/.." )
LIB_DIR="${ROOT_DIR}/lib"
ETC_DIR="${ROOT_DIR}/etc"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/os.sh"
source "${LIB_DIR}/pm.sh"
source "${LIB_DIR}/utils.sh"

log_info "Installing Ansible via pipx"

pm_install python3-pip python3-venv pipx

if command -v pipx >/dev/null 2>&1; then
  pipx install --include-deps ansible || true
  pipx upgrade ansible || true
else
  log_warn "pipx not available; falling back to system ansible"
  pm_install ansible
fi

if command -v ansible-galaxy >/dev/null 2>&1; then
  if [[ -f "${ETC_DIR}/ansible/requirements.yml" ]]; then
    log_info "Installing Ansible Galaxy requirements"
    ansible-galaxy install -r "${ETC_DIR}/ansible/requirements.yml"
  else
    log_warn "No galaxy requirements file at ${ETC_DIR}/ansible/requirements.yml"
  fi
fi

log_success "Ansible setup complete"
```

---

## scripts/opt/hashicorp.sh

```bash
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
```

---

## scripts/etc/ansible/requirements.yml

```yaml
# Example Galaxy requirements; customize per your playbooks
collections:
  - name: community.general
    version: ">=8.0.0"
  - name: ansible.posix
    version: ">=1.5.0"
roles: []
```

---

## README.md

```markdown
# Homelab2 Bash Scripts

A clean, modular Bash harness for bootstrapping a workstation or server using Debian/Ubuntu-family distributions. It prefers **nala** for APT operations (with an **apt** fallback), features robust logging and error handling, and organizes installers per toolstack.

## Layout

```
scripts/bin     # Entry point
scripts/lib     # Helpers (colors, logs, os, pm, utils)
scripts/opt     # Applications (common, python, ansible, hashicorp)
scripts/etc     # Configs and variables (system-wide)
~/.config/app_name/   # User-specific overrides
```

## Quick start

```bash
# From repo root
chmod +x scripts/bin/homelab scripts/opt/*.sh
scripts/bin/homelab doctor
scripts/bin/homelab bootstrap
# or full stack
scripts/bin/homelab all
```

## Configuration

System defaults live in `scripts/etc/config.env`. Per-user overrides go in `~/.config/app_name/config.env` (not version-controlled). Example variables:

```bash
THEME_MODE=auto   # auto|light|dark
NONINTERACTIVE=1  # when 1, installers add -y where appropriate
```

## Logging & Colors

- Uses [Catppuccin](https://catppuccin.com) palettes.
- Theme modes: `auto` (detect), `light` (Latte), `dark` (Mocha).
- Log levels: **INFO**, **SUCCESS**, **WARN**, **ERROR**. Each level maps to an appropriate palette color.

## Error handling

- `set -Eeuo pipefail` in every script.
- `trap_err` prints the exit code and a readable call stack (`file:line in func`).
- The exit trap prints a success footer on clean runs.

## Package management

- Prefers **nala**; installs it if missing (Debian/Ubuntu family).
- `pm_update` never uses `-y`.
- `pm_install` and `pm_upgrade` add `-y`.
- Sudo is used **only** when required (`sudo_if_needed`).

## Distro/OS detection

- `lib/os.sh` reads `/etc/os-release` and sets `OS_ID`, `OS_VERSION_ID`, `OS_FAMILY`, and CPU `ARCH`.
- Current support path targets Debian/Ubuntu-family (Ubuntu, Debian, Pop!_OS, Linux Mint). Extend `pm.sh` for other distros.

## Applications

- **common**: curl, git, gh, build-essential, jq, unzip, etc.
- **python**: python3, pip, venv, pipx (with `pipx ensurepath`).
- **ansible**: via pipx (preferred) or system package; installs Galaxy requirements from `scripts/etc/ansible/requirements.yml`.
- **hashicorp**: Adds official apt repo and installs Terraform & Packer.

## Ownership & Permissions

- Files created by root-owned actions are chowned back to the invoking user when appropriate via `ensure_owns`.

## Extending

- Add new installers under `scripts/opt/<name>.sh` and wire them into `scripts/bin/homelab`.
- For non-Debian distros, add an appropriate branch in `lib/pm.sh`.

## Troubleshooting

- Run `scripts/bin/homelab doctor` to verify OS detection and package manager.
- For verbose tracing, run with `bash -x scripts/opt/<script>.sh`.

## License

MIT (or your preferred license).
```

