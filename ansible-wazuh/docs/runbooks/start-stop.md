# Runbook — Démarrage / Arrêt Wazuh

## Démarrer la stack

```bash
ssh admin_ansible@wazuh.sec.lan
sudo systemctl start wazuh-indexer.service
sudo systemctl start wazuh-manager.service
sudo systemctl start wazuh-dashboard.service
# OU (legacy Docker)
sudo docker compose -f /opt/wazuh-docker/single-node/docker-compose.yml up -d
```

## Arrêter la stack (ordre important)

```bash
sudo systemctl stop wazuh-dashboard.service
sudo systemctl stop wazuh-manager.service
sudo systemctl stop wazuh-indexer.service
# OU (legacy Docker)
sudo docker compose -f /opt/wazuh-docker/single-node/docker-compose.yml stop
```

## Vérifier que tout est up

```bash
ansible-playbook playbooks/99_smoke_tests.yml --tags verify,smoke
```

## URL d'accès

- Dashboard : <https://wazuh.sec.lan> (via reverse proxy DMZ)
- API : <https://wazuh.sec.lan:55000> (depuis VLAN 10 uniquement)
- Indexer : <https://wazuh.sec.lan:9200> (réservé intra VLAN 50)
