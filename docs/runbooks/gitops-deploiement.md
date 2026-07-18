# Déploiement GitOps et retour arrière

Le dépôt Git est la source de vérité. `homelab-pull.sh` distribue uniquement un
commit déjà validé ; il ne redémarre aucun conteneur et refuse une avance rapide
si une VM contient une divergence suivie par Git.

## Flux recommandé

1. Modifier et relire sur le poste de contrôle.
2. Exécuter `scripts/validate-repo.sh`.
3. Créer un commit et attendre la CI GitHub verte.
4. Créer les snapshots Proxmox avec `playbooks/proxmox-snapshot.yml`.
5. Distribuer le commit avec `ansible/control-node/homelab-pull.sh`.
6. Déployer une seule pile à la fois avec `docker compose up -d`, puis contrôler
   sa santé et son accès via le reverse proxy.

## Retour arrière

Noter le SHA précédent avant chaque déploiement. Si le contrôle fonctionnel
échoue, revenir explicitement à ce SHA dans le clone de la VM puis relancer la
pile. Restaurer le snapshot seulement si le retour Git ne suffit pas (migration
de base, données ou volume modifiés).

L'automatisation d'un `compose up` général est volontairement exclue : les
migrations applicatives et les dépendances NFS imposent encore une validation
progressive. Le prochain palier sera un déploiement canari par VM avec contrôle
de santé et rollback automatique borné à la pile concernée.
