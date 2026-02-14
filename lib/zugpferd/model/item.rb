module Zugpferd
  module Model
    class Item
      attr_accessor :name,              # BT-153
                    :description,       # BT-154
                    :sellers_identifier, # BT-155
                    :tax_category,      # BT-151
                    :tax_percent,       # BT-152
                    :classification_codes # BT-158 (Array)

      def initialize(name:, **rest)
        @name = name
        @classification_codes = []
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
