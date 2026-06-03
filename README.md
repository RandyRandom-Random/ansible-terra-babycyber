# ansible-practice

Espace de travail Ansible / Terraform / Docker.

## Contenu

```
ansible-practice/
├── ansible-wazuh/                  # ⭐ Projet actif : SIEM Wazuh (cf. cahier des charges v1.0)
│
├── template-playbook.yml           # Template Ansible — 2 plays + handlers + tags + vault
├── template-docker-compose.yml     # Template Docker Compose (spec v2 moderne)
├── template-terraform.tf           # Template Terraform — VM Proxmox via bpg/proxmox
├── template-env.example            # Exemple .env pour docker-compose
└── template-terraform.tfvars.example  # Exemple tfvars pour Terraform
```

## Démarrage

### Projet actif — Wazuh SIEM

```bash
cd ansible-wazuh
cat README.md
```

URL GitLab : <https://gitlab.cyberbaby.lan/James/ansible-wazuh>

### Utiliser les templates

```bash
# Ansible — copier le template dans un nouveau projet
cp template-playbook.yml mon-projet/playbook.yml

# Docker Compose
mkdir mon-projet && cd mon-projet
cp ../template-docker-compose.yml docker-compose.yml
cp ../template-env.example .env
nano .env
mkdir -p secrets && echo "MotDePasseFort!" > secrets/postgres_password.txt
docker compose up -d

# Terraform Proxmox
mkdir mon-vm && cd mon-vm
cp ../template-terraform.tf main.tf
cp ../template-terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
terraform init && terraform plan
```

## Prérequis

- Ansible Core ≥ 2.16 — `python3 -m pip install ansible-core`
- Docker Engine ≥ 24 avec Compose v2 — `docker compose version`
- Terraform ≥ 1.5 — <https://developer.hashicorp.com/terraform/install>
