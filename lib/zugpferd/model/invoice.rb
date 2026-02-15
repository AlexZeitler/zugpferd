module Zugpferd
  module Model
    # Commercial Invoice (BG-0), type code 380.
    #
    # @example
    #   invoice = Invoice.new(number: "INV-001", issue_date: Date.today)
    #   invoice.seller = TradeParty.new(name: "Seller GmbH")
    class Invoice
      include BillingDocument

      TYPE_CODE = "380"
    end
  end
end
