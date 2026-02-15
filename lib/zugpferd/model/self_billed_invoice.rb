module Zugpferd
  module Model
    # Self-billed Invoice (BG-0), type code 389.
    #
    # @example
    #   inv = SelfBilledInvoice.new(number: "SB-001", issue_date: Date.today)
    class SelfBilledInvoice
      include BillingDocument

      TYPE_CODE = "389"
    end
  end
end
