module Zugpferd
  module Model
    class TradeParty
      attr_accessor :name,                  # BT-27 / BT-44
                    :trading_name,          # BT-28 / BT-45
                    :identifier,            # BT-29 / BT-46
                    :legal_registration_id, # BT-30 / BT-47
                    :legal_form,            # BT-33
                    :vat_identifier,        # BT-31 / BT-48
                    :electronic_address,    # BT-34 / BT-49
                    :electronic_address_scheme, # BT-34-1 / BT-49-1
                    :postal_address,        # BG-5 / BG-8 (PostalAddress)
                    :contact                # BG-6 / BG-9 (Contact)

      def initialize(name:, **rest)
        @name = name
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
