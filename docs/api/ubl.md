---
outline: deep
---

# UBL Reader / Writer

Read and write invoices in UBL 2.1 (OASIS) format, as used by XRechnung and PEPPOL BIS. Supports both `<Invoice>` and `<CreditNote>` documents.

## Reader

```ruby
reader = Zugpferd::UBL::Reader.new
invoice = reader.read(xml_string)
```

### `read(xml_string) → BillingDocument`

Parses a UBL 2.1 Invoice or Credit Note XML string and returns the appropriate model class. Credit Notes (`<CreditNote>` root element) return a `Zugpferd::Model::CreditNote`, all others return a `Zugpferd::Model::Invoice`.

**Parameters:**
- `xml_string` (`String`) — Valid UBL 2.1 Invoice or Credit Note XML

**Returns:** `Zugpferd::Model::Invoice` or `Zugpferd::Model::CreditNote`

**Raises:** `Nokogiri::XML::SyntaxError` if the XML is malformed

## Writer

```ruby
writer = Zugpferd::UBL::Writer.new
xml_string = writer.write(invoice)
```

### `write(invoice) → String`

Serializes a billing document to UBL 2.1 XML. When `type_code` is `"381"`, the writer generates a `<CreditNote>` document. All other type codes produce an `<Invoice>` document.

**Parameters:**
- `invoice` (`Zugpferd::Model::BillingDocument`) — The document to serialize

**Returns:** `String` — UTF-8 encoded XML

## Credit Note Support

Credit Notes (`type_code: "381"`) use a different UBL structure:

| Element | Invoice | Credit Note |
|---------|---------|-------------|
| Root element | `<Invoice>` | `<CreditNote>` |
| Namespace | `...Invoice-2` | `...CreditNote-2` |
| Type code element | `cbc:InvoiceTypeCode` | `cbc:CreditNoteTypeCode` |
| Line element | `cac:InvoiceLine` | `cac:CreditNoteLine` |
| Quantity element | `cbc:InvoicedQuantity` | `cbc:CreditedQuantity` |

Everything else (parties, totals, tax, payment, allowances/charges) is identical.

```ruby
# Writing a credit note
credit_note = Zugpferd::Model::CreditNote.new(
  number: "CN-001",
  issue_date: Date.today,
)
xml = Zugpferd::UBL::Writer.new.write(credit_note)
# => <CreditNote xmlns="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2" ...>
```

## UBL Namespaces

**Invoice** (`type_code` other than `"381"`):

| Prefix | URI |
|--------|-----|
| (default) | `urn:oasis:names:specification:ubl:schema:xsd:Invoice-2` |
| `cac` | `urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2` |
| `cbc` | `urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2` |

**Credit Note** (`type_code: "381"`):

| Prefix | URI |
|--------|-----|
| (default) | `urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2` |
| `cac` | `urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2` |
| `cbc` | `urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2` |

## UBL-Specific Notes

- Dates are formatted as ISO 8601 (`YYYY-MM-DD`)
- The creditor reference identifier (BT-90) is mapped to `cac:PartyIdentification/cbc:ID[@schemeID='SEPA']` on the seller party
- `cac:CardAccount/cbc:NetworkID` is required by the UBL schema; when converting from CII (which lacks this field), it defaults to `"mapped-from-cii"`
