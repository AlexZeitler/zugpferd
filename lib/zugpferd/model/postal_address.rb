module Zugpferd
  module Model
    class PostalAddress
      attr_accessor :street_name,     # BT-35 / BT-50
                    :city_name,       # BT-37 / BT-52
                    :postal_zone,     # BT-38 / BT-53
                    :country_code     # BT-40 / BT-55

      def initialize(country_code:, **rest)
        @country_code = country_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
