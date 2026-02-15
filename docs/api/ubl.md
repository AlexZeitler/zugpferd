---
outline: deep
---

# UBL Reader / Writer

Read and write invoices in UBL 2.1 (OASIS) format, as used by XRechnung and PEPPOL BIS.

## Reader

```ruby
reader = Zugpferd::UBL::Reader.new
invoice = reader.read(xml_string)
```

### `read(xml_string) → Invoice`

Parses a UBL 2.1 Invoice XML string and returns a `Zugpferd::Model::Invoice`.

**Parameters:**
- `xml_string` (`String`) — Valid UBL 2.1 Invoice XML

**Returns:** `Zugpferd::Model::Invoice`

**Raises:** `Nokogiri::XML::SyntaxError` if the XML is malformed

## Writer

```ruby
writer = Zugpferd::UBL::Writer.new
xml_string = writer.write(invoice)
```

### `write(invoice) → String`

Serializes a `Zugpferd::Model::Invoice` to a UBL 2.1 Invoice XML string.

**Parameters:**
- `invoice` (`Zugpferd::Model::Invoice`) — The invoice to serialize

**Returns:** `String` — UTF-8 encoded XML

## UBL Namespaces

The generated XML uses these namespaces:

| Prefix | URI |
|--------|-----|
| (default) | `urn:oasis:names:specification:ubl:schema:xsd:Invoice-2` |
| `cac` | `urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2` |
| `cbc` | `urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2` |

## UBL-Specific Notes

- Dates are formatted as ISO 8601 (`YYYY-MM-DD`)
- The creditor reference identifier (BT-90) is mapped to `cac:PartyIdentification/cbc:ID[@schemeID='SEPA']` on the seller party
- `cac:CardAccount/cbc:NetworkID` is required by the UBL schema; when converting from CII (which lacks this field), it defaults to `"mapped-from-cii"`
