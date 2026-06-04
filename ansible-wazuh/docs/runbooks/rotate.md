# Runbook — Rotation des secrets

## Cadence

Trimestrielle (calendrier équipe Infra), ou en cas d'incident sécurité.

## Procédure

```bash
# 1. Vérifier que Vault est joignable
vault status -address=https://vault.infra.lan:8200

# 2. Récupérer l'ancien mot de passe API (nécessaire pour s'authentifier)
vault kv get -field=password secret/wazuh/api > /tmp/old_api_pw

# 3. Lancer la rotation (génère + push Vault + applique côté Wazuh)
ansible-playbook playbooks/ops/rotate_secrets.yml --tags rotate

# 4. Smoke tests pour vérifier que les services tiennent
ansible-playbook playbooks/99_smoke_tests.yml

# 5. Effacer l'ancien mdp temporaire
rm -f /tmp/old_api_pw
```

## SLA — interruption max

- 60 secondes (cf. §10.1).

## Si quelque chose part de travers

```bash
# Rollback : restaurer l'ancien mot de passe depuis Vault history
vault kv rollback -version=<N-1> secret/wazuh/api
ansible-playbook playbooks/ops/rotate_secrets.yml --tags rotate
```

## Audit

Chaque rotation pousse un timestamp dans Vault (`rotated_at`).
Logs côté Wazuh : `/var/ossec/logs/api.log`.
