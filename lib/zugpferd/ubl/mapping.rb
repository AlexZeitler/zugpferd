module Zugpferd
  module UBL
    module Mapping
      class Document
        def xml_additional_namespaces
          {}
        end
      end

      class Invoice < Document
        class << self
          def model_class
            Model::Invoice
          end

          def xml_namespaces
            {
              "xmlns" => "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
              "xmlns:cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
              "xmlns:cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
            }.freeze
          end

          def xml_root_name
            "Invoice"
          end

          def type_code_name
            "cbc:InvoiceTypeCode"
          end

          def line_name
            "cac:InvoiceLine"
          end

          def line_quantity_name
            "cbc:InvoicedQuantity"
          end

          def line_unit_code_name
            "cbc:InvoicedQuantity/@unitCode"
          end
        end
      end

      class CorrectedInvoice < Invoice
        class << self
          def model_class
            Model::CorrectedInvoice
          end
        end
      end

      class PartialInvoice < Invoice
        class << self
          def model_class
            Model::PartialInvoice
          end
        end
      end

      class PrepaymentInvoice < Invoice
        class << self
          def model_class
            Model::PrepaymentInvoice
          end
        end
      end

      class SelfBilledInvoice < Invoice
        class << self
          def model_class
            Model::SelfBilledInvoice
          end
        end
      end

      class CreditNote < Document
        class << self
          def model_class
            Model::CreditNote
          end

          def xml_namespaces
            {
              "xmlns" => "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2",
              "xmlns:cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
              "xmlns:cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
            }.freeze
          end

          def xml_root_name
            "CreditNote"
          end

          def type_code_name
            "cbc:CreditNoteTypeCode"
          end

          def line_name
            "cac:CreditNoteLine"
          end

          def line_quantity_name
            "cbc:CreditedQuantity"
          end

          def line_unit_code_name
            "cbc:CreditedQuantity/@unitCode"
          end
        end
      end

      # Invoice (BG-0)
      INVOICE = {
        number:             "cbc:ID",
        issue_date:         "cbc:IssueDate",
        due_date:           "cbc:DueDate",
        currency_code:      "cbc:DocumentCurrencyCode",
        buyer_reference:    "cbc:BuyerReference",
        customization_id:   "cbc:CustomizationID",
        profile_id:         "cbc:ProfileID",
        note:               "cbc:Note",
      }.freeze

      # Delivery (BG-13)
      DELIVERY = "cac:Delivery"
      DELIVERY_DATE = "cbc:ActualDeliveryDate"

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
      LINE = {
        id:                    "cbc:ID",
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

      extend self

      # @return [Array<Class>] List of document type metadata classes
      def document_types
        descendants_of(Document)
      end

      private

      def descendants_of(type)
        type.subclasses.flat_map do |klass|
          [klass] + descendants_of(klass)
        end
      end
    end
  end
end
