# ═════════════════════════════════════════════════════════════════════
#  TEMPLATE — Terraform pour Proxmox (provider bpg/proxmox)
# ─────────────────────────────────────────────────────────────────────
#  Description : provisionner une VM Debian sur Proxmox via clone d'une
#                golden image (template VM), avec cloud-init.
#  Usage       :
#    cp terraform.tfvars.example terraform.tfvars  # remplir les secrets
#    terraform init
#    terraform plan
#    terraform apply
#    terraform destroy        # ⚠️ supprime la VM
# ═════════════════════════════════════════════════════════════════════

# ─── 1. Providers ─────────────────────────────────────────────────
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }

  # Backend GitLab (state distant — recommandé pour la CI)
  # Décommenter et passer les arguments via `terraform init -backend-config=`
  # backend "http" {}

  # ou backend local (par défaut, dev only)
  # backend "local" {}
}

provider "proxmox" {
  endpoint  = var.pm_api_url              # https://proxmox.lan:8006/api2/json
  api_token = var.pm_api_token            # user@realm!token-id=<secret>
  insecure  = true                        # cert self-signed : true ; sinon false
  ssh {
    agent = false
  }
}


# ─── 2. Variables (à passer via *.tfvars ou env TF_VAR_*) ────────
variable "pm_api_url" {
  type        = string
  description = "URL de l'API Proxmox"
}

variable "pm_api_token" {
  type        = string
  description = "Token API au format 'user@realm!tokenid=<secret>'"
  sensitive   = true
}

variable "target_node" {
  type        = string
  description = "Nom du node Proxmox"
  default     = "pve"
}

variable "template_id" {
  type        = number
  description = "VMID du template à cloner (golden image)"
  default     = 9000
}

variable "vm_name" {
  type        = string
  description = "Nom DNS-compatible de la VM (a-z, 0-9, -)"
  default     = "myvm"
}

variable "vm_ip" {
  type        = string
  description = "Adresse IP/CIDR de la VM"
  default     = "192.168.50.100/24"
}

variable "vm_gateway" {
  type        = string
  default     = "192.168.50.1"
}

variable "vlan_id" {
  type        = number
  description = "Tag VLAN (0 = pas de VLAN)"
  default     = 50
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_ram" {
  type        = number
  description = "RAM en MiB"
  default     = 2048
}

variable "vm_disk_size" {
  type        = number
  description = "Taille disque en GiB"
  default     = 20
}

variable "storage" {
  type    = string
  default = "local-lvm"
}

variable "ci_user" {
  type    = string
  default = "admin_ansible"
}

variable "ci_password" {
  type      = string
  sensitive = true
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Clefs SSH publiques injectées via cloud-init"
}


# ─── 3. Ressource VM ──────────────────────────────────────────────
resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  node_name   = var.target_node
  description = "VM Terraformée — clonée de template ${var.template_id}"
  tags        = ["terraform", var.vm_name]

  clone {
    vm_id = var.template_id
    # full = true  # clone complet (par défaut)
  }

  agent {
    enabled = false      # passer à true si qemu-guest-agent est dans le template
  }

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.vm_ram
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  network_device {
    bridge  = "vmbr1"
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  operating_system {
    type = "l26"          # Linux 2.6+
  }

  # ─── Cloud-init ─────────────────────────────────────────────────
  initialization {
    datastore_id = var.storage
    interface    = "scsi1"

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
      domain  = "lan"
    }

    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = var.ssh_public_keys
    }

    ip_config {
      ipv4 {
        address = var.vm_ip
        gateway = var.vm_gateway
      }
    }
  }

  # Ignore les changements qui surviennent post-clone (modifs manuelles via GUI)
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


# ─── 4. Outputs ──────────────────────────────────────────────────
output "vm_id" {
  description = "VMID Proxmox attribué"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.vm.name
}

output "vm_ip" {
  description = "IP de la VM (sans le /CIDR)"
  value       = split("/", var.vm_ip)[0]
}

output "ssh_command" {
  description = "Commande SSH prête à coller"
  value       = "ssh -i ~/.ssh/id_ed25519 ${var.ci_user}@${split("/", var.vm_ip)[0]}"
}
