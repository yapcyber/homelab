---
sidebar_position: 2
title: Études de cas
---

# Études de cas d'ingénierie

## Une panne de stockage ressemblait à une panne réseau

**Signal.** Plusieurs VM deviennent simultanément injoignables, ce qui évoque
d'abord un bannissement SSH ou une régression du pare-feu.

**Investigation.** La corrélation entre l'échec des agents invités et les tâches
hyperviseur bloquées révèle une dépendance NFS commune. Les symptômes réseau
sont une conséquence de l'attente d'entrées/sorties.

**Réponse.** Le runbook vérifie désormais NAS et stockage avant de modifier le
pare-feu. Le démontage à l'arrêt est renforcé et le domaine de panne temporaire
du stockage est documenté.

**Leçon.** Corréler plusieurs couches est plus efficace que multiplier les
sondes sur celle qui manifeste le symptôme.

## Les ports Docker contournaient la frontière prévue

**Signal.** Des services publiés sur l'hôte restent accessibles hors du chemin
du reverse proxy malgré une politique de pare-feu apparemment restrictive.

**Investigation.** Les règles de transfert Docker sont évaluées sur un chemin
différent de la chaîne d'entrée initialement surveillée.

**Réponse.** Une politique persistante `DOCKER-USER`, pilotée par inventaire,
limite les ports aux sources proxy et d'administration autorisées. Les accès
directs au socket Docker ont été supprimés ou placés derrière un proxy filtrant.

**Leçon.** Un contrôle n'existe réellement que s'il est testé sur le chemin
effectivement emprunté.

## La croissance du scanner saturait son disque système

**Signal.** La plateforme de vulnérabilités reste disponible, mais sa sauvegarde
nocturne échoue avec `No space left on device`.

**Investigation.** Les images sont toutes utilisées ; la place est consommée par
les feeds, la base active et plusieurs historiques de sauvegarde.

**Réponse.** Disque virtuel et filesystem sont étendus en ligne. Un contrôle
quotidien alerte désormais sur les archives périmées ou tronquées, tandis que la
capacité devient une métrique de croissance.

**Leçon.** Pour les outils de sécurité riches en données, rétention et capacité
de sauvegarde doivent être conçues ensemble.

## Faire évoluer un secret sans casser l'accès

**Signal.** Un jeton d'administration web privilégié est représenté par une
valeur réutilisable en clair dans la configuration d'exécution.

**Réponse.** Il est converti en place vers un hash à mémoire dure tout en
préservant l'accès opérateur. Les inscriptions publiques sont désactivées et les
invitations permettent l'enrôlement contrôlé.

**Étape suivante.** SOPS et Age préparent la livraison chiffrée. La clé privée de
récupération reste hors de Git et doit posséder une sauvegarde indépendante.

## La haute disponibilité butait sur le stockage, pas sur la configuration

**Signal.** Objectif : qu'une VM bascule automatiquement sur un nœud survivant en
cas de panne d'hyperviseur, avec un système de priorités. La fonction existe
nativement dans l'orchestrateur — il « suffirait » de l'activer.

**Investigation.** L'audit — trois nœuds, quorum sain, pile HA déjà présente —
déplace le problème. Une VM ne peut redémarrer ailleurs que si son disque y est
atteignable : or le stockage « partagé » était en réalité servi par une VM
tournant sur un seul nœud, adossée à un disque unique non redondant. Panne de ce
nœud → plus de stockage → aucune VM ne redémarre. S'y ajoute l'absence de marge
mémoire : nœuds à 80–95 %, aucun ne pouvant absorber la charge d'un voisin (règle
N+1 non tenue).

**Réponse.** La configuration HA est la partie facile et déjà prête ; le chantier
réel est le socle. Une loi cadre l'arbitrage : un disque de VM servi par le réseau
est borné par la latence et le débit — centraliser pour la HA échange de la
vitesse locale contre une vitesse réseau, et le bon compromis se joue sur « à
quelle distance, à quelle vitesse » se trouve ce stockage. Trois pistes pesées :

- **Stockage cloud** — écarté pour du disque « à chaud » : chaque entrée/sortie
  traverserait le WAN (latence et débit montant), ralentissant tout le système, et
  l'accès Internet deviendrait un point de défaillance. Sa place est en sauvegarde
  hors-site, pas en stockage primaire.
- **NAS dédié** — la réponse correcte : indépendant des nœuds de calcul, disques
  en miroir. Contreparties : coût matériel et, pour ne pas brider les I/O, une
  montée réseau vers 10G (le 1G devenant le nouveau goulot).
- **Recycler une machine existante** (par exemple une sonde de supervision) — coût
  immédiat nul, mais on sacrifie une capacité de sécurité et, avec un disque
  unique, on recrée la non-redondance que l'on cherchait à fuir.

**Leçon.** En virtualisation, la disponibilité se gagne d'abord au niveau du
stockage : activer la bascule ne protège de rien tant que le disque des VM dépend
d'un seul nœud. Nommer le vrai goulot — ici l'architecture de stockage, pas la
fonction HA — vaut mieux qu'activer une protection en trompe-l'œil.
