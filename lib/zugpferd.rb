require_relative "zugpferd/model/invoice"
require_relative "zugpferd/model/trade_party"
require_relative "zugpferd/model/postal_address"
require_relative "zugpferd/model/contact"
require_relative "zugpferd/model/line_item"
require_relative "zugpferd/model/item"
require_relative "zugpferd/model/price"
require_relative "zugpferd/model/monetary_totals"
require_relative "zugpferd/model/tax_breakdown"
require_relative "zugpferd/model/tax_subtotal"
require_relative "zugpferd/model/payment_instructions"
require_relative "zugpferd/model/allowance_charge"
require_relative "zugpferd/ubl/reader"
require_relative "zugpferd/ubl/writer"
require_relative "zugpferd/cii/reader"
require_relative "zugpferd/cii/writer"

module Zugpferd
  class Error < StandardError; end
end
