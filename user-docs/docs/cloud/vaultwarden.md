---
sidebar_position: 3
title: Vaultwarden
---

# Vaultwarden

Vaultwarden est votre coffre-fort de mots de passe, compatible avec les
applications Bitwarden.

## À quoi ça sert

- Enregistrer et générer des mots de passe forts.
- Les synchroniser de façon chiffrée entre vos appareils.
- Stocker des notes et codes sécurisés.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://vault.yapserver.fr`.
2. Connectez-vous avec votre **compte Vaultwarden** et votre **mot de passe
   maître** (compte distinct de la connexion unique).
3. Installez les applications et extensions **Bitwarden** et réglez l'URL de
   serveur sur `https://vault.yapserver.fr`.

## Interactions

- **Compte dédié** : Vaultwarden n'utilise pas la connexion unique, par sécurité
  pour le coffre.
- **WireGuard** requis pour toute synchronisation.

## Limites

- Le mot de passe maître ne peut pas être récupéré : s'il est perdu, le coffre
  devient inaccessible.
- L'inscription est fermée : les comptes sont créés sur invitation de
  l'administrateur.
- Activez la double authentification sur votre compte pour renforcer l'accès.
