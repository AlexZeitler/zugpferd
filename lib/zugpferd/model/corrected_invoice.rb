module Zugpferd
  module Model
    # Corrected Invoice (BG-0), type code 384.
    #
    # @example
    #   inv = CorrectedInvoice.new(number: "C-001", issue_date: Date.today)
    class CorrectedInvoice
      include BillingDocument

      TYPE_CODE = "384"
    end
  end
end
