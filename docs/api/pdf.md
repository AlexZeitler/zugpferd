---
outline: deep
---

# PDF Embedder / Extractor

Embed XML invoices into PDF/A-3 documents using Ghostscript, and read them back out of received PDFs. Loaded via `require "zugpferd/pdf"` (not included by default).

## Embedder

```ruby
require "zugpferd/pdf"

embedder = Zugpferd::PDF::Embedder.new
embedder.embed(
  pdf_path: "input.pdf",
  xml: xml_string,
  output_path: "output.pdf"
)
```

### `embed(pdf_path:, xml:, output_path:, version: "2p1", conformance_level: "EN 16931") → String`

Converts a PDF to PDF/A-3 and embeds the given XML as an associated file.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pdf_path` | `String` | (required) | Path to the input PDF |
| `xml` | `String` | (required) | XML content to embed (UBL or CII) |
| `output_path` | `String` | (required) | Path for the output PDF/A-3 file |
| `version` | `String` | `"2p1"` | ZUGFeRD version: `"2p1"`, `"2p0"`, `"1p0"`, `"rc"` |
| `conformance_level` | `String` | `"EN 16931"` | Profile level (version-dependent). Must match the invoice's CIUS — use `"XRECHNUNG"` for XRechnung invoices. |

**Returns:** `String` — the `output_path`

**Raises:**

| Exception | When |
|-----------|------|
| `Zugpferd::PDF::Embedder::GhostscriptNotFound` | `gs` is not installed or not in PATH |
| `Zugpferd::PDF::Embedder::EmbedError` | Ghostscript execution failed or `zugferd.ps` / ICC profile missing |
| `ArgumentError` | Invalid version, conformance level, or input file not found |

## Constants

### `Zugpferd::PDF::Embedder::VERSIONS`

```ruby
%w[rc 1p0 2p0 2p1]
```

### `Zugpferd::PDF::Embedder::CONFORMANCE_LEVELS`

Valid conformance levels per version:

| Version | Levels |
|---------|--------|
| `"2p1"` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"2p0"` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"1p0"` | BASIC, COMFORT, EXTENDED |

## Exceptions

### `Zugpferd::PDF::Embedder::GhostscriptNotFound`

Inherits from `Zugpferd::Error`. Raised when the `gs` binary cannot be found in PATH.

### `Zugpferd::PDF::Embedder::EmbedError`

Inherits from `Zugpferd::Error`. Raised when Ghostscript returns a non-zero exit code, or when required vendor files (`zugferd.ps`, `default_rgb.icc`) are missing.

## Extractor

Reads the embedded invoice XML from a hybrid PDF. Needs the `pdf-reader` gem in your Gemfile; zugpferd does not install it. See [PDF Extraction](/guide/pdf-extraction).

```ruby
require "zugpferd/pdf"

result = Zugpferd::PDF::Extractor.new.extract(pdf_path: "rechnung.pdf")
invoice = result.read
```

### `new(max_xml_bytes: 10_485_760, max_name_tree_depth: 32)`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `max_xml_bytes` | `Integer` | `10_485_760` (10 MiB) | Largest decompressed attachment to accept |
| `max_name_tree_depth` | `Integer` | `32` | Deepest `EmbeddedFiles` name tree level to visit |

### `extract(pdf_path:) → Result`

Finds the attachment named `factur-x.xml`, `xrechnung.xml`, `zugferd-invoice.xml` or `ZUGFeRD-invoice.xml`, first in the catalog's `/AF` array, then in the `EmbeddedFiles` name tree.

**Raises:**

| Exception | When |
|-----------|------|
| `Zugpferd::PDF::Extractor::PdfReaderNotFound` | the `pdf-reader` gem is not installed |
| `Zugpferd::PDF::Extractor::InvoiceNotFound` | no attachment has an invoice file name |
| `Zugpferd::PDF::Extractor::AmbiguousInvoice` | more than one attachment has one |
| `Zugpferd::PDF::Extractor::LimitExceeded` | the attachment or the name tree passes a limit |
| `Zugpferd::PDF::Extractor::ExtractError` | the PDF cannot be read, or the attachment uses a filter other than `FlateDecode` |
| `ArgumentError` | the input file does not exist |

### `Result`

| Method | Returns |
|--------|---------|
| `xml` | `String` — the embedded XML, byte for byte |
| `filename` | `String` — e.g. `"factur-x.xml"` |
| `syntax` | `:cii`, `:ubl`, or `nil` for any other root element |
| `read` | `Model::BillingDocument`, via `CII::Reader` or `UBL::Reader`; raises `UnsupportedSyntax` when `syntax` is `nil` (e.g. ZUGFeRD 1.0) |

### Exceptions

All inherit from `Zugpferd::Error`. `InvoiceNotFound`, `AmbiguousInvoice`, `LimitExceeded` and `UnsupportedSyntax` inherit from `Zugpferd::PDF::Extractor::ExtractError`.
