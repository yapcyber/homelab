// =============================================================================
// portfolio/docusaurus.config.ts
// Configuration principale du site portfolio — Homelab yapserver.fr
// =============================================================================
// Docusaurus v3 — TypeScript config
// Documentation : https://docusaurus.io/docs/configuration
// =============================================================================

import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {

  // ===========================================================================
  // IDENTITÉ DU SITE
  // ===========================================================================
  title: 'YapServer Homelab',
  tagline: 'Construire, sécuriser, comprendre et transmettre',
  favicon: 'img/favicon.ico',

  // URL publique du site (utilisée pour les liens canoniques, SEO, sitemap)
  url: 'https://yapserver.fr',
  baseUrl: '/',

  // Lien vers le repo GitHub (utilisé par les boutons "Edit this page")
  organizationName: 'yapcyber',
  projectName: 'homelab',

  onBrokenLinks: 'throw',

  // ===========================================================================
  // INTERNATIONALISATION — FR / EN
  // ===========================================================================
  // Le contenu de fond est d'abord consolidé en français. L'anglais sera
  // réactivé lorsque chaque page structurante aura une traduction relue.
  //
  // FLUX DE TRAVAIL BILINGUE :
  //   1. Écrire le contenu EN dans docs/ et blog/
  //   2. Exécuter : npm run write-translations -- --locale fr
  //   3. Traduire les fichiers générés dans i18n/fr/
  //   4. Les pages traduites apparaissent sur /fr/...
  i18n: {
    defaultLocale: 'fr',
    locales: ['fr'],
    localeConfigs: {
      fr: {
        label: 'Français',
        direction: 'ltr',
        htmlLang: 'fr-FR',
      },
    },
  },

  // ===========================================================================
  // PRESETS — Blog + Documentation + Thème
  // ===========================================================================
  presets: [
    [
      'classic',
      {
        // -----------------------------------------------------------------------
        // DOCUMENTATION TECHNIQUE
        // -----------------------------------------------------------------------
        // Contient : architecture, configuration réseau, déploiement des services
        // Organisé par phase (Phase 0, Phase 1, Phase 2, etc.)
        docs: {
          sidebarPath: './sidebars.ts',
          // Lien "Edit this page" → ouvre directement le fichier sur GitHub
          editUrl: 'https://github.com/yapcyber/homelab/tree/main/portfolio/',
          showLastUpdateTime: true,
          showLastUpdateAuthor: false,
          // Activer les tabs de code, les diagrams Mermaid, etc.
          remarkPlugins: [],
          rehypePlugins: [],
        },

        // -----------------------------------------------------------------------
        // BLOG — Journal de bord hebdomadaire
        // -----------------------------------------------------------------------
        // Contient : posts par phase, problèmes rencontrés, choix d'architecture
        // Publié sur LinkedIn avec lien vers l'article complet
        blog: {
          showReadingTime: true,
          // Flux RSS/Atom pour les abonnés
          feedOptions: {
            type: ['rss', 'atom'],
            title: 'YapServer Homelab — Journal de bord',
            description: 'Suivi hebdomadaire de la construction du homelab',
            copyright: `Copyright © ${new Date().getFullYear()} YapServer`,
            language: 'en',
          },
          editUrl: 'https://github.com/yapcyber/homelab/tree/main/portfolio/',
          // Sidebar du blog : tous les articles (pas de pagination = meilleur SEO)
          blogSidebarTitle: 'All posts',
          blogSidebarCount: 'ALL',
          postsPerPage: 10,
          onInlineAuthors: 'ignore',
        },

        theme: {
          customCss: './src/css/custom.css',
        },

        // Sitemap pour les moteurs de recherche
        sitemap: {
          changefreq: 'weekly',
          priority: 0.5,
        },
      } satisfies Preset.Options,
    ],
  ],

  // ===========================================================================
  // PLUGINS ADDITIONNELS
  // ===========================================================================
  plugins: [
    // Optimisation automatique des images (WebP, lazy loading)
    '@docusaurus/plugin-ideal-image',
  ],

  // Support des diagrammes Mermaid dans le Markdown
  // Usage : ```mermaid ... ```
  markdown: {
  mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  themes: ['@docusaurus/theme-mermaid'],

  // ===========================================================================
  // CONFIGURATION DU THÈME
  // ===========================================================================
  themeConfig: {

    // Image de partage social (OpenGraph, Twitter Cards)
    // Créer une image 1200x630px dans static/img/social-card.png
    image: 'img/social-card.png',

    // Mode sombre par défaut — cohérent avec l'univers DevOps/Sécurité
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },

    // Annonce en haut de page (optionnel — décommenter pour les annonces majeures)
    // announcementBar: {
    //   id: 'phase-launch',
    //   content: '🚀 Phase 3 — Proxmox Cluster is live! <a href="/blog/phase-3-proxmox">Read more</a>',
    //   backgroundColor: '#00d4aa',
    //   textColor: '#1a1a2e',
    //   isCloseable: true,
    // },

    // -------------------------------------------------------------------------
    // NAVBAR
    // -------------------------------------------------------------------------
    navbar: {
      title: 'YapServer',
      hideOnScroll: false,
      logo: {
        alt: 'YapServer Homelab',
        src: 'img/logo.svg',
        srcDark: 'img/logo.svg',
      },
      items: [
        // Documentation technique
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Documentation',
        },
        // Journal de bord
        {
          to: '/blog',
          label: 'Journal',
          position: 'left',
        },
        // Lien GitHub (repo public du homelab)
        {
          href: 'https://github.com/yapcyber/homelab',
          position: 'right',
          className: 'header-github-link',
          'aria-label': 'GitHub repository',
        },
        // LinkedIn (profil professionnel)
        {
          href: 'https://fr.linkedin.com/in/yanis-deschamps-892683199',  // ← À MODIFIER
          position: 'right',
          className: 'header-linkedin-link',
          'aria-label': 'LinkedIn profile',
        },
      ],
    },

    // -------------------------------------------------------------------------
    // FOOTER
    // -------------------------------------------------------------------------
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Homelab',
          items: [
            {label: 'Présentation', to: '/docs/intro'},
            {label: 'Études de cas', to: '/docs/case-studies'},
          ],
        },
        {
          title: 'Suivre le projet',
          items: [
            {label: 'Journal de bord', to: '/blog'},
            {label: 'GitHub', href: 'https://github.com/yapcyber'},
            {label: 'LinkedIn', href: 'https://fr.linkedin.com/in/yanis-deschamps-892683199'},
          ],
        },
      ],
      copyright: `Construit avec Docusaurus · Hébergé sur le homelab · © ${new Date().getFullYear()} YapServer`,
    },

    // -------------------------------------------------------------------------
    // COLORATION SYNTAXIQUE DU CODE
    // -------------------------------------------------------------------------
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      // Langages supplémentaires pour les articles techniques
      additionalLanguages: [
        'bash',
        'yaml',
        'docker',
        'nginx',
        'typescript',
        'python',
        'ini',
        'powershell',
      ],
    },

    // -------------------------------------------------------------------------
    // ALGOLIA DOCSEARCH (optionnel — Phase avancée)
    // -------------------------------------------------------------------------
    // Ajoute une barre de recherche full-text sur tout le site.
    // Gratuit pour les projets open-source : https://docsearch.algolia.com/
    // Décommenter après approbation Algolia :
    //
    // algolia: {
    //   appId: 'VOTRE_APP_ID',
    //   apiKey: 'VOTRE_SEARCH_API_KEY',
    //   indexName: 'yapserver-homelab',
    //   contextualSearch: true,
    // },

  } satisfies Preset.ThemeConfig,
};

export default config;
