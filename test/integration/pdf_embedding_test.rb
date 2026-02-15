require "test_helper"
require "zugpferd/pdf"
require "zugpferd/validation/pdf_validator"
require "zugpferd/validation/mustang_validator"
require "tmpdir"

class PdfEmbeddingTest < Minitest::Test
  include ValidatorHelper

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    skip "zugferd.ps not found (run bin/setup-schemas)" unless File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps"))
    skip "Ghostscript not available" unless ghostscript_available?
    skip "Testsuite not available" unless testsuite_available?
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

  def build_sample_invoice
    invoice = Zugpferd::Model::Invoice.new(
      number: "TEST-001",
      issue_date: Date.new(2024, 1, 15),
      currency_code: "EUR"
    )

    invoice.buyer_reference = "BUYER-REF"
    invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
    invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

    invoice.seller = Zugpferd::Model::TradeParty.new(name: "Test Seller GmbH")
    invoice.seller.vat_identifier = "DE123456789"
    invoice.seller.electronic_address = "seller@example.com"
    invoice.seller.electronic_address_scheme = "EM"
    invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE",
      city_name: "Berlin",
      postal_zone: "10115",
      street_name: "Teststr. 1"
    )

    invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Test Buyer AG")
    invoice.buyer.electronic_address = "buyer@example.com"
    invoice.buyer.electronic_address_scheme = "EM"
    invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE",
      city_name: "Munich",
      postal_zone: "80331"
    )

    line = Zugpferd::Model::LineItem.new(
      id: "1",
      invoiced_quantity: "1",
      unit_code: "C62",
      line_extension_amount: "100.00"
    )
    line.item = Zugpferd::Model::Item.new(
      name: "Test Item",
      tax_category: "S",
      tax_percent: BigDecimal("19")
    )
    line.price = Zugpferd::Model::Price.new(amount: "100.00")
    invoice.line_items << line

    invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(
      tax_amount: "19.00",
      currency_code: "EUR"
    )
    invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
      taxable_amount: "100.00",
      tax_amount: "19.00",
      category_code: "S",
      currency_code: "EUR",
      percent: BigDecimal("19")
    )

    invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
      line_extension_amount: "100.00",
      tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "119.00",
      payable_amount: "119.00"
    )

    invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "58",
      account_id: "DE89370400440532013000"
    )

    invoice
  end
end

class PdfVeraPdfValidationTest < Minitest::Test
  include ValidatorHelper

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    skip "zugferd.ps not found (run bin/setup-schemas)" unless File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps"))
    skip "Ghostscript not available" unless ghostscript_available?
    @pdf_validator = Zugpferd::Validation::PdfValidator.new
    skip "veraPDF not available (start with: docker compose up -d verapdf)" unless @pdf_validator.available?
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

    invoice = build_minimal_invoice
    xml = Zugpferd::CII::Writer.new.write(invoice)

    Zugpferd::PDF::Embedder.new.embed(
      pdf_path: base_pdf,
      xml: xml,
      output_path: output_pdf,
      version: "2p1",
      conformance_level: "EN 16931"
    )

    output_pdf
  end

  def build_minimal_invoice
    invoice = Zugpferd::Model::Invoice.new(
      number: "VAL-001",
      issue_date: Date.new(2024, 1, 15),
      currency_code: "EUR"
    )
    invoice.buyer_reference = "BUYER-REF"
    invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
    invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

    invoice.seller = Zugpferd::Model::TradeParty.new(name: "Seller GmbH")
    invoice.seller.vat_identifier = "DE123456789"
    invoice.seller.electronic_address = "seller@example.com"
    invoice.seller.electronic_address_scheme = "EM"
    invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE", city_name: "Berlin", postal_zone: "10115", street_name: "Str. 1"
    )

    invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Buyer AG")
    invoice.buyer.electronic_address = "buyer@example.com"
    invoice.buyer.electronic_address_scheme = "EM"
    invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE", city_name: "Munich", postal_zone: "80331"
    )

    line = Zugpferd::Model::LineItem.new(
      id: "1", invoiced_quantity: "1", unit_code: "C62", line_extension_amount: "100.00"
    )
    line.item = Zugpferd::Model::Item.new(name: "Item", tax_category: "S", tax_percent: BigDecimal("19"))
    line.price = Zugpferd::Model::Price.new(amount: "100.00")
    invoice.line_items << line

    invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(tax_amount: "19.00", currency_code: "EUR")
    invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
      taxable_amount: "100.00", tax_amount: "19.00", category_code: "S",
      currency_code: "EUR", percent: BigDecimal("19")
    )

    invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
      line_extension_amount: "100.00", tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "119.00", payable_amount: "119.00"
    )

    invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "58", account_id: "DE89370400440532013000"
    )

    invoice
  end
end

class PdfMustangValidationTest < Minitest::Test
  include ValidatorHelper

  VENDOR_ZUGFERD = File.expand_path("../../vendor/zugferd", __dir__)

  def setup
    skip "zugferd.ps not found (run bin/setup-schemas)" unless File.exist?(File.join(VENDOR_ZUGFERD, "zugferd.ps"))
    skip "Ghostscript not available" unless ghostscript_available?
    @mustang_validator = Zugpferd::Validation::MustangValidator.new
    skip "Mustangproject not available (build with: docker compose build mustang)" unless @mustang_validator.available?
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

    invoice = build_minimal_invoice
    xml = Zugpferd::CII::Writer.new.write(invoice)

    Zugpferd::PDF::Embedder.new.embed(
      pdf_path: base_pdf,
      xml: xml,
      output_path: output_pdf,
      version: "2p1",
      conformance_level: "EN 16931"
    )

    output_pdf
  end

  def build_minimal_invoice
    invoice = Zugpferd::Model::Invoice.new(
      number: "VAL-001",
      issue_date: Date.new(2024, 1, 15),
      currency_code: "EUR"
    )
    invoice.buyer_reference = "BUYER-REF"
    invoice.customization_id = "urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0"
    invoice.profile_id = "urn:fdc:peppol.eu:2017:poacc:billing:01:1.0"

    invoice.seller = Zugpferd::Model::TradeParty.new(name: "Seller GmbH")
    invoice.seller.vat_identifier = "DE123456789"
    invoice.seller.electronic_address = "seller@example.com"
    invoice.seller.electronic_address_scheme = "EM"
    invoice.seller.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE", city_name: "Berlin", postal_zone: "10115", street_name: "Str. 1"
    )

    invoice.buyer = Zugpferd::Model::TradeParty.new(name: "Buyer AG")
    invoice.buyer.electronic_address = "buyer@example.com"
    invoice.buyer.electronic_address_scheme = "EM"
    invoice.buyer.postal_address = Zugpferd::Model::PostalAddress.new(
      country_code: "DE", city_name: "Munich", postal_zone: "80331"
    )

    line = Zugpferd::Model::LineItem.new(
      id: "1", invoiced_quantity: "1", unit_code: "C62", line_extension_amount: "100.00"
    )
    line.item = Zugpferd::Model::Item.new(name: "Item", tax_category: "S", tax_percent: BigDecimal("19"))
    line.price = Zugpferd::Model::Price.new(amount: "100.00")
    invoice.line_items << line

    invoice.tax_breakdown = Zugpferd::Model::TaxBreakdown.new(tax_amount: "19.00", currency_code: "EUR")
    invoice.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
      taxable_amount: "100.00", tax_amount: "19.00", category_code: "S",
      currency_code: "EUR", percent: BigDecimal("19")
    )

    invoice.monetary_totals = Zugpferd::Model::MonetaryTotals.new(
      line_extension_amount: "100.00", tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "119.00", payable_amount: "119.00"
    )

    invoice.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "58", account_id: "DE89370400440532013000"
    )

    invoice
  end
end
