# Déploiements amont (hors clone GitOps)

Quatre VM ne font tourner **que des stacks amont**, déployés depuis leur propre
dossier (pas depuis un clone `~/homelab`). Elles sont donc **hors du verrou pull
read-only** et hors du flux GitOps classique. Ce dossier versionne leurs
**configurations non-secrètes** + documente comment les reproduire.

> **Secrets** (`.env`, mots de passe *inline*, `application.conf`, certs) : jamais
> ici. Ils vivent uniquement dans les **sauvegardes chiffrées** de chaque VM
> (jobs `backup_jobs` dans `ansible/inventory/host_vars/<vm>.yml`, chiffrées AES-256
> via `/etc/homelab-backup.key`, agrégées hors-site). Voir
> [[gitops-scope-vms]] et le runbook de restauration.

| VM | IP | Stack | Déployé depuis | Sauvegarde (chiffrée) |
|----|----|-------|----------------|-----------------------|
| security | .14 | Wazuh single-node | `~/wazuh-docker` (clone upstream) | `wazuh-etc` + `wazuh-deploy` |
| scanner  | .15 | Greenbone CE | `~/greenbone-community-container` | `gvmd-db` + `greenbone-deploy` |
| osint    | .17 | SpiderFoot | `~/osint` (+ build `spiderfoot:local`) | `osint` |
| ir       | .18 | TheHive + Cortex | `~/docker` (IaC maison multi-env) | `ir-config` |

---

## security — Wazuh 4.14.5

- **Source** : `github.com/wazuh/wazuh-docker` tag **v4.14.5** (commit `4161af02`), profil `single-node/`.
- **Conteneurs** : `wazuh-manager`, `wazuh-indexer`, `wazuh-dashboard` (4.14.5).
- **Modifications locales vs upstream** : `single-node/docker-compose.yml` (mots de
  passe INDEXER/API/DASHBOARD *inline*), `config/wazuh_cluster/wazuh_manager.conf`,
  `config/wazuh_dashboard/wazuh.yml`, `config/wazuh_indexer/internal_users.yml`
  (hashes bcrypt). **Non versionnés ici** (secrets) → dans `wazuh-deploy.tar.gz.enc`.
- **Reproduire** : `git clone --branch v4.14.5 https://github.com/wazuh/wazuh-docker`,
  restaurer l'arbre `single-node/` depuis la sauvegarde, `docker compose -f single-node/docker-compose.yml up -d`.

## scanner — Greenbone Community Edition

- **Source** : `compose.yaml` autonome (fourni par Greenbone, non versionné en git amont) → **versionné ici**.
- **Conteneurs** : `greenbone-community-edition-*` (gsad, gvmd, pg-gvm, ospd-openvas, openvasd, redis-server, nginx).
- **Reproduire** : placer `compose.yaml` dans `~/greenbone-community-container`,
  `docker compose -f compose.yaml up -d`. La base GVM se restaure depuis `gvmd-db.sql.gz`.

## osint — SpiderFoot

- **Source** : `~/osint/docker-compose.yml` (**versionné ici**) + sous-dossier `spiderfoot/`
  (clone amont) buildant l'image `spiderfoot:local`.
- **Conteneur** : `osint-spiderfoot-1` (port 5001).
- **Reproduire** : restaurer `~/osint` depuis `osint.tar.gz.enc` (contient scripts,
  rapports et le contexte de build), `docker compose up -d`.

## ir — TheHive + Cortex (IaC maison)

- **Source** : `~/docker`, structure multi-environnements maison (**versionnée ici** :
  compose + `dot.env.template` + `versions.env`).
- **Environnement actif** : `cortex/` + `prod1-thehive/` (les `prod2-*` et `testing/` sont des gabarits).
- **Versions** (`versions.env`) : Cassandra 4.1.11, Elasticsearch 8.19.15, TheHive 5.7.1, Cortex 4.0.1, nginx 1.31.1.
- **Conteneurs** : `thehive`, `cortex`, `cassandra`, `elasticsearch`, `cortex-elasticsearch`, `nginx`.
- **Secrets non versionnés** → dans `ir-config.tar.gz.enc` : `prod1-thehive/.env`,
  `cortex/application.conf` (clé Play + accès ES).
- **Reproduire** : restaurer les configs, remplir un `.env` à partir du `dot.env.template`
  correspondant (`UID/GID`, `elasticsearch_password`, …), `docker compose up -d`.
  ⚠️ Les **données** Cassandra/ES (~800 Mo) ne sont pas dans `ir-config` — sauvegarde
  de données applicative = chantier à part.
