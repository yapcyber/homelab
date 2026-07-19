# Pilote SOPS — Navidrome

## Objectif

Valider le cycle chiffré Git → déchiffrement local → livraison Ansible →
conteneur, sans utiliser un secret métier. `SOPS_CANARY` est ignoré par
Navidrome et ne modifie ni comptes, ni bibliothèque, ni lecture.

## Déployer

```bash
cd ~/homelab/ansible
ansible-playbook playbooks/sops-deliver-navidrome.yml
```

La clé Age reste sur l'EliteBook. La VM reçoit uniquement `.env` en mode `0600`.
La validation compare des empreintes et masque les tâches sensibles avec
`no_log: true`.

## Tester le rollback

```bash
ansible-playbook playbooks/sops-rollback-navidrome.yml
```

Le `.env` pilote est retiré, le conteneur recréé et son fonctionnement vérifié.

## Revenir à l'état final chiffré

```bash
ansible-playbook playbooks/sops-deliver-navidrome.yml
```
