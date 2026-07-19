---
sidebar_position: 1
title: Nextcloud
---

# Nextcloud

Nextcloud est votre espace de fichiers privé : documents, agenda, contacts et
discussions, synchronisés entre vos appareils.

## À quoi ça sert

- Stocker et synchroniser vos fichiers et dossiers.
- Partager des fichiers avec d'autres membres autorisés.
- Gérer agenda et contacts, et discuter via Nextcloud Talk.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://cloud.yapserver.fr` et choisissez
   **Se connecter avec Authentik**.
2. Installez les applications **Nextcloud** (bureau et mobile) et pointez-les vers
   `https://cloud.yapserver.fr`.
3. Pour les appels et messages, utilisez l'onglet **Talk** dans Nextcloud ou
   l'application **Nextcloud Talk** mobile.

## Interactions

- **Connexion unique (Authentik)** pour le web et les applications.
- **Distinct d'Immich** : les fichiers vont dans Nextcloud, les photos du
  téléphone dans Immich.
- **WireGuard** requis pour la synchronisation.

## Limites

- La synchronisation ne progresse que VPN actif ; elle reprend au retour.
- Évitez de synchroniser d'énormes dossiers sur une connexion lente.
- Videz régulièrement la corbeille : les fichiers supprimés comptent dans votre
  espace tant qu'ils y restent.
