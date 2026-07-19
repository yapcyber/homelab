---
sidebar_position: 2
title: Immich
---

# Immich

Immich sauvegarde et regroupe vos photos et vidéos, comme une galerie cloud
privée hébergée sur YapServer.

## À quoi ça sert

- Sauvegarder automatiquement les photos et vidéos de votre téléphone.
- Retrouver vos souvenirs par date, lieu, personne ou objet.
- Organiser des albums et les partager avec les autres membres autorisés.

## Comment l'utiliser

1. Activez WireGuard.
2. Dans un navigateur, ouvrez `https://photos.yapserver.fr` et choisissez
   **Se connecter avec Authentik** (votre compte unique YapServer).
3. Sur mobile, installez l'application **Immich** officielle, renseignez
   l'adresse `https://photos.yapserver.fr`, puis connectez-vous via le même compte.
4. Dans l'application, activez la **sauvegarde automatique** et sélectionnez les
   albums à protéger.

## Interactions

- **Connexion unique (Authentik)** : Immich utilise votre compte YapServer ; la
  double authentification s'applique.
- **Distinct de Nextcloud** : les photos vont dans Immich, les autres fichiers
  dans Nextcloud — les deux ne se synchronisent pas entre eux.
- **WireGuard** : la sauvegarde comme la consultation nécessitent le VPN actif.

## Limites

- Aucun accès sans WireGuard : la sauvegarde se met en pause hors VPN et reprend
  au retour.
- La sauvegarde automatique exige que l'application garde l'autorisation de
  tourner en arrière-plan.
- L'indexation (visages, objets) s'exécute côté serveur et peut prendre du temps
  après un gros import.
- Ne supprimez une photo depuis l'application qu'après avoir vérifié qu'elle est
  bien sauvegardée.
