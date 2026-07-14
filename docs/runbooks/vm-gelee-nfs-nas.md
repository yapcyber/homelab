# Runbook — VM gelée / `can't lock file lock-XXX.conf` / NAS down

> Vécu le 2026-07-13/14 : VM media (104) gelée « façon OOM », puis impossible à
> démarrer (`can't lock file '/var/lock/qemu-server/lock-104.conf' - got timeout`).
> Cause racine réelle : la VM TrueNAS (200) s'était éteinte toute seule → le
> disque RACINE de la 104, stocké sur NFS (`truenas-vm` = 10.0.60.10:/mnt/tank/proxmox),
> ne répondait plus. Le « gel mémoire » n'était que l'empilement de processus en
> attente I/O.

## Arbre de diagnostic

### 1. La VM semble gelée (services morts un à un, SSH inerte, ping OK)
```bash
qm agent <vmid> ping           # agent muet = userspace gelé
qm status <vmid> --verbose | grep freemem
grep -E "^(scsi|virtio|ide)" /etc/pve/qemu-server/<vmid>.conf
```
→ **Si un disque est sur un storage NFS (`truenas-*`), vérifier le NAS AVANT
   de conclure à un OOM.**

### 2. `can't lock file ... got timeout` au start/stop
```bash
fuser -v /run/lock/qemu-server/lock-<vmid>.conf   # qui tient le verrou ?
ps -eo pid,etime,cmd | grep "[t]ask UPID"         # tâches PVE actives
cat /proc/<PID>/wchan                              # sur quoi il attend
```
- `wchan = rpc_wait_bit_killable` → **attente NFS : le NAS ne répond pas.**
- Tâche `qmstart` pendue → la tuer une fois le NAS revenu (ou avant : `kill <PID>`),
  puis `qm unlock <vmid>` si un `lock:` traîne dans la conf.

### 3. Le NAS (VM 200, TrueNAS sur pve1) est éteint / ne démarre pas
```bash
pvesh get /nodes/pve1/tasks --vmid 200 --limit 6   # historique : pourquoi ?
qm start 200
# → "stat for '/dev/disk/by-id/usb-...' failed" = le disque USB du pool a disparu
```
Le pool TrueNAS passe par un pont USB JMicron JMS578 (réputé instable) :
```bash
lsusb | grep -i jmicron            # le pont est-il sur le bus ?
ls /dev/disk/by-id/ | grep usb     # le disque bloc existe-t-il ?
```
- Pont présent mais pas de disque bloc → **reset logiciel** :
  ```bash
  # trouver le device (idVendor 152d)
  for d in /sys/bus/usb/devices/[0-9]*/; do
    [ "$(cat $d/idVendor 2>/dev/null)" = "152d" ] && echo $d; done
  echo 0 > /sys/bus/usb/devices/<X-Y>/authorized; sleep 3
  echo 1 > /sys/bus/usb/devices/<X-Y>/authorized
  dmesg | tail          # attendre "Attached SCSI disk"
  ```
- Échec du reset → débrancher/rebrancher physiquement l'enclosure USB.
- Puis `qm start 200`, attendre que TrueNAS exporte (`showmount -e 10.0.60.10`
  depuis pve1), et les VM NFS-dépendantes reprennent (ou `qm start` les gelées).

## Ordre de rétablissement complet
1. NAS (VM 200) démarré et exports NFS up.
2. Tuer l'éventuel `qmstart` pendu, `qm unlock`, démarrer les VM gelées.
3. Vérifier les services applicatifs (docker ps, routes Traefik).

## Prévention / dette technique
- ⚠️ **Un pool TrueNAS sur pont USB JMS578 est fragile** : migrer vers du SATA
  interne ou un contrôleur en passthrough PCIe dès que possible.
- Le disque racine d'une VM de service sur NFS crée une dépendance forte au NAS :
  soit l'assumer (et superviser le NAS en priorité 1), soit migrer les disques
  racine sur du stockage local (local-lvm).
- Superviser : ping/export NFS du NAS + état de la VM 200 (le health-check
  horaire ne couvre que les conteneurs, pas les VM Proxmox).
