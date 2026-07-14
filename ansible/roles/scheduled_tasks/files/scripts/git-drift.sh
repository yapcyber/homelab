#!/usr/bin/env bash
# Anti-dérive Git quotidien (cron-securite #11).
# Alerte prio haute : fichiers suivis modifiés ou commits locaux (dérive vraie).
# Alerte prio normale : retard sur origin/main (pull pas encore fait).
# Les fichiers non suivis ne déclenchent pas d'alerte (comptés en info).
set -u
cd "$HOME/homelab" || { /usr/local/bin/homelab-alert "📂 $(hostname) : clone ~/homelab introuvable" "" high; exit 1; }
git fetch --quiet origin main || { /usr/local/bin/homelab-alert "📂 $(hostname) : git fetch impossible" "" high; exit 1; }

ahead=$(git rev-list --count origin/main..HEAD)
behind=$(git rev-list --count HEAD..origin/main)
mods=$(git status --porcelain --untracked-files=no)
untracked=$(git ls-files --others --exclude-standard | wc -l)

if [ -n "$mods" ] || [ "$ahead" -gt 0 ]; then
  msg="commits locaux: $ahead
fichiers suivis modifiés:
$mods
(non suivis: $untracked)"
  /usr/local/bin/homelab-alert "🚨 $(hostname) : dérive Git détectée" "$msg" high
  exit 1
fi
if [ "$behind" -gt 0 ]; then
  /usr/local/bin/homelab-alert "⬇️ $(hostname) : $behind commit(s) de retard sur origin/main" "git pull à faire (non suivis: $untracked)"
fi
