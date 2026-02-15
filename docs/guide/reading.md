---
outline: deep
---

# Reading Documents

Zugpferd can read XRechnung and ZUGFeRD documents in both UBL 2.1 and UN/CEFACT CII into the same data model.

## UBL Documents

The UBL reader automatically detects the document type from the root element and returns the appropriate model class:

```ruby
xml = File.read("invoice_ubl.xml")
doc = Zugpferd::UBL::Reader.new.read(xml)
doc.class      # => Zugpferd::Model::Invoice or Zugpferd::Model::CreditNote
doc.type_code  # => "380" for Invoice, "381" for CreditNote
```

## CII Documents

The CII reader maps the type code to the appropriate model class (e.g. `CreditNote` for 381, `CorrectedInvoice` for 384):

```ruby
xml = File.read("invoice_cii.xml")
doc = Zugpferd::CII::Reader.new.read(xml)
doc.class  # => Zugpferd::Model::Invoice, Zugpferd::Model::CreditNote, etc.
```

## Accessing Document Data

After reading, all document types share the same attributes:

```ruby
# Header
doc.number            # BT-1: Document number
doc.issue_date        # BT-2: Issue date (Date object)
doc.due_date          # BT-9: Due date (Date object)
doc.type_code         # BT-3: Document type code (e.g. "380")
doc.currency_code     # BT-5: Currency code (e.g. "EUR")
doc.buyer_reference   # BT-10: Buyer reference
doc.note              # BT-22: Document note

# Parties
doc.seller.name                    # BT-27: Seller name
doc.seller.vat_identifier          # BT-31: Seller VAT identifier
doc.seller.postal_address.city_name  # BT-37: Seller city
doc.buyer.name                     # BT-44: Buyer name

# Line items
doc.line_items.each do |line|
  line.id                    # BT-126: Line identifier
  line.invoiced_quantity     # BT-129: Quantity
  line.unit_code             # BT-130: Unit code
  line.line_extension_amount # BT-131: Line total
  line.item.name             # BT-153: Item name
  line.price.amount          # BT-146: Item net price
end

# Totals
totals = doc.monetary_totals
totals.line_extension_amount   # BT-106: Sum of line totals
totals.tax_exclusive_amount    # BT-109: Total without VAT
totals.tax_inclusive_amount    # BT-112: Total with VAT
totals.payable_amount          # BT-115: Amount due

# Tax breakdown
doc.tax_breakdown.subtotals.each do |sub|
  sub.taxable_amount   # BT-116: Tax base amount
  sub.tax_amount       # BT-117: Tax amount
  sub.category_code    # BT-118: Tax category (e.g. "S")
  sub.percent          # BT-119: Tax rate
end
```

## Monetary Values

All monetary values are `BigDecimal`:

```ruby
doc.monetary_totals.payable_amount.class  # => BigDecimal
```
