require "test_helper"
require "zugpferd/pdf"
require "zugpferd/validation/pdf_validator"
require "zugpferd/validation/mustang_validator"
require "tmpdir"

class PdfEmbeddingTest < Minitest::Test
  include ValidatorHelper
  include SampleInvoice
  include RequiredTools

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    require_tool File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps")), "zugferd.ps not found (run bin/setup-schemas)"
    require_tool ghostscript_available?, "Ghostscript not available"
    require_tool testsuite_available?, "Testsuite not available"
  end

  def test_embed_cii_into_pdf
    Dir.mktmpdir do |dir|
      output_pdf = File.join(dir, "zugferd.pdf")
      base_pdf = create_base_pdf(dir)

      invoice = build_sample_invoice
      xml = Zugpferd::CII::Writer.new.write(invoice)

      embedder = Zugpferd::PDF::Embedder.new
      result = embedder.embed(
        pdf_path: base_pdf,
        xml: xml,
        output_path: output_pdf,
        version: "2p1",
        conformance_level: "EN 16931"
      )

      assert_equal output_pdf, result
      assert File.exist?(output_pdf), "Output PDF must exist"
      assert File.size(output_pdf) > 0, "Output PDF must not be empty"

      # Verify it's a valid PDF
      header = File.binread(output_pdf, 5)
      assert_equal "%PDF-", header, "Output must be a PDF file"
    end
  end

  def test_embed_ubl_into_pdf
    Dir.mktmpdir do |dir|
      output_pdf = File.join(dir, "zugferd_ubl.pdf")
      base_pdf = create_base_pdf(dir)

      invoice = build_sample_invoice
      xml = Zugpferd::UBL::Writer.new.write(invoice)

      embedder = Zugpferd::PDF::Embedder.new
      embedder.embed(
        pdf_path: base_pdf,
        xml: xml,
        output_path: output_pdf,
        version: "2p1",
        conformance_level: "EN 16931"
      )

      assert File.exist?(output_pdf), "Output PDF must exist"
      assert File.size(output_pdf) > 0, "Output PDF must not be empty"
    end
  end

  def test_embed_with_different_versions
    Dir.mktmpdir do |dir|
      base_pdf = create_base_pdf(dir)
      invoice = build_sample_invoice
      xml = Zugpferd::CII::Writer.new.write(invoice)
      embedder = Zugpferd::PDF::Embedder.new

      %w[1p0 2p0 2p1].each do |version|
        level = (version == "1p0") ? "BASIC" : "EN 16931"
        output_pdf = File.join(dir, "zugferd_#{version}.pdf")

        embedder.embed(
          pdf_path: base_pdf,
          xml: xml,
          output_path: output_pdf,
          version: version,
          conformance_level: level
        )

        assert File.exist?(output_pdf), "PDF for version #{version} must exist"
      end
    end
  end

  def test_extract_returns_the_embedded_xml_byte_for_byte
    Dir.mktmpdir do |dir|
      base_pdf = create_base_pdf(dir)
      cii = Zugpferd::CII::Writer.new.write(build_sample_invoice)
      ubl = Zugpferd::UBL::Writer.new.write(build_sample_invoice)

      [
        [cii, "2p1", "EN 16931", "factur-x.xml"],
        [ubl, "2p1", "EN 16931", "factur-x.xml"],
        [cii, "2p1", "XRECHNUNG", "xrechnung.xml"],
        [cii, "2p0", "EN 16931", "zugferd-invoice.xml"],
        [cii, "1p0", "BASIC", "ZUGFeRD-invoice.xml"],
        [cii, "rc", "EN 16931", "ZUGFeRD-invoice.xml"],
      ].each do |xml, version, level, filename|
        output_pdf = File.join(dir, "roundtrip_#{version}_#{level.tr(" ", "_")}.pdf")
        Zugpferd::PDF::Embedder.new.embed(
          pdf_path: base_pdf, xml: xml, output_path: output_pdf,
          version: version, conformance_level: level
        )

        result = Zugpferd::PDF::Extractor.new.extract(pdf_path: output_pdf)

        assert_equal filename, result.filename, "file name for #{version} #{level}"
        assert_equal xml.b, result.xml, "XML for #{version} #{level}"
      end
    end
  end

  def test_embed_with_testsuite_fixture
    fixture = testsuite_cii_fixtures.first
    skip "No CII fixtures found" unless fixture

    xml = File.read(fixture)

    Dir.mktmpdir do |dir|
      base_pdf = create_base_pdf(dir)
      output_pdf = File.join(dir, "fixture_zugferd.pdf")

      embedder = Zugpferd::PDF::Embedder.new
      embedder.embed(
        pdf_path: base_pdf,
        xml: xml,
        output_path: output_pdf,
        version: "2p1",
        conformance_level: "EN 16931"
      )

      assert File.exist?(output_pdf)
      assert File.size(output_pdf) > 0
    end
  end

  private

  def ghostscript_available?
    _, _, status = Open3.capture3("gs", "--version")
    status.success?
  rescue Errno::ENOENT
    false
  end

  def create_base_pdf(dir)
    ps_path = File.join(dir, "base.ps")
    pdf_path = File.join(dir, "base.pdf")

    File.write(ps_path, <<~PS)
      %!PS-Adobe-3.0
      /Helvetica findfont 12 scalefont setfont
      72 750 moveto (Test Invoice) show
      showpage
    PS

    system("gs", "-dBATCH", "-dNOPAUSE", "-sDEVICE=pdfwrite",
      "-o", pdf_path, ps_path,
      [:out, :err] => File::NULL)

    pdf_path
  end
end

class PdfVeraPdfValidationTest < Minitest::Test
  include ValidatorHelper
  include SampleInvoice
  include RequiredTools

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    require_tool File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps")), "zugferd.ps not found (run bin/setup-schemas)"
    require_tool ghostscript_available?, "Ghostscript not available"
    @pdf_validator = Zugpferd::Validation::PdfValidator.new(port: 8081)
    require_tool @pdf_validator.available?, "veraPDF not available (start with: docker compose up -d verapdf)"
  end

  def test_embedded_pdf_is_pdfa3b_compliant
    Dir.mktmpdir do |dir|
      output_pdf = create_zugferd_pdf(dir)

      result = @pdf_validator.validate(output_pdf, profile: "3b")

      assert result.compliant,
        "PDF/A-3b validation failed:\n" +
        result.failures.map { |f| "  #{f[:description]}" }.join("\n")
    end
  end

  private

  def ghostscript_available?
    _, _, status = Open3.capture3("gs", "--version")
    status.success?
  rescue Errno::ENOENT
    false
  end

  def create_zugferd_pdf(dir)
    ps_path = File.join(dir, "base.ps")
    base_pdf = File.join(dir, "base.pdf")
    output_pdf = File.join(dir, "zugferd.pdf")

    File.write(ps_path, <<~PS)
      %!PS-Adobe-3.0
      /Helvetica findfont 12 scalefont setfont
      72 750 moveto (Test Invoice) show
      showpage
    PS

    system("gs", "-dBATCH", "-dNOPAUSE", "-sDEVICE=pdfwrite",
      "-o", base_pdf, ps_path,
      [:out, :err] => File::NULL)

    invoice = build_sample_invoice
    xml = Zugpferd::CII::Writer.new.write(invoice)

    Zugpferd::PDF::Embedder.new.embed(
      pdf_path: base_pdf,
      xml: xml,
      output_path: output_pdf,
      version: "2p1",
      conformance_level: "XRECHNUNG"
    )

    output_pdf
  end
end

class PdfMustangValidationTest < Minitest::Test
  include ValidatorHelper
  include SampleInvoice
  include RequiredTools

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    require_tool File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps")), "zugferd.ps not found (run bin/setup-schemas)"
    require_tool ghostscript_available?, "Ghostscript not available"
    @mustang_validator = Zugpferd::Validation::MustangValidator.new
    require_tool @mustang_validator.available?, "Mustangproject not available (build with: docker compose build mustang)"
  end

  def test_embedded_pdf_passes_mustang_validation
    Dir.mktmpdir do |dir|
      output_pdf = create_zugferd_pdf(dir)

      result = @mustang_validator.validate(output_pdf)

      assert result.valid,
        "Mustangproject validation failed:\n#{result.output}"
    end
  end

  private

  def ghostscript_available?
    _, _, status = Open3.capture3("gs", "--version")
    status.success?
  rescue Errno::ENOENT
    false
  end

  def create_zugferd_pdf(dir)
    ps_path = File.join(dir, "base.ps")
    base_pdf = File.join(dir, "base.pdf")
    output_pdf = File.join(dir, "zugferd.pdf")

    File.write(ps_path, <<~PS)
      %!PS-Adobe-3.0
      /Helvetica findfont 12 scalefont setfont
      72 750 moveto (Test Invoice) show
      showpage
    PS

    system("gs", "-dBATCH", "-dNOPAUSE", "-sDEVICE=pdfwrite",
      "-o", base_pdf, ps_path,
      [:out, :err] => File::NULL)

    invoice = build_sample_invoice
    xml = Zugpferd::CII::Writer.new.write(invoice)

    Zugpferd::PDF::Embedder.new.embed(
      pdf_path: base_pdf,
      xml: xml,
      output_path: output_pdf,
      version: "2p1",
      conformance_level: "XRECHNUNG"
    )

    output_pdf
  end
end
