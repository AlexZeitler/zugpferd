# Changelog

## [Unreleased]

## [0.3.3] - 2026-02-19

### Fixed

- Set browser User-Agent on all curl requests in `bin/setup-schemas` to avoid throttling

## [0.3.2] - 2026-02-19

### Fixed

- Remove `spec.executables` — `bin/setup-schemas` is a project-local bash script, not a gem executable

## [0.3.1] - 2026-02-19

### Added

- `bin/setup-schemas` is now included in the gem as an executable

### Fixed

- Missing `require "zugpferd/validation"` in Rakefile `validate` task

## [0.3.0] - 2026-02-15

### Added

- PDF/A-3 embedding via Ghostscript (`Zugpferd::PDF::Embedder`) — create ZUGFeRD / Factur-X hybrid invoices
- Support for ZUGFeRD versions 1.0, 2.0 and 2.1 with all conformance levels
- XSD and Schematron validation included in gem (`require "zugpferd/validation"`) — optional, requires Java + Saxon
- Actual delivery date (BT-72) support in data model, UBL and CII readers/writers
- veraPDF validation wrapper (`Zugpferd::Validation::PdfValidator`) for PDF/A-3 compliance checks
- Mustangproject validation wrapper (`Zugpferd::Validation::MustangValidator`) for full ZUGFeRD validation
- Docker setup for veraPDF (REST API) and Mustangproject (CLI)
- `bin/setup-schemas` downloads Saxon HE, XSD schemas, CEN/XRechnung Schematron, `zugferd.ps` and `default_rgb.icc`

## [0.2.0] - 2026-02-15

### Added

- `BillingDocument` module with shared attributes and initialization logic
- Dedicated classes for each document type:
  - `Model::CreditNote` (type code 381)
  - `Model::CorrectedInvoice` (type code 384)
  - `Model::SelfBilledInvoice` (type code 389)
  - `Model::PartialInvoice` (type code 326)
  - `Model::PrepaymentInvoice` (type code 386)

### Changed

- `Model::Invoice` now includes `BillingDocument` instead of defining attributes directly
- UBL Reader returns `Model::CreditNote` for Credit Note documents
- CII Reader maps type codes to the appropriate model class
- Writer parameter renamed from `invoice` to `document`

### Breaking

- UBL Reader now returns `Model::CreditNote` (instead of `Model::Invoice`) for type code 381
- CII Reader returns type-specific classes based on the document's type code

## [0.1.0] - 2026-02-14

### Added

- Syntax-agnostic EN 16931 data model with all mandatory and common optional fields
- UBL 2.1 Reader and Writer (Invoice and Credit Note)
- UN/CEFACT CII Reader and Writer
- Document-level allowances and charges (BG-20/BG-21)
- XRechnung CIUS support (BT-10, BT-34/BT-49 electronic addresses)
- Payment types: credit transfer, direct debit, payment card
- VitePress documentation site
