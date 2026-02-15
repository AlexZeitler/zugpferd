require "bigdecimal"

module Zugpferd
  module Model
    # Document level monetary totals (BG-22).
    class MonetaryTotals
      # @return [BigDecimal] BT-106 Sum of invoice line net amounts
      # @return [BigDecimal] BT-109 Invoice total without VAT
      # @return [BigDecimal] BT-112 Invoice total with VAT
      # @return [BigDecimal] BT-115 Amount due for payment
      # @return [BigDecimal, nil] BT-113 Paid amount
      # @return [BigDecimal, nil] BT-114 Rounding amount
      # @return [BigDecimal, nil] BT-107 Sum of allowances on document level
      # @return [BigDecimal, nil] BT-108 Sum of charges on document level
      attr_accessor :line_extension_amount, :tax_exclusive_amount,
                    :tax_inclusive_amount, :payable_amount,
                    :prepaid_amount, :payable_rounding_amount,
                    :allowance_total_amount, :charge_total_amount

      # @param line_extension_amount [String, BigDecimal] BT-106
      # @param tax_exclusive_amount [String, BigDecimal] BT-109
      # @param tax_inclusive_amount [String, BigDecimal] BT-112
      # @param payable_amount [String, BigDecimal] BT-115
      # @param rest [Hash] additional attributes set via accessors
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
