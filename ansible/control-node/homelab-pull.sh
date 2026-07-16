#!/usr/bin/env bash
# homelab-pull — git pull sur toutes les VM ayant un clone ~/homelab.
# Se lance depuis le control node (Elitebook). Agent SSH forwardé (-A) pour
# les remotes en git@github.com ; sans effet sur les remotes https.
# Détecte le clone dynamiquement : une VM sans ~/homelab/.git est ignorée.
set -u

# VM de service (VLAN 30). L'IP suffit ; le clone est détecté à distance.
HOSTS=(
  "infra:10.0.30.10"
  "monitoring:10.0.30.11"
  "cloud:10.0.30.12"
  "media:10.0.30.13"
  "security:10.0.30.14"
  "scanner:10.0.30.15"
  "firefly:10.0.30.16"
  "osint:10.0.30.17"
  "ir:10.0.30.18"
)

ok=0; skip=0; fail=0
printf "\n%-12s %s\n" "VM" "RÉSULTAT"
printf '%.0s─' {1..60}; echo

for entry in "${HOSTS[@]}"; do
  name="${entry%%:*}"; ip="${entry##*:}"
  # Un seul SSH par hôte : détecte le clone, se met sur une branche si besoin, pull.
  out=$(timeout 60 ssh -A -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
        -o ConnectTimeout=8 "debian@$ip" '
    set -e
    [ -d ~/homelab/.git ] || { echo "SKIP: pas de clone"; exit 0; }
    cd ~/homelab
    # Cas detached HEAD : se remettre sur main avant de puller.
    git symbolic-ref -q HEAD >/dev/null || git checkout main >/dev/null 2>&1
    before=$(git rev-parse --short HEAD)
    git fetch --quiet origin 2>&1
    if ! git merge --ff-only "origin/$(git rev-parse --abbrev-ref HEAD)" >/dev/null 2>&1; then
      echo "ERREUR: ff impossible (dérive locale ? voir git status)"; exit 3
    fi
    after=$(git rev-parse --short HEAD)
    [ "$before" = "$after" ] && echo "à jour ($after)" || echo "MAJ $before → $after"
  ' 2>&1)
  rc=$?

  if [ $rc -eq 0 ] && [[ "$out" == SKIP:* ]]; then
    printf "%-12s ⚪ %s\n" "$name" "${out#SKIP: }"; skip=$((skip+1))
  elif [ $rc -eq 0 ]; then
    printf "%-12s ✅ %s\n" "$name" "$out"; ok=$((ok+1))
  else
    printf "%-12s ❌ %s\n" "$name" "${out:-injoignable (rc=$rc)}"; fail=$((fail+1))
  fi
done

printf '%.0s─' {1..60}; echo
printf "%d à jour/mis à jour · %d ignorées · %d en échec\n\n" "$ok" "$skip" "$fail"
[ "$fail" -eq 0 ]
