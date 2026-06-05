# TrueNAS SCALE sous Proxmox — Solution stockage temporaire 2 To
## `infrastructure/nas/TRUENAS-PROXMOX.md`

> Solution temporaire avant acquisition d'un NAS dédié. TrueNAS fournit
> le stockage NFS/SMB pour les services (Nextcloud, Jellyfin, Proxmox Backup).

---

## Principe architectural — La règle fondamentale

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  RÈGLE ABSOLUE : ne JAMAIS stocker la VM TrueNAS        │
│  sur le même datastore que ce qu'elle va servir.            │
│                                                             │
│  Disque OS TrueNAS  →  Stockage LOCAL du node Proxmox      │
│                         (SSD interne, local-lvm ou local)  │
│                                                             │
│  Disques de données  →  Disques SÉPARÉS (virtual ou passthrough)
│  (le pool ZFS)           sur un autre datastore            │
└─────────────────────────────────────────────────────────────┘
```

Si la VM TrueNAS est sur le même stockage qu'elle fournit et que ce
stockage tombe, la VM tombe aussi → deadlock total. C'est le scénario
catastrophe à éviter absolument.

---

## Étape 1 — Choisir où mettre quoi

### Option A : Virtual disks (recommandé pour solution temporaire)

```
Node Proxmox 1 (Mini PC 1, 32 Go RAM — le plus puissant)
├── local-lvm (SSD interne)
│   └── disk-truenas-os.qcow2      ← VM TrueNAS OS (32 Go)
└── Datastore secondaire (à créer)
    └── disk-truenas-data-2to.raw  ← Disque données ZFS (2 To virtual)
```

Prérequis : avoir suffisamment d'espace libre sur le node.
Si le SSD interne du Mini PC 1 fait 500 Go, allouer 32 Go pour l'OS
et ~2 To pour les données (si l'espace le permet).

### Option B : Disk passthrough (meilleur pour ZFS)

Si tu as un disque dur externe ou interne disponible sur le Mini PC 1 :
ZFS préfère accéder au disque physique directement plutôt qu'à un
virtual disk. Les performances sont meilleures et les données sont
indépendantes du node Proxmox.

```bash
# Identifier les disques sur le node
ls -la /dev/disk/by-id/

# Le resultat ressemble à :
# ata-WDC_WD20EZRX-XXX  → /dev/sdb  (disque 2 To à passer en passthrough)
```

---

## Étape 2 — Créer la VM TrueNAS dans Proxmox

### Configuration VM recommandée

```
Nom        : truenas-scale
Node       : Mini PC 1 (VLAN 60 Storage)
vCPU       : 2 cores (4 si le node le permet)
RAM        : 8 Go minimum (16 Go recommandé pour ZFS ARC cache)
OS disk    : 32 Go — sur local-lvm du node (SCSI, VirtIO si possible)
Data disk  : 2 To — séparé (voir étape 1)
Network    : VirtIO, tag VLAN 60, adresse fixe 10.0.60.20
Boot order : CD-ROM (ISO TrueNAS) puis OS disk
```

### Commandes CLI Proxmox (depuis le node ou via SSH)

```bash
# Télécharger ISO TrueNAS SCALE (depuis le node)
pveam update
wget https://download-static.truenas.com/TrueNAS-SCALE/Latest/TrueNAS-SCALE-24.04-latest.iso \
  -O /var/lib/vz/template/iso/truenas-scale.iso

# Créer la VM (adapter vmid selon disponibilité, ex: 200)
qm create 200 \
  --name truenas-scale \
  --memory 8192 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0,tag=60 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:32 \     # OS disk 32 Go sur local-lvm
  --cdrom local:iso/truenas-scale.iso \
  --boot order=ide2 \
  --ostype l26

# Ajouter le disque de données (Option A — virtual disk)
qm set 200 --scsi1 local-lvm:2048  # 2 To = 2048 Go

# OU — Option B — passthrough disque physique
# Récupérer l'ID du disque :
ls -la /dev/disk/by-id/ | grep -v part
# Puis passer le disque en passthrough :
qm set 200 --scsi1 /dev/disk/by-id/ata-WDC_WD20EZRX-XXXXXX
```

---

## Étape 3 — Installation TrueNAS SCALE

1. Démarrer la VM, suivre l'installeur graphique
2. Installer sur le **premier disque** (32 Go = OS disk)
3. **Ne PAS ajouter le disque de données** pendant l'installation
4. Configurer le réseau : IP statique `10.0.60.20/24`, GW `10.0.60.1`
5. Accéder à l'interface web : `http://10.0.60.20`

---

## Étape 4 — Créer le pool ZFS et les datasets

Via l'interface web TrueNAS (Storage → Create Pool) :

```
Pool name   : tank
Layout      : Stripe (un seul disque — pas de redondance)
             ⚠️ STRIPE = AUCUNE REDONDANCE. Faire des backups réguliers
              vers Proxmox Backup Server ou un autre service.
Disk        : Le disque de données 2 To (pas le disque OS)
```

Datasets à créer sous `tank/` :

```
tank/
├── media/          → Jellyfin (films, séries, musique)
├── cloud/
│   ├── nextcloud/  → Fichiers Nextcloud
│   └── immich/     → Photos Immich
├── backups/        → Proxmox Backup Server
└── shared/         → Partage SMB/NFS général
```

---

## Étape 5 — Partages NFS pour Proxmox et les services

### NFS (pour Proxmox — ajouter comme datastore)

```
TrueNAS → Shares → NFS → Add
  Dataset   : tank/backups
  Networks  : 10.0.60.0/24 (VLAN Storage uniquement)
  MapRoot   : root
  Enabled   : true
```

```bash
# Ajouter le NFS comme datastore dans Proxmox
pvesm add nfs truenas-backups \
  --server 10.0.60.20 \
  --export /mnt/tank/backups \
  --content backup,images \
  --nodes pve1,pve2,pve3   # Les 3 nodes du cluster
```

### NFS pour les containers Docker (Nextcloud, Jellyfin)

Monter les datasets NFS dans les docker-compose avec des volumes NFS :

```yaml
# Exemple dans docker-compose.yml de Jellyfin
volumes:
  media:
    driver: local
    driver_opts:
      type: nfs
      o: addr=10.0.60.20,rw,nfsvers=4,soft
      device: ":/mnt/tank/media"
```

---

## Étape 6 — Snapshot automatique (protection données)

TrueNAS → Data Protection → Periodic Snapshot Tasks :

```
Dataset     : tank (tout le pool)
Fréquence   : Daily
Heure       : 03:00
Rétention   : 7 jours
```

---

## Points d'attention pour la solution temporaire

**RAM** : ZFS utilise l'ARC (cache en RAM). Avec 8 Go alloués à TrueNAS,
l'ARC prend ~4 Go. Surveiller la RAM disponible sur le node hôte.
Si le node manque de RAM, réduire l'ARC dans TrueNAS :
`System → Advanced → Kernel → ZFS ARC Max = 2147483648` (2 Go)

**Stripe sans redondance** : un seul disque = zéro tolérance aux pannes.
Configurer Proxmox Backup Server pour faire des backups réguliers
de `tank/` vers un autre endroit.

**Migration future** : Quand tu achètes un vrai NAS :
1. Créer le même layout de datasets sur le nouveau NAS
2. Copier les données via `rsync` ou `zfs send/receive`
3. Rediriger les mounts NFS des VMs et containers vers le nouveau NAS
4. Éteindre la VM TrueNAS

---

## Intégration réseau

```
VLAN 60 (Storage) : 10.0.60.0/24
TrueNAS IP        : 10.0.60.20 (fixe)
Proxmox Node 1    : 10.0.60.10
Proxmox Node 2    : 10.0.60.11
Proxmox Node 3    : 10.0.60.12

Firewall OPNsense VLAN 60 :
  Autoriser : 10.0.10.0/24 (Mgmt) → 10.0.60.20 (NFS 2049, SMB 445, Web 80/443)
  Autoriser : 10.0.30.0/24 (Prod) → 10.0.60.20 (NFS 2049)
  Bloquer   : Tout le reste
```
