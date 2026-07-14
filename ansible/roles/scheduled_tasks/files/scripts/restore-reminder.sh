#!/usr/bin/env bash
# Rappel mensuel : test de restauration (cron-securite #13).
# Une sauvegarde jamais testée n'est pas une sauvegarde.
set -u
/usr/local/bin/homelab-alert "🧪 Test de restauration mensuel" \
"À faire ce mois-ci : restaurer un dump (ex. Nextcloud ou Vaultwarden) sur une VM jetable et vérifier l'intégrité.
Dumps : /var/backups/homelab/ sur chaque VM. Clé de chiffrement : /etc/homelab-backup.key." default
