---
sidebar_position: 9
title: SOC et Blue Team
---

# SOC et Blue Team

Le SOC transforme de la télémétrie en décisions : qualifier, enquêter, contenir
ou clôturer avec une justification reproductible. C'est l'orientation principale
de ce laboratoire.

## Champs d'application

- Collecte et normalisation de logs, EDR/XDR, NDR et SIEM.
- Écriture de règles de détection, enrichissement, triage et investigation.
- Threat hunting, mesure de couverture et amélioration continue.
- Gestion des cas, escalade et coordination avec l'exploitation et le DFIR.

## Anatomie d'une bonne détection

Une détection utile possède une menace visée, une source fiable, une logique
testable, des faux positifs connus, un contexte de triage et un responsable. Le
volume d'alertes seul n'est jamais un indicateur de maturité : une règle qui se
déclenche mille fois par jour sans être triée est une dette, pas une capacité.

On combine trois familles de détection :

- **Signature** — précise mais contournable, utile sur des indicateurs connus.
- **Comportementale / heuristique** — vise les techniques (TTP), plus robuste au
  changement d'outil de l'attaquant.
- **Anomalie** — puissante mais coûteuse en tuning et en contexte.

## Concepts clés

- **Fenêtre de visibilité** — on ne détecte que ce que l'on collecte ; cartographier
  les sources avant d'écrire des règles.
- **Couverture vs bruit** — chaque règle a un coût de triage ; mesurer la valeur
  ajoutée, pas seulement l'ajout.
- **Enrichissement** — une alerte sans contexte (identité, actif, criticité) n'est
  pas exploitable.
- **Boucle de rétroaction** — faux positifs et incidents nourrissent la règle
  suivante.

## Repères et cadres

- **MITRE ATT&CK** pour décrire les comportements adverses et mesurer la couverture
  réelle plutôt que le nombre de règles ; **MITRE D3FEND** côté défense.
- **Detection-as-code** : règles versionnées, revues et testées comme du logiciel
  (Sigma, règles Suricata, décodeurs et règles Wazuh).
- **Pyramid of Pain** pour privilégier les détections coûteuses à contourner.
- **Cyber Kill Chain** et **SOC-CMM** pour situer couverture et maturité.

## Écueils fréquents

- Empiler des sources sans les normaliser ni les trier.
- Confondre « la règle existe » et « la règle est validée sur le chemin réel ».
- Mesurer l'activité (nombre d'alertes) au lieu du résultat (menaces qualifiées).
- Négliger la maintenance : une détection non entretenue dérive silencieusement.

## Dans YapServer

La détection est traitée comme un produit, pas comme un empilement d'outils :

- **Deux points de vue complémentaires** : un capteur hôte (Wazuh, avec agents sur
  les machines) et un capteur réseau (Security Onion — Suricata + Zeek — alimenté
  par un port miroir).
- **Détections écrites et versionnées**, mappées sur MITRE ATT&CK, puis rejouées
  sur des scénarios contrôlés pour comparer ce que chaque capteur voit ou manque.
- **Boucle de qualité** : tableau de bord de conformité des correctifs construit à
  partir de l'indexeur de vulnérabilités, alerte centralisée, et passage de relais
  vers la gestion de cas en cours de construction.

L'étude de cas [« Les ports Docker contournaient la frontière prévue »](../case-studies.md)
illustre le réflexe central du métier : **un contrôle n'existe que s'il est testé
sur le chemin réellement emprunté**.

## Pour aller plus loin

MITRE ATT&CK et D3FEND, le format Sigma, la « Pyramid of Pain » (David Bianco) et
le modèle SOC-CMM pour l'auto-évaluation.

## Liens

Cette spécialité s'appuie sur la [sécurité réseau](./securite-reseau.md)
(visibilité est-ouest), prolonge le [DFIR](./dfir.md) (qualification → réponse) et
consomme du [renseignement](./threat-intelligence.md) (comportements à détecter).
