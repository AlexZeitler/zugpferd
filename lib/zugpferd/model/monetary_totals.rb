require "bigdecimal"

module Zugpferd
  module Model
    class MonetaryTotals
      attr_accessor :line_extension_amount,    # BT-106
                    :tax_exclusive_amount,     # BT-109
                    :tax_inclusive_amount,      # BT-112
                    :prepaid_amount,            # BT-113
                    :payable_rounding_amount,   # BT-114
                    :payable_amount,            # BT-115
                    :allowance_total_amount,    # BT-107
                    :charge_total_amount        # BT-108

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
