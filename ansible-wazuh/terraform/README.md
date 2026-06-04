# Terraform — Provisioning VM Monitoring

Crée la VM `FRMONITOR01P` (192.168.50.11) sur Proxmox `aliexpress` via clone du template `alma10-template`.

> **Note** : la VM `WazuhSiem` (192.168.50.10) est gérée par un autre state Terraform (côté Lucas), elle n'est **pas** dans ce dossier. Ce dossier ne gère **que** la VM Monitor pour ne pas conflicter.

## Variables CI à définir dans GitLab

`Settings → CI/CD → Variables` du projet `siem` :

| Clé                       | Type     | Protégée | Masquée | Valeur                                                        |
|---------------------------|----------|----------|---------|---------------------------------------------------------------|
| `PM_API_URL`              | Variable | ✓        | ✗       | `https://192.168.214.34:8006/api2/json`                       |
| `PM_API_TOKEN_ID`         | Variable | ✓        | ✓       | `terraform@pve!ci` (à créer dans Proxmox)                     |
| `PM_API_TOKEN_SECRET`     | Variable | ✓        | ✓       | secret du token                                                |
| `TF_VAR_ssh_public_key`   | Variable | ✓        | ✓       | contenu de `~/.ssh/id_ed25519_ansible.pub`                    |
| `SSH_PRIVATE_KEY`         | File     | ✓        | ✗       | contenu de `~/.ssh/id_ed25519_ansible` (clef privée)          |

### Créer le token Proxmox

Sur le Proxmox `aliexpress` :
```bash
sudo pveum user add terraform@pve
sudo pveum aclmod / -user terraform@pve -role Administrator
sudo pveum user token add terraform@pve ci --privsep=0
# → te donne le PM_API_TOKEN_SECRET (à copier dans la variable GitLab)
```

## Utilisation manuelle (hors CI)

```bash
cd terraform/
export TF_VAR_pm_api_url="https://192.168.214.34:8006/api2/json"
export TF_VAR_pm_api_token_id="terraform@pve!ci"
export TF_VAR_pm_api_token_secret="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519_ansible.pub)"

# State local (pour tester) :
terraform init -backend=false
terraform plan
terraform apply
```

## Réseau requis pour le runner

Le runner GitLab doit pouvoir atteindre :
- `192.168.214.34:8006` (API Proxmox)
- `192.168.50.10:22` et `192.168.50.11:22` (VMs en SSH, pour la phase Ansible)

→ Le runner doit être hébergé sur le réseau interne `cyberbaby.lan` **ou** avoir une route vers le VLAN50 (via VPN OTERIA ou Tailscale).
