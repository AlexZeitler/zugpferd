require "nokogiri"
require "set"
require "zlib"

module Zugpferd
  module PDF
    # Extracts the embedded invoice XML from a ZUGFeRD / Factur-X / XRechnung
    # hybrid PDF.
    #
    # Needs the pdf-reader gem, which zugpferd does not install for you:
    #
    #   gem "pdf-reader", "~> 2.16"
    #
    # @example
    #   result = Zugpferd::PDF::Extractor.new.extract(pdf_path: "rechnung.pdf")
    #   result.filename # => "factur-x.xml"
    #   result.syntax   # => :cii
    #   invoice = result.read
    class Extractor
      class PdfReaderNotFound < Zugpferd::Error; end
      class ExtractError < Zugpferd::Error; end
      class InvoiceNotFound < ExtractError; end
      class AmbiguousInvoice < ExtractError; end
      class LimitExceeded < ExtractError; end
      class UnsupportedSyntax < ExtractError; end

      # The names the specifications give the embedded invoice, so that PDFs
      # from any producer are found, not only those of {Embedder}:
      #
      # - factur-x.xml: Factur-X 1.0.06 to 1.08 / ZUGFeRD 2.2 to 2.4, §6.2;
      #   ZUGFeRD 2.1.1 Technical Supplement Part A, §2.2
      # - xrechnung.xml: the same Factur-X §6.2 for the XRECHNUNG profile;
      #   ZUGFeRD 2.1.1 Technical Supplement Reference Profiles, §3.1
      # - zugferd-invoice.xml: ZUGFeRD 2.0 §5.2; ZUGFeRD 2.1.1 Technical
      #   Supplement Part B, §2.2
      # - ZUGFeRD-invoice.xml: ZUGFeRD 1.0 §7.2
      #
      # The specifications do not say whether case matters, so names are
      # matched exactly, as written there.
      INVOICE_FILENAMES = %w[factur-x.xml xrechnung.xml zugferd-invoice.xml ZUGFeRD-invoice.xml].freeze

      DEFAULT_MAX_XML_BYTES = 10 * 1024 * 1024
      DEFAULT_MAX_NAME_TREE_DEPTH = 32

      ROOTS = {
        ["urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100", "CrossIndustryInvoice"] => :cii,
        ["urn:oasis:names:specification:ubl:schema:xsd:Invoice-2", "Invoice"] => :ubl,
        ["urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2", "CreditNote"] => :ubl,
      }.freeze

      # The extracted attachment.
      #
      # @!attribute [r] xml
      #   @return [String] the embedded XML, byte for byte
      # @!attribute [r] filename
      #   @return [String] the attachment name, e.g. "factur-x.xml"
      # @!attribute [r] syntax
      #   @return [Symbol, nil] :cii or :ubl, nil for any other root element
      Result = Struct.new(:xml, :filename, :syntax, keyword_init: true) do
        # Parses the XML with {CII::Reader} or {UBL::Reader}.
        #
        # @return [Model::BillingDocument]
        # @raise [UnsupportedSyntax] for any other root element, e.g. ZUGFeRD 1.0
        def read
          case syntax
          when :cii then CII::Reader.new.read(xml)
          when :ubl then UBL::Reader.new.read(xml)
          else raise UnsupportedSyntax, unsupported_message
          end
        end

        private

        def unsupported_message
          root = Nokogiri::XML(xml).root
          if root.nil?
            "#{filename} has no XML root element"
          elsif root.name == "CrossIndustryDocument"
            "#{filename} is a ZUGFeRD 1.0 invoice (CrossIndustryDocument), which zugpferd cannot read"
          else
            "#{filename} has root element #{root.name}; expected CII CrossIndustryInvoice or UBL Invoice/CreditNote"
          end
        end
      end

      # @param max_xml_bytes [Integer] largest decompressed attachment to accept
      # @param max_name_tree_depth [Integer] deepest EmbeddedFiles name tree level to visit
      def initialize(max_xml_bytes: DEFAULT_MAX_XML_BYTES, max_name_tree_depth: DEFAULT_MAX_NAME_TREE_DEPTH)
        @max_xml_bytes = max_xml_bytes
        @max_name_tree_depth = max_name_tree_depth
      end

      # @param pdf_path [String]
      # @return [Result]
      # @raise [PdfReaderNotFound] if the pdf-reader gem is not installed
      # @raise [InvoiceNotFound] if no attachment has an invoice file name
      # @raise [AmbiguousInvoice] if more than one has
      # @raise [LimitExceeded] if a limit is hit
      # @raise [ExtractError] if the PDF or the attachment cannot be read
      def extract(pdf_path:)
        raise ArgumentError, "PDF file not found: #{pdf_path}" unless File.exist?(pdf_path)

        load_pdf_reader!
        filename, xml = read_invoice(pdf_path)

        Result.new(xml: xml, filename: filename, syntax: detect_syntax(xml))
      end

      private

      # Kept apart from #extract: the rescue clause names pdf-reader
      # constants, which only exist once the gem is loaded.
      def read_invoice(pdf_path)
        Document.new(::PDF::Reader::ObjectHash.new(pdf_path), @max_xml_bytes, @max_name_tree_depth).invoice
      rescue ::PDF::Reader::MalformedPDFError, ::PDF::Reader::UnsupportedFeatureError => e
        raise ExtractError, "Cannot read #{pdf_path}: #{e.message}"
      end

      def load_pdf_reader!
        require "pdf/reader"
      rescue LoadError
        raise PdfReaderNotFound,
          "Zugpferd::PDF::Extractor needs the pdf-reader gem. Add this line to your Gemfile:\n\n" \
          "  gem \"pdf-reader\", \"~> 2.16\""
      end

      def detect_syntax(xml)
        root = Nokogiri::XML(xml).root
        ROOTS[[root.namespace&.href, root.name]] if root
      end

      # Walks one PDF's object tree. A new one per call keeps Extractor
      # free of per-file state.
      class Document
        # Compressed bytes fed to zlib per step. Deflate expands at most
        # about 1032:1, so one step adds at most about 530 KB past the limit.
        INFLATE_CHUNK_BYTES = 512
        MAX_REFERENCE_HOPS = 16

        def initialize(objects, max_xml_bytes, max_name_tree_depth)
          @objects = objects
          @max_xml_bytes = max_xml_bytes
          @max_name_tree_depth = max_name_tree_depth
        end

        # @return [Array(String, String)] file name and XML
        def invoice
          filename, spec = find_invoice
          [filename, read_embedded_file(spec, filename)]
        end

        private

        # PDF/A-3 lists associated files in the catalog's /AF array. Only
        # when that holds no invoice is the EmbeddedFiles name tree searched.
        def find_invoice
          catalog = dictionary(@objects.trailer[:Root])
          matches = invoice_specs(pdf_array(catalog[:AF]))
          matches = invoice_specs(name_tree_values(dictionary(catalog[:Names])[:EmbeddedFiles])) if matches.empty?

          case matches.size
          when 0 then raise InvoiceNotFound, "No invoice attachment (#{INVOICE_FILENAMES.join(", ")}) found"
          when 1 then matches.first
          else raise AmbiguousInvoice, "More than one invoice attachment: #{matches.map(&:first).join(", ")}"
          end
        end

        def invoice_specs(refs)
          specs = refs.map { |ref| dictionary(ref) }.uniq(&:object_id)
          specs.filter_map do |spec|
            name = file_spec_name(spec)
            [name, spec] if INVOICE_FILENAMES.include?(name)
          end
        end

        def file_spec_name(spec)
          name = resolve(spec[:UF]) || resolve(spec[:F])
          decode_text_string(name) if name.is_a?(String)
        end

        # /UF is a text string: UTF-16BE or UTF-8 with a byte order mark,
        # otherwise PDFDocEncoding, which matches ASCII for file names.
        def decode_text_string(string)
          bytes = string.b
          if bytes.start_with?("\xFE\xFF".b)
            bytes.byteslice(2..).force_encoding(Encoding::UTF_16BE).encode(Encoding::UTF_8)
          elsif bytes.start_with?("\xEF\xBB\xBF".b)
            bytes.byteslice(3..).force_encoding(Encoding::UTF_8)
          else
            bytes.force_encoding(Encoding::UTF_8)
          end
        rescue EncodingError
          nil
        end

        def name_tree_values(root)
          values = []
          visited = Set.new
          pending = [[root, 0]]

          until pending.empty?
            ref, depth = pending.pop
            next if ref.nil?

            if depth > @max_name_tree_depth
              raise LimitExceeded, "EmbeddedFiles name tree is deeper than #{@max_name_tree_depth} levels"
            end
            next if ref.is_a?(::PDF::Reader::Reference) && !visited.add?(ref)

            node = dictionary(ref)
            pdf_array(node[:Names]).each_slice(2) { |_key, value| values << value }
            pdf_array(node[:Kids]).each { |kid| pending << [kid, depth + 1] }
          end

          values
        end

        def read_embedded_file(spec, filename)
          embedded = dictionary(spec[:EF])
          stream = resolve(embedded[:UF] || embedded[:F])
          raise ExtractError, "#{filename} has no embedded file stream" unless stream.is_a?(::PDF::Reader::Stream)

          decode_stream(stream, filename)
        end

        # pdf-reader inflates a whole stream in one call, so a size limit
        # could only be checked afterwards. The attachment is inflated here
        # in steps instead, to stop as soon as the limit is passed.
        def decode_stream(stream, filename)
          filters = list(stream.hash[:Filter]).map { |f| resolve(f) }

          case filters
          when []
            check_size!(stream.data.bytesize, filename)
            stream.data.b
          when [:FlateDecode]
            if predictor?(stream.hash[:DecodeParms])
              raise ExtractError, "#{filename} uses a Flate predictor, which is not supported"
            end

            inflate(stream.data, filename)
          else
            raise ExtractError, "#{filename} uses filter #{filters.join(", ")}; only FlateDecode is supported"
          end
        end

        def predictor?(decode_parms)
          list(decode_parms).any? { |params| dictionary(params).fetch(:Predictor, 1).to_i > 1 }
        end

        def inflate(data, filename)
          inflate_with(Zlib::MAX_WBITS + 32, data, filename)
        rescue Zlib::DataError
          # Some producers write raw deflate data without the zlib header.
          begin
            inflate_with(-Zlib::MAX_WBITS, data, filename)
          rescue Zlib::DataError
            raise ExtractError, "#{filename} is not valid Flate data"
          end
        end

        def inflate_with(window_bits, data, filename)
          zstream = Zlib::Inflate.new(window_bits)
          output = +"".b
          offset = 0

          while offset < data.bytesize && !zstream.finished?
            output << zstream.inflate(data.byteslice(offset, INFLATE_CHUNK_BYTES))
            offset += INFLATE_CHUNK_BYTES
            check_size!(output.bytesize, filename)
          end
          raise ExtractError, "#{filename} is truncated" unless zstream.finished?

          output
        ensure
          # Closing a stream stopped early warns unless it is reset first.
          zstream&.reset
          zstream&.close
        end

        def check_size!(bytesize, filename)
          return if bytesize <= @max_xml_bytes

          raise LimitExceeded, "#{filename} is larger than #{@max_xml_bytes} bytes"
        end

        # Follows a reference until it reaches a direct object. Ghostscript,
        # for one, writes /AF entries that point to an object holding
        # another reference.
        def resolve(value)
          MAX_REFERENCE_HOPS.times do
            return value unless value.is_a?(::PDF::Reader::Reference)

            value = @objects.deref(value)
          end
          raise LimitExceeded, "Reference chain longer than #{MAX_REFERENCE_HOPS} hops"
        end

        def dictionary(ref)
          value = resolve(ref)
          value.is_a?(Hash) ? value : {}
        end

        def pdf_array(ref)
          value = resolve(ref)
          value.is_a?(Array) ? value : []
        end

        # A value that may be a single object or an array of them.
        def list(ref)
          value = resolve(ref)
          value.is_a?(Array) ? value : [value].compact
        end
      end
      private_constant :Document
    end
  end
end
