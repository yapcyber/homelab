<div align="center">

# 🏠 YapServer Homelab

> Infrastructure homelab auto-hébergée : cloud personnel, médias, et un **Security Operations Center** complet — conçue, durcie et documentée comme environnement d'apprentissage et portfolio orienté **SOC / Detection Engineering**.

**Auteur :** [yapcyber](https://github.com/yapcyber) · **Portfolio :** [yapserver.fr](https://yapserver.fr)

---

## 🎯 Objectif

Un homelab à trois usages :

- **Personnel / familial** — gestionnaire de mots de passe, cloud, photos, médias pour les proches.
- **Sécurité / portfolio** — un véritable SOC maison (détection réseau + hôte, scan de vulnérabilités, detection-as-code) servant de démonstration de compétences en infrastructure, réseau, sécurité et DevOps.
- **Accès distant** — partout via WireGuard, exposition publique « par exception » via Cloudflare Tunnel.

Tout est versionné dans ce dépôt et documenté sur le portfolio Docusaurus.

---

## 🗺️ Architecture

```
Internet
  │  (double-NAT temporaire → WireGuard / Cloudflare Tunnel)
OPNsense (bare metal)  — pare-feu, VLANs, DHCP/DNS, WireGuard, DDNS
  │
Cisco 3560X  — switching L2/L3, SPAN → Security Onion
  │
┌───────────────────────────────────────────────┐
│ Cluster Proxmox « yapserver » (3 nœuds, HA)     │
│  pve1 / pve2 / pve3                             │
│                                                 │
│  VM 200  TrueNAS SCALE  (stockage ZFS, NFS)     │
│  VM 101  infra          (Traefik, Authentik…)   │
│  VM 102  monitoring     (Prometheus, Grafana…)  │
│  VM 103  cloud          (Nextcloud, Immich…)    │
│  VM 104  media          (Jellyfin, *arr…)       │
│  VM 105  security       (Wazuh — SIEM/HIDS)     │
│  VM 106  scanner        (OpenVAS / Greenbone)   │
│  VM 107  firefly        (Firefly III)           │
│  VM 108  osint          (SpiderFoot)            │
└───────────────────────────────────────────────┘
  │
Security Onion (bare metal)  — NIDS/NSM (Suricata + Zeek + Elastic) via SPAN
```

Reverse proxy unique : **Traefik**. Tous les services internes sont accessibles en `*.yapserver.fr` (DNS interne Unbound en split-DNS) derrière des certificats Let's Encrypt wildcard (DNS-challenge Cloudflare).

---

## 🔌 Réseau (VLANs)

| VLAN | Rôle | Subnet |
|---|---|---|
| 10 | Management | 10.0.10.0/24 |
| 20 | Corosync | 10.0.20.0/24 |
| 30 | Production | 10.0.30.0/24 |
| 40 | DMZ | 10.0.40.0/24 |
| 50 | SOC | 10.0.50.0/24 |
| 60 | Storage | 10.0.60.0/24 |
| 70 | IoT | 10.0.70.0/24 |
| 80 | Guest | 10.0.80.0/24 |
| 90 | Gaming | 10.0.90.0/24 |
| 100 | Admin | 10.0.100.0/24 |
| 200 | WireGuard | 10.0.200.0/24 |

Segmentation appliquée au pare-feu (OPNsense) : Production/Storage resserrés (DNS/NTP/NFS + sortie Internet seulement, latéral RFC1918 **bloqué + loggé**).

---

## 🧰 Stack technique

**Infrastructure** — Proxmox VE (cluster 3 nœuds, HA), TrueNAS SCALE (ZFS, NFS), Debian 12 (VMs cloud-init), Docker + Docker Compose.

**Réseau & accès** — OPNsense (VLANs, Kea DHCP, Unbound split-DNS, WireGuard, DDNS Cloudflare), Cisco 3560X (SPAN), Traefik (reverse proxy unique) + CrowdSec, Authentik (SSO), Let's Encrypt wildcard.

**Services** — Nextcloud, Immich, Vaultwarden, Jellyfin + stack *arr, Firefly III, Homarr, NetBox.

**Observabilité** — Prometheus, Grafana, Loki/Promtail, cAdvisor, Node Exporter, Jellystat.

**Sécurité** — Security Onion (NIDS/NSM), Wazuh (SIEM/HIDS), OpenVAS/Greenbone (scan de vulnérabilités), SpiderFoot (OSINT), règles **Sigma** (detection-as-code).

---

## 📦 Services par VM (VLAN 30)

| VM | IP | Services |
|---|---|---|
| infra | 10.0.30.10 | Traefik + CrowdSec, Authentik, Homarr, cloudflared |
| monitoring | 10.0.30.11 | Prometheus, Grafana, Loki, cAdvisor, **NetBox** |
| cloud | 10.0.30.12 | Vaultwarden, Nextcloud, Immich |
| media | 10.0.30.13 | Jellyfin, Radarr/Sonarr/Prowlarr, qBittorrent, **Jellystat** |
| security | 10.0.30.14 | **Wazuh** (manager + indexer + dashboard) |
| scanner | 10.0.30.15 | **OpenVAS / Greenbone Community** |
| firefly | 10.0.30.16 | **Firefly III** + Data Importer |
| osint | 10.0.30.17 | **SpiderFoot** |
| TrueNAS | 10.0.60.10 | NAS (pools `tank` + `media`) |

---

## 🛡️ Sécurité & Detection Engineering

Le cœur « portfolio » du projet : un cycle de détection complet, couvrant le **réseau** et l'**hôte**, mappé sur **MITRE ATT&CK**, et géré en **detection-as-code**.

### Détection réseau — Security Onion (NSM)
- **Suricata** (NIDS) + **Zeek** (métadonnées) alimentés par le **SPAN** du Cisco 3560X.
- Règles NIDS personnalisées (déclenchement/validation : marqueur ICMP custom, scan `nmap` → **T1046**).
- **Règles Sigma** déployées via **ElastAlert 2** (signature vs comportement), versionnées dans [`detections/sigma/`](detections/sigma/).

### Détection hôte — Wazuh (SIEM / HIDS)
- Agents sur l'ensemble des VMs et des nœuds Proxmox.
- **FIM** (whodata sur `/etc`, `.ssh`), **SCA** (durcissement CIS), **rootcheck**, intégration **VirusTotal**.
- **Règles de corrélation personnalisées** (escalade contextuelle d'un brute-force SSH selon le VLAN source — **T1110**) — voir [`services/security/wazuh/local_rules.xml`](services/security/wazuh/local_rules.xml).
- **Tuning du bruit** documenté : downgrade ciblé des faux positifs (promiscuous mode Docker, VirusTotal « no records », sessions PAM, rootcheck génériques) — ~68 % d'alertes en moins, sans perte de signal.

### Defense in depth — l'angle mort est-ouest
Démonstration A/B clé : le trafic **intra-nœud** (VMs co-localisées sur le même hyperviseur) ne traverse jamais le switch physique → **invisible au SPAN**. La couche **agent (Wazuh)** couvre cet angle mort → illustration concrète de la défense en profondeur.

### Scan de vulnérabilités
- **OpenVAS / Greenbone Community** (VM dédiée) — scans planifiés, triage basé sur le risque réel (≠ CVSS brut).

---

## 🗂️ Structure du dépôt

```
homelab/
├── README.md
├── .gitignore                 # secrets/volumes jamais versionnés
├── infrastructure/            # docs & procédures (TrueNAS↔Proxmox, …)
├── services/
│   ├── infra/                 # traefik (+ dynamic/), authentik, homarr, cloudflared
│   ├── monitoring/            # prometheus, grafana, loki, … + netbox/
│   ├── cloud/                 # vaultwarden, nextcloud, immich
│   ├── media/                 # jellyfin, *arr, qbittorrent + jellystat/
│   ├── security/wazuh/        # local_rules.xml + agent.conf (travail de détection)
│   ├── scanner/openvas/       # greenbone community containers
│   ├── firefly/               # firefly III + data-importer
│   └── osint/                 # spiderfoot
├── detections/
│   └── sigma/                 # règles Sigma (detection-as-code)
└── portfolio/                 # site Docusaurus (yapserver.fr)
```

---

## 🔐 Modèle d'accès & posture de sécurité

- **Public par exception** (Cloudflare Tunnel) : seuls Jellyfin, Nextcloud, Immich sont exposés, avec leur auth native (mots de passe forts + 2FA). Tout le reste est **VPN-only** (`internal-only` côté Traefik).
- **WireGuard** pour l'accès distant ; **CrowdSec** en bouncer côté edge ; **Authentik** pour le SSO.
- **SSH par clé uniquement** (aucun mot de passe).
- **Aucun secret versionné** : `.env`, clés, PEM et certificats sont exclus par `.gitignore` ; les configurations publiées utilisent des placeholders (ex. `${CROWDSEC_BOUNCER_API_KEY}`).

---

## 🚦 État

✅ Cluster Proxmox + HA · Réseau segmenté · TrueNAS/NFS · Reverse proxy + SSO · Cloud/médias · Monitoring · **SOC (Security Onion + Wazuh + agents)** · **Scan de vulnérabilités** · **Detection-as-code (Sigma)** · OSINT · Finances perso.

🔜 Cloudflare Tunnel · IA locale (Ollama) · pipeline CV · MISP / TheHive / Velociraptor · mail interne (post-migration FAI).

---

*Homelab personnel — documenté à des fins d'apprentissage et de portfolio. Les adresses internes (RFC1918) ne sont pas routables depuis Internet.*
