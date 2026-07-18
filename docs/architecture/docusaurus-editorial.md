# Architecture éditoriale de Docusaurus

## Rôle

Docusaurus est la surface publique et relue du projet. Il doit répondre à trois
questions : pourquoi le homelab existe, comment il a évolué, et ce que les
expériences permettent d'enseigner.

## Parcours de lecture

```text
Accueil
├── Le projet
│   ├── Vision et contraintes
│   ├── Chronologie par phases
│   └── Architecture actuelle
├── Construire
│   ├── Réseau et virtualisation
│   ├── IaC et automatisation
│   └── Services et exploitation
├── Défendre
│   ├── Architecture sécurité
│   ├── Détection et réponse
│   └── Sauvegarde et résilience
├── Études de cas
│   └── signal → investigation → décision → preuve → leçon
└── Cours cybersécurité
    ├── socle commun
    └── spécialités
```

## Types de contenu

- **Récit** : chronologie, choix, erreurs et évolution de maturité.
- **Architecture** : état actuel, frontières et compromis, daté et versionné.
- **Étude de cas** : faits observés, hypothèses, preuves et résultat.
- **Cours** : objectif, prérequis, notions, pratique sûre et ressources.
- **Runbook public** : procédure générique expurgée des informations sensibles.

## Règles éditoriales

1. Ne publier ni IP privée, secret, donnée personnelle, inventaire exploitable ou
   détail facilitant un accès non autorisé.
2. Distinguer clairement fait observé, hypothèse et opinion.
3. Dater les informations susceptibles d'évoluer et citer les sources primaires.
4. Ne présenter comme « maîtrisé » qu'un contrôle associé à une preuve ou un test.
5. Écrire pour expliquer une décision, pas pour dresser une liste d'outils.
6. Une page possède un propriétaire implicite, un statut et une date de revue.

## Prochaines pages structurantes

1. Chronologie des phases 0 à aujourd'hui à partir de l'historique Git et des
   notes privées, après expurgation.
2. Vue d'architecture logique sans adresses ni secrets.
3. Parcours pédagogiques débutant, Blue Team et infrastructure sécurité.
4. Laboratoires reproductibles et isolés associés aux cours.
5. Bibliographie et politique de mise à jour des contenus.
