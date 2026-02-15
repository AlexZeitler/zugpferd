---
outline: deep
---

# CII Reader / Writer

Read and write invoices in UN/CEFACT Cross-Industry Invoice (CII) format, as used by ZUGFeRD and XRechnung.

## Reader

```ruby
reader = Zugpferd::CII::Reader.new
invoice = reader.read(xml_string)
```

### `read(xml_string) → BillingDocument`

Parses a CII D16B XML string and returns the appropriate model class based on the type code (e.g. `CreditNote` for 381, `CorrectedInvoice` for 384). Falls back to `Invoice` for type code 380 and unknown codes.

**Parameters:**
- `xml_string` (`String`) — Valid CII CrossIndustryInvoice XML

**Returns:** `Zugpferd::Model::Invoice`, `Zugpferd::Model::CreditNote`, or other `BillingDocument` subtype

**Raises:** `Nokogiri::XML::SyntaxError` if the XML is malformed

## Writer

```ruby
writer = Zugpferd::CII::Writer.new
xml_string = writer.write(invoice)
```

### `write(invoice) → String`

Serializes a billing document to a CII CrossIndustryInvoice XML string.

**Parameters:**
- `invoice` (`Zugpferd::Model::BillingDocument`) — The document to serialize

**Returns:** `String` — UTF-8 encoded XML

## CII Namespaces

| Prefix | URI |
|--------|-----|
| `rsm` | `urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100` |
| `ram` | `urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100` |
| `udt` | `urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100` |
| `qdt` | `urn:un:unece:uncefact:data:standard:QualifiedDataType:100` |

## CII-Specific Notes

- Dates use format code `102` (YYYYMMDD), e.g. `20240115`
- The creditor reference identifier (BT-90) is at the settlement level as `ram:CreditorReferenceID`
- The mandate reference (BT-89) is inside `ram:SpecifiedTradePaymentTerms/ram:DirectDebitMandateID`
- Tax information on line items is in `ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax`, not in `ram:SpecifiedTradeProduct`
- The charge indicator uses `udt:Indicator` with string values `"true"` / `"false"`
