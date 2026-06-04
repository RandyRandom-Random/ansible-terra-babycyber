# Runbook — Incidents courants

## Un agent passe en `disconnected`

```bash
# 1. Identifier le ou les agents
ssh admin_ansible@wazuh.sec.lan
sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_control -l | grep -i disconnected

# 2. Sur l'agent :
ssh admin_ansible@<host>
sudo systemctl status wazuh-agent
sudo journalctl -u wazuh-agent --since "1h ago"

# 3. Re-démarrer l'agent
sudo systemctl restart wazuh-agent

# 4. Si l'agent ne s'inscrit plus : ré-enrollment
sudo /var/ossec/bin/agent-auth -m wazuh.sec.lan -P "$(vault kv get -field=password secret/wazuh/enrollment)"
sudo systemctl restart wazuh-agent
```

## Dashboard inaccessible (HTTP 500 / boot loop)

```bash
ssh admin_ansible@wazuh.sec.lan
sudo docker logs single-node-wazuh.dashboard-1 --tail 100

# Si "Permission denied" sur opensearch_dashboards.yml
sudo chmod -R o+r /opt/wazuh-docker/single-node/config/
sudo find /opt/wazuh-docker/single-node/config -type d -exec chmod o+x {} \;
sudo docker restart single-node-wazuh.dashboard-1
```

## Indexer OOM / heap pleine

```bash
# Augmenter la heap
ssh admin_ansible@wazuh.sec.lan
sudo sed -i 's/-Xms.*/-Xms4g/' /opt/wazuh-docker/single-node/config/wazuh_indexer/jvm.options
sudo sed -i 's/-Xmx.*/-Xmx4g/' /opt/wazuh-docker/single-node/config/wazuh_indexer/jvm.options
sudo docker restart single-node-wazuh.indexer-1
```

## Manager queue saturée

```bash
# Vérifier
ssh admin_ansible@wazuh.sec.lan
sudo docker exec single-node-wazuh.manager-1 cat /var/ossec/var/run/wazuh-analysisd.state | grep queue

# Augmenter queue_size dans ossec.conf si nécessaire
# (puis ansible-playbook 20_wazuh_server.yml --tags config)
```

## Certificat indexer expiré ou < 30 jours

```bash
ansible-playbook playbooks/20_wazuh_server.yml --tags certs,rotation
# La rotation est automatique : le rôle wazuh_certs détecte l'expiration <30j
```
