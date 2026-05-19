# =============================================================================
# portfolio/Dockerfile — Build multi-stage Docusaurus → nginx
# =============================================================================
# Stage 1 (builder) : Compile le site Docusaurus en fichiers statiques HTML/CSS/JS
# Stage 2 (production) : Copie les fichiers dans nginx pour les servir
#
# AVANTAGE DU MULTI-STAGE :
#   L'image finale ne contient que nginx + les fichiers statiques.
#   Node.js, npm, node_modules (~500 Mo) ne sont PAS dans l'image de production.
#   Image finale ≈ 20 Mo au lieu de 600+ Mo.
# =============================================================================

# =============================================================================
# STAGE 1 — BUILD
# =============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copier package.json et package-lock.json séparément pour profiter
# du cache Docker — les dépendances ne sont re-installées que si ces fichiers changent.
COPY package*.json ./
RUN npm ci --frozen-lockfile

# Copier le reste du projet et builder
COPY . .
RUN npm run build

# =============================================================================
# STAGE 2 — PRODUCTION
# =============================================================================
FROM nginx:alpine AS production

# Copier les fichiers statiques compilés depuis le stage builder
COPY --from=builder /app/build /usr/share/nginx/html

# Configuration nginx optimisée pour Docusaurus (SPA avec routing client)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
