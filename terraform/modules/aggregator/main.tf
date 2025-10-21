terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.73"
    }
  }
}


locals {

  has_k8s        = length(var.k8s_clusters) > 0
  has_standalone = length(var.standalone_vms) > 0
  has_other      = length(var.other_clusters) > 0

  standalone_groups = {
    for vm_name, vm in var.standalone_vms : vm_name => {
      name         = vm.name
      ip           = vm.ip
      proxmox_host = vm.proxmox_host
      tags         = vm.tags
    }
  }


  template_vars = {
    k8s_clusters      = var.k8s_clusters
    standalone_vms    = var.standalone_vms
    other_clusters    = var.other_clusters
    has_k8s           = local.has_k8s
    has_standalone    = local.has_standalone
    has_other         = local.has_other
    standalone_groups = local.standalone_groups
    proxmox_hosts     = var.proxmox_hosts
  }

  inventory_content = join("\n", [
    templatefile("${path.module}/templates/vmsmith_inventory.tpl", local.template_vars),
    templatefile("${path.module}/templates/k8s_inventory.tpl", local.template_vars),
    templatefile("${path.module}/templates/other_inventory.tpl", local.template_vars),
  ])
}

resource "local_file" "inventory" {
  filename        = var.inventory_path
  content         = local.inventory_content
  file_permission = "0644"
}
