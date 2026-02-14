require "bigdecimal"

module Zugpferd
  module Model
    class MonetaryTotals
      attr_accessor :line_extension_amount,  # BT-106
                    :tax_exclusive_amount,   # BT-109
                    :tax_inclusive_amount,    # BT-112
                    :payable_amount          # BT-115

      def initialize(line_extension_amount:, tax_exclusive_amount:,
                     tax_inclusive_amount:, payable_amount:, **rest)
        @line_extension_amount = BigDecimal(line_extension_amount.to_s)
        @tax_exclusive_amount = BigDecimal(tax_exclusive_amount.to_s)
        @tax_inclusive_amount = BigDecimal(tax_inclusive_amount.to_s)
        @payable_amount = BigDecimal(payable_amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
