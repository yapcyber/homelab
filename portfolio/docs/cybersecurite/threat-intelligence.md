---
sidebar_position: 11
title: Threat Intelligence et OSINT
---

# Threat Intelligence et OSINT

Le renseignement sur la menace transforme des informations dispersées en
connaissance utile à une décision de défense. Sans question de départ, on accumule
des indicateurs ; on ne produit pas du renseignement.

## Niveaux et usages

- **Stratégique** : tendances, motivations et exposition métier.
- **Opérationnel** : campagnes, infrastructures et temporalité.
- **Tactique** : comportements et techniques adverses.
- **Technique** : indicateurs à durée de vie souvent courte.

## Cycle du renseignement

Définir un besoin, collecter légalement, traiter, analyser, diffuser puis recueillir
le retour du destinataire. Accumuler des IOC sans question initiale produit du bruit,
pas du renseignement.

## Concepts clés

- **Actionnabilité** — un renseignement vaut par la décision qu'il permet, pas par
  son volume.
- **Fiabilité de la source** — distinguer la crédibilité de la source et celle de
  l'information (échelle de l'Amirauté).
- **Durée de vie** — un indicateur technique se périme vite ; un comportement (TTP)
  dure.
- **Partage maîtrisé** — le **TLP** encadre à qui l'on peut retransmettre.

## Repères et cadres

- **Cycle du renseignement**, **Diamond Model** et **Cyber Kill Chain** pour
  structurer l'analyse.
- **MITRE ATT&CK** comme langage commun des comportements adverses.
- **STIX / TAXII** et **MISP** pour formaliser et échanger.
- **Traffic Light Protocol (TLP)** pour la diffusion.

## Écueils fréquents

- Confondre données brutes et renseignement.
- Ingérer des flux d'IOC sans contexte ni date de péremption.
- Collecter en OSINT sans respecter le droit et les conditions d'usage.

## Dans YapServer

- **Collecte OSINT outillée** (SpiderFoot, Maigret) exécutée de façon planifiée et
  bornée, dans le respect du droit et des conditions d'usage.
- **Enrichissement** via des analyseurs (réputation d'adresses, recherche de comptes)
  reliés à la gestion de cas.
- **Passerelle vers la détection** : mapper les comportements observés à des règles,
  plutôt que d'empiler des indicateurs jetables.

## Pour aller plus loin

Le Diamond Model, MITRE ATT&CK, le format STIX/TAXII et le projet MISP.

## Liens

La threat intelligence oriente le [SOC](./soc-blue-team.md) (quoi détecter), nourrit
le [DFIR](./dfir.md) (contexte d'incident) et informe le
[pentest / Red Team](./pentest-red-team.md) (émulation d'adversaire).
