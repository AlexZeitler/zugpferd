module Zugpferd
  module Model
    # Item information (BG-31).
    class Item
      # @return [String] BT-153 Item name
      # @return [String, nil] BT-154 Item description
      # @return [String, nil] BT-155 Seller's item identifier
      # @return [String, nil] BT-151 Invoiced item VAT category code
      # @return [BigDecimal, nil] BT-152 Invoiced item VAT rate
      # @return [Array] BT-158 Item classification codes
      attr_accessor :name, :description, :sellers_identifier,
                    :tax_category, :tax_percent, :classification_codes

      # @param name [String] BT-153 Item name
      # @param rest [Hash] additional attributes set via accessors
      def initialize(name:, **rest)
        @name = name
        @classification_codes = []
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
