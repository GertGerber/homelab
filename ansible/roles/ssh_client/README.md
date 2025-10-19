# Role: ssh_client

Installs an SSH client and generates an ed25519 keypair on `localhost` if absent.  
Exports `ssh_client_public_key` as a cached fact for other plays/roles.

## Defaults
- `ssh_client_key_type: ed25519`
- `ssh_client_key_path: ~/.ssh/id_ed25519`
- `ssh_client_key_comment: <user>@<hostname>`

## Notes
- Uses `community.crypto.openssh_keypair` (install from `requirements.yml`).
