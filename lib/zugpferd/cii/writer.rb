require "nokogiri"
require_relative "mapping"

module Zugpferd
  module CII
    # Writes a billing document to UN/CEFACT CII CrossIndustryInvoice XML.
    #
    # @example
    #   xml = Zugpferd::CII::Writer.new.write(document)
    class Writer
      include Mapping

      # Serializes a billing document to CII D16B XML.
      #
      # @param document [Model::BillingDocument] the document to serialize
      # @return [String] UTF-8 encoded XML string
      def write(document)
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml["rsm"].CrossIndustryInvoice(
            "xmlns:rsm" => NS["rsm"],
            "xmlns:ram" => NS["ram"],
            "xmlns:qdt" => NS["qdt"],
            "xmlns:udt" => NS["udt"]
          ) do
            build_document_context(xml, document)
            build_exchanged_document(xml, document)
            build_transaction(xml, document)
          end
        end
        builder.to_xml
      end

      private

      def build_document_context(xml, doc)
        xml["rsm"].ExchangedDocumentContext do
          if doc.profile_id
            xml["ram"].BusinessProcessSpecifiedDocumentContextParameter do
              xml["ram"].ID doc.profile_id
            end
          end
          if doc.customization_id
            xml["ram"].GuidelineSpecifiedDocumentContextParameter do
              xml["ram"].ID doc.customization_id
            end
          end
        end
      end

      def build_exchanged_document(xml, doc)
        xml["rsm"].ExchangedDocument do
          xml["ram"].ID doc.number
          xml["ram"].TypeCode doc.type_code
          xml["ram"].IssueDateTime do
            xml["udt"].DateTimeString(format_cii_date(doc.issue_date), format: "102")
          end
          if doc.note
            xml["ram"].IncludedNote do
              xml["ram"].Content doc.note
            end
          end
        end
      end

      def build_transaction(xml, doc)
        xml["rsm"].SupplyChainTradeTransaction do
          doc.line_items.each { |li| build_line_item(xml, li) }
          build_agreement(xml, doc)
          build_delivery(xml, doc)
          build_settlement(xml, doc)
        end
      end

      def build_agreement(xml, doc)
        xml["ram"].ApplicableHeaderTradeAgreement do
          xml["ram"].BuyerReference doc.buyer_reference if doc.buyer_reference
          build_party(xml, "SellerTradeParty", doc.seller) if doc.seller
          build_party(xml, "BuyerTradeParty", doc.buyer) if doc.buyer
        end
      end

      def build_party(xml, element_name, party)
        xml["ram"].send(element_name) do
          if party.identifier
            xml["ram"].ID party.identifier
          end

          xml["ram"].Name party.name

          xml["ram"].Description party.legal_form if party.legal_form

          if party.legal_registration_id || party.trading_name
            xml["ram"].SpecifiedLegalOrganization do
              xml["ram"].ID party.legal_registration_id if party.legal_registration_id
              xml["ram"].TradingBusinessName party.trading_name if party.trading_name
            end
          end

          build_contact(xml, party.contact) if party.contact

          build_postal_address(xml, party.postal_address) if party.postal_address

          if party.electronic_address
            xml["ram"].URIUniversalCommunication do
              attrs = {}
              attrs[:schemeID] = party.electronic_address_scheme if party.electronic_address_scheme
              xml["ram"].URIID(party.electronic_address, attrs)
            end
          end

          if party.vat_identifier
            xml["ram"].SpecifiedTaxRegistration do
              xml["ram"].ID(party.vat_identifier, schemeID: "VA")
            end
          end
        end
      end

      def build_postal_address(xml, addr)
        xml["ram"].PostalTradeAddress do
          xml["ram"].PostcodeCode addr.postal_zone if addr.postal_zone
          xml["ram"].LineOne addr.street_name if addr.street_name
          xml["ram"].CityName addr.city_name if addr.city_name
          xml["ram"].CountryID addr.country_code
        end
      end

      def build_contact(xml, contact)
        xml["ram"].DefinedTradeContact do
          xml["ram"].PersonName contact.name if contact.name
          if contact.telephone
            xml["ram"].TelephoneUniversalCommunication do
              xml["ram"].CompleteNumber contact.telephone
            end
          end
          if contact.email
            xml["ram"].EmailURIUniversalCommunication do
              xml["ram"].URIID contact.email
            end
          end
        end
      end

      def build_delivery(xml, doc)
        xml["ram"].ApplicableHeaderTradeDelivery do
          if doc.delivery_date
            xml["ram"].ActualDeliverySupplyChainEvent do
              xml["ram"].OccurrenceDateTime do
                xml["udt"].DateTimeString(format_cii_date(doc.delivery_date), format: "102")
              end
            end
          end
        end
      end

      def build_settlement(xml, doc)
        xml["ram"].ApplicableHeaderTradeSettlement do
          if doc.payment_instructions&.creditor_reference_id
            xml["ram"].CreditorReferenceID doc.payment_instructions.creditor_reference_id
          end

          if doc.payment_instructions&.payment_id
            xml["ram"].PaymentReference doc.payment_instructions.payment_id
          end

          xml["ram"].InvoiceCurrencyCode doc.currency_code

          build_payment_means(xml, doc.payment_instructions) if doc.payment_instructions

          if doc.tax_breakdown
            doc.tax_breakdown.subtotals.each do |sub|
              build_tax_subtotal(xml, sub)
            end
          end

          doc.allowance_charges.each { |ac| build_allowance_charge(xml, ac) }

          if doc.payment_instructions&.note || doc.due_date || doc.payment_instructions&.mandate_reference
            xml["ram"].SpecifiedTradePaymentTerms do
              xml["ram"].Description doc.payment_instructions.note if doc.payment_instructions&.note
              if doc.due_date
                xml["ram"].DueDateDateTime do
                  xml["udt"].DateTimeString(format_cii_date(doc.due_date), format: "102")
                end
              end
              xml["ram"].DirectDebitMandateID doc.payment_instructions.mandate_reference if doc.payment_instructions&.mandate_reference
            end
          end

          build_monetary_total(xml, doc.monetary_totals, doc.tax_breakdown) if doc.monetary_totals
        end
      end

      def build_payment_means(xml, payment)
        xml["ram"].SpecifiedTradeSettlementPaymentMeans do
          xml["ram"].TypeCode payment.payment_means_code
          if payment.card_account_id
            xml["ram"].ApplicableTradeSettlementFinancialCard do
              xml["ram"].ID payment.card_account_id
              xml["ram"].CardholderName payment.card_holder_name if payment.card_holder_name
            end
          end
          if payment.debited_account_id
            xml["ram"].PayerPartyDebtorFinancialAccount do
              xml["ram"].IBANID payment.debited_account_id
            end
          end
          if payment.account_id
            xml["ram"].PayeePartyCreditorFinancialAccount do
              xml["ram"].IBANID payment.account_id
            end
          end
        end
      end

      def build_tax_subtotal(xml, sub)
        xml["ram"].ApplicableTradeTax do
          xml["ram"].CalculatedAmount format_decimal(sub.tax_amount)
          xml["ram"].TypeCode "VAT"
          xml["ram"].ExemptionReason sub.exemption_reason if sub.exemption_reason
          xml["ram"].BasisAmount format_decimal(sub.taxable_amount)
          xml["ram"].CategoryCode sub.category_code
          xml["ram"].ExemptionReasonCode sub.exemption_reason_code if sub.exemption_reason_code
          xml["ram"].RateApplicablePercent format_decimal(sub.percent) if sub.percent
        end
      end

      def build_monetary_total(xml, totals, tax_breakdown)
        xml["ram"].SpecifiedTradeSettlementHeaderMonetarySummation do
          xml["ram"].LineTotalAmount format_decimal(totals.line_extension_amount)
          xml["ram"].ChargeTotalAmount format_decimal(totals.charge_total_amount) if totals.charge_total_amount
          xml["ram"].AllowanceTotalAmount format_decimal(totals.allowance_total_amount) if totals.allowance_total_amount
          xml["ram"].TaxBasisTotalAmount format_decimal(totals.tax_exclusive_amount)
          if tax_breakdown
            xml["ram"].TaxTotalAmount(format_decimal(tax_breakdown.tax_amount),
                                      currencyID: tax_breakdown.currency_code)
          end
          xml["ram"].GrandTotalAmount format_decimal(totals.tax_inclusive_amount)
          xml["ram"].RoundingAmount format_decimal(totals.payable_rounding_amount) if totals.payable_rounding_amount
          xml["ram"].TotalPrepaidAmount format_decimal(totals.prepaid_amount) if totals.prepaid_amount
          xml["ram"].DuePayableAmount format_decimal(totals.payable_amount)
        end
      end

      def build_allowance_charge(xml, ac)
        xml["ram"].SpecifiedTradeAllowanceCharge do
          xml["ram"].ChargeIndicator do
            xml["udt"].Indicator ac.charge_indicator.to_s
          end
          xml["ram"].CalculationPercent format_decimal(ac.multiplier_factor) if ac.multiplier_factor
          xml["ram"].BasisAmount format_decimal(ac.base_amount) if ac.base_amount
          xml["ram"].ActualAmount format_decimal(ac.amount)
          xml["ram"].ReasonCode ac.reason_code if ac.reason_code
          xml["ram"].Reason ac.reason if ac.reason
          if ac.tax_category_code
            xml["ram"].CategoryTradeTax do
              xml["ram"].TypeCode "VAT"
              xml["ram"].CategoryCode ac.tax_category_code
              xml["ram"].RateApplicablePercent format_decimal(ac.tax_percent) if ac.tax_percent
            end
          end
        end
      end

      def build_line_item(xml, line)
        xml["ram"].IncludedSupplyChainTradeLineItem do
          xml["ram"].AssociatedDocumentLineDocument do
            xml["ram"].LineID line.id
            if line.note
              xml["ram"].IncludedNote do
                xml["ram"].Content line.note
              end
            end
          end

          build_item(xml, line.item) if line.item

          xml["ram"].SpecifiedLineTradeAgreement do
            if line.price
              xml["ram"].NetPriceProductTradePrice do
                xml["ram"].ChargeAmount format_decimal(line.price.amount)
              end
            end
          end

          xml["ram"].SpecifiedLineTradeDelivery do
            xml["ram"].BilledQuantity(format_decimal(line.invoiced_quantity),
                                      unitCode: line.unit_code)
          end

          xml["ram"].SpecifiedLineTradeSettlement do
            if line.item&.tax_category
              xml["ram"].ApplicableTradeTax do
                xml["ram"].TypeCode "VAT"
                xml["ram"].CategoryCode line.item.tax_category
                xml["ram"].RateApplicablePercent format_decimal(line.item.tax_percent) if line.item.tax_percent
              end
            end

            xml["ram"].SpecifiedTradeSettlementLineMonetarySummation do
              xml["ram"].LineTotalAmount format_decimal(line.line_extension_amount)
            end
          end
        end
      end

      def build_item(xml, item)
        xml["ram"].SpecifiedTradeProduct do
          xml["ram"].SellerAssignedID item.sellers_identifier if item.sellers_identifier
          xml["ram"].Name item.name
          xml["ram"].Description item.description if item.description
        end
      end

      def format_cii_date(date)
        date.strftime("%Y%m%d")
      end

      def format_decimal(value)
        return value.to_s unless value.is_a?(BigDecimal)
        str = value.to_s("F")
        str.sub(/\.?0+$/, "")
      end
    end
  end
end
