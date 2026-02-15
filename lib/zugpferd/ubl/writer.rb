require "nokogiri"
require_relative "mapping"

module Zugpferd
  module UBL
    # Writes a billing document to UBL 2.1 Invoice or Credit Note XML.
    #
    # @example
    #   xml = Zugpferd::UBL::Writer.new.write(document)
    class Writer
      include Mapping

      # Serializes a billing document to UBL 2.1 XML.
      #
      # @param document [Model::BillingDocument] the document to serialize
      # @return [String] UTF-8 encoded XML string
      def write(document)
        @credit_note = document.type_code == "381"
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          if @credit_note
            xml.CreditNote(xmlns: CN_NS["cn"],
                           "xmlns:cac" => CN_NS["cac"],
                           "xmlns:cbc" => CN_NS["cbc"]) do
              build_document(xml, document)
            end
          else
            xml.Invoice(xmlns: NS["ubl"],
                        "xmlns:cac" => NS["cac"],
                        "xmlns:cbc" => NS["cbc"]) do
              build_document(xml, document)
            end
          end
        end
        builder.to_xml
      end

      private

      def build_document(xml, doc)
        xml["cbc"].CustomizationID doc.customization_id if doc.customization_id
        xml["cbc"].ProfileID doc.profile_id if doc.profile_id
        xml["cbc"].ID doc.number
        xml["cbc"].IssueDate doc.issue_date.to_s
        xml["cbc"].DueDate doc.due_date.to_s if doc.due_date
        if @credit_note
          xml["cbc"].CreditNoteTypeCode doc.type_code
        else
          xml["cbc"].InvoiceTypeCode doc.type_code
        end
        xml["cbc"].Note doc.note if doc.note
        xml["cbc"].DocumentCurrencyCode doc.currency_code
        xml["cbc"].BuyerReference doc.buyer_reference if doc.buyer_reference

        build_supplier(xml, doc.seller, doc.payment_instructions) if doc.seller
        build_customer(xml, doc.buyer) if doc.buyer
        build_delivery(xml, doc) if doc.delivery_date
        build_payment_means(xml, doc.payment_instructions) if doc.payment_instructions
        build_payment_terms(xml, doc.payment_instructions) if doc.payment_instructions&.note
        doc.allowance_charges.each { |ac| build_allowance_charge(xml, ac, doc.currency_code) }
        build_tax_total(xml, doc.tax_breakdown) if doc.tax_breakdown
        build_monetary_total(xml, doc.monetary_totals, doc.currency_code) if doc.monetary_totals
        doc.line_items.each { |li| build_line(xml, li, doc.currency_code) }
      end

      def build_supplier(xml, party, payment_instructions = nil)
        xml["cac"].AccountingSupplierParty do
          build_party(xml, party,
            creditor_reference_id: payment_instructions&.creditor_reference_id)
        end
      end

      def build_customer(xml, party)
        xml["cac"].AccountingCustomerParty do
          build_party(xml, party)
        end
      end

      def build_party(xml, party, creditor_reference_id: nil)
        xml["cac"].Party do
          if party.electronic_address
            attrs = {}
            attrs[:schemeID] = party.electronic_address_scheme if party.electronic_address_scheme
            xml["cbc"].EndpointID(party.electronic_address, attrs)
          end

          if party.identifier
            xml["cac"].PartyIdentification do
              xml["cbc"].ID party.identifier
            end
          end

          if creditor_reference_id
            xml["cac"].PartyIdentification do
              xml["cbc"].ID(creditor_reference_id, schemeID: "SEPA")
            end
          end

          if party.trading_name
            xml["cac"].PartyName do
              xml["cbc"].Name party.trading_name
            end
          end

          build_postal_address(xml, party.postal_address) if party.postal_address

          if party.vat_identifier
            xml["cac"].PartyTaxScheme do
              xml["cbc"].CompanyID party.vat_identifier
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end

          xml["cac"].PartyLegalEntity do
            xml["cbc"].RegistrationName party.name
            xml["cbc"].CompanyID party.legal_registration_id if party.legal_registration_id
            xml["cbc"].CompanyLegalForm party.legal_form if party.legal_form
          end

          build_contact(xml, party.contact) if party.contact
        end
      end

      def build_postal_address(xml, addr)
        xml["cac"].PostalAddress do
          xml["cbc"].StreetName addr.street_name if addr.street_name
          xml["cbc"].CityName addr.city_name if addr.city_name
          xml["cbc"].PostalZone addr.postal_zone if addr.postal_zone
          xml["cac"].Country do
            xml["cbc"].IdentificationCode addr.country_code
          end
        end
      end

      def build_contact(xml, contact)
        xml["cac"].Contact do
          xml["cbc"].Name contact.name if contact.name
          xml["cbc"].Telephone contact.telephone if contact.telephone
          xml["cbc"].ElectronicMail contact.email if contact.email
        end
      end

      def build_delivery(xml, doc)
        xml["cac"].Delivery do
          xml["cbc"].ActualDeliveryDate doc.delivery_date.to_s
        end
      end

      def build_payment_means(xml, payment)
        xml["cac"].PaymentMeans do
          xml["cbc"].PaymentMeansCode payment.payment_means_code
          xml["cbc"].PaymentID payment.payment_id if payment.payment_id
          if payment.card_account_id
            xml["cac"].CardAccount do
              xml["cbc"].PrimaryAccountNumberID payment.card_account_id
              xml["cbc"].NetworkID(payment.card_network_id || "mapped-from-cii")
              xml["cbc"].HolderName payment.card_holder_name if payment.card_holder_name
            end
          end
          if payment.account_id
            xml["cac"].PayeeFinancialAccount do
              xml["cbc"].ID payment.account_id
            end
          end
          if payment.mandate_reference
            xml["cac"].PaymentMandate do
              xml["cbc"].ID payment.mandate_reference
              if payment.debited_account_id
                xml["cac"].PayerFinancialAccount do
                  xml["cbc"].ID payment.debited_account_id
                end
              end
            end
          end
        end
      end

      def build_payment_terms(xml, payment)
        xml["cac"].PaymentTerms do
          xml["cbc"].Note payment.note
        end
      end

      def build_tax_total(xml, breakdown)
        xml["cac"].TaxTotal do
          xml["cbc"].TaxAmount(format_decimal(breakdown.tax_amount),
                               currencyID: breakdown.currency_code)
          breakdown.subtotals.each do |sub|
            xml["cac"].TaxSubtotal do
              xml["cbc"].TaxableAmount(format_decimal(sub.taxable_amount),
                                       currencyID: sub.currency_code)
              xml["cbc"].TaxAmount(format_decimal(sub.tax_amount),
                                   currencyID: sub.currency_code)
              xml["cac"].TaxCategory do
                xml["cbc"].ID sub.category_code
                xml["cbc"].Percent format_decimal(sub.percent) if sub.percent
                xml["cbc"].TaxExemptionReasonCode sub.exemption_reason_code if sub.exemption_reason_code
                xml["cbc"].TaxExemptionReason sub.exemption_reason if sub.exemption_reason
                xml["cac"].TaxScheme do
                  xml["cbc"].ID "VAT"
                end
              end
            end
          end
        end
      end

      def build_monetary_total(xml, totals, currency_code)
        xml["cac"].LegalMonetaryTotal do
          xml["cbc"].LineExtensionAmount(format_decimal(totals.line_extension_amount),
                                         currencyID: currency_code)
          xml["cbc"].TaxExclusiveAmount(format_decimal(totals.tax_exclusive_amount),
                                        currencyID: currency_code)
          xml["cbc"].TaxInclusiveAmount(format_decimal(totals.tax_inclusive_amount),
                                        currencyID: currency_code)
          if totals.allowance_total_amount
            xml["cbc"].AllowanceTotalAmount(format_decimal(totals.allowance_total_amount),
                                            currencyID: currency_code)
          end
          if totals.charge_total_amount
            xml["cbc"].ChargeTotalAmount(format_decimal(totals.charge_total_amount),
                                          currencyID: currency_code)
          end
          if totals.prepaid_amount
            xml["cbc"].PrepaidAmount(format_decimal(totals.prepaid_amount),
                                     currencyID: currency_code)
          end
          if totals.payable_rounding_amount
            xml["cbc"].PayableRoundingAmount(format_decimal(totals.payable_rounding_amount),
                                              currencyID: currency_code)
          end
          xml["cbc"].PayableAmount(format_decimal(totals.payable_amount),
                                   currencyID: currency_code)
        end
      end

      def build_allowance_charge(xml, ac, currency_code)
        xml["cac"].AllowanceCharge do
          xml["cbc"].ChargeIndicator ac.charge_indicator.to_s
          xml["cbc"].AllowanceChargeReasonCode ac.reason_code if ac.reason_code
          xml["cbc"].AllowanceChargeReason ac.reason if ac.reason
          xml["cbc"].MultiplierFactorNumeric format_decimal(ac.multiplier_factor) if ac.multiplier_factor
          xml["cbc"].Amount(format_decimal(ac.amount), currencyID: currency_code)
          xml["cbc"].BaseAmount(format_decimal(ac.base_amount), currencyID: currency_code) if ac.base_amount
          if ac.tax_category_code
            xml["cac"].TaxCategory do
              xml["cbc"].ID ac.tax_category_code
              xml["cbc"].Percent format_decimal(ac.tax_percent) if ac.tax_percent
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end
        end
      end

      def build_line(xml, line, currency_code)
        line_method = @credit_note ? :CreditNoteLine : :InvoiceLine
        quantity_method = @credit_note ? :CreditedQuantity : :InvoicedQuantity

        xml["cac"].send(line_method) do
          xml["cbc"].ID line.id
          xml["cbc"].Note line.note if line.note
          xml["cbc"].send(quantity_method, format_decimal(line.invoiced_quantity),
                          unitCode: line.unit_code)
          xml["cbc"].LineExtensionAmount(format_decimal(line.line_extension_amount),
                                         currencyID: currency_code)
          build_item(xml, line.item) if line.item
          build_price(xml, line.price, currency_code) if line.price
        end
      end

      def build_item(xml, item)
        xml["cac"].Item do
          xml["cbc"].Description item.description if item.description
          xml["cbc"].Name item.name
          if item.sellers_identifier
            xml["cac"].SellersItemIdentification do
              xml["cbc"].ID item.sellers_identifier
            end
          end
          if item.tax_category
            xml["cac"].ClassifiedTaxCategory do
              xml["cbc"].ID item.tax_category
              xml["cbc"].Percent format_decimal(item.tax_percent) if item.tax_percent
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end
        end
      end

      def build_price(xml, price, currency_code)
        xml["cac"].Price do
          xml["cbc"].PriceAmount(format_decimal(price.amount), currencyID: currency_code)
        end
      end

      def format_decimal(value)
        return value.to_s unless value.is_a?(BigDecimal)
        # Remove trailing zeros but keep at least one decimal
        str = value.to_s("F")
        str.sub(/\.?0+$/, "")
      end
    end
  end
end
