require "bigdecimal"

module Zugpferd
  module Model
    class LineItem
      attr_accessor :id,                  # BT-126
                    :invoiced_quantity,    # BT-129
                    :unit_code,           # BT-130
                    :line_extension_amount, # BT-131
                    :note,                # BT-127
                    :item,                # BG-31 (Item)
                    :price                # BG-29 (Price)

      def initialize(id:, invoiced_quantity:, unit_code:,
                     line_extension_amount:, **rest)
        @id = id
        @invoiced_quantity = BigDecimal(invoiced_quantity.to_s)
        @unit_code = unit_code
        @line_extension_amount = BigDecimal(line_extension_amount.to_s)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
