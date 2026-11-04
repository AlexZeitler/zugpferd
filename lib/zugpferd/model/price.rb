require "bigdecimal"

module Zugpferd
  module Model
    # Price details (BG-29).
    class Price
      # @return [BigDecimal] BT-146 Item net price
      # @return [BigDecimal, nil] BT-149 Item price base quantity
      # @return [String, nil] BT-150 Item price base quantity unit of measure code
      attr_accessor :amount, :base_quantity, :base_quantity_unit_code

      # @param amount [String, BigDecimal] BT-146 Item net price
      # @param rest [Hash] additional attributes set via accessors
      def initialize(amount:, **rest)
        @amount = BigDecimal(amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
