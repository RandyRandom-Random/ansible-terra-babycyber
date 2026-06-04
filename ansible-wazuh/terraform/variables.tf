variable "pm_api_url" {
  type        = string
  description = "URL API Proxmox (ex: https://192.168.50.254:8006/api2/json)"
}

variable "pm_api_token" {
  type        = string
  sensitive   = true
  description = "Token Proxmox au format '<token-id>=<secret>' (ex: terraform@pve!ci=<uuid>)"
}

variable "ci_user" {
  type        = string
  default     = "admin_ansible"
  description = "Utilisateur cloud-init"
}

variable "ci_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe cloud-init"
}

variable "target_node" {
  type        = string
  default     = "aliexpress"
  description = "Node Proxmox cible"
}

variable "template_id" {
  type        = number
  default     = 9003
  description = "ID de la golden image AlmaLinux 10"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Liste des clefs SSH publiques pour cloud-init"
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.50.1"]
}

variable "dns_domain" {
  type    = string
  default = "cyberbaby.lab"
}
