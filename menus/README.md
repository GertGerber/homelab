# Menus Module (Bash)

A modular TUI menu system that plugs into your project and calls your existing `./homelab` entrypoint.

## Layout
```
menus/
  menu.sh                # Entry point
  lib/ui.sh              # UI helpers & colors (uses your scripts/lib/colors.sh if present)
  modules/
    bash_scripts.sh      # Runs ./homelab <option> with pretty prompts
    ansible.sh           # "Create SSH" workflow (homelab + fallbacks)
    packer.sh            # Simple packer helpers
    terraform.sh         # Simple terraform helpers
```

## Usage
Copy `menus/` into the root of your repo (next to your `scripts/` folder) and run:
```bash
chmod +x menus/menu.sh
menus/menu.sh
```

The Bash Scripts submenu exposes these `./homelab <option>` targets:
- bootstrap
- common
- python
- ansible
- hashicorp
- login
- all
- doctor
- help

## Notes
- The menu tries `./scripts/bin/homelab` first, then falls back to `./homelab`. Override with `HOMELAB_CMD=/path/to/homelab`.
- Colors: if your project has `scripts/lib/colors.sh`, it will be sourced automatically.
- Ansible → Create SSH tries `homelab ansible create-ssh`, then falls back to sensible defaults (local ED25519 key, then attempts known playbooks/scripts if present).
