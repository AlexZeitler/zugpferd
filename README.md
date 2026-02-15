# Zugpferd

A Ruby library for reading and writing electronic invoices according to **EN 16931**, supporting both **UBL 2.1** and **UN/CEFACT CII** syntaxes.

Built for Ruby developers integrating XRechnung or ZUGFeRD into their applications.

## Features

- Syntax-agnostic data model based on EN 16931 Business Terms (BTs)
- UBL 2.1 Reader & Writer (Invoice and Credit Note)
- UN/CEFACT CII Reader & Writer
- Supported document types:
  - `380` — Commercial Invoice
  - `381` — Credit Note (UBL: separate `<CreditNote>` root element)
  - `384` — Corrected Invoice
  - `389` — Self-billed Invoice
  - `326` — Partial Invoice
  - `386` — Prepayment Invoice
- No Java runtime dependency, no Rails dependency
- BigDecimal for all monetary amounts

## Installation

```ruby
# Gemfile
gem "zugpferd"
```

```bash
bundle install
```

Or install directly:

```bash
gem install zugpferd
```

## Usage

### Reading a UBL invoice

```ruby
require "zugpferd"

xml = File.read("invoice_ubl.xml")
invoice = Zugpferd::UBL::Reader.new.read(xml)

puts invoice.number          # BT-1
puts invoice.seller.name     # BG-4
puts invoice.type_code       # "380", "381", etc.

invoice.line_items.each do |line|
  puts "#{line.item.name}: #{line.line_extension_amount}"
end
```

### Reading a CII invoice

```ruby
xml = File.read("invoice_cii.xml")
invoice = Zugpferd::CII::Reader.new.read(xml)
```

The data model is identical regardless of whether UBL or CII is used.

### Writing a UBL invoice

```ruby
invoice = Zugpferd::Model::Invoice.new(
  number: "INV-2024-001",
  issue_date: Date.today,
  type_code: "380",
  currency_code: "EUR",
)

invoice.seller = Zugpferd::Model::TradeParty.new(name: "Seller GmbH")
invoice.buyer  = Zugpferd::Model::TradeParty.new(name: "Buyer AG")

# ... set line items, tax, totals, payment ...

xml = Zugpferd::UBL::Writer.new.write(invoice)
File.write("output.xml", xml)
```

### Writing a Credit Note

```ruby
credit_note = Zugpferd::Model::CreditNote.new(
  number: "CN-2024-001",
  issue_date: Date.today,
)

# The writer automatically generates <CreditNote> instead of <Invoice>
xml = Zugpferd::UBL::Writer.new.write(credit_note)
```

### Converting between syntaxes

```ruby
# Read CII, write as UBL
invoice = Zugpferd::CII::Reader.new.read(cii_xml)
ubl_xml = Zugpferd::UBL::Writer.new.write(invoice)
```

## Data Model

The model maps to the Business Groups of EN 16931:

| Class | Business Group | Description |
|-------|---------------|-------------|
| `Model::Invoice` | BG-0 | Commercial Invoice (380) |
| `Model::CreditNote` | BG-0 | Credit Note (381) |
| `Model::CorrectedInvoice` | BG-0 | Corrected Invoice (384) |
| `Model::SelfBilledInvoice` | BG-0 | Self-billed Invoice (389) |
| `Model::PartialInvoice` | BG-0 | Partial Invoice (326) |
| `Model::PrepaymentInvoice` | BG-0 | Prepayment Invoice (386) |
| `Model::TradeParty` | BG-4 / BG-7 | Seller / Buyer |
| `Model::PostalAddress` | BG-5 / BG-8 | Postal address |
| `Model::Contact` | BG-6 / BG-9 | Contact information |
| `Model::LineItem` | BG-25 | Invoice line |
| `Model::Item` | BG-31 | Item information |
| `Model::Price` | BG-29 | Price details |
| `Model::MonetaryTotals` | BG-22 | Document totals |
| `Model::TaxBreakdown` | BG-23 | VAT breakdown |
| `Model::PaymentInstructions` | BG-16 | Payment information |
| `Model::AllowanceCharge` | BG-20 / BG-21 | Allowances and charges |

## Requirements

- Ruby >= 3.2
- nokogiri ~> 1.16
- bigdecimal ~> 3.1

## Development

```bash
bundle install
bin/setup-schemas    # Downloads XSD schemas, CEN Schematron, XRechnung test suite
bundle exec rake test
```

## License

MIT
