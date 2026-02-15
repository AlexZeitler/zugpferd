---
outline: deep
---

# Writing Invoices

Build an invoice from scratch using the data model and write it to XML.

## Building an Invoice

```ruby
require "zugpferd"
require "bigdecimal"

invoice = Zugpferd::Model::Invoice.new(
  number: "INV-2024-001",
  issue_date: Date.new(2024, 1, 15),
  currency_code: "EUR"
)

invoice.buyer_reference = "BUYER-REF-123"
invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

# Seller
invoice.seller = Zugpferd::Model::TradeParty.new(name: "Seller GmbH")
invoice.seller.vat_identifier = "DE123456789"
invoice.seller.electronic_address = "seller@example.com"
invoice.seller.electronic_address_scheme = "EM"
invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
  country_code: "DE",
  city_name: "Frankfurt am Main",
  postal_zone: "60311",
  street_name: "Hauptstr. 1"
)

# Buyer
invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Buyer AG")
invoice.buyer.electronic_address = "buyer@example.com"
invoice.buyer.electronic_address_scheme = "EM"
invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
  country_code: "DE",
  city_name: "Munich",
  postal_zone: "80331"
)

# Line item
line = Zugpferd::Model::LineItem.new(
  id: "1",
  invoiced_quantity: "10",
  unit_code: "C62",
  line_extension_amount: "1000.00"
)
line.item = Zugpferd::Model::Item.new(
  name: "Consulting Services",
  tax_category: "S",
  tax_percent: BigDecimal("19")
)
line.price = Zugpferd::Model::Price.new(amount: "100.00")
invoice.line_items << line

# Tax breakdown
invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(
  tax_amount: "190.00",
  currency_code: "EUR"
)
invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
  taxable_amount: "1000.00",
  tax_amount: "190.00",
  category_code: "S",
  currency_code: "EUR",
  percent: BigDecimal("19")
)

# Monetary totals
invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
  line_extension_amount: "1000.00",
  tax_exclusive_amount: "1000.00",
  tax_inclusive_amount: "1190.00",
  payable_amount: "1190.00"
)

# Payment
invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
  payment_means_code: "58",
  account_id: "DE89370400440532013000"
)
```

## Document Types

The `type_code` attribute controls the document type:

Each document type has its own class with a default `type_code`:

```ruby
# Commercial Invoice (type_code: "380")
invoice = Zugpferd::Model::Invoice.new(number: "INV-001", issue_date: Date.today)

# Credit Note (type_code: "381") — UBL writer generates <CreditNote> root element
credit_note = Zugpferd::Model::CreditNote.new(number: "CN-001", issue_date: Date.today)

# Corrected Invoice (type_code: "384")
corrected = Zugpferd::Model::CorrectedInvoice.new(number: "CORR-001", issue_date: Date.today)

# Self-billed Invoice (type_code: "389")
self_billed = Zugpferd::Model::SelfBilledInvoice.new(number: "SB-001", issue_date: Date.today)

# Partial Invoice (type_code: "326")
partial = Zugpferd::Model::PartialInvoice.new(number: "P-001", issue_date: Date.today)

# Prepayment Invoice (type_code: "386")
prepayment = Zugpferd::Model::PrepaymentInvoice.new(number: "PRE-001", issue_date: Date.today)
```

| Class | Code | Description |
|-------|------|-------------|
| `Invoice` | `380` | Commercial Invoice |
| `CreditNote` | `381` | Credit Note |
| `CorrectedInvoice` | `384` | Corrected Invoice |
| `SelfBilledInvoice` | `389` | Self-billed Invoice |
| `PartialInvoice` | `326` | Partial Invoice |
| `PrepaymentInvoice` | `386` | Prepayment Invoice |

## Writing to UBL

```ruby
xml = Zugpferd::UBL::Writer.new.write(invoice)
File.write("invoice_ubl.xml", xml)
```

## Writing to CII

```ruby
xml = Zugpferd::CII::Writer.new.write(invoice)
File.write("invoice_cii.xml", xml)
```

## Format Conversion

Convert between UBL and CII by reading one format and writing the other:

```ruby
# CII to UBL
invoice = Zugpferd::CII::Reader.new.read(cii_xml)
ubl_xml = Zugpferd::UBL::Writer.new.write(invoice)

# UBL to CII
invoice = Zugpferd::UBL::Reader.new.read(ubl_xml)
cii_xml = Zugpferd::CII::Writer.new.write(invoice)
```
