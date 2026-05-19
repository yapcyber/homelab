#!/usr/bin/env bash
# =============================================================================
# init.sh — Initialisation OpenVAS / Greenbone Community Edition
# =============================================================================
# À exécuter en Phase 4, APRÈS le premier "docker compose up -d"
# et APRÈS avoir attendu la fin de la synchronisation des feeds.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}== Init OpenVAS / Greenbone Community Edition ==${NC}"
echo ""

# =============================================================================
# 1. Vérification que gvmd est prêt
# =============================================================================
info "Vérification que gvmd est opérationnel..."

MAX_WAIT=180  # 3 minutes max
WAIT=0
until docker compose exec -u gvmd gvmd gvmd --get-users > /dev/null 2>&1; do
  WAIT=$((WAIT + 5))
  if [[ $WAIT -ge $MAX_WAIT ]]; then
    error "gvmd n'est pas prêt après ${MAX_WAIT}s. Vérifier : docker compose logs gvmd"
  fi
  warn "gvmd pas encore prêt... attente (${WAIT}s/${MAX_WAIT}s)"
  sleep 5
done
ok "gvmd est opérationnel"

# =============================================================================
# 2. Vérification de la sync des feeds
# =============================================================================
# Les feeds sont synchronisés de façon asynchrone au démarrage.
# Tenter de scanner avant la fin de la sync = 0 résultat.
echo ""
info "Vérification de l'état des feeds de vulnérabilités..."

FEED_STATUS=$(docker compose exec -u gvmd gvmd gvmd --get-feeds 2>&1 || true)
echo "$FEED_STATUS"

echo ""
warn "Si les feeds ne sont pas encore synchronisés, patienter 30-60 minutes."
warn "Surveiller la progression : docker compose logs -f vulnerability-tests notus-data scap-data"
echo ""

# =============================================================================
# 3. Création du compte administrateur
# =============================================================================
echo -e "${BLUE}Création du compte administrateur OpenVAS...${NC}"
echo ""
echo -n "  Entrer le mot de passe admin OpenVAS : "
read -rs ADMIN_PASSWORD
echo ""

if [[ -z "$ADMIN_PASSWORD" ]]; then
  error "Le mot de passe ne peut pas être vide."
fi

# Créer l'utilisateur admin
docker compose exec -u gvmd gvmd \
  gvmd --user=admin --new-password="$ADMIN_PASSWORD"

ok "Compte admin OpenVAS créé / mot de passe mis à jour"

# =============================================================================
# 4. Configuration recommandée post-démarrage
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✅  OpenVAS initialisé${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${BLUE}  ACCÈS :${NC}"
echo -e "  https://openvas.${DOMAIN:-yapserver.fr}"
echo -e "  Login : admin / [mot de passe défini ci-dessus]"
echo ""
echo -e "${BLUE}  CONFIGURATION RECOMMANDÉE (dans l'interface web) :${NC}"
echo ""
echo -e "  1. Targets → New Target"
echo -e "     Créer un target par groupe VLAN (voir .env.example)"
echo -e "     Hosts : 10.0.10.0/24, 10.0.30.0/24, etc."
echo ""
echo -e "  2. Tasks → New Task"
echo -e "     Scan Config : Full and Fast"
echo -e "     Target : le groupe créé"
echo -e "     Schedule : Every Sunday at 02:00 (Administration → Schedules)"
echo ""
echo -e "  3. Administration → Feed Status"
echo -e "     Vérifier que tous les feeds sont 'Current'"
echo -e "     Les premiers scans sans feeds à jour = résultats incomplets"
echo ""
echo -e "  4. Administration → Users"
echo -e "     Créer un compte lecture seule pour Wazuh (si intégration Phase 5)"
echo ""
echo -e "${YELLOW}  INTÉGRATION WAZUH (Phase 5) :${NC}"
echo -e "  Wazuh peut importer les résultats OpenVAS automatiquement."
echo -e "  Dans ossec.conf → ajouter un wodle openvas avec l'IP et les credentials."
echo ""
