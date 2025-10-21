locals {
  common_vars = {
    vm_host   = "prime"
    vm_cores  = 1
    vm_memory = 4096
    disks = [
      {
        size    = 30
        storage = "local-lvm"
      }
    ]
    network_devices = [
      {
        bridge = "vmbr0"
        model  = "virtio"
      }
    ]
  }

  vms = {
    storage = {
      count       = 1
      template_id = 103
      tag_name    = "storage"
      vm_cores    = 2
      # storage = "quick-storage" # override default storage for the VM
      extr_disks = [
        { size = 100, storage = "monitoring-volume" },
        { size = 100, storage = "k8-volume" },
        { size = 100, storage = "other-volume" },
        { size = 100, storage = "samba-volume" }
      ]
    }

    netforge = {
      count       = 1
      template_id = 103
      tag_name    = "netforge"
    }

    cicd = {
      count       = 1
      template_id = 103
      tag_name    = "cicd"
    }

    monitoring = {
      count       = 1
      template_id = 103
      vm_cores    = 2
      tag_name    = "monitoring"
    }

    vault = {
      count       = 1
      template_id = 103
      tag_name    = "vault"
    }
  }

  base_id_start   = 1100
  sorted_vm_names = sort(keys(local.vms))

  vm_instances = flatten([
    for index, vm_name in local.sorted_vm_names : [
      for i in range(local.vms[vm_name].count) : {
        name        = local.vms[vm_name].count == 1 ? vm_name : "${vm_name}-${i + 1}"
        vm_name     = local.vms[vm_name].count == 1 ? "${vm_name}-server" : "${vm_name}-server-${i + 1}"
        vm_id       = local.base_id_start + index + i
        tag_name    = local.vms[vm_name].tag_name
        template_id = local.vms[vm_name].template_id
        vm_cores    = lookup(local.vms[vm_name], "vm_cores", local.common_vars.vm_cores)
        vm_memory   = lookup(local.vms[vm_name], "vm_memory", local.common_vars.vm_memory)
        disks = concat(
          [
            {
              size    = local.common_vars.disks[0].size
              storage = lookup(local.vms[vm_name], "storage", local.common_vars.disks[0].storage)
            }
          ],
          lookup(local.vms[vm_name], "extr_disks", [])
        )
        network_devices = local.common_vars.network_devices
      }
    ]
  ])
}

#  K8s CLUSTER: PROD
module "k8s_cluster" {
  source = "./modules/k8s"

  cluster_name   = "prod-cluster"
  master_count   = 1
  worker_count   = 2
  ha_count       = 0
  starting_vm_id = 1200

  vm_host         = local.common_vars.vm_host
  template_id     = 103
  vm_cores        = 4
  vm_memory       = 8192
  disks           = local.common_vars.disks
  network_devices = local.common_vars.network_devices
}


#  STANDALONE VMs
module "standalone_vms" {
  source   = "./modules/vmsmith"
  for_each = { for vm in local.vm_instances : vm.name => vm }

  vm_name         = each.value.vm_name
  vm_id           = each.value.vm_id
  tag_name        = each.value.tag_name
  vm_host         = local.common_vars.vm_host
  vm_cores        = local.common_vars.vm_cores
  vm_memory       = local.common_vars.vm_memory
  template_id     = each.value.template_id
  disks           = local.common_vars.disks
  network_devices = local.common_vars.network_devices
}

#  AGGREGATOR
module "aggregator" {
  source         = "./modules/aggregator"
  inventory_path = var.ansible_path

  proxmox_hosts = {
    (local.common_vars.vm_host) = regex("^https?://([^:/]+)", var.proxmox_endpoint)[0]
  }


  k8s_clusters = {
    "prod" = {
      masters  = module.k8s_cluster.master_nodes
      workers  = module.k8s_cluster.worker_nodes
      ha_nodes = module.k8s_cluster.ha_nodes
    }
  }

  standalone_vms = {
    for name, vm in module.standalone_vms : name => {
      name         = vm.vm_name
      ip           = vm.vm_ip
      tags         = vm.vm_tags
      proxmox_host = vm.vm_host
    }
  }

  depends_on = [
    module.k8s_cluster,
    module.standalone_vms
  ]
}
