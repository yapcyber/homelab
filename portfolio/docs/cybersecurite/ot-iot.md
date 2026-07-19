---
sidebar_position: 13
title: Sécurité OT, IoT et systèmes embarqués
---

# Sécurité OT, IoT et systèmes embarqués

Ces environnements relient le numérique au monde physique. Disponibilité, sûreté des
personnes et durée de vie des équipements y pèsent souvent davantage que dans un
système bureautique. Domaine abordé ici de façon conceptuelle, avec un ancrage
pratique limité à l'isolation d'objets connectés.

## Champs d'application

- Automates, supervision industrielle, capteurs, firmware et radio.
- Inventaire passif, zonage / conduits et accès de maintenance.
- Analyse de protocoles, secure boot, signature des mises à jour et identité des
  équipements.
- Gestion des vulnérabilités quand le patch immédiat est impossible.

## Ce qui change par rapport à l'IT

- **La disponibilité prime** — un redémarrage « banal » peut interrompre un processus
  physique critique.
- **La sûreté (safety) précède la sécurité** — protéger d'abord les personnes et les
  équipements.
- **Des cycles de vie longs** — des équipements non patchables pendant des années.
- **Observer avant d'agir** — les scans agressifs peuvent perturber des automates
  fragiles.

## Repères et cadres

- **IEC 62443** (sécurité des systèmes d'automatisation industrielle).
- **Modèle de Purdue** pour le zonage et les conduits.
- **NIST SP 800-82** (guide de sécurité OT).
- Surveillance **passive** et inventaire plutôt qu'analyse active intrusive.

## Écueils fréquents

- Appliquer sans adaptation des réflexes IT (scan actif, patch immédiat, reboot).
- Négliger l'inventaire : on ne protège pas ce que l'on ne connaît pas.
- Ignorer la coordination avec les équipes de sûreté.

## Dans YapServer

L'ancrage pratique se limite à l'IoT domestique, mais avec le bon réflexe :

- **Segment IoT isolé** pour contenir des objets connectés peu fiables et étudier
  leurs flux minimaux et leur télémétrie.
- **Observation avant confiance** : traiter ces équipements comme non maîtrisés par
  défaut.

L'OT industriel proprement dit (automates, protocoles temps réel) reste un domaine
théorique, approfondi via les référentiels ci-dessus.

## Pour aller plus loin

La série **IEC 62443**, le **NIST SP 800-82** et le modèle de Purdue.

## Liens

L'OT/IoT emprunte ses grilles de zonage à la [sécurité réseau](./securite-reseau.md),
ses principes de résilience à l'[architecture](./architecture-securite.md) et sa
surveillance passive au [SOC](./soc-blue-team.md).
