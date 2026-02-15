import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Zugpferd',
  base: '/zugpferd/',
  // Deploy URL: https://alexzeitler.github.io/zugpferd/
  description: 'Ruby library for reading and writing EN 16931 electronic invoices (UBL 2.1 & UN/CEFACT CII)',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'API', link: '/api/models' }
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'Reading Documents', link: '/guide/reading' },
          { text: 'Writing Documents', link: '/guide/writing' },
          { text: 'Validation', link: '/guide/validation' },
          { text: 'PDF/A-3 Embedding', link: '/guide/pdf-embedding' }
        ]
      },
      {
        text: 'API Reference',
        items: [
          { text: 'Data Model', link: '/api/models' },
          { text: 'UBL Reader / Writer', link: '/api/ubl' },
          { text: 'CII Reader / Writer', link: '/api/cii' },
          { text: 'Validation', link: '/api/validation' },
          { text: 'PDF Embedder', link: '/api/pdf' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/alexzeitler/zugpferd' }
    ]
  }
})
