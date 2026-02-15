---
outline: deep
---

# Validation

Validate XML invoices against XSD schemas and Schematron business rules. Loaded via `require "zugpferd/validation"` (not included by default).

## SchematronValidator

Validates XML against EN 16931 and XRechnung business rules using Saxon HE. Requires Java and the Saxon JARs from `bin/setup-schemas`.

```ruby
require "zugpferd/validation"

validator = Zugpferd::Validation::SchematronValidator.new(
  schemas_path: "vendor/schemas"
)
```

### `validate(xml_string, rule_set:) → Array<Result>`

Validates XML against a single Schematron rule set.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `xml_string` | `String` | XML to validate |
| `rule_set` | `Symbol` | `:cen_ubl`, `:cen_cii`, `:xrechnung_ubl`, or `:xrechnung_cii` |

**Returns:** `Array<Result>` — validation errors (empty if valid)

**Raises:** `TransformError` if Saxon fails, `ArgumentError` if XSLT or JAR files are missing

### `validate_all(xml_string, rule_sets:) → Array<Result>`

Validates XML against multiple rule sets and merges the results.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `xml_string` | `String` | XML to validate |
| `rule_sets` | `Array<Symbol>` | Rule sets to apply |

**Returns:** `Array<Result>` — merged validation errors

### Result Struct

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Business rule ID (e.g. `"BR-CO-25"`, `"BR-DE-2"`) |
| `location` | `String` | XPath location of the error |
| `text` | `String` | Human-readable error description |
| `flag` | `String` | Severity: `"fatal"` or `"warning"` |

### Rule Sets

| Key | Description |
|-----|-------------|
| `:cen_ubl` | EN 16931 rules for UBL |
| `:cen_cii` | EN 16931 rules for CII |
| `:xrechnung_ubl` | XRechnung CIUS rules for UBL |
| `:xrechnung_cii` | XRechnung CIUS rules for CII |

### Exceptions

**`SchematronValidator::TransformError`** — raised when Saxon fails to execute the XSLT transformation (e.g. Java not installed, malformed XML).

## SchemaValidator

Validates XML against XSD schemas using Nokogiri. Does **not** require Java.

```ruby
require "zugpferd/validation"

validator = Zugpferd::Validation::SchemaValidator.new(
  schemas_path: "vendor/schemas"
)
```

### `validate(xml_string, schema_key:) → Array<String>`

Validates XML against an XSD schema.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `xml_string` | `String` | XML to validate |
| `schema_key` | `Symbol` | `:ubl_invoice`, `:ubl_credit_note`, or `:cii` |

**Returns:** `Array<String>` — error messages (empty if valid)

### Schema Keys

| Key | XSD |
|-----|-----|
| `:ubl_invoice` | `UBL-Invoice-2.1.xsd` |
| `:ubl_credit_note` | `UBL-CreditNote-2.1.xsd` |
| `:cii` | `CrossIndustryInvoice_100pD16B.xsd` |

## Dependencies

| Validator | Requires | Installed via |
|-----------|----------|---------------|
| `SchemaValidator` | Nokogiri (bundled) | `gem install zugpferd` |
| `SchematronValidator` | Java + Saxon HE 12.5 | `bin/setup-schemas` |

Both validators need the schema files from `vendor/schemas/`, downloaded via `bin/setup-schemas`.
