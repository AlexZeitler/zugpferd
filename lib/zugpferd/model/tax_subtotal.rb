require "bigdecimal"

module Zugpferd
  module Model
    # A single VAT category breakdown within {TaxBreakdown}.
    class TaxSubtotal
      # @return [BigDecimal] BT-116 VAT category taxable amount
      # @return [BigDecimal] BT-117 VAT category tax amount
      # @return [String] BT-118 VAT category code
      # @return [BigDecimal, nil] BT-119 VAT category rate
      # @return [String] Currency code
      # @return [String, nil] BT-120 VAT exemption reason text
      # @return [String, nil] BT-121 VAT exemption reason code
      attr_accessor :taxable_amount, :tax_amount, :category_code,
                    :percent, :currency_code,
                    :exemption_reason, :exemption_reason_code

      # @param taxable_amount [String, BigDecimal] BT-116
      # @param tax_amount [String, BigDecimal] BT-117
      # @param category_code [String] BT-118
      # @param currency_code [String] Currency code
      # @param rest [Hash] additional attributes set via accessors
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
