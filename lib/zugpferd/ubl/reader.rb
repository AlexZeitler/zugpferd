require "nokogiri"
require "date"
require "bigdecimal"
require_relative "mapping"

module Zugpferd
  module UBL
    # Reads UBL 2.1 Invoice or Credit Note XML into the appropriate model class.
    #
    # @example
    #   doc = Zugpferd::UBL::Reader.new.read(File.read("invoice.xml"))
    class Reader
      include Mapping

      # Parses a UBL 2.1 Invoice or Credit Note XML string.
      #
      # @param xml_string [String] valid UBL 2.1 Invoice or Credit Note XML
      # @return [Model::BillingDocument]
      # @raise [Nokogiri::XML::SyntaxError] if the XML is malformed
      def read(xml_string)
        doc = Nokogiri::XML(xml_string) { |config| config.strict }
        root = doc.root
        @credit_note = root.name == "CreditNote"
        @ns = @credit_note ? CN_NS : NS
        build_invoice(root)
      end

      private

      def build_invoice(root)
        type_code_element = @credit_note ? "cbc:CreditNoteTypeCode" : INVOICE[:type_code]
        line_element = @credit_note ? "cac:CreditNoteLine" : INVOICE_LINE

        model_class = @credit_note ? Model::CreditNote : Model::Invoice

        model_class.new(
          number: text(root, INVOICE[:number]),
          issue_date: parse_date(text(root, INVOICE[:issue_date])),
          due_date: parse_date(text(root, INVOICE[:due_date])),
          type_code: text(root, type_code_element),
          currency_code: text(root, INVOICE[:currency_code]),
          buyer_reference: text(root, INVOICE[:buyer_reference]),
          customization_id: text(root, INVOICE[:customization_id]),
          profile_id: text(root, INVOICE[:profile_id]),
          note: text(root, INVOICE[:note]),
          seller: build_party(root.at_xpath(SELLER, @ns)),
          buyer: build_party(root.at_xpath(BUYER, @ns)),
          line_items: root.xpath(line_element, @ns).map { |n| build_line_item(n) },
          allowance_charges: root.xpath(ALLOWANCE_CHARGE, @ns).map { |n| build_allowance_charge(n) },
          tax_breakdown: build_tax_breakdown(root.at_xpath(TAX_TOTAL, @ns)),
          monetary_totals: build_monetary_totals(root.at_xpath(MONETARY_TOTAL, @ns)),
          payment_instructions: build_payment_instructions(root),
        )
      end

      def build_party(node)
        return nil unless node

        party = Model::TradeParty.new(
          name: text(node, PARTY[:name]),
          trading_name: text(node, PARTY[:trading_name]),
          identifier: text(node, PARTY[:identifier]),
          legal_registration_id: text(node, PARTY[:legal_registration_id]),
          legal_form: text(node, PARTY[:legal_form]),
          vat_identifier: text(node, PARTY[:vat_identifier]),
          electronic_address: text(node, PARTY[:electronic_address]),
        )

        endpoint = node.at_xpath(PARTY[:electronic_address], @ns)
        party.electronic_address_scheme = endpoint["schemeID"] if endpoint

        addr_node = node.at_xpath(POSTAL_ADDRESS, @ns)
        party.postal_address = build_postal_address(addr_node) if addr_node

        contact_node = node.at_xpath(CONTACT, @ns)
        party.contact = build_contact(contact_node) if contact_node

        party
      end

      def build_postal_address(node)
        Model::PostalAddress.new(
          country_code: text(node, ADDRESS[:country_code]),
          street_name: text(node, ADDRESS[:street_name]),
          city_name: text(node, ADDRESS[:city_name]),
          postal_zone: text(node, ADDRESS[:postal_zone]),
        )
      end

      def build_contact(node)
        Model::Contact.new(
          name: text(node, CONTACT_FIELDS[:name]),
          telephone: text(node, CONTACT_FIELDS[:telephone]),
          email: text(node, CONTACT_FIELDS[:email]),
        )
      end

      def build_payment_instructions(root)
        means_node = root.at_xpath(PAYMENT_MEANS, @ns)
        return nil unless means_node

        # BT-90: In UBL, creditor reference is a PartyIdentification with schemeID="SEPA" on the seller
        creditor_ref = root.at_xpath(
          "#{SELLER}/cac:PartyIdentification/cbc:ID[@schemeID='SEPA']", @ns
        )&.text

        Model::PaymentInstructions.new(
          payment_means_code: text(means_node, PAYMENT[:payment_means_code]),
          payment_id: text(means_node, PAYMENT[:payment_id]),
          account_id: text(means_node, PAYMENT[:account_id]),
          card_account_id: text(means_node, PAYMENT[:card_account_id]),
          card_network_id: text(means_node, PAYMENT[:card_network_id]),
          card_holder_name: text(means_node, PAYMENT[:card_holder_name]),
          mandate_reference: text(means_node, PAYMENT[:mandate_reference]),
          debited_account_id: text(means_node, PAYMENT[:debited_account_id]),
          creditor_reference_id: creditor_ref,
          note: text(root, PAYMENT_TERMS_NOTE),
        )
      end

      def build_tax_breakdown(node)
        return nil unless node

        currency = node.at_xpath("cbc:TaxAmount/@currencyID", @ns)&.text

        breakdown = Model::TaxBreakdown.new(
          tax_amount: text(node, "cbc:TaxAmount"),
          currency_code: currency,
        )

        breakdown.subtotals = node.xpath(TAX_SUBTOTAL, @ns).map do |sub|
          sub_currency = sub.at_xpath("cbc:TaxableAmount/@currencyID", @ns)&.text
          Model::TaxSubtotal.new(
            taxable_amount: text(sub, TAX[:taxable_amount]),
            tax_amount: text(sub, TAX[:tax_amount]),
            category_code: text(sub, TAX[:category_code]),
            percent: parse_decimal(text(sub, TAX[:percent])),
            currency_code: sub_currency,
            exemption_reason: text(sub, TAX[:exemption_reason]),
            exemption_reason_code: text(sub, TAX[:exemption_reason_code]),
          )
        end

        breakdown
      end

      def build_monetary_totals(node)
        return nil unless node

        Model::MonetaryTotals.new(
          line_extension_amount: text(node, TOTALS[:line_extension_amount]),
          tax_exclusive_amount: text(node, TOTALS[:tax_exclusive_amount]),
          tax_inclusive_amount: text(node, TOTALS[:tax_inclusive_amount]),
          prepaid_amount: parse_decimal(text(node, TOTALS[:prepaid_amount])),
          payable_rounding_amount: parse_decimal(text(node, TOTALS[:payable_rounding_amount])),
          allowance_total_amount: parse_decimal(text(node, TOTALS[:allowance_total_amount])),
          charge_total_amount: parse_decimal(text(node, TOTALS[:charge_total_amount])),
          payable_amount: text(node, TOTALS[:payable_amount]),
        )
      end

      def build_line_item(node)
        item_node = node.at_xpath(ITEM, @ns)
        price_node = node.at_xpath(PRICE, @ns)

        quantity_element = @credit_note ? "cbc:CreditedQuantity" : LINE[:invoiced_quantity]
        unit_code_element = @credit_note ? "cbc:CreditedQuantity/@unitCode" : LINE[:unit_code]

        Model::LineItem.new(
          id: text(node, LINE[:id]),
          invoiced_quantity: text(node, quantity_element),
          unit_code: node.at_xpath(unit_code_element, @ns)&.text,
          line_extension_amount: text(node, LINE[:line_extension_amount]),
          note: text(node, LINE[:note]),
          item: build_item(item_node),
          price: build_price(price_node),
        )
      end

      def build_item(node)
        return nil unless node

        Model::Item.new(
          name: text(node, ITEM_FIELDS[:name]),
          description: text(node, ITEM_FIELDS[:description]),
          sellers_identifier: text(node, ITEM_FIELDS[:sellers_identifier]),
          tax_category: text(node, ITEM_FIELDS[:tax_category]),
          tax_percent: parse_decimal(text(node, ITEM_FIELDS[:tax_percent])),
        )
      end

      def build_price(node)
        return nil unless node

        Model::Price.new(
          amount: text(node, PRICE_FIELDS[:amount]),
        )
      end

      def build_allowance_charge(node)
        currency = node.at_xpath("cbc:Amount/@currencyID", @ns)&.text
        Model::AllowanceCharge.new(
          charge_indicator: text(node, ALLOWANCE_CHARGE_FIELDS[:charge_indicator]) == "true",
          reason: text(node, ALLOWANCE_CHARGE_FIELDS[:reason]),
          reason_code: text(node, ALLOWANCE_CHARGE_FIELDS[:reason_code]),
          amount: text(node, ALLOWANCE_CHARGE_FIELDS[:amount]),
          base_amount: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:base_amount])),
          multiplier_factor: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:multiplier_factor])),
          tax_category_code: text(node, ALLOWANCE_CHARGE_FIELDS[:tax_category_code]),
          tax_percent: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:tax_percent])),
          currency_code: currency,
        )
      end

      def text(node, xpath)
        node.at_xpath(xpath, @ns)&.text
      end

      def parse_date(str)
        Date.parse(str) if str
      end

      def parse_decimal(str)
        BigDecimal(str) if str
      end
    end
  end
end
