---
sidebar_position: 3
title: Grafana
---

# Grafana

Grafana présente les métriques du homelab. Son accès est destiné aux personnes
autorisées à observer l'état technique de la plateforme.

## Utilisation

Activez WireGuard puis ouvrez `https://grafana.yapserver.fr`. Les tableaux de
bord sont principalement en lecture seule. Choisissez une période cohérente
avant de conclure à une anomalie et vérifiez le fuseau horaire affiché.

Une absence de données n'implique pas nécessairement une panne du service
observé : la collecte ou la source de métriques peut elle-même être indisponible.
