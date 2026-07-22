#!/usr/bin/env bash
# =============================================================================
# scripts/backup-usb-sync.sh — Copie HORS-SITE des sauvegardes homelab sur la
# clé USB chiffrée LUKS (rituel manuel, ex. chaque lundi matin).
# =============================================================================
# Sur le poste de contrôle (EliteBook), clé USB (préparée par backup-usb-setup.sh)
# branchée :
#
#   ./scripts/backup-usb-sync.sh            # auto-détecte la clé LUKS amovible
#   ./scripts/backup-usb-sync.sh /dev/sdX   # ou périphérique explicite
#
# Ce que ça fait, pour chaque VM du groupe 'services' qui a des sauvegardes :
#   - récupère le DERNIER 'daily' (/var/backups/homelab/daily/<date>) en tar-over-ssh
#     (rien à installer sur les VM) → <host>.tar ;
#   - récupère sa clé de chiffrement /etc/homelab-backup.key → keys/<host>.key
#     (indispensable pour relire les archives .enc) ;
#   - écrit un MANIFEST (tailles + sha256) et un RESTORE.md ;
#   - garde les 4 dernières exécutions (rotation), referme et verrouille la clé.
#
# La clé USB étant LUKS, archives + clés + dumps en clair sont protégés si elle
# est perdue/volée. Débranche-la et emporte-la HORS-SITE après chaque exécution.
# =============================================================================
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAPPER="homelab-bkp"
LABEL="HOMELAB-BKP"
MNT="/mnt/homelab-usb"
KEEP=4                      # nombre d'exécutions conservées sur la clé
SSH_OPTS=(-o ConnectTimeout=8 -o BatchMode=yes)
DATE="$(date +%F)"

die() { echo "❌ $*" >&2; exit 1; }

# --- Nettoyage garanti à la sortie : démonter + verrouiller ------------------
cleanup() {
  sync 2>/dev/null || true
  mountpoint -q "$MNT" 2>/dev/null && sudo umount "$MNT" 2>/dev/null || true
  [ -e "/dev/mapper/$MAPPER" ] && sudo cryptsetup luksClose "$MAPPER" 2>/dev/null || true
}
trap cleanup EXIT

command -v cryptsetup >/dev/null 2>&1 || die "cryptsetup absent → sudo apt install cryptsetup"

# --- 1. Trouver la clé USB LUKS ---------------------------------------------
DEV="${1:-}"
if [ -z "$DEV" ]; then
  mapfile -t CAND < <(lsblk -rno NAME,RM,TYPE,FSTYPE | awk '$2==1 && $4=="crypto_LUKS"{print "/dev/"$1}')
  if [ "${#CAND[@]}" -eq 1 ]; then
    DEV="${CAND[0]}"
  else
    echo "Impossible d'identifier automatiquement la clé LUKS amovible."
    echo "Périphériques présents :"; lsblk -o NAME,SIZE,TYPE,RM,FSTYPE,LABEL,MOUNTPOINT
    die "Relance avec le périphérique explicite : $0 /dev/sdX"
  fi
fi
[ -b "$DEV" ] || die "$DEV n'est pas un périphérique bloc."
echo "🔒 Clé USB : $DEV"

# --- 2. Ouvrir + monter (chown pour écrire en tant qu'utilisateur) ----------
[ -e "/dev/mapper/$MAPPER" ] && sudo cryptsetup luksClose "$MAPPER" 2>/dev/null || true
echo "→ Ouverture LUKS (entre la passphrase) ..."
sudo cryptsetup luksOpen "$DEV" "$MAPPER" || die "Ouverture LUKS échouée."
sudo mkdir -p "$MNT"
sudo mount "/dev/mapper/$MAPPER" "$MNT" || die "Montage échoué."
sudo chown "$(id -u):$(id -g)" "$MNT"

ROOT="$MNT/homelab-offsite"
DEST="$ROOT/$DATE"
mkdir -p "$DEST/keys"
MANIFEST="$DEST/MANIFEST.txt"
{ echo "# Sauvegarde hors-site homelab — $DATE $(date +%T)"; echo "# hôte  dernier-daily  taille  sha256"; } > "$MANIFEST"

# --- 3. Énumérer les hôtes 'services' ---------------------------------------
mapfile -t HOSTS < <(cd "$REPO/ansible" 2>/dev/null && ansible-inventory -i inventory/hosts.yml --list 2>/dev/null \
  | jq -r '.services.hosts[] as $h | "\($h) \(._meta.hostvars[$h].ansible_host)"' 2>/dev/null)
if [ "${#HOSTS[@]}" -eq 0 ]; then
  HOSTS=( "infra 10.0.30.10" "monitoring 10.0.30.11" "cloud 10.0.30.12" "media 10.0.30.13" \
          "security 10.0.30.14" "scanner 10.0.30.15" "firefly 10.0.30.16" "osint 10.0.30.17" "ir 10.0.30.18" )
fi

# --- 4. Tirer le dernier daily + la clé de chaque hôte ----------------------
OK=0; SKIP=0; FAIL=0
for entry in "${HOSTS[@]}"; do
  host="${entry%% *}"; ip="${entry##* }"
  printf '• %-11s (%s) ... ' "$host" "$ip"
  # Détection avec 3 tentatives : résiste aux glitches SSH transitoires.
  latest=""; rc=1
  for try in 1 2 3; do
    latest="$(ssh "${SSH_OPTS[@]}" "debian@$ip" 'sudo sh -c "ls -1 /var/backups/homelab/daily 2>/dev/null | sort | tail -1"' 2>/dev/null)"; rc=$?
    [ "$rc" -eq 0 ] && break
    sleep 2
  done
  # rc≠0 = SSH/sudo en échec (injoignable) → ÉCHEC bruyant, jamais un skip silencieux.
  if [ "$rc" -ne 0 ]; then echo "⚠️ ÉCHEC (injoignable/SSH) — NON copié"; FAIL=$((FAIL+1)); continue; fi
  # rc=0 mais vide = hôte joignable sans sauvegarde (skip légitime).
  if [ -z "$latest" ]; then echo "aucun backup — ignoré"; SKIP=$((SKIP+1)); continue; fi

  if ! ssh "${SSH_OPTS[@]}" "debian@$ip" "sudo tar cf - -C /var/backups/homelab/daily '$latest'" > "$DEST/$host.tar" 2>/dev/null; then
    echo "ÉCHEC copie archives"; FAIL=$((FAIL+1)); rm -f "$DEST/$host.tar"; continue
  fi
  if ! ssh "${SSH_OPTS[@]}" "debian@$ip" 'sudo cat /etc/homelab-backup.key' > "$DEST/keys/$host.key" 2>/dev/null \
       || [ ! -s "$DEST/keys/$host.key" ]; then
    echo "ÉCHEC copie clé"; FAIL=$((FAIL+1)); continue
  fi
  chmod 600 "$DEST/keys/$host.key"
  size="$(du -h "$DEST/$host.tar" | cut -f1)"
  sha="$(sha256sum "$DEST/$host.tar" | cut -d' ' -f1)"
  echo "OK ($latest, $size)"
  printf '%-11s %s %s %s\n' "$host" "$latest" "$size" "$sha" >> "$MANIFEST"
  OK=$((OK+1))
done

# --- 5. RESTORE.md (auto-documentation de la clé) ---------------------------
cat > "$ROOT/RESTORE.md" <<'EOF'
# Restaurer depuis cette clé USB (hors-site)

Chaque dossier daté contient, par VM :
- `<host>.tar`     : le dernier « daily » de la VM (archives sous `daily/<date>/`).
- `keys/<host>.key`: la clé openssl de CETTE VM (indispensable pour les `.enc`).

## Extraire
    mkdir -p /tmp/restore && tar xf cloud.tar -C /tmp/restore
    ls /tmp/restore/<date>/

## Déchiffrer une archive .enc (ex. vaultwarden)
    openssl enc -d -aes-256-cbc -pbkdf2 -pass file:keys/cloud.key \
      -in /tmp/restore/<date>/vaultwarden-data.tar.gz.enc | tar tzf -

Les dumps `*.sql.gz` (nextcloud, immich, dawarich, splitpro, gvmd…) sont en clair
(gzip), pas besoin de clé : `gunzip -c fichier.sql.gz | psql ...`.

Redéploiement des services : dépôt GitOps `homelab` (public) + `docker compose up -d`.
Procédure détaillée : `docs/runbooks/sauvegarde-usb-hors-site.md`.
EOF

# --- 6. Rotation : garder les KEEP dernières exécutions ---------------------
mapfile -t OLD < <(find "$ROOT" -maxdepth 1 -type d -regex '.*/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | sort | head -n "-$KEEP")
for d in "${OLD[@]}"; do echo "  rotation : suppression $(basename "$d")"; rm -rf "$d"; done

# --- 7. Bilan ---------------------------------------------------------------
echo ""
echo "MANIFEST :"; sed 's/^/   /' "$MANIFEST"
echo ""
USED="$(df -h "$MNT" | awk 'NR==2{print $3" / "$2" ("$5")"}')"
echo "📦 Copié : $OK hôte(s) | ignoré : $SKIP | échec : $FAIL | clé USB : $USED"
echo "→ Démontage et verrouillage automatiques ..."
# cleanup() s'exécute au trap EXIT
if [ "$FAIL" -gt 0 ]; then
  echo "⚠️  Des hôtes ont échoué — vérifie avant de considérer la sauvegarde complète."
  exit 1
fi
echo "✅ Terminé. Débranche la clé et emporte-la HORS-SITE."
