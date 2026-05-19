#!/usr/bin/env bash
# =============================================================================
# portfolio/init.sh — Initialisation du site portfolio Docusaurus v3
# =============================================================================
# À exécuter UNE SEULE FOIS depuis le dossier portfolio/ du repo.
# Crée le projet Docusaurus, configure le bilingue FR/EN,
# et installe les plugins recommandés.
#
# Pré-requis sur le Mini PC 5 Ubuntu 24.04 :
#   Node.js 20 LTS + npm
#   Installation : curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
#                  sudo apt-get install -y nodejs
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
info() { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }

echo ""
echo -e "${BLUE}== Initialisation Portfolio Docusaurus v3 ==${NC}"
echo ""

# =============================================================================
# 1. Vérification de Node.js
# =============================================================================
info "Vérification de Node.js..."
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [[ "$NODE_VERSION" -lt 18 ]]; then
  echo "Node.js 18+ requis. Version actuelle : $(node --version 2>/dev/null || echo 'non installé')"
  echo "Installer : curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - && sudo apt-get install -y nodejs"
  exit 1
fi
ok "Node.js $(node --version) détecté"

# =============================================================================
# 2. Création du projet Docusaurus
# =============================================================================
info "Création du projet Docusaurus v3 (TypeScript)..."

# Crée le projet dans le dossier courant (portfolio/)
# --typescript : config en TypeScript (meilleure autocomplétion, typage)
# classic      : preset incluant blog + docs + thème Infima
npx create-docusaurus@3 . classic --typescript --skip-install

ok "Projet Docusaurus créé"

# =============================================================================
# 3. Installation des dépendances + plugins
# =============================================================================
info "Installation des dépendances..."
npm install

info "Installation des plugins recommandés..."
npm install --save \
  @docusaurus/plugin-ideal-image \
  @docusaurus/plugin-pwa \
  docusaurus-plugin-sass \
  remark-math \
  rehype-katex

ok "Dépendances installées"

# =============================================================================
# 4. Configuration de l'i18n (FR/EN)
# =============================================================================
info "Génération des fichiers de traduction FR..."
npm run write-translations -- --locale fr

ok "Fichiers i18n FR générés dans i18n/fr/"

# =============================================================================
# 5. Remplacement des fichiers de config par les versions homelab
# =============================================================================
info "Application de la configuration homelab..."

# Les fichiers docusaurus.config.ts, sidebars.ts, et src/css/custom.css
# présents dans ce repo remplaceront ceux générés par Docusaurus.
# (Ils sont déjà dans portfolio/ — ce script les laisse en place)

# Supprimer les fichiers exemples par défaut de Docusaurus
rm -rf docs/tutorial-basics docs/tutorial-extras
rm -rf blog/2021-* blog/2019-* blog/authors.yml

# Créer la structure de dossiers du portfolio
mkdir -p docs/{architecture,network,phases,services,security}
mkdir -p i18n/fr/docusaurus-plugin-content-docs/current/{architecture,network,phases,services,security}
mkdir -p i18n/fr/docusaurus-plugin-content-blog

ok "Structure de dossiers créée"

# =============================================================================
# 6. Test de build local
# =============================================================================
info "Test de build (vérification qu'il n'y a pas d'erreurs)..."
npm run build 2>&1 | tail -5

ok "Build réussi"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✅  Portfolio Docusaurus initialisé${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${BLUE}  COMMANDES UTILES :${NC}"
echo ""
echo -e "  Développement local (hot reload) :"
echo -e "  ${BLUE}npm start${NC}                     → http://localhost:3000 (EN)"
echo -e "  ${BLUE}npm start -- --locale fr${NC}      → http://localhost:3000 (FR)"
echo ""
echo -e "  Build production :"
echo -e "  ${BLUE}npm run build${NC}                 → dossier build/"
echo -e "  ${BLUE}npm run serve${NC}                 → test du build prod local"
echo ""
echo -e "  Nouvelles traductions (après ajout de contenu) :"
echo -e "  ${BLUE}npm run write-translations -- --locale fr${NC}"
echo ""
echo -e "${YELLOW}  PROCHAINES ÉTAPES :${NC}"
echo -e "  1. Remplir docusaurus.config.ts (URL, liens LinkedIn/GitHub)"
echo -e "  2. Écrire le premier article de blog (blog/phase-0-architecture.md)"
echo -e "  3. git add . && git commit -m 'feat(portfolio): initialisation Docusaurus'"
echo -e "  4. En Phase 4 : déployer avec docker compose up -d"
echo ""
