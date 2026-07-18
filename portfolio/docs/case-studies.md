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
