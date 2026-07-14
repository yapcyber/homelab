#!/usr/bin/env bash
# Mise à jour quotidienne des feeds Greenbone (cron-securite #2).
# Flux officiel "community containers" : pull des images de données
# (NVT/SCAP/CERT/notus) puis up -d pour relancer les conteneurs de feed.
set -u
for d in /home/debian/greenbone-community-container /home/debian/greenbone; do
  [ -f "$d/docker-compose.yml" ] && { GB_DIR="$d"; break; }
done
[ -z "${GB_DIR:-}" ] && { echo "compose Greenbone introuvable" >&2; exit 1; }
cd "$GB_DIR"
docker compose pull --quiet 2>&1 | tail -3
docker compose up -d 2>&1 | tail -3
echo "feeds Greenbone rafraîchis ($GB_DIR)"
