require "nokogiri"
require "date"
require "bigdecimal"
require_relative "mapping"

module Zugpferd
  module CII
    # Reads UN/CEFACT CII CrossIndustryInvoice XML into {Model::Invoice}.
    #
    # @example
    #   invoice = Zugpferd::CII::Reader.new.read(File.read("invoice.xml"))
    class Reader
      include Mapping

      # Parses a CII CrossIndustryInvoice XML string.
      #
      # @param xml_string [String] valid CII D16B XML
      # @return [Model::Invoice]
      # @raise [Nokogiri::XML::SyntaxError] if the XML is malformed
      def read(xml_string)
        doc = Nokogiri::XML(xml_string) { |config| config.strict }
        root = doc.root
        build_invoice(root)
      end

      private

      def build_invoice(root)
        settlement = root.at_xpath(SETTLEMENT, NS)
        Model::Invoice.new(
          number: text(root, INVOICE[:number]),
          issue_date: parse_cii_date(text(root, INVOICE[:issue_date])),
          due_date: parse_cii_date(settlement ? text(settlement, PAYMENT_TERMS_DUE_DATE) : nil),
          type_code: text(root, INVOICE[:type_code]),
          currency_code: text(root, INVOICE_SETTLEMENT[:currency_code]),
          buyer_reference: text(root, INVOICE_SETTLEMENT[:buyer_reference]),
          customization_id: text(root, INVOICE[:customization_id]),
          profile_id: text(root, INVOICE[:profile_id]),
          note: text(root, INVOICE[:note]),
          seller: build_party(root.at_xpath(SELLER, NS)),
          buyer: build_party(root.at_xpath(BUYER, NS)),
          line_items: root.xpath(INVOICE_LINE, NS).map { |n| build_line_item(n) },
          allowance_charges: settlement ? build_allowance_charges(settlement) : [],
          tax_breakdown: build_tax_breakdown(settlement),
          monetary_totals: build_monetary_totals(settlement&.at_xpath(MONETARY_TOTAL, NS)),
          payment_instructions: build_payment_instructions(settlement),
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

        endpoint = node.at_xpath(PARTY[:electronic_address], NS)
        party.electronic_address_scheme = endpoint["schemeID"] if endpoint

        addr_node = node.at_xpath(POSTAL_ADDRESS, NS)
        party.postal_address = build_postal_address(addr_node) if addr_node

        contact_node = node.at_xpath(CONTACT, NS)
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

      def build_payment_instructions(settlement_node)
        return nil unless settlement_node

        means_node = settlement_node.at_xpath(PAYMENT_MEANS, NS)
        return nil unless means_node

        Model::PaymentInstructions.new(
          payment_means_code: text(means_node, PAYMENT[:payment_means_code]),
          payment_id: text(settlement_node, PAYMENT_REFERENCE),
          account_id: text(means_node, PAYMENT[:account_id]),
          card_account_id: text(means_node, PAYMENT[:card_account_id]),
          card_holder_name: text(means_node, PAYMENT[:card_holder_name]),
          debited_account_id: text(means_node, PAYMENT[:debited_account_id]),
          creditor_reference_id: text(settlement_node, CREDITOR_REFERENCE_ID),
          mandate_reference: text(settlement_node, PAYMENT_TERMS_MANDATE),
          note: text(settlement_node, PAYMENT_TERMS_NOTE),
        )
      end

      def build_tax_breakdown(settlement_node)
        return nil unless settlement_node

        totals_node = settlement_node.at_xpath(MONETARY_TOTAL, NS)
        tax_total_node = totals_node&.at_xpath(TOTALS[:tax_total_amount], NS)
        currency = tax_total_node&.[]("currencyID")

        breakdown = Model::TaxBreakdown.new(
          tax_amount: tax_total_node&.text,
          currency_code: currency,
        )

        breakdown.subtotals = settlement_node.xpath(TAX_SUBTOTAL, NS).map do |sub|
          Model::TaxSubtotal.new(
            taxable_amount: text(sub, TAX[:taxable_amount]),
            tax_amount: text(sub, TAX[:tax_amount]),
            category_code: text(sub, TAX[:category_code]),
            percent: parse_decimal(text(sub, TAX[:percent])),
            currency_code: currency,
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
        item_node = node.at_xpath(ITEM, NS)
        price_node = node.at_xpath(PRICE, NS)
        tax_node = node.at_xpath(ITEM_TAX, NS)

        Model::LineItem.new(
          id: text(node, LINE[:id]),
          invoiced_quantity: text(node, LINE[:invoiced_quantity]),
          unit_code: node.at_xpath(LINE[:unit_code], NS)&.text,
          line_extension_amount: text(node, LINE[:line_extension_amount]),
          note: text(node, LINE[:note]),
          item: build_item(item_node, tax_node),
          price: build_price(price_node),
        )
      end

      def build_item(node, tax_node)
        return nil unless node

        Model::Item.new(
          name: text(node, ITEM_FIELDS[:name]),
          description: text(node, ITEM_FIELDS[:description]),
          sellers_identifier: text(node, ITEM_FIELDS[:sellers_identifier]),
          tax_category: tax_node ? text(tax_node, ITEM_TAX_FIELDS[:tax_category]) : nil,
          tax_percent: tax_node ? parse_decimal(text(tax_node, ITEM_TAX_FIELDS[:tax_percent])) : nil,
        )
      end

      def build_price(node)
        return nil unless node

        Model::Price.new(
          amount: text(node, PRICE_FIELDS[:amount]),
        )
      end

      def build_allowance_charges(settlement_node)
        settlement_node.xpath(ALLOWANCE_CHARGE, NS).map do |node|
          Model::AllowanceCharge.new(
            charge_indicator: text(node, ALLOWANCE_CHARGE_FIELDS[:charge_indicator]) == "true",
            reason: text(node, ALLOWANCE_CHARGE_FIELDS[:reason]),
            reason_code: text(node, ALLOWANCE_CHARGE_FIELDS[:reason_code]),
            amount: text(node, ALLOWANCE_CHARGE_FIELDS[:amount]),
            base_amount: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:base_amount])),
            multiplier_factor: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:multiplier_factor])),
            tax_category_code: text(node, ALLOWANCE_CHARGE_FIELDS[:tax_category_code]),
            tax_percent: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:tax_percent])),
          )
        end
      end

      def text(node, xpath)
        node.at_xpath(xpath, NS)&.text
      end

      def parse_cii_date(str)
        return nil unless str
        # CII format 102 = YYYYMMDD
        Date.strptime(str, "%Y%m%d")
      end

      def parse_decimal(str)
        BigDecimal(str) if str
      end
    end
  end
end
