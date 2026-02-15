module Zugpferd
  module Model
    # Contact information (BG-6 / BG-9).
    class Contact
      # @return [String, nil] BT-41/BT-56 Contact name
      # @return [String, nil] BT-42/BT-57 Telephone
      # @return [String, nil] BT-43/BT-58 Email address
      attr_accessor :name, :telephone, :email

      # @param attrs [Hash] attributes set via accessors
      def initialize(**attrs)
        attrs.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
