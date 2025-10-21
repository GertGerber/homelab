variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
}

variable "master_count" {
  type        = number
  description = "Number of master nodes"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 2
}

variable "ha_count" {
  type        = number
  description = "Number of HA nodes"
  default     = 0
}

variable "starting_vm_id" {
  type        = number
  description = "Starting VM ID for the cluster nodes"
  default     = 1100
}

variable "vm_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "vm_memory" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "vm_machine_type" {
  type        = string
  description = "Machine type"
  default     = "q35"
}

variable "vm_host" {
  type        = string
  description = "Proxmox host to deploy the VMs on"
}

variable "template_id" {
  type        = number
  description = "Template ID to clone from"
}
variable "boot_on" {
  type        = bool
  description = "Whether to automatically boot the VM"
  default     = true
}
variable "disks" {
  description = "Configuration for VM disks for all nodes in the cluster."
  type = list(object({
    storage = string
    size    = string
  }))
}

variable "network_devices" {
  description = "List of network devices to attach to all nodes in the cluster."
  type = list(object({
    bridge = optional(string, "vmbr0")
    model  = optional(string, "virtio")
  }))
}
