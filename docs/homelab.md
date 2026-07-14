---
id: homelab
title: "Le homelab — yapserver.fr"
sidebar_label: Homelab
sidebar_position: 2
description: Architecture et décisions d'un homelab de détection et d'infrastructure.
---

# yapserver.fr — un homelab de détection et d'infrastructure

**yapserver.fr** est une infrastructure auto-hébergée que je conçois et exploite
chez moi, avec un double objectif : héberger des services du quotidien pour mes
proches (cloud, photos, médias, mots de passe) et me servir de terrain
d'apprentissage en cybersécurité — orienté détection, réponse à incident et
infrastructure-as-code.

Tout tourne sur un petit cluster de machines, dans un réseau segmenté en VLANs
derrière un pare-feu maison, sans aucun port ouvert sur Internet : l'accès distant
passe par un VPN, et l'exposition publique se fait par exception, service par
service. La couche de détection (SIEM, sonde réseau, scan de vulnérabilités,
réponse à incident) a été mise en place **avant** toute ouverture vers l'extérieur
— un principe que je m'impose : sécuriser avant d'exposer.

L'ensemble est versionné et reproductible : les machines virtuelles et leur
configuration sont décrites en infrastructure-as-code, et chaque décision
d'architecture est documentée. Ce site en présente la démarche ; le code et les
configurations sont publics sur [GitHub](https://github.com/yapcyber/homelab).

<!-- ========================================================================= -->
<!-- SECTIONS SUIVANTES — à rédiger étape par étape (voir plan)                 -->
<!-- ========================================================================= -->

## Architecture

<!-- TODO : diagramme réseau (Internet -> OPNsense -> VLANs -> cluster Proxmox
     -> services). À produire proprement, puis insérer ici en image ou en
     diagramme (Mermaid possible dans Docusaurus). -->

*(Schéma d'architecture à venir.)*

## Décisions d'architecture

<!-- TODO : 4-5 décisions expliquées avec leur POURQUOI. Squelette : -->

- **Segmentation en VLANs** — isolation et moindre privilège entre domaines (management, production, SOC, stockage, invités…).
- **Sécurité avant exposition** — la couche détection est opérationnelle avant tout accès externe.
- **VPN-only + exposition par exception** — aucun port ouvert ; accès distant par WireGuard, exposition publique durcie au cas par cas.
- **Infrastructure-as-code** — template doré (Packer) → provisioning (OpenTofu) → configuration et patching (Ansible) : tout reproductible.
- **Identité centralisée (SSO)** — Authentik, avec forward-auth ou OIDC natif selon le service.

*(Chaque décision sera développée en un court paragraphe.)*

## Stack technique

<!-- TODO : tableau/groupes lisibles (détection, infra, IR, services). Le détail
     complet vit sur GitHub, pas ici. -->

*(Vue d'ensemble de la stack à venir.)*

## Aller plus loin

Les problèmes concrets rencontrés et résolus sur cette infrastructure sont
détaillés dans les [write-ups](/docs/writeups).
