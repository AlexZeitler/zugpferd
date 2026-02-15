require "bigdecimal"

module Zugpferd
  module Model
    # An invoice line (BG-25).
    class LineItem
      # @return [String] BT-126 Line identifier
      # @return [BigDecimal] BT-129 Invoiced quantity
      # @return [String] BT-130 Unit of measure code
      # @return [BigDecimal] BT-131 Line extension amount
      # @return [String, nil] BT-127 Invoice line note
      # @return [Item, nil] BG-31 Item information
      # @return [Price, nil] BG-29 Price details
      attr_accessor :id, :invoiced_quantity, :unit_code,
                    :line_extension_amount, :note, :item, :price

      # @param id [String] BT-126 Line identifier
      # @param invoiced_quantity [String, BigDecimal] BT-129 Quantity
      # @param unit_code [String] BT-130 Unit of measure code
      # @param line_extension_amount [String, BigDecimal] BT-131 Line total
      # @param rest [Hash] additional attributes set via accessors
      def initialize(id:, invoiced_quantity:, unit_code:,
                     line_extension_amount:, **rest)
        @id = id
        @invoiced_quantity = BigDecimal(invoiced_quantity.to_s)
        @unit_code = unit_code
        @line_extension_amount = BigDecimal(line_extension_amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
