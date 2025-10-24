How to run
```bash
# 1) generate/push SSH keys only
ansible-playbook playbooks/ssh.yml -i inventory/hosts.ini

# 2) Proxmox API bootstrap only (user/role/token/ACL + local token file)
PVE_ROOT_PASSWORD=... PVE_SERVICE_USER_PASSWORD=... \
ansible-playbook playbooks/proxmox.yml -i inventory/hosts.ini
```