module Zugpferd
  module Model
    # A seller (BG-4) or buyer (BG-7) party.
    #
    # @example
    #   party = TradeParty.new(name: "Seller GmbH")
    #   party.vat_identifier = "DE123456789"
    class TradeParty
      # @return [String] BT-27/BT-44 Legal name
      # @return [String, nil] BT-28/BT-45 Trading name
      # @return [String, nil] BT-29/BT-46 Party identifier
      # @return [String, nil] BT-30/BT-47 Legal registration identifier
      # @return [String, nil] BT-33 Company legal form
      # @return [String, nil] BT-31/BT-48 VAT identifier
      # @return [String, nil] BT-34/BT-49 Electronic address
      # @return [String, nil] BT-34-1/BT-49-1 Electronic address scheme
      # @return [PostalAddress, nil] BG-5/BG-8 Postal address
      # @return [Contact, nil] BG-6/BG-9 Contact information
      attr_accessor :name, :trading_name, :identifier,
                    :legal_registration_id, :legal_form, :vat_identifier,
                    :electronic_address, :electronic_address_scheme,
                    :postal_address, :contact

      # @param name [String] BT-27/BT-44 Legal name
      # @param rest [Hash] additional attributes set via accessors
      def initialize(name:, **rest)
        @name = name
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
