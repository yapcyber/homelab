# Sauvegarde hors-site chiffrée vers Google Drive (restic + rclone)

Copie **hors-site automatisée** des sauvegardes homelab vers Google Drive, en
complément de la sauvegarde locale (VM, quotidienne) et de la clé USB LUKS
(air-gap, occasionnel). C'est la couche « en ligne » du 3-2-1-1.

- **Chiffrement côté client** : restic chiffre AVANT l'envoi → Google ne voit que
  du chiffré. Indispensable, car plusieurs dumps locaux sont en clair
  (`nextcloud-db`, `immich-db`, `firefly/ghostfolio`, `dawarich`, `splitpro`, `gvmd`, `wanderer`).
- **Depuis le poste de contrôle** (EliteBook), seul à disposer des clés SSH de
  toutes les VM. Rien n'est installé sur les VM (copie en `tar`-over-ssh).
- **Automatisé** : timer quotidien → RPO hors-site ~24 h.

## Architecture

    VM services ──tar-over-ssh──▶ poste de contrôle ──restic (chiffré)──▶ rclone ──▶ Google Drive
                                                       dépôt : rclone:gdrive:homelab-restic

Chaque exécution capture, par VM, le **dernier `daily`** + sa clé
`/etc/homelab-backup.key` (nécessaire aux `.enc`), dans un snapshot restic taggé par hôte.
Rétention : **7 quotidiennes / 4 hebdo / 6 mensuelles par hôte**, puis `restic check`.

## Installation (une seule fois)

### 1. Outils (poste de contrôle)

    sudo apt install -y rclone restic

### 2. Client OAuth Google PERSONNEL (obligatoire pour restic)

⚠️ Ne PAS laisser `client_id`/`client_secret` vides : le client OAuth **partagé** de
rclone est saturé (quota par minute mutualisé entre tous les utilisateurs) et
`restic init` échoue en `403 rateLimitExceeded`. Crée ton propre client (5 min, une fois) :

1. https://console.cloud.google.com/ → **Nouveau projet** (ex. `rclone-homelab`).
2. **APIs & Services → Bibliothèque** → active **Google Drive API**.
3. **APIs & Services → Écran de consentement OAuth** → type **External** → nom + ton email
   → **ajoute-toi comme Test user** → puis **Publier l'application** (« In production »),
   sinon le jeton expire au bout de **7 jours**.
4. **APIs & Services → Identifiants → Créer → ID client OAuth** → type **Application de bureau**
   → copie le **Client ID** et le **Client secret**.

### 3. Remote rclone vers Google Drive

    rclone config

- `n` (new remote) → name : **`gdrive`**
- Storage : **`drive`** (Google Drive)
- `client_id` / `client_secret` : **colle les tiens** (étape 2)
- scope : **`drive`** (accès complet — plus fiable pour restic ; `drive.file` possible mais capricieux)
- `root_folder_id`, `service_account_file` : vide
- Edit advanced config : `n`
- Use auto config : `y` → connecte-toi à Google dans le navigateur, autorise
- Configure as team drive : `n` → `y` (confirmer) → `q` (quitter)

Vérifie : `rclone listremotes` doit afficher `gdrive:`.

Le mot de passe restic est déjà généré et chiffré dans `scripts/restic-drive.enc.env`
(SOPS). **Récupère-le une fois et mets-le dans Vaultwarden** (custody unique du dépôt) :

    sops -d scripts/restic-drive.enc.env

### 3. Première sauvegarde (initialise le dépôt)

    ./scripts/backup-restic-drive.sh

(le dépôt restic est créé automatiquement s'il n'existe pas).

### 4. Automatisation (timer utilisateur quotidien)

    mkdir -p ~/.config/systemd/user
    cp scripts/systemd/homelab-restic-drive.{service,timer} ~/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable --now homelab-restic-drive.timer
    loginctl enable-linger "$USER"      # pour tourner même sans session ouverte
    systemctl --user list-timers | grep restic-drive

## Restauration

    export RESTIC_REPOSITORY=rclone:gdrive:homelab-restic
    export RESTIC_PASSWORD="$(sops -d scripts/restic-drive.enc.env | sed -n 's/^RESTIC_PASSWORD=//p')"
    restic snapshots                                  # lister (par hôte/tag)
    restic restore <snapshot-id> --target /tmp/restore
    tar xf /tmp/restore/cloud-daily.tar -C /tmp/restore   # daily + homelab-backup.key
    # archive .enc → clé de la même VM (dans le tar) :
    openssl enc -d -aes-256-cbc -pbkdf2 -pass file:/tmp/restore/homelab-backup.key \
      -in /tmp/restore/<date>/vaultwarden-data.tar.gz.enc | tar xzf -

## Sécurité

- **Client-side** : Google ne voit que du chiffré (contenu + noms via restic).
- **Custody** : le mot de passe restic (SOPS + Vaultwarden) est la seule clé du
  dépôt. Sans lui, le dépôt Drive est inexploitable — y compris par toi.
- **Token** : le jeton OAuth rclone vit dans `~/.config/rclone/rclone.conf` sur le
  poste de contrôle → protège ce poste (chiffrement disque). Révocable côté Google.
- Scope `drive.file` : rclone ne peut pas lire tes autres fichiers Drive.

## Limites

- Fraîcheur dépend du poste de contrôle allumé (timer `Persistent` rattrape les
  manques). La sauvegarde locale VM garde le RPO 24 h en propre.
- `media` (~1,8 Go) et `scanner` (~1,5 Go, feed re-téléchargeable) dominent le
  volume ; exclure possible si besoin (données re-constructibles).
- Air-gap (anti-ransomware / anti-lockout de compte) : voir `sauvegarde-usb-hors-site.md`.
