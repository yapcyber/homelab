# Restaurer et vérifier les sauvegardes applicatives

Les sauvegardes locales sont produites chaque nuit sous
`/var/backups/homelab`. Elles réduisent le RPO applicatif à environ 24 heures,
mais ne constituent pas une copie hors site : elles résident encore sur la VM.

## Contrôles automatiques

`homelab-backup-verify.timer` vérifie chaque matin que la dernière sauvegarde a
moins de 48 heures et que chaque flux gzip, y compris les archives chiffrées,
est lisible. Ce test détecte une archive tronquée ou une mauvaise clé ; il ne
remplace pas un test de restauration applicatif.

## Test trimestriel

1. Choisir une sauvegarde sans toucher au service de production.
2. Copier l'archive et, si nécessaire, la clé dans un environnement isolé.
3. Déchiffrer avec `openssl enc -d -aes-256-cbc -pbkdf2`.
4. Restaurer dans un conteneur éphémère de même moteur et même version majeure.
5. Vérifier les tables, un compte non privilégié et quelques objets métier.
6. Détruire l'environnement de test et consigner la date, la durée et le résultat.

La clé `/etc/homelab-backup.key` est unique à chaque VM. Sa perte rend les
archives `.enc` irrécupérables. Une copie doit être conservée dans Vaultwarden
et une seconde copie hors ligne. Ne jamais la placer dans Git, même chiffrée
avec une clé qui serait stockée au même endroit.

## Limite restante

La prochaine étape de continuité est une réplication chiffrée vers un support
indépendant du NAS et du cluster. Tant qu'elle n'existe pas, une panne commune
du stockage peut emporter simultanément le service et sa sauvegarde locale.
