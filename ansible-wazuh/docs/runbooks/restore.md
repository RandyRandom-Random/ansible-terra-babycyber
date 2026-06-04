# Runbook — Restauration

## RTO/RPO

- RTO ≤ 2h
- RPO ≤ 24h

## Procédure

```bash
# 1. (si VM perdue) Provisioning d'une nouvelle VM
cd ../terraform-cyberbaby && terraform apply -target=...

# 2. Réappliquer la config Wazuh (sans données)
ansible-playbook playbooks/20_wazuh_server.yml --tags server,certs

# 3. Lister les backups disponibles
ssh admin_ansible@wazuh.sec.lan "ls -lah /var/backups/wazuh/"

# 4. Restaurer depuis le tar.gz le plus récent
ansible-playbook playbooks/ops/restore.yml \
  -e backup_file=/var/backups/wazuh/wazuh-20260319T120000.tar.gz

# 5. Smoke tests
ansible-playbook playbooks/99_smoke_tests.yml
```

## Snapshot Proxmox

Si la restauration tar échoue, fallback sur snapshot Proxmox :

```bash
ssh root@proxmox.mgmt.lan
qm listsnapshot 107
qm rollback 107 wazuh-20260319T120000
qm start 107
```
