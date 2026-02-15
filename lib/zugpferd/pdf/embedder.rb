require "open3"
require "tempfile"

module Zugpferd
  module PDF
    class Embedder
      class GhostscriptNotFound < Zugpferd::Error; end
      class EmbedError < Zugpferd::Error; end

      VERSIONS = %w[rc 1p0 2p0 2p1].freeze

      CONFORMANCE_LEVELS = {
        "2p1" => ["MINIMUM", "BASIC WL", "BASIC", "EN 16931", "EXTENDED", "XRECHNUNG"],
        "2p0" => ["MINIMUM", "BASIC WL", "BASIC", "EN 16931", "EXTENDED", "XRECHNUNG"],
        "1p0" => ["BASIC", "COMFORT", "EXTENDED"],
      }.freeze

      # @param pdf_path [String] Pfad zum Input-PDF
      # @param xml [String] XML-String (UBL oder CII)
      # @param output_path [String] Pfad zur Ausgabe-PDF
      # @param version [String] "2p1" (default), "2p0", "1p0", "rc"
      # @param conformance_level [String] "EN 16931" (default), "BASIC", etc.
      # @return [String] Pfad zur erzeugten PDF-Datei
      def embed(pdf_path:, xml:, output_path:, version: "2p1", conformance_level: "EN 16931")
        validate_params!(pdf_path, version, conformance_level)
        ensure_ghostscript!

        xml_file = write_xml_tempfile(xml)
        begin
          run_ghostscript(pdf_path, xml_file.path, output_path, version, conformance_level)
        ensure
          xml_file.close!
        end

        output_path
      end

      private

      def validate_params!(pdf_path, version, conformance_level)
        raise ArgumentError, "PDF file not found: #{pdf_path}" unless File.exist?(pdf_path)
        raise ArgumentError, "Unknown version: #{version}. Valid: #{VERSIONS.join(", ")}" unless VERSIONS.include?(version)

        if version != "rc"
          valid_levels = CONFORMANCE_LEVELS[version]
          unless valid_levels&.include?(conformance_level)
            raise ArgumentError,
              "Unknown conformance level '#{conformance_level}' for version #{version}. " \
              "Valid: #{valid_levels.join(", ")}"
          end
        end
      end

      def ensure_ghostscript!
        _, _, status = Open3.capture3("gs", "--version")
        raise GhostscriptNotFound, "Ghostscript (gs) not found in PATH" unless status.success?
      rescue Errno::ENOENT
        raise GhostscriptNotFound, "Ghostscript (gs) not found in PATH"
      end

      def vendor_dir
        File.expand_path("../../../vendor/zugferd", __dir__)
      end

      def zugferd_ps_path
        File.join(vendor_dir, "zugferd.ps")
      end

      def icc_profile_path
        File.join(vendor_dir, "default_rgb.icc")
      end

      def write_xml_tempfile(xml)
        tmpfile = Tempfile.new(["zugferd", ".xml"])
        tmpfile.binmode
        tmpfile.write(xml)
        tmpfile.flush
        tmpfile
      end

      def run_ghostscript(pdf_path, xml_path, output_path, version, conformance_level)
        ps_path = zugferd_ps_path
        icc_path = icc_profile_path

        unless File.exist?(ps_path)
          raise EmbedError, "zugferd.ps not found at #{ps_path}. Run bin/setup-schemas."
        end

        unless File.exist?(icc_path)
          raise EmbedError, "ICC profile not found at #{icc_path}. Run bin/setup-schemas."
        end

        cmd = build_command(pdf_path, xml_path, output_path, version, conformance_level, ps_path, icc_path)
        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          raise EmbedError, "Ghostscript failed (exit #{status.exitstatus}):\n#{stderr}#{stdout}"
        end

        unless File.exist?(output_path)
          raise EmbedError, "Ghostscript did not produce output file: #{output_path}"
        end
      end

      def build_command(pdf_path, xml_path, output_path, version, conformance_level, ps_path, icc_path)
        cmd = %w[gs]
        cmd += %w[-dBATCH -dNOPAUSE -dNOOUTERSAVE]
        cmd += %w[-sDEVICE=pdfwrite]
        cmd += %w[-dPDFA=3 -dPDFACompatibilityPolicy=1]
        cmd += %w[-sColorConversionStrategy=RGB -sProcessColorModel=DeviceRGB]
        cmd << "--permit-file-read=#{xml_path}"
        cmd << "--permit-file-read=#{icc_path}"
        cmd << "--permit-file-read=#{pdf_path}"
        cmd << "-sZUGFeRDXMLFile=#{xml_path}"
        cmd << "-sZUGFeRDProfile=#{icc_path}"
        cmd << "-sZUGFeRDVersion=#{version}"
        cmd << "-sZUGFeRDConformanceLevel=#{conformance_level}"
        cmd << "-o"
        cmd << output_path
        cmd << ps_path
        cmd << pdf_path
        cmd
      end
    end
  end
end
