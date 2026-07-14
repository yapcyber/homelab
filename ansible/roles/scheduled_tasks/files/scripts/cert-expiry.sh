#!/usr/bin/env bash
# Vérification quotidienne de l'expiration des certificats (cron-securite #10).
# Sonde TLS locale (SNI) pour chaque Host(...) des fichiers dynamiques Traefik ;
# alerte si un certificat expire dans moins de 21 jours.
set -u
DYN=/home/debian/homelab/services/infra/traefik/dynamic
THRESHOLD_DAYS=21
now=$(date +%s)
bad=""
for h in $(grep -rhoP 'Host\(`\K[^`]+' "$DYN"/*.yml | sort -u); do
  end=$(echo | timeout 10 openssl s_client -servername "$h" -connect 127.0.0.1:443 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$end" ]; then bad+="$h : sonde TLS impossible"$'\n'; continue; fi
  days=$(( ($(date -d "$end" +%s) - now) / 86400 ))
  [ "$days" -lt "$THRESHOLD_DAYS" ] && bad+="$h : expire dans $days j"$'\n'
done
if [ -n "$bad" ]; then
  /usr/local/bin/homelab-alert "🔒 $(hostname) : certificats à surveiller" "$bad" high
  exit 1
fi
