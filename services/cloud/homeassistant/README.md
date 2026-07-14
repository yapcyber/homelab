# Home Assistant — automatisations geofence

## Cas 1 — Liste de courses au magasin (le post d'origine, adapté)

**Principe** : une zone geofence autour du magasin ; quand le téléphone y entre,
notification avec le contenu de la liste de courses et un lien direct.

Mise en place (UI, ~10 min) :
1. **App compagnon** sur le téléphone → serveur `https://ha.yapserver.fr`
   (fonctionne à l'extérieur via WireGuard, split-tunnel DNS inclus).
   Autoriser la localisation → crée `device_tracker.<ton_tel>`.
2. **Zone** : Paramètres → Zones → ajouter « Magasin » (rayon ~150 m).
3. **Liste** : Paramètres → Intégrations → « Listes de tâches locales » →
   créer « Liste de courses » → `todo.liste_de_courses`.
4. **Automatisation** (déclencheur : entrée dans la zone) :

```yaml
alias: Courses — notification à l'arrivée au magasin
triggers:
  - trigger: zone
    entity_id: device_tracker.TON_TELEPHONE   # à adapter
    zone: zone.magasin
    event: enter
actions:
  - action: todo.get_items
    target:
      entity_id: todo.liste_de_courses
    data:
      status: [needs_action]
    response_variable: liste
  - action: notify.mobile_app_TON_TELEPHONE   # à adapter
    data:
      title: "🛒 Tu es au magasin"
      message: >-
        {%- set items = liste['todo.liste_de_courses']['items'] %}
        {%- if items %}À prendre :
        {% for i in items %}• {{ i.summary }}
        {% endfor %}{%- else %}Liste vide !{%- endif %}
      data:
        notification_icon: mdi:basket
        actions:
          - action: URI
            title: Ouvrir la liste
            uri: /todo?entity_id=todo.liste_de_courses
```

## Cas 2 — QR de point-relais affiché en approchant (extension maison)

**Pipeline cible** :
```
mail livraison (Gmail) ──> intégration IMAP (idle) ──> automatisation :
  1. filtre expéditeur (Mondial Relay, Relais Colis, Chronopost…)
  2. extraction : pièce jointe/QR + adresse du point relais
  3. géocodage de l'adresse (Nominatim, déjà utilisé par Wanderer)
  4. stockage : input_text.relais_coords + QR copié dans /config/www/qr/
  5. déclencheur template : distance(states.device_tracker.tel, lat, lon) < 0.3
  6. notification persistante avec image=/local/qr/colis.png
  7. nettoyage à la sortie de zone + colis récupéré
```

Points de conception :
- **Pas besoin de créer une « vraie » zone dynamiquement** (HA ne le permet pas
  proprement) : un déclencheur template avec la fonction `distance()` sur des
  coordonnées stockées en `input_text` fait le même travail, sans limite de
  nombre de points relais.
- Le QR est déjà une image dans le mail → on l'affiche tel quel dans la
  notification (`image: /local/qr/...`), pas besoin de le régénérer.
- L'extraction mail se fait par un petit script python appelé en
  `shell_command` (imap → sauvegarde de la PJ → géocodage → set des helpers).

Prérequis à fournir :
- mot de passe d'application Gmail (intégration IMAP),
- un mail de livraison réel de chaque transporteur (pour écrire les parsers).
