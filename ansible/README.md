# Homelab Ansible — Controller + SSH Keys + Proxmox Identity

## What this does
1) **Bootstrap Local (controller)** — sets up a Python venv, required Python libs (`proxmoxer`, `requests`), common CLI tools, and optionally HashiCorp tools (`terraform`, `packer`).
2) **SSH Keys** — generates a controller keypair and installs the public key on Proxmox hosts.
3) **Proxmox Identity (via SSH)** — on the Proxmox node(s), creates the service **user**, **custom role**, and **API token**; writes the token secret **locally** for reuse by Ansible/Packer/Terraform.  
   - If the local token file is missing later, the playbook **rotates** the token server-side and re-saves the secret.

> After step 2, all subsequent steps **must** use SSH keys only (no passwords). The identity playbook will **fail** if a password is used.

---

## Prereqs
- Inventory contains a `[proxmox]` group.
- You can run Ansible from a controller (your machine/CI) with `python3`.

---

## One-time setup

```bash
# 0) Collections (once)
ansible-galaxy collection install -r scripts/etc/ansible/requirements.yml

# 1) Bootstrap the controller (venv, tools)
ansible-playbook ansible/playbooks/01_bootstrap_local.yml --tags local,hashicorp

# 2) SSH keys to nodes
ansible-playbook ansible/playbooks/02_ssh_keys.yml --tags ssh

# 3) Identity (user/role/token), keys-only + local token rotation if missing
ansible-playbook ansible/playbooks/03_proxmox_identity.yml --tags identity
