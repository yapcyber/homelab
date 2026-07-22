# Finaliser les sauvegardes — clé USB air-gap + custody des clés

> Complète la couche hors-site **Drive** (restic, déjà active + testée) par la
> couche **air-gap USB** et la **custody des clés `.enc`**. À faire une fois, sur
> l'EliteBook. Voir aussi `sauvegarde-usb-hors-site.md` et `sauvegarde-restic-drive.md`.

## 1. Clé USB air-gap (LUKS) — première mise en place

Clé USB branchée (identifiée : **`/dev/sda`**, Kingston 64 Go).

```bash
sudo apt install -y cryptsetup            # une seule fois
cd ~/homelab
./scripts/backup-usb-setup.sh /dev/sda    # formate en LUKS (EFFACE la clé)
./scripts/backup-usb-sync.sh              # 1ʳᵉ sauvegarde air-gap
```

- Le **setup** demande : mot de passe `sudo`, confirmation `EFFACER /dev/sda`, puis
  une **passphrase LUKS** (2×).
- Le **sync** demande `sudo` + la passphrase, puis copie le dernier `daily` **+ les
  clés** de chaque VM sur la clé chiffrée, et la **verrouille** automatiquement.
- Débranche la clé et range-la **hors-site**. Rituel à répéter (ex. mensuel) : `./scripts/backup-usb-sync.sh`.

⚠️ **Passphrase LUKS → Vaultwarden** (perdue = clé USB irrécupérable).

## 2. Clés de chiffrement `.enc` → Vaultwarden

Chaque VM a une clé `/etc/homelab-backup.key` unique. Elles voyagent déjà **dans**
les sauvegardes (Drive + USB) — donc restaurables même sans Vaultwarden — mais une
copie dans Vaultwarden = custody de secours.

Dans un endroit sans regard par-dessus l'épaule :

```bash
for e in infra:10.0.30.10 monitoring:10.0.30.11 cloud:10.0.30.12 media:10.0.30.13 \
         security:10.0.30.14 scanner:10.0.30.15 firefly:10.0.30.16 osint:10.0.30.17; do
  n=${e%%:*}; ip=${e##*:}
  echo "=== $n ($ip) ==="
  ssh debian@$ip 'sudo cat /etc/homelab-backup.key'
  echo
done
```

→ Colle les 8 clés dans une **note sécurisée Vaultwarden** « Homelab — clés sauvegarde .enc »,
chacune sous son nom de VM. (`ir` n'a pas de sauvegardes → pas de clé.)

## Checklist
- [ ] `cryptsetup` installé
- [ ] Clé USB formatée LUKS (`backup-usb-setup.sh /dev/sda`)
- [ ] 1ʳᵉ sauvegarde USB (`backup-usb-sync.sh`)
- [ ] Passphrase **LUKS** → Vaultwarden
- [ ] 8 clés **`.enc`** → Vaultwarden

## Custody à vérifier dans Vaultwarden (récap)
- Passphrase LUKS (clé USB)
- Mot de passe **restic** (`sops -d scripts/restic-drive.enc.env`)
- Code d'accès **SiYuan** (`sops -d services/cloud/siyuan/siyuan.enc.env`)
- 8 clés `.enc` par VM
