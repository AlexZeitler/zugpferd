---
outline: deep
---

# Getting Started

Zugpferd is a Ruby library for reading and writing XRechnung and ZUGFeRD electronic invoices (e-Rechnung) according to EN 16931.

## Installation

Add Zugpferd to your Gemfile:

```ruby
gem "zugpferd"
```

Then run:

```bash
bundle install
```

## Requirements

- Ruby >= 3.2
- [Nokogiri](https://nokogiri.org/) ~> 1.16

## Quick Example

```ruby
require "zugpferd"

# Read a UBL invoice
xml = File.read("invoice.xml")
invoice = Zugpferd::UBL::Reader.new.read(xml)

puts invoice.number        # => "INV-2024-001"
puts invoice.seller.name   # => "Seller GmbH"
puts invoice.monetary_totals.payable_amount  # => 1190.00

# Write it back
output = Zugpferd::UBL::Writer.new.write(invoice)
File.write("output.xml", output)
```

## CII Format

The same workflow works with UN/CEFACT CII invoices:

```ruby
xml = File.read("invoice_cii.xml")
invoice = Zugpferd::CII::Reader.new.read(xml)
output = Zugpferd::CII::Writer.new.write(invoice)
```

## Format Conversion

Since both formats share the same data model, you can convert between UBL and CII:

```ruby
# Read CII, write UBL
invoice = Zugpferd::CII::Reader.new.read(cii_xml)
ubl_xml = Zugpferd::UBL::Writer.new.write(invoice)
```
