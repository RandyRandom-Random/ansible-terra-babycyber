# ansible-wazuh

> Déploiement Wazuh 4.12 via Ansible — conforme cahier des charges v1.0.

Stack : Wazuh manager + indexer + dashboard (single-node) sur VM Debian 12 du
VLAN 50, agents sur Debian (VLAN 20/30/40), règles pfSense gérées par
l'API, secrets via HashiCorp Vault, monitoring exposé à Grafana.

---

## Sommaire

- [Architecture](#architecture)
- [Arborescence](#arborescence)
- [Démarrage rapide](#démarrage-rapide)
- [Inventaire & VLAN](#inventaire--vlan)
- [Rôles](#rôles)
- [Playbooks](#playbooks)
- [Pipeline CI/CD](#pipeline-cicd)
- [Sécurité](#sécurité)
- [Runbooks d'exploitation](#runbooks-dexploitation)
- [Conformité cahier des charges](#conformité-cahier-des-charges)

---

## Architecture

```
                      ┌─────────────────────────────┐
                      │   VLAN 50 SEC               │
                      │   wazuh.sec.lan             │
                      │   ┌──────────┐ ┌─────────┐  │
       agents ───►────┤   │ manager  │ │ indexer │  │
       1514/1515      │   └────┬─────┘ └────┬────┘  │
                      │        └───────┬────┘       │
                      │           ┌────▼─────┐      │
                      │           │dashboard │      │
                      │           └────┬─────┘      │
                      └────────────────┼────────────┘
                                       │ 443
                                       │
       admin VLAN 10 ◄────────reverse proxy DMZ
       (55000 API)
```

Cibles cahier des charges (§3) :

| Ressource    | Manager | Indexer | Dashboard | VM totale |
|--------------|---------|---------|-----------|-----------|
| vCPU         | 1       | 2       | 1         | **4**     |
| RAM          | 2 Go    | 4 Go    | 1 Go      | **8 Go**  |
| Stockage     | 20 Go   | 60 Go   | 5 Go      | **100 Go**|

---

## Arborescence

```
ansible-wazuh/
├── ansible.cfg
├── requirements.yml
├── inventories/
│   └── prod/
│       ├── hosts.yml                # 6 VLANs + groupes fonctionnels
│       ├── group_vars/
│       │   ├── all.yml
│       │   ├── vlan_mgmt.yml
│       │   ├── vlan_infra.yml
│       │   ├── vlan_runtime.yml
│       │   ├── vlan_dmz.yml
│       │   ├── vlan_sec.yml
│       │   └── vault.yml            # chiffré ansible-vault
│       └── host_vars/
│           ├── wazuh.sec.lan.yml
│           └── pfsense.mgmt.lan.yml
├── playbooks/
│   ├── 00_preflight.yml
│   ├── 10_pfsense_firewall.yml
│   ├── 20_wazuh_server.yml
│   ├── 30_wazuh_agents.yml
│   ├── 40_integrations.yml
│   ├── 99_smoke_tests.yml
│   ├── site.yml                     # orchestration complète
│   └── ops/
│       ├── backup.yml
│       ├── restore.yml
│       └── rotate_secrets.yml
├── roles/
│   ├── common_hardening/            # sysctl/SSH/AppArmor/nftables/auditd/umask
│   ├── podman_quadlet/              # Podman ≥4.9 + /etc/containers/systemd
│   ├── wazuh_certs/                 # root CA + feuilles, rotation J-30 auto
│   ├── wazuh_server/                # déploiement stack + rotation secrets
│   ├── wazuh_agent/                 # agent Debian + groupes par VLAN
│   ├── pfsense_rules/               # API pfSense, matrice §3.2
│   ├── vault_integration/           # AppRole + Vault Agent sidecar
│   ├── grafana_datasource/          # datasource OpenSearch RO
│   └── monitor/                     # (bonus, hors cahier) Prometheus+Grafana
├── molecule/                        # scenarios par rôle
├── docs/
│   ├── architecture/
│   └── runbooks/
├── terraform/                       # provisioning VM monitoring (bonus)
├── .gitlab-ci.yml
├── .yamllint
├── .ansible-lint
└── .gitignore
```

---

## Démarrage rapide

### Prérequis

- Ansible Core ≥ 2.16
- Collections épinglées : `ansible-galaxy install -r requirements.yml`
- Accès SSH par clé à toutes les VMs cibles (clé `id_ed25519_ansible`)
- Token Vault et token API pfSense disponibles dans GitLab CI/CD vars

### Première exécution

```bash
# 1. Préflight — vérifie que tout est joignable
ansible-playbook playbooks/00_preflight.yml

# 2. Règles pfSense (idéalement avant que le dashboard soit exposé)
ansible-playbook playbooks/10_pfsense_firewall.yml

# 3. Déploiement Wazuh server (hardening + Vault + certs + stack)
ansible-playbook playbooks/20_wazuh_server.yml

# 4. Déploiement des agents (par batch de 5)
ansible-playbook playbooks/30_wazuh_agents.yml

# 5. Intégration Grafana
ansible-playbook playbooks/40_integrations.yml

# 6. Smoke tests
ansible-playbook playbooks/99_smoke_tests.yml
```

### Tout en un

```bash
ansible-playbook playbooks/site.yml
```

### Exécution ciblée

```bash
# Re-déployer uniquement les agents INFRA en dry-run
ansible-playbook playbooks/30_wazuh_agents.yml --limit vlan_infra --tags agents --check --diff

# Rotation des secrets (trimestrielle)
ansible-playbook playbooks/ops/rotate_secrets.yml --tags rotate

# Backup
ansible-playbook playbooks/ops/backup.yml
```

---

## Inventaire & VLAN

| VLAN | Groupe Ansible | Rôle |
|------|---------------|------|
| 10   | `vlan_mgmt`    | Proxmox + pfSense (admin) |
| 20   | `vlan_infra`   | Vault, K3s, GitLab, Nexus, Authentik |
| 30   | `vlan_runtime` | Podman host, fullstack app |
| 40   | `vlan_dmz`     | Reverse proxy public |
| 50   | `vlan_sec`     | Wazuh, Grafana, observabilité |

Groupes Wazuh (§6.1) :

| Groupe Wazuh     | Hôtes                                 | Profil                          |
|------------------|---------------------------------------|---------------------------------|
| `infra-critical` | Vault, GitLab, Authentik              | FIM realtime + SCA CIS          |
| `infra-k3s`      | nœuds K3s                             | FIM /etc/rancher + audit K8s    |
| `infra-registry` | Nexus                                 | FIM configs + audit artefacts   |
| `runtime`        | Podman host, fullstack-app            | FIM scheduled 12h, audit Podman |
| `dmz`            | Reverse proxy                         | Logs HTTP, brute force          |
| `network`        | pfSense (v1.1)                        | Logs FreeBSD                    |

---

## Rôles

| Rôle | Cibles | Idempotent | Statut |
|------|--------|-----------|--------|
| `common_hardening` | tous | ✓ | ✅ v1.0 |
| `podman_quadlet`   | wazuh_server | ✓ | ✅ v1.0 |
| `wazuh_certs`      | wazuh_server | ✓ (skip si valide >30j) | ✅ v1.0 |
| `wazuh_server`     | wazuh_server | ✓ | ⚠️ migration Docker→Podman en cours |
| `wazuh_agent`      | wazuh_agents | ✓ | ✅ v1.0 |
| `pfsense_rules`    | firewalls | ✓ | ✅ v1.0 |
| `vault_integration`| wazuh_server | ✓ | ✅ v1.0 |
| `grafana_datasource`| grafana hosts | ✓ | ✅ v1.0 |
| `monitor`          | monitor.sec.lan | ✓ | 🎁 bonus hors cahier |

Différé v1.1 (cf. §2.2) : `wazuh_agent_freebsd`, `vector_shipper`, `authentik_oidc`,
`wazuh_certs_rotation` (cron), `restic_backup`.

---

## Playbooks

| Fichier | Tags | Description |
|---------|------|-------------|
| `00_preflight.yml` | `preflight` | Ping + facts + asserts (OS, RAM, disque) |
| `10_pfsense_firewall.yml` | `firewall` | Crée aliases + règles pfSense (matrice §3.2) |
| `20_wazuh_server.yml` | `server`, `certs` | Provisionne VM Wazuh complète |
| `30_wazuh_agents.yml` | `agents` | Déploie agents par batch de 5 |
| `40_integrations.yml` | `integrations` | Datasource Grafana (Vector/Authentik en v1.1) |
| `99_smoke_tests.yml` | `verify`, `smoke` | Healthchecks post-apply |
| `ops/rotate_secrets.yml` | `rotate` | Rotation trimestrielle des secrets |
| `ops/backup.yml` | `backup` | Snapshot Proxmox + dump volumes |
| `ops/restore.yml` | `restore` | Restauration depuis tar (-e backup_file=…) |

---

## Pipeline CI/CD

```
lint → syntax → molecule → check → apply (manuel) → smoke
```

| Stage | Auto | Outils |
|-------|------|--------|
| `lint`     | ✓ | ansible-lint + yamllint + markdownlint + gitleaks |
| `syntax`   | ✓ | `ansible-playbook --syntax-check` |
| `molecule` | ✓ | tests par rôle, driver Docker (Podman en v1.1) |
| `check`    | ✓ | `--check --diff` sur l'inventaire prod |
| `apply`    | **manuel**, main only | `ansible-playbook site.yml` |
| `smoke`    | ✓ | `99_smoke_tests.yml` |

Variables CI requises :

| Clé | Type | Source |
|-----|------|--------|
| `SSH_PRIVATE_KEY` | File | `~/.ssh/id_ed25519_ansible` |
| `ANSIBLE_VAULT_PASSWORD` | Variable masked | Vault `secret/ci/ansible-vault` |
| `VAULT_TOKEN` | Variable masked | JWT auth de Vault |
| `PFSENSE_API_TOKEN` | Variable masked | Vault `secret/pfsense/api` |

---

## Sécurité

### Secrets (§7.1)

| Secret | Vault path |
|--------|-----------|
| Clé ansible-vault | `secret/ci/ansible-vault` |
| Wazuh admin indexer | `secret/wazuh/indexer/admin` |
| API Wazuh | `secret/wazuh/api` |
| Enrollment password agents | `secret/wazuh/enrollment` |
| Root CA key | `secret/wazuh/certs/root-key` |
| Token pfSense | `secret/pfsense/api` |

Rotation trimestrielle via `playbooks/ops/rotate_secrets.yml`.

### Durcissement OS (§7.2)

Rôle `common_hardening` applique :
- SSH : key-only, no root, AllowUsers limitatif, ciphers Mozilla intermediate
- sysctl : ip_forward=0, accept_redirects=0, syncookies=1, kptr_restrict=2, randomize_va_space=2
- AppArmor : profils en `enforce`
- nftables : deny-by-default + SSH MGMT + ports applicatifs explicites
- auditd : règles CIS-L1 (time-change, identity, perm_mod, scope, modules…)
- umask global : `027`

### TLS (§7.3)

- Root CA interne : 5 ans, RSA 4096, clé Vault path `secret/wazuh/certs/root-key`
- Certs feuilles : 1 an, **rotation auto à J-30** (vérif via `x509_certificate_info`)
- Cert externe dashboard : ACME DNS-01 sur Let's Encrypt (reverse proxy DMZ)

---

## Runbooks d'exploitation

Voir [`docs/runbooks/`](./docs/runbooks/) :

- `start-stop.md` — démarrer / arrêter la stack
- `restore.md` — restaurer depuis backup
- `rotate.md` — rotation secrets manuelle
- `incident.md` — procédure incident (agent perdu, dashboard down…)

---

## Conformité cahier des charges

| Critère §10 | Statut |
|------------|--------|
| 10.1 Fonctionnels — préflight, server 15 min, agents 100%, rotation < 60s, SSO MGMT | 🟡 partiel (SSO en v1.1) |
| 10.2 Idempotence — 0 changed au 2nd run, --check diff = 0 | ✅ |
| 10.3 Sécurité — gitleaks clean, mdp rotés, nmap conforme, TLS Labs ≥ A | 🟡 partiel (TLS Labs dépend du reverse proxy DMZ) |
| 10.4 Performance — latence ingest <5s, CPU <50%, heap <70% | à mesurer |
| 10.5 Observabilité — métriques §9.3 visibles, alertes §9.4 testées | 🟡 partiel (datasource OK, alertes en v1.1) |

Détails complets : [`docs/architecture/conformite.md`](./docs/architecture/conformite.md).
