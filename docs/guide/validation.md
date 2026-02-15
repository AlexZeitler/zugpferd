---
outline: deep
---

# Validation

Validate generated XML invoices against EN 16931 and XRechnung business rules before sending them to customers or embedding them into PDFs.

## When to Validate

**During development** — validate every generated invoice to catch missing fields or structural errors early. This requires Java and Saxon HE.

**In production** — once your invoice generation logic is verified, you can skip validation for performance. If users create invoices interactively (variable input), keep the validator active.

## Setup

Install Java and download the validation artifacts:

```bash
# Debian / Ubuntu
sudo apt-get install default-jre-headless

# Arch Linux
sudo pacman -S jre-openjdk-headless

# macOS
brew install openjdk

# Download Saxon, XSD schemas, and Schematron XSLT files
bin/setup-schemas
```

`bin/setup-schemas` downloads:
- Saxon HE 12.5 + xmlresolver (XSLT processor)
- UBL 2.1 XSD schemas (OASIS)
- CII D16B XSD schemas (UN/CEFACT)
- CEN EN16931 Schematron XSLT (business rules)
- XRechnung Schematron XSLT (German CIUS rules)

## Schematron Validation

The Schematron validator checks EN 16931 business rules (e.g. "payable amount must match line totals plus tax") and XRechnung-specific rules (e.g. "seller contact is required").

```ruby
require "zugpferd"
require "zugpferd/validation"  # explicit opt-in, requires Java + Saxon

xml = Zugpferd::CII::Writer.new.write(invoice)

validator = Zugpferd::Validation::SchematronValidator.new(
  schemas_path: "vendor/schemas"
)

# Validate against CEN EN16931 rules
errors = validator.validate(xml, rule_set: :cen_cii)

# Validate against XRechnung rules
errors = validator.validate(xml, rule_set: :xrechnung_cii)

# Validate against both at once
errors = validator.validate_all(xml, rule_sets: [:cen_cii, :xrechnung_cii])
```

### Rule Sets

| Key | Rules | Syntax |
|-----|-------|--------|
| `:cen_ubl` | EN 16931 (BR-*) | UBL |
| `:cen_cii` | EN 16931 (BR-*) | CII |
| `:xrechnung_ubl` | XRechnung (BR-DE-*) | UBL |
| `:xrechnung_cii` | XRechnung (BR-DE-*) | CII |

### Interpreting Results

Each error has an `id`, `text`, `location`, and `flag`:

```ruby
errors.each do |error|
  puts "[#{error.flag}] #{error.id}: #{error.text}"
  # => [fatal] BR-CO-25: In case the Amount due for payment (BT-115)
  #    is positive, either the Payment due date (BT-9) or the
  #    Payment terms (BT-20) shall be present.
end

# Fatal errors = the invoice is invalid
fatals = errors.select { |e| e.flag == "fatal" }

# Warnings / information = should be fixed but not blocking
warnings = errors.reject { |e| e.flag == "fatal" }
```

The error ID (e.g. `BR-CO-25`, `BR-DE-2`) references a specific business rule in the EN 16931 or XRechnung specification.

## XSD Schema Validation

The schema validator checks structural XML correctness against the XSD schemas. This catches malformed elements, wrong namespaces, or missing required XML elements — but not business logic errors.

```ruby
require "zugpferd/validation"

validator = Zugpferd::Validation::SchemaValidator.new(
  schemas_path: "vendor/schemas"
)

errors = validator.validate(xml, schema_key: :ubl_invoice)
# => [] if valid, or ["Element 'foo': not expected"] etc.
```

### Schema Keys

| Key | Schema |
|-----|--------|
| `:ubl_invoice` | UBL 2.1 Invoice XSD |
| `:ubl_credit_note` | UBL 2.1 Credit Note XSD |
| `:cii` | CII D16B XSD |

XSD validation does **not** require Java — it uses Nokogiri's built-in XML Schema support.

## Typical Workflow

```ruby
require "zugpferd"
require "zugpferd/validation"

# 1. Build the invoice
invoice = build_invoice(params)

# 2. Serialize to XML
xml = Zugpferd::CII::Writer.new.write(invoice)

# 3. Validate (during development or for interactive input)
validator = Zugpferd::Validation::SchematronValidator.new(
  schemas_path: "vendor/schemas"
)
errors = validator.validate_all(xml, rule_sets: [:cen_cii, :xrechnung_cii])
fatals = errors.select { |e| e.flag == "fatal" }

if fatals.any?
  # Show errors to the user or log them
  fatals.each { |e| puts "[#{e.id}] #{e.text}" }
  raise "Invoice validation failed"
end

# 4. Embed into PDF (optional)
require "zugpferd/pdf"
Zugpferd::PDF::Embedder.new.embed(
  pdf_path: "input.pdf",
  xml: xml,
  output_path: "zugferd.pdf",
  conformance_level: "XRECHNUNG"  # must match the CIUS in customization_id
)
```
