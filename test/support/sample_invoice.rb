module SampleInvoice
  def build_sample_credit_note
    invoice = Zugpferd::Model::CreditNote.new(
      number: "TEST-001",
      issue_date: Date.new(2024, 1, 15),
      due_date: Date.new(2024, 1, 25),
    )

    invoice.customization_id = "urn:oasis:names:specification:ubl:xpath:CreditNote-2.0:sbs-1.0-draft"
    invoice.profile_id = "bpid:urn:oasis:names:draft:bpss:ubl-2-sbs-credit-notification-draft"

    set_sample_attributes(invoice)
  end


  def build_sample_invoice
    invoice = Zugpferd::Model::Invoice.new(
      number: "TEST-001",
      issue_date: Date.new(2024, 1, 15),
      due_date: Date.new(2024, 1, 25),
    )

    invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
    invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

    set_sample_attributes(invoice)
  end

  def set_sample_attributes(invoice)
    invoice.currency_code = "EUR"
    invoice.buyer_reference = "BUYER-REF"
    invoice.seller = Zugpferd::Model::TradeParty.new(name: "Test Seller GmbH")
    invoice.seller.vat_identifier = "DE123456789"
    invoice.seller.electronic_address = "seller@example.com"
    invoice.seller.electronic_address_scheme = "EM"
    invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE",
      city_name: "Berlin",
      postal_zone: "10115",
      street_name: "Teststr. 1"
      )
    invoice.seller.contact = Zugpferd::Model::Contact.new(
      name: "Sample contact",
      telephone: "+49 12345678",
      email: "seller@example.com",
    )

    invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Test Buyer AG")
    invoice.buyer.electronic_address = "buyer@example.com"
    invoice.buyer.electronic_address_scheme = "EM"
    invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE",
      city_name: "Munich",
      postal_zone: "80331"
    )

    line = Zugpferd::Model::LineItem.new(
      id: "1",
      invoiced_quantity: "1",
      unit_code: "C62",
      line_extension_amount: "100.00"
    )
    line.item = Zugpferd::Model::Item.new(
      name: "Test Item",
      tax_category: "S",
      tax_percent: BigDecimal("19")
    )
    line.price = Zugpferd::Model::Price.new(amount: "100.00")
    invoice.line_items << line

    invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(
      tax_amount: "19.00",
      currency_code: "EUR"
    )
    invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
      taxable_amount: "100.00",
      tax_amount: "19.00",
      category_code: "S",
      currency_code: "EUR",
      percent: BigDecimal("19")
    )

    invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
      line_extension_amount: "100.00",
      tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "119.00",
      payable_amount: "119.00"
    )

    invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "58",
      account_id: "DE89370400440532013000"
    )

    invoice
  end
end
