require "bigdecimal"

module Zugpferd
  module Model
    class AllowanceCharge
      attr_accessor :charge_indicator,          # true = charge (BG-21), false = allowance (BG-20)
                    :reason,                    # BT-97 / BT-104
                    :reason_code,               # BT-98 / BT-105
                    :amount,                    # BT-92 / BT-99
                    :base_amount,               # BT-93 / BT-100
                    :multiplier_factor,         # BT-94 / BT-101
                    :tax_category_code,         # BT-95 / BT-102
                    :tax_percent,               # BT-96 / BT-103
                    :currency_code

      def initialize(charge_indicator:, amount:, **rest)
        @charge_indicator = charge_indicator
        @amount = BigDecimal(amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end

      def charge?
        charge_indicator
      end

      def allowance?
        !charge_indicator
      end
    end
  end
end
