# Runbook — SSH timeout vers une VM alors que HTTP/ICMP passent

> Symptôme : `ssh debian@10.0.30.X` timeout depuis l'Elitebook (10.0.100.100),
> alors que HTTP/HTTPS et ICMP vers la même VM passent. Vécu le 2026-07-13.

## ⚠️ Verdict de l'incident du 13/07 : ce n'était PAS un ban
Tous les tests (Wazuh AR, fail2ban, iptables locales, OPNsense) sont revenus
vides — car il n'y avait pas de ban : **les VM étaient gelées par la mort du
NFS** (voir `vm-gelee-nfs-nas.md`). Une VM gelée a exactement la signature d'un
ban SSH : sshd timeout (il a besoin du disque : PAM, logs), pendant que les
démons résidents en RAM (Traefik, ntfy) et l'ICMP (noyau) répondent encore.
La « progression VM par VM » = chaque VM gelait quand son cache disque se
vidait ; la « récupération » = reprise du NFS.

**→ Premier réflexe devant cette signature : vérifier le NAS et le stockage
des VM (`qm agent <id> ping`, wchan des tâches PVE), AVANT de chercher un ban.**

## Si le NAS est sain, alors chercher un vrai ban
- Port 22 uniquement, par VM, avec escalade → mécanismes ci-dessous.
- **Toute sonde répétée peut entretenir un vrai ban** — arrêter les boucles de test.

## Identification — dans l'ordre

### 1. Côté VM encore accessible (2 min)
```bash
ssh debian@10.0.30.11
sudo grep <IP_BANNIE> /var/ossec/logs/active-responses.log   # Wazuh AR ?
systemctl is-active fail2ban && sudo fail2ban-client banned  # fail2ban ?
sudo iptables -S | grep -E "recent|hashlimit|<IP_BANNIE>"    # règle locale ?
sudo sshd -T | grep -i penal                                 # OpenSSH >= 9.8 ?
```
Tout vide → passer à OPNsense.

### 2. Côté OPNsense (UI ou SSH)
- **Suricata/IPS** : Services → Intrusion Detection → Alerts, filtrer sur l'IP.
  Une règle `ET SCAN SSH*` en mode drop = coupable. (Suspect n°1 de l'incident.)
- **virusprot** (max new connections/sec sur une règle FW) :
  Diagnostics → Firewall → pfTables → `virusprot` — ou en SSH :
  `pfctl -t virusprot -T show`. ⚠️ ces entrées n'expirent PAS seules.
- **CrowdSec** (si plugin installé) : `cscli decisions list`.

### 3. Débannir
- Suricata : la règle drop se calme seule après ~15-30 min SANS nouvelle tentative ;
  sinon désactiver/passer la règle en alert-only le temps de l'intervention.
- virusprot : `pfctl -t virusprot -T delete <IP>`.
- CrowdSec : `cscli decisions delete --ip <IP>`.

## Prévention (à faire, décision utilisateur)
1. **Whitelister le control node** (10.0.100.100) dans le mécanisme identifié :
   - Suricata : ajouter l'IP à la Home Net/pass list.
   - CrowdSec : `cscli allowlists` / parka whitelist.
   - Wazuh (par précaution) : `<white_list>10.0.100.100</white_list>` dans
     `ossec.conf` du manager (VM security), section `<global>`.
2. **Côté Ansible** : `forks` raisonnable + `pipelining = True` dans ansible.cfg
   (une seule connexion TCP par hôte au lieu d'une par tâche).
3. ⚠️ La fenêtre de patch auto (dimanche 04:30, Elitebook) DOIT être whitelistée
   avant, sinon elle se fera bloquer en plein run.

## Leçon apprise
Quand on diagnostique un blocage réseau : UNE sonde, puis silence. Une boucle
de retry toutes les 20 s transforme un ban de 10 min en ban permanent.
