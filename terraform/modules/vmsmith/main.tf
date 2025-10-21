terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vmsmithy" {
  name        = var.vm_name
  description = "VM Managed by Terraform"
  tags        = [var.tag_name, "terraform"]
  node_name   = var.vm_host
  vm_id       = var.vm_id
  machine     = var.vm_machine_type

  clone {
    vm_id        = var.template_id
    datastore_id = var.disks[0].storage
    full         = true
  }

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory
  }


  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id = disk.value.storage
      file_format  = "raw"
      interface    = "scsi${disk.key + 1}"
      size         = disk.value.size
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      model  = network_device.value.model
      bridge = network_device.value.bridge
    }
  }

  agent {
    enabled = true
  }

  operating_system {
    type = var.ostype
  }


  on_boot = var.boot_on
  started = true

  initialization {
    datastore_id      = var.disks[0].storage
    user_data_file_id = "snippets:snippets/shared-cloud-init.yaml"
    interface         = "ide2"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_device,
    initialization]
  }
}
