# SOPS/Age — runbook Bash

## Test sans toucher aux secrets

```bash
cd ~/homelab
./scripts/sops-runbook.sh test
```

Résultat attendu : `clé Age et aller-retour validés`. Le script vérifie les
binaires, les permissions, la correspondance de clés, le chiffrement puis le
déchiffrement d'une valeur factice. Les fichiers temporaires sont supprimés.

## Chiffrer un fichier réel

```bash
cd ~/homelab
./scripts/sops-runbook.sh encrypt \
  /chemin/prive/service.env \
  services/nom-du-service/service.enc.env
```

Le fichier de sortie doit finir par `.enc.env`. Le script refuse d'écraser un
fichier, refuse une source déjà suivie par Git et compare le déchiffrement avec
l'original. Il ne supprime jamais le fichier source automatiquement.

Après contrôle :

```bash
git status --short
git add services/nom-du-service/service.enc.env
```

Ne jamais ajouter le fichier source en clair. La clé privée Age reste hors Git.
