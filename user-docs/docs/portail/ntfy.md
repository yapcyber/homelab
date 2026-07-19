---
sidebar_position: 3
title: ntfy (notifications)
---

# ntfy

ntfy diffuse les notifications du homelab (alertes techniques, rappels) vers vos
appareils.

## À quoi ça sert

- Recevoir des notifications push depuis YapServer.
- S'abonner à un canal (topic) pour être tenu informé.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://ntfy.yapserver.fr`.
2. Sur mobile, installez l'application **ntfy** officielle et réglez le serveur sur
   `https://ntfy.yapserver.fr`.
3. Abonnez-vous au canal indiqué par l'administrateur.

## Interactions

- **Canal d'alerte central** utilisé par les tâches de supervision du homelab.
- **WireGuard** requis pour recevoir et consulter les notifications.

## Limites

- Les canaux sont ouverts en interne : n'y publiez rien de confidentiel.
- La réception dépend du VPN actif ; les notifications n'arrivent pas hors tunnel.
