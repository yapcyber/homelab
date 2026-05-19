---
slug: phase-0-planning-my-homelab
title: "Phase 0 — Planning a Production-Grade Homelab"
authors:
  - name: yapcyber
    title: Cloud/DevOps & Cybersecurity Engineer
    url: https://github.com/yapcyber
    image_url: https://github.com/yapcyber.png
tags: [homelab, architecture, planning, networking, proxmox, opnsense]
date: 2026-05-19
description: "Every solid infrastructure starts with a solid plan. Here's how I designed the architecture of my homelab before touching a single piece of hardware."
image: /img/phase-0-architecture.png
---

Before writing a single line of configuration, I spent two weeks designing the architecture of this homelab. This post documents every decision made during that planning phase — the hardware choices, the network segmentation strategy, and the security principles that will guide the entire project.

<!-- truncate -->

## Why a homelab in 2026?

Three reasons: learn by doing, have full control over my data, and build a documented project that reflects real production infrastructure.

The goal is not to host a simple Nextcloud on a Raspberry Pi. The goal is to build something that looks like what you'd find in a mid-size company's infrastructure — with proper VLAN segmentation, a SIEM, a PKI, SSO, and documented architecture decisions.

## Hardware inventory

The backbone of this homelab runs at **10 Gbps** between the firewall, the switch, and the gaming PC. The rest of the infrastructure connects at standard 1 Gbps.

| Component | Machine | Role |
|-----------|---------|------|
| Firewall | Gaming PC (repurposed) + Mellanox SFP+ | OPNsense — WAN 10G + LAN 10G |
| Switch | Cisco WS-C3560X + C3KX-NM-10G module | L3, 10 VLANs, SPAN port |
| Node 1 | Mini PC 1 — 32 GB RAM | Proxmox VE |
| Node 2 | Mini PC 2 — 16 GB RAM | Proxmox VE |
| Node 3 | Mini PC 3 — 32 GB RAM | Proxmox VE |
| SOC | Mini PC 4 — SPAN port | Security Onion |
| Gaming | Dedicated PC + Mellanox SFP+ | Sunshine cloud gaming |

## Network segmentation: 10 VLANs

The most critical decision in this phase was the VLAN plan. Every VLAN represents a security boundary — traffic between VLANs goes through OPNsense and is subject to explicit firewall rules.

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | Management | 10.0.10.0/24 | Proxmox, switch, OPNsense |
| 20 | Corosync | 10.0.20.0/24 | Proxmox HA heartbeat (isolated) |
| 30 | Production | 10.0.30.0/24 | Application VMs |
| 40 | DMZ | 10.0.40.0/24 | Traefik, Cloudflare Tunnel |
| 50 | SOC | 10.0.50.0/24 | Security Onion, Wazuh, OpenVAS |
| 60 | Storage | 10.0.60.0/24 | NAS, Proxmox Backup Server |
| 70 | IoT | 10.0.70.0/24 | Home Assistant, smart devices |
| 80 | Guest | 10.0.80.0/24 | Guest Wi-Fi (isolated) |
| 90 | Gaming | 10.0.90.0/24 | Sunshine game streaming |
| 100 | Admin | 10.0.100.0/24 | Jump Host (Mini PC 5) |

**A note on Corosync isolation**: The Proxmox cluster heartbeat runs on VLAN 20. Any network congestion on a shared VLAN could delay heartbeats and trigger false "node down" alerts — causing unnecessary VM migrations or, worse, split-brain scenarios. Dedicated VLAN = dedicated bandwidth = reliable HA.

## Architecture decisions (ADR log)

I documented every significant decision as an Architecture Decision Record (ADR):

- **ADR-001**: Full DMZ instead of double-NAT → OPNsense receives the public IP directly
- **ADR-004**: Authentik instead of Kerberos/AD → OIDC/SAML/LDAP, much simpler for a homelab
- **ADR-005**: OpenVAS instead of Nessus → ~33 IPs to scan, beyond the 16-IP Nessus free limit
- **ADR-007**: Docusaurus for the portfolio → native i18n FR/EN, blog + docs in one

## What's next

**Phase 1** covers the complete software preparation: all `docker-compose.yml` files, `.env` templates, and configuration files prepared locally before touching any hardware.

The entire codebase is available on [GitHub](https://github.com/yapcyber/homelab).

---

*Follow this series on [LinkedIn](https://linkedin.com/in/VOTRE_PROFIL) for weekly updates.*
