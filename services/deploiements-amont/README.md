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
| ir       | .18 | TheHive + Cortex | `~/docker` (IaC maison multi-env) | `ir-config` + `ir-cassandra` + `ir-thehive-files` + `ir-cortex-es` |

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
- **Sauvegarde des données** (jobs `backup_jobs` d'ir, chiffrés) :
  - `ir-cassandra` — BDD primaire TheHive. `nodetool flush` + `nodetool snapshot`
    du keyspace `thehive` (cohérent, hardlinks) → tar du snapshot. Contient
    `schema.cql` + SSTables → **restaurable schéma inclus**.
  - `ir-thehive-files` — pièces jointes (`thehive/data/files`) + config TheHive.
  - `ir-cortex-es` — store primaire Cortex (`cortex/es-data`), sauvegarde **à froid**
    (arrêt ~qq sec de `cortex-elasticsearch`, trap = redémarrage garanti).
  - ES TheHive (`thehive_global`) **non sauvegardé** : index reconstructible depuis
    Cassandra (réindexation TheHive au restore).
- **Restaurer** :
  1. Reproduire le déploiement (configs + `.env` depuis `dot.env.template`), stack à l'arrêt.
  2. **Cassandra** : démarrer `cassandra`, laisser TheHive créer le schéma OU appliquer
     `schema.cql`, copier les SSTables du snapshot dans les dossiers de chaque table,
     puis `nodetool refresh thehive <table>`.
  3. **Cortex ES** : décompresser `ir-cortex-es` dans `cortex/es-data` (ES arrêté), démarrer.
  4. **TheHive** : démarrer, réindexer si besoin ; restaurer les pièces jointes.
  - ⚠️ Les **données** ne couvrent pas les jobs Cortex en cours ni les logs (volatils).
