#!/usr/bin/env bash
# =============================================================================
# init.sh — Initialisation de la stack Wazuh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}== Init Stack Wazuh SIEM ==${NC}"
echo ""

# =============================================================================
# 1. PRÉREQUIS OS CRITIQUE — vm.max_map_count
# =============================================================================
# OpenSearch (Wazuh Indexer) utilise des fichiers mappés en mémoire (mmap).
# Par défaut, Linux limite le nombre de ces mappings à 65530.
# OpenSearch en a besoin de 262144 minimum.
# Sans ce paramètre → l'Indexer refuse de démarrer avec l'erreur :
#   "max virtual memory areas vm.max_map_count [65530] is too low"
info "Vérification de vm.max_map_count..."

CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count)
REQUIRED_MAP_COUNT=262144

if [[ "$CURRENT_MAP_COUNT" -lt "$REQUIRED_MAP_COUNT" ]]; then
  warn "vm.max_map_count=$CURRENT_MAP_COUNT — trop bas pour OpenSearch"
  info "Application du paramètre..."
  # Permanent (survit aux redémarrages)
  if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
  else
    sudo sed -i 's/vm.max_map_count.*/vm.max_map_count=262144/' /etc/sysctl.conf
  fi
  # Immédiat (sans redémarrage)
  sudo sysctl -w vm.max_map_count=262144
  ok "vm.max_map_count=262144 appliqué (permanent)"
else
  ok "vm.max_map_count=$CURRENT_MAP_COUNT — OK"
fi

# =============================================================================
# 2. Création des dossiers de données
# =============================================================================
info "Création des dossiers de données..."
mkdir -p data/{certs,manager/{api,etc,logs,queue,wodles,filebeat},indexer}
ok "Dossiers créés"

# =============================================================================
# 3. Vérification du .env
# =============================================================================
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  warn ".env créé — REMPLIR les mots de passe avant de continuer !"
else
  ok ".env présent"
fi

# =============================================================================
# 4. Génération des certificats TLS internes
# =============================================================================
# Les certificats sont nécessaires pour la communication sécurisée entre
# Manager, Indexer et Dashboard. Ils sont différents des certs Step-CA.
info "Génération des certificats TLS internes Wazuh..."

if [[ -f "data/certs/root-ca.pem" ]]; then
  warn "Certificats existants trouvés — skip (supprimer data/certs/ pour regénérer)"
else
  docker compose -f generate-certs.yml run --rm generator
  ok "Certificats générés dans data/certs/"
fi

# =============================================================================
# 5. Génération des hashes de mots de passe pour internal_users.yml
# =============================================================================
echo ""
echo -e "${YELLOW}  ⚠️  ACTION MANUELLE REQUISE — Hashes des mots de passe${NC}"
echo ""
echo -e "  Le fichier config/wazuh_indexer/internal_users.yml"
echo -e "  contient des hashes BCRYPT des mots de passe OpenSearch."
echo -e "  Vous devez remplacer les hashes par ceux de vos mots de passe."
echo ""
echo -e "  Pour générer le hash du WAZUH_INDEXER_PASSWORD :"
echo -e "  ${BLUE}docker run --rm wazuh/wazuh-indexer:${WAZUH_VERSION:-4.9.0} bash -c \\"
echo -e "    \"plugins/opensearch-security/tools/hash.sh -p VOTRE_MOT_DE_PASSE\"${NC}"
echo ""
echo -e "  Remplacer les hashes des utilisateurs : admin, kibanaserver,"
echo -e "  kibanaro, logstash, filebeat, wazuh-wui"
echo ""

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✅  Pré-requis Wazuh initialisés${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${BLUE}  SÉQUENCE DE DÉMARRAGE (Phase 4) :${NC}"
echo ""
echo -e "  1. Remplir .env et mettre à jour les hashes dans internal_users.yml"
echo -e "  2. Démarrer l'Indexer en premier :"
echo -e "     ${BLUE}docker compose up wazuh-indexer -d${NC}"
echo -e "     ${BLUE}docker compose logs -f wazuh-indexer${NC}  # Attendre 'ready'"
echo ""
echo -e "  3. Démarrer le Manager :"
echo -e "     ${BLUE}docker compose up wazuh-manager -d${NC}"
echo ""
echo -e "  4. Démarrer le Dashboard :"
echo -e "     ${BLUE}docker compose up wazuh-dashboard -d${NC}"
echo ""
echo -e "  5. Accéder à https://wazuh.yapserver.fr"
echo -e "     Login : admin / WAZUH_INDEXER_PASSWORD"
echo ""
echo -e "${BLUE}  CONFIGURATION POST-DÉMARRAGE :${NC}"
echo -e "  - Ajouter les agents sur chaque VM (voir .env.example)"
echo -e "  - Configurer le syslog OPNsense → 10.0.50.10:514"
echo -e "  - Créer des alertes personnalisées dans le Dashboard"
echo ""
