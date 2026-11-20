require "test_helper"
require "zugpferd/pdf"
require "minitest/mock"
require "tmpdir"
require "tempfile"

class ExtractorTest < Minitest::Test
  FIXTURES = File.expand_path("../../fixtures", __dir__)
  CII_XML = File.binread(File.join(FIXTURES, "cii/invoice.xml"))
  UBL_XML = File.binread(File.join(FIXTURES, "ubl/invoice.xml"))

  # Counts the bytes zlib hands back, to show that extraction stops near
  # the limit instead of inflating the whole stream first.
  module InflateCounter
    class << self
      attr_accessor :bytes
    end

    def inflate(*args, **kwargs, &block)
      super.tap { |out| InflateCounter.bytes += out.bytesize if InflateCounter.bytes && out }
    end
  end
  Zlib::Inflate.prepend(InflateCounter)

  def setup
    @extractor = Zugpferd::PDF::Extractor.new
  end

  # --- Ghostscript fixtures, one per invoice file name ---

  {
    "ghostscript-2p1.pdf" => "factur-x.xml",
    "ghostscript-2p1-xrechnung.pdf" => "xrechnung.xml",
    "ghostscript-2p0.pdf" => "zugferd-invoice.xml",
  }.each do |fixture, filename|
    define_method("test_extracts_#{filename.tr(".-", "__")}_from_ghostscript_output") do
      result = @extractor.extract(pdf_path: File.join(FIXTURES, "pdf", fixture))

      assert_equal filename, result.filename
      assert_equal :cii, result.syntax
      assert_equal CII_XML, result.xml
      assert_equal "TEST-001", result.read.number
    end
  end

  def test_extracts_a_pdf_from_another_producer
    result = @extractor.extract(pdf_path: File.join(FIXTURES, "pdf/mustang/MustangBeispiel20221026.pdf"))

    assert_equal "factur-x.xml", result.filename
    assert_equal :cii, result.syntax
    invoice = result.read
    assert_equal "RE1001", invoice.number
    assert_equal BigDecimal("963.11"), BigDecimal(invoice.monetary_totals.payable_amount.to_s)
  end

  def test_zugferd_1_xml_is_returned_but_not_read
    result = @extractor.extract(pdf_path: File.join(FIXTURES, "pdf/ghostscript-1p0.pdf"))

    assert_equal "ZUGFeRD-invoice.xml", result.filename
    assert_nil result.syntax
    assert_equal File.binread(File.join(FIXTURES, "pdf/zugferd-1p0.xml")), result.xml
    error = assert_raises(Zugpferd::PDF::Extractor::UnsupportedSyntax) { result.read }
    assert_match(/ZUGFeRD 1\.0/, error.message)
  end

  # --- Lookup ---

  def test_reads_name_from_f_when_uf_is_missing
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, f: "factur-x.xml")

    result = extract(pdf, af: [spec])

    assert_equal "factur-x.xml", result.filename
    assert_equal CII_XML, result.xml
  end

  def test_prefers_utf16_uf_over_f
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, uf: "<FEFF#{"factur-x.xml".encode("UTF-16BE").unpack1("H*")}>", f: "invoice.dat")

    assert_equal "factur-x.xml", extract(pdf, af: [spec]).filename
  end

  def test_ignores_unrelated_attachments
    pdf = PdfBuilder.new
    other = pdf.attachment("<note/>", uf: "terms.xml")
    invoice = pdf.attachment(UBL_XML, uf: "xrechnung.xml")

    result = extract(pdf, af: [other, invoice])

    assert_equal "xrechnung.xml", result.filename
    assert_equal :ubl, result.syntax
  end

  def test_falls_back_to_a_split_embedded_files_name_tree
    pdf = PdfBuilder.new
    other = pdf.attachment("<note/>", uf: "terms.xml")
    invoice = pdf.attachment(CII_XML, uf: "factur-x.xml")
    left = pdf.name_tree([["a", other]])
    right = pdf.name_tree([["b", invoice]])
    root = pdf.add("<< /Kids [#{left} #{pdf.add("<< /Kids [#{right}] >>")}] >>")

    assert_equal "factur-x.xml", extract(pdf, embedded_files: root).filename
  end

  def test_af_wins_over_the_name_tree
    pdf = PdfBuilder.new
    in_af = pdf.attachment(CII_XML, uf: "factur-x.xml")
    in_tree = pdf.attachment(UBL_XML, uf: "xrechnung.xml")

    result = extract(pdf, af: [in_af], embedded_files: pdf.name_tree([["x", in_tree]]))

    assert_equal "factur-x.xml", result.filename
  end

  def test_the_same_attachment_listed_twice_is_one_match
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, uf: "factur-x.xml")

    assert_equal "factur-x.xml", extract(pdf, af: [spec, spec]).filename
  end

  def test_refuses_two_invoice_attachments
    pdf = PdfBuilder.new
    first = pdf.attachment(CII_XML, uf: "factur-x.xml")
    second = pdf.attachment(UBL_XML, uf: "xrechnung.xml")

    error = assert_raises(Zugpferd::PDF::Extractor::AmbiguousInvoice) { extract(pdf, af: [first, second]) }
    assert_match(/factur-x\.xml, xrechnung\.xml/, error.message)
  end

  def test_refuses_a_pdf_without_an_invoice
    pdf = PdfBuilder.new
    other = pdf.attachment("<note/>", uf: "terms.xml")

    assert_raises(Zugpferd::PDF::Extractor::InvoiceNotFound) { extract(pdf, af: [other]) }
  end

  def test_matches_file_names_exactly
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, uf: "Factur-X.XML")

    assert_raises(Zugpferd::PDF::Extractor::InvoiceNotFound) { extract(pdf, af: [spec]) }
  end

  # --- Limits ---

  def test_stops_at_the_name_tree_depth_limit
    pdf = PdfBuilder.new
    node = pdf.name_tree([["x", pdf.attachment(CII_XML, uf: "factur-x.xml")]])
    3.times { node = pdf.add("<< /Kids [#{node}] >>") }

    extractor = Zugpferd::PDF::Extractor.new(max_name_tree_depth: 2)
    assert_raises(Zugpferd::PDF::Extractor::LimitExceeded) { extract(pdf, embedded_files: node, extractor: extractor) }
    assert_equal "factur-x.xml", extract(pdf, embedded_files: node).filename
  end

  def test_survives_a_name_tree_cycle
    pdf = PdfBuilder.new
    number = pdf.reserve
    loop_ref = pdf.set(number, "<< /Kids [#{number} 0 R] >>")

    assert_raises(Zugpferd::PDF::Extractor::InvoiceNotFound) { extract(pdf, embedded_files: loop_ref) }
  end

  def test_refuses_an_uncompressed_attachment_over_the_limit
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, uf: "factur-x.xml", filter: :none)

    extractor = Zugpferd::PDF::Extractor.new(max_xml_bytes: CII_XML.bytesize - 1)
    assert_raises(Zugpferd::PDF::Extractor::LimitExceeded) { extract(pdf, af: [spec], extractor: extractor) }
    assert_equal CII_XML, extract(pdf, af: [spec]).xml
  end

  def test_stops_inflating_soon_after_the_limit
    limit = 1024 * 1024
    bomb = compressed_zeros(64 * 1024 * 1024)
    pdf = PdfBuilder.new
    file = pdf.stream("/Type /EmbeddedFile /Filter /FlateDecode", bomb)
    spec = pdf.add("<< /Type /Filespec /UF (factur-x.xml) /EF << /F #{file} >> >>")

    InflateCounter.bytes = 0
    extractor = Zugpferd::PDF::Extractor.new(max_xml_bytes: limit)
    assert_raises(Zugpferd::PDF::Extractor::LimitExceeded) { extract(pdf, af: [spec], extractor: extractor) }
    assert_operator InflateCounter.bytes, :<, 2 * limit
  ensure
    InflateCounter.bytes = nil
  end

  # --- Filters and broken input ---

  def test_refuses_filters_other_than_flate
    pdf = PdfBuilder.new
    spec = pdf.attachment(CII_XML, uf: "factur-x.xml", filter: :LZWDecode)

    error = assert_raises(Zugpferd::PDF::Extractor::ExtractError) { extract(pdf, af: [spec]) }
    assert_match(/LZWDecode/, error.message)
  end

  def test_refuses_truncated_flate_data
    pdf = PdfBuilder.new
    data = Zlib::Deflate.deflate(CII_XML)
    file = pdf.stream("/Type /EmbeddedFile /Filter /FlateDecode", data.byteslice(0, data.bytesize / 2))
    spec = pdf.add("<< /Type /Filespec /UF (factur-x.xml) /EF << /F #{file} >> >>")

    assert_raises(Zugpferd::PDF::Extractor::ExtractError) { extract(pdf, af: [spec]) }
  end

  def test_wraps_a_file_that_is_not_a_pdf
    Tempfile.create(["broken", ".pdf"]) do |file|
      file.write("not a pdf")
      file.flush

      assert_raises(Zugpferd::PDF::Extractor::ExtractError) { @extractor.extract(pdf_path: file.path) }
    end
  end

  def test_raises_on_missing_file
    assert_raises(ArgumentError) { @extractor.extract(pdf_path: "/nonexistent/file.pdf") }
  end

  def test_names_the_gem_when_pdf_reader_is_missing
    @extractor.stub(:require, ->(_name) { raise LoadError }) do
      error = assert_raises(Zugpferd::PDF::Extractor::PdfReaderNotFound) do
        @extractor.extract(pdf_path: File.join(FIXTURES, "pdf/ghostscript-2p1.pdf"))
      end
      assert_includes error.message, 'gem "pdf-reader", "~> 2.16"'
    end
  end

  private

  def extract(pdf, af: [], embedded_files: nil, extractor: @extractor)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test.pdf")
      File.binwrite(path, pdf.render(af: af, embedded_files: embedded_files))
      extractor.extract(pdf_path: path)
    end
  end

  def compressed_zeros(size)
    deflate = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
    chunk = "\0".b * (1024 * 1024)
    out = +"".b
    (size / chunk.bytesize).times { out << deflate.deflate(chunk) }
    out << deflate.finish
  ensure
    deflate.close
  end
end
