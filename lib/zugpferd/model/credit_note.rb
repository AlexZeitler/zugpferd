module Zugpferd
  module Model
    # Credit Note (BG-0), type code 381.
    #
    # @example
    #   cn = CreditNote.new(number: "CN-001", issue_date: Date.today)
    class CreditNote
      include BillingDocument

      TYPE_CODE = "381"
    end
  end
end
