---
sidebar_position: 6
title: Cloud, conteneurs et DevSecOps
---

# Cloud, conteneurs et DevSecOps

Le DevSecOps intègre les exigences de sécurité au cycle de livraison, sans faire
de la CI une simple accumulation de scanners.

## Champs d'application

- IaC, politiques comme code, images minimales et gestion des dépendances.
- Analyse SAST, secrets, composants, conteneurs et configurations.
- Identités de workloads, registres, provenance et chaîne d'approvisionnement.
- Garde-fous de déploiement, observabilité et rollback.

## Principes

Échouer tôt sur les erreurs déterministes, limiter les permissions du pipeline,
épingler les versions et séparer construction, validation et déploiement. Un
résultat de scanner doit être trié selon exploitabilité et impact.

## Mise en pratique homelab

Packer, OpenTofu, Ansible, Docker Compose, Renovate et GitHub Actions forment une
chaîne suffisamment petite pour observer chaque frontière de confiance.
