require "test_helper"

class SmokeTest < Minitest::Test
  include ValidatorHelper
  include XmlHelper

  def test_ubl_xsd_exists
    path = File.join(schemas_path, "ubl/xsd/maindoc/UBL-Invoice-2.1.xsd")
    assert File.exist?(path),
      "UBL schema missing – run bin/setup-schemas"
  end

  def test_cen_ubl_schematron_xslt_exists
    path = File.join(schemas_path,
      "schematron/cen/ubl/xslt/EN16931-UBL-validation.xslt")
    assert File.exist?(path),
      "CEN UBL XSLT missing – run bin/setup-schemas"
  end

  def test_cen_cii_schematron_xslt_exists
    path = File.join(schemas_path,
      "schematron/cen/cii/xslt/EN16931-CII-validation.xslt")
    assert File.exist?(path),
      "CEN CII XSLT missing – run bin/setup-schemas"
  end

  def test_testsuite_has_ubl_fixtures
    skip "Testsuite nicht vorhanden" unless testsuite_available?
    refute_empty testsuite_ubl_fixtures
  end

  def test_testsuite_has_cii_fixtures
    skip "Testsuite nicht vorhanden" unless testsuite_available?
    refute_empty testsuite_cii_fixtures
  end

  def test_validates_kosit_ubl_fixture
    skip "Testsuite nicht vorhanden" unless testsuite_available?

    fixture = testsuite_ubl_fixtures.first
    xml = File.read(fixture)
    errors = schematron_validator.validate(xml, rule_set: :cen_ubl)
    fatal = errors.select { |e| e.flag == "fatal" }

    assert_empty fatal,
      "#{File.basename(fixture)} has fatal errors:\n" +
      fatal.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
  end

  def test_validates_kosit_cii_fixture
    skip "Testsuite nicht vorhanden" unless testsuite_available?

    fixture = testsuite_cii_fixtures.first
    xml = File.read(fixture)
    errors = schematron_validator.validate(xml, rule_set: :cen_cii)
    fatal = errors.select { |e| e.flag == "fatal" }

    assert_empty fatal,
      "#{File.basename(fixture)} has fatal errors:\n" +
      fatal.map { |e| "  [#{e.id}] #{e.text}" }.join("\n")
  end
end
