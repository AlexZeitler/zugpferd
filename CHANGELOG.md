# Changelog

## [Unreleased]

### Fixed

- `Zugpferd::Validation::PdfValidator` reads the response of veraPDF 1.30. `validationResult` is a list there, and the failed rules are under `details.ruleSummaries`. It no longer raises a `TypeError`, and it lists the failed rules. `available?` also returns `false` when the connection opens and then breaks
- `Zugpferd::PDF::Embedder` produces PDF/A-3 compliant output with Ghostscript before 10.04.0. The Catalog lacked the Associated Files array `/AF`, and veraPDF and Mustangproject rejected the PDF under ISO 19005-3, clause 6.8. The gem now sets `/AF` itself for these versions

## [0.9.0] - 2026-11-20

### Added

- Payment account name (BT-85) in data model, UBL and CII readers/writers
- Project reference (BT-11) in data model, UBL and CII readers/writers. UBL credit notes carry it as `cac:AdditionalDocumentReference` with document type code `50`, CII writes the mandatory `ram:Name` as "Project reference"
- Contract reference (BT-12) and sales order reference (BT-14) in data model, UBL and CII readers/writers. Because UBL requires `cac:OrderReference/cbc:ID`, the UBL writer writes `NA` there when only the sales order reference is set, and the UBL reader returns a purchase order reference (BT-13) of `NA` as `nil`
- Buyer accounting reference (BT-19) in data model, UBL (`cbc:AccountingCost`) and CII (`ram:ReceivableSpecifiedTradeAccountingAccount`) readers/writers
- `Zugpferd::PDF::Extractor` reads the embedded invoice XML from a ZUGFeRD / Factur-X / XRechnung PDF and hands it to the CII or UBL reader. It needs the `pdf-reader` gem, which is not a runtime dependency. The decompressed attachment size and the name tree depth are limited

### Fixed

- `Zugpferd::Validation::SchemaValidator` loads the XSD schemas without `Dir.chdir`. It no longer changes the working directory of the whole process, and it no longer raises a `RuntimeError` when another thread is inside a `Dir.chdir` block

## [0.8.0] - 2026-11-10

### Added

- Deliver to address (BG-15) with street (BT-75), city (BT-77), post code (BT-78) and country code (BT-80) in data model, UBL and CII readers/writers

## [0.7.0] - 2026-11-05

### Added

- Seller tax registration identifier (BT-32) in data model, UBL and CII readers/writers. It is written and read for the seller only

### Changed

- UBL and CII readers/writers: write and read the seller additional legal information (BT-33, `legal_form`) for the seller only. A buyer value is no longer written, and the readers return `nil` for it on the buyer

## [0.6.0] - 2026-11-04

### Added

- Purchase order reference (BT-13) in data model, UBL and CII readers/writers
- Preceding invoice reference (BG-3) with number (BT-25) and issue date (BT-26) in data model, UBL and CII readers/writers. CII carries only the first reference
- Item price base quantity (BT-149) and its unit code (BT-150) in UBL and CII readers/writers. `Price#base_quantity` existed before but was never read or written

### Fixed

- UBL writer: write the payment due date (BT-9) of credit notes as `cac:PaymentMeans/cbc:PaymentDueDate` instead of `cbc:DueDate`, which CreditNote-2 does not allow. Without payment instructions (BG-16) the due date is not written
- Docs: label `PaymentInstructions#note` as payment terms (BT-20) instead of BT-82

### Changed

- UBL reader: read the payment due date (BT-9) of credit notes from `cac:PaymentMeans/cbc:PaymentDueDate`. A `cbc:DueDate` in a credit note is no longer read

## [0.5.1] - 2026-11-03

### Fixed

- CII reader: read invoices without VAT that omit the invoice total VAT amount (BT-110) instead of raising an `ArgumentError`. The amount is set to `0`, so the writers output it

### Changed

- CII reader: raise `Zugpferd::CII::Reader::MissingTaxTotalError` when BT-110 is missing and the VAT breakdown (BG-23) is empty or does not sum to 0

## [0.5.0] - 2026-11-02

### Added

- Invoice line period (BG-26) with start date (BT-134) and end date (BT-135) in data model, UBL and CII readers/writers

### Changed

- Relax the `bigdecimal` dependency from `~> 3.1` to `>= 3.1` to allow version 4 and later

## [0.4.0] - 2026-11-02

### Added

- Invoicing period (BG-14) with start date (BT-73) and end date (BT-74) in data model, UBL and CII readers/writers

## [0.3.5] - 2026-10-20

### Fixed

- CII writer: write `RoundingAmount` (BT-114) before `GrandTotalAmount` as required by the CII D16B XSD

### Changed

- `vendor/schemas/` is no longer tracked in git; run `bin/setup-schemas` after cloning

## [0.3.4] - 2026-02-19

### Fixed

- `bin/setup-schemas`: use `$(pwd)/vendor` instead of path relative to script location
- `bin/setup-schemas`: fix UBL ZIP extraction path (`xsd/*` instead of `os-UBL-2.1/xsd/*`)
- `bin/setup-schemas`: download CII D16B XSD from GitHub release asset (unece.org blocked by Cloudflare)
- `bin/setup-schemas`: flatten deeply nested CII XSD files after extraction
- `bin/setup-schemas`: fix XRechnung Schematron release tag (`v2.5.0` instead of `release-2.5.0`)

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
