require "nokogiri"
require "open3"
require "tempfile"

module Zugpferd
  module Validation
    class SchematronValidator
      SVRL_NS = "http://purl.oclc.org/dsdl/svrl"

      XSLT_PATHS = {
        cen_ubl: "schematron/cen/ubl/xslt/EN16931-UBL-validation.xslt",
        cen_cii: "schematron/cen/cii/xslt/EN16931-CII-validation.xslt",
        xrechnung_ubl: "schematron/xrechnung/schematron/ubl/XRechnung-UBL-validation.xsl",
        xrechnung_cii: "schematron/xrechnung/schematron/cii/XRechnung-CII-validation.xsl",
      }.freeze

      SAXON_JARS = [
        "saxon/saxon-he-12.5.jar",
        "saxon/xmlresolver-5.2.2.jar",
      ].freeze

      class TransformError < StandardError; end

      Result = Struct.new(:id, :location, :text, :flag, keyword_init: true)

      def initialize(schemas_path:)
        @schemas_path = schemas_path
      end

      def validate(xml_string, rule_set:)
        xslt_path = resolve_xslt(rule_set)
        svrl_xml = run_saxon(xml_string, xslt_path)
        svrl_doc = Nokogiri::XML(svrl_xml)
        parse_failed_asserts(svrl_doc)
      end

      def validate_all(xml_string, rule_sets:)
        rule_sets.flat_map { |rs| validate(xml_string, rule_set: rs) }
      end

      private

      def resolve_xslt(rule_set)
        path = File.join(@schemas_path, XSLT_PATHS.fetch(rule_set))
        raise ArgumentError,
          "XSLT not found: #{path} – run bin/setup-schemas" \
          unless File.exist?(path)
        path
      end

      def saxon_classpath
        SAXON_JARS.map do |jar|
          path = File.join(@schemas_path, jar)
          raise ArgumentError,
            "#{jar} not found: #{path} – run bin/setup-schemas" \
            unless File.exist?(path)
          path
        end.join(":")
      end

      def run_saxon(xml_string, xslt_path)
        input = Tempfile.new(["input", ".xml"])
        input.write(xml_string)
        input.close

        stdout, stderr, status = Open3.capture3(
          "java", "-cp", saxon_classpath,
          "net.sf.saxon.Transform",
          "-s:#{input.path}",
          "-xsl:#{xslt_path}"
        )

        unless status.success?
          raise TransformError, "Saxon transform failed: #{stderr}"
        end

        stdout
      ensure
        input&.unlink
      end

      def parse_failed_asserts(svrl_doc)
        svrl_doc.xpath("//svrl:failed-assert", "svrl" => SVRL_NS).map do |node|
          Result.new(
            id: node["id"],
            location: node["location"],
            text: node.at_xpath("svrl:text", "svrl" => SVRL_NS)&.text&.strip,
            flag: node["flag"]
          )
        end
      end
    end
  end
end
