variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_host" {
  type        = string
  description = "Proxmox host to deploy the VM on"
}

variable "vm_id" {
  type        = number
  description = "ID for the virtual machine"
}

variable "template_id" {
  type        = number
  description = "Template ID to clone from"
}

variable "vm_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "vm_memory" {
  type        = number
  description = "Memory in MB"
  default     = 2048
}

variable "vm_machine_type" {
  type        = string
  description = "Machine type"
  default     = "q35"
}

variable "ostype" {
  type        = string
  description = "Operating system type"
  default     = "l26"
}

variable "boot_on" {
  type        = bool
  description = "Whether to automatically boot the VM"
  default     = true
}

variable "tag_name" {
  type        = string
  description = "Primary tag for the VM"
}

variable "network_devices" {
  description = " List of network devices to attach to"
  type = list(object({
    bridge = string
    model  = string
  }))
  default = [
    {
      bridge = "vmbr0"
      model  = "virtio"
    }
  ]
}

variable "disks" {
  description = "Configuration for VM disks"
  type = list(object({
    storage = string
    size    = string
  }))
  default = [
    {
      storage = "local-lvm"
      size    = "32G"
    }
  ]
}
