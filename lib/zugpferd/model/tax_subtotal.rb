require "bigdecimal"

module Zugpferd
  module Model
    class TaxSubtotal
      attr_accessor :taxable_amount,        # BT-116
                    :tax_amount,            # BT-117
                    :category_code,         # BT-118
                    :percent,               # BT-119
                    :currency_code,
                    :exemption_reason,      # BT-120
                    :exemption_reason_code  # BT-121

      def initialize(taxable_amount:, tax_amount:, category_code:, currency_code:, **rest)
        @taxable_amount = BigDecimal(taxable_amount.to_s)
        @tax_amount = BigDecimal(tax_amount.to_s)
        @category_code = category_code
        @currency_code = currency_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
