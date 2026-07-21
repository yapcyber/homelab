#!/usr/bin/env bash
# =============================================================================
# scripts/runbook-backup-drive.sh — ACTIVATION de la sauvegarde hors-site Drive.
# =============================================================================
# À lancer UNE FOIS, sur le POSTE DE CONTRÔLE (celui qui a les clés SSH des VM
# et la clé age SOPS). Idempotent : re-lançable sans risque.
#
#   ./scripts/runbook-backup-drive.sh
#
# Enchaîne tout : pré-vérifs → install outils → remote Google Drive (OAuth) →
# init dépôt restic → 1ʳᵉ sauvegarde → contrôle → timer quotidien.
# La seule étape interactive est l'autorisation Google (navigateur), une fois.
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RCLONE_REMOTE="gdrive"
AGE_KEY="$HOME/.config/sops/age/keys.txt"
step() { echo ""; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*" >&2; }
die()  { echo "  ❌ $*" >&2; exit 1; }

# --- 0. Pré-vérifications : suis-je sur le bon poste ? -----------------------
step "Pré-vérifications du poste"
command -v sops >/dev/null 2>&1 || die "sops absent : ce n'est pas le poste de contrôle."
[ -f "$AGE_KEY" ] || die "Clé age SOPS absente ($AGE_KEY) : mauvais poste."
[ -f "$REPO_DIR/scripts/restic-drive.enc.env" ] || die "Secret restic introuvable dans le dépôt."
command -v jq >/dev/null 2>&1 || die "jq absent."
if ssh -o BatchMode=yes -o ConnectTimeout=6 debian@10.0.30.12 true 2>/dev/null; then
  ok "Accès SSH aux VM confirmé (cloud joignable)."
else
  warn "Impossible de joindre une VM (debian@10.0.30.12). Mauvais poste ou VPN coupé ?"
  read -r -p "  Continuer quand même ? [o/N] " a; [ "$a" = "o" ] || die "Abandon."
fi

# --- 1. Outils : rclone + restic --------------------------------------------
step "Outils rclone + restic"
NEED=()
command -v rclone >/dev/null 2>&1 || NEED+=(rclone)
command -v restic >/dev/null 2>&1 || NEED+=(restic)
if [ "${#NEED[@]}" -gt 0 ]; then
  if command -v apt >/dev/null 2>&1; then
    echo "  Installation : ${NEED[*]} (sudo)"; sudo apt update -qq && sudo apt install -y "${NEED[@]}" || die "Installation échouée."
  else
    die "Installe manuellement : ${NEED[*]} (pas d'apt détecté)."
  fi
fi
ok "rclone $(rclone version 2>/dev/null | head -1 | awk '{print $2}') / restic $(restic version 2>/dev/null | awk '{print $2}')"

# --- 2. Remote Google Drive (OAuth) -----------------------------------------
step "Remote rclone '${RCLONE_REMOTE}:' (Google Drive)"
if rclone listremotes 2>/dev/null | grep -qx "${RCLONE_REMOTE}:"; then
  ok "Remote '${RCLONE_REMOTE}:' déjà configuré."
else
  cat <<EOF
  → Le remote n'existe pas. Lancement de 'rclone config'.
    Réponds :  n → nom: ${RCLONE_REMOTE} → storage: drive → client_id/secret: vide
               → scope: drive.file → root_folder_id/service_account: vide
               → advanced: n → auto config: y (autorise dans le navigateur)
               → team drive: n → q (quitter)
EOF
  read -r -p "  Prêt ? [Entrée] " _ ; rclone config
  rclone listremotes 2>/dev/null | grep -qx "${RCLONE_REMOTE}:" || die "Remote '${RCLONE_REMOTE}:' toujours absent."
  ok "Remote configuré."
fi
# Test d'accès Drive
rclone lsd "${RCLONE_REMOTE}:" >/dev/null 2>&1 && ok "Accès Drive OK." || warn "Accès Drive non confirmé (à vérifier)."

# --- 3. Mot de passe restic (SOPS) + init du dépôt --------------------------
step "Dépôt restic sur Drive"
export RESTIC_REPOSITORY="rclone:${RCLONE_REMOTE}:homelab-restic"
RESTIC_PASSWORD="$(sops -d "$REPO_DIR/scripts/restic-drive.enc.env" 2>/dev/null | sed -n 's/^RESTIC_PASSWORD=//p')"
[ -n "$RESTIC_PASSWORD" ] || die "RESTIC_PASSWORD illisible (SOPS)."
export RESTIC_PASSWORD
if restic snapshots >/dev/null 2>&1; then
  ok "Dépôt déjà initialisé."
else
  echo "  Initialisation du dépôt ${RESTIC_REPOSITORY} ..."; restic init || die "restic init échoué."
  ok "Dépôt initialisé."
fi

# --- 4. Première sauvegarde --------------------------------------------------
step "Première sauvegarde hors-site (peut prendre quelques minutes)"
"$REPO_DIR/scripts/backup-restic-drive.sh" || warn "La sauvegarde a signalé au moins un échec (voir ci-dessus)."
echo ""; echo "  Snapshots présents :"; restic snapshots --compact 2>/dev/null | sed 's/^/    /'

# --- 5. Automatisation : timer utilisateur quotidien ------------------------
step "Timer quotidien (systemctl --user)"
mkdir -p "$HOME/.config/systemd/user"
cp "$REPO_DIR"/scripts/systemd/homelab-restic-drive.{service,timer} "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now homelab-restic-drive.timer 2>/dev/null \
  && ok "Timer activé." || warn "Activation du timer à vérifier (session --user ?)."
loginctl enable-linger "$USER" 2>/dev/null && ok "Linger activé (tourne sans session ouverte)." || warn "enable-linger à faire manuellement."
systemctl --user list-timers 2>/dev/null | grep -i restic-drive | sed 's/^/  /'

# --- 6. Rappels custody -----------------------------------------------------
step "À NE PAS OUBLIER"
cat <<EOF
  • Mets le mot de passe restic dans Vaultwarden (custody unique du dépôt) :
        sops -d scripts/restic-drive.enc.env
  • Le jeton OAuth vit dans ~/.config/rclone/rclone.conf → protège ce poste
    (chiffrement disque). Révocable côté Google si besoin.
  • Restauration & détails : docs/runbooks/sauvegarde-restic-drive.md
  ✅ Sauvegarde hors-site Drive active.
EOF
