<div align="center">

# 🏠 YapServer Homelab

**Building a production-grade homelab — fully documented, every step of the way**

[![Phase](https://img.shields.io/badge/Phase-1.5_Portfolio_%26_GitHub-2ea44f?style=for-the-badge)](https://yapserver.fr)
[![Site](https://img.shields.io/badge/Portfolio-yapserver.fr-00d4aa?style=for-the-badge&logo=docusaurus&logoColor=white)](https://yapserver.fr)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Follow_the_journey-0A66C2?style=for-the-badge&logo=linkedin)](https://linkedin.com/in/VOTRE_PROFIL)

**[📖 Portfolio](https://yapserver.fr) · [📰 Journal de bord](https://yapserver.fr/blog) · [💼 LinkedIn](https://linkedin.com/in/VOTRE_PROFIL)**

</div>

---

## 🎯 What is this?

This repository documents the complete construction of a **production-grade homelab** — from architecture planning to full deployment. Every configuration file, every architectural decision, every problem and solution is tracked here and published on [yapserver.fr](https://yapserver.fr).

This is not a "spin up a Raspberry Pi" tutorial. It's an infrastructure project designed with the same patterns used in enterprise environments:

- **10G SFP+ backbone** between the firewall, switch, and gaming PC
- **10-VLAN L3 segmentation** on a Cisco 3560X with OPNsense routing
- **3-node Proxmox HA cluster** with Corosync isolation on dedicated VLAN
- **Zero Trust exposure** via Cloudflare Tunnels (zero open inbound ports)
- **Full security stack**: SIEM (Wazuh), WAF (CrowdSec), IDS/IPS (OPNsense), NSM (Security Onion), vulnerability scanner (OpenVAS), internal PKI (Step-CA)
- **SSO across all services** via Authentik (OIDC, SAML, LDAP)

---

## 🖥️ Hardware

| Component | Machine | Specs | Role |
|-----------|---------|-------|------|
| **Firewall** | PC Parefeu | Mellanox ConnectX SFP+ 10G dual-port | OPNsense — WAN 10G + LAN 10G |
| **Switch** | Cisco WS-C3560X-24P-S | + C3KX-NM-10G (2× SFP+ 10G) | L3, 10 VLANs, SPAN, inter-VLAN routing |
| **Node 1** | Mini PC 1 |  | Proxmox VE |
| **Node 2** | Mini PC 2 |  | Proxmox VE |
| **Node 3** | Mini PC 3 |  | Proxmox VE |
| **SOC** | Mini PC 4 | 1G admin + 1G SPAN | Security Onion (bare metal) |
| **Gaming** | Gaming PC | Mellanox SFP+ 10G | Sunshine cloud gaming |
| **Jump Host** | Laptop |  | Ubuntu 24.04 LTS — Admin |

---

## 🌐 Network — 10 VLANs on `10.0.0.0/8`

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | Management | `10.0.10.0/24` | Proxmox nodes, switch, OPNsense |
| 20 | Corosync | `10.0.20.0/24` | Proxmox HA heartbeat *(isolated)* |
| 30 | Production | `10.0.30.0/24` | Application VMs (Docker services) |
| 40 | DMZ | `10.0.40.0/24` | Traefik, Cloudflare Tunnel |
| 50 | SOC | `10.0.50.0/24` | Security Onion, Wazuh, OpenVAS |
| 60 | Storage | `10.0.60.0/24` | NAS, Proxmox Backup Server |
| 70 | IoT | `10.0.70.0/24` | Home Assistant, smart devices |
| 80 | Guest | `10.0.80.0/24` | Guest Wi-Fi *(fully isolated)* |
| 90 | Gaming | `10.0.90.0/24` | Sunshine game streaming |
| 100 | Admin | `10.0.100.0/24` | Jump Host (Mini PC 5) |

---

## 🚀 Services Stack

<details>
<summary><strong>🔒 Infrastructure & Security</strong></summary>

| Service | Role | Network |
|---------|------|---------|
| **OPNsense** | Firewall, routing, WireGuard VPN, IDS/IPS | WAN/LAN |
| **Traefik v3** | Reverse proxy, TLS termination, service routing | VLAN 40 |
| **CrowdSec** | Collaborative WAF — blocks known malicious IPs | VLAN 40 |
| **Authentik** | SSO Identity Provider (OIDC, SAML, LDAP) | VLAN 30 |
| **Step-CA** | Internal PKI — TLS certificates for all internal services | VLAN 10 |
| **Wazuh** | SIEM — security events, FIM, vulnerability detection | VLAN 50 |
| **OpenVAS** | Vulnerability scanner (~33 IPs across all VLANs) | VLAN 50 |
| **Security Onion** | NSM — full packet capture, Suricata, PCAP | Bare metal |

</details>

<details>
<summary><strong>☁️ Personal Cloud & Media</strong></summary>

| Service | Role |
|---------|------|
| **Nextcloud** | Personal cloud storage — files, contacts, calendar |
| **Immich** | Photo management with AI face/object recognition |
| **Jellyfin** | Media server — movies, TV series, music |
| **Radarr / Sonarr / Prowlarr** | Automated media acquisition |
| **qBittorrent** | Download client (single-volume `/data` — hardlinks) |

</details>

<details>
<summary><strong>🛠️ Administration & Monitoring</strong></summary>

| Service | Role |
|---------|------|
| **Homarr** | Homelab dashboard — unified service overview |
| **Netbox** | IPAM & infrastructure documentation (source of truth) |
| **Proxmox Backup Server** | VM and container backups |
| **Home Assistant** | Home automation *(Phase 4 — Raspberry Pi, VLAN 70)* |

</details>

<details>
<summary><strong>🎮 Gaming & Remote Access</strong></summary>

| Service | Role |
|---------|------|
| **Sunshine** | Cloud gaming server (10G SFP+ — GPU hardware encoding) |
| **Moonlight** | Client-side only (iOS, Android, Windows, Apple TV) |
| **WireGuard** | VPN — remote access to all VLANs + DNS ad-blocking |

</details>

---

## 📋 Architecture Decisions (ADR Log)

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| ADR-001 | NAT Architecture | Full DMZ (ISP box in bridge mode) | Single NAT, OPNsense in full control |
| ADR-002 | Service Exposure | Cloudflare Tunnels only | Zero open inbound ports |
| ADR-003 | DNS Strategy | Split-Horizon (Unbound + Cloudflare) | Same `yapserver.fr` domain internally and externally |
| ADR-004 | Identity Provider | Authentik | OIDC/SAML/LDAP, simpler than Kerberos/AD |
| ADR-005 | Vulnerability Scanning | OpenVAS (Greenbone CE) | ~33 IPs — exceeds Nessus free limit (16) |
| ADR-006 | Jump Host OS | Ubuntu 24.04 LTS | LTS until 2029, maximum DevOps tooling compatibility |
| ADR-007 | Portfolio Framework | Docusaurus v3 | Native FR/EN i18n, blog + docs, Markdown-only |
| ADR-008 | Ad Blocking | OPNsense Unbound (blocklists) | No need for separate Pi-hole |
| ADR-009 | Secrets Management | SOPS + Age | Git-friendly encryption, no vault needed |
| ADR-010 | Native VLAN | VLAN 1 blackholed | Anti-VLAN hopping (Cisco best practice) |

---

## 🗺️ Project Phases

```
✅  Phase 0   — Architecture & Planning
✅  Phase 1   — Local Software Preparation (all docker-compose files)
🔄  Phase 1.5 — GitHub Setup & LinkedIn Launch          ← YOU ARE HERE
⬜  Phase 2   — Physical Network & OPNsense
⬜  Phase 3   — Proxmox Cluster (3-node HA)
⬜  Phase 4   — Services Deployment
⬜  Phase 5   — Security, SOC & Hardening
```

---

## 📁 Repository Structure

```
homelab/
├── docs/                    # Architecture docs, network diagrams, runbooks
├── infrastructure/
│   ├── network/             # OPNsense exports, Cisco IOS configs
│   ├── proxmox/             # Cloud-init templates, provisioning scripts
│   └── ansible/             # Automation playbooks (Phase 4+)
├── services/
│   ├── infra/               # traefik · authentik · homarr · netbox
│   ├── media/               # jellyfin · radarr · sonarr · prowlarr
│   ├── cloud/               # nextcloud · immich
│   ├── security/            # step-ca · wazuh · openvas
│   └── gaming/              # sunshine
└── portfolio/               # Docusaurus site (this site: yapserver.fr)
```

---

## 📚 Follow the Journey

Weekly posts on **[LinkedIn](https://linkedin.com/in/VOTRE_PROFIL)** covering:
- Phase completions with architecture decisions
- Problems encountered and how I solved them
- Technical deep-dives on specific components
- Before/after comparisons

Full technical documentation on **[yapserver.fr](https://yapserver.fr)**

---

<div align="center">

*Built from scratch — no cloud, no managed services, no shortcuts.*

**[⭐ Star this repo](https://github.com/yapcyber/homelab)** if you find it useful

</div>
