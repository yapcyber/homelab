#!/usr/bin/env bash
# Health-check horaire des conteneurs (cron-securite #9).
# Alerte si un conteneur est Restarting / Dead / unhealthy / Exited != 0.
set -u
bad=$(docker ps -a --format '{{.Names}}\t{{.Status}}' \
  | awk -F'\t' '$2 ~ /Restarting|Dead|unhealthy/ || ($2 ~ /^Exited \(/ && $2 !~ /^Exited \(0\)/)')
if [ -n "$bad" ]; then
  /usr/local/bin/homelab-alert "🐳 $(hostname) : conteneur(s) en panne" "$bad" high
  exit 1
fi
