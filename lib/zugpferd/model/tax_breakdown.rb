require "bigdecimal"

module Zugpferd
  module Model
    class TaxBreakdown
      attr_accessor :tax_amount,    # BT-110
                    :currency_code, # from TaxTotal
                    :subtotals      # Array<TaxSubtotal>

      def initialize(tax_amount:, currency_code:, **rest)
        @tax_amount = BigDecimal(tax_amount.to_s)
        @currency_code = currency_code
        @subtotals = []
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
