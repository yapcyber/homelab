# Déployer `secondbrain.yapserver.fr`

> État : préparation. Ne pas exécuter avant la sauvegarde des clés de
> récupération et la création du compose versionné.

## Prérequis

- L'override DNS `secondbrain.yapserver.fr` résout vers Traefik.
- Les clés Age et `/etc/homelab-backup.key` sont sauvegardées dans Vaultwarden
  et sur un support hors ligne.
- Une destination de sauvegarde indépendante du disque de la VM est disponible.
- Authentik possède un groupe autorisé dédié au second brain.

## Actions qui seront automatisées

1. Créer le compose SilverBullet épinglé et son template `.env.example`.
2. Ajouter le routeur Traefik avec `internal-only`, Authentik et les en-têtes de
   sécurité, sans publication directe de port.
3. Ajouter la sauvegarde chiffrée du dossier Markdown et son contrôle quotidien.
4. Valider Compose, déployer, contrôler santé et accès négatif hors WireGuard.
5. Créer les templates initiaux sans importer de données privées.

## Actions utilisateur prévues

1. Créer dans Authentik l'application/provider demandé par le runbook détaillé.
2. Générer un mot de passe de secours dans Vaultwarden, jamais dans Git.
3. Tester la connexion depuis un appareil WireGuard puis depuis un réseau sans
   VPN, qui doit échouer.
4. Confirmer la première restauration avant tout import massif.

## Retour arrière

Arrêter uniquement la pile SilverBullet, conserver son volume Markdown, retirer
le routeur Traefik puis restaurer la dernière archive dans une instance isolée.
Le DNS peut rester en place : sans routeur, il ne donne accès à aucun service.
