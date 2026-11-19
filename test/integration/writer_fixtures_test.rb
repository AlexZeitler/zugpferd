require "test_helper"

# Compares the writer output against the snapshot fixtures in test/fixtures/
# and validates it against the XSD and the EN 16931 Schematron rules
# (requires Java/Saxon).
#
# To regenerate the fixtures after an intended change of the writer output, run:
#
#   WRITE_FIXTURES=1 bundle exec rake test:integration
class WriterFixturesTest < Minitest::Test
  include SampleInvoice
  include ValidatorHelper

  def test_ubl_invoice
    assert_match_fixture "ubl/invoice.xml", Zugpferd::UBL::Writer.new.write(build_sample_invoice), schema_key: :ubl_invoice, rule_set: :cen_ubl
  end

  def test_ubl_credit_note
    assert_match_fixture "ubl/credit-note.xml", Zugpferd::UBL::Writer.new.write(build_sample_credit_note), schema_key: :ubl_credit_note, rule_set: :cen_ubl
  end

  def test_cii
    assert_match_fixture "cii/invoice.xml", Zugpferd::CII::Writer.new.write(build_sample_invoice), schema_key: :cii, rule_set: :cen_cii
  end

  private

  def assert_match_fixture(filename, xml, schema_key:, rule_set:)
    path = File.expand_path("../fixtures/#{filename}", __dir__)

    File.write(path, xml) if ENV["WRITE_FIXTURES"]

    assert_equal File.read(path), xml

    schema_errors = schema_validator.validate(xml, schema_key:)
    assert_empty schema_errors,
      "#{path} violates the XSD:\n" + schema_errors.map { |e| " #{e}" }.join("\n")

    errors = schematron_validator.validate(xml, rule_set:)
    fatal  = errors.select { |e| e.flag == "fatal" }

    assert_empty fatal,
      "#{path} has fatal errors:\n" +
      fatal.map { |e| " [#{e.id}] #{e.text}" }.join("\n")
  end
end
