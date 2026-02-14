require "nokogiri"
require_relative "mapping"

module Zugpferd
  module UBL
    class Writer
      include Mapping

      def write(invoice)
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.Invoice(xmlns: NS["ubl"],
                      "xmlns:cac" => NS["cac"],
                      "xmlns:cbc" => NS["cbc"]) do
            build_invoice(xml, invoice)
          end
        end
        builder.to_xml
      end

      private

      def build_invoice(xml, inv)
        xml["cbc"].CustomizationID inv.customization_id if inv.customization_id
        xml["cbc"].ProfileID inv.profile_id if inv.profile_id
        xml["cbc"].ID inv.number
        xml["cbc"].IssueDate inv.issue_date.to_s
        xml["cbc"].InvoiceTypeCode inv.type_code
        xml["cbc"].Note inv.note if inv.note
        xml["cbc"].DocumentCurrencyCode inv.currency_code
        xml["cbc"].BuyerReference inv.buyer_reference if inv.buyer_reference

        build_supplier(xml, inv.seller) if inv.seller
        build_customer(xml, inv.buyer) if inv.buyer
        build_payment_means(xml, inv.payment_instructions) if inv.payment_instructions
        build_payment_terms(xml, inv.payment_instructions) if inv.payment_instructions&.note
        build_tax_total(xml, inv.tax_breakdown) if inv.tax_breakdown
        build_monetary_total(xml, inv.monetary_totals, inv.currency_code) if inv.monetary_totals
        inv.line_items.each { |li| build_invoice_line(xml, li, inv.currency_code) }
      end

      def build_supplier(xml, party)
        xml["cac"].AccountingSupplierParty do
          build_party(xml, party)
        end
      end

      def build_customer(xml, party)
        xml["cac"].AccountingCustomerParty do
          build_party(xml, party)
        end
      end

      def build_party(xml, party)
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

      def build_payment_means(xml, payment)
        xml["cac"].PaymentMeans do
          xml["cbc"].PaymentMeansCode payment.payment_means_code
          xml["cbc"].PaymentID payment.payment_id if payment.payment_id
          if payment.account_id
            xml["cac"].PayeeFinancialAccount do
              xml["cbc"].ID payment.account_id
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
          xml["cbc"].PayableAmount(format_decimal(totals.payable_amount),
                                   currencyID: currency_code)
        end
      end

      def build_invoice_line(xml, line, currency_code)
        xml["cac"].InvoiceLine do
          xml["cbc"].ID line.id
          xml["cbc"].Note line.note if line.note
          xml["cbc"].InvoicedQuantity(format_decimal(line.invoiced_quantity),
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
