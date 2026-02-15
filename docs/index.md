---
layout: home
head:
  - - meta
    - property: og:image
      content: https://alexzeitler.github.io/zugpferd/og-image.png
  - - meta
    - property: og:image:width
      content: '1200'
  - - meta
    - property: og:image:height
      content: '630'

hero:
  name: "Zugpferd"
  text: "EN 16931 E-Invoicing for Ruby"
  tagline: Read, write and convert electronic invoices in UBL 2.1 and UN/CEFACT CII
  actions:
    - theme: brand
      text: Getting Started
      link: /guide/getting-started
    - theme: alt
      text: API Reference
      link: /api/models

features:
  - title: UBL 2.1 & CII
    details: Full support for both EN 16931 syntaxes — read, write and roundtrip any XRechnung or ZUGFeRD invoice.
  - title: XRechnung & ZUGFeRD
    details: Supports XRechnung and ZUGFeRD profiles — read any compliant invoice and convert between UBL and CII.
  - title: Pure Ruby Data Model
    details: Agnostic data model with BigDecimal amounts, Date fields, and plain Ruby objects.
---
