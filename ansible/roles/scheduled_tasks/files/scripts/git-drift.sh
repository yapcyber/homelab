#!/usr/bin/env bash
# Anti-dérive quotidien (verrou pull read-only).
# Vérifie deux choses :
#   1. Dérive Git : commits locaux ou fichiers suivis modifiés (alerte haute) ;
#                   retard sur origin/main (alerte normale). Non suivis = info.
#   2. Déploiements HORS-REPO : conteneurs dont le working_dir compose n'est pas
#      sous ~/homelab (dérive type firefly/jellystat/cloudflared). Alerte haute.
# Les commits sur les VM sont par ailleurs refusés par le hook git pre-commit.
set -u
drift=0

cd "$HOME/homelab" || { /usr/local/bin/homelab-alert "📂 $(hostname) : clone ~/homelab introuvable" "" high; exit 1; }
git fetch --quiet origin main || { /usr/local/bin/homelab-alert "📂 $(hostname) : git fetch impossible" "" high; exit 1; }

# --- 1. Dérive Git -----------------------------------------------------------
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
  drift=1
elif [ "$behind" -gt 0 ]; then
  /usr/local/bin/homelab-alert "⬇️ $(hostname) : $behind commit(s) de retard sur origin/main" "git pull à faire (non suivis: $untracked)"
fi

# --- 2. Déploiements hors-repo ----------------------------------------------
# Best-effort : nécessite l'accès Docker (sinon ignoré silencieusement).
if command -v docker >/dev/null 2>&1; then
  offrepo=$(docker ps --format '{{.Names}}' 2>/dev/null | while read -r c; do
    wd=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null)
    case "$wd" in
      ""|"$HOME/homelab/"*) ;;                 # pas un projet compose, ou sous le repo → OK
      *) echo "  - $c  ($wd)" ;;
    esac
  done)
  if [ -n "$offrepo" ]; then
    /usr/local/bin/homelab-alert "🧩 $(hostname) : conteneur(s) déployé(s) HORS du repo GitOps" "$offrepo
→ réconcilier sous ~/homelab/services/ (cf. runbook gitops-deploiement)." high
    drift=1
  fi
fi

exit $drift
