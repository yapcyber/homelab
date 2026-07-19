---
sidebar_position: 2
title: Navidrome
---

# Navidrome

Navidrome donne accès à votre bibliothèque musicale, depuis un navigateur ou une
application compatible Subsonic.

## À quoi ça sert

- Écouter la musique de la médiathèque en streaming.
- Créer des playlists et marquer des favoris, rattachés à votre compte.

## Comment l'utiliser

1. Activez WireGuard.
2. Dans un navigateur, ouvrez `https://music.yapserver.fr` : la connexion se fait
   via votre compte unique YapServer.
3. Sur mobile, installez une application compatible **Subsonic** (Symfonium,
   play:Sub, DSub…), renseignez `https://music.yapserver.fr` et l'**identifiant
   Navidrome dédié** fourni par l'administrateur.

## Interactions

- **Connexion unique (Authentik)** sur le web ; les applications Subsonic
  utilisent un identifiant Navidrome distinct (elles ne gèrent pas le SSO).
- **WireGuard** : écoute possible uniquement via le VPN.

## Limites

- Une piste absente ou mal identifiée doit être signalée avec l'artiste, l'album
  et le titre attendus.
- Les playlists et favoris appartiennent au compte : ils ne sont pas partagés
  entre utilisateurs.
