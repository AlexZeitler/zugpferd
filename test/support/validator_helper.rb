module ValidatorHelper
  def schemas_path
    SCHEMAS_PATH
  end

  def schematron_validator
    @schematron_validator ||= Zugpferd::Validation::SchematronValidator.new(
      schemas_path: schemas_path
    )
  end

  def schema_validator
    @schema_validator ||= Zugpferd::Validation::SchemaValidator.new(
      schemas_path: schemas_path
    )
  end

  def testsuite_path
    TESTSUITE_PATH
  end

  def testsuite_available?
    Dir.exist?(testsuite_path)
  end

  def testsuite_ubl_fixtures
    Dir.glob(File.join(testsuite_path,
      "src/test/business-cases/standard/*_ubl.xml")).sort
  end

  def testsuite_cii_fixtures
    Dir.glob(File.join(testsuite_path,
      "src/test/business-cases/standard/*_uncefact.xml")).sort
  end
end
