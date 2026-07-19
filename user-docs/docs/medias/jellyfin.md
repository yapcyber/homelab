---
sidebar_position: 1
title: Jellyfin
---

# Jellyfin

Jellyfin permet de regarder les films et séries de la médiathèque YapServer,
depuis un navigateur ou une application.

## À quoi ça sert

- Lire les films et séries disponibles sur le serveur.
- Reprendre une lecture là où vous l'avez laissée, sur n'importe quel appareil.
- Gérer des profils et des listes personnels.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://jellyfin.yapserver.fr`.
2. Connectez-vous avec le compte transmis par l'administrateur.
3. Sur TV ou mobile, installez l'application **Jellyfin** officielle et indiquez
   la même adresse ; sur TV, **Quick Connect** évite de saisir le mot de passe.
4. Laissez la qualité sur **automatique** à la première lecture.

## Interactions

- **Seerr** : pour demander un film ou une série absente, passez par Seerr — ne
  cherchez pas à l'ajouter vous-même dans Jellyfin.
- **Compte dédié** : Jellyfin n'utilise pas la connexion unique ; son compte est
  distinct (y compris pour Quick Connect sur TV).
- **WireGuard** : lecture possible uniquement via le VPN.

## Limites

- Les sous-titres incrustés et certaines conversions sollicitent le serveur :
  n'activez les sous-titres que si nécessaire.
- Ne partagez pas votre compte ; demandez un compte séparé pour chaque personne.
- En cas de lecture saccadée, réduisez la qualité, testez un autre client, puis
  notez le titre et l'heure avant de demander de l'aide.
