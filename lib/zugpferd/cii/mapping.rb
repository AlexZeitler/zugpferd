module Zugpferd
  module CII
    module Mapping
      NS = {
        "rsm" => "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100",
        "ram" => "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100",
        "udt" => "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100",
        "qdt" => "urn:un:unece:uncefact:data:standard:QualifiedDataType:100",
      }.freeze

      # Document context
      CONTEXT = "rsm:ExchangedDocumentContext"
      DOCUMENT = "rsm:ExchangedDocument"
      TRANSACTION = "rsm:SupplyChainTradeTransaction"

      # Invoice header (BG-0)
      INVOICE = {
        number:           "#{DOCUMENT}/ram:ID",
        issue_date:       "#{DOCUMENT}/ram:IssueDateTime/udt:DateTimeString",
        type_code:        "#{DOCUMENT}/ram:TypeCode",
        note:             "#{DOCUMENT}/ram:IncludedNote/ram:Content",
        customization_id: "#{CONTEXT}/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID",
        profile_id:       "#{CONTEXT}/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID",
      }.freeze

      # Delivery (BG-13)
      DELIVERY = "#{TRANSACTION}/ram:ApplicableHeaderTradeDelivery"
      DELIVERY_DATE = "ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString"

      # Settlement (contains currency, payment, tax, totals)
      SETTLEMENT = "#{TRANSACTION}/ram:ApplicableHeaderTradeSettlement"
      AGREEMENT = "#{TRANSACTION}/ram:ApplicableHeaderTradeAgreement"

      INVOICE_SETTLEMENT = {
        currency_code:  "#{SETTLEMENT}/ram:InvoiceCurrencyCode",
        buyer_reference: "#{AGREEMENT}/ram:BuyerReference",
      }.freeze

      # Seller (BG-4)
      SELLER = "#{AGREEMENT}/ram:SellerTradeParty"
      # Buyer (BG-7)
      BUYER = "#{AGREEMENT}/ram:BuyerTradeParty"

      # TradeParty fields
      PARTY = {
        name:                  "ram:Name",
        trading_name:          "ram:SpecifiedLegalOrganization/ram:TradingBusinessName",
        identifier:            "ram:ID",
        legal_registration_id: "ram:SpecifiedLegalOrganization/ram:ID",
        legal_form:            "ram:Description",
        vat_identifier:        "ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']",
        electronic_address:    "ram:URIUniversalCommunication/ram:URIID",
      }.freeze

      # PostalAddress (BG-5 / BG-8)
      POSTAL_ADDRESS = "ram:PostalTradeAddress"
      ADDRESS = {
        street_name:  "ram:LineOne",
        city_name:    "ram:CityName",
        postal_zone:  "ram:PostcodeCode",
        country_code: "ram:CountryID",
      }.freeze

      # Contact (BG-6 / BG-9)
      CONTACT = "ram:DefinedTradeContact"
      CONTACT_FIELDS = {
        name:      "ram:PersonName",
        telephone: "ram:TelephoneUniversalCommunication/ram:CompleteNumber",
        email:     "ram:EmailURIUniversalCommunication/ram:URIID",
      }.freeze

      # PaymentMeans (BG-16)
      PAYMENT_MEANS = "ram:SpecifiedTradeSettlementPaymentMeans"
      PAYMENT = {
        payment_means_code: "ram:TypeCode",
        account_id:         "ram:PayeePartyCreditorFinancialAccount/ram:IBANID",
        card_account_id:    "ram:ApplicableTradeSettlementFinancialCard/ram:ID",
        card_holder_name:   "ram:ApplicableTradeSettlementFinancialCard/ram:CardholderName",
        debited_account_id: "ram:PayerPartyDebtorFinancialAccount/ram:IBANID",
      }.freeze
      CREDITOR_REFERENCE_ID = "ram:CreditorReferenceID"
      PAYMENT_REFERENCE = "ram:PaymentReference"
      PAYMENT_TERMS_NOTE = "ram:SpecifiedTradePaymentTerms/ram:Description"
      PAYMENT_TERMS_DUE_DATE = "ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString"
      PAYMENT_TERMS_MANDATE = "ram:SpecifiedTradePaymentTerms/ram:DirectDebitMandateID"

      # TaxTotal (BG-23)
      TAX_SUBTOTAL = "ram:ApplicableTradeTax"
      TAX = {
        taxable_amount:        "ram:BasisAmount",
        tax_amount:            "ram:CalculatedAmount",
        category_code:         "ram:CategoryCode",
        percent:               "ram:RateApplicablePercent",
        exemption_reason:      "ram:ExemptionReason",
        exemption_reason_code: "ram:ExemptionReasonCode",
      }.freeze

      # LegalMonetaryTotal (BG-22)
      MONETARY_TOTAL = "ram:SpecifiedTradeSettlementHeaderMonetarySummation"
      TOTALS = {
        line_extension_amount:  "ram:LineTotalAmount",
        tax_exclusive_amount:   "ram:TaxBasisTotalAmount",
        tax_inclusive_amount:    "ram:GrandTotalAmount",
        prepaid_amount:          "ram:TotalPrepaidAmount",
        payable_rounding_amount: "ram:RoundingAmount",
        payable_amount:          "ram:DuePayableAmount",
        tax_total_amount:        "ram:TaxTotalAmount",
        allowance_total_amount:  "ram:AllowanceTotalAmount",
        charge_total_amount:     "ram:ChargeTotalAmount",
      }.freeze

      # AllowanceCharge (BG-20 / BG-21)
      ALLOWANCE_CHARGE = "ram:SpecifiedTradeAllowanceCharge"
      ALLOWANCE_CHARGE_FIELDS = {
        charge_indicator: "ram:ChargeIndicator/udt:Indicator",
        reason:           "ram:Reason",
        reason_code:      "ram:ReasonCode",
        amount:           "ram:ActualAmount",
        base_amount:      "ram:BasisAmount",
        multiplier_factor: "ram:CalculationPercent",
        tax_category_code: "ram:CategoryTradeTax/ram:CategoryCode",
        tax_percent:       "ram:CategoryTradeTax/ram:RateApplicablePercent",
      }.freeze

      # InvoiceLine (BG-25)
      INVOICE_LINE = "#{TRANSACTION}/ram:IncludedSupplyChainTradeLineItem"
      LINE = {
        id:                    "ram:AssociatedDocumentLineDocument/ram:LineID",
        note:                  "ram:AssociatedDocumentLineDocument/ram:IncludedNote/ram:Content",
        invoiced_quantity:     "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity",
        unit_code:             "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode",
        line_extension_amount: "ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount",
      }.freeze

      # Item (BG-31)
      ITEM = "ram:SpecifiedTradeProduct"
      ITEM_FIELDS = {
        name:               "ram:Name",
        description:        "ram:Description",
        sellers_identifier: "ram:SellerAssignedID",
      }.freeze

      # Item tax (from line settlement, not from product)
      ITEM_TAX = "ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax"
      ITEM_TAX_FIELDS = {
        tax_category: "ram:CategoryCode",
        tax_percent:  "ram:RateApplicablePercent",
      }.freeze

      # Price (BG-29)
      PRICE = "ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice"
      PRICE_FIELDS = {
        amount: "ram:ChargeAmount",
      }.freeze
    end
  end
end
