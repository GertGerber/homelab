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