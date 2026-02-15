require "nokogiri"

module Zugpferd
  module Validation
    # Validates XML against XSD schemas using Nokogiri.
    #
    # @example
    #   validator = SchemaValidator.new(schemas_path: "vendor/schemas")
    #   errors = validator.validate(xml, schema_key: :ubl_invoice)
    class SchemaValidator
      XSD_PATHS = {
        ubl_invoice: "ubl/xsd/maindoc/UBL-Invoice-2.1.xsd",
        ubl_credit_note: "ubl/xsd/maindoc/UBL-CreditNote-2.1.xsd",
        cii: "cii/CrossIndustryInvoice_100pD16B.xsd",
      }.freeze

      # @param schemas_path [String] path to the schemas directory
      def initialize(schemas_path:)
        @schemas_path = schemas_path
        @schema_cache = {}
      end

      # Validates XML against an XSD schema.
      #
      # @param xml_string [String] XML to validate
      # @param schema_key [Symbol] one of +:ubl_invoice+, +:ubl_credit_note+, +:cii+
      # @return [Array<String>] error messages (empty if valid)
      def validate(xml_string, schema_key:)
        doc = Nokogiri::XML(xml_string)
        schema = load_schema(schema_key)
        schema.validate(doc).map(&:message)
      end

      private

      def load_schema(key)
        @schema_cache[key] ||= begin
          path = File.join(@schemas_path, XSD_PATHS.fetch(key))
          Dir.chdir(File.dirname(path)) do
            Nokogiri::XML::Schema(File.read(File.basename(path)))
          end
        end
      end
    end
  end
end
