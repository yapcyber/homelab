---
sidebar_position: 4
title: Dawarich
---

# Dawarich

Dawarich enregistre l'historique de vos déplacements et l'affiche sur une carte,
comme un journal de localisation privé.

## À quoi ça sert

- Conserver l'historique de vos positions sur une carte.
- Visualiser trajets, statistiques et lieux visités.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://dawarich.yapserver.fr` et connectez-vous
   avec **Authentik**.
2. Sur mobile, installez une application de suivi compatible (par ex. **Overland**
   ou **GPSLogger**) et configurez-la pour envoyer vos positions à
   `https://dawarich.yapserver.fr` avec la clé indiquée dans votre compte.

## Interactions

- **Connexion unique (Authentik)** pour l'interface web.
- **Application mobile de suivi** : c'est elle qui alimente Dawarich en positions.
- **WireGuard** requis pour l'envoi et la consultation.

## Limites

- Sans VPN actif, l'application mobile met les positions en file et les envoie au
  retour.
- Le suivi en continu consomme de la batterie : réglez la fréquence selon vos
  besoins.
- Données de localisation sensibles : ne partagez pas votre accès.
