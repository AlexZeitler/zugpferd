---
outline: deep
---

# Data Model

All model classes live under `Zugpferd::Model` and map to EN 16931 Business Groups (BGs) and Business Terms (BTs). Monetary values are `BigDecimal`, dates are `Date` objects.

## Invoice (BG-0)

The root document.

```ruby
invoice = Zugpferd::Model::Invoice.new(
  number: "INV-001",       # BT-1 (required)
  issue_date: Date.today,  # BT-2 (required)
  type_code: "380",        # BT-3 (default: "380")
  currency_code: "EUR"     # BT-5 (default: "EUR")
)
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `number` | BT-1 | `String` | Invoice number |
| `issue_date` | BT-2 | `Date` | Issue date |
| `due_date` | BT-9 | `Date` | Payment due date |
| `type_code` | BT-3 | `String` | Invoice type code |
| `currency_code` | BT-5 | `String` | Document currency |
| `buyer_reference` | BT-10 | `String` | Buyer reference |
| `customization_id` | BT-24 | `String` | Specification identifier |
| `profile_id` | BT-23 | `String` | Business process type |
| `note` | BT-22 | `String` | Invoice note |
| `seller` | BG-4 | `TradeParty` | Seller party |
| `buyer` | BG-7 | `TradeParty` | Buyer party |
| `line_items` | BG-25 | `Array<LineItem>` | Invoice lines |
| `allowance_charges` | BG-20/21 | `Array<AllowanceCharge>` | Document-level allowances/charges |
| `tax_breakdown` | BG-23 | `TaxBreakdown` | VAT breakdown |
| `monetary_totals` | BG-22 | `MonetaryTotals` | Document totals |
| `payment_instructions` | BG-16 | `PaymentInstructions` | Payment information |

## TradeParty (BG-4 / BG-7)

Seller or buyer party.

```ruby
party = Zugpferd::Model::TradeParty.new(name: "Company GmbH")
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `name` | BT-27/44 | `String` | Legal name (required) |
| `trading_name` | BT-28/45 | `String` | Trading name |
| `identifier` | BT-29/46 | `String` | Party identifier |
| `legal_registration_id` | BT-30/47 | `String` | Legal registration ID |
| `legal_form` | BT-33 | `String` | Company legal form |
| `vat_identifier` | BT-31/48 | `String` | VAT identifier |
| `electronic_address` | BT-34/49 | `String` | Electronic address |
| `electronic_address_scheme` | BT-34-1/49-1 | `String` | Scheme ID (e.g. "EM") |
| `postal_address` | BG-5/8 | `PostalAddress` | Postal address |
| `contact` | BG-6/9 | `Contact` | Contact information |

## PostalAddress (BG-5 / BG-8)

```ruby
addr = Zugpferd::Model::PostalAddress.new(country_code: "DE")
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `country_code` | BT-40/55 | `String` | Country code (required) |
| `street_name` | BT-35/50 | `String` | Street |
| `city_name` | BT-37/52 | `String` | City |
| `postal_zone` | BT-38/53 | `String` | Postal code |

## Contact (BG-6 / BG-9)

```ruby
contact = Zugpferd::Model::Contact.new
contact.name = "Max Mustermann"
contact.telephone = "+49 30 12345"
contact.email = "max@example.com"
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `name` | BT-41/56 | `String` | Contact name |
| `telephone` | BT-42/57 | `String` | Telephone |
| `email` | BT-43/58 | `String` | Email |

## LineItem (BG-25)

```ruby
line = Zugpferd::Model::LineItem.new(
  id: "1",
  invoiced_quantity: "10",
  unit_code: "C62",
  line_extension_amount: "1000.00"
)
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `id` | BT-126 | `String` | Line identifier (required) |
| `invoiced_quantity` | BT-129 | `String` | Quantity (required) |
| `unit_code` | BT-130 | `String` | Unit code (required) |
| `line_extension_amount` | BT-131 | `String` | Line total (required) |
| `note` | BT-127 | `String` | Line note |
| `item` | BG-31 | `Item` | Item information |
| `price` | BG-29 | `Price` | Price details |

## Item (BG-31)

```ruby
item = Zugpferd::Model::Item.new(name: "Widget")
item.tax_category = "S"
item.tax_percent = BigDecimal("19")
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `name` | BT-153 | `String` | Item name (required) |
| `description` | BT-154 | `String` | Item description |
| `sellers_identifier` | BT-155 | `String` | Seller's item ID |
| `tax_category` | BT-151 | `String` | Tax category code |
| `tax_percent` | BT-152 | `BigDecimal` | Tax rate |

## Price (BG-29)

```ruby
price = Zugpferd::Model::Price.new(amount: "100.00")
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `amount` | BT-146 | `String` | Item net price (required) |

## MonetaryTotals (BG-22)

```ruby
totals = Zugpferd::Model::MonetaryTotals.new(
  line_extension_amount: "1000.00",
  tax_exclusive_amount: "1000.00",
  tax_inclusive_amount: "1190.00",
  payable_amount: "1190.00"
)
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `line_extension_amount` | BT-106 | `String` | Sum of line totals (required) |
| `tax_exclusive_amount` | BT-109 | `String` | Total without VAT (required) |
| `tax_inclusive_amount` | BT-112 | `String` | Total with VAT (required) |
| `payable_amount` | BT-115 | `String` | Amount due (required) |
| `prepaid_amount` | BT-113 | `BigDecimal` | Prepaid amount |
| `payable_rounding_amount` | BT-114 | `BigDecimal` | Rounding amount |
| `allowance_total_amount` | BT-107 | `BigDecimal` | Total allowances |
| `charge_total_amount` | BT-108 | `BigDecimal` | Total charges |

## TaxBreakdown (BG-23)

```ruby
breakdown = Zugpferd::Model::TaxBreakdown.new(
  tax_amount: "190.00",
  currency_code: "EUR"
)
breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(...)
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `tax_amount` | BT-110 | `String` | Total tax amount (required) |
| `currency_code` | BT-110-1 | `String` | Tax currency (required) |
| `subtotals` | — | `Array<TaxSubtotal>` | Tax subtotals |

## TaxSubtotal

```ruby
sub = Zugpferd::Model::TaxSubtotal.new(
  taxable_amount: "1000.00",
  tax_amount: "190.00",
  category_code: "S",
  currency_code: "EUR",
  percent: BigDecimal("19")
)
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `taxable_amount` | BT-116 | `String` | Tax base (required) |
| `tax_amount` | BT-117 | `String` | Tax amount (required) |
| `category_code` | BT-118 | `String` | Tax category code (required) |
| `currency_code` | — | `String` | Currency (required) |
| `percent` | BT-119 | `BigDecimal` | Tax rate |
| `exemption_reason` | BT-120 | `String` | Exemption reason |
| `exemption_reason_code` | BT-121 | `String` | Exemption reason code |

## PaymentInstructions (BG-16)

```ruby
payment = Zugpferd::Model::PaymentInstructions.new(
  payment_means_code: "58"
)
payment.account_id = "DE89370400440532013000"
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `payment_means_code` | BT-81 | `String` | Payment means code (required) |
| `payment_id` | BT-83 | `String` | Payment reference |
| `account_id` | BT-84 | `String` | IBAN |
| `note` | BT-82 | `String` | Payment terms note |
| `card_account_id` | BT-87 | `String` | Payment card number |
| `card_holder_name` | BT-88 | `String` | Card holder name |
| `card_network_id` | — | `String` | Card network (UBL only) |
| `mandate_reference` | BT-89 | `String` | Direct debit mandate reference |
| `creditor_reference_id` | BT-90 | `String` | Bank assigned creditor ID |
| `debited_account_id` | BT-91 | `String` | Debited account IBAN |

## AllowanceCharge (BG-20 / BG-21)

```ruby
charge = Zugpferd::Model::AllowanceCharge.new(
  charge_indicator: true,
  amount: "50.00"
)
charge.reason = "Service charge"
charge.tax_category_code = "S"
charge.tax_percent = BigDecimal("19")
```

| Attribute | BT | Type | Description |
|-----------|-----|------|-------------|
| `charge_indicator` | BT-92/95 | `Boolean` | `true` = charge, `false` = allowance (required) |
| `amount` | BT-92/99 | `BigDecimal` | Amount (required) |
| `reason` | BT-97/104 | `String` | Reason |
| `reason_code` | BT-98/105 | `String` | Reason code |
| `base_amount` | BT-93/100 | `BigDecimal` | Base amount |
| `multiplier_factor` | BT-94/101 | `BigDecimal` | Percentage |
| `tax_category_code` | BT-95/102 | `String` | Tax category |
| `tax_percent` | BT-96/103 | `BigDecimal` | Tax rate |
