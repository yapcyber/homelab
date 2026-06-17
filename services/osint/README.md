# osint — VM osint (10.0.30.17)

## SpiderFoot (conteneur)
Image **buildee localement** `spiderfoot:local` depuis l'upstream
(non vendu dans ce repo : projet tiers + licence propre).

Provenance epinglee :
- upstream : https://github.com/smicallef/spiderfoot.git
- version  : SpiderFoot 4.0.0 (commit 0f815a20)

Reconstruire :
    git clone https://github.com/smicallef/spiderfoot.git ~/osint/spiderfoot
    cd ~/osint/spiderfoot && git checkout 0f815a20
    docker build -t spiderfoot:local .
    docker compose up -d        # voir docker-compose.yml

Hors perimetre Renovate (build local).

## Maigret (runner systemd hebdomadaire)
Scan ponctuel via `soxoj/maigret:latest` (tag flottant assume — `docker pull`
a chaque run), pilote par `maigret/maigret-scan.sh`, declenche par les units
de `systemd/`.

Deploiement des units :
    sudo cp systemd/maigret-scan.{service,timer} /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now maigret-scan.timer

## NON committe (prive / PII)
- `~/osint/spiderfoot/` : clone upstream.
- `maigret/profiles.txt` : pseudos reels de la famille (cf .example).
- `maigret/reports/`     : resultats OSINT sur des personnes reelles.
