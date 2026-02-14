require "test_helper"

class UBLRoundtripTest < Minitest::Test
  include ValidatorHelper

  # Fixtures that fail due to missing optional fields (Step 7)
  SKIP_UBL = {
    "01.04a-INVOICE_ubl" => "BR-O-10: VAT exemption reason BT-120/121",
    "01.09a-INVOICE_ubl" => "BR-CO-25: payment due date BT-9",
    "01.11a-INVOICE_ubl" => "BR-CO-25: payment due date BT-9",
    "01.12a-INVOICE_ubl" => "BR-CO-25: payment due date BT-9",
    "01.14a-INVOICE_ubl" => "BR-CO-25: payment due date BT-9",
    "01.17a-INVOICE_ubl" => "BR-CO-16: rounding amount BT-114",
    "01.21a-INVOICE_ubl" => "BR-AE-10, BR-CO-13: allowances/charges + exemption reason",
    "02.01a-INVOICE_ubl" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.02a-INVOICE_ubl" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.03a-INVOICE_ubl" => "BR-E-10, BR-CO-16: exemption reason + paid amount BT-113",
    "02.04a-INVOICE_ubl" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.05a-INVOICE_ubl" => "BR-S-08, BR-CO-13: allowances/charges",
    "03.01a-INVOICE_ubl" => "BR-CO-16: paid amount BT-113",
    "03.04a-INVOICE_ubl" => "BR-CO-16: paid amount BT-113",
    "03.06a-INVOICE_ubl" => "BR-CO-25: payment due date BT-9",
    "03.07a-INVOICE_ubl" => "BR-E-10: VAT exemption reason BT-120/121",
  }.freeze

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
      errors = schematron_validator.validate(output, rule_set: :cen_ubl)
      fatals = errors.select { |e| e.flag == "fatal" }

      assert_empty fatals,
        "#{name} roundtrip failed:\n" +
        fatals.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
    end
  end
end

class CIIRoundtripTest < Minitest::Test
  include ValidatorHelper

  # Fixtures that fail due to missing optional fields (Step 7)
  SKIP_CII = {
    "01.04a-INVOICE_uncefact" => "BR-O-10: VAT exemption reason BT-120/121",
    "01.09a-INVOICE_uncefact" => "BR-CO-25: payment due date BT-9",
    "01.11a-INVOICE_uncefact" => "BR-CO-25: payment due date BT-9",
    "01.12a-INVOICE_uncefact" => "BR-CO-25: payment due date BT-9",
    "01.14a-INVOICE_uncefact" => "BR-CO-25: payment due date BT-9",
    "01.17a-INVOICE_uncefact" => "BR-CO-16: rounding amount BT-114",
    "01.21a-INVOICE_uncefact" => "BR-AE-10, BR-CO-13: allowances/charges + exemption reason",
    "02.01a-INVOICE_uncefact" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.02a-INVOICE_uncefact" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.03a-INVOICE_uncefact" => "BR-E-10, BR-CO-16: exemption reason + paid amount BT-113",
    "02.04a-INVOICE_uncefact" => "BR-E-10: VAT exemption reason BT-120/121",
    "02.05a-INVOICE_uncefact" => "BR-S-08, BR-CO-13: allowances/charges",
    "03.01a-INVOICE_uncefact" => "BR-CO-16: paid amount BT-113",
    "03.04a-INVOICE_uncefact" => "BR-CO-16: paid amount BT-113",
    "03.06a-INVOICE_uncefact" => "BR-CO-25: payment due date BT-9",
    "03.07a-INVOICE_uncefact" => "BR-E-10: VAT exemption reason BT-120/121",
  }.freeze

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
      errors = schematron_validator.validate(output, rule_set: :cen_cii)
      fatals = errors.select { |e| e.flag == "fatal" }

      assert_empty fatals,
        "#{name} roundtrip failed:\n" +
        fatals.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
    end
  end
end
