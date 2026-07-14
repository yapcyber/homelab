---
id: homelab
title: "The homelab — yapserver.fr"
sidebar_label: Homelab
sidebar_position: 2
description: Architecture and design decisions of a detection and infrastructure homelab.
---

# yapserver.fr — a detection and infrastructure homelab

**yapserver.fr** is a self-hosted infrastructure I design and operate at home,
with a dual purpose: hosting everyday services for my family (cloud, photos,
media, passwords) and serving as a hands-on learning ground in cybersecurity —
focused on detection, incident response, and infrastructure-as-code.

Everything runs on a small cluster of machines, on a network segmented into VLANs
behind a self-managed firewall, with no port open to the Internet: remote access
goes through a VPN, and public exposure is handled by exception, service by
service. The detection layer (SIEM, network sensor, vulnerability scanning,
incident response) was put in place **before** any exposure to the outside — a
principle I hold to: secure before exposing.

The whole setup is versioned and reproducible: the virtual machines and their
configuration are described as infrastructure-as-code, and every architectural
decision is documented. This site presents the approach; the code and
configurations are public on [GitHub](https://github.com/yapcyber/homelab).

<!-- ========================================================================= -->
<!-- NEXT SECTIONS — to be written step by step (see plan)                     -->
<!-- ========================================================================= -->

## Architecture

<!-- TODO: network diagram (Internet -> OPNsense -> VLANs -> Proxmox cluster
     -> services). To be produced cleanly, then embedded here as an image or a
     diagram (Mermaid is supported in Docusaurus). -->

*(Architecture diagram coming soon.)*

## Architectural decisions

<!-- TODO: 4-5 decisions explained with their WHY. Skeleton: -->

- **VLAN segmentation** — isolation and least privilege across domains (management, production, SOC, storage, guest…).
- **Security before exposure** — the detection layer is operational before any external access.
- **VPN-only + exposure by exception** — no open ports; remote access via WireGuard, hardened public exposure case by case.
- **Infrastructure-as-code** — golden template (Packer) → provisioning (OpenTofu) → configuration and patching (Ansible): fully reproducible.
- **Centralized identity (SSO)** — Authentik, using forward-auth or native OIDC depending on the service.

*(Each decision will be expanded into a short paragraph.)*

## Tech stack

<!-- TODO: readable table/groups (detection, infra, IR, services). Full detail
     lives on GitHub, not here. -->

*(Stack overview coming soon.)*

## Going further

The concrete problems encountered and solved on this infrastructure are detailed
in the [write-ups](/docs/writeups).
