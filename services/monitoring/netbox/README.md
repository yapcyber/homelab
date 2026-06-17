# NetBox — VM monitoring (10.0.30.11)

Deploye via **netbox-docker** (clone upstream, NON vendu ici : projet tiers + licence).

## Provenance epinglee
- upstream : https://github.com/netbox-community/netbox-docker.git
- ref      : 55edb98 (netbox-docker 5.0.1)
- images   : netboxcommunity/netbox:v4.6-5.0.1, postgres:18-alpine, valkey/valkey:9.0-alpine
- Versions pinnees cote upstream => hors perimetre Renovate (MaJ = re-clone/pull).

## Setup
    git clone https://github.com/netbox-community/netbox-docker.git ~/netbox-docker
    cd ~/netbox-docker && git checkout 55edb98
    # depuis ce repo : remplir et copier les env + l'override
    cp <repo>/services/monitoring/netbox/env/*.env.example env/   # puis renommer en .env + remplir secrets
    cp <repo>/services/monitoring/netbox/docker-compose.override.yml.example docker-compose.override.yml
    docker compose up -d

Les valeurs de config non-secretes (DB_HOST, REDIS_HOST...) sont celles par defaut de netbox-docker upstream.

## NON committe (prive)
- ~/netbox-docker/ : clone upstream complet
- docker-compose.override.yml : contient SUPERUSER_PASSWORD
- env/*.env : SECRET_KEY, DB/REDIS/EMAIL passwords, API_TOKEN_PEPPER
