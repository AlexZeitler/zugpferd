require "nokogiri"
require_relative "mapping"

module Zugpferd
  module CII
    class Writer
      include Mapping

      def write(invoice)
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml["rsm"].CrossIndustryInvoice(
            "xmlns:rsm" => NS["rsm"],
            "xmlns:ram" => NS["ram"],
            "xmlns:qdt" => NS["qdt"],
            "xmlns:udt" => NS["udt"]
          ) do
            build_document_context(xml, invoice)
            build_exchanged_document(xml, invoice)
            build_transaction(xml, invoice)
          end
        end
        builder.to_xml
      end

      private

      def build_document_context(xml, inv)
        xml["rsm"].ExchangedDocumentContext do
          if inv.profile_id
            xml["ram"].BusinessProcessSpecifiedDocumentContextParameter do
              xml["ram"].ID inv.profile_id
            end
          end
          if inv.customization_id
            xml["ram"].GuidelineSpecifiedDocumentContextParameter do
              xml["ram"].ID inv.customization_id
            end
          end
        end
      end

      def build_exchanged_document(xml, inv)
        xml["rsm"].ExchangedDocument do
          xml["ram"].ID inv.number
          xml["ram"].TypeCode inv.type_code
          xml["ram"].IssueDateTime do
            xml["udt"].DateTimeString(format_cii_date(inv.issue_date), format: "102")
          end
          if inv.note
            xml["ram"].IncludedNote do
              xml["ram"].Content inv.note
            end
          end
        end
      end

      def build_transaction(xml, inv)
        xml["rsm"].SupplyChainTradeTransaction do
          inv.line_items.each { |li| build_line_item(xml, li) }
          build_agreement(xml, inv)
          xml["ram"].ApplicableHeaderTradeDelivery
          build_settlement(xml, inv)
        end
      end

      def build_agreement(xml, inv)
        xml["ram"].ApplicableHeaderTradeAgreement do
          xml["ram"].BuyerReference inv.buyer_reference if inv.buyer_reference
          build_party(xml, "SellerTradeParty", inv.seller) if inv.seller
          build_party(xml, "BuyerTradeParty", inv.buyer) if inv.buyer
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

      def build_settlement(xml, inv)
        xml["ram"].ApplicableHeaderTradeSettlement do
          if inv.payment_instructions&.payment_id
            xml["ram"].PaymentReference inv.payment_instructions.payment_id
          end

          xml["ram"].InvoiceCurrencyCode inv.currency_code

          build_payment_means(xml, inv.payment_instructions) if inv.payment_instructions

          if inv.tax_breakdown
            inv.tax_breakdown.subtotals.each do |sub|
              build_tax_subtotal(xml, sub)
            end
          end

          if inv.payment_instructions&.note
            xml["ram"].SpecifiedTradePaymentTerms do
              xml["ram"].Description inv.payment_instructions.note
            end
          end

          build_monetary_total(xml, inv.monetary_totals, inv.tax_breakdown) if inv.monetary_totals
        end
      end

      def build_payment_means(xml, payment)
        xml["ram"].SpecifiedTradeSettlementPaymentMeans do
          xml["ram"].TypeCode payment.payment_means_code
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
          xml["ram"].BasisAmount format_decimal(sub.taxable_amount)
          xml["ram"].CategoryCode sub.category_code
          xml["ram"].RateApplicablePercent format_decimal(sub.percent) if sub.percent
        end
      end

      def build_monetary_total(xml, totals, tax_breakdown)
        xml["ram"].SpecifiedTradeSettlementHeaderMonetarySummation do
          xml["ram"].LineTotalAmount format_decimal(totals.line_extension_amount)
          xml["ram"].TaxBasisTotalAmount format_decimal(totals.tax_exclusive_amount)
          if tax_breakdown
            xml["ram"].TaxTotalAmount(format_decimal(tax_breakdown.tax_amount),
                                      currencyID: tax_breakdown.currency_code)
          end
          xml["ram"].GrandTotalAmount format_decimal(totals.tax_inclusive_amount)
          xml["ram"].DuePayableAmount format_decimal(totals.payable_amount)
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
