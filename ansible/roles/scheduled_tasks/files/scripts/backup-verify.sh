#!/usr/bin/env bash
# Vérification quotidienne, en lecture seule, de la dernière sauvegarde locale.
set -euo pipefail
exec 9>/run/lock/homelab-backup.lock
# Une vérification manuelle lancée pendant le dump attend sa fin.
flock -s 9
BASE=/var/backups/homelab/daily
KEYFILE=/etc/homelab-backup.key
latest=$(find "$BASE" -mindepth 1 -maxdepth 1 -type d -printf '%p\n' | sort | tail -1)
[ -n "$latest" ] || { echo "aucune sauvegarde" >&2; exit 1; }
[ "$(date -d "$(basename "$latest")" +%s)" -ge "$(date -d '2 days ago' +%s)" ] || {
  echo "dernière sauvegarde trop ancienne : $(basename "$latest")" >&2; exit 1;
}

checked=0
while IFS= read -r -d '' file; do
  case "$file" in
    *.tar.gz|*.sql.gz) gzip -t "$file" ;;
    *.enc)
      [ -r "$KEYFILE" ] || { echo "clé absente" >&2; exit 1; }
      openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:$KEYFILE" \
        -in "$file" | gzip -t
      ;;
    *) continue ;;
  esac
  checked=$((checked + 1))
done < <(find "$latest" -maxdepth 1 -type f -size +0c -print0)

[ "$checked" -gt 0 ] || { echo "aucune archive vérifiable dans $latest" >&2; exit 1; }
echo "$checked archive(s) valides dans $latest"
