# Autoriser le control node en SSH sur Security Onion

## Ce que l'UI peut gérer

Les comptes SOC et les comptes Linux sont distincts. `Administration > Users`
gère uniquement les utilisateurs de la console SOC ; cette page ne modifie pas
les comptes Linux ni leurs clés SSH.

Le pare-feu Security Onion se gère dans :

1. `Administration` ;
2. `Configuration` ;
3. `firewall` ;
4. `hostgroups`.

Le control node utilise actuellement `10.0.100.100`. Vérifier que cette adresse,
ou le VLAN Admin `10.0.100.0/24`, appartient au groupe autorisé à joindre SSH.
Ne pas modifier directement iptables : le pare-feu est piloté par Salt.

## Poser la clé publique de l'EliteBook

Depuis la console locale Security Onion, se connecter avec le compte Linux créé
pendant l'installation, puis exécuter cette commande unique :

```bash
install -d -m 700 ~/.ssh && curl -fsSL https://raw.githubusercontent.com/yapcyber/homelab/main/infrastructure/security-onion/elitebook-control-node.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```

Afficher ensuite le nom du compte à reporter sur le control node :

```bash
whoami
```

Sur l'EliteBook, ce nom est passé au script de vérification avec la variable
`SECURITY_ONION_USER`. Exemple si le compte affiché est `yanis` :

```bash
SECURITY_ONION_USER=yanis ~/homelab/ansible/control-node/homelab-update-check.sh
```

La clé versionnée est publique. La clé privée correspondante reste uniquement
dans `~/.ssh/id_ed25519` sur l'EliteBook et ne doit jamais être copiée dans Git.
