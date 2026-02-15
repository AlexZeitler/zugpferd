module Zugpferd
  module Model
    # Partial Invoice (BG-0), type code 326.
    #
    # @example
    #   inv = PartialInvoice.new(number: "P-001", issue_date: Date.today)
    class PartialInvoice
      include BillingDocument

      TYPE_CODE = "326"
    end
  end
end
