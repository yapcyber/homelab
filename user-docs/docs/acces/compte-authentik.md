---
sidebar_position: 2
title: Compte & connexion unique
---

# Compte & connexion unique

La plupart des services YapServer partagent un compte unique géré par Authentik,
avec double authentification obligatoire.

## À quoi ça sert

- Se connecter à plusieurs services avec un seul identifiant.
- Protéger l'accès par un second facteur (code temporaire).

## Comment l'utiliser

1. L'inscription se fait **sur invitation** : suivez le lien transmis par
   l'administrateur.
2. Renseignez vos identifiants, puis configurez une application d'authentification
   (TOTP : Aegis, FreeOTP, Google Authenticator…). Conservez le code de secours.
3. Sur un service compatible, choisissez **Se connecter avec Authentik** puis
   validez avec le code temporaire.

## Interactions

- **Services en connexion unique** : Immich, Nextcloud, AudioBookShelf, Kavita,
  SplitPro, Dawarich, Wanderer, et l'accès web à Navidrome, Firefly, Ghostfolio
  et Readeck.
- **Comptes séparés** : Jellyfin (et Jellyseerr), Vaultwarden et Home Assistant
  gardent leur propre identifiant — c'est volontaire.

## Limites

- Sans code d'authentification, la connexion échoue : gardez votre application
  TOTP accessible.
- En cas de perte du second facteur, seul l'administrateur peut réinitialiser
  l'accès.
- L'inscription libre est fermée : pas d'invitation, pas de compte.
