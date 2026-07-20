#!/usr/bin/env bash
# =============================================================================
# scripts/bootstrap-portfolio-dmz.sh
# -----------------------------------------------------------------------------
# Provisionne la VM DMZ (portfolio_dmz, VLAN 40) puis déploie le portfolio
# public (nginx + cloudflared → nginx local). À lancer sur l'EliteBook.
#
#   ./scripts/bootstrap-portfolio-dmz.sh
#
# Passphrase du state : lue automatiquement via SOPS
#   (iac/opentofu/state-passphrase.enc.env — créée par le bootstrap games).
#
# PRÉREQUIS de TON côté (le runbook les VÉRIFIE et s'arrête sinon) :
#   - OPNsense VLAN 40 : sortie Internet autorisée (443 + pulls), init vers
#     VLAN 30 bloquée ;
#   - Cloudflare (tunnel portfolio-homelab) : Public Hostname
#       portfolio.yapserver.fr → http://portfolio:80
# =============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO}/iac/opentofu"
PASS_ENC="${TF_DIR}/state-passphrase.enc.env"
DMZ_IP="10.0.40.20"
DMZ_SSH="debian@${DMZ_IP}"
SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)

log() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
log "1/7  Passphrase du state (SOPS)"
[ -f "${PASS_ENC}" ] || { echo "Passphrase SOPS absente (${PASS_ENC})."; echo "Lance d'abord scripts/bootstrap-games-romm.sh (qui la crée) ou committe-la."; exit 1; }
export TF_VAR_state_passphrase="$(sops -d "${PASS_ENC}" | sed -n 's/^TF_VAR_state_passphrase=//p')"

# ---------------------------------------------------------------------------
log "2/7  tofu apply (VM portfolio-dmz uniquement)"
cd "${TF_DIR}"
tofu apply -target=proxmox_virtual_environment_vm.portfolio_dmz -auto-approve

# ---------------------------------------------------------------------------
log "3/7  Attente SSH de la VM ${DMZ_IP} (cloud-init)"
ok=""
for i in $(seq 1 30); do
  if ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" true 2>/dev/null; then ok=1; echo "VM joignable."; break; fi
  echo "  ...pas encore prête (${i}/30)"; sleep 10
done
[ -n "${ok}" ] || { echo "VM injoignable après ~5 min — vérifie la console Proxmox (VM 111 / pve1)."; exit 1; }

# ---------------------------------------------------------------------------
log "4/7  Contrôles DMZ : DNS + egress Internet + isolation VLAN 30"
# Le template ne pose pas le DNS sur IP statique -> on le fixe avant tout test
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'grep -q "^nameserver" /etc/resolv.conf || { echo "nameserver 10.0.40.1" | sudo tee /etc/resolv.conf.head >/dev/null; echo "nameserver 10.0.40.1" | sudo tee -a /etc/resolv.conf >/dev/null; }'
if ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'ping -c1 -W3 1.1.1.1 >/dev/null 2>&1 && curl -sS -m 8 -o /dev/null https://github.com'; then
  echo "  DNS + egress Internet : OK"
else
  echo "  !! PAS d'egress Internet en VLAN 40 (ou DNS 10.0.40.1 KO) → configure OPNsense (sortie 443 + pulls). Déploiement stoppé."
  exit 1
fi
if ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'curl -sS -m 5 -o /dev/null https://10.0.30.10' 2>/dev/null; then
  echo "  !! ATTENTION : la DMZ JOINT le VLAN 30 (10.0.30.10) → isolation NON effective, à corriger sur OPNsense."
else
  echo "  isolation VLAN 30 : OK (10.0.30.10 injoignable, attendu)"
fi

# ---------------------------------------------------------------------------
log "5/7  Repo + secret tunnel (SOPS → .env 0600)"
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" '
  set -e
  sudo cloud-init status --wait >/dev/null 2>&1 || true
  # git absent du template ; attendre le lock apt (unattended-upgrades au boot)
  command -v git >/dev/null || {
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq git
  }
  [ -d ~/homelab/.git ] || git clone --depth 1 https://github.com/yapcyber/homelab.git ~/homelab
  cd ~/homelab && git fetch -q origin && git reset --hard origin/main
'
sops -d "${REPO}/portfolio/portfolio.enc.env" | \
  ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'umask 077; cat > ~/homelab/portfolio/.env; chmod 600 ~/homelab/portfolio/.env'

# ---------------------------------------------------------------------------
log "6/7  Build + démarrage (nginx + cloudflared)"
# Buffers UDP pour QUIC (cloudflared) — sinon paquets perdus sous la charge parallèle d'un navigateur
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'printf "net.core.rmem_max=7500000\nnet.core.wmem_max=7500000\n" | sudo tee /etc/sysctl.d/99-quic-buffers.conf >/dev/null; sudo /usr/sbin/sysctl -q -p /etc/sysctl.d/99-quic-buffers.conf'
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'cd ~/homelab/portfolio && docker compose up -d --build'

# ---------------------------------------------------------------------------
log "7/7  Vérifications"
sleep 8
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'cd ~/homelab/portfolio && docker compose ps'
ssh "${SSH_OPTS[@]}" "${DMZ_SSH}" 'docker logs --tail 6 portfolio-cloudflared 2>&1 | sed "s/^/  cf: /"'
echo "--- portfolio.yapserver.fr depuis Internet (si Public Hostname configuré) ---"
curl -sSL -m 12 -o /dev/null -w "portfolio.yapserver.fr : HTTP %{http_code}\n" https://portfolio.yapserver.fr/ || echo "  (pas encore joignable — vérifie le Public Hostname Cloudflare)"

echo
echo "Terminé. Rappel Cloudflare (tunnel portfolio-homelab) : Public Hostname portfolio.yapserver.fr → http://portfolio:80."
unset TF_VAR_state_passphrase
