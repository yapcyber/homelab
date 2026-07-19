---
sidebar_position: 5
title: Sécurité réseau
---

# Sécurité réseau

La sécurité réseau contrôle et observe les communications entre zones de
confiance. Elle ne consiste pas seulement à « fermer des ports » : il s'agit de
définir les flux légitimes, de les faire respecter et de prouver qu'ils le sont.

## Champs d'application

- Segmentation, filtrage stateful, VPN, DNS, proxy et accès distant.
- IDS/IPS, analyse de flux, capture de paquets et détection est-ouest.
- Durcissement des équipements, plan d'administration séparé et haute disponibilité.
- Diagnostic entre couches : routage, transport, application et stockage.

## Méthode

Partir des flux métier autorisés, appliquer le **refus par défaut**, journaliser
les écarts puis tester depuis chaque zone. Une règle de pare-feu n'est une preuve
que si le paquet emprunte réellement la chaîne attendue.

## Concepts clés

- **Nord-sud vs est-ouest** — le trafic entre segments est souvent filtré ; le
  trafic interne à un segment est le vrai angle mort.
- **Zone de confiance** — un segment n'est sûr que si l'on maîtrise qui y entre et
  ce qui s'y parle.
- **Chaîne de traitement** — un paquet traverse plusieurs points de décision
  (routeur, pare-feu, règles hôte, proxy) ; un contrôle au mauvais endroit ne
  protège rien.
- **Prévention et visibilité** — prévenir sans observer, c'est piloter à l'aveugle ;
  observer sans prévenir, c'est constater les dégâts.

## Repères et cadres

- **Défense en profondeur** et **moindre privilège réseau** ; principes du
  **Zero Trust** (NIST SP 800-207) appliqués avec pragmatisme.
- **MITRE ATT&CK** pour raisonner le mouvement latéral et l'exfiltration.
- **Modèle de Purdue** comme grille de zonage (utile aussi côté OT/IoT).
- NIDS **Suricata / Zeek**, analyse de flux et capture pour la preuve.

## Écueils fréquents

- Considérer un VLAN comme une frontière de sécurité alors que le trafic
  intra-segment n'est ni filtré ni observé.
- Oublier que des ports publiés par un conteneur peuvent contourner la politique
  attendue.
- Confondre « pas d'exposition Internet » et « pas de surface d'attaque interne ».

## Dans YapServer

- **Segmentation par zones de confiance** derrière un pare-feu maison, DNS interne
  en résolution scindée, et accès distant exclusivement par VPN.
- **Visibilité réseau** via un capteur passif alimenté par un port miroir
  (Suricata + Zeek), pour étudier conjointement prévention et détection.
- **Filtrage des chemins Docker** piloté par inventaire, après avoir constaté qu'un
  port publié pouvait contourner la frontière prévue.

Les études de cas
[« Une panne de stockage ressemblait à une panne réseau »](../case-studies.md) et
[« Les ports Docker contournaient la frontière prévue »](../case-studies.md)
rappellent qu'un contrôle se valide sur le chemin réel, pas sur le schéma.

## Pour aller plus loin

NIST SP 800-207 (Zero Trust), la documentation Suricata et Zeek, et le modèle de
Purdue pour le zonage.

## Liens

La sécurité réseau alimente le [SOC](./soc-blue-team.md) (télémétrie est-ouest),
s'articule avec l'[architecture](./architecture-securite.md) (frontières de
confiance) et partage ses grilles de zonage avec l'[OT/IoT](./ot-iot.md).
