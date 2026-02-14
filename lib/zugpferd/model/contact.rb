module Zugpferd
  module Model
    class Contact
      attr_accessor :name,       # BT-41 / BT-56
                    :telephone,  # BT-42 / BT-57
                    :email       # BT-43 / BT-58

      def initialize(**attrs)
        attrs.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
