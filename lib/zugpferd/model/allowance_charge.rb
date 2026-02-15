require "bigdecimal"

module Zugpferd
  module Model
    # Document-level allowance (BG-20) or charge (BG-21).
    #
    # @example Create a charge
    #   charge = AllowanceCharge.new(charge_indicator: true, amount: "50.00")
    #   charge.charge? # => true
    #
    # @example Create an allowance
    #   allowance = AllowanceCharge.new(charge_indicator: false, amount: "10.00")
    #   allowance.allowance? # => true
    class AllowanceCharge
      # @return [Boolean] +true+ for charge (BG-21), +false+ for allowance (BG-20)
      # @return [String, nil] BT-97/BT-104 Allowance/charge reason
      # @return [String, nil] BT-98/BT-105 Allowance/charge reason code
      # @return [BigDecimal] BT-92/BT-99 Allowance/charge amount
      # @return [BigDecimal, nil] BT-93/BT-100 Base amount
      # @return [BigDecimal, nil] BT-94/BT-101 Percentage
      # @return [String, nil] BT-95/BT-102 Tax category code
      # @return [BigDecimal, nil] BT-96/BT-103 Tax rate
      # @return [String, nil] Currency code
      attr_accessor :charge_indicator, :reason, :reason_code,
                    :amount, :base_amount, :multiplier_factor,
                    :tax_category_code, :tax_percent, :currency_code

      # @param charge_indicator [Boolean] +true+ for charge, +false+ for allowance
      # @param amount [String, BigDecimal] Allowance/charge amount
      # @param rest [Hash] additional attributes set via accessors
      def initialize(charge_indicator:, amount:, **rest)
        @charge_indicator = charge_indicator
        @amount = BigDecimal(amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end

      # @return [Boolean] whether this is a charge
      def charge?
        charge_indicator
      end

      # @return [Boolean] whether this is an allowance
      def allowance?
        !charge_indicator
      end
    end
  end
end
