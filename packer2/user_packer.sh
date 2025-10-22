ssh root@192.168.88.250 'bash -s' <<'EOF'
#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

# ======= Config =======
USER_ID="packer@pve"
ROLE_ID="packer_role"
TOKEN_ID="packer_token"

# Optional token expiry (epoch seconds). Leave empty for no expiry.
EXPIRY_EPOCH=""

# Where to grant the ACL. Adjust to least privilege when you know your scope.
ACL_PATHS=("/")

# File on the Proxmox host to store the token secret (created on token creation only).
TOKEN_SECRET_FILE="/root/packer_token_secret.txt"

# Role privileges suitable for PVE 9 (no VM.Monitor). Add or remove as needed.
PRIVS=(
  "Datastore.Audit"
  "Datastore.AllocateSpace"
  "Pool.Audit"
  "Sys.Audit"
  "VM.Allocate"
  "VM.Audit"
  "VM.Config.CPU"
  "VM.Config.Disk"
  "VM.Config.Memory"
  "VM.Config.Network"
  "VM.Config.HWType"
  "VM.Config.Options"
  "VM.PowerMgmt"
  # If your builds read guest-agent data (IPs, etc.), also add:
  # "VM.GuestAgent.Audit"
  # If you use cloud-init:
  # "VM.Config.Cloudinit"
)

# ======= Helpers =======
join_privs() { local IFS=' '; echo "${PRIVS[*]}"; }

user_exists()  { pveum user list  | awk '{print $1}' | grep -qx "$USER_ID"; }
role_exists()  { pveum role list  | awk '{print $1}' | grep -qx "$ROLE_ID"; }
token_exists() { pveum user token list "$USER_ID" 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$TOKEN_ID" || true; }
acl_present()  { pveum acl list | awk -v u="$USER_ID" -v r="$ROLE_ID" -v p="$1" '$1==p && $2==u && $3==r {found=1} END{exit found?0:1}'; }

# Try to extract "value" from JSON via jq; fallback to sed if jq absent.
extract_token_secret() {
  local json="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.value // .data.value // empty' <<<"$json"
  else
    sed -n 's/.*"value":"\([^"]*\)".*/\1/p' <<<"$json"
  fi
}

# ======= Functions =======
delete_all() {
  echo "== Teardown: deleting token(s), ACLs, user, and role if present =="
  if user_exists; then
    # Remove all tokens for this user (defensive, in case more than one exists)
    mapfile -t TOKS < <(pveum user token list "$USER_ID" 2>/dev/null | awk 'NR>1{print $1}')
    for t in "${TOKS[@]:-}"; do
      echo "Removing token: $USER_ID $t"
      pveum user token remove "$USER_ID" "$t" || true
    done

    # Remove any ACLs referencing user+role
    mapfile -t PATHS < <(pveum acl list | awk -v u="$USER_ID" -v r="$ROLE_ID" '$2==u && $3==r {print $1}' | sort -u)
    for p in "${PATHS[@]:-}"; do
      echo "Removing ACL at $p for $USER_ID role $ROLE_ID"
      pveum acldel "$p" -user "$USER_ID" -role "$ROLE_ID" || true
    done

    # Delete user
    echo "Deleting user: $USER_ID"
    pveum user delete "$USER_ID" || true
  else
    echo "User not present: $USER_ID"
  fi

  # Delete role
  if role_exists; then
    echo "Deleting role: $ROLE_ID"
    pveum role delete "$ROLE_ID" || true
  else
    echo "Role not present: $ROLE_ID"
  fi

  echo "== Teardown complete =="
}

create_all() {
  echo "== Create: user, role, ACLs, and token =="

  # User
  if user_exists; then
    echo "User exists: $USER_ID"
  else
    pveum user add "$USER_ID" --comment "Packer automation user"
    echo "Created user: $USER_ID"
  fi

  # Role (ensure privileges match)
  if role_exists; then
    echo "Role exists: $ROLE_ID (ensuring privileges match)"
    pveum role modify "$ROLE_ID" -privs "$(join_privs)"
  else
    pveum role add "$ROLE_ID" -privs "$(join_privs)"
    echo "Created role: $ROLE_ID"
  fi

  # ACLs
  for path in "${ACL_PATHS[@]}"; do
    if acl_present "$path"; then
      echo "ACL already present on ${path} for ${USER_ID} as ${ROLE_ID}"
    else
      pveum aclmod "$path" -user "$USER_ID" -role "$ROLE_ID"
      echo "Granted ${ROLE_ID} to ${USER_ID} at ${path}"
    fi
  done

  # Token (always create fresh here)
  if token_exists; then
    echo "Existing token found for $USER_ID: $TOKEN_ID (will rotate)"
    pveum user token remove "$USER_ID" "$TOKEN_ID" || true
  fi

  echo "Creating token: $USER_ID $TOKEN_ID"
  if [[ -n "$EXPIRY_EPOCH" ]]; then
    OUT="$(pveum user token add "$USER_ID" "$TOKEN_ID" --privsep 0 --expire "$EXPIRY_EPOCH" --output-format json)"
  else
    OUT="$(pveum user token add "$USER_ID" "$TOKEN_ID" --privsep 0 --output-format json)"
  fi

  SECRET="$(extract_token_secret "$OUT" || true)"
  echo "Token ID: ${USER_ID}!${TOKEN_ID}"

  if [[ -n "$SECRET" ]]; then
    echo "==== SAVE THIS SECRET NOW ===="
    echo "$SECRET"
    echo "=============================="
    # Write to local file with strict perms
    umask 177
    printf "%s\n" "$SECRET" > "$TOKEN_SECRET_FILE"
    chmod 600 "$TOKEN_SECRET_FILE"
    echo "Token secret written to: $TOKEN_SECRET_FILE"
  else
    echo "Token created but secret could not be parsed. Raw output follows:"
    echo "$OUT"
    echo "You may wish to install 'jq' for reliable parsing: apt-get update && apt-get install -y jq"
  fi

  echo "== Create complete =="
}

# ======= Run sequence: delete then create =======
delete_all
create_all

EOF
