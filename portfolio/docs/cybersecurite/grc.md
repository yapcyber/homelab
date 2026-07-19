---
sidebar_position: 2
title: Gouvernance, risques et conformité
---

# GRC

La GRC relie les objectifs de l'organisation aux décisions de sécurité. Elle
transforme actifs, menaces, vulnérabilités et impacts en priorités explicables —
et distingue ce qui est conforme de ce qui est réellement efficace.

## Champs d'application

- Cartographie des actifs, processus critiques et dépendances.
- Analyse et traitement des risques : réduire, transférer, accepter ou éviter.
- Politiques, plans de contrôle, audits et gestion des tiers.
- Continuité d'activité, exigences réglementaires et preuves de conformité.

## Concepts clés

- **Risque = menace × vulnérabilité × impact**, pondéré par la vraisemblance ; un
  risque se traite, il ne se « corrige » pas toujours.
- **Appétence au risque** — décider explicitement ce que l'on accepte, plutôt que de
  le subir par défaut.
- **Contrôle ↔ preuve** — un contrôle sans preuve vérifiable n'est qu'une intention.
- **Conformité ≠ sécurité** — cocher un référentiel ne prouve pas la résistance à
  une attaque.

## Repères et cadres

- **ISO/IEC 27001 et 27005** (SMSI et gestion des risques), **NIST CSF**.
- **EBIOS Risk Manager** (ANSSI) pour l'analyse de risque par scénarios.
- **ISAE 3402 / SOC 2**, **PCI DSS**, **RGPD** selon le contexte.
- **ISO 22301**, **RPO / RTO** et **BIA** pour la continuité d'activité.

## Écueils fréquents

- Un registre des risques qui vit dans un tableur mort, jamais relu.
- Des politiques génériques sans propriétaire ni date de revue.
- Confondre l'audit (preuve à un instant t) et la sécurité (propriété continue).

## Dans YapServer

La gouvernance est appliquée à l'échelle d'un lab, mais avec les mêmes réflexes :

- **Décisions tracées** : les choix structurants (secrets hors Git, une majeure à la
  fois, VPN par défaut) sont documentés et justifiés, façon registre de décisions.
- **Contrôle associé à une preuve** : sauvegardes vérifiées quotidiennement,
  contrôles de dérive et d'expiration — chaque garde-fou produit un signal.
- **Continuité assumée** : RPO/RTO à formaliser, restauration à tester, et les
  limites connues (copie hors site à consolider) sont écrites, pas masquées.

## Pour aller plus loin

ISO/IEC 27001 et 27005, NIST Cybersecurity Framework, et EBIOS Risk Manager (guides
ANSSI).

## Liens

La GRC oriente l'[architecture](./architecture-securite.md) (priorités et
exigences), s'appuie sur l'[IAM](./iam.md) (revues d'accès, preuves) et cadre la
[réponse à incident](./dfir.md) (critères de déclaration).
