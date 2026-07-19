---
sidebar_position: 1
title: Firefly III
---

# Firefly III

Firefly III est votre outil de gestion budgétaire : comptes, dépenses, budgets et
objectifs.

## À quoi ça sert

- Suivre vos comptes, revenus et dépenses.
- Définir des budgets et des catégories.
- Analyser vos finances avec des rapports.

## Comment l'utiliser

1. Activez WireGuard puis ouvrez `https://firefly.yapserver.fr` : l'accès passe
   par la **connexion unique**.
2. Créez vos comptes, puis saisissez ou importez vos transactions.
3. Pour importer des relevés bancaires (CSV), utilisez l'**importateur** sur
   `https://importer.yapserver.fr`.

## Interactions

- **Firefly Data Importer** (`importer.yapserver.fr`) : compagnon dédié à l'import
  de relevés vers Firefly III.
- **Connexion unique (Authentik)** : l'accès web est protégé par votre compte
  YapServer.
- **WireGuard** requis.

## Limites

- L'import demande un fichier au bon format ; vérifiez le mappage des colonnes
  avant de valider.
- Firefly III enregistre vos données par saisie ou import : il ne se connecte pas
  directement à vos banques.
