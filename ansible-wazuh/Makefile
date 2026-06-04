# Makefile — ansible-wazuh
# Raccourcis de déploiement. Lance `make help` pour la liste.

INV     ?= inventories/prod/hosts.yml
PB      := ansible-playbook -i $(INV)

.DEFAULT_GOAL := help

.PHONY: help deps ping check site \
        wazuh agents node-exporter prometheus grafana monitoring \
        smoke lint

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

deps: ## Installe les collections Ansible requises
	ansible-galaxy collection install -r requirements.yml

ping: ## Teste la connexion SSH à tous les hôtes
	ansible all -i $(INV) -m ping

check: ## Dry-run complet (--check --diff), n'applique rien
	$(PB) playbooks/site.yml --check --diff

site: ## Déploiement complet (tout)
	$(PB) playbooks/site.yml

wazuh: ## Déploie le serveur Wazuh (SIEM)
	$(PB) playbooks/20_wazuh_server.yml

agents: ## Déploie les agents Wazuh
	$(PB) playbooks/30_wazuh_agents.yml

node-exporter: ## Déploie node_exporter sur tous les hôtes
	$(PB) playbooks/45_node_exporter.yml

prometheus: ## Déploie Prometheus
	$(PB) playbooks/50_prometheus.yml

grafana: ## Déploie Grafana + dashboards
	$(PB) playbooks/60_grafana.yml

monitoring: ## Déploie TOUTE l'observabilité (node_exporter + Prometheus + Grafana)
	$(PB) playbooks/deploy-monitoring.yml

smoke: ## Tests post-déploiement (containers, API, ports)
	$(PB) playbooks/99_smoke_tests.yml

lint: ## Vérifie la qualité du code (ansible-lint + yamllint)
	ansible-lint
	yamllint -c .yamllint .
