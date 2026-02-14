require "bigdecimal"

module Zugpferd
  module Model
    class Invoice
      attr_accessor :number,               # BT-1
                    :issue_date,           # BT-2
                    :due_date,             # BT-9
                    :type_code,            # BT-3
                    :currency_code,        # BT-5
                    :buyer_reference,      # BT-10
                    :customization_id,     # BT-24
                    :profile_id,           # BT-23
                    :note,                 # BT-22
                    :seller,               # BG-4  (TradeParty)
                    :buyer,                # BG-7  (TradeParty)
                    :line_items,           # BG-25 (Array<LineItem>)
                    :tax_breakdown,        # BG-23 (TaxBreakdown)
                    :monetary_totals,      # BG-22 (MonetaryTotals)
                    :payment_instructions, # BG-16 (PaymentInstructions)
                    :allowance_charges     # BG-20/BG-21 (Array<AllowanceCharge>)

      def initialize(number:, issue_date:, type_code: "380",
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
