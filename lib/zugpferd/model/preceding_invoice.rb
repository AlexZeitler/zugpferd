module Zugpferd
  module Model
    # Reference to a preceding invoice (BG-3).
    class PrecedingInvoice
      # @return [String] BT-25 Preceding invoice number
      # @return [Date, nil] BT-26 Preceding invoice issue date
      attr_accessor :number, :issue_date

      # @param number [String] BT-25 Preceding invoice number
      # @param rest [Hash] additional attributes set via accessors
      def initialize(number:, **rest)
        @number = number
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
