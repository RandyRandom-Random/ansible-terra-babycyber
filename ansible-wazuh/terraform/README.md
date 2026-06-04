# Terraform — Provisioning des VMs SOC

Crée les **3 VMs du VLAN 50** sur Proxmox (provider `bpg/proxmox`), par clone
de la golden image AlmaLinux 10 :

| VM | IP | vCPU | RAM | Disque |
|----|----|------|-----|--------|
| `FRWAZUH01P` (Wazuh) | 192.168.50.10 | 4 | 8 Go | 100 Go |
| `FRPROM01P` (Prometheus) | 192.168.50.11 | 2 | 4 Go | 50 Go |
| `FRGRAF01P` (Grafana) | 192.168.50.12 | 2 | 2 Go | 20 Go |

Flux global : **Terraform (crée) → Ansible (configure) → GitLab CI (orchestre)**.

## Variables CI à définir dans GitLab

`Settings → CI/CD → Variables` du projet :

| Clé | Type | Masquée | Exemple |
|-----|------|---------|---------|
| `PM_API_URL` | Variable | ✗ | `https://10.201.220.235:8006/api2/json` |
| `PM_API_TOKEN_ID` | Variable | ✓ | `terraform-user@pve!terrafom-token` |
| `PM_API_TOKEN_SECRET` | Variable | ✓ | (secret du token) |
| `TF_VAR_ssh_public_keys` | Variable | ✗ | `["ssh-ed25519 AAAA... ansible"]` |
| `CI_VM_PASSWORD` | Variable | ✓ | mot de passe cloud-init `admin_ansible` |
| `SSH_PRIVATE_KEY` | File | ✗ | contenu de `~/.ssh/id_ed25519_ansible` |

> Le runner GitLab doit être sur le réseau interne (tag `vlan50`) pour
> atteindre l'API Proxmox et les VMs en SSH.

## Utilisation manuelle (hors CI)

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars   # puis renseigne les valeurs
terraform init -backend=false
terraform plan
terraform apply
```

Puis configuration Ansible :

```bash
cd ..
make monitoring     # node_exporter + Prometheus + Grafana
make wazuh          # serveur Wazuh
```
