---
sidebar_position: 1
title: Se connecter au VPN (WireGuard)
---

# Se connecter au VPN (WireGuard)

Tous les services YapServer sont privés : ils ne répondent qu'une fois le tunnel
WireGuard actif.

## À quoi ça sert

- Ouvrir un tunnel chiffré entre votre appareil et le homelab.
- Rendre joignables les adresses `*.yapserver.fr` depuis l'extérieur comme à la
  maison.

## Comment l'utiliser

1. Installez l'application **WireGuard** officielle (Windows, macOS, Linux, iOS,
   Android).
2. Importez la configuration fournie par l'administrateur (fichier ou QR code).
   Ne la partagez jamais.
3. Activez le tunnel. Une fois le **handshake** récent affiché, ouvrez l'adresse
   du service voulu.
4. Désactivez le tunnel quand vous n'en avez plus besoin.

## Interactions

- **Prérequis de tout le reste** : Jellyfin, Immich, Nextcloud… ne répondent pas
  sans VPN actif.
- **Connexion unique (Authentik)** : une fois le VPN actif, la plupart des
  services partagent le même compte.

## Limites

- Une configuration par appareil ; demandez un profil séparé pour chaque
  appareil plutôt que de dupliquer le vôtre.
- Si un service ne répond pas, vérifiez d'abord la date du dernier handshake
  WireGuard.
- La clé WireGuard ne se communique jamais dans une demande d'assistance.
