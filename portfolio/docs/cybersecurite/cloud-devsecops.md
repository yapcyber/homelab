---
sidebar_position: 6
title: Cloud, conteneurs et DevSecOps
---

# Cloud, conteneurs et DevSecOps

Le DevSecOps intègre les exigences de sécurité au cycle de livraison, sans faire
de la CI une simple accumulation de scanners. L'objectif : rendre le chemin sûr
plus facile que le chemin risqué.

## Champs d'application

- IaC, politiques comme code, images minimales et gestion des dépendances.
- Analyse SAST, secrets, composants (SCA), conteneurs et configurations.
- Identités de workloads, registres, provenance et chaîne d'approvisionnement.
- Garde-fous de déploiement, observabilité et rollback.

## Principes

Échouer tôt sur les erreurs déterministes, limiter les permissions du pipeline,
épingler les versions et séparer construction, validation et déploiement. Un
résultat de scanner se trie selon **exploitabilité et impact**, il ne se coche pas.

## Concepts clés

- **Infrastructure immuable** — reconstruire plutôt que modifier en place réduit la
  dérive et les angles morts.
- **Shift-left, mais pas shift-only** — détecter tôt sans négliger l'exécution.
- **Chaîne d'approvisionnement** — l'essentiel du code exécuté vient de tiers ;
  provenance et épinglage comptent autant que « son » code.
- **Secrets** — ne jamais versionner en clair ; chiffrer, faire tourner, livrer au
  plus près du besoin.

## Repères et cadres

- **NIST SSDF (SP 800-218)** et **OWASP SAMM / DSOMM** pour structurer la démarche.
- **SLSA** et signatures/provenance pour la chaîne d'approvisionnement.
- **CIS Benchmarks** pour le durcissement des hôtes et conteneurs.
- **Policy-as-code** pour transformer une règle en garde-fou automatique.

## Écueils fréquents

- Un pipeline surprivilégié qui devient la meilleure cible de l'attaquant.
- Des scanners bruyants dont personne ne trie les résultats.
- Des secrets « temporaires » en clair qui survivent des mois.
- Des mises à jour majeures automatisées sans snapshot ni test.

## Dans YapServer

La chaîne est volontairement petite pour observer chaque frontière de confiance :

- **Provisionnement reproductible** : image dorée (Packer) → déploiement des VM
  (OpenTofu, état chiffré) → configuration et patching (Ansible).
- **GitOps** : la configuration vit dans Git, une source de vérité unique commite,
  les machines ne font que suivre en lecture ; un préflight et une CI valident
  avant fusion.
- **Secrets chiffrés** (SOPS + Age) : la clé privée reste hors dépôt, la livraison
  se fait au plus près du service avec contrôle d'intégrité et rollback borné.
- **Mises à jour maîtrisées** : une majeure à la fois, snapshot puis test, plutôt
  qu'un « tout-automatique » illusoire sur des migrations à état.

Deux études de cas prolongent cette section :
[« La croissance du scanner saturait son disque système »](../case-studies.md)
(capacité et sauvegarde conçues ensemble) et
[« Faire évoluer un secret sans casser l'accès »](../case-studies.md)
(rotation vers un hash à mémoire dure, puis livraison chiffrée).

## Pour aller plus loin

NIST SSDF, OWASP DSOMM, le cadre SLSA et les CIS Benchmarks.

## Liens

Le DevSecOps porte les [secrets et l'IAM](./iam.md) des workloads, outille
l'[AppSec](./appsec.md) (SAST/SCA dans la CI) et fournit au [SOC](./soc-blue-team.md)
une infrastructure observable et reconstructible.
