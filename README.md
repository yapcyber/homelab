# 🏠 Homelab `yapserver.fr`

> Infrastructure personnelle documentée — Architecture Cloud/DevOps & Cybersécurité

[![Phase](https://img.shields.io/badge/Phase-1%20—%20Préparation-blue)]()
[![Stack](https://img.shields.io/badge/Stack-Proxmox%20%7C%20Docker%20%7C%20OPNsense-orange)]()

## 🗺️ Architecture matérielle

| Composant | Machine | Rôle |
|-----------|---------|------|
| **Firewall** | PC Parefeu — Mellanox 10G SFP+ PCIe | OPNsense — WAN 10G + LAN 10G |
| **Switch** | Cisco WS-C3560X + C3KX-NM-10G | L3, 10 VLANs, SPAN, 2× SFP+ 10G |
| **Nœud 1** | Mini PC 1 — 32 Go RAM | Proxmox VE |
| **Nœud 2** | Mini PC 2 — 16 Go RAM | Proxmox VE |
| **Nœud 3** | Mini PC 3 — 32 Go RAM | Proxmox VE + NIC M.2 2.5G |
| **SOC** | Mini PC 4 — port SPAN | Security Onion |
| **Gaming** | PC Gamer — Mellanox 10G SFP+ PCIe | Sunshine / Cloud Gaming |
| **Jump Host** | Mini PC 5 — 32 Go RAM | Ubuntu 24.04 LTS — Administration |

## 🌐 Plan réseau — 10 VLANs sur `10.0.0.0/8`

| VLAN | Nom | Subnet Prod | Usage |
|------|-----|-------------|-------|
| 10 | Management | 10.0.10.0/24 | Proxmox, switch, OPNsense |
| 20 | Corosync | 10.0.20.0/24 | Heartbeat cluster HA |
| 30 | Production | 10.0.30.0/24 | VMs services Docker |
| 40 | DMZ | 10.0.40.0/24 | Traefik, Cloudflare Tunnel |
| 50 | SOC | 10.0.50.0/24 | Security Onion, Wazuh, OpenVAS |
| 60 | Storage | 10.0.60.0/24 | NAS, Proxmox Backup Server |
| 70 | IoT | 10.0.70.0/24 | Home Assistant |
| 80 | Guest | 10.0.80.0/24 | Wi-Fi invités (isolé) |
| 90 | Gaming | 10.0.90.0/24 | PC gaming, Sunshine/Moonlight |
| 100 | Admin | 10.0.100.0/24 | Jump Host |

## 🚀 Stack de services

- **Reverse Proxy** : Traefik v3 + CrowdSec (WAF)
- **SSO** : Authentik (OIDC / SAML / LDAP)
- **PKI** : Step-CA (certificats TLS internes)
- **Médias** : Jellyfin, Radarr, Sonarr, Prowlarr
- **Cloud** : Nextcloud, Immich
- **Admin** : Homarr, Netbox
- **SOC** : Wazuh, Security Onion, OpenVAS
- **VPN** : WireGuard (OPNsense plugin)

## 📚 Journal de bord & Portfolio

- 🌐 Site : [yapserver.fr](https://yapserver.fr)
- 💼 LinkedIn : Posts hebdomadaires (phases, problèmes, solutions, évolutions)
- 💻 GitHub : [github.com/yapcyber](https://github.com/yapcyber)

## 🔐 Gestion des secrets

Tous les secrets sont chiffrés avec **SOPS + Age** avant d'être committés.

```bash
# Chiffrer un .env
sops --encrypt services/media/.env > services/media/.enc.env

# Déchiffrer
sops --decrypt services/media/.enc.env > services/media/.env
```

> ⚠️ Ne jamais committer un `.env` en clair. Seuls les `.env.example` et `.enc.env` vont sur Git.

## 📁 Structure du projet

```
homelab/
├── docs/              # Documentation, schémas, runbooks
├── infrastructure/    # Config réseau (OPNsense, Cisco), Proxmox, Ansible
├── services/          # docker-compose par service (media, cloud, infra, security)
├── portfolio/         # Site Docusaurus FR/EN (journal de bord)
└── secrets/           # Gitignored — données sensibles locales uniquement
```

---
*Phase actuelle : **1 — Préparation logicielle** | Prochaine : 1.5 — Portfolio & GitHub*
