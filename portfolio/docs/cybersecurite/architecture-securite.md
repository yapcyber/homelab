---
sidebar_position: 3
title: Architecture et ingénierie sécurité
---

# Architecture et ingénierie sécurité

Cette spécialité construit des systèmes résistants, observables et récupérables
avant qu'un incident n'impose ses propres contraintes. Elle arbitre en amont ce
que la détection et la réponse devront gérer en aval.

## Champs d'application

- Modélisation des menaces, frontières de confiance et réduction de surface.
- Défense en profondeur, moindre privilège, segmentation et chiffrement.
- Choix de contrôles, standards techniques et revues d'architecture.
- Résilience, journalisation, sauvegarde et scénarios de défaillance.

## Concepts clés

- **Frontière de confiance** — chaque endroit où le niveau de confiance change
  mérite un contrôle explicite.
- **Fail-closed** — en cas d'erreur ou d'absence de règle, refuser par défaut.
- **Rayon d'explosion** — concevoir pour qu'un point d'appui compromis n'ouvre pas
  tout le système.
- **Récupérabilité** — une sauvegarde non testée n'est pas une sauvegarde.

## Modélisation des menaces

Partir des actifs et des flux, identifier les frontières, puis raisonner les abus
possibles (**STRIDE**, arbres d'attaque). Documenter les décisions dans des **ADR**
pour que les compromis de coût, disponibilité et ergonomie restent traçables.

## Repères et cadres

- Principes de conception sûre (**Saltzer & Schroeder** : moindre privilège, défaut
  sûr, économie de mécanisme…).
- **Zero Trust** (NIST SP 800-207) et défense en profondeur.
- **STRIDE / PASTA** pour la modélisation, **ADR** pour la traçabilité.
- Cartes de flux et architectures de référence comme livrables.

## Écueils fréquents

- Empiler des contrôles sans modèle de menace : beaucoup d'efforts, peu de
  couverture.
- Confondre conformité formelle et résistance réelle.
- Un réseau « à plat » derrière une belle façade : rayon d'explosion maximal.

## Dans YapServer

- **Segmentation en zones de confiance** et principe **fail-closed** de bout en bout
  (proxy, politiques d'accès, secrets).
- **Vérification des chemins réels** plutôt que des schémas : les frontières Docker
  et inter-segments sont testées, pas supposées.
- **Résilience assumée et mesurée** : sauvegardes applicatives quotidiennes,
  chiffrement des données sensibles, et un point de défaillance de stockage
  documenté comme donnée d'ingénierie plutôt que masqué.

L'étude de cas
[« Une panne de stockage ressemblait à une panne réseau »](../case-studies.md)
montre comment une dépendance partagée devient un domaine de panne — un sujet
d'architecture avant d'être un sujet d'exploitation.

## Pour aller plus loin

NIST SP 800-207, la méthode STRIDE, et les principes de conception sûre de
Saltzer & Schroeder.

## Liens

L'architecture fixe le cadre de la [sécurité réseau](./securite-reseau.md) et de
l'[IAM](./iam.md), et détermine ce que le [SOC](./soc-blue-team.md) et le
[DFIR](./dfir.md) pourront observer et restaurer.
