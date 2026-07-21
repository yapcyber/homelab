# Sauvegarde hors-site sur clé USB chiffrée (LUKS)

Complète les sauvegardes locales des VM (`/var/backups/homelab`, quotidiennes) par
une copie **hors-réseau et hors-site** sur une clé USB chiffrée, que tu emportes.
C'est le dernier maillon du 3-2-1 : une panne commune du stockage n'emporte plus
à la fois le service et sa seule sauvegarde.

- **Off-network** : la clé n'est branchée que le temps de la copie.
- **Off-site** : tu l'emportes après chaque exécution.
- **Zéro brique serveur** : tout se pilote depuis le poste de contrôle (EliteBook) ;
  rien n'est installé sur les VM (copie en `tar`-over-ssh).

## Ce qui est copié

Pour chaque VM du groupe `services` ayant des sauvegardes, à chaque exécution :

| Élément | Détail |
|---|---|
| `<host>.tar` | le **dernier `daily`** de la VM (`/var/backups/homelab/daily/<date>/`) |
| `keys/<host>.key` | la clé openssl `/etc/homelab-backup.key` de CETTE VM (pour les `.enc`) |
| `MANIFEST.txt` | date, tailles, `sha256` de chaque archive |
| `RESTORE.md` | procédure de restauration, écrite sur la clé |

La VM garde son historique de rotation en local (7 j / 4 s / 3 m) ; la clé USB
conserve les **4 dernières exécutions** (rotation automatique).

## RPO / RTO

- Sauvegarde **locale** : quotidienne → RPO ~24 h (mais sur la VM uniquement).
- Sauvegarde **hors-site** : à la fréquence où tu branches la clé (ex. hebdo) →
  RPO hors-site ~1 semaine. C'est le compromis assumé d'un rituel manuel.

## Prérequis (une fois)

- Une clé USB dédiée (≥ 64 Go conseillé ; une exécution complète ≈ 4 Go, ×4 rotations).
- `cryptsetup` sur le poste de contrôle : `sudo apt install cryptsetup`.

## Initialisation de la clé (une seule fois)

⚠️ **Destructif** : efface toute la clé.

    lsblk                                   # repérer le périphérique, ex. /dev/sdb
    ./scripts/backup-usb-setup.sh /dev/sdb  # LUKS2 + ext4 'HOMELAB-BKP'

Choisis une passphrase LUKS solide, puis **enregistre-la dans Vaultwarden + une
copie hors-ligne**. Passphrase perdue = clé USB irrécupérable.

## Rituel de sauvegarde (récurrent, ex. chaque lundi)

1. Branche la clé USB.
2. Lance :

       cd ~/homelab && ./scripts/backup-usb-sync.sh

3. Saisis ton mot de passe `sudo` puis la **passphrase LUKS**.
4. Le script tire le dernier daily + la clé de chaque VM, écrit le MANIFEST,
   fait la rotation, puis **démonte et verrouille** la clé automatiquement.
5. Débranche la clé et **emporte-la hors-site**.

Le script auto-détecte la clé LUKS amovible ; sinon précise-la :
`./scripts/backup-usb-sync.sh /dev/sdb`.

## Restauration

La clé contient un `RESTORE.md`. En résumé, depuis un dossier daté :

    tar xf cloud.tar -C /tmp/restore                     # extrait le daily
    # archive chiffrée (.enc) → clé de la même VM :
    openssl enc -d -aes-256-cbc -pbkdf2 -pass file:keys/cloud.key \
      -in /tmp/restore/<date>/vaultwarden-data.tar.gz.enc | tar xzf - -C /cible
    # dump SQL en clair (.sql.gz) → pas de clé :
    gunzip -c /tmp/restore/<date>/nextcloud-db.sql.gz | docker exec -i nextcloud-db psql -U <user>

Redéploiement des services : dépôt GitOps `homelab` + `docker compose up -d`.

## Sécurité

- La clé est **LUKS** : archives, clés openssl **et** dumps SQL en clair
  (`nextcloud-db`, `immich-db`, `dawarich`, `splitpro`, `gvmd`, `wanderer`, non
  chiffrés individuellement) sont protégés si la clé est perdue/volée.
- Clés openssl et archives voyagent ensemble sur la clé : c'est acceptable **parce
  que** le conteneur LUKS les enveloppe. Ne jamais copier ces fichiers hors du LUKS.
- La passphrase LUKS est la seule custody : Vaultwarden + hors-ligne.

## Limites et réglages

- Rituel **manuel** : la fraîcheur hors-site dépend de ta régularité.
- Les gros postes dominent le volume : `media` (`media-configs.tar.gz` ≈ 1,8 Go)
  et `scanner` (`gvmd-db.sql.gz` ≈ 1,5 Go, largement re-téléchargeable). Si tu veux
  alléger, on peut exclure ces deux-là de la copie hors-site (données re-constructibles).
- `KEEP=4` exécutions conservées : ajustable en tête de `backup-usb-sync.sh`.

## Test de restauration (trimestriel)

Une fois par trimestre, prends une archive de la clé, restaure-la dans un conteneur
éphémère de même moteur/version, vérifie quelques objets, détruis l'environnement,
et consigne date/durée/résultat. Voir aussi `restauration-sauvegardes.md`.
