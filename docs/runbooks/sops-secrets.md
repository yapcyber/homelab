# Gérer les secrets avec SOPS et Age

SOPS est installé sur le poste de contrôle. `.sops.yaml` contient uniquement le
destinataire Age public ; la clé privée est locale, en mode `0600`, et la paire
a été vérifiée sans afficher son contenu.

## Créer un secret chiffré

Créer d'abord un fichier temporaire protégé hors du dépôt, puis :

```bash
sops --encrypt /chemin/prive/service.env > services/service/service.enc.env
sops --decrypt services/service/service.enc.env > services/service/.env
chmod 600 services/service/.env
```

Seuls les fichiers correspondant aux règles de `.sops.yaml` (`*.enc.env` ou
`secrets/*.{yaml,json,env}`) doivent être versionnés. Le `.env` déchiffré reste
ignoré par Git.

## Modèle de livraison

Le poste de contrôle déchiffre au dernier moment et transfère le secret sur la
VM cible avec Ansible `no_log: true`, permissions `0600`, sans journaliser sa
valeur. Une VM de service ne reçoit que les secrets nécessaires à sa pile.

## Récupération

La clé privée Age doit avoir deux copies indépendantes : une pièce jointe
protégée dans Vaultwarden et une copie hors ligne. SOPS ne remplace pas cette
sauvegarde : perdre la clé privée rend tous les futurs fichiers chiffrés
illisibles. Avant de migrer les secrets existants, tester le chiffrement et le
déchiffrement d'une valeur factice puis documenter la restauration de la clé.
