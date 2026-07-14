#!/usr/bin/env bash
# Sauvegarde quotidienne (cron-securite #6).
# Exécute les jobs déposés dans /etc/homelab-backup.d/*.sh (un job = un
# snippet shell qui écrit dans $DAILY). Rotation : 7 quotidiennes,
# 4 hebdomadaires (dimanche), 3 mensuelles (le 1er) — via hard links.
# Les jobs sensibles chiffrent avec `enc` (clé /etc/homelab-backup.key,
# à sauvegarder dans Vaultwarden : sans elle, pas de restauration).
set -u
BASE=/var/backups/homelab
DAILY="$BASE/daily/$(date +%F)"
KEYFILE=/etc/homelab-backup.key
mkdir -p "$DAILY" "$BASE/weekly" "$BASE/monthly"
chmod 700 "$BASE"

enc() { openssl enc -aes-256-cbc -pbkdf2 -pass "file:$KEYFILE"; }
export -f enc
export KEYFILE DAILY

errs=""
shopt -s nullglob
for job in /etc/homelab-backup.d/*.sh; do
  name=$(basename "$job" .sh)
  if ! out=$(bash -e -o pipefail "$job" 2>&1); then
    errs+="[$name] $(echo "$out" | tail -c 300)"$'\n'
  fi
done

# Promotion hebdo (dimanche) et mensuelle (le 1er) — hard links, coût nul
[ "$(date +%u)" = 7 ] && cp -al "$DAILY" "$BASE/weekly/$(date +%F)" 2>/dev/null
[ "$(date +%d)" = 01 ] && cp -al "$DAILY" "$BASE/monthly/$(date +%F)" 2>/dev/null

# Rétention
find "$BASE/daily"   -mindepth 1 -maxdepth 1 -type d -mtime +7  -exec rm -rf {} +
ls -1dt "$BASE/weekly"/*/  2>/dev/null | tail -n +5 | xargs -r rm -rf
ls -1dt "$BASE/monthly"/*/ 2>/dev/null | tail -n +4 | xargs -r rm -rf

if [ -n "$errs" ]; then
  /usr/local/bin/homelab-alert "💾 $(hostname) : échec sauvegarde" "$errs" high
  exit 1
fi
echo "backup OK : $(du -sh "$DAILY" | cut -f1) dans $DAILY"
