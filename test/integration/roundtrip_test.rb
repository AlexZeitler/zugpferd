require "test_helper"

class UBLRoundtripTest < Minitest::Test
  include ValidatorHelper

  SKIP_UBL = {}.freeze

  def setup
    skip "Testsuite not available" unless testsuite_available?
  end

  testsuite_path = ENV.fetch(
    "XRECHNUNG_TESTSUITE_PATH",
    File.expand_path("../../vendor/testsuite", __dir__)
  )
  fixtures = Dir.glob(File.join(testsuite_path,
    "src/test/business-cases/standard/*_ubl.xml")).sort

  fixtures.each do |fixture|
    name = File.basename(fixture, ".xml")
    define_method("test_roundtrip_#{name}") do
      if SKIP_UBL[name]
        skip "Missing optional fields: #{SKIP_UBL[name]}"
      end

      xml = File.read(fixture)
      invoice = Zugpferd::UBL::Reader.new.read(xml)
      output = Zugpferd::UBL::Writer.new.write(invoice)
      errors = schematron_validator.validate_all(output,
        rule_sets: [:cen_ubl, :xrechnung_ubl])
      fatals = errors.select { |e| e.flag == "fatal" }

      assert_empty fatals,
        "#{name} roundtrip failed:\n" +
        fatals.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
    end
  end
end

class UBLCreditNoteRoundtripTest < Minitest::Test
  include ValidatorHelper

  FIXTURE = File.expand_path(
    "../../vendor/schemas/schematron/cen/ubl/examples/ubl-tc434-creditnote1.xml", __dir__
  )

  def setup
    skip "Credit note fixture not available" unless File.exist?(FIXTURE)
  end

  def test_roundtrip_credit_note
    xml = File.read(FIXTURE)
    invoice = Zugpferd::UBL::Reader.new.read(xml)

    assert_instance_of Zugpferd::Model::CreditNote, invoice
    assert_equal "381", invoice.type_code
    assert_equal "018304 / 28865", invoice.number

    output = Zugpferd::UBL::Writer.new.write(invoice)

    doc = Nokogiri::XML(output)
    assert_equal "CreditNote", doc.root.name
    assert_equal "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2",
                 doc.root.namespace.href

    errors = schematron_validator.validate(output, rule_set: :cen_ubl)
    fatals = errors.select { |e| e.flag == "fatal" }

    assert_empty fatals,
      "Credit note roundtrip failed:\n" +
      fatals.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
  end
end

class CIIRoundtripTest < Minitest::Test
  include ValidatorHelper

  SKIP_CII = {}.freeze

  def setup
    skip "Testsuite not available" unless testsuite_available?
  end

  testsuite_path = ENV.fetch(
    "XRECHNUNG_TESTSUITE_PATH",
    File.expand_path("../../vendor/testsuite", __dir__)
  )
  fixtures = Dir.glob(File.join(testsuite_path,
    "src/test/business-cases/standard/*_uncefact.xml")).sort

  fixtures.each do |fixture|
    name = File.basename(fixture, ".xml")
    define_method("test_roundtrip_#{name}") do
      if SKIP_CII[name]
        skip "Missing optional fields: #{SKIP_CII[name]}"
      end

      xml = File.read(fixture)
      invoice = Zugpferd::CII::Reader.new.read(xml)
      output = Zugpferd::CII::Writer.new.write(invoice)
      errors = schematron_validator.validate_all(output,
        rule_sets: [:cen_cii, :xrechnung_cii])
      fatals = errors.select { |e| e.flag == "fatal" }

      assert_empty fatals,
        "#{name} roundtrip failed:\n" +
        fatals.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
    end
  end
end
