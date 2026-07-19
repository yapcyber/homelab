---
sidebar_position: 4
title: Grafana
---

# Grafana

Grafana présente les métriques techniques du homelab sous forme de tableaux de
bord.

## À quoi ça sert

- Observer l'état technique de la plateforme (charge, disponibilité, ressources).
- Consulter l'historique des mesures sur une période choisie.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://grafana.yapserver.fr` (connexion unique).
2. Ouvrez un tableau de bord et choisissez une période cohérente en haut à droite.
3. Vérifiez le fuseau horaire affiché avant d'interpréter une courbe.

## Interactions

- **Réservé aux personnes autorisées** à observer l'état technique.
- **Connexion unique (Authentik)** ; accès en lecture seule pour l'essentiel.
- **WireGuard** requis.

## Limites

- Une absence de données n'implique pas forcément une panne : la collecte ou la
  source de métriques peut elle-même être indisponible.
- Les tableaux de bord sont principalement en lecture seule ; ne modifiez rien
  sans y être invité.
