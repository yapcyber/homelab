---
sidebar_position: 7
title: Sécurité applicative
---

# AppSec — sécurité applicative

L'AppSec réduit les vulnérabilités introduites pendant la conception, le
développement, l'intégration et l'exploitation d'un logiciel. Ces notes en posent
le cadre ; la pratique offensive avancée reste un domaine en apprentissage.

## Champs d'application

- Exigences et threat modeling dès la conception.
- Revue de code, SAST, DAST, fuzzing et analyse des dépendances.
- Authentification, contrôle d'accès, validation des entrées et gestion d'erreur.
- Sécurisation des API, sessions, données sensibles et logique métier.

## Concepts clés

- **Une vulnérabilité n'est pas qu'une entrée mal filtrée** — les abus de workflow
  et les autorisations horizontales exigent une compréhension métier.
- **Confiance des entrées** — tout ce qui vient du client est hostile jusqu'à preuve
  du contraire.
- **Dépendances** — beaucoup de failles viennent de composants tiers ; le SCA
  compte autant que la revue de « son » code.
- **Défaut sûr** — échouer en refusant, pas en laissant passer.

## Repères et cadres

- **OWASP Top 10** (risques les plus courants) et **OWASP ASVS** (exigences de
  vérification).
- **OWASP Cheat Sheets** et **CWE** pour les schémas de défaut.
- **SAST / DAST / SCA** intégrés au cycle de livraison.
- Threat modeling (**STRIDE**) appliqué au périmètre applicatif.

## Écueils fréquents

- Se limiter aux injections et ignorer la logique métier (IDOR, abus de workflow).
- Traiter les résultats de scanner comme une liste, sans triage d'exploitabilité.
- Gérer les secrets applicatifs en clair dans le code ou la configuration.

## Dans YapServer

L'angle est surtout **DevSecOps appliqué** : intégrer les contrôles au pipeline
plutôt que d'auditer du code à la main.

- **Contrôles en CI** : validation de configuration, interdiction de secrets en
  clair, préflight avant fusion.
- **Gestion des secrets** chiffrée (SOPS + Age) plutôt que codée en dur.
- **Intégrité des données d'un pipeline** : le projet « CV-as-Code » impose des
  garde-fous stricts pour empêcher une IA d'inventer ou d'altérer un fait — une
  approche « défaut sûr » appliquée à une chaîne logicielle.

La revue de code sécurisée et le test applicatif offensif sont approfondis
progressivement, en s'appuyant sur les cibles d'entraînement OWASP.

## Pour aller plus loin

OWASP Top 10, OWASP ASVS et les OWASP Cheat Sheets ; la base CWE pour les schémas de
vulnérabilités.

## Liens

L'AppSec se déploie via le [DevSecOps](./cloud-devsecops.md) (SAST/SCA en CI),
partage ses contrôles d'accès avec l'[IAM](./iam.md) et fournit des cibles au
[pentest](./pentest-red-team.md).
