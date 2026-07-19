import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import {themes as prismThemes} from 'prism-react-renderer';

const config: Config = {
  title: 'Documentation YapServer',
  tagline: 'Guides utilisateurs des services du homelab',
  url: 'https://docs.yapserver.fr',
  baseUrl: '/',
  favicon: 'img/favicon.svg',
  onBrokenLinks: 'throw',
  organizationName: 'yapcyber',
  projectName: 'homelab',
  i18n: {defaultLocale: 'fr', locales: ['fr']},
  presets: [[
    'classic',
    {
      docs: {sidebarPath: './sidebars.ts', routeBasePath: '/'},
      blog: false,
      pages: false,
      theme: {customCss: './src/css/custom.css'},
      sitemap: false,
    } satisfies Preset.Options,
  ]],
  themeConfig: {
    navbar: {
      title: 'Docs YapServer',
      logo: {alt: 'YapServer', src: 'img/logo.svg'},
      items: [
        {type: 'docSidebar', sidebarId: 'docsSidebar', label: 'Guides', position: 'left'},
        {to: '/faq', label: 'FAQ', position: 'left'},
      ],
    },
    footer: {
      style: 'dark',
      links: [{title: 'Aide', items: [
        {label: 'Commencer', to: '/'},
        {label: 'Dépannage', to: '/depannage'},
      ]}],
      copyright: `Documentation privée YapServer · ${new Date().getFullYear()}`,
    },
    colorMode: {defaultMode: 'dark', respectPrefersColorScheme: true},
    prism: {theme: prismThemes.github, darkTheme: prismThemes.dracula},
  } satisfies Preset.ThemeConfig,
};

export default config;
