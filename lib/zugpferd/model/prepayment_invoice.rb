module Zugpferd
  module Model
    # Prepayment Invoice (BG-0), type code 386.
    #
    # @example
    #   inv = PrepaymentInvoice.new(number: "PP-001", issue_date: Date.today)
    class PrepaymentInvoice
      include BillingDocument

      TYPE_CODE = "386"
    end
  end
end
