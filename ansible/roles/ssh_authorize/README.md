# Role: ssh_authorize

Installs the cached localhost public key into remote users' `authorized_keys`.

## Input
- `hostvars['localhost']['ssh_client_public_key']` (set by `ssh_client` role)

## Vars
- `ssh_authorize_target_user` (default: `ansible_user` or `root`)
