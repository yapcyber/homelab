#!/usr/bin/env bash
# Vérification des mises à jour DISPONIBLES sur tout le parc (n'applique rien).
# Couverture : 9 VM de service + 3 nœuds PVE (apt via Ansible),
# Tarasque et Security Onion (apt sans sudo — listes rafraîchies par apt-daily),
# OPNsense (si le SSH y est activé un jour ; sinon marqué non couvert).
# Résultat : notification ntfy + stdout (journal).
set -u
cd "$HOME/homelab/ansible"
NTFY=http://10.0.30.11:8082/homelab
R=""

# VMs + PVE (apt, root via become)
OUT=$(timeout 900 ansible services,proxmox -m shell -a \
  'apt-get update -qq >/dev/null 2>&1; n=$(apt list --upgradable 2>/dev/null | grep -c upgradable); s=$(test -f /var/run/reboot-required && echo " [reboot requis]"); echo "$n MAJ$s"' 2>/dev/null \
  | paste - - | sed -E "s/ \| CHANGED \| rc=[0-9]+ >>//; s/ \| UNREACHABLE.*/ INJOIGNABLE/" | sort)
R+="$OUT"$'\n'

# Tarasque — NB: grep -c sort en code 1 si 0 résultat,
# d'où le "; exit 0" pour ne pas confondre "0 MAJ" et "injoignable".
SO=$(timeout 60 ssh -S none -o BatchMode=yes -o ConnectTimeout=8 debian@10.0.30.30 \
  'apt list --upgradable 2>/dev/null | grep -c upgradable; exit 0' 2>/dev/null)
[ -n "$SO" ] \
  && R+="tarasque	$SO MAJ (listes apt-daily)"$'\n' \
  || R+="tarasque	INJOIGNABLE"$'\n'

# Security Onion bare metal. Surcharger SECURITY_ONION_USER si son compte SSH
# diffère de celui du template Debian.
SECURITY_ONION_USER="${SECURITY_ONION_USER:-debian}"
SO_UPDATES=$(timeout 60 ssh -S none -o BatchMode=yes -o ConnectTimeout=8 \
  "${SECURITY_ONION_USER}@10.0.50.10" \
  'apt list --upgradable 2>/dev/null | grep -c upgradable; exit 0' 2>/dev/null)
[ -n "$SO_UPDATES" ] \
  && R+="security-onion	$SO_UPDATES MAJ (listes apt-daily)"$'\n' \
  || R+="security-onion	INJOIGNABLE (user=$SECURITY_ONION_USER)"$'\n'

# OPNsense (auto-inclus dès que SSH root activé)
OPN=$(timeout 30 ssh -S none -o BatchMode=yes -o ConnectTimeout=6 root@10.0.100.1 \
  'opnsense-update -c >/dev/null 2>&1 && echo "MAJ firmware disponible" || echo "à jour"' 2>/dev/null) \
  && R+="opnsense	$OPN"$'\n' \
  || R+="opnsense	non couvert (SSH désactivé)"$'\n'

echo "$R"
curl -fsS -m 10 -H "Title: 🔎 Vérif MAJ du parc" -H "Tags: mag" -d "$R" "$NTFY" >/dev/null || true
