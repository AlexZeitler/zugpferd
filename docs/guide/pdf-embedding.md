---
outline: deep
---

# PDF/A-3 Embedding

Embed XML invoices into PDF/A-3 documents to create ZUGFeRD / Factur-X hybrid invoices. The embedded PDF contains both a human-readable invoice and the machine-readable XML data.

## Prerequisites

[Ghostscript](https://ghostscript.com/) must be installed on your system:

```bash
# Debian / Ubuntu
sudo apt-get install ghostscript

# Arch Linux
sudo pacman -S ghostscript

# macOS
brew install ghostscript

# Verify
gs --version
```

Then download the required PDF artifacts:

```bash
bin/setup-schemas
```

This downloads `zugferd.ps` and the sRGB ICC color profile into `vendor/zugferd/`.

## Basic Usage

```ruby
require "zugpferd"
require "zugpferd/pdf"  # explicit opt-in for PDF support

# Build and serialize an invoice (CII is typical for ZUGFeRD)
invoice = Zugpferd::Model::Invoice.new(
  number: "RE-2024-001",
  issue_date: Date.new(2024, 6, 15),
  currency_code: "EUR"
)
# ... configure seller, buyer, line items, totals ...
xml = Zugpferd::CII::Writer.new.write(invoice)

# Embed into an existing PDF
embedder = Zugpferd::PDF::Embedder.new
embedder.embed(
  pdf_path: "rechnung.pdf",
  xml: xml,
  output_path: "rechnung_zugferd.pdf"
)
```

The output is a PDF/A-3 compliant file with the XML attached as `factur-x.xml`.

## Versions and Conformance Levels

The `version` parameter controls which ZUGFeRD/Factur-X version metadata is written:

| Version | XML Filename | Profiles |
|---------|-------------|----------|
| `"2p1"` (default) | `factur-x.xml` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"2p0"` | `zugferd-invoice.xml` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"1p0"` | `ZUGFeRD-invoice.xml` | BASIC, COMFORT, EXTENDED |

```ruby
# ZUGFeRD 2.1 / Factur-X with XRECHNUNG profile
embedder.embed(
  pdf_path: "input.pdf",
  xml: xml,
  output_path: "output.pdf",
  version: "2p1",
  conformance_level: "XRECHNUNG"
)

# ZUGFeRD 1.0
embedder.embed(
  pdf_path: "input.pdf",
  xml: xml,
  output_path: "output.pdf",
  version: "1p0",
  conformance_level: "EXTENDED"
)
```

## Error Handling

```ruby
begin
  embedder.embed(pdf_path: "input.pdf", xml: xml, output_path: "output.pdf")
rescue Zugpferd::PDF::Embedder::GhostscriptNotFound
  # Ghostscript is not installed or not in PATH
rescue Zugpferd::PDF::Embedder::EmbedError => e
  # Ghostscript failed — e.message contains stderr output
rescue ArgumentError => e
  # Invalid version, conformance level, or missing input file
end
```

## How It Works

Under the hood, the embedder:

1. Writes the XML to a temporary file
2. Invokes Ghostscript with `-dPDFA=3` and the vendored `zugferd.ps` PostScript program
3. Ghostscript converts the input PDF to PDF/A-3, embeds the XML with correct AF arrays, AFRelationship, XMP metadata, and ICC color profile
4. Cleans up temporary files

The vendored `zugferd.ps` and `default_rgb.icc` files are sourced from the Ghostscript project, ensuring consistent behavior independent of the installed Ghostscript version.

## Validating the Output

For production use, validate generated PDFs with [veraPDF](https://verapdf.org/) (PDF/A-3 structure) or [Mustangproject](https://www.mustangproject.org/) (full ZUGFeRD validation). Both are available as Docker containers — see [Docker Setup](#docker-setup).

### Docker Setup

```yaml
# docker-compose.yml
services:
  verapdf:
    image: verapdf/rest:latest
    ports:
      - "8080:8080"

  mustang:
    build: docker/mustang
```

```bash
# Start veraPDF
docker compose up -d verapdf

# Build Mustangproject image
docker compose build mustang
```

### veraPDF (PDF/A-3 compliance)

```ruby
require "zugpferd/validation/pdf_validator"

validator = Zugpferd::Validation::PdfValidator.new
result = validator.validate("output.pdf", profile: "3b")

if result.compliant
  puts "PDF/A-3b compliant"
else
  result.failures.each { |f| puts f[:description] }
end
```

### Mustangproject (full ZUGFeRD validation)

```ruby
require "zugpferd/validation/mustang_validator"

validator = Zugpferd::Validation::MustangValidator.new
result = validator.validate("output.pdf")

if result.valid
  puts "ZUGFeRD valid"
else
  puts result.output
end
```
