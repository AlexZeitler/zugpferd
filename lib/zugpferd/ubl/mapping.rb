module Zugpferd
  module UBL
    module Mapping
      NS = {
        "ubl" => "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
        "cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      }.freeze

      # Invoice (BG-0)
      INVOICE = {
        number:             "cbc:ID",
        issue_date:         "cbc:IssueDate",
        due_date:           "cbc:DueDate",
        type_code:          "cbc:InvoiceTypeCode",
        currency_code:      "cbc:DocumentCurrencyCode",
        buyer_reference:    "cbc:BuyerReference",
        customization_id:   "cbc:CustomizationID",
        profile_id:         "cbc:ProfileID",
        note:               "cbc:Note",
      }.freeze

      # Seller (BG-4)
      SELLER = "cac:AccountingSupplierParty/cac:Party"
      # Buyer (BG-7)
      BUYER = "cac:AccountingCustomerParty/cac:Party"

      # TradeParty fields
      PARTY = {
        name:                    "cac:PartyLegalEntity/cbc:RegistrationName",
        trading_name:            "cac:PartyName/cbc:Name",
        identifier:              "cac:PartyIdentification/cbc:ID",
        legal_registration_id:   "cac:PartyLegalEntity/cbc:CompanyID",
        legal_form:              "cac:PartyLegalEntity/cbc:CompanyLegalForm",
        vat_identifier:          "cac:PartyTaxScheme[cac:TaxScheme/cbc:ID='VAT']/cbc:CompanyID",
        electronic_address:      "cbc:EndpointID",
      }.freeze

      # PostalAddress (BG-5 / BG-8)
      POSTAL_ADDRESS = "cac:PostalAddress"
      ADDRESS = {
        street_name:  "cbc:StreetName",
        city_name:    "cbc:CityName",
        postal_zone:  "cbc:PostalZone",
        country_code: "cac:Country/cbc:IdentificationCode",
      }.freeze

      # Contact (BG-6 / BG-9)
      CONTACT = "cac:Contact"
      CONTACT_FIELDS = {
        name:      "cbc:Name",
        telephone: "cbc:Telephone",
        email:     "cbc:ElectronicMail",
      }.freeze

      # PaymentMeans (BG-16)
      PAYMENT_MEANS = "cac:PaymentMeans"
      PAYMENT = {
        payment_means_code: "cbc:PaymentMeansCode",
        payment_id:         "cbc:PaymentID",
        account_id:         "cac:PayeeFinancialAccount/cbc:ID",
        card_account_id:    "cac:CardAccount/cbc:PrimaryAccountNumberID",
        card_network_id:    "cac:CardAccount/cbc:NetworkID",
        card_holder_name:   "cac:CardAccount/cbc:HolderName",
        mandate_reference:  "cac:PaymentMandate/cbc:ID",
        debited_account_id: "cac:PaymentMandate/cac:PayerFinancialAccount/cbc:ID",
      }.freeze
      PAYMENT_TERMS_NOTE = "cac:PaymentTerms/cbc:Note"

      # TaxTotal (BG-23)
      TAX_TOTAL = "cac:TaxTotal"
      TAX_SUBTOTAL = "cac:TaxSubtotal"
      TAX = {
        taxable_amount:        "cbc:TaxableAmount",
        tax_amount:            "cbc:TaxAmount",
        category_code:         "cac:TaxCategory/cbc:ID",
        percent:               "cac:TaxCategory/cbc:Percent",
        exemption_reason:      "cac:TaxCategory/cbc:TaxExemptionReason",
        exemption_reason_code: "cac:TaxCategory/cbc:TaxExemptionReasonCode",
      }.freeze

      # LegalMonetaryTotal (BG-22)
      MONETARY_TOTAL = "cac:LegalMonetaryTotal"
      TOTALS = {
        line_extension_amount:  "cbc:LineExtensionAmount",
        tax_exclusive_amount:   "cbc:TaxExclusiveAmount",
        tax_inclusive_amount:    "cbc:TaxInclusiveAmount",
        prepaid_amount:          "cbc:PrepaidAmount",
        payable_rounding_amount: "cbc:PayableRoundingAmount",
        allowance_total_amount:  "cbc:AllowanceTotalAmount",
        charge_total_amount:     "cbc:ChargeTotalAmount",
        payable_amount:          "cbc:PayableAmount",
      }.freeze

      # AllowanceCharge (BG-20 / BG-21)
      ALLOWANCE_CHARGE = "cac:AllowanceCharge"
      ALLOWANCE_CHARGE_FIELDS = {
        charge_indicator: "cbc:ChargeIndicator",
        reason:           "cbc:AllowanceChargeReason",
        reason_code:      "cbc:AllowanceChargeReasonCode",
        amount:           "cbc:Amount",
        base_amount:      "cbc:BaseAmount",
        multiplier_factor: "cbc:MultiplierFactorNumeric",
        tax_category_code: "cac:TaxCategory/cbc:ID",
        tax_percent:       "cac:TaxCategory/cbc:Percent",
      }.freeze

      # InvoiceLine (BG-25)
      INVOICE_LINE = "cac:InvoiceLine"
      LINE = {
        id:                    "cbc:ID",
        invoiced_quantity:     "cbc:InvoicedQuantity",
        unit_code:             "cbc:InvoicedQuantity/@unitCode",
        line_extension_amount: "cbc:LineExtensionAmount",
        note:                  "cbc:Note",
      }.freeze

      # Item (BG-31)
      ITEM = "cac:Item"
      ITEM_FIELDS = {
        name:              "cbc:Name",
        description:       "cbc:Description",
        sellers_identifier: "cac:SellersItemIdentification/cbc:ID",
        tax_category:      "cac:ClassifiedTaxCategory/cbc:ID",
        tax_percent:       "cac:ClassifiedTaxCategory/cbc:Percent",
      }.freeze

      # Price (BG-29)
      PRICE = "cac:Price"
      PRICE_FIELDS = {
        amount: "cbc:PriceAmount",
      }.freeze
    end
  end
end
