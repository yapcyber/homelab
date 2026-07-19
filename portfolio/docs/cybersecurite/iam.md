---
sidebar_position: 4
title: Identité et gestion des accès
---

# IAM — Identity and Access Management

L'IAM s'assure qu'une identité correctement vérifiée reçoit uniquement les droits
nécessaires, pendant la durée nécessaire, avec une trace exploitable. C'est
souvent le vrai périmètre de sécurité d'un système moderne.

## Champs d'application

- Cycle de vie des comptes, authentification multifacteur et fédération SSO.
- RBAC/ABAC, comptes de service, accès privilégiés et revues périodiques.
- Protocoles OIDC, OAuth 2.0, SAML, LDAP, SCIM et gestion des sessions.
- Détection des comptes dormants, secrets persistants et élévations anormales.

## Concepts clés

- **Authentification ≠ autorisation** — prouver qui l'on est ne dit pas ce que l'on
  a le droit de faire.
- **Moindre privilège dans le temps** — le bon droit, pour la bonne durée (accès
  juste-à-temps plutôt que permanent).
- **Compte de secours (break-glass)** — chaque dépendance SSO doit avoir une porte
  de sortie documentée et surveillée.
- **Défense en profondeur du coffre** — le magasin de secrets ne dépend pas de la
  même identité que ce qu'il protège.

## Repères et cadres

- **OIDC / OAuth 2.0 / SAML / SCIM** pour la fédération et le provisionnement.
- **NIST SP 800-63** (niveaux d'assurance d'identité et d'authentification).
- **RBAC / ABAC**, revues d'accès et gestion des accès privilégiés (PAM).
- **MFA résistante au phishing** comme cible, TOTP comme socle minimal.

## Écueils fréquents

- Confondre authentification et autorisation dès la conception.
- Multiplier les administrateurs et laisser des comptes orphelins.
- Stocker des jetons sans rotation, ou fédérer un service au point de perdre tout
  accès si le SSO tombe.

## Dans YapServer

- **SSO centralisé** (Authentik) : OIDC natif pour les services à clients
  mobiles/desktop, forward-auth pour les outils web d'administration, et **MFA TOTP
  imposée** à l'enrôlement comme à la connexion.
- **Enrôlement sur invitation** (fail-closed : sans invitation, pas de compte).
- **Comptes de secours documentés** pour ne pas dépendre entièrement du SSO.
- **Coffre de secrets** (Vaultwarden) **volontairement hors SSO**, par défense en
  profondeur ; la configuration d'identité est versionnée pour être reproductible.

La rotation décrite dans
[« Faire évoluer un secret sans casser l'accès »](../case-studies.md) relève autant
de l'IAM que du DevSecOps : changer une valeur privilégiée sans interrompre l'accès
légitime.

## Pour aller plus loin

NIST SP 800-63, les spécifications OpenID Connect et OAuth 2.0, et les principes de
gestion des accès privilégiés.

## Liens

L'IAM s'appuie sur l'[architecture](./architecture-securite.md), se déploie via le
[DevSecOps](./cloud-devsecops.md) (secrets et identités de workloads) et fournit au
[SOC](./soc-blue-team.md) des signaux d'abus d'identité.
