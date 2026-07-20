#!/usr/bin/env bash
# =============================================================================
# scripts/bootstrap-games-romm.sh
# -----------------------------------------------------------------------------
# Provisionne la VM "games" (OpenTofu, VLAN 30, clone du template pré-stagé 9001
# sur pve2) puis déploie RomM (RomM + MariaDB). À lancer sur l'EliteBook.
#
#   ./scripts/bootstrap-games-romm.sh
#
# PASSPHRASE DU STATE OPENTOFU :
#   - si iac/opentofu/state-passphrase.enc.env existe -> déchiffrée via SOPS (auto,
#     et c'est ce qui me permet de relancer tofu en autonomie ensuite) ;
#   - sinon on la demande ; si tu l'as PERDUE, laisse vide -> RESET propre
#     (le state est vide : aucune ressource gérée, donc zéro perte). Une nouvelle
#     passphrase est générée puis chiffrée en SOPS (à committer).
# =============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO}/iac/opentofu"
PASS_ENC="${TF_DIR}/state-passphrase.enc.env"
GAMES_IP="10.0.30.20"
GAMES_SSH="debian@${GAMES_IP}"
INFRA_SSH="debian@10.0.30.10"
SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)

log() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
log "1/7  Passphrase du state OpenTofu"
if [ -f "${PASS_ENC}" ]; then
  echo "Passphrase SOPS trouvée -> déchiffrement automatique."
  TF_VAR_state_passphrase="$(sops -d "${PASS_ENC}" | sed -n 's/^TF_VAR_state_passphrase=//p')"
else
  read -rsp "Passphrase du state (laisse VIDE si perdue -> RESET) : " TF_VAR_state_passphrase; echo
  if [ -z "${TF_VAR_state_passphrase}" ]; then
    echo "RESET : state vide (aucune ressource gérée) -> on repart proprement."
    ts="$(date +%Y%m%d-%H%M%S)"
    cp -a "${TF_DIR}/terraform.tfstate"        "${TF_DIR}/terraform.tfstate.bak-${ts}"        2>/dev/null || true
    cp -a "${TF_DIR}/terraform.tfstate.backup" "${TF_DIR}/terraform.tfstate.backup.bak-${ts}" 2>/dev/null || true
    rm -f "${TF_DIR}/terraform.tfstate" "${TF_DIR}/terraform.tfstate.backup"
    TF_VAR_state_passphrase="$(openssl rand -hex 32)"
    umask 077
    printf 'TF_VAR_state_passphrase=%s\n' "${TF_VAR_state_passphrase}" > "${PASS_ENC}"
    sops --encrypt --in-place "${PASS_ENC}"
    echo "Nouvelle passphrase générée + chiffrée -> ${PASS_ENC}"
    echo ">>> À COMMITTER : git add '${PASS_ENC#"${REPO}"/}' && git commit -m 'chore(iac): passphrase state via SOPS'"
  fi
fi
export TF_VAR_state_passphrase

# ---------------------------------------------------------------------------
log "2/7  tofu apply (VM games uniquement)"
cd "${TF_DIR}"
tofu apply -target=proxmox_virtual_environment_vm.games -auto-approve

# ---------------------------------------------------------------------------
log "3/7  Attente SSH de la VM ${GAMES_IP} (cloud-init)"
ok=""
for i in $(seq 1 30); do
  if ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" true 2>/dev/null; then ok=1; echo "VM joignable."; break; fi
  echo "  ...pas encore prête (${i}/30)"; sleep 10
done
[ -n "${ok}" ] || { echo "VM injoignable après ~5 min — vérifie la console Proxmox (VM 112 / pve2)."; exit 1; }

# ---------------------------------------------------------------------------
log "4/7  Repo homelab sur la VM (fix DNS template + install git)"
ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" '
  set -e
  # Le template doré ne pose pas le DNS sur IP statique -> resolv.conf sans nameserver
  grep -q "^nameserver" /etc/resolv.conf || {
    echo "nameserver 10.0.30.1" | sudo tee /etc/resolv.conf.head >/dev/null
    echo "nameserver 10.0.30.1" | sudo tee -a /etc/resolv.conf >/dev/null
  }
  sudo cloud-init status --wait >/dev/null 2>&1 || true
  # git absent du template ; attendre le lock apt (unattended-upgrades au boot)
  command -v git >/dev/null || {
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq git
  }
  [ -d ~/homelab/.git ] || git clone --depth 1 https://github.com/yapcyber/homelab.git ~/homelab
  cd ~/homelab && git fetch -q origin && git reset --hard origin/main
'

# ---------------------------------------------------------------------------
log "5/7  Livraison du .env chiffré (SOPS -> 0600, jamais de clair local ni sur le réseau)"
sops -d "${REPO}/services/games/games.enc.env" | \
  ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" 'umask 077; cat > ~/homelab/services/games/.env; chmod 600 ~/homelab/services/games/.env'

# ---------------------------------------------------------------------------
log "6/7  Démarrage RomM + pull du routeur romm.yml sur infra (Traefik recharge à chaud)"
ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" 'cd ~/homelab/services/games && docker compose up -d'
ssh "${SSH_OPTS[@]}" "${INFRA_SSH}" 'cd ~/homelab && git fetch -q origin && { [ -z "$(git status --porcelain --untracked-files=no)" ] && git reset --hard origin/main >/dev/null || echo "infra: modifs suivies, reset sauté"; }'

# ---------------------------------------------------------------------------
log "7/7  Vérifications"
sleep 8
ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" 'cd ~/homelab/services/games && docker compose ps'
ssh "${SSH_OPTS[@]}" "${GAMES_SSH}" 'curl -sS -m 8 -o /dev/null -w "RomM local (8080) : HTTP %{http_code}\n" http://127.0.0.1:8080/ || echo "RomM pas encore prêt (init MariaDB ~1 min, relance le curl)"'
curl -sS -m 10 -o /dev/null -w "romm.yapserver.fr (via Traefik, VPN) : HTTP %{http_code}\n" https://romm.yapserver.fr/ || true

echo
echo "Terminé. Ouvre https://romm.yapserver.fr (sous WireGuard) pour l'assistant de configuration RomM."
echo "Rappel : disque 20 Go -> pour une vraie collection, on repointera /romm/library vers le NAS/SMB."
unset TF_VAR_state_passphrase
