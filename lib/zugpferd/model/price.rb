require "bigdecimal"

module Zugpferd
  module Model
    class Price
      attr_accessor :amount,       # BT-146
                    :base_quantity # BT-149

      def initialize(amount:, **rest)
        @amount = BigDecimal(amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
