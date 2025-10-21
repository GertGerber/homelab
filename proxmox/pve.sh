# creating a user is
# Adding the new user to Proxmox VE
# pveum useradd <userid> --password <password> --comment <comment> --groups <group>

# Where:

# ––password <password> is the password for the new user.

# ––comment <comment> is an optional comment or description for the user.

# ––groups <group> is the group (or groups) to which the user should belong.
#     pveum user add myuser@pve -password MySecurePassword123

# Example:

# pveum useradd user2@pve --password UserSecretPassword111 --comment "user2 – admin group" --groups admin



# Adding roles
# Roles are used to define a set of permissions for users and groups to whom this role is assigned.

# Syntax:

# pveum roleadd <rolename> --privs <privileges>

# Where:

# <rolename> is the name of the role to create.

# ––privs <privileges> is a comma-separated list of privileges to assign to the role (for example, VM.PowerMgmt,VM.Config.Disk).

# Example:

# pveum roleadd vmmanager --privs VM.PowerMgmt,VM.Config.CDROM

# This command creates a role called vmmanager with permissions to manage VM power settings and configure CD-ROMs.

# Modifying an existing role
# Administrators can modify existing roles and permissions with the rolemod command (add or remove privileges).

# Syntax:

# pveum rolemod <rolename> --privs <privileges>

# Example:

# pveum rolemod vmmanager --privs +VM.Config.Network

# This command adds the VM.Config.Network privilege to the vmmanager role.

# Modifying ACL
# Proxmox administrators can modify Access Control Lists (ACL) by assigning roles to users or groups on specific Proxmox objects.

# Syntax:

# pveum aclmod <path> --roles <rolename> --users <userid> --groups <groupname>

# Where:

# <path> is the object path on which to set the ACL (for example, /vms/100 for a specific VM or / for the entire cluster).

# ––roles <rolename> is the role to assign.

# ––users <userid> is the user to whom the role is assigned.

# ––groups <groupname> is the group to whom the role is assigned.

# Example:

# pveum aclmod /vms/104 --roles vmmanager --users user4@pve

# This command assigns the vmmanager role to user4@pve on VM 104, allowing the user (user4) to manage that specific VM according to the privileges in the vmmanager role. The aclremove command is used to remove ACLs from objects accordingly.