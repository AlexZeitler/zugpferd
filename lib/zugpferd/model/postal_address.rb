module Zugpferd
  module Model
    # Postal address (BG-5 / BG-8 / BG-15).
    class PostalAddress
      # @return [String, nil] BT-35/BT-50/BT-75 Street name
      # @return [String, nil] BT-37/BT-52/BT-77 City name
      # @return [String, nil] BT-38/BT-53/BT-78 Postal zone
      # @return [String] BT-40/BT-55/BT-80 Country code
      attr_accessor :street_name, :city_name, :postal_zone, :country_code

      # @param country_code [String] BT-40/BT-55/BT-80 Country code (ISO 3166-1 alpha-2)
      # @param rest [Hash] additional attributes set via accessors
      def initialize(country_code:, **rest)
        @country_code = country_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
