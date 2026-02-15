require "bigdecimal"

module Zugpferd
  module Model
    # Shared behaviour for all billing document types (BG-0).
    #
    # Each including class must define a +TYPE_CODE+ constant that serves as
    # the default value for +type_code+.
    #
    # @example
    #   class Invoice
    #     include BillingDocument
    #     TYPE_CODE = "380"
    #   end
    module BillingDocument
      # @return [String] BT-1 Invoice number
      # @return [Date] BT-2 Issue date
      # @return [Date, nil] BT-9 Payment due date
      # @return [String] BT-3 Invoice type code
      # @return [String] BT-5 Document currency code (default: "EUR")
      # @return [String, nil] BT-10 Buyer reference
      # @return [String, nil] BT-24 Specification identifier
      # @return [String, nil] BT-23 Business process type
      # @return [String, nil] BT-22 Invoice note
      # @return [TradeParty, nil] BG-4 Seller party
      # @return [TradeParty, nil] BG-7 Buyer party
      # @return [Array<LineItem>] BG-25 Invoice lines
      # @return [TaxBreakdown, nil] BG-23 VAT breakdown
      # @return [MonetaryTotals, nil] BG-22 Document totals
      # @return [PaymentInstructions, nil] BG-16 Payment information
      # @return [Array<AllowanceCharge>] BG-20/BG-21 Document-level allowances and charges
      attr_accessor :number, :issue_date, :due_date, :type_code,
                    :currency_code, :buyer_reference, :customization_id,
                    :profile_id, :note, :seller, :buyer, :line_items,
                    :tax_breakdown, :monetary_totals, :payment_instructions,
                    :allowance_charges

      # @param number [String] BT-1 Invoice number
      # @param issue_date [Date] BT-2 Issue date
      # @param type_code [String] BT-3 Invoice type code (defaults to the class's TYPE_CODE)
      # @param currency_code [String] BT-5 Document currency code
      # @param rest [Hash] additional attributes set via accessors
      def initialize(number:, issue_date:, type_code: self.class::TYPE_CODE,
                     currency_code: "EUR", **rest)
        @number = number
        @issue_date = issue_date
        @type_code = type_code
        @currency_code = currency_code
        @line_items = []
        @allowance_charges = []
        @tax_breakdown = nil
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
