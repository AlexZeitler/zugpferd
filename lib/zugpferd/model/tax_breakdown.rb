require "bigdecimal"

module Zugpferd
  module Model
    # VAT breakdown (BG-23).
    class TaxBreakdown
      # @return [BigDecimal] BT-110 Invoice total VAT amount
      # @return [String] Tax currency code
      # @return [Array<TaxSubtotal>] Individual VAT category breakdowns
      attr_accessor :tax_amount, :currency_code, :subtotals

      # @param tax_amount [String, BigDecimal] BT-110 Total VAT amount
      # @param currency_code [String] Tax currency code
      # @param rest [Hash] additional attributes set via accessors
      def initialize(tax_amount:, currency_code:, **rest)
        @tax_amount = BigDecimal(tax_amount.to_s)
        @currency_code = currency_code
        @subtotals = []
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
