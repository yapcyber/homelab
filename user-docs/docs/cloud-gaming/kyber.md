---
sidebar_position: 1
title: Kyber (cloud gaming)
---

# Kyber

Kyber diffuse en direct l'écran et le son du PC de jeu vers votre navigateur, pour
jouer à distance avec une manette.

## À quoi ça sert

- Jouer aux jeux du PC YapServer depuis un autre appareil, via le streaming.
- Utiliser une manette à travers le flux, avec une latence très faible.

## Comment l'utiliser

1. Activez WireGuard.
2. Ouvrez **Google Chrome ou Chromium** (obligatoire) à l'adresse
   `https://kyber.yapserver.fr/webclient/` — le chemin `/webclient/` est
   nécessaire.
3. Connectez-vous, branchez une manette si besoin, puis lancez le flux.

## Interactions

- **Service à part** : Kyber ne passe pas par le reverse proxy des autres pages ;
  il est joignable directement en VPN.
- **WireGuard** requis.

## Limites

- **Chrome / Chromium uniquement** : Firefox et Safari ne sont pas compatibles ;
  Edge fonctionne (hors HEVC).
- Un **avertissement de certificat** s'affiche actuellement : c'est **connu et
  temporaire**, le certificat définitif étant en cours de mise en place. En cas de
  doute, vérifiez auprès de l'administrateur.
- Le PC de jeu doit être allumé et le service actif ; signalez toute
  indisponibilité à l'administrateur.
- Pas de client TV ni d'appareil sans WireGuard pour l'instant.
