# VM Monitoring (Prometheus + Grafana)
# Aligné sur la structure d'infta/terraform-cyberbaby (provider bpg/proxmox).
# Cette VM est gérée par CE repo (pas par terraform-cyberbaby) car c'est un
# ajout spécifique au projet SIEM/Wazuh. La VM WazuhSiem reste gérée par
# infta/terraform-cyberbaby (state séparé).

locals {
  monitor_vms = {
    "FRMONITOR01P" = {
      vlan   = 50
      ram    = 2048
      cores  = 2
      ip     = "192.168.50.11/24"
      gw     = "192.168.50.1"
      dns    = ["192.168.50.1"]
      domain = "cyberbaby.lab"
    }
  }
}

resource "proxmox_virtual_environment_vm" "monitor" {
  for_each = local.monitor_vms

  name      = each.key
  node_name = var.target_node

  clone {
    vm_id = var.template_id
  }

  # qemu-guest-agent désactivé : le virtio-serial device n'est pas exposé
  # par le golden image, donc TF restait bloqué à "Still modifying..."
  agent {
    enabled = false
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = 20
  }

  network_device {
    bridge  = "vmbr1"
    model   = "virtio"
    vlan_id = each.value.vlan
  }

  operating_system {
    type = "l26"
  }

  vga {
    memory = 16
    type   = "std"
  }

  initialization {
    datastore_id = "local"
    interface    = "scsi1"

    dns {
      servers = each.value.dns
      domain  = each.value.domain
    }

    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = var.ssh_public_keys
    }

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = each.value.gw
      }
    }
  }
}

output "monitor_ips" {
  description = "IP de la VM Monitor"
  value = {
    for name, vm in proxmox_virtual_environment_vm.monitor :
    name => vm.initialization[0].ip_config[0].ipv4[0].address
  }
}
