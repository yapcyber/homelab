#!/usr/bin/env bash
# =============================================================================
# init.sh — Initialisation de la stack Traefik + CrowdSec
# =============================================================================
# À exécuter UNE FOIS avant le premier "docker compose up"
# Ce script crée les pré-requis que Docker ne peut pas créer lui-même.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
info() { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }

echo ""
echo -e "${BLUE}== Init Stack Traefik + CrowdSec ==${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1. Réseau Docker partagé
# ---------------------------------------------------------------------------
# traefik-proxy est le réseau que toutes les stacks utilisent pour être
# joignables par Traefik. Il est créé une seule fois sur l'hôte.
info "Création du réseau Docker traefik-proxy..."
if docker network inspect traefik-proxy &>/dev/null; then
  warn "Réseau traefik-proxy déjà existant — skip"
else
  docker network create traefik-proxy
  ok "Réseau traefik-proxy créé"
fi

# ---------------------------------------------------------------------------
# 2. Dossiers de données persistantes
# ---------------------------------------------------------------------------
info "Création des dossiers de données..."
mkdir -p data/logs
mkdir -p data/crowdsec/db
mkdir -p data/crowdsec/config
mkdir -p dynamic/secrets
ok "Dossiers data/ créés"

# Le file provider Traefik n'interpole pas les variables d'environnement.
if [[ ! -s "dynamic/secrets/traefik_users" ]]; then
  warn "dynamic/secrets/traefik_users absent"
  echo "  Générer avant le déploiement :"
  echo "  htpasswd -nbB admin 'MOT_DE_PASSE' > dynamic/secrets/traefik_users"
fi

# ---------------------------------------------------------------------------
# 3. Fichier acme.json — Stockage des certificats Let's Encrypt
# ---------------------------------------------------------------------------
# Ce fichier DOIT exister avant le démarrage de Traefik ET avoir les
# permissions 600 (lisible uniquement par le propriétaire).
# Traefik refuse de démarrer si ce fichier n'a pas les bonnes permissions.
info "Création du fichier acme-cloudflare.json..."
if [[ ! -f "data/acme-cloudflare.json" ]]; then
  touch data/acme-cloudflare.json
  chmod 600 data/acme-cloudflare.json
  ok "data/acme-cloudflare.json créé (permissions 600)"
else
  chmod 600 data/acme-cloudflare.json
  warn "data/acme-cloudflare.json déjà existant — permissions vérifiées"
fi

# ---------------------------------------------------------------------------
# 4. Vérification du fichier .env
# ---------------------------------------------------------------------------
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  warn ".env créé depuis .env.example — REMPLIR LES VALEURS avant de continuer !"
else
  ok ".env présent"
fi

# ---------------------------------------------------------------------------
# Résumé et prochaines étapes
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅  Pré-requis Traefik initialisés${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}  ÉTAPES SUIVANTES :${NC}"
echo ""
echo -e "  1. Remplir le fichier .env (CF_API_EMAIL, CF_DNS_API_TOKEN, etc.)"
echo ""
echo -e "  2. Démarrer CrowdSec seul pour générer la clé bouncer :"
echo -e "     ${BLUE}docker compose up crowdsec -d${NC}"
echo -e "     ${BLUE}sleep 30${NC}"
echo -e "     ${BLUE}docker exec crowdsec cscli bouncers add traefik-bouncer${NC}"
echo -e "     → Copier la clé dans .env (CROWDSEC_BOUNCER_API_KEY)"
echo ""
echo -e "  3. Démarrer la stack complète :"
echo -e "     ${BLUE}docker compose up -d${NC}"
echo ""
echo -e "  4. Vérifier les logs :"
echo -e "     ${BLUE}docker compose logs -f traefik${NC}"
echo -e "     ${BLUE}docker compose logs -f crowdsec${NC}"
echo ""
