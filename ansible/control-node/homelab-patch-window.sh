#!/usr/bin/env bash
# Fenêtre de patch hebdomadaire (cron-securite #3 + #7), depuis le control
# node (Elitebook) : snapshots Proxmox → patch Ansible du parc → notif ntfy.
# Installé en unité systemd *user* : ~/.config/systemd/user/homelab-patch.*
set -uo pipefail
cd "$HOME/homelab/ansible"

NTFY=http://10.0.30.11:8082/homelab
alert() { curl -fsS -m 10 -H "Title: $1" -H "Priority: ${3:-default}" -d "$2" "$NTFY" >/dev/null || true; }

alert "🩹 Fenêtre de patch : démarrage" "snapshots Proxmox puis patch du parc"
if ansible-playbook playbooks/proxmox-snapshot.yml >/tmp/patch-window.log 2>&1 \
   && ansible-playbook playbooks/patch.yml >>/tmp/patch-window.log 2>&1; then
  alert "✅ Fenêtre de patch : terminée" "$(tail -5 /tmp/patch-window.log)"
else
  alert "❌ Fenêtre de patch : ÉCHEC" "$(tail -15 /tmp/patch-window.log)" high
  exit 1
fi
