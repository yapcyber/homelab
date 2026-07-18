---
sidebar_position: 5
title: Sécurité réseau
---

# Sécurité réseau

La sécurité réseau contrôle et observe les communications entre zones de
confiance. Elle ne consiste pas seulement à « fermer des ports ».

## Champs d'application

- Segmentation, filtrage stateful, VPN, DNS, proxy et accès distant.
- IDS/IPS, analyse de flux, capture de paquets et détection est-ouest.
- Durcissement des équipements, administration séparée et haute disponibilité.
- Diagnostic entre couches : routage, transport, application et stockage.

## Méthode

Partir des flux métier autorisés, appliquer le refus par défaut, journaliser les
écarts puis tester depuis chaque zone. Une règle de pare-feu n'est une preuve que
si le paquet emprunte réellement la chaîne attendue.

## Mise en pratique homelab

VLAN, OPNsense, WireGuard, Security Onion et les règles `DOCKER-USER` permettent
d'étudier conjointement prévention, visibilité et validation des chemins.
