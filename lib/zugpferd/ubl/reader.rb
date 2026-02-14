require "nokogiri"
require "date"
require "bigdecimal"
require_relative "mapping"

module Zugpferd
  module UBL
    class Reader
      include Mapping

      def read(xml_string)
        doc = Nokogiri::XML(xml_string) { |config| config.strict }
        root = doc.root
        build_invoice(root)
      end

      private

      def build_invoice(root)
        Model::Invoice.new(
          number: text(root, INVOICE[:number]),
          issue_date: parse_date(text(root, INVOICE[:issue_date])),
          type_code: text(root, INVOICE[:type_code]),
          currency_code: text(root, INVOICE[:currency_code]),
          buyer_reference: text(root, INVOICE[:buyer_reference]),
          customization_id: text(root, INVOICE[:customization_id]),
          profile_id: text(root, INVOICE[:profile_id]),
          note: text(root, INVOICE[:note]),
          seller: build_party(root.at_xpath(SELLER, NS)),
          buyer: build_party(root.at_xpath(BUYER, NS)),
          line_items: root.xpath(INVOICE_LINE, NS).map { |n| build_line_item(n) },
          tax_breakdown: build_tax_breakdown(root.at_xpath(TAX_TOTAL, NS)),
          monetary_totals: build_monetary_totals(root.at_xpath(MONETARY_TOTAL, NS)),
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

      def build_payment_instructions(root)
        means_node = root.at_xpath(PAYMENT_MEANS, NS)
        return nil unless means_node

        Model::PaymentInstructions.new(
          payment_means_code: text(means_node, PAYMENT[:payment_means_code]),
          payment_id: text(means_node, PAYMENT[:payment_id]),
          account_id: text(means_node, PAYMENT[:account_id]),
          note: text(root, PAYMENT_TERMS_NOTE),
        )
      end

      def build_tax_breakdown(node)
        return nil unless node

        currency = node.at_xpath("cbc:TaxAmount/@currencyID", NS)&.text

        breakdown = Model::TaxBreakdown.new(
          tax_amount: text(node, "cbc:TaxAmount"),
          currency_code: currency,
        )

        breakdown.subtotals = node.xpath(TAX_SUBTOTAL, NS).map do |sub|
          sub_currency = sub.at_xpath("cbc:TaxableAmount/@currencyID", NS)&.text
          Model::TaxSubtotal.new(
            taxable_amount: text(sub, TAX[:taxable_amount]),
            tax_amount: text(sub, TAX[:tax_amount]),
            category_code: text(sub, TAX[:category_code]),
            percent: parse_decimal(text(sub, TAX[:percent])),
            currency_code: sub_currency,
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
          payable_amount: text(node, TOTALS[:payable_amount]),
        )
      end

      def build_line_item(node)
        item_node = node.at_xpath(ITEM, NS)
        price_node = node.at_xpath(PRICE, NS)

        Model::LineItem.new(
          id: text(node, LINE[:id]),
          invoiced_quantity: text(node, LINE[:invoiced_quantity]),
          unit_code: node.at_xpath(LINE[:unit_code], NS)&.text,
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

      def text(node, xpath)
        node.at_xpath(xpath, NS)&.text
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
