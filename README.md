# YapServer Homelab

Infrastructure auto-hébergée personnelle et familiale, également utilisée comme
laboratoire cybersécurité et portfolio orienté **SOC**, **Detection Engineering**,
réponse à incident et infrastructure-as-code.

- Auteur : [yapcyber](https://github.com/yapcyber)
- Portfolio : [yapserver.fr](https://yapserver.fr)
- Accès distant : WireGuard
- Exposition Internet : aucune publication directe ; Cloudflare Tunnel reste prévu par exception

## Objectifs

Le projet remplit trois fonctions complémentaires :

1. héberger des services personnels et familiaux durables ;
2. construire un environnement défensif réaliste, du réseau à la réponse à incident ;
3. rendre l'infrastructure reproductible, observable et documentée.

Le principe directeur est **fail-closed** : une autorisation doit être explicite,
les secrets ne sont jamais stockés en clair dans Git, et une configuration non
validée ne doit pas être déployée.

## Architecture

```text
Internet
  |
Box opérateur (double NAT temporaire)
  |
OPNsense bare metal
  |-- VLAN Management / Corosync / Production / DMZ / SOC
  |-- VLAN Storage / IoT / Guest / Gaming / Admin / WireGuard
  |
Cisco 3560X -- SPAN --> Security Onion (Suricata + Zeek)
  |
Cluster Proxmox VE : pve1 / pve2 / pve3
  |-- VMs Docker de services
  |-- TrueNAS SCALE (stockage NFS/ZFS provisoire)
  `-- workloads sécurité, monitoring et réponse à incident

Control node : EliteBook -- Packer / OpenTofu / Ansible / Git
```

Le trafic inter-VLAN est filtré par OPNsense. Le trafic est-ouest du VLAN
Production ne traverse pas le pare-feu ; les ports Docker publiés nécessaires au
proxy inter-VM sont donc protégés localement dans `DOCKER-USER`. Leur accès direct
est réservé à Traefik et au VLAN Admin.

## Services

### Identité, accès et infrastructure

- Traefik 3.7, certificats Let's Encrypt par DNS challenge et CrowdSec ;
- Authentik : MFA TOTP, enrôlement sur invitation, OIDC et forward-auth ;
- Homarr et NetBox ;
- WireGuard, Unbound split-DNS et Cloudflare DNS ;
- ntfy pour les alertes opérationnelles.

### Cloud personnel et usages familiaux

- Vaultwarden, en inscription fermée et création sur invitation ;
- Nextcloud et Nextcloud Talk HPB ;
- Immich ;
- Home Assistant ;
- Dawarich, Wanderer et SplitPro.

### Médias et lecture

- Jellyfin, Jellystat et Seerr ;
- Prowlarr, Radarr, Sonarr, Lidarr, qBittorrent derrière Gluetun ;
- Navidrome et Beets ;
- AudioBookShelf, Kavita et Readeck ;
- stockage média TrueNAS complété par une source SMB sur le PC Gaming.

### Finances

- Firefly III et Data Importer ;
- Ghostfolio.

### Observabilité

- Prometheus, Grafana, Loki et Promtail ;
- Node Exporter et cAdvisor durci ;
- Uptime Kuma ;
- annotations de maintenance et tableau de conformité Wazuh.

### Sécurité et réponse à incident

- Security Onion : Suricata, Zeek et visibilité réseau via SPAN ;
- Wazuh : SIEM/HIDS, FIM, SCA, vulnérabilités et règles locales ;
- Greenbone/OpenVAS ;
- TheHive 5 et Cortex 4 avec analyzer Maigret ;
- SpiderFoot et Maigret pour l'OSINT ;
- règles Sigma versionnées dans `detections/`.

### Projets complémentaires

- Kyber sur le PC Gaming pour le cloud gaming en accès VPN-only ;
- backend LLM local Tarasque/Ollama, hors de ce dépôt ;
- pipeline CV-as-Code en cours de développement ;
- serveur mail receive-only prévu, non déployé.

## Automatisation et GitOps

La chaîne cible est :

```text
Packer -> template Debian doré -> OpenTofu -> VM -> Ansible -> services Docker
                                                |
Git / Renovate -> validation -> pull VM -> déploiement contrôlé
```

État actuel :

- Packer construit le template Debian 13 ;
- OpenTofu sait provisionner une VM de validation, avec state chiffré ;
- Ansible gère le patching, les snapshots pré-maintenance, la journalisation
  Docker, les sauvegardes et les timers de sécurité ;
- Renovate ouvre les mises à jour, avec validation manuelle des majeures ;
- les VMs applicatives font uniquement des pulls en lecture ;
- la généralisation d'OpenTofu aux VMs de production et la CI de validation
  restent à réaliser.

## Tâches planifiées

Des timers systemd versionnés assurent notamment :

- sauvegardes chiffrées et rotation ;
- contrôle de santé des conteneurs ;
- détection de dérive Git ;
- contrôle des certificats et agents Wazuh ;
- mise à jour des feeds Greenbone ;
- rappel de test de restauration ;
- fenêtre hebdomadaire snapshot puis patch Ansible.

Les alertes convergent vers ntfy. Une sauvegarde n'est considérée fiable qu'après
un test de restauration ; cette validation reste un chantier prioritaire.

## Gestion des secrets

- les `.env`, clés, certificats et données runtime sont ignorés par Git ;
- Ansible Vault chiffre actuellement les secrets utilisés par l'inventaire ;
- SOPS + Age est configuré dans `.sops.yaml`, mais aucun secret SOPS n'est encore
  versionné : il s'agit pour l'instant d'un socle préparatoire ;
- `prompting/` est volontairement exclu du dépôt public, car il contient la
  cartographie détaillée, l'état de travail et des informations personnelles.

La clé privée Age et les clés de sauvegarde doivent être conservées hors du dépôt
et sauvegardées dans un emplacement indépendant.

## Structure du dépôt

```text
homelab/
|-- ansible/
|   |-- control-node/       # scripts et timers de l'EliteBook
|   |-- inventory/          # inventaires statique/dynamique et host_vars
|   |-- playbooks/          # baseline, patch, snapshots, tâches planifiées
|   `-- roles/              # maintenance, alerting et filtrage Docker
|-- detections/
|   `-- sigma/              # detection-as-code
|-- docs/                   # architecture, documentation et runbooks
|-- iac/
|   |-- opentofu/           # provisioning Proxmox
|   `-- packer/             # templates Debian
|-- infrastructure/         # procédures NAS/réseau/Proxmox
|-- portfolio/              # site Docusaurus bilingue
|-- scripts/                # outils d'exploitation ponctuels
|-- services/
|   |-- cloud/              # Nextcloud, Immich, Vaultwarden, HA, etc.
|   |-- firefly/            # Firefly III et Ghostfolio
|   |-- infra/              # Traefik, Authentik, Homarr, NetBox, Talk HPB
|   |-- media/              # Jellyfin, arr, musique et lecture
|   |-- monitoring/         # Prometheus, Grafana, Loki, ntfy, Uptime Kuma
|   |-- osint/              # SpiderFoot et Maigret
|   |-- scanner/            # Greenbone/OpenVAS
|   `-- security/           # Wazuh
|-- renovate.json
`-- README.md
```

`prompting/`, les données persistantes et certains composants déployés hors Git
ne figurent volontairement pas dans cette vue publique.

## État et limites connues

### Opérationnel

- cluster Proxmox trois nœuds et segmentation VLAN ;
- services personnels/familiaux derrière Traefik ;
- SSO Authentik sur les applications compatibles ;
- monitoring, alerting et tâches de maintenance ;
- Wazuh, Security Onion, Greenbone, TheHive/Cortex et OSINT ;
- chaîne Packer/OpenTofu/Ansible fonctionnelle sur son périmètre actuel.

### Priorités

1. sortir les disques système des VMs du NFS TrueNAS sur pont USB ;
2. tester régulièrement les restaurations et externaliser les clés de sauvegarde ;
3. ajouter une CI de validation des Compose, playbooks, IaC et règles Sigma ;
4. généraliser OpenTofu aux VMs de production ;
5. microsegmenter davantage le VLAN Production ;
6. terminer le forwarding Wazuh vers TheHive ;
7. déployer Cloudflare Tunnel uniquement après validation de la posture edge ;
8. finaliser le portfolio et le pipeline CV-as-Code.

### Limites assumées

- stockage TrueNAS provisoire, sans redondance matérielle suffisante ;
- switch limité à 1 Gbit/s tant que le module 10G n'est pas installé ;
- OPNsense, Cisco, Security Onion et une partie de Cloudflare ne sont pas encore
  entièrement reproductibles depuis ce dépôt ;
- les configurations publiques évitent les secrets, mais exposent nécessairement
  une partie de la conception technique du portfolio.

## Documentation

- [Documentation homelab](docs/homelab.md)
- [Runbook VM gelée par dépendance NFS](docs/runbooks/vm-gelee-nfs-nas.md)
- [Runbook diagnostic SSH](docs/runbooks/ban-ssh-depuis-control-node.md)
- [Autoriser le control node sur Security Onion](docs/runbooks/security-onion-ssh-control-node.md)
- [Procédure TrueNAS / Proxmox](infrastructure/nas/truenas-proxmox/TRUENAS-PROXMOX.md)

---

Homelab personnel documenté à des fins d'apprentissage et de portfolio. Les
adresses privées éventuellement présentes dans l'historique ne sont pas
routables depuis Internet, mais ne doivent pas être considérées comme un secret.
