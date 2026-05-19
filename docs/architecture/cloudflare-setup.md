# Guide — Migration Cloudflare & Configuration du Tunnel
## `docs/cloudflare-setup.md`

> Durée estimée : 30 minutes + 24-48h de propagation DNS

---

## Partie 1 — Migration du domaine vers Cloudflare

### Pourquoi migrer depuis Infomaniak ?

Le domaine reste **enregistré** chez Infomaniak (le registrar ne change pas). Ce qu'on change, c'est uniquement les **nameservers** — les serveurs DNS qui résolvent yapserver.fr. On pointe vers Cloudflare DNS à la place des DNS Infomaniak.

Avantages :
- Gestion DNS centralisée avec Cloudflare (là où sont les tunnels, le WAF, etc.)
- Token API pour Traefik/Let's Encrypt (DNS Challenge ACME)
- CDN et protection DDoS gratuits sur les services publics

### Étapes

**1. Créer un compte Cloudflare**
→ https://dash.cloudflare.com/sign-up (gratuit)

**2. Ajouter le domaine**
```
Cloudflare Dashboard → Add a site → Entrer: yapserver.fr → Sélectionner: Free
```
Cloudflare va scanner tes DNS existants et les importer automatiquement. Vérifier que les enregistrements existants sont bien présents.

**3. Récupérer les nameservers Cloudflare**
À la fin du wizard, Cloudflare affiche deux nameservers du type :
```
ada.ns.cloudflare.com
miles.ns.cloudflare.com
```
Note ces valeurs — elles sont uniques à ton compte.

**4. Changer les nameservers chez Infomaniak**
```
Infomaniak Manager → Noms de domaine → yapserver.fr
→ Serveurs DNS → Modifier
→ Remplacer les DNS Infomaniak par les deux nameservers Cloudflare
→ Sauvegarder
```

**5. Attendre la propagation**
Délai : 24-48h (souvent 30 minutes en pratique).

Vérifier la propagation :
```bash
# Depuis le Mini PC 5
dig NS yapserver.fr +short
# Doit retourner les nameservers Cloudflare, pas Infomaniak
```

**6. Vérifier dans Cloudflare**
Le domaine passe du statut **Pending** à **Active** dans le dashboard.

---

## Partie 2 — Créer le Token API (pour Traefik/ACME)

Le token API permet à Traefik de créer des enregistrements TXT temporaires pour valider les certificats Let's Encrypt via DNS Challenge.

```
Cloudflare Dashboard → My Profile → API Tokens → Create Token
→ Utiliser le template "Edit zone DNS"
→ Zone resources : Include → Specific zone → yapserver.fr
→ Continue to summary → Create Token
```

Copier le token généré dans :
- `services/infra/traefik/.env` → `CF_DNS_API_TOKEN`
- `services/cloud/nextcloud/.env` (si utilisé pour certs)

⚠️ Ce token n'est affiché qu'une seule fois — le sauvegarder dans le gestionnaire de mots de passe.

---

## Partie 3 — Créer le Tunnel Cloudflare

Le tunnel permet d'exposer le portfolio (et futurs services publics) sans ouvrir de port sur la box FAI.

### Création du tunnel

```
Cloudflare Dashboard → Zero Trust → Networks → Tunnels
→ Create a tunnel
→ Connector type: Cloudflared
→ Tunnel name: homelab-prod
→ Save tunnel
```

Cloudflare affiche alors un token sous la forme :
```
eyJhIjoiXXXXXXXXXXXXX...
```

**Copier ce token** dans `portfolio/.env` → `CLOUDFLARE_TUNNEL_TOKEN`

### Configuration des Public Hostnames (Phase 4)

Après avoir démarré le container cloudflared, configurer les routes :

```
Zero Trust → Networks → Tunnels → homelab-prod → Configure → Public Hostnames
```

| Subdomain | Domain | Service | Notes |
|-----------|--------|---------|-------|
| *(vide)* | yapserver.fr | `http://traefik:80` | Site portfolio (apex) |
| www | yapserver.fr | `http://traefik:80` | Redirection www |

**Header HTTP à ajouter** pour chaque hostname :
```
HTTP Headers → Host: yapserver.fr
```
→ Traefik utilise ce header pour router vers le bon container.

### Configuration Cloudflare SSL/TLS

```
Cloudflare Dashboard → yapserver.fr → SSL/TLS → Overview
→ Mode: Full (strict)
```

`Full (strict)` = Cloudflare valide le certificat Let's Encrypt de Traefik.
`Full` seul accepte les certificats auto-signés (moins sécurisé).
`Flexible` = HTTP en clair entre Cloudflare et ton serveur (ne jamais utiliser).

---

## Partie 4 — Configurer le Split-DNS dans OPNsense (Phase 2)

Pour que les services internes soient accessibles depuis le LAN via `service.yapserver.fr` sans sortir par Cloudflare :

```
OPNsense → Services → Unbound DNS → Host Overrides
```

Ajouter une entrée par service interne :

| Host | Domain | IP | Description |
|------|--------|----|-------------|
| traefik | yapserver.fr | 10.0.40.10 | Dashboard Traefik |
| wazuh | yapserver.fr | 10.0.50.10 | Wazuh Dashboard |
| proxmox | yapserver.fr | 10.0.10.10 | Proxmox Node 1 |
| *(vide)* | yapserver.fr | 10.0.40.10 | Apex → Traefik (portfolio) |

Résultat :
- **Depuis le LAN/WireGuard** : `wazuh.yapserver.fr` → 10.0.50.10 (direct, sans Cloudflare)
- **Depuis internet** : `yapserver.fr` → Cloudflare → Tunnel → Traefik → Portfolio
