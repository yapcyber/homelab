---
sidebar_position: 10
title: Réponse à incident et forensic
---

# DFIR — Digital Forensics and Incident Response

Le DFIR établit ce qui s'est produit, limite l'impact, préserve les preuves et
guide le retour à un état de confiance. Sous pression, seule une préparation
sérieuse évite l'improvisation.

## Cycle de réponse

1. **Préparation** et critères de déclaration.
2. **Identification**, qualification et chronologie.
3. **Confinement** court puis durable.
4. **Éradication** et restauration contrôlée.
5. **Retour d'expérience** et amélioration des contrôles.

## Forensic

La collecte doit préserver intégrité, horodatage, provenance et chaîne de
possession. Disque, mémoire, journaux, réseau et cloud offrent des fragments
complémentaires ; **l'absence de trace n'est pas une preuve d'absence**. L'**ordre
de volatilité** guide la priorité de capture (mémoire avant disque avant archives).

## Concepts clés

- **Chronologie (timeline)** — corréler des horodatages fiables est le cœur de
  l'analyse ; d'où l'importance d'une synchronisation temporelle propre.
- **Confinement réversible d'abord** — arrêter l'hémorragie sans détruire les preuves.
- **Hypothèse puis vérification** — une investigation se pilote comme une enquête,
  pas comme une collecte tous azimuts.
- **Post-mortem sans blâme** — l'objectif est le contrôle manquant, pas le coupable.

## Repères et cadres

- **NIST SP 800-61** (gestion des incidents) et le cycle **SANS PICERL**.
- **MITRE ATT&CK** pour structurer l'analyse des techniques observées.
- Chaîne de possession et ordre de volatilité pour la valeur probante.

## Écueils fréquents

- Éteindre ou réinstaller trop tôt et perdre les preuves.
- Ne pas savoir déclarer : sans critères, l'incident est reconnu trop tard.
- Des journaux non centralisés ou une horloge désynchronisée qui rendent la
  chronologie ininterprétable.

## Dans YapServer

Le laboratoire privilégie la **préparation**, socle de toute réponse :

- **Runbooks** écrits à partir d'incidents réels (par exemple un gel de parc dû à
  une dépendance de stockage), qui imposent de vérifier la bonne couche avant d'agir.
- **Journaux centralisés** et **temps synchronisé** pour rendre une chronologie
  exploitable.
- **Outillage de gestion de cas** (TheHive + Cortex) déployé pour l'analyse et
  l'enrichissement ; le chaînage automatique depuis la détection est un chantier en
  cours.
- **Post-mortems** systématiques : chaque incident produit une leçon et un contrôle.

La réponse à incident à grande échelle reste un domaine approfondi progressivement ;
le lab en construit les réflexes et l'outillage.

## Pour aller plus loin

NIST SP 800-61, le modèle SANS PICERL, et les guides de collecte respectant l'ordre
de volatilité.

## Liens

Le DFIR reçoit ses signaux du [SOC](./soc-blue-team.md), s'appuie sur
l'[architecture](./architecture-securite.md) (journalisation, restauration) et
alimente la [threat intelligence](./threat-intelligence.md) (leçons et indicateurs).
