#!/usr/bin/env bash
# =============================================================================
# scripts/backup-usb-setup.sh — Initialise une clé USB chiffrée LUKS pour la
# sauvegarde HORS-SITE des backups homelab.
# =============================================================================
# À lancer UNE SEULE FOIS, sur le poste de contrôle (EliteBook), clé USB branchée.
#
#   ./scripts/backup-usb-setup.sh /dev/sdX
#
# Ce que ça fait :
#   - vérifie que /dev/sdX est bien une clé AMOVIBLE et non le disque système ;
#   - chiffre toute la clé en LUKS2 (tu choisis une passphrase) ;
#   - crée un ext4 étiqueté HOMELAB-BKP à l'intérieur.
#
# ⚠️  DESTRUCTIF : tout le contenu de /dev/sdX est effacé.
# ⚠️  La passphrase LUKS est la SEULE façon de relire la clé : mets-la dans
#     Vaultwarden ET note-la hors-ligne. Perdue = clé USB irrécupérable.
# =============================================================================
set -euo pipefail

MAPPER="homelab-bkp"
LABEL="HOMELAB-BKP"

die() { echo "❌ $*" >&2; exit 1; }

DEV="${1:-}"
[ -n "$DEV" ] || die "Usage : $0 /dev/sdX  (le périphérique de la clé USB, ex. /dev/sdb)"
[ -b "$DEV" ] || die "$DEV n'est pas un périphérique bloc."

command -v cryptsetup >/dev/null 2>&1 || die "cryptsetup absent → installe-le : sudo apt install cryptsetup"

# --- Garde-fous : refuser le disque système et tout ce qui n'est pas amovible ---
BASE="$(lsblk -no PKNAME "$DEV" 2>/dev/null | head -1)"; BASE="${BASE:-$(basename "$DEV")}"
RM="$(lsblk -dno RM "/dev/$BASE" 2>/dev/null | tr -d ' ')"
[ "$RM" = "1" ] || die "/dev/$BASE n'est PAS amovible (RM=$RM). Refus par sécurité — vérifie le nom du périphérique."
if lsblk -no MOUNTPOINT "$DEV" 2>/dev/null | grep -qE '^/($|boot|home)'; then
  die "$DEV semble monté sur un point système. Refus."
fi
# Refuser explicitement le disque qui porte la racine / (garde-fou robuste, indépendant du nommage)
ROOTDISK="$(lsblk -no PKNAME "$(findmnt -no SOURCE / 2>/dev/null)" 2>/dev/null | head -1)"
[ -n "$ROOTDISK" ] && [ "$BASE" = "$ROOTDISK" ] && die "Refus : $DEV contient le système (racine /)."
echo "$DEV" | grep -qE 'nvme|mmcblk' && die "Refus : $DEV ressemble à un disque interne. Vérifie avec 'lsblk'."

echo "=============================================================="
echo "  Périphérique cible :"
lsblk -o NAME,SIZE,TYPE,RM,FSTYPE,LABEL,MOUNTPOINT "$DEV"
echo "=============================================================="
echo "⚠️  TOUT le contenu de $DEV va être EFFACÉ et chiffré en LUKS2."
read -r -p "   Tape exactement 'EFFACER $DEV' pour confirmer : " CONFIRM
[ "$CONFIRM" = "EFFACER $DEV" ] || die "Confirmation incorrecte. Abandon (rien n'a été touché)."

echo "→ Démontage des partitions éventuelles de $DEV ..."
lsblk -lnpo NAME "$DEV" | tail -n +2 | while read -r part; do sudo umount "$part" 2>/dev/null || true; done

echo "→ Formatage LUKS2 (choisis une passphrase solide) ..."
sudo cryptsetup luksFormat --type luks2 "$DEV"

echo "→ Ouverture du conteneur ..."
sudo cryptsetup luksOpen "$DEV" "$MAPPER"

echo "→ Création du système de fichiers ext4 (label $LABEL) ..."
sudo mkfs.ext4 -q -L "$LABEL" "/dev/mapper/$MAPPER"

echo "→ Fermeture du conteneur ..."
sudo cryptsetup luksClose "$MAPPER"

UUID="$(sudo cryptsetup luksUUID "$DEV" 2>/dev/null || true)"
echo ""
echo "✅ Clé USB prête (LUKS2 + ext4 '$LABEL')."
echo "   UUID LUKS : ${UUID:-inconnu}"
echo ""
echo "👉 À FAIRE MAINTENANT :"
echo "   1. Enregistre la passphrase LUKS dans Vaultwarden (+ une copie hors-ligne)."
echo "   2. Lance la 1ʳᵉ sauvegarde :  ./scripts/backup-usb-sync.sh"
