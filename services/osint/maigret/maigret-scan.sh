#!/usr/bin/env bash
set -euo pipefail
BASE="/home/debian/osint/maigret"
PROFILES="$BASE/profiles.txt"
REPORTS="$BASE/reports"
IMAGE="soxoj/maigret:latest"
STAMP="$(date +%F_%H%M)"
mkdir -p "$REPORTS"
docker pull "$IMAGE" >/dev/null 2>&1 || true

while IFS= read -r line || [[ -n "$line" ]]; do
  member="${line%%;*}"                            # avant le 1er ';'
  member="${member#"${member%%[![:space:]]*}"}"   # ltrim
  member="${member%"${member##*[![:space:]]}"}"   # rtrim
  [[ -z "$member" || "${member:0:1}" == "#" ]] && continue
  rest="${line#*;}"
  usernames="${rest//;/ }"                         # ';' restants -> espaces
  out="$REPORTS/$member/$STAMP"
  mkdir -p "$out"
  echo ">> $member : $usernames"
  # shellcheck disable=SC2086
  docker run --rm -v "$out:/app/reports" "$IMAGE" $usernames \
      --html --json simple --dns-resolver threaded --timeout 30 \
    || echo "   (échec pour $member)"
done < "$PROFILES"

chown -R 1000:1000 "$REPORTS" 2>/dev/null || true
echo "Terminé : rapports dans $REPORTS/<membre>/$STAMP/"
