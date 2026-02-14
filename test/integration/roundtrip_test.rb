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
