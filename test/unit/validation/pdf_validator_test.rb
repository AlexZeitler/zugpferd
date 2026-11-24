require "test_helper"
require "zugpferd/validation/pdf_validator"

class PdfValidatorTest < Minitest::Test
  FIXTURES = File.expand_path("../../fixtures", __dir__)

  # Stands in for Net::HTTPResponse, parse_response reads only these two.
  Response = Struct.new(:code, :body)

  def setup
    @validator = Zugpferd::Validation::PdfValidator.new
  end

  def test_parses_a_non_compliant_response_of_verapdf_1_30
    body = File.read(File.join(FIXTURES, "verapdf/pdfa3b-not-compliant.json"))

    result = @validator.send(:parse_response, Response.new("200", body))

    refute result.compliant
    assert_equal %w[6.1.9 6.1.7.1 6.6.4], result.failures.map { |f| f[:clause] }
    assert_equal [1, 2, 1], result.failures.map { |f| f[:test_number] }
    assert_equal %w[CosIndirect CosStream MainXMPPackage], result.failures.map { |f| f[:object] }
    assert_match(/PDF\/A Identification extension schema/, result.failures.last[:description])
    assert_equal ["root/indirectObjects[5](2 0)"],
      result.failures.first[:checks].map { |c| c["context"] }
  end
end
