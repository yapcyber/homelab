---
sidebar_position: 4
title: Identité et gestion des accès
---

# IAM — Identity and Access Management

L'IAM s'assure qu'une identité correctement vérifiée reçoit uniquement les
droits nécessaires, pendant la durée nécessaire, avec une trace exploitable.

## Champs d'application

- Cycle de vie des comptes, authentification multifacteur et fédération SSO.
- RBAC/ABAC, comptes de service, accès privilégiés et revues périodiques.
- Protocoles OIDC, OAuth 2.0, SAML, LDAP et gestion des sessions.
- Détection des comptes dormants, secrets persistants et élévations anormales.

## Risques fréquents

Confondre authentification et autorisation, multiplier les administrateurs,
laisser des comptes orphelins ou stocker des jetons sans rotation.

## Mise en pratique homelab

Authentik centralise les applications compatibles, Vaultwarden protège les
secrets, et chaque intégration doit prévoir un compte de secours documenté.
