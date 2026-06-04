# Conformité — Cahier des charges v1.0

Matrice détaillée par section.

## §2 Périmètre

| Item | Statut | Notes |
|------|--------|-------|
| VM dédiée Wazuh VLAN 50 | ✅ | wazuh.sec.lan / 192.168.50.10 |
| manager + indexer + dashboard via Podman/Quadlet | ⚠️ | encore Docker en lab, migration en cours |
| Certs internes mTLS indexer | ✅ | root-ca 4096 bits 5 ans + feuilles 1 an, rotation J-30 |
| Agents Debian VLAN 20/30/40 | ✅ rôle prêt | déploiement à orchestrer |
| Règles pfSense via Ansible | ✅ | rôle `pfsense_rules` + matrice §3.2 |
| Datasource Grafana RO sur indexer | ✅ | rôle `grafana_datasource` |
| HashiCorp Vault pour secrets | ✅ | rôle `vault_integration` + AppRole + Vault Agent |
| Backup minimal (snapshot + dump) | ✅ | playbook `ops/backup.yml` |

## §5 Spécifications Ansible

| Item | Statut |
|------|--------|
| Arborescence §5.1 | ✅ |
| Inventaire par VLAN §5.2 | ✅ |
| Précédence variables §5.3 | ✅ |
| Catalogue rôles v1.0 §5.4 | ✅ (9/9 dossiers prêts, contenu varie) |
| Stratégie de tags §5.5 | ✅ |
| Collections épinglées §5.6 | ✅ `requirements.yml` |
| Idempotence §5.7 | ✅ par construction (check via `check --diff`) |
| Tests §5.8 — lint + syntax + smoke | ✅ |
| Pipeline CI §5.9 | ✅ 6 stages |

## §7 Sécurité

| Item | Statut |
|------|--------|
| Secrets via Vault | ✅ |
| mTLS manager↔indexer | ✅ |
| TLS dashboard via reverse proxy Let's Encrypt DNS-01 | 🟡 dépend du rproxy DMZ |
| SSO Authentik OIDC | 🟡 v1.1 |
| Mots de passe par défaut rotés | ✅ `ops/rotate_secrets.yml` |
| SSH key-only | ✅ rôle `common_hardening` |

## §10 Critères d'acceptation

| Critère | Statut |
|---------|--------|
| 10.1 préflight OK | ✅ playbook prêt |
| 10.1 server 15 min sur VM neuve | à mesurer |
| 10.1 agents 100% enrôlés | à mesurer après run |
| 10.1 rotation < 60s | ✅ (handler restart ciblé) |
| 10.1 dashboard accessible MGMT only | ✅ matrice pfSense |
| 10.2 idempotence 0 changed | ✅ par construction |
| 10.2 --check --diff = 0 | ✅ stage `check` CI |
| 10.3 gitleaks clean | ✅ stage `gitleaks` CI |
| 10.3 mdp par défaut rotés | ✅ `rotate_secrets.yml` |
| 10.3 nmap conforme | ✅ test dans `99_smoke_tests.yml` |
| 10.3 TLS Labs ≥ A | 🟡 dépend du rproxy |
| 10.4 perf | à mesurer 24h après MEP |
| 10.5 observabilité | 🟡 partiel (datasource OK, alertes en v1.1) |

## Glissements identifiés vs cahier

- Migration Docker → Podman/Quadlet : **point dur J4 du planning** (cf. §12), partiellement traité.
  Le rôle `podman_quadlet` est prêt, `wazuh_server` doit être refondu en Quadlet units.
- Active response DMZ : v1.1.
- SSO Authentik : v1.1.
- Vector shipper : v1.1.
- Molecule full : seul `common_hardening` a un scenario, à étendre.
