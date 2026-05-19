#!/usr/bin/env bash
# =============================================================================
# init.sh — Initialisation de la PKI Step-CA
# =============================================================================
# Ce script prépare l'environnement AVANT le premier "docker compose up".
# La PKI elle-même est initialisée automatiquement au premier démarrage Docker.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}== Init PKI Step-CA ==${NC}"
echo ""

# =============================================================================
# 1. Création des dossiers
# =============================================================================
info "Création des dossiers..."

mkdir -p data/step
mkdir -p secrets
chmod 700 secrets   # Accessible uniquement par le propriétaire

ok "Dossiers créés"

# =============================================================================
# 2. Génération du mot de passe de la clé CA
# =============================================================================
# Ce mot de passe protège la clé privée de l'Intermediate CA sur disque.
# Si quelqu'un vole le volume Docker (./data/step), il ne peut pas utiliser
# la clé sans ce mot de passe.
# SAUVEGARDER CE MOT DE PASSE dans un gestionnaire externe (Bitwarden, etc.)

info "Génération du mot de passe CA..."

CA_PASSWORD_FILE="./secrets/ca-password.txt"

if [[ -f "$CA_PASSWORD_FILE" ]]; then
  warn "Mot de passe CA existant trouvé — réutilisation (OK si PKI déjà initialisée)"
else
  # Génération d'un mot de passe fort (48 caractères base64)
  openssl rand 36 | base64 -w 0 > "$CA_PASSWORD_FILE"
  chmod 600 "$CA_PASSWORD_FILE"
  ok "Mot de passe CA généré : $CA_PASSWORD_FILE"
fi

CA_PASSWORD=$(cat "$CA_PASSWORD_FILE")
echo ""
echo -e "${RED}  ╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}  ║  ⚠️  SAUVEGARDER CE MOT DE PASSE MAINTENANT          ║${NC}"
echo -e "${RED}  ║  Sans lui, impossible de redémarrer la CA             ║${NC}"
echo -e "${RED}  ╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Mot de passe CA : ${YELLOW}${CA_PASSWORD}${NC}"
echo -e "  Fichier         : ${BLUE}${CA_PASSWORD_FILE}${NC}"
echo ""
echo -e "  → Copier dans Bitwarden / KeePass / 1Password maintenant."
echo ""

# =============================================================================
# 3. Vérification du .env
# =============================================================================
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  warn ".env créé — vérifier les valeurs (CA_NAME, CA_DNS_NAMES, CA_ADMIN_EMAIL)"
else
  ok ".env présent"
fi

# =============================================================================
# RÉSUMÉ ET PROCÉDURE COMPLÈTE
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✅  Pré-requis Step-CA prêts${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${BLUE}  ÉTAPE 1 — Démarrer la PKI (Phase 4, sur la VM VLAN 10) :${NC}"
echo -e "    docker compose up -d"
echo -e "    docker compose logs -f step-ca"
echo -e "    # Attendre le message : 'Serving HTTPS on :9000'"
echo ""
echo -e "${BLUE}  ÉTAPE 2 — Récupérer le certificat Root CA :${NC}"
echo -e "    docker cp step-ca:/home/step/certs/root_ca.crt ./data/root_ca.crt"
echo -e "    # Ce fichier est le certificat PUBLIC (pas de clé privée)"
echo -e "    # Le committer dans le repo est acceptable (c'est public par définition)"
echo ""
echo -e "${BLUE}  ÉTAPE 3 — Faire confiance au Root CA sur le Jump Host Ubuntu :${NC}"
echo -e "    sudo cp ./data/root_ca.crt /usr/local/share/ca-certificates/homelab-root.crt"
echo -e "    sudo update-ca-certificates"
echo -e "    # Vérifier : curl https://step-ca.int.yapserver.fr:9000/health"
echo ""
echo -e "${BLUE}  ÉTAPE 4 — Monter le Root CA dans Traefik (VM VLAN 40) :${NC}"
echo -e "    # Copier root_ca.crt dans le dossier de la stack Traefik :"
echo -e "    cp ./data/root_ca.crt ../infra/traefik/data/homelab-root-ca.crt"
echo -e "    # Ajouter dans traefik/docker-compose.yml (volumes section) :"
echo -e "    #   - ./data/homelab-root-ca.crt:/etc/ssl/certs/homelab-root-ca.crt:ro"
echo ""
echo -e "${BLUE}  ÉTAPE 5 — Activer le resolver Step-CA dans traefik.yml :${NC}"
echo -e "    # Décommenter dans services/infra/traefik/config/traefik.yml :"
echo -e "    #   step-ca:"
echo -e "    #     acme:"
echo -e "    #       caServer: 'https://step-ca.int.yapserver.fr:9000/acme/acme/directory'"
echo -e "    #       storage: /data/acme-internal.json"
echo -e "    #       tlsChallenge: {}"
echo ""
echo -e "${BLUE}  ÉTAPE 6 — Distribuer le Root CA aux clients WireGuard :${NC}"
echo -e "    Android/iOS  : Envoyer root_ca.crt par email → Installer le profil"
echo -e "    Windows      : Ouvrir root_ca.crt → 'Installer' → 'Autorités racines'"
echo -e "    macOS        : Keychain Access → Importer → Toujours faire confiance"
echo ""
echo -e "${YELLOW}  POUR LES SERVICES INTERNES — Label Traefik à utiliser :${NC}"
echo -e "    - \"traefik.http.routers.SERVICE.tls.certresolver=step-ca\""
echo -e "    # Au lieu de cloudflare, pour les services VLAN 10/30/50/60"
echo ""
