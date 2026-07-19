---
sidebar_position: 7
title: Home Assistant
---

# Home Assistant

Home Assistant pilote la domotique de la maison : lumières, capteurs, scènes et
automatisations.

## À quoi ça sert

- Contrôler les appareils connectés de la maison.
- Créer des scènes et des automatisations.
- Suivre l'état des capteurs.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://ha.yapserver.fr`.
2. Connectez-vous avec votre **compte Home Assistant** (identifiant dédié).
3. Sur mobile, installez l'application **Home Assistant** officielle et pointez-la
   vers `https://ha.yapserver.fr`.

## Interactions

- **Compte dédié** : Home Assistant garde son propre identifiant (hors connexion
  unique) pour rester compatible avec l'application et les jetons d'accès.
- **WireGuard** requis à distance ; à la maison, l'accès local reste possible.

## Limites

- Certaines automatisations et certains appareils ne fonctionnent qu'au sein du
  réseau local.
- Les notifications et le contrôle à distance nécessitent le VPN actif sur
  l'appareil.
