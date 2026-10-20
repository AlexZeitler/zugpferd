require "test_helper"

class CIIWriterTest < Minitest::Test
  include XmlHelper
  include Zugpferd::Model

  SETTLEMENT = "//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement".freeze
  SELLER = "//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty".freeze
  LINE = "//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem".freeze

  def test_writes_cross_industry_invoice_root_with_namespaces
    root = write(minimal_invoice).root

    assert_equal "CrossIndustryInvoice", root.name
    assert_equal CII_NS["rsm"], root.namespace.href
    assert_equal "urn:un:unece:uncefact:data:standard:QualifiedDataType:100", root.namespaces["xmlns:qdt"]
  end

  def test_writes_exchanged_document
    doc = write(minimal_invoice)

    assert_equal "RE-1", text(doc, "//rsm:ExchangedDocument/ram:ID")
    assert_equal "380", text(doc, "//rsm:ExchangedDocument/ram:TypeCode")
    date = doc.at_xpath("//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString", CII_NS)
    assert_equal "20240615", date.text
    assert_equal "102", date["format"]
  end

  def test_writes_type_code_of_credit_note
    credit_note = CreditNote.new(number: "GS-1", issue_date: Date.new(2024, 6, 15))

    assert_equal "381", text(write(credit_note), "//rsm:ExchangedDocument/ram:TypeCode")
  end

  def test_writes_note
    invoice = minimal_invoice
    invoice.note = "Thanks"

    assert_equal "Thanks", text(write(invoice), "//rsm:ExchangedDocument/ram:IncludedNote/ram:Content")
  end

  def test_omits_note_when_not_set
    assert_nil write(minimal_invoice).at_xpath("//ram:IncludedNote", CII_NS)
  end

  def test_writes_document_context
    invoice = minimal_invoice
    invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"
    invoice.customization_id = "urn:cen.eu:en16931:2017"
    doc = write(invoice)

    assert_equal "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0",
                 text(doc, "//rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID")
    assert_equal "urn:cen.eu:en16931:2017",
                 text(doc, "//rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID")
  end

  def test_writes_empty_document_context_when_ids_not_set
    context = write(minimal_invoice).at_xpath("//rsm:ExchangedDocumentContext", CII_NS)

    assert_empty context.element_children
  end

  def test_writes_transaction_parts_in_order
    transaction = write(full_invoice).at_xpath("//rsm:SupplyChainTradeTransaction", CII_NS)

    assert_equal %w[
      IncludedSupplyChainTradeLineItem ApplicableHeaderTradeAgreement
      ApplicableHeaderTradeDelivery ApplicableHeaderTradeSettlement
    ], child_names(transaction)
  end

  def test_writes_buyer_reference
    assert_equal "04011000-12345-34",
                 text(write(full_invoice), "//ram:ApplicableHeaderTradeAgreement/ram:BuyerReference")
  end

  def test_writes_party_elements_in_order
    seller = write(full_invoice).at_xpath(SELLER, CII_NS)

    assert_equal %w[
      ID Name Description SpecifiedLegalOrganization DefinedTradeContact
      PostalTradeAddress URIUniversalCommunication SpecifiedTaxRegistration
    ], child_names(seller)
  end

  def test_writes_party_values
    doc = write(full_invoice)

    assert_equal "S-1", text(doc, "#{SELLER}/ram:ID")
    assert_equal "Seller GmbH", text(doc, "#{SELLER}/ram:Name")
    assert_equal "GmbH", text(doc, "#{SELLER}/ram:Description")
    assert_equal "HRB 1234", text(doc, "#{SELLER}/ram:SpecifiedLegalOrganization/ram:ID")
    assert_equal "Seller", text(doc, "#{SELLER}/ram:SpecifiedLegalOrganization/ram:TradingBusinessName")
    assert_equal "DE123456789", text(doc, "#{SELLER}/ram:SpecifiedTaxRegistration/ram:ID")
    assert_equal "VA", doc.at_xpath("#{SELLER}/ram:SpecifiedTaxRegistration/ram:ID", CII_NS)["schemeID"]
  end

  def test_writes_party_electronic_address_with_scheme
    uri = write(full_invoice).at_xpath("#{SELLER}/ram:URIUniversalCommunication/ram:URIID", CII_NS)

    assert_equal "seller@example.com", uri.text
    assert_equal "EM", uri["schemeID"]
  end

  def test_writes_party_contact
    contact = write(full_invoice).at_xpath("#{SELLER}/ram:DefinedTradeContact", CII_NS)

    assert_equal "Max Muster", text(contact, "ram:PersonName")
    assert_equal "+49 30 123", text(contact, "ram:TelephoneUniversalCommunication/ram:CompleteNumber")
    assert_equal "max@example.com", text(contact, "ram:EmailURIUniversalCommunication/ram:URIID")
  end

  def test_writes_postal_address_elements_in_order
    address = write(full_invoice).at_xpath("#{SELLER}/ram:PostalTradeAddress", CII_NS)

    assert_equal %w[PostcodeCode LineOne CityName CountryID], child_names(address)
    assert_equal %w[10115 Hauptstr.\ 1 Berlin DE], address.element_children.map(&:text)
  end

  def test_writes_minimal_party_with_name_only
    invoice = minimal_invoice
    invoice.buyer = TradeParty.new(name: "Buyer AG")
    buyer = write(invoice).at_xpath("//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty", CII_NS)

    assert_equal %w[Name], child_names(buyer)
  end

  def test_writes_empty_agreement_without_parties
    agreement = write(minimal_invoice).at_xpath("//ram:ApplicableHeaderTradeAgreement", CII_NS)

    assert_empty agreement.element_children
  end

  def test_writes_delivery_date
    date = write(full_invoice).at_xpath(
      "//ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString",
      CII_NS
    )

    assert_equal "20240610", date.text
    assert_equal "102", date["format"]
  end

  def test_writes_empty_delivery_without_delivery_date
    delivery = write(minimal_invoice).at_xpath("//ram:ApplicableHeaderTradeDelivery", CII_NS)

    assert_empty delivery.element_children
  end

  def test_writes_settlement_elements_in_order
    settlement = write(full_invoice).at_xpath(SETTLEMENT, CII_NS)

    assert_equal %w[
      CreditorReferenceID PaymentReference InvoiceCurrencyCode SpecifiedTradeSettlementPaymentMeans
      ApplicableTradeTax SpecifiedTradeAllowanceCharge SpecifiedTradeAllowanceCharge
      SpecifiedTradePaymentTerms SpecifiedTradeSettlementHeaderMonetarySummation
    ], child_names(settlement)
  end

  def test_writes_settlement_references_and_currency
    doc = write(full_invoice)

    assert_equal "DE98ZZZ09999999999", text(doc, "#{SETTLEMENT}/ram:CreditorReferenceID")
    assert_equal "RE-1", text(doc, "#{SETTLEMENT}/ram:PaymentReference")
    assert_equal "EUR", text(doc, "#{SETTLEMENT}/ram:InvoiceCurrencyCode")
  end

  def test_writes_only_currency_in_minimal_settlement
    settlement = write(minimal_invoice).at_xpath(SETTLEMENT, CII_NS)

    assert_equal %w[InvoiceCurrencyCode], child_names(settlement)
  end

  def test_writes_payment_means
    means = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeSettlementPaymentMeans", CII_NS)

    assert_equal %w[
      TypeCode ApplicableTradeSettlementFinancialCard
      PayerPartyDebtorFinancialAccount PayeePartyCreditorFinancialAccount
    ], child_names(means)
    assert_equal "58", text(means, "ram:TypeCode")
    assert_equal "1234", text(means, "ram:ApplicableTradeSettlementFinancialCard/ram:ID")
    assert_equal "Max Muster", text(means, "ram:ApplicableTradeSettlementFinancialCard/ram:CardholderName")
    assert_equal "DE02100100109307118603", text(means, "ram:PayerPartyDebtorFinancialAccount/ram:IBANID")
    assert_equal "DE89370400440532013000", text(means, "ram:PayeePartyCreditorFinancialAccount/ram:IBANID")
  end

  def test_writes_tax_subtotal
    tax = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:ApplicableTradeTax", CII_NS)

    assert_equal %w[CalculatedAmount TypeCode BasisAmount CategoryCode RateApplicablePercent], child_names(tax)
    assert_equal %w[19 VAT 100 S 19], tax.element_children.map(&:text)
  end

  def test_writes_tax_subtotal_exemption
    invoice = minimal_invoice
    invoice.tax_breakdown = TaxBreakdown.new(tax_amount: "0", currency_code: "EUR")
    invoice.tax_breakdown.subtotals << TaxSubtotal.new(
      taxable_amount: "100", tax_amount: "0", category_code: "E", currency_code: "EUR",
      exemption_reason: "Steuerbefreit", exemption_reason_code: "VATEX-EU-132"
    )
    tax = write(invoice).at_xpath("#{SETTLEMENT}/ram:ApplicableTradeTax", CII_NS)

    assert_equal %w[CalculatedAmount TypeCode ExemptionReason BasisAmount CategoryCode ExemptionReasonCode],
                 child_names(tax)
    assert_equal "Steuerbefreit", text(tax, "ram:ExemptionReason")
    assert_equal "VATEX-EU-132", text(tax, "ram:ExemptionReasonCode")
  end

  def test_writes_document_level_allowance
    allowance = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeAllowanceCharge[1]", CII_NS)

    assert_equal %w[
      ChargeIndicator CalculationPercent BasisAmount ActualAmount ReasonCode Reason CategoryTradeTax
    ], child_names(allowance)
    assert_equal "false", text(allowance, "ram:ChargeIndicator/udt:Indicator")
    assert_equal "5", text(allowance, "ram:CalculationPercent")
    assert_equal "100", text(allowance, "ram:BasisAmount")
    assert_equal "5", text(allowance, "ram:ActualAmount")
    assert_equal "95", text(allowance, "ram:ReasonCode")
    assert_equal "Rabatt", text(allowance, "ram:Reason")
    assert_equal %w[VAT S 19], allowance.at_xpath("ram:CategoryTradeTax", CII_NS).element_children.map(&:text)
  end

  def test_writes_document_level_charge
    charge = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeAllowanceCharge[2]", CII_NS)

    assert_equal %w[ChargeIndicator ActualAmount], child_names(charge)
    assert_equal "true", text(charge, "ram:ChargeIndicator/udt:Indicator")
    assert_equal "5", text(charge, "ram:ActualAmount")
  end

  def test_writes_payment_terms
    terms = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradePaymentTerms", CII_NS)

    assert_equal %w[Description DueDateDateTime DirectDebitMandateID], child_names(terms)
    assert_equal "Zahlbar in 14 Tagen", text(terms, "ram:Description")
    assert_equal "20240629", text(terms, "ram:DueDateDateTime/udt:DateTimeString")
    assert_equal "MANDATE-1", text(terms, "ram:DirectDebitMandateID")
  end

  def test_writes_payment_terms_with_due_date_only
    invoice = minimal_invoice
    invoice.due_date = Date.new(2024, 6, 29)
    terms = write(invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradePaymentTerms", CII_NS)

    assert_equal %w[DueDateDateTime], child_names(terms)
  end

  def test_writes_monetary_summation
    summation = write(full_invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeSettlementHeaderMonetarySummation", CII_NS)

    assert_equal %w[
      LineTotalAmount ChargeTotalAmount AllowanceTotalAmount TaxBasisTotalAmount
      TaxTotalAmount GrandTotalAmount TotalPrepaidAmount DuePayableAmount
    ], child_names(summation)
    assert_equal %w[100 5 5 100 19 119 10 109], summation.element_children.map(&:text)
    assert_equal "EUR", summation.at_xpath("ram:TaxTotalAmount", CII_NS)["currencyID"]
  end

  def test_writes_rounding_amount
    invoice = full_invoice
    invoice.monetary_totals.payable_rounding_amount = BigDecimal("0.02")
    summation = write(invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeSettlementHeaderMonetarySummation", CII_NS)

    assert_equal "0.02", text(summation, "ram:RoundingAmount")
  end

  def test_writes_rounding_amount_before_grand_total
    invoice = full_invoice
    invoice.monetary_totals.payable_rounding_amount = BigDecimal("0.02")
    summation = write(invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeSettlementHeaderMonetarySummation", CII_NS)

    assert_equal %w[
      LineTotalAmount ChargeTotalAmount AllowanceTotalAmount TaxBasisTotalAmount
      TaxTotalAmount RoundingAmount GrandTotalAmount TotalPrepaidAmount DuePayableAmount
    ], child_names(summation)
  end

  def test_omits_tax_total_without_tax_breakdown
    invoice = minimal_invoice
    invoice.monetary_totals = MonetaryTotals.new(
      line_extension_amount: "100", tax_exclusive_amount: "100", tax_inclusive_amount: "100", payable_amount: "100"
    )
    summation = write(invoice).at_xpath("#{SETTLEMENT}/ram:SpecifiedTradeSettlementHeaderMonetarySummation", CII_NS)

    assert_equal %w[LineTotalAmount TaxBasisTotalAmount GrandTotalAmount DuePayableAmount], child_names(summation)
  end

  def test_writes_line_item_parts_in_order
    line = write(full_invoice).at_xpath(LINE, CII_NS)

    assert_equal %w[
      AssociatedDocumentLineDocument SpecifiedTradeProduct SpecifiedLineTradeAgreement
      SpecifiedLineTradeDelivery SpecifiedLineTradeSettlement
    ], child_names(line)
  end

  def test_writes_line_item_values
    line = write(full_invoice).at_xpath(LINE, CII_NS)

    assert_equal "1", text(line, "ram:AssociatedDocumentLineDocument/ram:LineID")
    assert_equal "Line note", text(line, "ram:AssociatedDocumentLineDocument/ram:IncludedNote/ram:Content")
    assert_equal %w[ART-1 Widget Blue\ widget], line.at_xpath("ram:SpecifiedTradeProduct", CII_NS).element_children.map(&:text)
    assert_equal "50", text(line, "ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount")
    assert_equal "100", text(line, "ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount")
  end

  def test_writes_line_item_quantity_with_unit_code
    quantity = write(full_invoice).at_xpath("#{LINE}/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity", CII_NS)

    assert_equal "2", quantity.text
    assert_equal "H87", quantity["unitCode"]
  end

  def test_writes_line_item_tax
    tax = write(full_invoice).at_xpath("#{LINE}/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax", CII_NS)

    assert_equal %w[TypeCode CategoryCode RateApplicablePercent], child_names(tax)
    assert_equal %w[VAT S 19], tax.element_children.map(&:text)
  end

  def test_writes_minimal_line_item
    invoice = minimal_invoice
    invoice.line_items << LineItem.new(id: "1", invoiced_quantity: "1", unit_code: "C62", line_extension_amount: "10")
    line = write(invoice).at_xpath(LINE, CII_NS)

    assert_equal %w[
      AssociatedDocumentLineDocument SpecifiedLineTradeAgreement
      SpecifiedLineTradeDelivery SpecifiedLineTradeSettlement
    ], child_names(line)
    assert_empty line.at_xpath("ram:SpecifiedLineTradeAgreement", CII_NS).element_children
    assert_equal %w[SpecifiedTradeSettlementLineMonetarySummation],
                 child_names(line.at_xpath("ram:SpecifiedLineTradeSettlement", CII_NS))
  end

  def test_strips_trailing_zeros_from_decimals
    invoice = minimal_invoice
    invoice.line_items << LineItem.new(
      id: "1", invoiced_quantity: "1.500", unit_code: "KGM", line_extension_amount: "100.10"
    )
    line = write(invoice).at_xpath(LINE, CII_NS)

    assert_equal "1.5", text(line, "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity")
    assert_equal "100.1", text(line, "ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount")
  end

  private

  def write(document)
    parse_xml(Zugpferd::CII::Writer.new.write(document))
  end

  def text(node, xpath)
    node.at_xpath(xpath, CII_NS)&.text
  end

  def child_names(node)
    node.element_children.map(&:name)
  end

  def minimal_invoice
    Invoice.new(number: "RE-1", issue_date: Date.new(2024, 6, 15))
  end

  def full_invoice
    invoice = minimal_invoice
    invoice.buyer_reference = "04011000-12345-34"
    invoice.delivery_date = Date.new(2024, 6, 10)
    invoice.due_date = Date.new(2024, 6, 29)
    invoice.seller = TradeParty.new(
      name: "Seller GmbH", identifier: "S-1", legal_form: "GmbH",
      legal_registration_id: "HRB 1234", trading_name: "Seller", vat_identifier: "DE123456789",
      electronic_address: "seller@example.com", electronic_address_scheme: "EM",
      contact: Contact.new(name: "Max Muster", telephone: "+49 30 123", email: "max@example.com"),
      postal_address: PostalAddress.new(
        street_name: "Hauptstr. 1", city_name: "Berlin", postal_zone: "10115", country_code: "DE"
      )
    )
    invoice.buyer = TradeParty.new(name: "Buyer AG")
    invoice.payment_instructions = PaymentInstructions.new(
      payment_means_code: "58", payment_id: "RE-1", account_id: "DE89370400440532013000",
      note: "Zahlbar in 14 Tagen", card_account_id: "1234", card_holder_name: "Max Muster",
      mandate_reference: "MANDATE-1", creditor_reference_id: "DE98ZZZ09999999999",
      debited_account_id: "DE02100100109307118603"
    )
    invoice.tax_breakdown = TaxBreakdown.new(tax_amount: "19.00", currency_code: "EUR")
    invoice.tax_breakdown.subtotals << TaxSubtotal.new(
      taxable_amount: "100.00", tax_amount: "19.00", category_code: "S", currency_code: "EUR",
      percent: BigDecimal("19")
    )
    invoice.allowance_charges << AllowanceCharge.new(
      charge_indicator: false, amount: "5.00", base_amount: BigDecimal("100"),
      multiplier_factor: BigDecimal("5"), reason_code: "95", reason: "Rabatt",
      tax_category_code: "S", tax_percent: BigDecimal("19")
    )
    invoice.allowance_charges << AllowanceCharge.new(charge_indicator: true, amount: "5.00")
    invoice.line_items << LineItem.new(
      id: "1", invoiced_quantity: "2", unit_code: "H87", line_extension_amount: "100.00",
      note: "Line note",
      item: Item.new(name: "Widget", description: "Blue widget", sellers_identifier: "ART-1",
                     tax_category: "S", tax_percent: BigDecimal("19")),
      price: Price.new(amount: "50.00")
    )
    invoice.monetary_totals = MonetaryTotals.new(
      line_extension_amount: "100.00", tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "119.00", payable_amount: "109.00",
      charge_total_amount: BigDecimal("5"), allowance_total_amount: BigDecimal("5"),
      prepaid_amount: BigDecimal("10")
    )
    invoice
  end
end
